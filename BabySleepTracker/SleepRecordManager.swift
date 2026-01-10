//
//  SleepRecordManager.swift
//  BabySleepTracker
//
//  Manages sleep records storage and retrieval
//

import Foundation

class SleepRecordManager: ObservableObject {
    @Published var records: [SleepRecord] = []
    
    private let recordsKey = "SleepRecords"
    private let testDataGeneratedKey = "TestDataGenerated"
    
    init() {
        loadRecords()
        // 如果没有数据且未生成过测试数据，则生成测试数据
        if records.isEmpty && !UserDefaults.standard.bool(forKey: testDataGeneratedKey) {
            generateTestData()
            UserDefaults.standard.set(true, forKey: testDataGeneratedKey)
        }
    }
    
    func startSleep() {
        let newRecord = SleepRecord(sleepTime: Date())
        records.insert(newRecord, at: 0)
        saveRecords()
    }
    
    func startSleep(minutesAgo: Int) {
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
            // 保持原有的 ID
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
    
    private func saveRecords() {
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
    }
    
    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([SleepRecord].self, from: data) {
            records = decoded
        }
    }
    
    // MARK: - 测试数据生成
    func generateTestData() {
        let calendar = Calendar.current
        let now = Date()
        var testRecords: [SleepRecord] = []
        
        // 生成过去3个月的数据，确保有足够的数据展示统计效果
        for monthOffset in 0..<3 {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now),
                  let monthDate = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart)) else { continue }
            
            // 每个月生成25-30条记录
            let recordsPerMonth = Int.random(in: 25...30)
            
            for _ in 0..<recordsPerMonth {
                // 随机选择这个月中的某一天（避免选择未来日期）
                let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 30
                let maxDay = monthOffset == 0 ? calendar.component(.day, from: now) : daysInMonth
                let randomDay = Int.random(in: 1...maxDay)
                
                guard let recordDate = calendar.date(byAdding: .day, value: randomDay - 1, to: monthDate) else { continue }
                
                // 确保日期不超过今天
                if recordDate > now {
                    continue
                }
                
                // 随机选择时间：晚上8点到11点之间入睡
                let sleepHour = Int.random(in: 20...23)
                let sleepMinute = Int.random(in: 0...59)
                
                guard var sleepTime = calendar.date(bySettingHour: sleepHour, minute: sleepMinute, second: 0, of: recordDate) else { continue }
                
                // 如果时间在未来，则往前推一天
                if sleepTime > now {
                    sleepTime = calendar.date(byAdding: .day, value: -1, to: sleepTime) ?? sleepTime
                }
                
                // 睡眠时长：6-12小时之间，更真实的数据分布
                let sleepDurationHours = Double.random(in: 7.0...11.5)
                let sleepDuration = sleepDurationHours * 3600
                
                guard let wakeTime = calendar.date(byAdding: .second, value: Int(sleepDuration), to: sleepTime) else { continue }
                
                // 确保醒来时间不超过现在
                let finalWakeTime = wakeTime > now ? now : wakeTime
                
                // 确保醒来时间晚于入睡时间
                if finalWakeTime > sleepTime {
                    let record = SleepRecord(sleepTime: sleepTime, wakeTime: finalWakeTime)
                    testRecords.append(record)
                }
            }
        }
        
        // 按时间倒序排列（最新的在前）
        testRecords.sort { $0.sleepTime > $1.sleepTime }
        
        records = testRecords
        saveRecords()
    }
    
    // 重新生成测试数据（用于测试）
    func regenerateTestData() {
        records = []
        generateTestData()
        UserDefaults.standard.set(true, forKey: testDataGeneratedKey)
    }
    
    // 清除所有数据（包括测试数据）
    func clearAllData() {
        records = []
        saveRecords()
    }
}

