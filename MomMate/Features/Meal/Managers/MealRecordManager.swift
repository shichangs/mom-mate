//
//  MealRecordManager.swift
//  MomMate
//
//  Manages meal records storage and retrieval
//

import Foundation

class MealRecordManager: ObservableObject {
    @Published var mealRecords: [MealRecord] = []
    
    private let mealRecordsKey = "MealRecords"
    private let cloudSyncEnabledKey = "cloudSyncEnabled"
    private let syncAuthorizedKey = "sync.auth.enabled.v1"
    private let cloudStore = NSUbiquitousKeyValueStore.default
    private var lastKnownCloudSyncEnabled = (UserDefaults.standard.object(forKey: "cloudSyncEnabled") as? Bool ?? true)
        && UserDefaults.standard.bool(forKey: "sync.auth.enabled.v1")
    
    init() {
        setupObservers()
        loadMealRecords()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addMealRecord(_ record: MealRecord) {
        mealRecords.insert(record, at: 0)
        saveMealRecords()
    }
    
    func updateMealRecord(_ record: MealRecord) {
        if let index = mealRecords.firstIndex(where: { $0.id == record.id }) {
            mealRecords[index] = record
            saveMealRecords()
        }
    }
    
    func deleteMealRecord(_ record: MealRecord) {
        mealRecords.removeAll { $0.id == record.id }
        saveMealRecords()
    }
    
    var sortedMealRecords: [MealRecord] {
        mealRecords.sorted { $0.date > $1.date }
    }
    
    func mealRecordsByType(_ type: MealType) -> [MealRecord] {
        mealRecords.filter { $0.mealType == type }.sorted { $0.date > $1.date }
    }
    
    func mealRecordsForToday() -> [MealRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return mealRecords.filter { record in
            record.date >= today && record.date < tomorrow
        }.sorted { $0.date > $1.date }
    }
    
    private func saveMealRecords() {
        guard let encoded = try? JSONEncoder().encode(mealRecords) else { return }
        UserDefaults.standard.set(encoded, forKey: mealRecordsKey)
        if isCloudSyncEnabled {
            cloudStore.set(encoded, forKey: mealRecordsKey)
            cloudStore.synchronize()
        }
    }
    
    private func loadMealRecords() {
        let data: Data?
        if isCloudSyncEnabled {
            cloudStore.synchronize()
            data = cloudStore.data(forKey: mealRecordsKey) ?? UserDefaults.standard.data(forKey: mealRecordsKey)
        } else {
            data = UserDefaults.standard.data(forKey: mealRecordsKey)
        }
        
        guard let data,
              let decoded = try? JSONDecoder().decode([MealRecord].self, from: data) else {
            mealRecords = []
            return
        }
        mealRecords = decoded
    }
    
    private var isCloudSyncEnabled: Bool {
        let cloudSyncEnabled = UserDefaults.standard.object(forKey: cloudSyncEnabledKey) as? Bool ?? true
        let syncAuthorized = UserDefaults.standard.bool(forKey: syncAuthorizedKey)
        return cloudSyncEnabled && syncAuthorized
    }
    
    private func pushCurrentRecordsToCloud() {
        guard let encoded = try? JSONEncoder().encode(mealRecords) else { return }
        cloudStore.set(encoded, forKey: mealRecordsKey)
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
        loadMealRecords()
    }
    
    @objc
    private func handleUserDefaultsDidChange(_ notification: Notification) {
        let current = isCloudSyncEnabled
        guard current != lastKnownCloudSyncEnabled else { return }
        lastKnownCloudSyncEnabled = current
        
        if current {
            pushCurrentRecordsToCloud()
        }
        loadMealRecords()
    }
}
