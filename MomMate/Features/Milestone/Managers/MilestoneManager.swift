//
//  MilestoneManager.swift
//  MomMate
//
//  Manages milestones storage and retrieval
//

import Foundation

class MilestoneManager: ObservableObject {
    @Published var milestones: [Milestone] = []
    
    private let milestonesKey = "Milestones"
    private let cloudSyncEnabledKey = "cloudSyncEnabled"
    private let cloudStore = NSUbiquitousKeyValueStore.default
    private var lastKnownCloudSyncEnabled = UserDefaults.standard.object(forKey: "cloudSyncEnabled") as? Bool ?? true
    
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
    
    private func saveMilestones() {
        guard let encoded = try? JSONEncoder().encode(milestones) else { return }
        UserDefaults.standard.set(encoded, forKey: milestonesKey)
        if isCloudSyncEnabled {
            cloudStore.set(encoded, forKey: milestonesKey)
            cloudStore.synchronize()
        }
    }
    
    private func loadMilestones() {
        let data: Data?
        if isCloudSyncEnabled {
            cloudStore.synchronize()
            data = cloudStore.data(forKey: milestonesKey) ?? UserDefaults.standard.data(forKey: milestonesKey)
        } else {
            data = UserDefaults.standard.data(forKey: milestonesKey)
        }
        
        guard let data,
              let decoded = try? JSONDecoder().decode([Milestone].self, from: data) else {
            milestones = []
            return
        }
        milestones = decoded
    }
    
    private var isCloudSyncEnabled: Bool {
        UserDefaults.standard.object(forKey: cloudSyncEnabledKey) as? Bool ?? true
    }
    
    private func pushCurrentRecordsToCloud() {
        guard let encoded = try? JSONEncoder().encode(milestones) else { return }
        cloudStore.set(encoded, forKey: milestonesKey)
        cloudStore.synchronize()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudStoreDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
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
        guard isCloudSyncEnabled else { return }
        loadMilestones()
    }
    
    @objc
    private func handleUserDefaultsDidChange(_ notification: Notification) {
        let current = isCloudSyncEnabled
        guard current != lastKnownCloudSyncEnabled else { return }
        lastKnownCloudSyncEnabled = current
        
        if current {
            pushCurrentRecordsToCloud()
        }
        loadMilestones()
    }
}
