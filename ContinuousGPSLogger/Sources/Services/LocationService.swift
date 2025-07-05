//
//  LocationService.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/06.
//

import Foundation
import CoreLocation

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var current: CLLocation?

    private let manager = CLLocationManager()

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
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
        }
    }
}
