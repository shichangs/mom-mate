//
//  NotesManager.swift
//  MomMate
//
//  Manages markdown notes storage
//

import Foundation

class NotesManager: ObservableObject, CloudSyncObserver {
    @Published var notes: String = ""

    let store = CloudSyncStore(storageKey: StorageKeys.notes)

    init() {
        store.setupObservers(for: self)
        loadNotes()
        if notes.isEmpty {
            initializeDefaultNotes()
        }
    }

    deinit {
        store.teardownObservers()
    }

    func reloadFromStore() { loadNotes() }
    func pushCurrentDataToCloud() { store.pushStringToCloud(notes) }

    func saveNotes() {
        store.saveString(notes)
    }

    func loadNotes() {
        notes = store.loadString()
    }

    func clearAllData() {
        notes = ""
        saveNotes()
    }

    private func initializeDefaultNotes() {
        notes = NotesManager.defaultNotesContent(formattedDate: formatDate(Date()))
        saveNotes()
    }

    private func formatDate(_ date: Date) -> String {
        DateFormatters.fullDateTimeZhCN.string(from: date)
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
