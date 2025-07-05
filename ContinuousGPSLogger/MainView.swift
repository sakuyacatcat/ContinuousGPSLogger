//
//  MainView.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/06.
//

import SwiftUI

struct MainView: View {
    @StateObject private var loc = LocationService.shared

    var body: some View {
        VStack(spacing: 12) {
            if let c = loc.current {
                Text("Lat: \(c.coordinate.latitude,  specifier: "%.5f")")
                Text("Lon: \(c.coordinate.longitude, specifier: "%.5f")")
            } else {
                ProgressView("取得中…")
            }
        }
        .padding()
        .navigationTitle("現在地")
    }
}

#Preview {
    MainView()
}
