## GPS センサロガー — 実装計画（Swift UI + iOS 18 以降想定）

下記は **まっさらな Xcode プロジェクトを作るところから TestFlight 配布準備まで** を 9 章 46 ステップに分けたロードマップです。
各ステップは **✅ ＝必須** / **⭐️ ＝推奨** を付けました。
先に全体像を把握してから、1 章ずつ進めると迷いません。

---

### 🗂 0. 事前フォルダ構成（ローカル）

```text
GPSLogger/
 ├─ Docs/            … 設計メモ・Mermaid 図
 ├─ GPSLogger.xcodeproj
 ├─ Sources/
 │   ├─ AppDelegate.swift
 │   ├─ Main/
 │   │   ├─ MainView.swift
 │   │   └─ HistoryView.swift
 │   ├─ ViewModel/
 │   │   └─ LocationViewModel.swift
 │   ├─ Services/
 │   │   ├─ LocationService.swift
 │   │   ├─ MotionService.swift   (任意)
 │   │   └─ PersistenceService.swift
 │   └─ Support/
 │       └─ BGTask+Registration.swift
 └─ Resources/
     └─ Assets.xcassets
```

---

## 1. 新規プロジェクト作成

| #   | 手順                                                                    | 備考                                       |
| --- | ----------------------------------------------------------------------- | ------------------------------------------ |
| 1   | **✅ File › New › Project** → App テンプレートを選択                    |                                            |
| 2   | **Product Name** = `GPSLogger` / Interface = SwiftUI / Language = Swift |                                            |
| 3   | **Team** を選択し、自動サイン                                           | Apple ID 無しなら無料プロビジョニングで OK |
| 4   | **iOS Deployment Target** を 18.0 に設定 ⭐️                            | 新 API を使う場合                          |

---

## 2. Capabilities & Info.plist

| #   | 手順                                                     | キー / 値                                                                                                                                         |
| --- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| 5   | **✅ Signing & Capabilities** › **+ Capability**         | `Background Modes` を追加                                                                                                                         |
| 6   |                                                          | `Location updates` / ⭐️`Background fetch` / ⭐️`Processing` にチェック                                                                           |
| 7   | **Info.plist** にプライバシー説明を追加                  | `NSLocationAlwaysAndWhenInUseUsageDescription` <br> `NSLocationWhenInUseUsageDescription` <br> 例: “現在地を記録してランニングログを作成するため” |
| 8   | ⭐️ `UIBackgroundModes` が自動で挿入されていることを確認 | 値: `location`, `processing` など                                                                                                                 |

---

## 3. パッケージ & ライブラリ

| #   | 手順                                             | 備考                 |
| --- | ------------------------------------------------ | -------------------- |
| 9   | **⭐️ Swift Package** `swift-log` 追加           | ロギングに便利       |
| 10  | ⭐️ `swift-composable-architecture` など導入も可 | アーキテクチャ好みで |

---

## 4. PersistenceService（Core Data or SwiftData）

| #   | 手順                                                                                                 | 備考                                                               |
| --- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 11  | **✅ File › New › File… › Core Data › Data Model**                                                   | `TrackPoint` Entity を作成                                         |
| 12  | 属性: `timestamp: Date`, `lat: Double`, `lon: Double`, `hAcc: Double?`, `speed: Double?`, `id: UUID` |                                                                    |
| 13  | **PersistenceService.swift** を実装                                                                  | _initPersistentStore()_, _save(trackPoint:)_, _fetch(limit:)_ など |
| 14  | ⭐️ iOS 18 以降なら `SwiftData` へ置き換え可                                                         |                                                                    |

---

## 5. LocationService

| #   | 手順                                                                                                                                                 | 実装ポイント                                                            |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| 15  | **✅ import CoreLocation**                                                                                                                           |                                                                         |
| 16  | クラスを `@MainActor final class LocationService: NSObject, ObservableObject` で宣言                                                                 |                                                                         |
| 17  | プロパティ                                                                                                                                           | `@Published var current: CLLocation?`                                   |
| 18  | CLLocationManager を private lazy で保持                                                                                                             | desiredAccuracy = Best, distanceFilter = 5                              |
| 19  | `start()` で `requestAlwaysAuthorization()` → iOS 18 なら `for await` ループで `CLLocationUpdate.liveUpdates()` / 旧 OS は `startUpdatingLocation()` |                                                                         |
| 20  | `startMonitoringSignificantLocationChanges()` を必ず呼ぶ                                                                                             | キル後再起動用                                                          |
| 21  | `allowsBackgroundLocationUpdates = true`, `pausesLocationUpdatesAutomatically = false`                                                               |                                                                         |
| 22  | **delegate** の `didUpdateLocations` 内で…                                                                                                           | • `self.current = lastLocation`<br>• 直ちに `PersistenceService.save()` |

---

## 6. MotionService ⭐️（任意）

| #   | 手順                                                                                         | 実装ポイント               |
| --- | -------------------------------------------------------------------------------------------- | -------------------------- |
| 23  | import CoreMotion                                                                            |                            |
| 24  | `startOnDemand()` / `stop()` を公開                                                          |                            |
| 25  | Significant-Change トリガ受信時に `LocationService` → `MotionService.startOnDemand()` を呼ぶ | 例: 30 秒だけ 50 Hz で収集 |

---

## 7. ViewModel

| #   | 手順                                                             | 実装ポイント                                |
| --- | ---------------------------------------------------------------- | ------------------------------------------- |
| 26  | `class LocationViewModel: ObservableObject`                      |                                             |
| 27  | `@Published var coordinateText: String = "--"`                   |                                             |
| 28  | `init(service: LocationService)` で Combine sink                 | service.\$current → `coordinateText` を更新 |
| 29  | `func fetchHistory()` → PersistenceService から過去 N 件読み取り |                                             |

---

## 8. SwiftUI ビュー

| #   | 手順                          | 実装ポイント                                           |
| --- | ----------------------------- | ------------------------------------------------------ |
| 30  | **MainView\.swift**           | MapKit の `Map` + `Text(coordinateText)`               |
| 31  | ⭐️ `LiveActivity` 表示を検討 | 長時間 BG 延命可                                       |
| 32  | **HistoryView\.swift**        | `List` { ForEach(history) }<br>・タップで map ピン表示 |

---

## 9. AppDelegate / BGTask

| #   | 手順                                                                             | 実装ポイント                                                           |
| --- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| 33  | **✅ UIApplicationDelegateAdaptor** で AppDelegate を使う                        |                                                                        |
| 34  | `application(_:didFinishLaunchingWithOptions:)` で…                              | • `LocationService.start()`<br>• `BGTaskScheduler.shared.register`     |
| 35  | `BGProcessingTaskRequest(identifier: "flush")` を 15 min 後にスケジュール        | `requiresNetworkConnectivity = false`, `requiresExternalPower = false` |
| 36  | ハンドラで `PersistenceService.flush(task:)` → `task.setTaskCompleted(success:)` |                                                                        |

---

## 10. デバッグ & 検証

| #   | 手順                                                                     | 備考                                       |
| --- | ------------------------------------------------------------------------ | ------------------------------------------ |
| 37  | **✅ シミュレータ** で Custom Location GPX を流す                        |                                            |
| 38  | **実機** でフォアグラウンド動作を確認                                    |                                            |
| 39  | **Background Fetch** を擬似 → Xcode ▶︎ Debug › Simulate Background Fetch | BGTask の flush が走るか                   |
| 40  | **端末再起動** 後、500 m 移動シミュレーション                            | ログが再開するか                           |
| 41  | **ユーザがスワイプキル** → Significant-Change で起動を確認               | 必要に応じて UX 文言で「キルしないで」案内 |

---

## 11. リリース準備

| #   | 手順                                                                     | 備考                   |
| --- | ------------------------------------------------------------------------ | ---------------------- |
| 42  | App Store Connect で App レコード作成                                    |                        |
| 43  | Info.plist の `NSLocation*` 文言を本番用に調整                           |                        |
| 44  | 🎨 AppIcon / スプラッシュを追加                                          |                        |
| 45  | **TestFlight** で内部テスト → バッテリー消費・バックグラウンド挙動を実測 |                        |
| 46  | App Review で “Always Location” の説明をスクリーンショット付きで提出     | Apple は厳しいので必須 |

---

### ✅ これで MVP が完成

1. **メイン動線**（フォアグラウンド ログ取得）
2. **Significant-Change で BG 再起動**
3. **CoreData 保存＋ BGTask フラッシュ**
4. **履歴 UI**

を 2〜3 週間（平日夜＋週末）で作り、
MotionService や GPX 書き出し、Live Activity などは **後続スプリント**で追加する進め方が現実的です。

疑問点が出たステップ番号を教えていただければ、該当箇所を深掘りします！
