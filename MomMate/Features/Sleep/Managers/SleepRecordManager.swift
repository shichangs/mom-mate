//
//  SleepRecordManager.swift
//  MomMate
//
//  Manages sleep records storage and retrieval
//

import Foundation

class SleepRecordManager: ObservableObject, CloudSyncObserver {
    @Published var records: [SleepRecord] = []

    let store = CloudSyncStore(storageKey: StorageKeys.sleepRecords)

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
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            let updatedRecord = SleepRecord(sleepTime: record.sleepTime, wakeTime: Date())
            records[index] = updatedRecord
            saveRecords()
        }
    }

    func endCurrentSleep() {
        if let currentRecord = records.first, currentRecord.isSleeping {
            endSleep(for: currentRecord)
        }
    }

    func endCurrentSleep(minutesAgo: Int) {
        if let currentRecord = records.first, currentRecord.isSleeping {
            let wakeTime = Calendar.current.date(byAdding: .minute, value: -minutesAgo, to: Date()) ?? Date()
            guard wakeTime > currentRecord.sleepTime else { return }
            if let index = records.firstIndex(where: { $0.id == currentRecord.id }) {
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
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            let recordWithSameId = SleepRecord(id: record.id, sleepTime: sleepTime, wakeTime: wakeTime)
            records[index] = recordWithSameId
            saveRecords()
        }
    }

    func updateRecord(_ record: SleepRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
            saveRecords()
        }
    }

    var currentSleepRecord: SleepRecord? {
        return records.first { $0.isSleeping }
    }

    var completedRecords: [SleepRecord] {
        return records.filter { !$0.isSleeping }
    }

    // MARK: - Persistence (via CloudSyncStore)

    private func saveRecords() {
        store.save(records)
        SleepStatisticsManager.shared.invalidateCache()
    }

    private func loadRecords() {
        records = store.load([SleepRecord].self) ?? []
        SleepStatisticsManager.shared.invalidateCache()
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
