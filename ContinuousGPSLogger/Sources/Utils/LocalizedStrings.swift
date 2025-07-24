//
//  LocalizedStrings.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import Foundation
import CoreLocation

enum LocalizedStrings {
    // MARK: - Section Headers
    enum Sections {
        static let permissionStatus = "権限状態"
        static let currentLocation = "現在地"
        static let gpsStrategy = "GPS取得方式"
        static let saveStatistics = "保存統計"
        static let backgroundStatus = "バックグラウンド状態"
        static let error = "エラー"
    }
    
    // MARK: - Location Information
    enum Location {
        static let latitude = "緯度"
        static let longitude = "経度"
        static let accuracy = "精度"
        static let speed = "速度"
        static let updateTime = "更新時刻"
        static let obtaining = "位置情報を取得中…"
    }
    
    // MARK: - Permission Status
    enum Permission {
        static let locationPermission = "位置情報権限"
        static let trackingStatus = "位置取得状態"
        static let backgroundTracking = "バックグラウンド追跡"
        
        static let notDetermined = "未設定"
        static let denied = "拒否"
        static let restricted = "制限"
        static let authorizedWhenInUse = "使用中のみ許可"
        static let authorizedAlways = "常に許可"
        static let unknown = "不明"
        
        static let tracking = "取得中"
        static let stopped = "停止中"
        static let enabled = "有効"
        static let disabled = "無効"
        static let configuring = "設定中"
        
        static let requesting = "権限を要求中…"
        static let requestAlways = "Always 権限をリクエスト"
        static let openSettings = "設定を開く"
    }
    
    // MARK: - GPS Strategy
    enum Strategy {
        static let updateCount = "更新回数"
        static let lastUpdate = "最終更新"
        static let averageAccuracy = "精度(平均)"
        static let batteryUsage = "電力消費"
        static let updateFrequency = "更新頻度"
        static let resetStatistics = "統計リセット"
        
        static let significantDescription = "大幅な位置変更時のみ更新。省電力だが低頻度（通常500m〜数km移動で更新）。アプリキル後・電源OFF後も継続。"
        static let standardDescription = "5m移動ごとに更新。高精度だが電力消費大。バックグラウンド5m間隔、アプリキル後は停止。"
        static let regionDescription = "100m地域の出入りで更新。中程度の精度と電力消費。アプリキル後・電源OFF後も継続可能。"
    }
    
    // MARK: - Save Statistics
    enum SaveStatistics {
        static let saveCount = "保存件数"
        static let lastSave = "最終保存"
        static let saveError = "データの保存に失敗しました"
    }
    
    // MARK: - Background Status
    enum Background {
        static let operationInfo = "動作について"
        static let strategyDifference = "• 取得方式により動作が異なります"
        static let standardInfo = "• Standard: フォアグラウンド1Hz、バックグラウンド5m間隔"
        static let significantInfo = "• Significant: アプリキル後も継続、500m〜数km間隔"
        static let regionInfo = "• Region: 100m地域の出入りで更新、電源OFF後も可能"
        static let dataInfo = "• データ保存: 最大100件まで"
        static let resetState = "状態リセット"
    }
    
    // MARK: - Permission Guidance
    enum PermissionGuidance {
        static let notDetermined = "位置情報の利用許可をお願いします。バックグラウンドでの GPS 追跡には Always 権限が必要です。"
        static let denied = "位置情報の利用が拒否されています。設定から位置情報の利用を許可してください。"
        static let restricted = "位置情報の利用が制限されています。"
        static let whenInUse = "現在は使用中のみ許可されています。バックグラウンドでの GPS 追跡には Always 権限が必要です。"
        static let always = "位置情報の利用が許可されています。バックグラウンドでの GPS 追跡が可能です。"
        static let unknown = "不明な権限状態です。"
    }
    
    // MARK: - Units
    enum Units {
        static let meters = "m"
        static let kmh = "km/h"
        static let times = "回"
        static let items = "件"
    }
    
    // MARK: - Battery Usage Levels
    enum BatteryUsage {
        static let low = "低"
        static let medium = "中"
        static let high = "高"
        static let veryHigh = "最高"
    }
    
    // MARK: - Update Frequency Levels
    enum UpdateFrequency {
        static let low = "低"
        static let medium = "中"
        static let high = "高"
        static let veryHigh = "最高"
    }
    
    // MARK: - Navigation
    enum Navigation {
        static let currentLocation = "現在地"
    }
}

// MARK: - Helper Extensions
extension CLAuthorizationStatus {
    var localizedText: String {
        switch self {
        case .notDetermined:
            return LocalizedStrings.Permission.notDetermined
        case .denied:
            return LocalizedStrings.Permission.denied
        case .restricted:
            return LocalizedStrings.Permission.restricted
        case .authorizedWhenInUse:
            return LocalizedStrings.Permission.authorizedWhenInUse
        case .authorizedAlways:
            return LocalizedStrings.Permission.authorizedAlways
        @unknown default:
            return LocalizedStrings.Permission.unknown
        }
    }
    
    var guidanceText: String {
        switch self {
        case .notDetermined:
            return LocalizedStrings.PermissionGuidance.notDetermined
        case .denied:
            return LocalizedStrings.PermissionGuidance.denied
        case .restricted:
            return LocalizedStrings.PermissionGuidance.restricted
        case .authorizedWhenInUse:
            return LocalizedStrings.PermissionGuidance.whenInUse
        case .authorizedAlways:
            return LocalizedStrings.PermissionGuidance.always
        @unknown default:
            return LocalizedStrings.PermissionGuidance.unknown
        }
    }
}