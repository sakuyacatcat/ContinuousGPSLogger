# 段階 5: 詳細実装計画 - 履歴制限と最適化

## 概要

HistoryViewの100件制限、データ使用量表示、手動削除機能、自動削除機能、パフォーマンス最適化を実装する。

**実装開始日**: 2025-07-06  
**実装完了日**: 2025-07-06

## TODO リスト

### 1. HistoryView の改善（15分）

- [x] @FetchRequest に fetchLimit: 100 を追加（計算プロパティで実装）
- [x] データ件数・使用量表示セクションを追加
- [x] 手動削除機能のボタン追加（全削除、古いデータ削除）
- [x] 削除確認ダイアログの実装
- [x] UI レイアウトの調整

**変更ファイル**: `HistoryView.swift`

### 2. PersistenceService の拡張（10分）

- [x] 全データ削除メソッド `deleteAll()` の追加
- [x] データ統計取得メソッドの追加:
  - `getTotalCount() -> Int`
  - `getOldestRecord() -> TrackPoint?`
  - `getNewestRecord() -> TrackPoint?`
- [x] エラーハンドリングの改善

**変更ファイル**: `PersistenceService.swift`

### 3. LocationService の最適化（10分）

- [x] 定期的な古いデータ削除の実装
- [x] 保存時のデータ件数チェック機能
- [x] 自動削除のタイミング調整

**変更ファイル**: `LocationService.swift`

### 4. 段階順序の変更（5分）

- [x] docs/stagedImplementationPlan.md で段階4と5を入れ替え
- [x] Stage 5を先に実装してからStage 4（バックグラウンド対応）に進む

**変更ファイル**: `docs/stagedImplementationPlan.md`

### 5. ビルドとテスト（5分）

- [x] ビルドエラーがないことを確認
- [x] 100件制限の動作確認
- [x] 削除機能の動作確認
- [x] データ統計表示の正確性確認
- [x] パフォーマンス確認

## 成功基準

✅ HistoryViewに100件制限が適用される  
✅ データ使用量と統計が表示される  
✅ 手動削除機能（全削除、古いデータ削除）が動作する  
✅ 削除時に確認ダイアログが表示される  
✅ 大量データでも快適に動作する  

## 推定時間: 40分

## 詳細実装メモ

### HistoryView の改善詳細

```swift
struct HistoryView: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.timestamp, order: .reverse)],
        fetchLimit: 100,
        animation: .default
    )
    private var points: FetchedResults<TrackPoint>
    
    @State private var showDeleteAllAlert = false
    @State private var showDeleteOldAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                // データ統計セクション
                Section("データ統計") {
                    VStack {
                        HStack {
                            Text("表示件数")
                            Spacer()
                            Text("\(points.count)/100件")
                        }
                        
                        HStack {
                            Text("総データ数")
                            Spacer()
                            Text("\(PersistenceService.shared.getTotalCount())件")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 削除機能セクション
                Section("データ管理") {
                    HStack {
                        Button("古いデータ削除") {
                            showDeleteOldAlert = true
                        }
                        .foregroundColor(.orange)
                        
                        Spacer()
                        
                        Button("全データ削除") {
                            showDeleteAllAlert = true
                        }
                        .foregroundColor(.red)
                    }
                    .padding()
                }
                
                // 履歴リスト
                List(points) { p in
                    // 既存のリストアイテム
                }
            }
        }
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
```

### PersistenceService の拡張詳細

```swift
extension PersistenceService {
    /// 全データ削除
    func deleteAll() {
        let context = container.viewContext
        let request = TrackPoint.fetchRequest()
        
        do {
            let points = try context.fetch(request)
            for point in points {
                context.delete(point)
            }
            try context.save()
        } catch {
            print("全データ削除エラー:", error)
        }
    }
    
    /// 総データ数取得
    func getTotalCount() -> Int {
        let context = container.viewContext
        let request = TrackPoint.fetchRequest()
        
        do {
            return try context.count(for: request)
        } catch {
            print("データ数取得エラー:", error)
            return 0
        }
    }
    
    /// 最古データ取得
    func getOldestRecord() -> TrackPoint? {
        let context = container.viewContext
        let request = TrackPoint.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("最古データ取得エラー:", error)
            return nil
        }
    }
    
    /// 最新データ取得
    func getNewestRecord() -> TrackPoint? {
        let context = container.viewContext
        let request = TrackPoint.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("最新データ取得エラー:", error)
            return nil
        }
    }
}
```

### LocationService の最適化詳細

```swift
extension LocationService {
    /// 保存時のデータ管理
    private func manageDataAfterSave() {
        let totalCount = PersistenceService.shared.getTotalCount()
        
        // 1000件を超えたら古いデータを削除
        if totalCount > 1000 {
            PersistenceService.shared.purge(olderThan: 30)
        }
        
        // 一定間隔で自動削除（例：100件保存ごと）
        if saveCount % 100 == 0 {
            PersistenceService.shared.purge(olderThan: 7)
        }
    }
}
```

## 実装順序

1. **PersistenceService の拡張** (10分)
   - 削除メソッドと統計メソッドを追加
   - エラーハンドリングの改善

2. **HistoryView の改善** (15分)
   - fetchLimit の追加
   - データ統計セクションの追加
   - 削除機能とダイアログの実装

3. **LocationService の最適化** (10分)
   - 定期的なデータクリーンアップ機能の追加

4. **段階順序の変更** (5分)
   - stagedImplementationPlan.md の更新

5. **ビルド・テスト** (5分)
   - 機能テストと統合テスト
   - エラー修正

## 次のステップ

この段階完了後、段階 4「バックグラウンド対応」に進む。