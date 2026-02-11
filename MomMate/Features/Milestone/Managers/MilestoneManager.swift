//
//  MilestoneManager.swift
//  MomMate
//
//  Manages milestones storage and retrieval
//

import Foundation

class MilestoneManager: ObservableObject {
    @Published var milestones: [Milestone] = []

    private let store = CloudSyncStore(storageKey: StorageKeys.milestones)

    init() {
        setupObservers()
        loadMilestones()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func addMilestone(_ milestone: Milestone) {
        milestones.insert(milestone, at: 0)
        saveMilestones()
    }

    func updateMilestone(_ milestone: Milestone) {
        if let index = milestones.firstIndex(where: { $0.id == milestone.id }) {
            milestones[index] = milestone
            saveMilestones()
        }
    }

    func deleteMilestone(_ milestone: Milestone) {
        milestones.removeAll { $0.id == milestone.id }
        saveMilestones()
    }

    var sortedMilestones: [Milestone] {
        milestones.sorted { $0.date > $1.date }
    }

    func milestonesByCategory(_ category: MilestoneCategory) -> [Milestone] {
        milestones.filter { $0.category == category }.sorted { $0.date > $1.date }
    }

    // MARK: - Persistence (via CloudSyncStore)

    private func saveMilestones() {
        store.save(milestones)
    }

    private func loadMilestones() {
        milestones = store.load([Milestone].self) ?? []
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
        loadMilestones()
    }

    @objc
    private func handleUserDefaultsDidChange(_ notification: Notification) {
        let current = store.isCloudSyncEnabled
        guard current != store.lastKnownCloudSyncEnabled else { return }
        store.lastKnownCloudSyncEnabled = current
        if current {
            store.pushToCloud(milestones)
        }
        loadMilestones()
    }
}
