//
//  MilestoneManager.swift
//  MomMate
//
//  Manages milestones storage and retrieval
//

import Foundation

class MilestoneManager: ObservableObject, CloudSyncObserver {
    @Published var milestones: [Milestone] = []

    let store = CloudSyncStore(storageKey: StorageKeys.milestones)

    init() {
        store.setupObservers(for: self)
        loadMilestones()
    }

    deinit {
        store.teardownObservers()
    }

    func reloadFromStore() { loadMilestones() }
    func pushCurrentDataToCloud() { store.pushToCloud(milestones) }

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

}
