//
//  ContinuousGPSLoggerApp.swift
//  ContinuousGPSLogger
//
//  Created by Shingo Takagi on 2025/07/03.
//

import SwiftUI
import BackgroundTasks

@main
struct ContinuousGPSLoggerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let ctx = PersistenceService.shared.container.viewContext

    var body: some Scene {
        WindowGroup {
            TabView {
                MainView()                    // ← 位置をライブ表示
                    .tabItem {
                        Label("現在地", systemImage: "location.fill")
                    }

                NavigationStack {             // 履歴は Navigation 付きに
                    HistoryView()
                }
                .tabItem {
                    Label("履歴", systemImage: "list.bullet.rectangle")
                }
            }
            .environment(\.managedObjectContext, ctx)   // ← ここが重要
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ app: UIApplication,
        didFinishLaunchingWithOptions opts: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // ① タスク登録
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: PersistenceService.flushID,
            using: nil) { task in
                guard let task = task as? BGProcessingTask else { return }
                Task { @MainActor in
                    PersistenceService.shared.flush(task: task)
                }
        }

        // ② 最初のスケジュール（アプリ起動時に一度だけ）
        scheduleFlush()

        return true
    }

    private func scheduleFlush() {
        let req = BGProcessingTaskRequest(identifier: PersistenceService.flushID)
        req.requiresNetworkConnectivity = false
        req.requiresExternalPower      = false
        req.earliestBeginDate = .now.addingTimeInterval(60 * 15)

        do { try BGTaskScheduler.shared.submit(req) }
        catch { print("BGTask submit error:", error) }
    }
}
