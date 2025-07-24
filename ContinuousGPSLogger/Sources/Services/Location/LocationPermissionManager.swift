//
//  LocationPermissionManager.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import Foundation
import CoreLocation
import UIKit

@MainActor
final class LocationPermissionManager: ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var permissionRequestInProgress: Bool = false
    
    private let manager: CLLocationManager
    
    init(locationManager: CLLocationManager) {
        self.manager = locationManager
        self.authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestAlwaysPermission() {
        permissionRequestInProgress = true
        manager.requestAlwaysAuthorization()
    }
    
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    var needsAlwaysPermission: Bool {
        return authorizationStatus == .authorizedWhenInUse
    }
    
    func updateAuthorizationStatus(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
        permissionRequestInProgress = false
    }
    
    var isAuthorizedForBasicTracking: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    var isAuthorizedForBackgroundTracking: Bool {
        return authorizationStatus == .authorizedAlways
    }
    
    var permissionGuidanceText: String {
        switch authorizationStatus {
        case .notDetermined:
            return "位置情報の利用許可をお願いします。バックグラウンドでの GPS 追跡には Always 権限が必要です。"
        case .denied:
            return "位置情報の利用が拒否されています。設定から位置情報の利用を許可してください。"
        case .restricted:
            return "位置情報の利用が制限されています。"
        case .authorizedWhenInUse:
            return "現在は使用中のみ許可されています。バックグラウンドでの GPS 追跡には Always 権限が必要です。"
        case .authorizedAlways:
            return "位置情報の利用が許可されています。バックグラウンドでの GPS 追跡が可能です。"
        @unknown default:
            return "不明な権限状態です。"
        }
    }
    
    var authorizationStatusText: String {
        switch authorizationStatus {
        case .notDetermined:
            return "未設定"
        case .denied:
            return "拒否"
        case .restricted:
            return "制限"
        case .authorizedWhenInUse:
            return "使用中のみ許可"
        case .authorizedAlways:
            return "常に許可"
        @unknown default:
            return "不明"
        }
    }
}