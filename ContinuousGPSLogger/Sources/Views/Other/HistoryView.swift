//
//  ContentView.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/03.
//

import SwiftUI

struct HistoryView: View {
    // CoreData の @FetchRequest を活用（100件制限）
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.timestamp, order: .reverse)],
        animation: .default
    )
    private var allPoints: FetchedResults<TrackPoint>
    
    // 100件制限のための計算プロパティ
    private var points: Array<TrackPoint> {
        Array(allPoints.prefix(100))
    }
    
    @State private var showDeleteAllAlert = false
    @State private var showDeleteOldAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // データ統計セクション
            VStack(alignment: .leading, spacing: 8) {
                Text("データ統計")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    Text("表示件数")
                    Spacer()
                    Text("\(points.count)/100件")
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("総データ数")
                    Spacer()
                    Text("\(allPoints.count)件")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top)
            
            // 削除機能セクション
            HStack(spacing: 16) {
                Button("古いデータ削除") {
                    showDeleteOldAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.orange)
                
                Spacer()
                
                Button("全データ削除") {
                    showDeleteAllAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            .padding()
            
            // 履歴リスト
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
        }
        .navigationTitle("履歴")
        .alert("古いデータ削除", isPresented: $showDeleteOldAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                PersistenceService.shared.purge()
            }
        } message: {
            Text("30日以上前のデータを削除しますか？")
        }
        .alert("全データ削除", isPresented: $showDeleteAllAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                PersistenceService.shared.deleteAll()
            }
        } message: {
            Text("全ての履歴データを削除しますか？この操作は取り消せません。")
        }
    }
}

#Preview {
    HistoryView().environment(\.managedObjectContext, PersistenceService.shared.container.viewContext)
}
