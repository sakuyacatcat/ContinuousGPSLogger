# ContinuousGPSLogger ドキュメント

このディレクトリには、ContinuousGPSLogger アプリケーションの詳細仕様書が含まれています。

## 📋 ドキュメント一覧

### 🏗️ アプリケーション仕様

- **[application-spec.md](./application-spec.md)** - アプリケーション全体の仕様書
  - 概要・機能・システム要件
  - アーキテクチャ・デザインパターン
  - セキュリティ・パフォーマンス仕様

### 🛰️ GPS 戦略仕様

- **[gps-strategy-spec.md](./gps-strategy-spec.md)** - GPS 取得戦略の詳細仕様
  - 3 つの戦略の動作仕様
  - フォアグラウンド・バックグラウンド・アプリキル後の動作
  - 戦略切り替え・パラメータ設定

### 📊 システム構成図・シーケンス図

- **[system-architecture-diagrams.md](./system-architecture-diagrams.md)** - システム構成とデータフロー
  - システム全体構成図
  - Strategy Pattern 詳細構成図
  - データフロー図
  - 各種シーケンス図（起動・切り替え・復旧・エラー処理）
  - 状態遷移図

### 🧪 テスト・確認手順

- **[testing-verification-guide.md](./testing-verification-guide.md)** - 動作確認とテスト手順
  - 基本機能の確認方法
  - 各戦略別のテスト手順
  - エラーケース・パフォーマンステスト
  - トラブルシューティング

### ⚠️ 技術制限・実装詳細

- **[technical-limitations-spec.md](./technical-limitations-spec.md)** - 技術制限と実装詳細
  - iOS システム制限
  - アプリ固有の制約
  - パフォーマンス制限・既知の問題

## 🎯 GPS 取得戦略 クイックリファレンス

| 戦略            | 適用場面                 | アプリキル後 | 電源 OFF 後 | 更新頻度            |
| --------------- | ------------------------ | ------------ | ----------- | ------------------- |
| **Standard**    | 開発・テスト・短時間追跡 | ❌ 停止      | ❌ 停止     | 最高（1Hz）         |
| **Significant** | 長距離移動・長期監視     | ✅ 継続      | ✅ 継続     | 最低（500m〜数 km） |
| **Region**      | 中距離移動・バランス重視 | ✅ 継続      | ⚠️ 条件付き | 中（100m 間隔）     |

## 🔍 状況別推奨戦略

### 用途別推奨

- **徒歩・ジョギング** → Region Monitoring
- **自転車・バイク** → Region Monitoring または Standard
- **自動車・電車** → Significant Location Changes
- **開発・テスト** → Standard Location Updates
- **長期監視** → Significant Location Changes

### 要件別推奨

- **高精度重視** → Standard Location Updates
- **電力効率重視** → Significant Location Changes
- **継続性重視** → Significant Location Changes
- **バランス重視** → Region Monitoring

## 📱 動作確認の流れ

### 1. 事前準備

```
設定 > プライバシーとセキュリティ > 位置情報サービス > オン
設定 > 一般 > Backgroundアプリの更新 > ContinuousGPSLogger > オン
低電力モード > オフ（テスト時）
```

### 2. 基本動作確認

1. アプリ起動・Always 権限設定
2. 各戦略での位置取得確認
3. 戦略切り替えテスト
4. バックグラウンド・アプリキル後テスト

### 3. 詳細確認

詳しい手順は [testing-verification-guide.md](./testing-verification-guide.md) を参照

## 🚨 よくある問題と対処法

### 位置情報が取得できない

1. 屋外に移動して GPS 信号を改善
2. Always 権限の設定確認
3. WiFi 環境での位置精度向上

### バックグラウンドで動作しない

1. Background App Refresh 設定確認
2. Significant または Region 戦略を使用
3. Always 権限が必要

### アプリキル後に復旧しない

1. Significant または Region 戦略を使用
2. システム再起動試行
3. 位置情報サービス設定確認

## 📊 パフォーマンス指標

### 電力消費（相対値）

- Standard: 100%（基準）
- Region: 30-50%
- Significant: 5-10%

### メモリ使用量

- 基本動作: 約 10-20MB
- データ 100 件時: 約 25MB
- Strategy 切り替え時: 一時的に+5MB

### CPU 使用率

- フォアグラウンド時: 1-3%
- バックグラウンド時: 0.1-1%

## 🔗 関連ドキュメント

### 既存ドキュメント

- **[GPS_Sequence_Diagrams.md](../GPS_Sequence_Diagrams.md)** - GPS 取得プロセスのシーケンス図
- **[README.md](../README.md)** - プロジェクト概要
- **[DEVELOPMENT.md](../DEVELOPMENT.md)** - 開発関連情報

### 設計ドキュメント

- **[stagedImplementationPlan.md](./stagedImplementationPlan.md)** - 段階的実装計画
- **[updatePlanForHighFrequencyGPSLogging.md](./updatePlanForHighFrequencyGPSLogging.md)** - 高頻度 GPS 対応計画

## 📝 ドキュメント更新履歴

- 2025-07-14: 初回作成
  - アプリケーション仕様書
  - GPS 戦略詳細仕様
  - システム構成図・シーケンス図
  - テスト・確認手順書
  - 技術制限・実装詳細仕様

## 🤝 貢献・フィードバック

ドキュメントの改善や追加情報があれば、以下の方法でご連絡ください：

- Issue 作成
- Pull Request
- 直接フィードバック

---

**注意**: このドキュメントはアプリのバージョン v1.0 時点の情報です。アプリの更新に伴い、仕様が変更される場合があります。
