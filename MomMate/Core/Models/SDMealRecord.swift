//
//  SDMealRecord.swift
//  MomMate
//
//  SwiftData model for meal records with CloudKit sync support
//

import Foundation
import SwiftData
import SwiftUI

@available(*, deprecated, message: "Current app data source is UserDefaults via MealRecordManager.")
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
    
    var formattedDate: String {
        DateFormatters.fullDateTimeZhCN.string(from: date)
    }
    
    var formattedTime: String {
        DateFormatters.time24ZhCN.string(from: date)
    }
    
    var relativeTime: String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date, to: now)
        
        if let hours = components.hour, let minutes = components.minute {
            if hours == 0 && minutes < 30 {
                return "刚刚"
            } else if hours == 0 {
                return "\(minutes)分钟前"
            } else if hours < 24 {
                return "\(hours)小时前"
            } else {
                let days = hours / 24
                return "\(days)天前"
            }
        }
        return formattedTime
    }
    
    // 从旧模型转换
    convenience init(from record: MealRecord) {
        self.init(id: record.id, date: record.date, mealType: record.mealType, foodItems: record.foodItems, amount: record.amount, notes: record.notes)
    }
    
    // 转换为旧模型（用于兼容现有视图）
    func toMealRecord() -> MealRecord {
        return MealRecord(id: id, date: date, mealType: mealType, foodItems: foodItems, amount: amount, notes: notes)
    }
}
