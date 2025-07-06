# 段階 5: 詳細実装計画 - バックグラウンド対応

## 概要

アプリ終了後も位置追跡を継続するためのバックグラウンド対応機能を実装する。

**実装開始日**: 2025-07-06  
**推定所要時間**: 45分

## TODO リスト

### 1. LocationService のバックグラウンド対応（20分）

- [ ] `allowsBackgroundLocationUpdates = true` 設定の追加
- [ ] `startMonitoringSignificantLocationChanges()` の実装
- [ ] バックグラウンド状態の追跡機能
- [ ] アプリライフサイクルイベントの処理
- [ ] エラーハンドリングの改善

**変更ファイル**: `LocationService.swift`

### 2. MainView のバックグラウンド状態表示（15分）

- [ ] バックグラウンド位置追跡状態の表示セクション
- [ ] 重要な位置変更の監視状態表示
- [ ] 最後のバックグラウンド更新時刻の表示
- [ ] UIレイアウトの調整

**変更ファイル**: `MainView.swift`

### 3. アプリライフサイクル管理（10分）

- [ ] アプリがバックグラウンドに移行する時の処理
- [ ] アプリがフォアグラウンドに復帰する時の処理
- [ ] 状態同期とデータ更新

**変更ファイル**: `LocationService.swift`

### 4. テスト・検証（10分）

- [ ] バックグラウンド位置更新のテスト
- [ ] アプリ終了・復帰のテスト
- [ ] 重要な位置変更の動作確認
- [ ] データ保存の確認

## 成功基準

✅ アプリ終了後も位置追跡が継続される  
✅ アプリ復帰時に新しい位置データが保存されている  
✅ UI にバックグラウンド動作状態が表示される  
✅ 重要な位置変更が適切に検出される  
✅ バックグラウンド動作が安定している  

## 詳細実装メモ

### LocationService の拡張詳細

```swift
extension LocationService {
    // バックグラウンド状態の追跡
    @Published private(set) var isBackgroundLocationEnabled: Bool = false
    @Published private(set) var isSignificantLocationChangesEnabled: Bool = false
    @Published private(set) var lastBackgroundUpdate: Date?
    
    /// バックグラウンド位置更新の設定
    private func enableBackgroundLocationUpdates() {
        guard authorizationStatus == .authorizedAlways else { return }
        
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        isBackgroundLocationEnabled = true
    }
    
    /// 重要な位置変更の監視開始
    func startMonitoringSignificantLocationChanges() {
        guard authorizationStatus == .authorizedAlways else { return }
        
        manager.startMonitoringSignificantLocationChanges()
        isSignificantLocationChangesEnabled = true
    }
    
    /// 重要な位置変更の監視停止
    func stopMonitoringSignificantLocationChanges() {
        manager.stopMonitoringSignificantLocationChanges()
        isSignificantLocationChangesEnabled = false
    }
    
    /// アプリライフサイクルイベントの処理
    func handleAppDidEnterBackground() {
        // バックグラウンド移行時の処理
        enableBackgroundLocationUpdates()
        startMonitoringSignificantLocationChanges()
    }
    
    func handleAppWillEnterForeground() {
        // フォアグラウンド復帰時の処理
        // 状態同期とデータ更新
        lastBackgroundUpdate = Date()
    }
}
```

### MainView の拡張詳細

```swift
// バックグラウンド状態セクションの追加
Section("バックグラウンド状態") {
    HStack {
        Text("バックグラウンド位置更新")
        Spacer()
        Text(loc.isBackgroundLocationEnabled ? "有効" : "無効")
            .foregroundColor(loc.isBackgroundLocationEnabled ? .green : .gray)
    }
    
    HStack {
        Text("重要な位置変更の監視")
        Spacer()
        Text(loc.isSignificantLocationChangesEnabled ? "監視中" : "停止中")
            .foregroundColor(loc.isSignificantLocationChangesEnabled ? .green : .gray)
    }
    
    if let lastUpdate = loc.lastBackgroundUpdate {
        HStack {
            Text("最後のバックグラウンド更新")
            Spacer()
            Text(lastUpdate, format: .dateTime.hour().minute().second())
                .foregroundColor(.secondary)
        }
    }
}
```

### アプリライフサイクル管理の詳細

```swift
// ContinuousGPSLoggerApp.swift に追加
struct ContinuousGPSLoggerApp: App {
    var body: some Scene {
        WindowGroup {
            // 既存のコード
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            LocationService.shared.handleAppDidEnterBackground()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            LocationService.shared.handleAppWillEnterForeground()
        }
    }
}
```

## 実装順序

1. **LocationService のバックグラウンド対応** (20分)
   - バックグラウンド位置更新の設定
   - 重要な位置変更の監視機能
   - 状態追跡プロパティの追加

2. **MainView の状態表示** (15分)
   - バックグラウンド状態セクションの追加
   - UI レイアウトの調整

3. **アプリライフサイクル管理** (10分)
   - アプリライフサイクルイベントの処理
   - 状態同期機能

4. **テスト・検証** (10分)
   - 機能テストと統合テスト
   - エラー修正

## 注意事項

- `allowsBackgroundLocationUpdates = true` は `authorizedAlways` 権限が必要
- 重要な位置変更は電池消費を抑えるため、大幅な位置変更時のみ発火
- バックグラウンド位置更新は iOS の省電力機能の影響を受ける
- 実機でのテストが必要（シミュレーターでは正確な動作確認不可）

## 次のステップ

この段階完了後、アプリの基本機能は完成。実機テストと最適化に進む。