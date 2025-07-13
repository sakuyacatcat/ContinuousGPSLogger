# ContinuousGPSLogger システム構成図・シーケンス図

## 概要

このドキュメントは、ContinuousGPSLogger のシステム構成とデータフローを視覚的に説明します。

---

## 1. システム全体構成図

```mermaid
graph TB
    %% UI Layer
    subgraph "UI Layer (SwiftUI)"
        MainView[MainView<br/>・戦略選択UI<br/>・状態表示<br/>・統計表示]
        HistoryView[HistoryView<br/>・履歴データ表示<br/>・詳細情報表示]
        PermissionView[PermissionGuidanceView<br/>・権限案内<br/>・設定誘導]
    end

    %% Service Layer
    subgraph "Service Layer"
        LocationService[LocationService<br/>・GPS取得制御<br/>・戦略管理<br/>・復旧システム]
        PersistenceService[PersistenceService<br/>・データ永続化<br/>・FIFO制限<br/>・履歴管理]
    end

    %% Strategy Layer
    subgraph "Strategy Pattern"
        StrategyProtocol[LocationAcquisitionStrategy<br/>Protocol]
        StandardStrategy[StandardLocationUpdatesStrategy<br/>・高頻度更新<br/>・高精度<br/>・アプリキル後停止]
        SignificantStrategy[SignificantLocationChangesStrategy<br/>・低頻度更新<br/>・省電力<br/>・アプリキル後継続]
        RegionStrategy[RegionMonitoringStrategy<br/>・地域ベース更新<br/>・中程度電力<br/>・アプリキル後継続]
        StrategyFactory[LocationAcquisitionStrategyFactory<br/>・戦略インスタンス生成]
    end

    %% Data Layer
    subgraph "Data Layer"
        CoreData[Core Data<br/>・位置データ永続化<br/>・100件制限<br/>・フォルトメカニズム]
        UserDefaults[UserDefaults<br/>・設定永続化<br/>・復旧状態管理<br/>・戦略選択状態]
    end

    %% iOS System Layer
    subgraph "iOS System"
        CLLocationManager[CLLocationManager<br/>・位置情報取得<br/>・権限管理<br/>・各種監視機能]
        SystemServices[System Services<br/>・Significant Location Changes<br/>・Region Monitoring<br/>・Background App Refresh]
    end

    %% Connections
    MainView --> LocationService
    MainView --> PersistenceService
    HistoryView --> PersistenceService

    LocationService --> StrategyProtocol
    LocationService --> PersistenceService
    LocationService --> CLLocationManager
    LocationService --> UserDefaults

    StrategyProtocol --> StandardStrategy
    StrategyProtocol --> SignificantStrategy
    StrategyProtocol --> RegionStrategy
    StrategyFactory --> StrategyProtocol

    StandardStrategy --> CLLocationManager
    SignificantStrategy --> CLLocationManager
    SignificantStrategy --> SystemServices
    RegionStrategy --> CLLocationManager
    RegionStrategy --> SystemServices

    PersistenceService --> CoreData

    CLLocationManager --> SystemServices

    %% Styling
    classDef uiClass fill:#e1f5fe
    classDef serviceClass fill:#f3e5f5
    classDef strategyClass fill:#e8f5e8
    classDef dataClass fill:#fff3e0
    classDef systemClass fill:#ffebee

    class MainView,HistoryView,PermissionView uiClass
    class LocationService,PersistenceService serviceClass
    class StrategyProtocol,StandardStrategy,SignificantStrategy,RegionStrategy,StrategyFactory strategyClass
    class CoreData,UserDefaults dataClass
    class CLLocationManager,SystemServices systemClass
```

---

## 2. Strategy Pattern 詳細構成図

```mermaid
classDiagram
    class LocationAcquisitionStrategy {
        <<interface>>
        +name: String
        +description: String
        +isActive: Bool
        +statistics: StrategyStatistics
        +start(manager, delegate)
        +stop(manager)
        +configure(parameters)
        +didUpdateLocations(locations)
        +didFailWithError(error)
        +resetStatistics()
    }

    class StandardLocationUpdatesStrategy {
        -foregroundUpdateInterval: TimeInterval
        -lastProcessedLocationTime: Date
        +start(manager, delegate)
        +configureForCurrentState(manager)
        +updateForApplicationState(manager)
    }

    class SignificantLocationChangesStrategy {
        +start(manager, delegate)
        +stop(manager)
    }

    class RegionMonitoringStrategy {
        -currentRegion: CLCircularRegion?
        -regionEvents: [RegionEvent]
        -regionIdentifier: String
        +setupRegionMonitoring(location, manager)
        +didEnterRegion(region)
        +didExitRegion(region, manager)
        +getCurrentRegionInfo()
        +getRegionEvents()
    }

    class StrategyStatistics {
        +updateCount: Int
        +lastUpdateTime: Date?
        +averageAccuracy: Double
        +estimatedBatteryUsage: BatteryUsageLevel
        +updateFrequency: UpdateFrequency
        +activeDuration: TimeInterval
    }

    class StrategyParameters {
        +distanceFilter: CLLocationDistance
        +desiredAccuracy: CLLocationAccuracy
        +regionRadius: CLLocationDistance
        +customSettings: [String: Any]
    }

    class LocationAcquisitionStrategyFactory {
        +createStrategy(type): LocationAcquisitionStrategy
    }

    class LocationService {
        -currentStrategy: LocationAcquisitionStrategy?
        -strategies: [LocationAcquisitionStrategyType: LocationAcquisitionStrategy]
        +changeStrategy(to: LocationAcquisitionStrategyType)
        +getCurrentStrategyStatistics(): StrategyStatistics?
        +getAllStrategyStatistics(): [LocationAcquisitionStrategyType: StrategyStatistics]
    }

    LocationAcquisitionStrategy <|-- StandardLocationUpdatesStrategy
    LocationAcquisitionStrategy <|-- SignificantLocationChangesStrategy
    LocationAcquisitionStrategy <|-- RegionMonitoringStrategy
    LocationAcquisitionStrategy --> StrategyStatistics
    LocationAcquisitionStrategy --> StrategyParameters
    LocationAcquisitionStrategyFactory --> LocationAcquisitionStrategy
    LocationService --> LocationAcquisitionStrategy
    LocationService --> LocationAcquisitionStrategyFactory
```

---

## 3. データフロー図

```mermaid
flowchart TD
    %% User Actions
    UserAction[ユーザー操作<br/>戦略選択・アプリ操作]

    %% UI Layer
    UI[UI Layer<br/>MainView / HistoryView]

    %% Service Layer
    LocationService[LocationService<br/>GPS取得制御]
    PersistenceService[PersistenceService<br/>データ永続化]

    %% Strategy Layer
    CurrentStrategy[Current Strategy<br/>選択された戦略]

    %% System Layer
    CLLocationManager[CLLocationManager<br/>iOS位置情報API]

    %% Data Storage
    CoreData[Core Data<br/>位置データ保存]
    UserDefaults[UserDefaults<br/>設定保存]

    %% External Systems
    GPS[GPS衛星]
    CellTower[セルタワー基地局]
    WiFi[WiFiアクセスポイント]

    %% Data Flow
    UserAction --> UI
    UI --> LocationService
    UI --> PersistenceService

    LocationService --> CurrentStrategy
    LocationService --> CLLocationManager
    LocationService --> UserDefaults

    CurrentStrategy --> CLLocationManager
    CLLocationManager --> GPS
    CLLocationManager --> CellTower
    CLLocationManager --> WiFi

    CLLocationManager --> CurrentStrategy
    CurrentStrategy --> LocationService
    LocationService --> PersistenceService
    PersistenceService --> CoreData

    PersistenceService --> UI
    LocationService --> UI

    %% Background Processes
    subgraph "Background Processes"
        SystemServices[iOS System Services<br/>Significant/Region Monitoring]
        AutoRecovery[自動復旧システム<br/>アプリキル後の復旧]
    end

    CLLocationManager --> SystemServices
    SystemServices --> LocationService
    LocationService --> AutoRecovery
    AutoRecovery --> CurrentStrategy

    %% Styling
    classDef userClass fill:#e3f2fd
    classDef uiClass fill:#e1f5fe
    classDef serviceClass fill:#f3e5f5
    classDef strategyClass fill:#e8f5e8
    classDef systemClass fill:#ffebee
    classDef dataClass fill:#fff3e0
    classDef externalClass fill:#f5f5f5

    class UserAction userClass
    class UI uiClass
    class LocationService,PersistenceService serviceClass
    class CurrentStrategy strategyClass
    class CLLocationManager,SystemServices,AutoRecovery systemClass
    class CoreData,UserDefaults dataClass
    class GPS,CellTower,WiFi externalClass
```

---

## 4. シーケンス図集

### 4.1 アプリ起動・初期化シーケンス

```mermaid
sequenceDiagram
    participant User
    participant App as ContinuousGPSLoggerApp
    participant MainView
    participant LocationService
    participant CLLocationManager
    participant Strategy as Current Strategy
    participant UserDefaults

    User->>App: アプリ起動
    App->>MainView: 画面表示
    MainView->>LocationService: shared インスタンス取得

    LocationService->>UserDefaults: 前回の設定読み込み
    UserDefaults-->>LocationService: 戦略タイプ・追跡状態

    LocationService->>LocationService: initializeStrategies()
    LocationService->>Strategy: 戦略インスタンス生成

    LocationService->>CLLocationManager: 権限状態確認
    CLLocationManager-->>LocationService: authorizationStatus

    alt 権限が未設定
        LocationService->>CLLocationManager: requestAlwaysAuthorization()
        CLLocationManager->>User: 権限ダイアログ表示
        User->>CLLocationManager: 権限許可
        CLLocationManager->>LocationService: didChangeAuthorization
    end

    alt 前回追跡が有効だった場合
        LocationService->>LocationService: performRecoveryIfNeeded()
        LocationService->>Strategy: start(manager, delegate)
        Strategy->>CLLocationManager: 位置取得開始
    end

    LocationService-->>MainView: 状態更新通知
    MainView-->>User: UI更新
```

### 4.2 戦略切り替えシーケンス

```mermaid
sequenceDiagram
    participant User
    participant MainView
    participant LocationService
    participant OldStrategy as 旧Strategy
    participant NewStrategy as 新Strategy
    participant CLLocationManager
    participant UserDefaults

    User->>MainView: 戦略選択（Picker操作）
    MainView->>LocationService: changeStrategy(to: newType)

    LocationService->>LocationService: 追跡状態確認

    alt 追跡中の場合
        LocationService->>OldStrategy: stop(with: manager)
        OldStrategy->>CLLocationManager: 位置取得停止
        CLLocationManager-->>OldStrategy: 停止完了
    end

    LocationService->>LocationService: currentStrategy = newStrategy
    LocationService->>UserDefaults: 戦略タイプ保存

    alt 追跡中だった場合
        LocationService->>NewStrategy: start(with: manager, delegate)
        NewStrategy->>CLLocationManager: 新しい設定で位置取得開始
        CLLocationManager-->>NewStrategy: 開始完了
    end

    LocationService->>LocationService: addRecoveryLog("Strategy変更")
    LocationService-->>MainView: 状態更新通知
    MainView-->>User: UI更新（新戦略情報表示）
```

### 4.3 GPS 位置取得・保存シーケンス

```mermaid
sequenceDiagram
    participant CLLocationManager
    participant Strategy as Current Strategy
    participant LocationService
    participant PersistenceService
    participant CoreData
    participant MainView

    CLLocationManager->>Strategy: didUpdateLocations(locations)
    Strategy->>Strategy: 戦略固有の処理<br/>（頻度制限・統計更新）

    alt 処理すべき位置更新の場合
        Strategy->>LocationService: didUpdateLocations(locations)
        LocationService->>LocationService: 1Hz制限チェック<br/>（Standard戦略のみ）

        alt 処理許可の場合
            LocationService->>LocationService: current = location
            LocationService->>LocationService: resetErrorCount()

            LocationService->>PersistenceService: save(trackPoint: location)
            PersistenceService->>CoreData: 位置データ保存
            CoreData-->>PersistenceService: 保存完了

            PersistenceService->>PersistenceService: limitData(maxCount: 100)
            PersistenceService->>CoreData: 古いデータ削除（必要時）

            PersistenceService-->>LocationService: 保存成功
            LocationService->>LocationService: saveCount更新
            LocationService->>LocationService: lastSaveTimestamp更新

            alt Region Monitoring有効の場合
                LocationService->>LocationService: updateRegionMonitoring(location)
            end

            LocationService-->>MainView: 状態更新通知
            MainView-->>MainView: UI更新
        end
    end
```

### 4.4 アプリキル後復旧シーケンス

```mermaid
sequenceDiagram
    participant System as iOS System
    participant LocationService
    participant Strategy as Significant/Region Strategy
    participant CLLocationManager
    participant PersistenceService
    participant MainView
    participant User

    Note over System: アプリがキルされた状態

    System->>System: 大幅な位置変更検出<br/>または地域出入り検出
    System->>LocationService: アプリを背景で起動

    LocationService->>LocationService: performRecoveryIfNeeded()
    LocationService->>LocationService: UserDefaults確認

    alt 前回追跡が有効だった場合
        LocationService->>LocationService: attemptRecovery()
        LocationService->>LocationService: addRecoveryLog("復旧試行開始")

        LocationService->>Strategy: start(with: manager, delegate)
        Strategy->>CLLocationManager: 位置取得再開

        CLLocationManager->>Strategy: didUpdateLocations(locations)
        Strategy->>LocationService: 位置データ通知
        LocationService->>PersistenceService: save(trackPoint: location)

        LocationService->>LocationService: addRecoveryLog("復旧完了")
    end

    Note over System: ユーザーがアプリを開く
    User->>MainView: アプリを前景に移行
    MainView->>LocationService: handleAppWillEnterForeground()
    LocationService->>LocationService: performRecoveryIfNeeded()
    LocationService-->>MainView: 状態更新通知
    MainView-->>User: 復旧状況表示
```

### 4.5 エラーハンドリング・復旧シーケンス

```mermaid
sequenceDiagram
    participant CLLocationManager
    participant Strategy as Current Strategy
    participant LocationService
    participant Timer as Error Recovery Timer
    participant MainView

    CLLocationManager->>Strategy: didFailWithError(error)
    Strategy->>LocationService: didFailWithError(error)

    LocationService->>LocationService: handleLocationError(error)
    LocationService->>LocationService: lastError = error
    LocationService->>LocationService: consecutiveErrors++
    LocationService->>LocationService: addRecoveryLog("エラー発生")

    alt 連続エラー >= 3回
        LocationService->>LocationService: scheduleErrorRecovery()
        LocationService->>Timer: 10秒後に復旧試行をスケジュール
        LocationService->>LocationService: addRecoveryLog("自動復旧を10秒後に実行")

        Timer-->>LocationService: タイマー発火（10秒後）
        LocationService->>LocationService: attemptErrorRecovery()

        LocationService->>CLLocationManager: stopUpdatingLocation()
        LocationService->>LocationService: 2秒待機
        LocationService->>CLLocationManager: startUpdatingLocation()

        alt Region Monitoring有効の場合
            LocationService->>LocationService: updateRegionMonitoring(currentLocation)
        end

        LocationService->>LocationService: addRecoveryLog("エラー復旧試行完了")
    end

    LocationService-->>MainView: エラー状態更新通知
    MainView-->>MainView: エラー表示更新

    Note over CLLocationManager,MainView: 正常な位置取得時
    CLLocationManager->>LocationService: didUpdateLocations(正常データ)
    LocationService->>LocationService: resetErrorCount()
    LocationService->>LocationService: addRecoveryLog("エラー復旧成功")
    LocationService-->>MainView: 正常状態通知
```

### 4.6 Strategy 別動作比較シーケンス

```mermaid
sequenceDiagram
    participant User
    participant CLLocationManager
    participant Standard as Standard Strategy
    participant Significant as Significant Strategy
    participant Region as Region Strategy
    participant System as iOS System

    Note over User,System: Standard Location Updates
    User->>Standard: フォアグラウンド移動
    Standard->>CLLocationManager: 制限なし設定
    CLLocationManager-->>Standard: 高頻度位置更新（~1Hz）

    User->>Standard: バックグラウンド移動
    Standard->>CLLocationManager: 5m distanceFilter
    CLLocationManager-->>Standard: 5m間隔位置更新

    User->>User: アプリキル
    Note over Standard,CLLocationManager: 位置取得完全停止

    Note over User,System: Significant Location Changes
    User->>Significant: 大幅移動（500m+）
    Significant->>System: システム制御の監視
    System-->>Significant: 大幅変更時のみ通知

    User->>User: アプリキル
    System->>Significant: バックグラウンドでアプリ起動
    Significant-->>System: 継続監視

    Note over User,System: Region Monitoring
    User->>Region: 100m移動
    Region->>CLLocationManager: 地域監視設定
    CLLocationManager->>System: 地域監視開始
    System-->>Region: 地域出入り通知

    User->>User: アプリキル
    System->>Region: 地域出入り時にアプリ起動
    Region-->>System: 新しい地域設定
```

---

## 5. 状態遷移図

### 5.1 アプリケーション状態遷移

```mermaid
stateDiagram-v2
    [*] --> AppLaunch : アプリ起動

    AppLaunch --> PermissionRequest : 権限未設定
    AppLaunch --> Initialized : 権限設定済み

    PermissionRequest --> PermissionDenied : ユーザー拒否
    PermissionRequest --> Initialized : ユーザー許可

    PermissionDenied --> [*] : アプリ終了
    PermissionDenied --> PermissionRequest : 設定変更

    Initialized --> Tracking : startTracking()
    Initialized --> Standby : 待機状態

    Tracking --> Standby : stopTracking()
    Tracking --> Background : アプリバックグラウンド
    Tracking --> ErrorState : エラー発生

    Background --> Tracking : アプリフォアグラウンド
    Background --> Killed : アプリキル
    Background --> ErrorState : エラー発生

    Killed --> Recovery : System起動（Significant/Region）
    Killed --> [*] : Standard Strategy

    Recovery --> Tracking : 復旧成功
    Recovery --> ErrorState : 復旧失敗

    ErrorState --> Tracking : エラー解決
    ErrorState --> Recovery : 自動復旧試行
    ErrorState --> [*] : 致命的エラー

    Standby --> Tracking : ユーザー操作
    Standby --> [*] : アプリ終了
```

### 5.2 Strategy 状態遷移

```mermaid
stateDiagram-v2
    [*] --> Inactive : Strategy生成

    Inactive --> Starting : start()呼び出し
    Starting --> Active : 開始成功
    Starting --> Error : 開始失敗

    Active --> Stopping : stop()呼び出し
    Active --> Error : 実行時エラー
    Active --> Updating : 位置更新受信

    Updating --> Active : 更新処理完了
    Updating --> Error : 処理エラー

    Stopping --> Inactive : 停止完了

    Error --> Inactive : エラー解決
    Error --> Active : 自動復旧成功

    Inactive --> [*] : Strategy破棄
```

---

## 6. 補足説明

### 6.1 図表の読み方

#### システム構成図

- **青色**: UI 層コンポーネント
- **紫色**: サービス層コンポーネント
- **緑色**: Strategy 層コンポーネント
- **オレンジ色**: データ層コンポーネント
- **赤色**: iOS システム層コンポーネント

#### シーケンス図

- **実線矢印**: 同期呼び出し
- **破線矢印**: 非同期通知・コールバック
- **alt ブロック**: 条件分岐
- **Note**: 補足説明

#### 状態遷移図

- **角丸四角**: 状態
- **矢印**: 状態遷移
- **[*]**: 開始・終了状態

### 6.2 重要なポイント

1. **Strategy Pattern**: 実行時に異なる GPS 取得方式を切り替え可能
2. **復旧システム**: アプリキル後の自動復旧機能
3. **データフロー**: 位置データの取得から保存まで一貫した流れ
4. **エラーハンドリング**: 段階的なエラー復旧システム
5. **状態管理**: アプリ・Strategy 別の詳細な状態追跡

### 6.3 パフォーマンス考慮事項

- **メモリ効率**: Strategy インスタンスの事前生成・再利用
- **CPU 効率**: メインスレッド負荷の分散
- **電力効率**: 戦略別の最適化された設定
- **データ効率**: FIFO 制限による一定メモリ使用量
