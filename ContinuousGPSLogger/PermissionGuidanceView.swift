//
//  PermissionGuidanceView.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/06.
//

import SwiftUI
import CoreLocation

struct PermissionGuidanceView: View {
    let status: CLAuthorizationStatus
    let onRequestAlways: () -> Void
    let onOpenSettings: () -> Void
    let isRequestInProgress: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                Text(titleText)
                    .font(.headline)
                    .foregroundColor(iconColor)
            }
            
            Text(descriptionText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
            
            actionButton
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
    
    private var iconName: String {
        switch status {
        case .notDetermined:
            return "location.circle"
        case .denied, .restricted:
            return "location.slash"
        case .authorizedWhenInUse:
            return "location.circle.fill"
        case .authorizedAlways:
            return "location.fill"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    private var iconColor: Color {
        switch status {
        case .authorizedAlways:
            return .green
        case .authorizedWhenInUse:
            return .orange
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .blue
        @unknown default:
            return .gray
        }
    }
    
    private var titleText: String {
        switch status {
        case .notDetermined:
            return "位置情報の許可が必要"
        case .denied:
            return "位置情報が拒否されています"
        case .restricted:
            return "位置情報が制限されています"
        case .authorizedWhenInUse:
            return "Always権限が必要"
        case .authorizedAlways:
            return "位置情報の利用許可済み"
        @unknown default:
            return "不明な権限状態"
        }
    }
    
    private var descriptionText: String {
        switch status {
        case .notDetermined:
            return "位置情報の利用許可をお願いします。バックグラウンドでのGPS追跡にはAlways権限が必要です。"
        case .denied:
            return "位置情報の利用が拒否されています。設定から位置情報の利用を許可してください。"
        case .restricted:
            return "位置情報の利用が制限されています。デバイスの設定を確認してください。"
        case .authorizedWhenInUse:
            return "現在は使用中のみ許可されています。バックグラウンドでのGPS追跡にはAlways権限が必要です。"
        case .authorizedAlways:
            return "位置情報の利用が許可されています。バックグラウンドでのGPS追跡が可能です。"
        @unknown default:
            return "不明な権限状態です。"
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        switch status {
        case .authorizedWhenInUse:
            Button(action: onRequestAlways) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Always権限をリクエスト")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequestInProgress)
            
        case .denied:
            Button(action: onOpenSettings) {
                HStack {
                    Image(systemName: "gear")
                    Text("設定を開く")
                }
            }
            .buttonStyle(.bordered)
            
        case .notDetermined:
            if isRequestInProgress {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("権限を要求中...")
                }
                .foregroundStyle(.secondary)
            } else {
                EmptyView()
            }
            
        case .authorizedAlways, .restricted:
            EmptyView()
            
        @unknown default:
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        PermissionGuidanceView(
            status: .notDetermined,
            onRequestAlways: {},
            onOpenSettings: {},
            isRequestInProgress: false
        )
        
        PermissionGuidanceView(
            status: .authorizedWhenInUse,
            onRequestAlways: {},
            onOpenSettings: {},
            isRequestInProgress: false
        )
        
        PermissionGuidanceView(
            status: .denied,
            onRequestAlways: {},
            onOpenSettings: {},
            isRequestInProgress: false
        )
        
        PermissionGuidanceView(
            status: .authorizedAlways,
            onRequestAlways: {},
            onOpenSettings: {},
            isRequestInProgress: false
        )
    }
    .padding()
}