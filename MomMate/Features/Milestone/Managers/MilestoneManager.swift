//
//  MilestoneManager.swift
//  MomMate
//
//  Manages milestones storage and retrieval
//

import Foundation

class MilestoneManager: ObservableObject, CloudSyncObserver {
    @Published private(set) var milestones: [Milestone] = []

    let store = CloudSyncStore(storageKey: StorageKeys.milestones)
    private var milestoneIndexByID: [UUID: Int] = [:]
    private var sortedMilestonesCache: [Milestone] = []
    private var milestonesByCategoryCache: [MilestoneCategory: [Milestone]] = [:]
    private var milestoneCountByCategory: [MilestoneCategory: Int] = [:]

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
        if let index = milestoneIndexByID[milestone.id] {
            milestones[index] = milestone
            saveMilestones()
        }
    }

    func deleteMilestone(_ milestone: Milestone) {
        milestones.removeAll { $0.id == milestone.id }
        saveMilestones()
    }

    var sortedMilestones: [Milestone] {
        sortedMilestonesCache
    }

    func milestonesByCategory(_ category: MilestoneCategory) -> [Milestone] {
        milestonesByCategoryCache[category] ?? []
    }

    func milestoneCount(for category: MilestoneCategory) -> Int {
        milestoneCountByCategory[category] ?? 0
    }

    var unlockedCategoryCount: Int {
        milestoneCountByCategory.values.filter { $0 > 0 }.count
    }

    func clearAllData() {
        milestones = []
        saveMilestones()
    }

    // MARK: - Persistence (via CloudSyncStore)

    private func saveMilestones() {
        rebuildDerivedData()
        store.save(milestones)
    }

    private func loadMilestones() {
        milestones = store.load([Milestone].self) ?? []
        rebuildDerivedData()
    }

    private func rebuildDerivedData() {
        milestoneIndexByID = Dictionary(
            uniqueKeysWithValues: milestones.enumerated().map { ($0.element.id, $0.offset) }
        )
        sortedMilestonesCache = milestones.sorted { $0.date > $1.date }

        var grouped: [MilestoneCategory: [Milestone]] = [:]
        var counts: [MilestoneCategory: Int] = [:]
        for milestone in sortedMilestonesCache {
            grouped[milestone.category, default: []].append(milestone)
            counts[milestone.category, default: 0] += 1
        }
        milestonesByCategoryCache = grouped
        milestoneCountByCategory = counts
    }

}
