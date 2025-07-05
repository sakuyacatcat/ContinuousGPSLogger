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
            VStack(alignment: .leading) {
                Text(p.timestamp ?? Date(), style: .time)
                Text("\(p.lat), \(p.lon)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("履歴")
    }
}

#Preview {
    HistoryView().environment(\.managedObjectContext, PersistenceService.shared.container.viewContext)
}
