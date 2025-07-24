// MARK: - Background Task
import BackgroundTasks     // ← 追加

extension PersistenceService {
    func flush(task: BGProcessingTask) {
        purge(olderThan: 30)                       // ① 古いデータ削除
        task.expirationHandler = {                 // ② タイムアウト時の保険
            task.setTaskCompleted(success: false)
        }
        try? container.viewContext.save()          // ③ 残りの変更を保存
        task.setTaskCompleted(success: true)       // ④ 完了通知

        // ⑤ 次回 15 分後に再スケジューリング
        let req = BGProcessingTaskRequest(identifier: Self.flushID)
        req.earliestBeginDate = .now.addingTimeInterval(60 * 15)
        try? BGTaskScheduler.shared.submit(req)
    }

    static let flushID = "logger.flush"            // ← まとめておくとミスしない
}
