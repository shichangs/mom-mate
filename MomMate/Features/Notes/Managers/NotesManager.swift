//
//  NotesManager.swift
//  MomMate
//
//  Manages markdown notes storage
//

import Foundation

class NotesManager: ObservableObject {
    @Published var notes: String = ""

    private let store = CloudSyncStore(storageKey: StorageKeys.notes)

    init() {
        setupObservers()
        loadNotes()
        if notes.isEmpty {
            initializeDefaultNotes()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func saveNotes() {
        store.saveString(notes)
    }

    func loadNotes() {
        notes = store.loadString()
    }

    private func initializeDefaultNotes() {
        notes = NotesManager.defaultNotesContent(formattedDate: formatDate(Date()))
        saveNotes()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }

    // MARK: - Observers

    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudStoreDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store.cloudStore
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserDefaultsDidChange(_:)),
            name: UserDefaults.didChangeNotification,
            object: UserDefaults.standard
        )
    }

    @objc
    private func handleCloudStoreDidChange(_ notification: Notification) {
        guard store.isCloudSyncEnabled else { return }
        loadNotes()
    }

    @objc
    private func handleUserDefaultsDidChange(_ notification: Notification) {
        let current = store.isCloudSyncEnabled
        guard current != store.lastKnownCloudSyncEnabled else { return }
        store.lastKnownCloudSyncEnabled = current
        if current {
            store.pushStringToCloud(notes)
        }
        loadNotes()
    }

    // MARK: - Default content

    static func defaultNotesContent(formattedDate: String) -> String {
        """
        # 宝宝睡眠记录应用 - 开发者文档

        ## 项目架构

        ### 技术栈
        - **SwiftUI**：UI 框架，iOS 17.0+
        - **UserDefaults + iCloud**：数据持久化与云同步
        - **Combine**：响应式数据流（@Published, ObservableObject）

        ### 核心模块
        - **Sleep** - 睡眠记录与统计
        - **Meal** - 饮食记录与食物管理
        - **Milestone** - 成长里程碑
        - **Notes** - 开发者笔记

        ## 数据流
        1. 用户操作 → Manager CRUD 方法
        2. @Published 触发 UI 更新
        3. CloudSyncStore 处理持久化与云同步

        ---
        *最后更新：\(formattedDate)*
        """
    }
}
