//
//  LocationService.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/06.
//

import Foundation
import CoreLocation
import UIKit

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var current: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isTracking: Bool = false
    @Published private(set) var lastError: String?
    @Published private(set) var permissionRequestInProgress: Bool = false
    @Published private(set) var saveCount: Int = 0
    @Published private(set) var lastSaveTimestamp: Date?
    @Published private(set) var saveError: String?
    
    // バックグラウンド関連の状態
    @Published private(set) var isBackgroundLocationEnabled: Bool = false
    @Published private(set) var isSignificantLocationChangesEnabled: Bool = false
    @Published private(set) var lastBackgroundUpdate: Date?
    
    // Region Monitoring関連の状態
    @Published private(set) var isRegionMonitoringEnabled: Bool = false
    @Published private(set) var currentMonitoredRegion: CLCircularRegion?
    @Published private(set) var regionEvents: [String] = []
    
    // Background App Refresh関連の状態
    @Published private(set) var backgroundAppRefreshStatus: UIBackgroundRefreshStatus = .available
    @Published private(set) var backgroundRefreshAvailable: Bool = true
    
    // Strategy関連の状態
    @Published private(set) var currentStrategyType: LocationAcquisitionStrategyType = .significantLocationChanges
    @Published private(set) var availableStrategies: [LocationAcquisitionStrategyType] = LocationAcquisitionStrategyType.allCases
    private var currentStrategy: LocationAcquisitionStrategy?
    private var strategies: [LocationAcquisitionStrategyType: LocationAcquisitionStrategy] = [:]
    
    // 復旧システム関連
    @Published private(set) var recoveryAttempts: Int = 0
    @Published private(set) var lastRecoveryTime: Date?
    @Published private(set) var isRecovering: Bool = false
    @Published private(set) var recoveryLog: [String] = []
    
    // エラーハンドリング関連
    @Published private(set) var consecutiveErrors: Int = 0
    @Published private(set) var lastErrorTime: Date?
    private var errorRetryTimer: Timer?
    
    // 1Hz GPS取得用
    private var lastProcessedLocationTime: Date = Date.distantPast
    private let foregroundUpdateInterval: TimeInterval = 1.0 // 1秒間隔

    private let manager = CLLocationManager()
    
    // UserDefaults keys for state persistence
    private let trackingStateKey = "LocationService.isTrackingEnabled"
    private let lastKnownLocationKey = "LocationService.lastKnownLocation"
    private let recoveryLogKey = "LocationService.recoveryLog"
    private let regionMonitoringStateKey = "LocationService.isRegionMonitoringEnabled"
    private let lastRegionCenterKey = "LocationService.lastRegionCenter"
    private let currentStrategyTypeKey = "LocationService.currentStrategyType"
    
    // Region monitoring settings
    private let regionRadius: CLLocationDistance = 200 // 200m radius
    private let regionIdentifier = "GPSLoggerRegion"

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone // フォアグラウンド時は全ての更新を受け取る
        authorizationStatus = manager.authorizationStatus
        
        // 復旧ログを読み込み
        loadRecoveryLog()
        
        // Background App Refresh の状態をチェック
        checkBackgroundAppRefreshStatus()
        
        // Strategyを初期化
        initializeStrategies()
        
        if authorizationStatus == .notDetermined {
            manager.requestAlwaysAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            // アプリ起動時の状態復旧をチェック
            performRecoveryIfNeeded()
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }
        // MainActor に Hop して Published プロパティを更新
        Task { @MainActor in
            // 現在のStrategyに通知
            self.currentStrategy?.didUpdateLocations(locs)
            
            let now = Date()
            
            // フォアグラウンド時は1Hz制限、バックグラウンド時は制限なし
            let isBackgroundMode = UIApplication.shared.applicationState != .active
            let shouldProcess = isBackgroundMode || 
                               (now.timeIntervalSince(self.lastProcessedLocationTime) >= self.foregroundUpdateInterval)
            
            guard shouldProcess else { return }
            
            self.lastProcessedLocationTime = now
            self.current = loc
            self.lastError = nil
            
            // エラーカウンターをリセット（正常に位置情報を取得できた）
            self.resetErrorCount()
            
            // 自動保存処理
            let success = PersistenceService.shared.save(trackPoint: loc)
            if success {
                self.saveCount += 1
                self.lastSaveTimestamp = Date()
                self.saveError = nil
                
                // 定期的なデータ管理
                self.manageDataAfterSave()
                
                // Region Monitoringが有効な場合、地域監視を更新
                if self.isRegionMonitoringEnabled {
                    self.updateRegionMonitoring(around: loc)
                }
            } else {
                self.saveError = "データの保存に失敗しました"
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
            self.permissionRequestInProgress = false
            
            switch status {
            case .authorizedWhenInUse:
                self.startTracking()
                self.lastError = nil
            case .authorizedAlways:
                self.startTracking()
                self.enableBackgroundLocationUpdates()
                self.startMonitoringSignificantLocationChanges()
                self.lastError = nil
            case .denied, .restricted:
                self.stopTracking()
                self.lastError = "位置情報の利用が許可されていません"
            case .notDetermined:
                self.stopTracking()
                self.lastError = nil
            @unknown default:
                self.stopTracking()
                self.lastError = "不明な認証状態です"
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            // 現在のStrategyに通知
            self.currentStrategy?.didFailWithError(error)
            
            self.handleLocationError(error)
        }
    }
    
    // MARK: - Region Monitoring Delegate
    
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task { @MainActor in
            // RegionMonitoringStrategyに通知
            if let regionStrategy = self.currentStrategy as? RegionMonitoringStrategy {
                regionStrategy.didEnterRegion(region)
            }
            
            // RegionTriggeredStandardStrategyに通知
            if let regionTriggeredStrategy = self.currentStrategy as? RegionTriggeredStandardStrategy {
                regionTriggeredStrategy.didEnterRegion(region)
            }
            
            let event = "地域進入: \(region.identifier)"
            self.addRegionEvent(event)
            self.addRecoveryLog(event)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task { @MainActor in
            // RegionMonitoringStrategyに通知
            if let regionStrategy = self.currentStrategy as? RegionMonitoringStrategy {
                regionStrategy.didExitRegion(region, with: manager)
            }
            
            // RegionTriggeredStandardStrategyに通知
            if let regionTriggeredStrategy = self.currentStrategy as? RegionTriggeredStandardStrategy {
                regionTriggeredStrategy.didExitRegion(region, with: manager)
            }
            
            let event = "地域退出: \(region.identifier) - 新しい地域の監視を開始"
            self.addRegionEvent(event)
            self.addRecoveryLog(event)
            
            // 地域から出たので、新しい位置での地域監視を開始
            if let currentLocation = self.current {
                self.updateRegionMonitoring(around: currentLocation)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task { @MainActor in
            // RegionMonitoringStrategyに通知
            if let regionStrategy = self.currentStrategy as? RegionMonitoringStrategy {
                regionStrategy.monitoringDidFailFor(region, withError: error)
            }
            
            // RegionTriggeredStandardStrategyに通知
            if let regionTriggeredStrategy = self.currentStrategy as? RegionTriggeredStandardStrategy {
                regionTriggeredStrategy.monitoringDidFailFor(region, withError: error)
            }
            
            let event = "地域監視エラー: \(error.localizedDescription)"
            self.addRegionEvent(event)
            self.addRecoveryLog(event)
            self.lastError = event
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        Task { @MainActor in
            // RegionMonitoringStrategyに通知
            if let regionStrategy = self.currentStrategy as? RegionMonitoringStrategy {
                regionStrategy.didStartMonitoringFor(region)
            }
            
            // RegionTriggeredStandardStrategyに通知
            if let regionTriggeredStrategy = self.currentStrategy as? RegionTriggeredStandardStrategy {
                regionTriggeredStrategy.didStartMonitoringFor(region)
            }
            
            let event = "地域監視開始: \(region.identifier)"
            self.addRegionEvent(event)
            self.addRecoveryLog(event)
        }
    }
    
    private func startTracking() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        // 現在のStrategyを開始
        currentStrategy?.start(with: manager, delegate: self)
        isTracking = true
        
        // 状態を永続化
        UserDefaults.standard.set(true, forKey: trackingStateKey)
        addRecoveryLog("GPS追跡を開始しました: \(currentStrategy?.name ?? "Unknown")")
    }
    
    private func stopTracking() {
        // 現在のStrategyを停止
        currentStrategy?.stop(with: manager)
        isTracking = false
        
        // 状態を永続化
        UserDefaults.standard.set(false, forKey: trackingStateKey)
        addRecoveryLog("GPS追跡を停止しました")
    }
    
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
    
    /// 保存後のデータ管理
    private func manageDataAfterSave() {
        // 100件を超えたら古いデータを削除（FIFO方式）
        PersistenceService.shared.limitData(maxCount: 100)
    }
    
    // MARK: - バックグラウンド対応
    
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
        configureForBackgroundMode()
        enableBackgroundLocationUpdates()
        startMonitoringSignificantLocationChanges()
    }
    
    func handleAppWillEnterForeground() {
        // フォアグラウンド復帰時の処理
        configureForForegroundMode()
        lastBackgroundUpdate = Date()
        
        // フォアグラウンド復帰時も復旧チェック
        performRecoveryIfNeeded()
    }
    
    /// フォアグラウンドモード用の設定
    private func configureForForegroundMode() {
        guard isTracking else { return }
        manager.distanceFilter = kCLDistanceFilterNone // 全ての更新を受け取る（1Hz制限は内部で実装）
        addRecoveryLog("フォアグラウンドモード: 1Hz更新に設定")
    }
    
    /// バックグラウンドモード用の設定
    private func configureForBackgroundMode() {
        guard isTracking else { return }
        manager.distanceFilter = 50 // バックグラウンド時は50m間隔で省電力化
        addRecoveryLog("バックグラウンドモード: 50m間隔に設定")
    }
    
    // MARK: - 復旧システム
    
    /// アプリ起動時・復帰時の状態復旧チェック
    private func performRecoveryIfNeeded() {
        guard !isRecovering else { return }
        
        let wasTrackingEnabled = UserDefaults.standard.bool(forKey: trackingStateKey)
        
        // 以前GPS追跡が有効だった場合、復旧を試行
        if wasTrackingEnabled && !isTracking {
            addRecoveryLog("復旧が必要: 以前の状態 - GPS追跡有効")
            attemptRecovery()
        } else if wasTrackingEnabled && isTracking {
            addRecoveryLog("復旧不要: GPS追跡は既に動作中")
        }
    }
    
    /// 復旧処理の実行
    private func attemptRecovery() {
        isRecovering = true
        recoveryAttempts += 1
        lastRecoveryTime = Date()
        
        addRecoveryLog("復旧試行 #\(recoveryAttempts) を開始")
        
        // 権限チェック
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            addRecoveryLog("復旧失敗: 位置情報権限が不十分")
            isRecovering = false
            return
        }
        
        // GPS追跡を再開
        startTracking()
        
        // Always権限がある場合はバックグラウンド機能も復旧
        if authorizationStatus == .authorizedAlways {
            enableBackgroundLocationUpdates()
            startMonitoringSignificantLocationChanges()
            
            // Region Monitoring も復旧
            let wasRegionMonitoringEnabled = UserDefaults.standard.bool(forKey: regionMonitoringStateKey)
            if wasRegionMonitoringEnabled {
                enableRegionMonitoring()
            }
            
            addRecoveryLog("バックグラウンド機能も復旧しました")
        }
        
        addRecoveryLog("復旧試行 #\(recoveryAttempts) 完了")
        isRecovering = false
    }
    
    /// 復旧ログの追加
    private func addRecoveryLog(_ message: String) {
        let timestamp = DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] \(message)"
        
        recoveryLog.append(logEntry)
        
        // ログは最新100件まで保持
        if recoveryLog.count > 100 {
            recoveryLog.removeFirst(recoveryLog.count - 100)
        }
        
        // UserDefaultsに保存
        UserDefaults.standard.set(recoveryLog, forKey: recoveryLogKey)
        
        print("LocationService Recovery: \(logEntry)")
    }
    
    /// 復旧ログの読み込み
    private func loadRecoveryLog() {
        if let savedLog = UserDefaults.standard.array(forKey: recoveryLogKey) as? [String] {
            recoveryLog = savedLog
        }
    }
    
    /// 復旧ログをクリア
    func clearRecoveryLog() {
        recoveryLog.removeAll()
        UserDefaults.standard.removeObject(forKey: recoveryLogKey)
        addRecoveryLog("復旧ログをクリアしました")
    }
    
    /// 手動復旧の実行（ユーザー操作用）
    func forceRecovery() {
        addRecoveryLog("手動復旧を実行")
        attemptRecovery()
    }
    
    // MARK: - Region Monitoring
    
    /// Region Monitoring を有効化
    func enableRegionMonitoring() {
        guard authorizationStatus == .authorizedAlways else {
            addRecoveryLog("Region Monitoring有効化失敗: Always権限が必要")
            return
        }
        
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            addRecoveryLog("Region Monitoring有効化失敗: デバイスが対応していません")
            return
        }
        
        isRegionMonitoringEnabled = true
        UserDefaults.standard.set(true, forKey: regionMonitoringStateKey)
        
        // 現在地がある場合は即座に監視開始
        if let currentLocation = current {
            updateRegionMonitoring(around: currentLocation)
        }
        
        addRecoveryLog("Region Monitoring を有効化しました")
    }
    
    /// Region Monitoring を無効化
    func disableRegionMonitoring() {
        isRegionMonitoringEnabled = false
        UserDefaults.standard.set(false, forKey: regionMonitoringStateKey)
        
        // 現在監視中の地域があれば停止
        if let region = currentMonitoredRegion {
            manager.stopMonitoring(for: region)
            currentMonitoredRegion = nil
        }
        
        addRecoveryLog("Region Monitoring を無効化しました")
    }
    
    /// 指定位置周辺の地域監視を更新
    private func updateRegionMonitoring(around location: CLLocation) {
        guard isRegionMonitoringEnabled else { return }
        
        let newCenter = location.coordinate
        
        // 既存の監視地域があり、中心からの距離が100m以内なら更新不要
        if let existingRegion = currentMonitoredRegion {
            let existingCenter = CLLocation(latitude: existingRegion.center.latitude, 
                                          longitude: existingRegion.center.longitude)
            let distance = location.distance(from: existingCenter)
            
            if distance < 100 {
                return // 更新不要
            }
            
            // 既存の監視を停止
            manager.stopMonitoring(for: existingRegion)
        }
        
        // 新しい地域監視を開始
        let newRegion = CLCircularRegion(center: newCenter, 
                                       radius: regionRadius, 
                                       identifier: regionIdentifier)
        newRegion.notifyOnEntry = true
        newRegion.notifyOnExit = true
        
        manager.startMonitoring(for: newRegion)
        currentMonitoredRegion = newRegion
        
        // 状態を保存
        let centerData = [
            "latitude": newCenter.latitude,
            "longitude": newCenter.longitude
        ]
        UserDefaults.standard.set(centerData, forKey: lastRegionCenterKey)
        
        addRecoveryLog("地域監視を更新: 中心(\(newCenter.latitude), \(newCenter.longitude)) 半径\(regionRadius)m")
    }
    
    /// Region イベントログの追加
    private func addRegionEvent(_ event: String) {
        let timestamp = DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] \(event)"
        
        regionEvents.append(logEntry)
        
        // イベントログは最新50件まで保持
        if regionEvents.count > 50 {
            regionEvents.removeFirst(regionEvents.count - 50)
        }
        
        print("LocationService Region: \(logEntry)")
    }
    
    /// Region イベントログをクリア
    func clearRegionEvents() {
        regionEvents.removeAll()
        addRegionEvent("地域イベントログをクリアしました")
    }
    
    // MARK: - Background App Refresh
    
    /// Background App Refresh の状態をチェック
    private func checkBackgroundAppRefreshStatus() {
        backgroundAppRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        backgroundRefreshAvailable = backgroundAppRefreshStatus == .available
        
        let statusText: String
        switch backgroundAppRefreshStatus {
        case .available:
            statusText = "利用可能"
        case .denied:
            statusText = "無効（ユーザー設定）"
        case .restricted:
            statusText = "制限されています"
        @unknown default:
            statusText = "不明"
        }
        
        addRecoveryLog("Background App Refresh 状態: \(statusText)")
        
        // 無効な場合は対処法をログに記録
        if !backgroundRefreshAvailable {
            addRecoveryLog("推奨: Background App Refresh を有効にしてください（設定 > アプリ名 > Background App Refresh）")
        }
    }
    
    /// Background App Refresh の状態を更新（フォアグラウンド復帰時用）
    func updateBackgroundAppRefreshStatus() {
        checkBackgroundAppRefreshStatus()
    }
    
    /// Background App Refresh のガイダンスメッセージを取得
    var backgroundRefreshGuidanceMessage: String {
        switch backgroundAppRefreshStatus {
        case .available:
            return "Background App Refresh が有効です。バックグラウンドでの動作が最適化されています。"
        case .denied:
            let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "このアプリ"
            return "Background App Refresh が無効です。設定 > \(appName) > Background App Refresh を有効にすることで、バックグラウンド動作が改善されます。"
        case .restricted:
            return "Background App Refresh が制限されています。デバイスの制限により、バックグラウンド動作が制限される場合があります。"
        @unknown default:
            return "Background App Refresh の状態が不明です。"
        }
    }
    
    /// 設定アプリのBackground App Refresh画面を開く
    func openBackgroundRefreshSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
            addRecoveryLog("Background App Refresh 設定画面を開きました")
        }
    }
    
    // MARK: - エラーハンドリング
    
    /// Location エラーの処理
    private func handleLocationError(_ error: Error) {
        lastError = error.localizedDescription
        lastErrorTime = Date()
        consecutiveErrors += 1
        
        addRecoveryLog("位置情報エラー #\(consecutiveErrors): \(error.localizedDescription)")
        
        // 連続エラーが3回以上の場合、自動復旧を試行
        if consecutiveErrors >= 3 {
            addRecoveryLog("連続エラー\(consecutiveErrors)回：自動復旧を開始")
            scheduleErrorRecovery()
        }
    }
    
    /// エラー復旧のスケジューリング
    private func scheduleErrorRecovery() {
        // 既存のタイマーをキャンセル
        errorRetryTimer?.invalidate()
        
        // 10秒後に復旧を試行
        errorRetryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.attemptErrorRecovery()
            }
        }
        
        addRecoveryLog("10秒後にエラー復旧を試行します")
    }
    
    /// エラーからの復旧試行
    private func attemptErrorRecovery() {
        guard consecutiveErrors > 0 else { return }
        
        addRecoveryLog("エラー復旧を試行中...")
        
        // Location Manager の状態をリセット
        if isTracking {
            manager.stopUpdatingLocation()
            
            // 少し待ってから再開
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways {
                    self.manager.startUpdatingLocation()
                    self.addRecoveryLog("GPS追跡を再開しました")
                }
            }
        }
        
        // Region Monitoring もリセット
        if isRegionMonitoringEnabled, let currentLocation = current {
            updateRegionMonitoring(around: currentLocation)
        }
        
        // 復旧成功時の処理は didUpdateLocations で行われる
    }
    
    /// エラーカウンターのリセット（成功時に呼ばれる）
    private func resetErrorCount() {
        if consecutiveErrors > 0 {
            addRecoveryLog("エラー復旧成功：連続エラーカウンターをリセット")
            consecutiveErrors = 0
            lastError = nil
            errorRetryTimer?.invalidate()
            errorRetryTimer = nil
        }
    }
    
    /// 手動でエラーを解決
    func clearErrors() {
        consecutiveErrors = 0
        lastError = nil
        lastErrorTime = nil
        errorRetryTimer?.invalidate()
        errorRetryTimer = nil
        addRecoveryLog("エラー状態を手動でクリアしました")
    }
    
    // MARK: - Strategy Management
    
    /// Strategyを初期化
    private func initializeStrategies() {
        // 全てのStrategyを作成
        for strategyType in LocationAcquisitionStrategyType.allCases {
            strategies[strategyType] = LocationAcquisitionStrategyFactory.createStrategy(type: strategyType)
        }
        
        // 保存されたStrategyタイプを読み込み
        if let savedStrategyRawValue = UserDefaults.standard.string(forKey: currentStrategyTypeKey),
           let savedStrategyType = LocationAcquisitionStrategyType(rawValue: savedStrategyRawValue) {
            currentStrategyType = savedStrategyType
        }
        
        // 現在のStrategyを設定
        currentStrategy = strategies[currentStrategyType]
        
        addRecoveryLog("Strategy初期化完了: \(currentStrategyType.displayName)")
    }
    
    /// Strategyを変更
    func changeStrategy(to strategyType: LocationAcquisitionStrategyType) {
        guard strategyType != currentStrategyType else { return }
        
        let wasTracking = isTracking
        
        // 現在のStrategyを停止
        if wasTracking {
            currentStrategy?.stop(with: manager)
        }
        
        // 新しいStrategyに変更
        currentStrategyType = strategyType
        currentStrategy = strategies[strategyType]
        
        // 状態を保存
        UserDefaults.standard.set(strategyType.rawValue, forKey: currentStrategyTypeKey)
        
        // 追跡中だった場合は新しいStrategyで再開
        if wasTracking {
            currentStrategy?.start(with: manager, delegate: self)
        }
        
        addRecoveryLog("Strategy変更: \(strategyType.displayName)")
    }
    
    /// 現在のStrategyの統計情報を取得
    func getCurrentStrategyStatistics() -> StrategyStatistics? {
        return currentStrategy?.statistics
    }
    
    /// 全Strategyの統計情報を取得
    func getAllStrategyStatistics() -> [LocationAcquisitionStrategyType: StrategyStatistics] {
        var result: [LocationAcquisitionStrategyType: StrategyStatistics] = [:]
        for (type, strategy) in strategies {
            result[type] = strategy.statistics
        }
        return result
    }
    
    /// 現在のStrategyの統計をリセット
    func resetCurrentStrategyStatistics() {
        currentStrategy?.resetStatistics()
        addRecoveryLog("Strategy統計をリセット: \(currentStrategyType.displayName)")
    }
    
    /// 全Strategyの統計をリセット
    func resetAllStrategyStatistics() {
        for strategy in strategies.values {
            strategy.resetStatistics()
        }
        addRecoveryLog("全Strategy統計をリセット")
    }
}
