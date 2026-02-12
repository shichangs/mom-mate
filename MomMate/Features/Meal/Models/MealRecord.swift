//
//  MealRecord.swift
//  MomMate
//
//  Meal record data model
//

import Foundation
import SwiftUI // Required for Color in MealType

struct MealRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var mealType: MealType
    var foodItems: [String]
    var amount: String // 食量描述
    var notes: String // 备注
    
    init(id: UUID = UUID(), date: Date, mealType: MealType, foodItems: [String] = [], amount: String = "", notes: String = "") {
        self.id = id
        self.date = date
        self.mealType = mealType
        self.foodItems = foodItems
        self.amount = amount
        self.notes = notes
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
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snack = "加餐"
    case milk = "奶"
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        case .milk: return "drop.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .blue
        case .snack: return .green
        case .milk: return .pink
        }
    }
}

extension MealType {
    var colorString: String {
        switch self {
        case .breakfast: return "orange"
        case .lunch: return "yellow"
        case .dinner: return "blue"
        case .snack: return "green"
        case .milk: return "pink"
        }
    }
}

struct FoodItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var sortOrder: Int
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.isArchived = isArchived
    }
}
