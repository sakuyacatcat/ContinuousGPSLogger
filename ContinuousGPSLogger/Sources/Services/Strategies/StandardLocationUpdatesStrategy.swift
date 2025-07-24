//
//  StandardLocationUpdatesStrategy.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/13.
//

import Foundation
import CoreLocation
import UIKit

class StandardLocationUpdatesStrategy: LocationAcquisitionStrategy {
    
    // MARK: - Properties
    
    let name = "Standard Location Updates"
    let description = "設定距離ごとに更新。高精度だが電力消費大。バックグラウンド制限あり。"
    
    private(set) var isActive = false
    private var startTime: Date?
    private var updateCount = 0
    private var lastUpdateTime: Date?
    private var totalAccuracy: Double = 0
    private var parameters = StrategyParameters.default
    
    // 1Hz 制御用
    private var lastProcessedLocationTime: Date = Date.distantPast
    private let foregroundUpdateInterval: TimeInterval = 1.0
    
    var statistics: StrategyStatistics {
        let averageAccuracy = updateCount > 0 ? totalAccuracy / Double(updateCount) : 0
        let activeDuration = startTime?.timeIntervalSinceNow.magnitude ?? 0
        
        // フォアグラウンド/バックグラウンドで頻度と電力消費を調整
        let isBackground = UIApplication.shared.applicationState != .active
        let frequency: StrategyStatistics.UpdateFrequency = isBackground ? .medium : .veryHigh
        let batteryUsage: StrategyStatistics.BatteryUsageLevel = isBackground ? .medium : .veryHigh
        
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
        
        manager.delegate = delegate
        manager.desiredAccuracy = parameters.desiredAccuracy
        
        // フォアグラウンド/バックグラウンドで設定を変更
        configureForCurrentState(manager: manager)
        
        manager.startUpdatingLocation()
        
        isActive = true
        startTime = Date()
        
        print("Started Standard Location Updates")
        print("- Distance Filter: \(manager.distanceFilter)m")
        print("- Desired Accuracy: \(parameters.desiredAccuracy)")
    }
    
    func stop(with manager: CLLocationManager) {
        guard isActive else { return }
        
        manager.stopUpdatingLocation()
        isActive = false
        
        print("Stopped Standard Location Updates")
    }
    
    func configure(parameters: StrategyParameters) {
        self.parameters = parameters
    }
    
    func didUpdateLocations(_ locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        let now = Date()
        let isBackground = UIApplication.shared.applicationState != .active
        
        // フォアグラウンド時は1Hz制限、バックグラウンド時は制限なし
        let shouldProcess = isBackground || 
                           (now.timeIntervalSince(lastProcessedLocationTime) >= foregroundUpdateInterval)
        
        guard shouldProcess else { return }
        
        lastProcessedLocationTime = now
        updateCount += 1
        lastUpdateTime = Date()
        
        if location.horizontalAccuracy > 0 {
            totalAccuracy += location.horizontalAccuracy
        }
        
        let state = isBackground ? "Background" : "Foreground"
        print("Standard Location Update (\(state)): \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("Accuracy: \(location.horizontalAccuracy)m, Speed: \(location.speed)m/s")
    }
    
    func didFailWithError(_ error: Error) {
        print("Standard Location Updates error: \(error.localizedDescription)")
    }
    
    func resetStatistics() {
        updateCount = 0
        lastUpdateTime = nil
        totalAccuracy = 0
        startTime = Date()
        lastProcessedLocationTime = Date.distantPast
    }
    
    // MARK: - Private Methods
    
    private func configureForCurrentState(manager: CLLocationManager) {
        let isBackground = UIApplication.shared.applicationState != .active
        
        if isBackground {
            // バックグラウンド時：頻度向上のため短い距離に設定（アプリキル前まで有効）
            manager.distanceFilter = max(parameters.distanceFilter, 5.0) // 最小5m、通常5m
            print("Standard Strategy: バックグラウンド設定 - distanceFilter: \(manager.distanceFilter)m")
        } else {
            // フォアグラウンド時：高頻度設定（1Hz制限は内部で実装）
            manager.distanceFilter = kCLDistanceFilterNone
            print("Standard Strategy: フォアグラウンド設定 - 制限なし（1Hz内部制御）")
        }
    }
    
    /// アプリ状態変更時の設定更新
    func updateForApplicationState(manager: CLLocationManager) {
        guard isActive else { return }
        configureForCurrentState(manager: manager)
        
        let isBackground = UIApplication.shared.applicationState != .active
        let state = isBackground ? "Background" : "Foreground"
        print("Standard Location Updates configured for \(state) mode")
    }
}