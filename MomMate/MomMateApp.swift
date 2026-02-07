//
//  MomMateApp.swift
//  MomMate
//
//  应用入口 - 配置 SwiftData 和 CloudKit 同步
//

import SwiftUI
import SwiftData

// MARK: - SwiftData Models (内联以确保编译索引)

@Model
final class SDSleepRecord {
    @Attribute(.unique) var id: UUID
    var sleepTime: Date
    var wakeTime: Date?
    var duration: Double?
    
    init(id: UUID = UUID(), sleepTime: Date, wakeTime: Date? = nil) {
        self.id = id
        self.sleepTime = sleepTime
        self.wakeTime = wakeTime
        if let wakeTime = wakeTime {
            self.duration = wakeTime.timeIntervalSince(sleepTime)
        } else {
            self.duration = nil
        }
    }
    
    var isSleeping: Bool { wakeTime == nil }
    
    var formattedDuration: String {
        guard let duration = duration else { return "进行中" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }
    
    // 从旧模型转换
    convenience init(from record: SleepRecord) {
        self.init(id: record.id, sleepTime: record.sleepTime, wakeTime: record.wakeTime)
    }
    
    // 转换为旧模型
    func toSleepRecord() -> SleepRecord {
        return SleepRecord(id: id, sleepTime: sleepTime, wakeTime: wakeTime)
    }
}

@Model
final class SDMealRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var mealTypeRaw: String
    var foodItems: [String]
    var amount: String
    var notes: String
    
    init(id: UUID = UUID(), date: Date, mealType: MealType, foodItems: [String] = [], amount: String = "", notes: String = "") {
        self.id = id
        self.date = date
        self.mealTypeRaw = mealType.rawValue
        self.foodItems = foodItems
        self.amount = amount
        self.notes = notes
    }
    
    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .snack }
        set { mealTypeRaw = newValue.rawValue }
    }
    
    // 从旧模型转换
    convenience init(from record: MealRecord) {
        self.init(id: record.id, date: record.date, mealType: record.mealType, foodItems: record.foodItems, amount: record.amount, notes: record.notes)
    }
    
    // 转换为旧模型
    func toMealRecord() -> MealRecord {
        return MealRecord(id: id, date: date, mealType: mealType, foodItems: foodItems, amount: amount, notes: notes)
    }
}

// MARK: - App Entry Point

@main
struct MomMateApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                SDSleepRecord.self,
                SDMealRecord.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("无法初始化 ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
