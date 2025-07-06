//
//  LocationService.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/06.
//

import Foundation
import CoreLocation
import UIKit

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var current: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isTracking: Bool = false
    @Published private(set) var lastError: String?
    @Published private(set) var permissionRequestInProgress: Bool = false
    @Published private(set) var saveCount: Int = 0
    @Published private(set) var lastSaveTimestamp: Date?
    @Published private(set) var saveError: String?
    
    // バックグラウンド関連の状態
    @Published private(set) var isBackgroundLocationEnabled: Bool = false
    @Published private(set) var isSignificantLocationChangesEnabled: Bool = false
    @Published private(set) var lastBackgroundUpdate: Date?

    private let manager = CLLocationManager()

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
        
        if authorizationStatus == .notDetermined {
            manager.requestAlwaysAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startTracking()
            // Always権限が取得済みの場合はバックグラウンド対応を有効化
            if authorizationStatus == .authorizedAlways {
                enableBackgroundLocationUpdates()
                startMonitoringSignificantLocationChanges()
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }
        // MainActor に Hop して Published プロパティを更新
        Task { @MainActor in
            self.current = loc
            self.lastError = nil
            
            // 自動保存処理
            let success = PersistenceService.shared.save(trackPoint: loc)
            if success {
                self.saveCount += 1
                self.lastSaveTimestamp = Date()
                self.saveError = nil
                
                // 定期的なデータ管理
                self.manageDataAfterSave()
            } else {
                self.saveError = "データの保存に失敗しました"
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            self.permissionRequestInProgress = false
            
            switch status {
            case .authorizedWhenInUse:
                self.startTracking()
                self.lastError = nil
            case .authorizedAlways:
                self.startTracking()
                self.enableBackgroundLocationUpdates()
                self.startMonitoringSignificantLocationChanges()
                self.lastError = nil
            case .denied, .restricted:
                self.stopTracking()
                self.lastError = "位置情報の利用が許可されていません"
            case .notDetermined:
                self.stopTracking()
                self.lastError = nil
            @unknown default:
                self.stopTracking()
                self.lastError = "不明な認証状態です"
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error.localizedDescription
        }
    }
    
    private func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        manager.startUpdatingLocation()
        isTracking = true
    }
    
    private func stopTracking() {
        manager.stopUpdatingLocation()
        isTracking = false
    }
    
    func requestAlwaysPermission() {
        permissionRequestInProgress = true
        manager.requestAlwaysAuthorization()
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    var needsAlwaysPermission: Bool {
        return authorizationStatus == .authorizedWhenInUse
    }
    
    /// 保存後のデータ管理
    private func manageDataAfterSave() {
        let totalCount = PersistenceService.shared.getTotalCount()
        
        // 1000件を超えたら古いデータを削除
        if totalCount > 1000 {
            PersistenceService.shared.purge(olderThan: 30)
        }
        
        // 一定間隔で自動削除（例：100件保存ごと）
        if saveCount % 100 == 0 {
            PersistenceService.shared.purge(olderThan: 7)
        }
    }
    
    // MARK: - バックグラウンド対応
    
    /// バックグラウンド位置更新の設定
    private func enableBackgroundLocationUpdates() {
        guard authorizationStatus == .authorizedAlways else { return }
        
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        isBackgroundLocationEnabled = true
    }
    
    /// 重要な位置変更の監視開始
    func startMonitoringSignificantLocationChanges() {
        guard authorizationStatus == .authorizedAlways else { return }
        
        manager.startMonitoringSignificantLocationChanges()
        isSignificantLocationChangesEnabled = true
    }
    
    /// 重要な位置変更の監視停止
    func stopMonitoringSignificantLocationChanges() {
        manager.stopMonitoringSignificantLocationChanges()
        isSignificantLocationChangesEnabled = false
    }
    
    /// アプリライフサイクルイベントの処理
    func handleAppDidEnterBackground() {
        // バックグラウンド移行時の処理
        enableBackgroundLocationUpdates()
        startMonitoringSignificantLocationChanges()
    }
    
    func handleAppWillEnterForeground() {
        // フォアグラウンド復帰時の処理
        // 状態同期とデータ更新
        lastBackgroundUpdate = Date()
    }
}
