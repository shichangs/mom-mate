//
//  SleepRecordManager.swift
//  MomMate
//
//  Manages sleep records storage and retrieval
//

import Foundation

class SleepRecordManager: ObservableObject, CloudSyncObserver {
    @Published private(set) var records: [SleepRecord] = []

    let store = CloudSyncStore(storageKey: StorageKeys.sleepRecords)
    private let calendar = Calendar.current

    private struct DaySummary {
        var totalDuration: TimeInterval = 0
        var count: Int = 0
    }

    private var recordIndexByID: [UUID: Int] = [:]
    private var completedRecordsCache: [SleepRecord] = []
    private var currentSleepRecordCache: SleepRecord?
    private var wakeDaySummaries: [Date: DaySummary] = [:]

    init() {
        store.setupObservers(for: self)
        loadRecords()
#if DEBUG
        if records.isEmpty && !UserDefaults.standard.bool(forKey: StorageKeys.testDataGenerated) {
            generateTestData()
            UserDefaults.standard.set(true, forKey: StorageKeys.testDataGenerated)
        }
#endif
    }

    deinit {
        store.teardownObservers()
    }

    func reloadFromStore() { loadRecords() }
    func pushCurrentDataToCloud() { store.pushToCloud(records) }

    func startSleep() {
        guard currentSleepRecord == nil else { return }
        let newRecord = SleepRecord(sleepTime: Date())
        records.insert(newRecord, at: 0)
        saveRecords()
    }

    func startSleep(minutesAgo: Int) {
        guard currentSleepRecord == nil else { return }
        let sleepTime = Calendar.current.date(byAdding: .minute, value: -minutesAgo, to: Date()) ?? Date()
        let newRecord = SleepRecord(sleepTime: sleepTime)
        records.insert(newRecord, at: 0)
        saveRecords()
    }

    func endSleep(for record: SleepRecord) {
        if let index = recordIndexByID[record.id] {
            let updatedRecord = SleepRecord(id: record.id, sleepTime: record.sleepTime, wakeTime: Date())
            records[index] = updatedRecord
            saveRecords()
        }
    }

    func endCurrentSleep() {
        if let currentRecord = currentSleepRecord {
            endSleep(for: currentRecord)
        }
    }

    func endCurrentSleep(minutesAgo: Int) {
        if let currentRecord = currentSleepRecord {
            let wakeTime = Calendar.current.date(byAdding: .minute, value: -minutesAgo, to: Date()) ?? Date()
            guard wakeTime > currentRecord.sleepTime else { return }
            if let index = recordIndexByID[currentRecord.id] {
                let updatedRecord = SleepRecord(id: currentRecord.id, sleepTime: currentRecord.sleepTime, wakeTime: wakeTime)
                records[index] = updatedRecord
                saveRecords()
            }
        }
    }

    func deleteRecord(_ record: SleepRecord) {
        records.removeAll { $0.id == record.id }
        saveRecords()
    }

    func updateRecord(_ record: SleepRecord, sleepTime: Date, wakeTime: Date?) {
        if let index = recordIndexByID[record.id] {
            let recordWithSameId = SleepRecord(id: record.id, sleepTime: sleepTime, wakeTime: wakeTime)
            records[index] = recordWithSameId
            saveRecords()
        }
    }

    func updateRecord(_ record: SleepRecord) {
        if let index = recordIndexByID[record.id] {
            records[index] = record
            saveRecords()
        }
    }

    var currentSleepRecord: SleepRecord? {
        currentSleepRecordCache
    }

    var completedRecords: [SleepRecord] {
        completedRecordsCache
    }

    func sleepDaySummary(for day: Date) -> (duration: TimeInterval, count: Int) {
        let key = calendar.startOfDay(for: day)
        let summary = wakeDaySummaries[key] ?? DaySummary()
        return (summary.totalDuration, summary.count)
    }

    func sleepRangeSummary(start: Date, end: Date) -> (duration: TimeInterval, count: Int) {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        guard startDay < endDay else { return (0, 0) }

        var cursor = startDay
        var totalDuration: TimeInterval = 0
        var totalCount = 0

        while cursor < endDay {
            if let summary = wakeDaySummaries[cursor] {
                totalDuration += summary.totalDuration
                totalCount += summary.count
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }

        return (totalDuration, totalCount)
    }

    // MARK: - Persistence (via CloudSyncStore)

    private func saveRecords() {
        rebuildDerivedData()
        store.save(records)
        SleepStatisticsManager.shared.invalidateCache()
    }

    private func loadRecords() {
        records = store.load([SleepRecord].self) ?? []
        rebuildDerivedData()
        SleepStatisticsManager.shared.invalidateCache()
    }

    private func rebuildDerivedData() {
        recordIndexByID = Dictionary(
            uniqueKeysWithValues: records.enumerated().map { ($0.element.id, $0.offset) }
        )
        currentSleepRecordCache = records.first(where: { $0.isSleeping })
        completedRecordsCache = records.filter { !$0.isSleeping }

        var summaries: [Date: DaySummary] = [:]
        for record in completedRecordsCache {
            guard let wakeTime = record.wakeTime,
                  let duration = record.duration else { continue }
            let key = calendar.startOfDay(for: wakeTime)
            var summary = summaries[key] ?? DaySummary()
            summary.totalDuration += duration
            summary.count += 1
            summaries[key] = summary
        }
        wakeDaySummaries = summaries
    }

    // MARK: - Test data generation

    func generateTestData() {
        let calendar = Calendar.current
        let now = Date()
        var testRecords: [SleepRecord] = []

        for monthOffset in 0..<3 {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now),
                  let monthDate = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart)) else { continue }

            let recordsPerMonth = Int.random(in: 25...30)

            for _ in 0..<recordsPerMonth {
                let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 30
                let maxDay = monthOffset == 0 ? calendar.component(.day, from: now) : daysInMonth
                let randomDay = Int.random(in: 1...maxDay)

                guard let recordDate = calendar.date(byAdding: .day, value: randomDay - 1, to: monthDate) else { continue }
                if recordDate > now { continue }

                let sleepHour = Int.random(in: 20...23)
                let sleepMinute = Int.random(in: 0...59)

                guard var sleepTime = calendar.date(bySettingHour: sleepHour, minute: sleepMinute, second: 0, of: recordDate) else { continue }
                if sleepTime > now {
                    sleepTime = calendar.date(byAdding: .day, value: -1, to: sleepTime) ?? sleepTime
                }

                let sleepDurationHours = Double.random(in: 7.0...11.5)
                let sleepDuration = sleepDurationHours * 3600

                guard let wakeTime = calendar.date(byAdding: .second, value: Int(sleepDuration), to: sleepTime) else { continue }
                let finalWakeTime = wakeTime > now ? now : wakeTime

                if finalWakeTime > sleepTime {
                    let record = SleepRecord(sleepTime: sleepTime, wakeTime: finalWakeTime)
                    testRecords.append(record)
                }
            }
        }

        testRecords.sort { $0.sleepTime > $1.sleepTime }
        records = testRecords
        saveRecords()
    }

    func regenerateTestData() {
        records = []
        generateTestData()
        UserDefaults.standard.set(true, forKey: StorageKeys.testDataGenerated)
    }

    func clearAllData() {
        records = []
        saveRecords()
    }

}
