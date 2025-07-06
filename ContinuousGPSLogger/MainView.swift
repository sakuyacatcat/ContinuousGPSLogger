//
//  MainView.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/06.
//

import SwiftUI
import CoreLocation

struct MainView: View {
    @StateObject private var loc = LocationService.shared

    var body: some View {
        Form {
            Section("権限状態") {
                HStack {
                    Text("位置情報権限")
                    Spacer()
                    Text(authorizationStatusText)
                        .foregroundColor(authorizationStatusColor)
                }
                
                HStack {
                    Text("位置取得状態")
                    Spacer()
                    Text(loc.isTracking ? "取得中" : "停止中")
                        .foregroundColor(loc.isTracking ? .green : .gray)
                }
                
                if loc.permissionRequestInProgress {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("権限を要求中…")
                            .foregroundStyle(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(permissionGuidanceText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if loc.needsAlwaysPermission {
                        Button("Always 権限をリクエスト") {
                            loc.requestAlwaysPermission()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(loc.permissionRequestInProgress)
                    } else if loc.authorizationStatus == .denied {
                        Button("設定を開く") {
                            loc.openSettings()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            Section("現在地") {
                if let c = loc.current {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("緯度")
                            Spacer()
                            Text("\(c.coordinate.latitude, specifier: "%.6f")")
                        }
                        
                        HStack {
                            Text("経度")
                            Spacer()
                            Text("\(c.coordinate.longitude, specifier: "%.6f")")
                        }
                        
                        if c.horizontalAccuracy > 0 {
                            HStack {
                                Text("精度")
                                Spacer()
                                Text("\(c.horizontalAccuracy, specifier: "%.1f")m")
                            }
                        }
                        
                        if c.speed >= 0 {
                            HStack {
                                Text("速度")
                                Spacer()
                                Text("\(c.speed * 3.6, specifier: "%.1f")km/h")
                            }
                        }
                        
                        HStack {
                            Text("更新時刻")
                            Spacer()
                            Text(c.timestamp, format: .dateTime.hour().minute().second())
                        }
                    }
                } else {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("位置情報を取得中…")
                    }
                }
            }
            
            if let error = loc.lastError {
                Section("エラー") {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("現在地")
    }
    
    private var permissionGuidanceText: String {
        switch loc.authorizationStatus {
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
    
    private var authorizationStatusText: String {
        switch loc.authorizationStatus {
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
    
    private var authorizationStatusColor: Color {
        switch loc.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
}

#Preview {
    MainView()
}
