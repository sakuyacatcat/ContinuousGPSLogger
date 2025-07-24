//
//  GPSStrategyPickerView.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import SwiftUI
import CoreLocation

struct GPSStrategyPickerView: View {
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        Section("GPS取得方式") {
            VStack(alignment: .leading, spacing: 12) {
                // Strategy選択
                Picker("取得方式", selection: Binding(
                    get: { locationService.currentStrategyType },
                    set: { locationService.changeStrategy(to: $0) }
                )) {
                    ForEach(locationService.availableStrategies, id: \.self) { strategy in
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
                if let stats = locationService.getCurrentStrategyStatistics() {
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
                        locationService.resetCurrentStrategyStatistics()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func getCurrentStrategyDescription() -> String? {
        switch locationService.currentStrategyType {
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
    Form {
        GPSStrategyPickerView(locationService: LocationService.shared)
    }
}