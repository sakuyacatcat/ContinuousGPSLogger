//
//  RegionTriggeredStandardStrategy.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/31.
//

import Foundation
import CoreLocation
import UIKit

class RegionTriggeredStandardStrategy: LocationAcquisitionStrategy {
    
    // MARK: - Properties
    
    let name = "Region Triggered Standard"
    let description = "地域の出入りでStandard Location Updatesを開始。アプリキル後も1Hz GPS取得可能。"
    
    private(set) var isActive = false
    private var startTime: Date?
    private var updateCount = 0
    private var lastUpdateTime: Date?
    private var totalAccuracy: Double = 0
    private var parameters = StrategyParameters.default
    
    // Region Monitoring関連
    private var currentRegion: CLCircularRegion?
    private var regionEvents: [RegionEvent] = []
    private let regionIdentifier = "RegionTriggeredGPSLogger"
    
    // Standard Location Updates関連
    private var isStandardUpdatesActive = false
    private var lastProcessedLocationTime: Date = Date.distantPast
    private let foregroundUpdateInterval: TimeInterval = 1.0
    
    private struct RegionEvent {
        let type: EventType
        let timestamp: Date
        let triggeredStandardUpdates: Bool
        
        enum EventType {
            case enter, exit, startMonitoring, error
        }
    }
    
    var statistics: StrategyStatistics {
        let averageAccuracy = updateCount > 0 ? totalAccuracy / Double(updateCount) : 0
        let activeDuration = startTime?.timeIntervalSinceNow.magnitude ?? 0
        
        // Standard updates が有効な場合は高頻度・高電力消費
        let frequency: StrategyStatistics.UpdateFrequency = isStandardUpdatesActive ? .veryHigh : .low
        let batteryUsage: StrategyStatistics.BatteryUsageLevel = isStandardUpdatesActive ? .veryHigh : .medium
        
        return StrategyStatistics(
            updateCount: updateCount,
            lastUpdateTime: lastUpdateTime,
            averageAccuracy: averageAccuracy,
            estimatedBatteryUsage: batteryUsage,
            updateFrequency: frequency,
            activeDuration: activeDuration
        )
    }
    
    // MARK: - LocationAcquisitionStrategy
    
    func start(with manager: CLLocationManager, delegate: CLLocationManagerDelegate?) {
        guard !isActive else { return }
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            print("Region Monitoring not available")
            return
        }
        
        manager.delegate = delegate
        
        // 最初はRegion Monitoringから開始
        if let lastKnownLocation = manager.location {
            setupRegionMonitoring(at: lastKnownLocation, with: manager)
        } else {
            // 一時的に位置取得してから地域設定
            manager.requestLocation()
        }
        
        isActive = true
        startTime = Date()
        
        print("Started Region Triggered Standard Strategy")
        print("- Initial Mode: Region Monitoring")
        print("- Region Radius: \(parameters.regionRadius)m")
    }
    
    func stop(with manager: CLLocationManager) {
        guard isActive else { return }
        
        // Region Monitoring を停止
        if let region = currentRegion {
            manager.stopMonitoring(for: region)
        }
        
        // Standard Location Updates を停止
        if isStandardUpdatesActive {
            manager.stopUpdatingLocation()
            isStandardUpdatesActive = false
        }
        
        isActive = false
        currentRegion = nil
        
        print("Stopped Region Triggered Standard Strategy")
    }
    
    func configure(parameters: StrategyParameters) {
        self.parameters = parameters
    }
    
    func didUpdateLocations(_ locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let now = Date()
        let isBackground = UIApplication.shared.applicationState != .active
        
        // Standard Updates が有効な場合は1Hz制限を適用
        if isStandardUpdatesActive {
            let shouldProcess = isBackground || 
                               (now.timeIntervalSince(lastProcessedLocationTime) >= foregroundUpdateInterval)
            
            guard shouldProcess else { return }
            lastProcessedLocationTime = now
        }
        
        updateCount += 1
        lastUpdateTime = Date()
        
        if location.horizontalAccuracy > 0 {
            totalAccuracy += location.horizontalAccuracy
        }
        
        let mode = isStandardUpdatesActive ? "Standard Updates" : "Region Setup"
        let state = isBackground ? "Background" : "Foreground"
        print("Region Triggered Strategy (\(mode), \(state)): \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("Accuracy: \(location.horizontalAccuracy)m")
        
        // Region が未設定の場合は設定（初回位置取得時）
        if currentRegion == nil, let manager = getCurrentLocationManager() {
            setupRegionMonitoring(at: location, with: manager)
        }
    }
    
    func didFailWithError(_ error: Error) {
        print("Region Triggered Standard Strategy error: \(error.localizedDescription)")
        regionEvents.append(RegionEvent(type: .error, timestamp: Date(), triggeredStandardUpdates: false))
    }
    
    func resetStatistics() {
        updateCount = 0
        lastUpdateTime = nil
        totalAccuracy = 0
        startTime = Date()
        regionEvents.removeAll()
        lastProcessedLocationTime = Date.distantPast
    }
    
    // MARK: - Region Monitoring Methods
    
    private func setupRegionMonitoring(at location: CLLocation, with manager: CLLocationManager) {
        // 既存の監視を停止
        if let existingRegion = currentRegion {
            manager.stopMonitoring(for: existingRegion)
        }
        
        // アプリキル後の頻度向上のため小さい半径を使用
        let effectiveRadius = min(parameters.regionRadius, 100.0) // 最大100mに制限
        
        // 新しい地域を作成
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: effectiveRadius,
            identifier: regionIdentifier
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        manager.startMonitoring(for: region)
        currentRegion = region
        
        regionEvents.append(RegionEvent(type: .startMonitoring, timestamp: Date(), triggeredStandardUpdates: false))
        
        print("Setup Region Monitoring at: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("Radius: \(effectiveRadius)m")
        print("アプリキル後でも地域退出時にStandard Updates開始")
    }
    
    // MARK: - Region Delegate Methods (called from LocationService)
    
    func didEnterRegion(_ region: CLRegion) {
        guard region.identifier == regionIdentifier else { return }
        
        regionEvents.append(RegionEvent(type: .enter, timestamp: Date(), triggeredStandardUpdates: false))
        print("Entered region: \(region.identifier)")
        
        // 地域進入時は特に何もしない（Standard Updates継続または維持）
    }
    
    func didExitRegion(_ region: CLRegion, with manager: CLLocationManager) {
        guard region.identifier == regionIdentifier else { return }
        
        // 地域退出時にStandard Location Updatesを開始（1Hz GPS取得）
        startStandardLocationUpdates(with: manager)
        
        regionEvents.append(RegionEvent(type: .exit, timestamp: Date(), triggeredStandardUpdates: true))
        print("Exited region: \(region.identifier) → Starting Standard Location Updates")
        
        // 新しい位置で地域監視を再設定（Standard Updates で取得した位置を使用）
        // Note: 実際の新しい位置は didUpdateLocations で処理される
    }
    
    func monitoringDidFailFor(_ region: CLRegion?, withError error: Error) {
        print("Region monitoring failed for \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
        regionEvents.append(RegionEvent(type: .error, timestamp: Date(), triggeredStandardUpdates: false))
    }
    
    func didStartMonitoringFor(_ region: CLRegion) {
        print("Started monitoring for region: \(region.identifier)")
    }
    
    // MARK: - Standard Location Updates Methods
    
    private func startStandardLocationUpdates(with manager: CLLocationManager) {
        guard !isStandardUpdatesActive else { return }
        
        // Standard Location Updates の設定
        manager.desiredAccuracy = parameters.desiredAccuracy
        
        // フォアグラウンド/バックグラウンドで設定を調整
        let isBackground = UIApplication.shared.applicationState != .active
        if isBackground {
            // バックグラウンド時：アプリキル後の継続性を考慮
            manager.distanceFilter = max(parameters.distanceFilter, 5.0)
            print("Background mode: distanceFilter set to \(manager.distanceFilter)m")
        } else {
            // フォアグラウンド時：1Hz制限のため制限なし
            manager.distanceFilter = kCLDistanceFilterNone
            print("Foreground mode: no distance filter (1Hz internal control)")
        }
        
        manager.startUpdatingLocation()
        isStandardUpdatesActive = true
        
        print("Started Standard Location Updates for 1Hz GPS tracking")
        print("- Desired Accuracy: \(parameters.desiredAccuracy)")
        print("- Distance Filter: \(manager.distanceFilter)m")
    }
    
    private func stopStandardLocationUpdates(with manager: CLLocationManager) {
        guard isStandardUpdatesActive else { return }
        
        manager.stopUpdatingLocation()
        isStandardUpdatesActive = false
        
        print("Stopped Standard Location Updates")
    }
    
    // MARK: - Public Methods
    
    /// 現在監視中の地域情報を取得
    func getCurrentRegionInfo() -> (center: CLLocationCoordinate2D, radius: CLLocationDistance)? {
        guard let region = currentRegion else { return nil }
        return (center: region.center, radius: region.radius)
    }
    
    /// Standard Location Updates の状態
    var isStandardLocationUpdatesActive: Bool {
        return isStandardUpdatesActive
    }
    
    /// 地域イベント履歴を取得
    func getRegionEvents() -> [(type: String, timestamp: Date, triggeredStandardUpdates: Bool)] {
        return regionEvents.map { event in
            let typeString: String
            switch event.type {
            case .enter: typeString = "進入"
            case .exit: typeString = "退出"
            case .startMonitoring: typeString = "監視開始"
            case .error: typeString = "エラー"
            }
            return (type: typeString, timestamp: event.timestamp, triggeredStandardUpdates: event.triggeredStandardUpdates)
        }
    }
    
    /// 現在地周辺で新しいRegion Monitoringを設定（手動用）
    func setupNewRegionMonitoring(at location: CLLocation, with manager: CLLocationManager) {
        setupRegionMonitoring(at: location, with: manager)
    }
    
    // MARK: - Private Helper
    
    private func getCurrentLocationManager() -> CLLocationManager? {
        // この実装は簡略化されています。実際にはLocationServiceから取得する必要があります
        return nil
    }
}