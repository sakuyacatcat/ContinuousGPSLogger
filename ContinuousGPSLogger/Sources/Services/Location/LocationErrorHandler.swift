//
//  LocationErrorHandler.swift
//  ContinuousGPSLogger
//
//  Created by Claude on 2025/07/24.
//

import Foundation
import CoreLocation

@MainActor
final class LocationErrorHandler: ObservableObject {
    @Published private(set) var lastError: String?
    @Published private(set) var consecutiveErrors: Int = 0
    @Published private(set) var lastErrorTime: Date?
    
    private var errorRetryTimer: Timer?
    private let recoveryService: LocationRecoveryService
    
    init(recoveryService: LocationRecoveryService) {
        self.recoveryService = recoveryService
    }
    
    /// Location エラーの処理
    func handleLocationError(
        _ error: Error,
        onErrorRecovery: @escaping () -> Void
    ) {
        lastError = error.localizedDescription
        lastErrorTime = Date()
        consecutiveErrors += 1
        
        recoveryService.addRecoveryLog("位置情報エラー #\(consecutiveErrors): \(error.localizedDescription)")
        
        // 連続エラーが3回以上の場合、自動復旧を試行
        if consecutiveErrors >= 3 {
            recoveryService.addRecoveryLog("連続エラー\(consecutiveErrors)回：自動復旧を開始")
            scheduleErrorRecovery(onErrorRecovery: onErrorRecovery)
        }
    }
    
    /// エラー復旧のスケジューリング
    private func scheduleErrorRecovery(onErrorRecovery: @escaping () -> Void) {
        // 既存のタイマーをキャンセル
        errorRetryTimer?.invalidate()
        
        // 10秒後に復旧を試行
        errorRetryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.attemptErrorRecovery(onErrorRecovery: onErrorRecovery)
            }
        }
        
        recoveryService.addRecoveryLog("10秒後にエラー復旧を試行します")
    }
    
    /// エラーからの復旧試行
    private func attemptErrorRecovery(onErrorRecovery: @escaping () -> Void) {
        guard consecutiveErrors > 0 else { return }
        
        recoveryService.addRecoveryLog("エラー復旧を試行中...")
        onErrorRecovery()
        
        // 復旧成功時の処理は didUpdateLocations で行われる
    }
    
    /// エラーカウンターのリセット（成功時に呼ばれる）
    func resetErrorCount() {
        if consecutiveErrors > 0 {
            recoveryService.addRecoveryLog("エラー復旧成功：連続エラーカウンターをリセット")
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
        recoveryService.addRecoveryLog("エラー状態を手動でクリアしました")
    }
    
    deinit {
        errorRetryTimer?.invalidate()
    }
}