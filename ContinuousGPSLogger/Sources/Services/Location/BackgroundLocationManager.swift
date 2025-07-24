//
//  BackgroundLocationManager.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import Foundation
import CoreLocation
import UIKit

@MainActor
final class BackgroundLocationManager: ObservableObject {
    @Published private(set) var isBackgroundLocationEnabled: Bool = false
    @Published private(set) var isSignificantLocationChangesEnabled: Bool = false
    @Published private(set) var lastBackgroundUpdate: Date?
    @Published private(set) var backgroundAppRefreshStatus: UIBackgroundRefreshStatus = .available
    @Published private(set) var backgroundRefreshAvailable: Bool = true
    
    private let manager: CLLocationManager
    private let recoveryService: LocationRecoveryService
    
    init(locationManager: CLLocationManager, recoveryService: LocationRecoveryService) {
        self.manager = locationManager
        self.recoveryService = recoveryService
        
        // Background App Refresh の状態をチェック
        checkBackgroundAppRefreshStatus()
    }
    
    /// バックグラウンド位置更新の設定
    func enableBackgroundLocationUpdates(authorizationStatus: CLAuthorizationStatus) {
        guard authorizationStatus == .authorizedAlways else { return }
        
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        isBackgroundLocationEnabled = true
        
        recoveryService.addRecoveryLog("バックグラウンド位置更新を有効化")
    }
    
    /// 重要な位置変更の監視開始
    func startMonitoringSignificantLocationChanges(authorizationStatus: CLAuthorizationStatus) {
        guard authorizationStatus == .authorizedAlways else { return }
        
        manager.startMonitoringSignificantLocationChanges()
        isSignificantLocationChangesEnabled = true
        
        recoveryService.addRecoveryLog("重要な位置変更の監視を開始")
    }
    
    /// 重要な位置変更の監視停止
    func stopMonitoringSignificantLocationChanges() {
        manager.stopMonitoringSignificantLocationChanges()
        isSignificantLocationChangesEnabled = false
        
        recoveryService.addRecoveryLog("重要な位置変更の監視を停止")
    }
    
    /// アプリライフサイクルイベントの処理
    func handleAppDidEnterBackground(
        authorizationStatus: CLAuthorizationStatus,
        isTracking: Bool
    ) {
        // バックグラウンド移行時の処理
        configureForBackgroundMode(isTracking: isTracking)
        enableBackgroundLocationUpdates(authorizationStatus: authorizationStatus)
        startMonitoringSignificantLocationChanges(authorizationStatus: authorizationStatus)
    }
    
    func handleAppWillEnterForeground(isTracking: Bool) {
        // フォアグラウンド復帰時の処理
        configureForForegroundMode(isTracking: isTracking)
        lastBackgroundUpdate = Date()
    }
    
    /// フォアグラウンドモード用の設定
    private func configureForForegroundMode(isTracking: Bool) {
        guard isTracking else { return }
        manager.distanceFilter = kCLDistanceFilterNone // 全ての更新を受け取る（1Hz制限は内部で実装）
        recoveryService.addRecoveryLog("フォアグラウンドモード: 1Hz更新に設定")
    }
    
    /// バックグラウンドモード用の設定
    private func configureForBackgroundMode(isTracking: Bool) {
        guard isTracking else { return }
        manager.distanceFilter = 50 // バックグラウンド時は50m間隔で省電力化
        recoveryService.addRecoveryLog("バックグラウンドモード: 50m間隔に設定")
    }
    
    /// Background App Refresh の状態をチェック
    private func checkBackgroundAppRefreshStatus() {
        backgroundAppRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        backgroundRefreshAvailable = backgroundAppRefreshStatus == .available
        
        let statusText: String
        switch backgroundAppRefreshStatus {
        case .available:
            statusText = "利用可能"
        case .denied:
            statusText = "無効（ユーザー設定）"
        case .restricted:
            statusText = "制限されています"
        @unknown default:
            statusText = "不明"
        }
        
        recoveryService.addRecoveryLog("Background App Refresh 状態: \(statusText)")
        
        // 無効な場合は対処法をログに記録
        if !backgroundRefreshAvailable {
            recoveryService.addRecoveryLog("推奨: Background App Refresh を有効にしてください（設定 > アプリ名 > Background App Refresh）")
        }
    }
    
    /// Background App Refresh の状態を更新（フォアグラウンド復帰時用）
    func updateBackgroundAppRefreshStatus() {
        checkBackgroundAppRefreshStatus()
    }
    
    /// Background App Refresh のガイダンスメッセージを取得
    var backgroundRefreshGuidanceMessage: String {
        switch backgroundAppRefreshStatus {
        case .available:
            return "Background App Refresh が有効です。バックグラウンドでの動作が最適化されています。"
        case .denied:
            let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "このアプリ"
            return "Background App Refresh が無効です。設定 > \(appName) > Background App Refresh を有効にすることで、バックグラウンド動作が改善されます。"
        case .restricted:
            return "Background App Refresh が制限されています。デバイスの制限により、バックグラウンド動作が制限される場合があります。"
        @unknown default:
            return "Background App Refresh の状態が不明です。"
        }
    }
    
    /// 設定アプリのBackground App Refresh画面を開く
    func openBackgroundRefreshSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
            recoveryService.addRecoveryLog("Background App Refresh 設定画面を開きました")
        }
    }
    
    var backgroundTrackingStatusText: String {
        if isBackgroundLocationEnabled && (isSignificantLocationChangesEnabled) {
            return "有効"
        } else {
            return "設定中"
        }
    }
}