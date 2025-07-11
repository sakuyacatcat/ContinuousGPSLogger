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
            
            Section("保存統計") {
                HStack {
                    Text("保存件数")
                    Spacer()
                    Text("\(loc.saveCount)件")
                        .foregroundColor(.green)
                }
                
                if let lastSave = loc.lastSaveTimestamp {
                    HStack {
                        Text("最終保存")
                        Spacer()
                        Text(lastSave, format: .dateTime.hour().minute().second())
                            .foregroundColor(.secondary)
                    }
                }
                
                if let error = loc.saveError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Section("バックグラウンド状態") {
                HStack {
                    Text("バックグラウンド位置更新")
                    Spacer()
                    Text(loc.isBackgroundLocationEnabled ? "有効" : "無効")
                        .foregroundColor(loc.isBackgroundLocationEnabled ? .green : .gray)
                }
                
                HStack {
                    Text("重要な位置変更の監視")
                    Spacer()
                    Text(loc.isSignificantLocationChangesEnabled ? "監視中" : "停止中")
                        .foregroundColor(loc.isSignificantLocationChangesEnabled ? .green : .gray)
                }
                
                if let lastUpdate = loc.lastBackgroundUpdate {
                    HStack {
                        Text("最後のバックグラウンド更新")
                        Spacer()
                        Text(lastUpdate, format: .dateTime.hour().minute().second())
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(backgroundStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
    
    private var backgroundStatusText: String {
        if loc.authorizationStatus == .authorizedAlways {
            if loc.isBackgroundLocationEnabled && loc.isSignificantLocationChangesEnabled {
                return "バックグラウンドでの位置追跡が有効です。アプリ終了後も継続的に位置情報を記録します。"
            } else {
                return "Always権限が許可されていますが、バックグラウンド機能の設定が不完全です。"
            }
        } else {
            return "バックグラウンドでの位置追跡にはAlways権限が必要です。"
        }
    }
}

#Preview {
    MainView()
}
