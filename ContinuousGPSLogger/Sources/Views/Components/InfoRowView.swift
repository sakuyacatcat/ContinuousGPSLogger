//
//  InfoRowView.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import SwiftUI

struct InfoRowView: View {
    let label: String
    let value: String
    let valueColor: Color?
    
    init(label: String, value: String, valueColor: Color? = nil) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
        }
    }
}

#Preview {
    Form {
        Section("Location Info") {
            InfoRowView(label: "緯度", value: "35.681236")
            InfoRowView(label: "経度", value: "139.767125")
            InfoRowView(label: "精度", value: "5.0m")
            InfoRowView(label: "保存件数", value: "142件", valueColor: .green)
            InfoRowView(label: "最終更新", value: "14:32:45", valueColor: .secondary)
        }
    }
}