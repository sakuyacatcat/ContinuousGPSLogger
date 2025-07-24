//
//  StatusIndicatorView.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import SwiftUI

struct StatusIndicatorView: View {
    let label: String
    let status: String
    let statusColor: Color
    let showProgressIndicator: Bool
    
    init(label: String, status: String, statusColor: Color, showProgressIndicator: Bool = false) {
        self.label = label
        self.status = status
        self.statusColor = statusColor
        self.showProgressIndicator = showProgressIndicator
    }
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            
            if showProgressIndicator {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(status)
                        .foregroundColor(statusColor)
                }
            } else {
                Text(status)
                    .foregroundColor(statusColor)
            }
        }
    }
}

#Preview {
    Form {
        Section("Status Examples") {
            StatusIndicatorView(
                label: "位置情報権限",
                status: "常に許可",
                statusColor: .green
            )
            
            StatusIndicatorView(
                label: "位置取得状態",
                status: "取得中",
                statusColor: .green
            )
            
            StatusIndicatorView(
                label: "バックグラウンド追跡",
                status: "有効",
                statusColor: .green
            )
            
            StatusIndicatorView(
                label: "権限要求",
                status: "要求中…",
                statusColor: .secondary,
                showProgressIndicator: true
            )
        }
    }
}