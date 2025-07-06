//
//  LocationService.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/06.
//

import Foundation
import CoreLocation
import UIKit

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var current: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isTracking: Bool = false
    @Published private(set) var lastError: String?
    @Published private(set) var permissionRequestInProgress: Bool = false

    private let manager = CLLocationManager()

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
        
        if authorizationStatus == .notDetermined {
            manager.requestAlwaysAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startTracking()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }
        // MainActor に Hop して Published プロパティを更新
        Task { @MainActor in
            self.current = loc
            self.lastError = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            self.permissionRequestInProgress = false
            
            switch status {
            case .authorizedWhenInUse:
                self.startTracking()
                self.lastError = nil
            case .authorizedAlways:
                self.startTracking()
                self.lastError = nil
            case .denied, .restricted:
                self.stopTracking()
                self.lastError = "位置情報の利用が許可されていません"
            case .notDetermined:
                self.stopTracking()
                self.lastError = nil
            @unknown default:
                self.stopTracking()
                self.lastError = "不明な認証状態です"
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error.localizedDescription
        }
    }
    
    private func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        manager.startUpdatingLocation()
        isTracking = true
    }
    
    private func stopTracking() {
        manager.stopUpdatingLocation()
        isTracking = false
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
}
