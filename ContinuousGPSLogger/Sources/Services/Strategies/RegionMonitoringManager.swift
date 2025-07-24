//
//  RegionMonitoringManager.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import Foundation
import CoreLocation

@MainActor
final class RegionMonitoringManager: ObservableObject {
    @Published private(set) var isRegionMonitoringEnabled: Bool = false
    @Published private(set) var currentMonitoredRegion: CLCircularRegion?
    @Published private(set) var regionEvents: [String] = []
    
    private let manager: CLLocationManager
    private let recoveryService: LocationRecoveryService
    
    // Region monitoring settings
    private let regionRadius: CLLocationDistance = 200 // 200m radius
    private let regionIdentifier = "GPSLoggerRegion"
    
    // UserDefaults keys
    private let regionMonitoringStateKey = "LocationService.isRegionMonitoringEnabled"
    private let lastRegionCenterKey = "LocationService.lastRegionCenter"
    
    init(locationManager: CLLocationManager, recoveryService: LocationRecoveryService) {
        self.manager = locationManager
        self.recoveryService = recoveryService
    }
    
    /// Region Monitoring を有効化
    func enableRegionMonitoring(authorizationStatus: CLAuthorizationStatus) {
        guard authorizationStatus == .authorizedAlways else {
            recoveryService.addRecoveryLog("Region Monitoring有効化失敗: Always権限が必要")
            return
        }
        
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            recoveryService.addRecoveryLog("Region Monitoring有効化失敗: デバイスが対応していません")
            return
        }
        
        isRegionMonitoringEnabled = true
        recoveryService.saveRegionMonitoringState(true)
        
        recoveryService.addRecoveryLog("Region Monitoring を有効化しました")
    }
    
    /// Region Monitoring を無効化
    func disableRegionMonitoring() {
        isRegionMonitoringEnabled = false
        recoveryService.saveRegionMonitoringState(false)
        
        // 現在監視中の地域があれば停止
        if let region = currentMonitoredRegion {
            manager.stopMonitoring(for: region)
            currentMonitoredRegion = nil
        }
        
        recoveryService.addRecoveryLog("Region Monitoring を無効化しました")
    }
    
    /// 指定位置周辺の地域監視を更新
    func updateRegionMonitoring(around location: CLLocation) {
        guard isRegionMonitoringEnabled else { return }
        
        let newCenter = location.coordinate
        
        // 既存の監視地域があり、中心からの距離が100m以内なら更新不要
        if let existingRegion = currentMonitoredRegion {
            let existingCenter = CLLocation(latitude: existingRegion.center.latitude, 
                                          longitude: existingRegion.center.longitude)
            let distance = location.distance(from: existingCenter)
            
            if distance < 100 {
                return // 更新不要
            }
            
            // 既存の監視を停止
            manager.stopMonitoring(for: existingRegion)
        }
        
        // 新しい地域監視を開始
        let newRegion = CLCircularRegion(center: newCenter, 
                                       radius: regionRadius, 
                                       identifier: regionIdentifier)
        newRegion.notifyOnEntry = true
        newRegion.notifyOnExit = true
        
        manager.startMonitoring(for: newRegion)
        currentMonitoredRegion = newRegion
        
        // 状態を保存
        let centerData = [
            "latitude": newCenter.latitude,
            "longitude": newCenter.longitude
        ]
        UserDefaults.standard.set(centerData, forKey: lastRegionCenterKey)
        
        recoveryService.addRecoveryLog("地域監視を更新: 中心(\(newCenter.latitude), \(newCenter.longitude)) 半径\(regionRadius)m")
    }
    
    /// 地域進入時の処理
    func handleRegionEntry(_ region: CLRegion) {
        let event = "地域進入: \(region.identifier)"
        addRegionEvent(event)
        recoveryService.addRecoveryLog(event)
    }
    
    /// 地域退出時の処理
    func handleRegionExit(_ region: CLRegion, currentLocation: CLLocation?) {
        let event = "地域退出: \(region.identifier) - 新しい地域の監視を開始"
        addRegionEvent(event)
        recoveryService.addRecoveryLog(event)
        
        // 地域から出たので、新しい位置での地域監視を開始
        if let currentLocation = currentLocation {
            updateRegionMonitoring(around: currentLocation)
        }
    }
    
    /// 地域監視エラー時の処理
    func handleRegionMonitoringError(_ region: CLRegion?, error: Error) -> String {
        let event = "地域監視エラー: \(error.localizedDescription)"
        addRegionEvent(event)
        recoveryService.addRecoveryLog(event)
        return event
    }
    
    /// 地域監視開始時の処理
    func handleRegionMonitoringStart(_ region: CLRegion) {
        let event = "地域監視開始: \(region.identifier)"
        addRegionEvent(event)
        recoveryService.addRecoveryLog(event)
    }
    
    /// Region イベントログの追加
    private func addRegionEvent(_ event: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let logEntry = "[\(timestamp)] \(event)"
        
        regionEvents.append(logEntry)
        
        // イベントログは最新50件まで保持
        if regionEvents.count > 50 {
            regionEvents.removeFirst(regionEvents.count - 50)
        }
        
        print("LocationService Region: \(logEntry)")
    }
    
    /// Region イベントログをクリア
    func clearRegionEvents() {
        regionEvents.removeAll()
        addRegionEvent("地域イベントログをクリアしました")
    }
    
    /// 復旧時にRegion Monitoringを復元
    func restoreIfNeeded(authorizationStatus: CLAuthorizationStatus) {
        let wasRegionMonitoringEnabled = recoveryService.getRegionMonitoringState()
        if wasRegionMonitoringEnabled {
            enableRegionMonitoring(authorizationStatus: authorizationStatus)
        }
    }
}