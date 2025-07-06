# 段階 2: 詳細実装計画 - 権限管理の改善 ✅

## 概要

Always 権限要求と UI 連動を実装し、ユーザーが適切に権限設定できるようにする。

**実装完了日**: 2025-07-06

## TODO リスト

### 1. LocationService の拡張（15分） ✅

- [x] `requestWhenInUseAuthorization()` を `requestAlwaysAuthorization()` に変更
- [x] Always 権限アップグレード用メソッド `requestAlwaysPermission()` を追加
- [x] 設定画面を開く `openSettings()` メソッドを追加
- [x] 権限アップグレードが必要かを判断する `needsAlwaysPermission` プロパティを追加
- [x] 権限要求状態を追跡する `@Published var permissionRequestInProgress: Bool` を追加
- [x] `didChangeAuthorization` で Always 権限への案内ロジックを追加

**変更ファイル**: `LocationService.swift` ✅

### 2. MainView の権限 UI 改善（10分） ✅

- [x] 権限状態セクションに詳細説明を追加
- [x] "Always 権限をリクエスト" ボタンを追加（WhenInUse 時）
- [x] "設定を開く" ボタンを追加（拒否時）
- [x] 権限状態に応じたガイダンステキストを追加
- [x] 権限要求中の進行状況表示を追加
- [x] 背景 GPS 追跡の必要性説明を追加

**変更ファイル**: `MainView.swift` ✅

### 3. 権限ガイダンスコンポーネント（5分） ✅

- [x] `PermissionGuidanceView` コンポーネントを作成
- [x] 各権限状態での説明テキストを定義
- [x] アクションボタンのスタイリングを統一
- [x] 視覚的なインジケーター（アイコン、色）を追加

**新規ファイル**: `PermissionGuidanceView.swift` ✅

### 4. ビルドとテスト（5分） ✅

- [x] ビルドエラーがないことを確認
- [x] 権限要求フローの動作確認
- [x] 設定画面への遷移確認
- [x] UI 状態変更の動作確認

## 成功基準

✅ Always 権限が適切に要求される  
✅ WhenInUse から Always への移行フローが動作する  
✅ 権限拒否時に設定画面への案内が表示される  
✅ 権限状態に応じた適切なガイダンスが表示される  
✅ UI がリアルタイムで権限状態を反映する  

## 推定時間: 30分

## 詳細実装メモ

### LocationService の拡張詳細

```swift
@Published private(set) var needsAlwaysPermission: Bool = false
@Published private(set) var permissionRequestInProgress: Bool = false

func requestAlwaysPermission() {
    permissionRequestInProgress = true
    manager.requestAlwaysAuthorization()
}

func openSettings() {
    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(settingsUrl)
    }
}

var needsAlwaysPermission: Bool {
    return authorizationStatus == .authorizedWhenInUse
}
```

### MainView の改善詳細

```swift
// 権限状態に応じたアクションボタン
if loc.authorizationStatus == .authorizedWhenInUse {
    Button("Always 権限をリクエスト") {
        loc.requestAlwaysPermission()
    }
    .buttonStyle(.borderedProminent)
} else if loc.authorizationStatus == .denied {
    Button("設定を開く") {
        loc.openSettings()
    }
    .buttonStyle(.bordered)
}

// ガイダンステキスト
Text("バックグラウンドでの GPS 追跡には Always 権限が必要です")
    .font(.caption)
    .foregroundStyle(.secondary)
```

### PermissionGuidanceView の詳細

```swift
struct PermissionGuidanceView: View {
    let status: CLAuthorizationStatus
    let onRequestAlways: () -> Void
    let onOpenSettings: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                Text(titleText)
                    .font(.headline)
            }
            
            Text(descriptionText)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let action = actionButton {
                action
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
    
    // 状態に応じたアイコン、テキスト、アクションの計算プロパティ
}
```

## 実装順序

1. **LocationService の拡張** (15分)
   - 新しいプロパティとメソッドを追加
   - 権限フローロジックを更新

2. **MainView の UI 改善** (10分)
   - 権限関連の UI コンポーネントを追加
   - 状態に応じた表示ロジックを実装

3. **PermissionGuidanceView の作成** (5分)
   - 再利用可能なコンポーネントとして作成
   - 統一されたスタイリングを適用

4. **ビルド・テスト** (5分)
   - 機能テストと UI テスト
   - エラー修正

## 次のステップ

この段階完了後、段階 3「自動データ保存の実装」に進む。