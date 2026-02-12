//
//  MealRecordManager.swift
//  MomMate
//
//  Manages meal records storage and retrieval
//

import Foundation

class MealRecordManager: ObservableObject, CloudSyncObserver {
    @Published private(set) var mealRecords: [MealRecord] = []

    let store = CloudSyncStore(storageKey: StorageKeys.mealRecords)
    private let calendar = Calendar.current

    private struct DaySummary {
        var totalCount: Int = 0
        var typeCounts: [MealType: Int] = [:]
    }

    private var recordIndexByID: [UUID: Int] = [:]
    private var sortedMealRecordsCache: [MealRecord] = []
    private var mealRecordsByTypeCache: [MealType: [MealRecord]] = [:]
    private var todayRecordsCache: [MealRecord] = []
    private var daySummaries: [Date: DaySummary] = [:]

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
        if let index = recordIndexByID[record.id] {
            mealRecords[index] = record
            saveMealRecords()
        }
    }

    func deleteMealRecord(_ record: MealRecord) {
        mealRecords.removeAll { $0.id == record.id }
        saveMealRecords()
    }

    var sortedMealRecords: [MealRecord] {
        sortedMealRecordsCache
    }

    func mealRecordsByType(_ type: MealType) -> [MealRecord] {
        mealRecordsByTypeCache[type] ?? []
    }

    func mealRecordsForToday() -> [MealRecord] {
        todayRecordsCache
    }

    func mealDaySummary(for day: Date) -> (totalCount: Int, typeCounts: [MealType: Int]) {
        let key = calendar.startOfDay(for: day)
        let summary = daySummaries[key] ?? DaySummary()
        return (summary.totalCount, summary.typeCounts)
    }

    func mealRangeSummary(start: Date, end: Date) -> (totalCount: Int, typeCounts: [MealType: Int]) {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        guard startDay < endDay else { return (0, [:]) }

        var cursor = startDay
        var total = 0
        var typeCounts: [MealType: Int] = [:]

        while cursor < endDay {
            if let summary = daySummaries[cursor] {
                total += summary.totalCount
                for (type, count) in summary.typeCounts {
                    typeCounts[type, default: 0] += count
                }
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return (total, typeCounts)
    }

    // MARK: - Persistence (via CloudSyncStore)

    private func saveMealRecords() {
        rebuildDerivedData()
        store.save(mealRecords)
    }

    private func loadMealRecords() {
        mealRecords = store.load([MealRecord].self) ?? []
        rebuildDerivedData()
    }

    private func rebuildDerivedData() {
        recordIndexByID = Dictionary(
            uniqueKeysWithValues: mealRecords.enumerated().map { ($0.element.id, $0.offset) }
        )
        sortedMealRecordsCache = mealRecords.sorted { $0.date > $1.date }

        var byType: [MealType: [MealRecord]] = [:]
        var summaries: [Date: DaySummary] = [:]
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        var todayRecords: [MealRecord] = []

        for record in sortedMealRecordsCache {
            byType[record.mealType, default: []].append(record)

            let dayKey = calendar.startOfDay(for: record.date)
            var summary = summaries[dayKey] ?? DaySummary()
            summary.totalCount += 1
            summary.typeCounts[record.mealType, default: 0] += 1
            summaries[dayKey] = summary

            if record.date >= today && record.date < tomorrow {
                todayRecords.append(record)
            }
        }

        mealRecordsByTypeCache = byType
        daySummaries = summaries
        todayRecordsCache = todayRecords
    }

}

final class FoodCatalogManager: ObservableObject {
    @Published private(set) var items: [FoodItem] = []

    private let store = CloudSyncStore(storageKey: StorageKeys.foodCatalog)
    private let defaults = UserDefaults.standard

    private static let defaultFoods = [
        "米粥", "面条", "馒头", "面包", "燕麦",
        "鸡蛋", "豆腐", "鸡肉", "鱼肉",
        "香蕉", "苹果", "牛油果", "蓝莓",
        "红薯", "胡萝卜", "西兰花", "南瓜", "土豆",
        "母乳", "配方奶", "酸奶"
    ]

    init() {
        loadCatalog()
    }

    var activeItems: [FoodItem] {
        items
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var activeNames: [String] {
        activeItems.map(\.name)
    }

    func addFood(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let normalized = normalizedKey(trimmed)
        if items.contains(where: { normalizedKey($0.name) == normalized && !$0.isArchived }) {
            return
        }

        var snapshot = items
        let nextOrder = (snapshot.map(\.sortOrder).max() ?? -1) + 1
        snapshot.append(FoodItem(name: trimmed, sortOrder: nextOrder))
        commit(snapshot)
    }

    func removeFoods(at offsets: IndexSet) {
        let visible = activeItems
        let idsToRemove = offsets.compactMap { index in
            visible.indices.contains(index) ? visible[index].id : nil
        }
        guard !idsToRemove.isEmpty else { return }

        let idSet = Set(idsToRemove)
        let snapshot = items.filter { !idSet.contains($0.id) }
        commit(snapshot)
    }

    func moveFoods(from source: IndexSet, to destination: Int) {
        let reorderedActive = moved(activeItems, from: source, to: destination)
        let activeIDSet = Set(reorderedActive.map(\.id))
        let archived = items.filter { !activeIDSet.contains($0.id) }

        var normalized = reorderedActive.enumerated().map { offset, item in
            var updated = item
            updated.sortOrder = offset
            return updated
        }
        normalized.append(contentsOf: archived)
        commit(normalized)
    }

    private func loadCatalog() {
        if let stored = store.load([FoodItem].self) {
            items = normalizeSortOrder(stored)
            return
        }

        if let legacyData = defaults.data(forKey: StorageKeys.legacySavedFoodList),
           let legacyNames = try? JSONDecoder().decode([String].self, from: legacyData),
           !legacyNames.isEmpty {
            let migrated = buildItems(from: legacyNames)
            commit(migrated)
            return
        }

        commit(buildItems(from: Self.defaultFoods))
    }

    private func commit(_ next: [FoodItem]) {
        let normalized = normalizeSortOrder(next)
        items = normalized
        store.save(normalized)
    }

    private func buildItems(from names: [String]) -> [FoodItem] {
        var seen: Set<String> = []
        var result: [FoodItem] = []

        for raw in names {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let key = normalizedKey(trimmed)
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(FoodItem(name: trimmed, sortOrder: result.count))
        }

        return result
    }

    private func normalizeSortOrder(_ items: [FoodItem]) -> [FoodItem] {
        let active = items
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
            .enumerated()
            .map { index, item in
                var updated = item
                updated.sortOrder = index
                return updated
            }
        let archived = items.filter { $0.isArchived }
        return active + archived
    }

    private func normalizedKey(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func moved(_ items: [FoodItem], from source: IndexSet, to destination: Int) -> [FoodItem] {
        guard !source.isEmpty else { return items }

        var mutable = items
        let movingItems = source.compactMap { index in
            mutable.indices.contains(index) ? mutable[index] : nil
        }

        for index in source.sorted(by: >) where mutable.indices.contains(index) {
            mutable.remove(at: index)
        }

        let sourceBeforeDestination = source.filter { $0 < destination }.count
        let target = max(0, min(destination - sourceBeforeDestination, mutable.count))
        mutable.insert(contentsOf: movingItems, at: target)
        return mutable
    }
}
