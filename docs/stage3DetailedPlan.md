# 段階 3: 詳細実装計画 - 自動データ保存の実装

## 概要

位置更新時の自動保存機能を実装し、リアルタイムで履歴に反映されるようにする。

**実装開始日**: 2025-07-06
**実装完了日**: 2025-07-06

## TODO リスト

### 1. PersistenceService の改善（5分）

- [x] `save` メソッドの戻り値を成功/失敗で返すように変更
- [x] エラーハンドリングの改善
- [x] 成功時とエラー時の適切な戻り値設定

**変更ファイル**: `PersistenceService.swift`

### 2. LocationService の拡張（15分）

- [x] `didUpdateLocations` で位置情報を自動保存
- [x] 保存統計の Published プロパティを追加:
  - `@Published private(set) var saveCount: Int = 0`
  - `@Published private(set) var lastSaveTimestamp: Date?`
  - `@Published private(set) var saveError: String?`
- [x] 保存成功/失敗の状態管理
- [x] 保存カウントの増加処理

**変更ファイル**: `LocationService.swift`

### 3. MainView の UI 拡張（10分）

- [x] 新しい「保存統計」セクションを追加
- [x] 保存件数表示
- [x] 最新保存時刻表示
- [x] 保存エラー表示（あれば）
- [x] 適切なフォーマットとスタイリング

**変更ファイル**: `MainView.swift`

### 4. HistoryView の確認（確認のみ）

- [x] @FetchRequest による自動更新が正常に動作することを確認
- [x] 必要に応じて UI の微調整

**対象ファイル**: `HistoryView.swift`

### 5. ビルドとテスト（5分）

- [x] ビルドエラーがないことを確認
- [x] 位置更新時の自動保存動作確認
- [x] HistoryView へのリアルタイム反映確認
- [x] 保存統計表示の正確性確認

## 成功基準

✅ 位置更新時に自動的にデータが保存される  
✅ 保存件数と最新保存時刻が MainView に表示される  
✅ HistoryView にリアルタイムで新しいデータが表示される  
✅ 保存エラーが発生した場合、適切に UI に表示される  

## 推定時間: 30分

## 詳細実装メモ

### PersistenceService の改善詳細

```swift
/// 1 点保存（成功/失敗を返す）
func save(trackPoint: CLLocation) -> Bool {
    let ctx = container.viewContext
    let tp = TrackPoint(context: ctx)
    tp.id        = .init()
    tp.timestamp = trackPoint.timestamp
    tp.lat       = trackPoint.coordinate.latitude
    tp.lon       = trackPoint.coordinate.longitude
    tp.hAcc      = trackPoint.horizontalAccuracy
    tp.speed     = trackPoint.speed

    do {
        try ctx.save()
        return true
    } catch {
        print("CoreData save error", error)
        return false
    }
}
```

### LocationService の拡張詳細

```swift
@Published private(set) var saveCount: Int = 0
@Published private(set) var lastSaveTimestamp: Date?
@Published private(set) var saveError: String?

nonisolated func locationManager(_ manager: CLLocationManager,
                                 didUpdateLocations locs: [CLLocation]) {
    guard let loc = locs.last else { return }
    
    Task { @MainActor in
        self.current = loc
        self.lastError = nil
        
        // 自動保存処理
        let success = PersistenceService.shared.save(trackPoint: loc)
        if success {
            self.saveCount += 1
            self.lastSaveTimestamp = Date()
            self.saveError = nil
        } else {
            self.saveError = "データの保存に失敗しました"
        }
    }
}
```

### MainView の UI 拡張詳細

```swift
Section("保存統計") {
    HStack {
        Text("保存件数")
        Spacer()
        Text("\(loc.saveCount)件")
            .foregroundColor(.green)
    }
    
    if let lastSave = loc.lastSaveTimestamp {
        HStack {
            Text("最終保存")
            Spacer()
            Text(lastSave, format: .dateTime.hour().minute().second())
                .foregroundColor(.secondary)
        }
    }
    
    if let error = loc.saveError {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text(error)
                .foregroundColor(.red)
        }
    }
}
```

## 実装順序

1. **PersistenceService の改善** (5分)
   - save メソッドの戻り値を Bool に変更
   - エラーハンドリングの改善

2. **LocationService の拡張** (15分)
   - 新しい Published プロパティを追加
   - didUpdateLocations で自動保存ロジックを実装

3. **MainView の UI 拡張** (10分)
   - 保存統計セクションを追加
   - 統計情報の表示ロジックを実装

4. **ビルド・テスト** (5分)
   - 機能テストと UI テスト
   - エラー修正

## 次のステップ

この段階完了後、段階 4「バックグラウンド対応」に進む。