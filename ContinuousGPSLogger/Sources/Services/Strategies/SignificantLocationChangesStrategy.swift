//
//  SignificantLocationChangesStrategy.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/13.
//

import Foundation
import CoreLocation

class SignificantLocationChangesStrategy: LocationAcquisitionStrategy {
    
    // MARK: - Properties
    
    let name = "Significant Location Changes"
    let description = "大幅な位置変更時のみ更新。省電力だが低頻度（通常500m〜数km移動で更新）。アプリキル後・電源OFF後も継続。"
    
    private(set) var isActive = false
    private var startTime: Date?
    private var updateCount = 0
    private var lastUpdateTime: Date?
    private var totalAccuracy: Double = 0
    private var parameters = StrategyParameters.default
    
    var statistics: StrategyStatistics {
        let averageAccuracy = updateCount > 0 ? totalAccuracy / Double(updateCount) : 0
        let activeDuration = startTime?.timeIntervalSinceNow.magnitude ?? 0
        
        return StrategyStatistics(
            updateCount: updateCount,
            lastUpdateTime: lastUpdateTime,
            averageAccuracy: averageAccuracy,
            estimatedBatteryUsage: .low,
            updateFrequency: .veryLow,
            activeDuration: activeDuration
        )
    }
    
    // MARK: - LocationAcquisitionStrategy
    
    func start(with manager: CLLocationManager, delegate: CLLocationManagerDelegate?) {
        guard !isActive else { return }
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
            print("Significant Location Changes not available")
            return
        }
        
        manager.delegate = delegate
        manager.startMonitoringSignificantLocationChanges()
        
        isActive = true
        startTime = Date()
        
        print("Started Significant Location Changes monitoring")
    }
    
    func stop(with manager: CLLocationManager) {
        guard isActive else { return }
        
        manager.stopMonitoringSignificantLocationChanges()
        isActive = false
        
        print("Stopped Significant Location Changes monitoring")
    }
    
    func configure(parameters: StrategyParameters) {
        self.parameters = parameters
        // Significant Location Changes doesn't use distance filter or accuracy settings
    }
    
    func didUpdateLocations(_ locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        updateCount += 1
        lastUpdateTime = Date()
        
        if location.horizontalAccuracy > 0 {
            totalAccuracy += location.horizontalAccuracy
        }
        
        print("Significant Location Change: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("Accuracy: \(location.horizontalAccuracy)m")
    }
    
    func didFailWithError(_ error: Error) {
        print("Significant Location Changes error: \(error.localizedDescription)")
    }
    
    func resetStatistics() {
        updateCount = 0
        lastUpdateTime = nil
        totalAccuracy = 0
        startTime = Date()
    }
}