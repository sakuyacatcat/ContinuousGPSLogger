//
//  BackgroundStatusView.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import SwiftUI
import CoreLocation

struct BackgroundStatusView: View {
    @ObservedObject var locationService: LocationService
    
    var body: some View {
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
            if locationService.authorizationStatus == .authorizedAlways && locationService.recoveryAttempts > 0 {
                HStack {
                    Button("状態リセット") {
                        locationService.clearErrors()
                        locationService.clearRecoveryLog()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var backgroundTrackingStatusText: String {
        if locationService.authorizationStatus == .authorizedAlways {
            if locationService.isBackgroundLocationEnabled && (locationService.isSignificantLocationChangesEnabled || locationService.isRegionMonitoringEnabled) {
                return "有効"
            } else {
                return "設定中"
            }
        } else {
            return "無効"
        }
    }
    
    private var backgroundTrackingStatusColor: Color {
        if locationService.authorizationStatus == .authorizedAlways {
            if locationService.isBackgroundLocationEnabled && (locationService.isSignificantLocationChangesEnabled || locationService.isRegionMonitoringEnabled) {
                return .green
            } else {
                return .orange
            }
        } else {
            return .red
        }
    }
}

#Preview {
    Form {
        BackgroundStatusView(locationService: LocationService.shared)
    }
}