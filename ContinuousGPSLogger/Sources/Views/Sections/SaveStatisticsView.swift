//
//  SaveStatisticsView.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import SwiftUI

struct SaveStatisticsView: View {
    @ObservedObject var locationService: LocationService
    
    var body: some View {
        Section("保存統計") {
            HStack {
                Text("保存件数")
                Spacer()
                Text("\(locationService.saveCount)件")
                    .foregroundColor(.green)
            }
            
            if let lastSave = locationService.lastSaveTimestamp {
                HStack {
                    Text("最終保存")
                    Spacer()
                    Text(lastSave, format: .dateTime.hour().minute().second())
                        .foregroundColor(.secondary)
                }
            }
            
            if let error = locationService.saveError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

#Preview {
    Form {
        SaveStatisticsView(locationService: LocationService.shared)
    }
}