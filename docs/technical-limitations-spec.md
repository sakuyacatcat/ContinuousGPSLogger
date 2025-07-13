# ContinuousGPSLogger 技術制限・実装詳細仕様書

## 概要

このドキュメントは、ContinuousGPSLogger の技術的制限、iOS システム制限、実装詳細について詳しく説明します。

---

## iOS システム制限

### 1. バックグラウンド実行制限

#### Standard Location Updates

**制限内容**:

- 通常のバックグラウンド実行時間は数分程度
- システムによる強制終了の可能性
- アプリキル後は完全停止

**技術詳細**:

```swift
// iOS標準の制限
backgroundTimeRemaining: 通常180秒（3分）
UIApplication.shared.beginBackgroundTask() // 最大30秒延長可能
```

**回避策**:

- Background Location モードの使用
- `allowsBackgroundLocationUpdates = true`
- Significant Location Changes への移行

#### Significant Location Changes

**システム制御**:

- セルタワー基地局の変更検出
- 通常 500m〜数 km 移動で反応
- アプリキル後もシステムが管理

**技術詳細**:

```swift
// システム内部判定（推定）
基地局変更: セルラータワーIDの変化
WiFi変化: アクセスポイントBSSIDの変化
時間要素: 長時間静止後の移動
距離要素: 前回位置からの直線距離
```

#### Region Monitoring

**システム制限**:

- 同時監視可能地域数：通常 20 地域
- 最小半径：CLLocationManager で定義
- 電源 OFF 後の継続：iOS バージョン依存

### 2. 権限制限

#### When In Use vs Always

**When In Use 制限**:

- フォアグラウンド時のみ位置取得
- バックグラウンド移行で数秒後に停止
- Background Location Updates 不可

**Always 権限の利点**:

```swift
// 利用可能機能
manager.allowsBackgroundLocationUpdates = true
manager.startMonitoringSignificantLocationChanges()
manager.startMonitoring(for: region)
```

#### 権限状態の遷移

```
未設定 → When In Use → Always（アップグレード可能）
未設定 → 拒否（設定アプリでのみ変更可能）
Always → When In Use（ユーザー変更可能）
```

### 3. 精度・電力制限

#### 精度レベルとトレードオフ

```swift
kCLLocationAccuracyBestForNavigation  // 最高精度、最高電力
kCLLocationAccuracyBest               // 高精度、高電力
kCLLocationAccuracyNearestTenMeters   // 10m精度、中電力
kCLLocationAccuracyHundredMeters      // 100m精度、低電力
kCLLocationAccuracyKilometer          // 1km精度、最低電力
```

#### 距離フィルタの影響

```swift
// 電力消費への影響
distanceFilter = kCLDistanceFilterNone  // 最高頻度、最高電力
distanceFilter = 5.0                    // 5m間隔、高電力
distanceFilter = 100.0                  // 100m間隔、低電力
```

---

## アプリ固有の制限

### 1. データ保存制限

#### FIFO 制限の実装

```swift
// PersistenceService.swift での実装
func limitData(maxCount: Int = 100) {
    let currentCount = getTotalCount()
    guard currentCount > maxCount else { return }
    let deleteCount = currentCount - maxCount
    // 古いデータから削除（タイムスタンプソート）
}
```

#### メモリ使用量制限

- Core Data フォルトメカニズム使用
- 必要時のみデータロード
- 100 件制限によるメモリ使用量上限設定

### 2. Strategy Pattern 制限

#### 同時実行制限

**設計制限**:

- 単一戦略のみ実行可能
- 複数戦略同時実行は未実装
- 理由：競合状態の回避、電力消費制御

**実装詳細**:

```swift
// LocationService.swift
private var currentStrategy: LocationAcquisitionStrategy?
// 必ず1つのstrategyのみアクティブ

func changeStrategy(to strategyType: LocationAcquisitionStrategyType) {
    // 既存strategyを停止してから新strategyを開始
    currentStrategy?.stop(with: manager)
    currentStrategy = strategies[strategyType]
    currentStrategy?.start(with: manager, delegate: self)
}
```

#### 戦略切り替え時の制約

- 切り替え時の短時間中断（通常 1 秒未満）
- 統計情報は戦略別に個別管理
- 設定は UserDefaults で永続化

### 3. 1Hz 制限の実装

#### フォアグラウンド時の制限理由

```swift
// StandardLocationUpdatesStrategy.swift
private let foregroundUpdateInterval: TimeInterval = 1.0

func didUpdateLocations(_ locations: [CLLocation]) {
    let now = Date()
    let shouldProcess = isBackground ||
                       (now.timeIntervalSince(lastProcessedLocationTime) >= foregroundUpdateInterval)
    guard shouldProcess else { return }
    // 処理実行
}
```

**制限理由**:

- UI 更新の負荷軽減
- 電力消費の抑制
- データ保存頻度の制御

---

## パフォーマンス制限

### 1. メモリ使用量

#### 実測値（iPhone 実機）

```
基本動作（戦略なし）: 約8-12MB
Standard Strategy動作中: 約15-20MB
データ100件保存時: 約20-25MB
Strategy切り替え時: 一時的に+5MB
```

#### メモリ効率化実装

```swift
// Core Data の効率化
lazy var persistentContainer: NSPersistentContainer = {
    // フォルトメカニズム有効
    // 必要時ロード
}()

// Strategy instances の効率化
private var strategies: [LocationAcquisitionStrategyType: LocationAcquisitionStrategy] = [:]
// 事前生成、再利用
```

### 2. CPU 使用率

#### 実測値

```
フォアグラウンド（Standard）: 1-3%
バックグラウンド（Standard）: 0.5-1%
Significant/Region: 0.1-0.3%
Strategy切り替え: 短時間で5-10%（1-2秒）
```

#### CPU 効率化実装

```swift
// メインスレッド負荷軽減
nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    Task { @MainActor in
        // UI更新は MainActor で実行
        self.updateUI(with: locations)
    }
}
```

### 3. 電力消費

#### 相対的消費量（Standard Strategy を 100%として）

```
Standard Location Updates:     100%
Region Monitoring:             30-50%
Significant Location Changes:  5-10%
```

#### 消費量に影響する要因

```swift
// 精度設定の影響
desiredAccuracy = kCLLocationAccuracyBest      // 100%
desiredAccuracy = kCLLocationAccuracyNearestTenMeters  // 70%
desiredAccuracy = kCLLocationAccuracyHundredMeters     // 40%

// 距離フィルタの影響
distanceFilter = kCLDistanceFilterNone  // 100%
distanceFilter = 5.0                    // 80%
distanceFilter = 50.0                   // 30%
```

---

## 実装制限・既知の問題

### 1. Region Monitoring の制限

#### 地域数制限

```swift
// iOS システム制限
最大同時監視地域数: 20地域
現在の実装: 1地域のみ使用（動的更新）
```

#### 精度の不安定性

- 地域境界付近での精度低下
- セルラー電波状況による影響
- WiFi 環境での精度向上

### 2. Significant Location Changes の予測困難性

#### システム依存の動作

```swift
// 制御不可能な要素
基地局密度: 都市部（高頻度） vs 郊外（低頻度）
移動手段: 徒歩（低頻度） vs 車（高頻度）
時間帯: 混雑時間の影響
```

#### 予測可能な動作パターン

- 500m 以下：通常反応なし
- 500m-2km：条件により反応
- 2km 以上：高確率で反応

### 3. バックグラウンド復旧の制約

#### 復旧可能条件

```swift
// LocationService.swift recovery system
アプリキル後の復旧:
- Significant Location Changes: ✅ 自動復旧
- Region Monitoring: ✅ 自動復旧
- Standard Location Updates: ❌ 手動起動必要
```

#### 復旧タイミング

```swift
復旧トリガー:
1. アプリフォアグラウンド復帰時
2. Significant Location変更時（自動アプリ起動）
3. Region進入/退出時（自動アプリ起動）
```

---

## セキュリティ制限

### 1. データプライバシー

#### ローカルストレージのみ

```swift
// 設計方針
外部送信: なし
クラウド同期: なし
データ共有: なし（アプリ内のみ）
暗号化: iOS標準のCore Data保護
```

#### 位置データの取り扱い

```swift
// データ保存項目（最小限）
保存項目: 緯度、経度、精度、速度、タイムスタンプ
非保存項目: 住所、場所名、個人識別情報
```

### 2. 権限最小化

#### 段階的権限要求

```swift
// 実装方針
初期: When In Use 権限要求
必要時: Always 権限アップグレード提案
説明: 各機能の必要性を明確に説明
```

---

## 将来の制約・考慮事項

### 1. iOS バージョンアップ対応

#### 予想される変更

- バックグラウンド実行のさらなる制限
- 位置情報権限の詳細化
- プライバシー保護の強化

#### 対応策

```swift
// 対応可能設計
Strategy Pattern: 新戦略の追加容易
パラメータ化: 設定値の動的調整
抽象化: iOS API変更への対応
```

### 2. パフォーマンス要件の変化

#### スケーラビリティ制限

```swift
// 現在の制限
データ上限: 100件（メモリ・パフォーマンス考慮）
戦略数: 3種類（管理複雑性考慮）
同時戦略: 1つ（競合回避）
```

#### 拡張可能性

```swift
// 拡張のための設計
Factory Pattern: 新戦略追加
Parameter System: 設定値カスタマイズ
Statistics System: 詳細分析機能
```

---

## トラブルシューティング技術詳細

### 1. ログ収集・解析

#### 実装されたログ機能

```swift
// LocationService.swift
復旧ログ: recoveryLog（最新100件）
地域イベントログ: regionEvents（最新50件）
エラーログ: lastError、consecutiveErrors
統計ログ: 各Strategy個別統計
```

#### ログ確認方法

```swift
// アプリ内確認
MainView > バックグラウンド状態 > 復旧ログ
MainView > GPS取得方式 > 統計情報

// Xcode console確認
print文による詳細ログ出力
Strategy動作状況のリアルタイム確認
```

### 2. 性能問題の診断

#### メモリリーク確認

```bash
# Instruments使用
Product > Profile > Allocations
長時間動作でのメモリ増加確認
```

#### CPU 使用率確認

```bash
# Instruments使用
Product > Profile > Time Profiler
各Strategy別のCPU使用率測定
```

#### 電力消費確認

```bash
# デバイス設定確認
設定 > バッテリー > バッテリー使用状況
アプリ別消費量の確認
```

### 3. 権限問題の解決

#### 権限状態の詳細確認

```swift
// LocationService.swift で確認可能
authorizationStatus: CLAuthorizationStatus
backgroundAppRefreshStatus: UIBackgroundRefreshStatus
```

#### 段階的解決手順

1. 位置情報サービス有効化確認
2. アプリ個別権限確認
3. Background App Refresh 確認
4. システム再起動
5. アプリ再インストール
