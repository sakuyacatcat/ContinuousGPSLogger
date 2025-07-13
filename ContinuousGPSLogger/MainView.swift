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
            
            Section("GPS取得方式") {
                VStack(alignment: .leading, spacing: 12) {
                    // Strategy選択
                    Picker("取得方式", selection: Binding(
                        get: { loc.currentStrategyType },
                        set: { loc.changeStrategy(to: $0) }
                    )) {
                        ForEach(loc.availableStrategies, id: \.self) { strategy in
                            Text(strategy.displayName).tag(strategy)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // 現在の Strategy の説明
                    if let currentStrategy = getCurrentStrategyDescription() {
                        Text(currentStrategy)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
                    
                    // Strategy統計
                    if let stats = loc.getCurrentStrategyStatistics() {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("更新回数")
                                Spacer()
                                Text("\(stats.updateCount)回")
                                    .foregroundColor(.blue)
                            }
                            
                            if let lastUpdate = stats.lastUpdateTime {
                                HStack {
                                    Text("最終更新")
                                    Spacer()
                                    Text(lastUpdate, format: .dateTime.hour().minute().second())
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                Text("精度(平均)")
                                Spacer()
                                Text(stats.averageAccuracy > 0 ? "\(stats.averageAccuracy, specifier: "%.1f")m" : "-")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("電力消費")
                                Spacer()
                                Text(stats.estimatedBatteryUsage.rawValue)
                                    .foregroundColor(batteryUsageColor(stats.estimatedBatteryUsage))
                            }
                            
                            HStack {
                                Text("更新頻度")
                                Spacer()
                                Text(stats.updateFrequency.rawValue)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 4)
                    }
                    
                    // 統計リセットボタン
                    HStack {
                        Button("統計リセット") {
                            loc.resetCurrentStrategyStatistics()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Spacer()
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
                    Text("バックグラウンド追跡")
                    Spacer()
                    Text(backgroundTrackingStatusText)
                        .foregroundColor(backgroundTrackingStatusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("動作について")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                    
                    Text("• 取得方式により動作が異なります")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("• Standard: フォアグラウンド1Hz、バックグラウンド5m間隔")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("• Significant: アプリキル後も継続、500m〜数km間隔")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("• Region: 100m地域の出入りで更新、電源OFF後も可能")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("• データ保存: 最大100件まで")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // システム制御
                if loc.authorizationStatus == .authorizedAlways && loc.recoveryAttempts > 0 {
                    HStack {
                        Button("状態リセット") {
                            loc.clearErrors()
                            loc.clearRecoveryLog()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Spacer()
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
    
    private var backgroundTrackingStatusText: String {
        if loc.authorizationStatus == .authorizedAlways {
            if loc.isBackgroundLocationEnabled && (loc.isSignificantLocationChangesEnabled || loc.isRegionMonitoringEnabled) {
                return "有効"
            } else {
                return "設定中"
            }
        } else {
            return "無効"
        }
    }
    
    private var backgroundTrackingStatusColor: Color {
        if loc.authorizationStatus == .authorizedAlways {
            if loc.isBackgroundLocationEnabled && (loc.isSignificantLocationChangesEnabled || loc.isRegionMonitoringEnabled) {
                return .green
            } else {
                return .orange
            }
        } else {
            return .red
        }
    }
    
    private func getCurrentStrategyDescription() -> String? {
        switch loc.currentStrategyType {
        case .significantLocationChanges:
            return "大幅な位置変更時のみ更新。省電力だが低頻度（通常500m〜数km移動で更新）。アプリキル後・電源OFF後も継続。"
        case .standardLocationUpdates:
            return "5m移動ごとに更新。高精度だが電力消費大。バックグラウンド5m間隔、アプリキル後は停止。"
        case .regionMonitoring:
            return "100m地域の出入りで更新。中程度の精度と電力消費。アプリキル後・電源OFF後も継続可能。"
        }
    }
    
    private func batteryUsageColor(_ usage: StrategyStatistics.BatteryUsageLevel) -> Color {
        switch usage {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high, .veryHigh:
            return .red
        }
    }
}

#Preview {
    MainView()
}
