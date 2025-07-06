# 段階 1: 詳細実装計画 - UI 改善と動作確認

## 概要

現在のコードの動作確認と UI 改善を行い、段階的開発の基盤を作る。

## TODO リスト

### 1. LocationService の拡張（15分） ✅ 完了

- [x] 権限状態を追跡する `@Published var authorizationStatus: CLAuthorizationStatus` を追加
- [x] 位置取得状態を追跡する `@Published var isTracking: Bool` を追加
- [x] エラー状態を追跡する `@Published var lastError: String?` を追加
- [x] `CLLocationManagerDelegate` の `didChangeAuthorization` メソッドを実装

**変更ファイル**: `LocationService.swift` ✅

### 2. MainView の改善（10分） ✅ 完了

- [x] 権限状態表示（未許可/許可済み/拒否）を追加
- [x] 位置取得状態表示（取得中/停止中）を追加
- [x] 精度情報表示（horizontalAccuracy）を追加
- [x] エラー状態表示（権限エラー、位置取得エラー）を追加
- [x] より見やすいレイアウト（VStack → Form or GroupBox）に改善

**変更ファイル**: `MainView.swift` ✅

### 3. HistoryView の改善（10分） ✅ 完了

- [x] 時刻フォーマット改善（日時 + 時刻表示）
- [x] 座標表示の精度向上（小数点以下桁数調整）
- [x] 精度情報表示（hAcc, speed）を追加
- [x] より見やすいレイアウト（カード形式）に改善

**変更ファイル**: `HistoryView.swift` ✅

### 4. ビルドとテスト（5分） ✅ 完了

- [x] ビルドエラーがないことを確認
- [x] シミュレーターで UI が正常に表示されることを確認
- [x] 権限要求ダイアログが表示されることを確認
- [x] 位置情報が取得・表示されることを確認

## 成功基準

✅ アプリが正常にビルドされる  
✅ 位置情報が画面に表示される  
✅ 権限状態が適切に表示される  
✅ エラー状態が適切に表示される  
✅ 履歴画面の見た目が改善される  

## 推定時間: 30分 ✅ 完了

**完了日時**: 2025-07-06  
**実装済み**: 全ての TODO アイテムが完了しました。

## 詳細実装メモ

### LocationService の拡張詳細

```swift
@Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
@Published private(set) var isTracking: Bool = false
@Published private(set) var lastError: String?

func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    authorizationStatus = status
    // 権限に応じた処理
}
```

### MainView の改善詳細

```swift
// 権限状態表示
switch loc.authorizationStatus {
case .notDetermined: "権限未設定"
case .authorizedWhenInUse: "使用中のみ許可"
case .authorizedAlways: "常に許可"
case .denied: "権限拒否"
// ...
}

// 精度情報表示
if let accuracy = loc.current?.horizontalAccuracy {
    Text("精度: \(accuracy, specifier: "%.1f")m")
}
```

### HistoryView の改善詳細

```swift
// 時刻フォーマット
Text(p.timestamp ?? Date(), format: .dateTime.month().day().hour().minute())

// 精度情報
if let hAcc = p.hAcc, hAcc > 0 {
    Text("精度: \(hAcc, specifier: "%.1f")m")
}
```

## 次のステップ

この段階完了後、段階 2「権限管理の改善」に進む。

## 実装完了サマリー

### LocationService の拡張
- `authorizationStatus`, `isTracking`, `lastError` プロパティを追加
- `didChangeAuthorization` デリゲートメソッドを実装
- `didFailWithError` デリゲートメソッドを追加
- `startTracking()` / `stopTracking()` メソッドを追加

### MainView の改善
- Form ベースのレイアウトに変更
- 権限状態・位置取得状態・精度情報・エラー状態表示を実装
- カラーコード化された状態表示

### HistoryView の改善
- 詳細な時刻フォーマット（月日時分秒）
- 座標表示精度向上（小数点以下6桁）
- 精度・速度情報表示
- カード風のレイアウト・背景色

### ビルド・テスト
- iOS シミュレーター向けビルド成功
- 全機能の動作確認完了

**段階 1 完了 ✅**