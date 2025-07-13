//
//  RegionMonitoringStrategy.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/13.
//

import Foundation
import CoreLocation

class RegionMonitoringStrategy: LocationAcquisitionStrategy {
    
    // MARK: - Properties
    
    let name = "Region Monitoring"
    let description = "地域の出入りで更新。中程度の精度と電力消費。電源OFF後も継続可能。"
    
    private(set) var isActive = false
    private var startTime: Date?
    private var updateCount = 0
    private var lastUpdateTime: Date?
    private var totalAccuracy: Double = 0
    private var parameters = StrategyParameters.default
    
    // Region Monitoring固有のプロパティ
    private var currentRegion: CLCircularRegion?
    private var regionEvents: [RegionEvent] = []
    private let regionIdentifier = "GPSLoggerRegion"
    
    private struct RegionEvent {
        let type: EventType
        let timestamp: Date
        let location: CLLocation?
        
        enum EventType {
            case enter, exit, startMonitoring, error
        }
    }
    
    var statistics: StrategyStatistics {
        let averageAccuracy = updateCount > 0 ? totalAccuracy / Double(updateCount) : 0
        let activeDuration = startTime?.timeIntervalSinceNow.magnitude ?? 0
        
        return StrategyStatistics(
            updateCount: updateCount,
            lastUpdateTime: lastUpdateTime,
            averageAccuracy: averageAccuracy,
            estimatedBatteryUsage: .medium,
            updateFrequency: .low,
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
        
        // 現在地があれば即座に監視開始、なければ一時的に位置取得
        if let lastKnownLocation = manager.location {
            setupRegionMonitoring(at: lastKnownLocation, with: manager)
        } else {
            // 一時的に位置取得して地域設定
            manager.requestLocation()
        }
        
        isActive = true
        startTime = Date()
        
        print("Started Region Monitoring")
        print("- Region Radius: \(parameters.regionRadius)m")
    }
    
    func stop(with manager: CLLocationManager) {
        guard isActive else { return }
        
        // 現在監視中の地域があれば停止
        if let region = currentRegion {
            manager.stopMonitoring(for: region)
        }
        
        isActive = false
        currentRegion = nil
        
        print("Stopped Region Monitoring")
    }
    
    func configure(parameters: StrategyParameters) {
        self.parameters = parameters
    }
    
    func didUpdateLocations(_ locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        updateCount += 1
        lastUpdateTime = Date()
        
        if location.horizontalAccuracy > 0 {
            totalAccuracy += location.horizontalAccuracy
        }
        
        print("Region Monitoring Location Update: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("Accuracy: \(location.horizontalAccuracy)m")
        
        // 新しい地域での監視を設定（一時的な位置取得の場合）
        if currentRegion == nil, let manager = getCurrentLocationManager() {
            setupRegionMonitoring(at: location, with: manager)
        }
    }
    
    func didFailWithError(_ error: Error) {
        print("Region Monitoring error: \(error.localizedDescription)")
        regionEvents.append(RegionEvent(type: .error, timestamp: Date(), location: nil))
    }
    
    func resetStatistics() {
        updateCount = 0
        lastUpdateTime = nil
        totalAccuracy = 0
        startTime = Date()
        regionEvents.removeAll()
    }
    
    // MARK: - Region Monitoring Specific Methods
    
    /// 地域監視をセットアップ
    private func setupRegionMonitoring(at location: CLLocation, with manager: CLLocationManager) {
        // 既存の監視を停止
        if let existingRegion = currentRegion {
            manager.stopMonitoring(for: existingRegion)
        }
        
        // 頻度向上のため小さい半径を使用
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
        
        regionEvents.append(RegionEvent(type: .startMonitoring, timestamp: Date(), location: location))
        
        print("Setup Region Monitoring at: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("Radius: \(effectiveRadius)m (頻度向上のため小半径)")
        print("アプリキル後でも地域出入りで更新継続")
    }
    
    /// 地域進入時の処理
    func didEnterRegion(_ region: CLRegion) {
        guard region.identifier == regionIdentifier else { return }
        
        regionEvents.append(RegionEvent(type: .enter, timestamp: Date(), location: nil))
        print("Entered region: \(region.identifier)")
    }
    
    /// 地域退出時の処理
    func didExitRegion(_ region: CLRegion, with manager: CLLocationManager) {
        guard region.identifier == regionIdentifier else { return }
        
        regionEvents.append(RegionEvent(type: .exit, timestamp: Date(), location: nil))
        print("Exited region: \(region.identifier)")
        
        // 地域から出たので新しい位置で監視を再設定
        manager.requestLocation()
    }
    
    /// 地域監視エラー処理
    func monitoringDidFailFor(_ region: CLRegion?, withError error: Error) {
        print("Region monitoring failed for \(region?.identifier ?? "unknown"): \(error.localizedDescription)")
        regionEvents.append(RegionEvent(type: .error, timestamp: Date(), location: nil))
    }
    
    /// 地域監視開始確認
    func didStartMonitoringFor(_ region: CLRegion) {
        print("Started monitoring for region: \(region.identifier)")
    }
    
    /// 現在監視中の地域情報を取得
    func getCurrentRegionInfo() -> (center: CLLocationCoordinate2D, radius: CLLocationDistance)? {
        guard let region = currentRegion else { return nil }
        return (center: region.center, radius: region.radius)
    }
    
    /// 地域イベント履歴を取得
    func getRegionEvents() -> [(type: String, timestamp: Date)] {
        return regionEvents.map { event in
            let typeString: String
            switch event.type {
            case .enter: typeString = "進入"
            case .exit: typeString = "退出"
            case .startMonitoring: typeString = "監視開始"
            case .error: typeString = "エラー"
            }
            return (type: typeString, timestamp: event.timestamp)
        }
    }
    
    // MARK: - Private Helper
    
    private func getCurrentLocationManager() -> CLLocationManager? {
        // この実装は簡略化されています。実際にはLocationServiceから取得する必要があります
        return nil
    }
}