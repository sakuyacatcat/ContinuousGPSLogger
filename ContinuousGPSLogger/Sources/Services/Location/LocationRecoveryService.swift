//
//  LocationRecoveryService.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import Foundation
import CoreLocation

@MainActor
final class LocationRecoveryService: ObservableObject {
    @Published private(set) var recoveryAttempts: Int = 0
    @Published private(set) var lastRecoveryTime: Date?
    @Published private(set) var isRecovering: Bool = false
    @Published private(set) var recoveryLog: [String] = []
    
    private let recoveryLogKey = "LocationService.recoveryLog"
    private let trackingStateKey = "LocationService.isTrackingEnabled"
    private let regionMonitoringStateKey = "LocationService.isRegionMonitoringEnabled"
    
    init() {
        loadRecoveryLog()
    }
    
    /// 復旧ログの追加
    func addRecoveryLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: Date())
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
    
    /// アプリ起動時・復帰時の状態復旧チェック
    func performRecoveryIfNeeded(
        isCurrentlyTracking: Bool,
        permissionManager: LocationPermissionManager,
        onRecoveryNeeded: @escaping () -> Void
    ) {
        guard !isRecovering else { return }
        
        let wasTrackingEnabled = UserDefaults.standard.bool(forKey: trackingStateKey)
        
        // 以前GPS追跡が有効だった場合、復旧を試行
        if wasTrackingEnabled && !isCurrentlyTracking {
            addRecoveryLog("復旧が必要: 以前の状態 - GPS追跡有効")
            attemptRecovery(
                permissionManager: permissionManager,
                onRecoveryNeeded: onRecoveryNeeded
            )
        } else if wasTrackingEnabled && isCurrentlyTracking {
            addRecoveryLog("復旧不要: GPS追跡は既に動作中")
        }
    }
    
    /// 復旧処理の実行
    private func attemptRecovery(
        permissionManager: LocationPermissionManager,
        onRecoveryNeeded: @escaping () -> Void
    ) {
        isRecovering = true
        recoveryAttempts += 1
        lastRecoveryTime = Date()
        
        addRecoveryLog("復旧試行 #\(recoveryAttempts) を開始")
        
        // 権限チェック
        guard permissionManager.isAuthorizedForBasicTracking else {
            addRecoveryLog("復旧失敗: 位置情報権限が不十分")
            isRecovering = false
            return
        }
        
        // 復旧処理を実行
        onRecoveryNeeded()
        
        addRecoveryLog("復旧試行 #\(recoveryAttempts) 完了")
        isRecovering = false
    }
    
    /// 手動復旧の実行（ユーザー操作用）
    func forceRecovery(
        permissionManager: LocationPermissionManager,
        onRecoveryNeeded: @escaping () -> Void
    ) {
        addRecoveryLog("手動復旧を実行")
        attemptRecovery(
            permissionManager: permissionManager,
            onRecoveryNeeded: onRecoveryNeeded
        )
    }
    
    /// 追跡状態を保存
    func saveTrackingState(_ isTracking: Bool) {
        UserDefaults.standard.set(isTracking, forKey: trackingStateKey)
    }
    
    /// Region Monitoring状態を保存
    func saveRegionMonitoringState(_ isEnabled: Bool) {
        UserDefaults.standard.set(isEnabled, forKey: regionMonitoringStateKey)
    }
    
    /// Region Monitoring状態を取得
    func getRegionMonitoringState() -> Bool {
        return UserDefaults.standard.bool(forKey: regionMonitoringStateKey)
    }
}