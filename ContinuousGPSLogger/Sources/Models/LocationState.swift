//
//  LocationState.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import Foundation
import CoreLocation
import UIKit

// MARK: - Location Tracking State
@MainActor
final class LocationTrackingState: ObservableObject {
    @Published var current: CLLocation?
    @Published var isTracking: Bool = false
    @Published var lastProcessedLocationTime: Date = Date.distantPast
    
    func updateLocation(_ location: CLLocation) {
        current = location
        lastProcessedLocationTime = Date()
    }
    
    func setTracking(_ isTracking: Bool) {
        self.isTracking = isTracking
    }
}

// MARK: - Permission State
@MainActor
final class LocationPermissionState: ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var permissionRequestInProgress: Bool = false
    @Published var needsAlwaysPermission: Bool = false
    
    func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        permissionRequestInProgress = false
        needsAlwaysPermission = (status == .authorizedWhenInUse)
    }
    
    func setPermissionRequestInProgress(_ inProgress: Bool) {
        permissionRequestInProgress = inProgress
    }
}

// MARK: - Background Operation State
@MainActor
final class BackgroundOperationState: ObservableObject {
    @Published var isBackgroundLocationEnabled: Bool = false
    @Published var isSignificantLocationChangesEnabled: Bool = false
    @Published var lastBackgroundUpdate: Date?
    @Published var backgroundAppRefreshStatus: UIBackgroundRefreshStatus = .available
    @Published var backgroundRefreshAvailable: Bool = true
    
    // Region Monitoring
    @Published var isRegionMonitoringEnabled: Bool = false
    @Published var currentMonitoredRegion: CLCircularRegion?
    @Published var regionEvents: [String] = []
    
    func updateBackgroundLocationStatus(_ enabled: Bool) {
        isBackgroundLocationEnabled = enabled
    }
    
    func updateSignificantLocationChanges(_ enabled: Bool) {
        isSignificantLocationChangesEnabled = enabled
    }
    
    func updateBackgroundAppRefreshStatus(_ status: UIBackgroundRefreshStatus) {
        backgroundAppRefreshStatus = status
        backgroundRefreshAvailable = status == .available
    }
    
    func updateRegionMonitoring(_ enabled: Bool, region: CLCircularRegion? = nil) {
        isRegionMonitoringEnabled = enabled
        if let region = region {
            currentMonitoredRegion = region
        }
    }
    
    func addRegionEvent(_ event: String) {
        regionEvents.append(event)
        if regionEvents.count > 50 {
            regionEvents.removeFirst(regionEvents.count - 50)
        }
    }
}

// MARK: - Error and Recovery State
@MainActor
final class ErrorAndRecoveryState: ObservableObject {
    @Published var lastError: String?
    @Published var saveError: String?
    @Published var consecutiveErrors: Int = 0
    @Published var lastErrorTime: Date?
    
    // Recovery
    @Published var recoveryAttempts: Int = 0
    @Published var lastRecoveryTime: Date?
    @Published var isRecovering: Bool = false
    @Published var recoveryLog: [String] = []
    
    func setError(_ error: String?) {
        lastError = error
        if error != nil {
            lastErrorTime = Date()
            consecutiveErrors += 1
        } else {
            consecutiveErrors = 0
            lastErrorTime = nil
        }
    }
    
    func setSaveError(_ error: String?) {
        saveError = error
    }
    
    func clearErrors() {
        lastError = nil
        saveError = nil
        consecutiveErrors = 0
        lastErrorTime = nil
    }
    
    func updateRecoveryState(attempts: Int, isRecovering: Bool, lastTime: Date?) {
        recoveryAttempts = attempts
        self.isRecovering = isRecovering
        lastRecoveryTime = lastTime
    }
    
    func addRecoveryLog(_ message: String) {
        recoveryLog.append(message)
        if recoveryLog.count > 100 {
            recoveryLog.removeFirst(recoveryLog.count - 100)
        }
    }
}

// MARK: - GPS Strategy State
@MainActor
final class GPSStrategyState: ObservableObject {
    @Published var currentStrategyType: LocationAcquisitionStrategyType = .significantLocationChanges
    @Published var availableStrategies: [LocationAcquisitionStrategyType] = LocationAcquisitionStrategyType.allCases
    
    func updateCurrentStrategy(_ strategyType: LocationAcquisitionStrategyType) {
        currentStrategyType = strategyType
    }
}

// MARK: - Statistics State
@MainActor
final class LocationStatisticsState: ObservableObject {
    @Published var saveCount: Int = 0
    @Published var lastSaveTimestamp: Date?
    
    func updateSaveStatistics(count: Int, lastSave: Date?) {
        saveCount = count
        lastSaveTimestamp = lastSave
    }
    
    func incrementSaveCount() {
        saveCount += 1
        lastSaveTimestamp = Date()
    }
}