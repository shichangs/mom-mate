//
//  MealRecordManager.swift
//  MomMate
//
//  Manages meal records storage and retrieval
//

import Foundation

class MealRecordManager: ObservableObject, CloudSyncObserver {
    @Published var mealRecords: [MealRecord] = []

    let store = CloudSyncStore(storageKey: StorageKeys.mealRecords)

    init() {
        store.setupObservers(for: self)
        loadMealRecords()
    }

    deinit {
        store.teardownObservers()
    }

    func reloadFromStore() { loadMealRecords() }
    func pushCurrentDataToCloud() { store.pushToCloud(mealRecords) }

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
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return [] }

        return mealRecords.filter { record in
            record.date >= today && record.date < tomorrow
        }.sorted { $0.date > $1.date }
    }

    // MARK: - Persistence (via CloudSyncStore)

    private func saveMealRecords() {
        store.save(mealRecords)
    }

    private func loadMealRecords() {
        mealRecords = store.load([MealRecord].self) ?? []
    }

}
