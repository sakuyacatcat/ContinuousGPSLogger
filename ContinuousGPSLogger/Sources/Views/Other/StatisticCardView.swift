//
//  StatisticCardView.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import SwiftUI

struct StatisticCardView: View {
    let statistics: [(label: String, value: String, color: Color?)]
    
    init(statistics: [(label: String, value: String, color: Color?)]) {
        self.statistics = statistics
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(statistics.enumerated()), id: \.offset) { index, stat in
                HStack {
                    Text(stat.label)
                    Spacer()
                    Text(stat.value)
                        .foregroundColor(stat.color ?? .primary)
                }
            }
        }
        .font(.caption)
        .padding(.horizontal, 4)
    }
}

#Preview {
    Form {
        Section("Strategy Statistics") {
            StatisticCardView(statistics: [
                ("更新回数", "25回", .blue),
                ("最終更新", "14:32:45", .secondary),
                ("精度(平均)", "8.5m", .secondary),
                ("電力消費", "中", .orange),
                ("更新頻度", "高", .secondary)
            ])
        }
    }
}