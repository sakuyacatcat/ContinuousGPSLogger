//
//  Constants.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import Foundation
import CoreLocation

enum AppConstants {
    // MARK: - Location Settings
    enum Location {
        static let desiredAccuracy = kCLLocationAccuracyBest
        static let foregroundUpdateInterval: TimeInterval = 1.0 // 1秒間隔
        static let backgroundDistanceFilter: CLLocationDistance = 50 // 50m間隔
        static let regionRadius: CLLocationDistance = 200 // 200m radius
        static let regionIdentifier = "GPSLoggerRegion"
    }
    
    // MARK: - Data Management
    enum Data {
        static let maxTrackPoints = 100 // 最大保存件数
        static let maxRecoveryLogEntries = 100 // 復旧ログ最大件数
        static let maxRegionEventEntries = 50 // 地域イベントログ最大件数
    }
    
    // MARK: - Error Recovery
    enum ErrorRecovery {
        static let maxConsecutiveErrorsBeforeRecovery = 3
        static let errorRecoveryDelaySeconds: TimeInterval = 10.0
        static let locationManagerRestartDelaySeconds: TimeInterval = 2.0
        static let regionUpdateDistanceThreshold: CLLocationDistance = 100 // 100m
    }
    
    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys {
        static let trackingStateKey = "LocationService.isTrackingEnabled"
        static let lastKnownLocationKey = "LocationService.lastKnownLocation"
        static let recoveryLogKey = "LocationService.recoveryLog"
        static let regionMonitoringStateKey = "LocationService.isRegionMonitoringEnabled"
        static let lastRegionCenterKey = "LocationService.lastRegionCenter"
        static let currentStrategyTypeKey = "LocationService.currentStrategyType"
    }
    
    // MARK: - UI Constants
    enum UI {
        static let progressViewScale: CGFloat = 0.8
        static let sectionSpacing: CGFloat = 8.0
        static let cardSpacing: CGFloat = 6.0
        static let horizontalPadding: CGFloat = 4.0
    }
    
    // MARK: - Number Formatting
    enum Formatting {
        static let coordinateDecimalPlaces = "%.6f"
        static let accuracyDecimalPlaces = "%.1f"
        static let speedDecimalPlaces = "%.1f"
        static let kmhConversionFactor = 3.6
    }
}

// MARK: - Application Information
enum AppInfo {
    static var displayName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "このアプリ"
    }
    
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}