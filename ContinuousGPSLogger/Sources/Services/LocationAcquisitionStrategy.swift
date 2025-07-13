//
//  LocationAcquisitionStrategy.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/13.
//

import Foundation
import CoreLocation

// MARK: - Strategy Statistics

struct StrategyStatistics {
    let updateCount: Int
    let lastUpdateTime: Date?
    let averageAccuracy: Double
    let estimatedBatteryUsage: BatteryUsageLevel
    let updateFrequency: UpdateFrequency
    let activeDuration: TimeInterval
    
    enum BatteryUsageLevel: String, CaseIterable {
        case low = "低"
        case medium = "中"
        case high = "高"
        case veryHigh = "最高"
    }
    
    enum UpdateFrequency: String, CaseIterable {
        case veryLow = "極低"      // 数時間〜数日
        case low = "低"           // 数十分〜数時間
        case medium = "中"        // 数分〜数十分
        case high = "高"          // 数秒〜数分
        case veryHigh = "最高"    // 1秒以下
    }
}

// MARK: - Strategy Parameters

struct StrategyParameters {
    let distanceFilter: CLLocationDistance
    let desiredAccuracy: CLLocationAccuracy
    let regionRadius: CLLocationDistance
    let customSettings: [String: Any]
    
    static let `default` = StrategyParameters(
        distanceFilter: 5.0,  // アプリキル後の頻度向上のため5mに短縮
        desiredAccuracy: kCLLocationAccuracyBest,
        regionRadius: 100.0,  // 地域監視の頻度向上のため100mに短縮
        customSettings: [:]
    )
    
    // 高頻度版（電力消費大、取得頻度高）
    static let highFrequency = StrategyParameters(
        distanceFilter: 3.0,
        desiredAccuracy: kCLLocationAccuracyBest,
        regionRadius: 50.0,
        customSettings: [:]
    )
    
    // 低電力版（電力消費小、取得頻度低）
    static let lowPower = StrategyParameters(
        distanceFilter: 20.0,
        desiredAccuracy: kCLLocationAccuracyHundredMeters,
        regionRadius: 500.0,
        customSettings: [:]
    )
}

// MARK: - Location Acquisition Strategy Protocol

protocol LocationAcquisitionStrategy: AnyObject {
    /// Strategy の名前
    var name: String { get }
    
    /// Strategy の説明
    var description: String { get }
    
    /// 現在アクティブかどうか
    var isActive: Bool { get }
    
    /// 統計情報
    var statistics: StrategyStatistics { get }
    
    /// Strategy を開始
    func start(with manager: CLLocationManager, delegate: CLLocationManagerDelegate?)
    
    /// Strategy を停止
    func stop(with manager: CLLocationManager)
    
    /// パラメータで設定
    func configure(parameters: StrategyParameters)
    
    /// 位置更新を受信した際の処理
    func didUpdateLocations(_ locations: [CLLocation])
    
    /// エラーを受信した際の処理
    func didFailWithError(_ error: Error)
    
    /// 統計をリセット
    func resetStatistics()
}

// MARK: - Strategy Type Enum

enum LocationAcquisitionStrategyType: String, CaseIterable {
    case significantLocationChanges = "significant"
    case standardLocationUpdates = "standard"
    case regionMonitoring = "region"
    
    var displayName: String {
        switch self {
        case .significantLocationChanges:
            return "Significant Location Changes"
        case .standardLocationUpdates:
            return "Standard Location Updates"
        case .regionMonitoring:
            return "Region Monitoring"
        }
    }
    
    var shortName: String {
        switch self {
        case .significantLocationChanges:
            return "SLC"
        case .standardLocationUpdates:
            return "SLU"
        case .regionMonitoring:
            return "RM"
        }
    }
}

// MARK: - Strategy Factory

class LocationAcquisitionStrategyFactory {
    static func createStrategy(type: LocationAcquisitionStrategyType) -> LocationAcquisitionStrategy {
        switch type {
        case .significantLocationChanges:
            return SignificantLocationChangesStrategy()
        case .standardLocationUpdates:
            return StandardLocationUpdatesStrategy()
        case .regionMonitoring:
            return RegionMonitoringStrategy()
        }
    }
}