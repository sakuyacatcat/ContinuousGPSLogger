# GPS 取得戦略 詳細仕様書

## 戦略概要

ContinuousGPSLogger は 3 つの GPS 取得戦略を提供し、用途や電力消費・精度の要件に応じて選択可能です。

## 戦略比較表

| 戦略                             | 精度 | 電力消費 | フォアグラウンド | バックグラウンド | アプリキル後 | 電源 OFF 後 |
| -------------------------------- | ---- | -------- | ---------------- | ---------------- | ------------ | ----------- |
| **Standard Location Updates**    | 最高 | 最高     | 1Hz 更新         | 5m 間隔          | ❌ 停止      | ❌ 停止     |
| **Significant Location Changes** | 低   | 最低     | 500m〜数 km      | 500m〜数 km      | ✅ 継続      | ✅ 継続     |
| **Region Monitoring**            | 中   | 中       | 100m 地域監視    | 100m 地域監視    | ✅ 継続      | ✅ 継続     |

---

## 1. Standard Location Updates Strategy

### 概要

最も精密な GPS 取得方式。高頻度・高精度だが電力消費が大きく、アプリキル後は動作停止。

### 動作仕様

#### フォアグラウンド状態

- **更新頻度**: 1Hz（1 秒間隔）
- **距離フィルタ**: なし（すべての位置更新を処理）
- **精度**: kCLLocationAccuracyBest（最高精度）
- **実装**: 内部で 1 秒間隔制御、iOS 自体は制限なし

#### バックグラウンド状態

- **更新頻度**: 5m 移動ごと
- **距離フィルタ**: 5.0m
- **精度**: kCLLocationAccuracyBest
- **制限**: iOS のバックグラウンド実行時間制限（通常数分）

#### アプリキル後

- **動作**: 完全停止
- **復旧**: アプリ再起動時に自動復旧
- **データ**: キル前のデータは保持

#### 電源 OFF 後

- **動作**: 完全停止
- **復旧**: アプリ再起動時に自動復旧

### パラメータ設定

```swift
// デフォルト
distanceFilter: 5.0m (バックグラウンド時)
desiredAccuracy: kCLLocationAccuracyBest

// 高頻度版
distanceFilter: 3.0m
desiredAccuracy: kCLLocationAccuracyBest

// 省電力版
distanceFilter: 20.0m
desiredAccuracy: kCLLocationAccuracyHundredMeters
```

### 適用場面

- 開発・テスト用途
- 短時間の高精度追跡
- フォアグラウンドメインの用途

---

## 2. Significant Location Changes Strategy

### 概要

システムが大幅な位置変更を検出した際のみ更新。最も省電力でアプリキル後も継続するが、更新頻度は最も低い。

### 動作仕様

#### フォアグラウンド状態

- **更新頻度**: 500m〜数 km 移動時（システム判定）
- **距離フィルタ**: システム制御（調整不可）
- **精度**: システム依存
- **特徴**: セルタワー基地局変更が主なトリガー

#### バックグラウンド状態

- **更新頻度**: フォアグラウンドと同じ
- **制限**: なし（システムサービス）
- **持続性**: 無制限

#### アプリキル後

- **動作**: 継続動作
- **更新**: 大幅な位置変更時にアプリが起動され、位置を記録
- **復旧**: 自動（システムによるアプリ起動）

#### 電源 OFF 後

- **動作**: 電源 ON 後に継続
- **条件**: 位置サービスが有効な場合
- **復旧**: 自動

### システム判定基準（iOS 内部、概算）

- **基地局変更**: セルタワーエリア移動
- **WiFi 環境変化**: WiFi アクセスポイント圏外
- **移動距離**: 通常 500m 以上の移動
- **時間経過**: 長時間同一場所後の移動

### 適用場面

- 長期間の移動追跡
- 電力消費を最小限に抑えたい場合
- アプリキル・電源 OFF 後も確実に継続したい場合

---

## 3. Region Monitoring Strategy

### 概要

指定した地理的領域の出入りを監視。中程度の電力消費・精度で、アプリキル後も継続可能。

### 動作仕様

#### フォアグラウンド状態

- **更新頻度**: 100m 半径地域の出入り時
- **精度**: 地域境界付近では高精度、遠い場合は低精度
- **動作**: 現在地中心に 100m 半径の円形地域を設定

#### バックグラウンド状態

- **更新頻度**: フォアグラウンドと同じ
- **持続性**: 無制限（システムサービス）
- **制限**: 同時監視可能地域数に制限（通常 20 地域まで）

#### アプリキル後

- **動作**: 継続動作
- **更新**: 地域出入り時にアプリが起動され、新しい地域設定
- **復旧**: 自動

#### 電源 OFF 後

- **動作**: 条件付きで継続
- **条件**: iOS バージョン・デバイス状態依存
- **復旧**: 多くの場合自動復旧

### 地域設定仕様

```swift
// 現在の設定
半径: 100m（最大、実際は100m固定）
識別子: "GPSLoggerRegion"
進入通知: 有効
退出通知: 有効

// 動的更新
- 地域退出時：現在地で新しい地域設定
- 地域間隔：前の地域中心から100m以上移動時のみ更新
```

### 地域イベント

1. **地域進入**: ログ記録のみ
2. **地域退出**: 新しい位置で地域再設定
3. **監視開始**: 地域設定完了
4. **監視エラー**: エラーログ記録

### 適用場面

- 中距離移動の追跡
- 電力消費と精度のバランス重視
- アプリキル後も一定頻度で継続したい場合

---

## 戦略切り替え仕様

### 切り替え動作

1. **現在戦略の停止**: 安全に現在の位置取得を停止
2. **戦略変更**: 新しい戦略インスタンスに切り替え
3. **設定保存**: UserDefaults に選択状態を永続化
4. **新戦略開始**: 追跡中の場合は新戦略で再開

### 切り替え時の制約

- **データロス**: なし（切り替え瞬間のデータは保持）
- **中断時間**: 通常 1 秒未満
- **設定引き継ぎ**: 戦略固有パラメータは個別管理

### 統計情報

各戦略で以下の統計を個別管理：

- 更新回数
- 最終更新時刻
- 平均精度
- 稼働時間
- 推定電力消費レベル
- 更新頻度レベル

---

## パフォーマンス比較

### 電力消費（相対値）

- **Standard**: 100%（基準）
- **Region**: 30-50%
- **Significant**: 5-10%

### 更新頻度（理想的移動時）

- **Standard**: 1 回/秒（フォアグラウンド）、1 回/5m（バックグラウンド）
- **Region**: 1 回/100m 移動
- **Significant**: 1 回/500m-数 km 移動

### 精度（概算）

- **Standard**: 3-5m（良好な環境）
- **Region**: 10-50m（地域境界依存）
- **Significant**: 100-1000m（システム依存）

---

## 使用推奨

### 用途別推奨戦略

#### 徒歩・ジョギング

- **推奨**: Region Monitoring
- **理由**: 適度な頻度、電力効率、アプリキル後継続

#### 自転車・バイク

- **推奨**: Region Monitoring または Standard
- **理由**: 移動速度に応じて選択

#### 自動車・電車

- **推奨**: Significant Location Changes
- **理由**: 長距離移動、確実な継続性

#### 開発・テスト

- **推奨**: Standard Location Updates
- **理由**: 即座の反応、高精度

#### 長期監視

- **推奨**: Significant Location Changes
- **理由**: 電力効率、確実な継続性
