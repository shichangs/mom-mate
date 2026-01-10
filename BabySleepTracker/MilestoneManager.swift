//
//  MilestoneManager.swift
//  BabySleepTracker
//
//  Manages milestones storage and retrieval
//

import Foundation

class MilestoneManager: ObservableObject {
    @Published var milestones: [Milestone] = []
    
    private let milestonesKey = "Milestones"
    
    init() {
        loadMilestones()
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
        if let encoded = try? JSONEncoder().encode(milestones) {
            UserDefaults.standard.set(encoded, forKey: milestonesKey)
        }
    }
    
    private func loadMilestones() {
        if let data = UserDefaults.standard.data(forKey: milestonesKey),
           let decoded = try? JSONDecoder().decode([Milestone].self, from: data) {
            milestones = decoded
        }
    }
}

