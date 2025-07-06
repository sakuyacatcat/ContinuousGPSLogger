//
//  ContentView.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/03.
//

import SwiftUI

struct HistoryView: View {
    // CoreData の @FetchRequest を活用
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.timestamp, order: .reverse)],
        animation: .default
    )
    private var points: FetchedResults<TrackPoint>

    var body: some View {
        List(points) { p in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(p.timestamp ?? Date(), format: .dateTime.month().day().hour().minute().second())
                        .font(.headline)
                    Spacer()
                    Text("#\(p.id?.uuidString.prefix(8) ?? "unknown")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("緯度")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(p.lat, specifier: "%.6f")")
                            .font(.caption)
                            .monospaced()
                    }
                    
                    HStack {
                        Text("経度")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(p.lon, specifier: "%.6f")")
                            .font(.caption)
                            .monospaced()
                    }
                    
                    HStack {
                        if p.hAcc > 0 {
                            HStack {
                                Text("精度")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(p.hAcc, specifier: "%.1f")m")
                                    .font(.caption)
                            }
                        }
                        
                        Spacer()
                        
                        if p.speed >= 0 {
                            HStack {
                                Text("速度")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(p.speed * 3.6, specifier: "%.1f")km/h")
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemGray6))
                    .opacity(0.5)
            )
        }
        .navigationTitle("履歴")
    }
}

#Preview {
    HistoryView().environment(\.managedObjectContext, PersistenceService.shared.container.viewContext)
}
