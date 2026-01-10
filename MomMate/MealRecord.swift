//
//  MealRecord.swift
//  MomMate
//
//  Meal record data model
//

import Foundation
import SwiftUI

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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
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

// MARK: - 辅食推荐数据
struct FoodRecommendation {
    let age: Int // 月龄
    let category: String
    let foods: [String]
    let tips: String
    
    static let recommendations: [FoodRecommendation] = [
        FoodRecommendation(
            age: 4,
            category: "初期辅食",
            foods: ["米糊", "南瓜泥", "胡萝卜泥", "苹果泥", "香蕉泥"],
            tips: "从单一食材开始，每次只添加一种新食物，观察3-5天无过敏反应后再添加下一种"
        ),
        FoodRecommendation(
            age: 5,
            category: "初期辅食",
            foods: ["土豆泥", "红薯泥", "梨泥", "牛油果泥", "菠菜泥"],
            tips: "继续添加单一食材，可以开始尝试混合两种已尝试过的食物"
        ),
        FoodRecommendation(
            age: 6,
            category: "中期辅食",
            foods: ["蛋黄", "豆腐", "鸡肉泥", "鱼肉泥", "西兰花泥"],
            tips: "可以开始添加蛋白质食物，确保完全煮熟并打成泥状"
        ),
        FoodRecommendation(
            age: 7,
            category: "中期辅食",
            foods: ["瘦肉泥", "猪肝泥", "三文鱼泥", "小米粥", "软面条"],
            tips: "可以尝试更丰富的蛋白质来源，食物可以稍微粗糙一些"
        ),
        FoodRecommendation(
            age: 8,
            category: "后期辅食",
            foods: ["软米饭", "小馄饨", "蒸蛋羹", "软水果块", "手指食物"],
            tips: "可以开始添加手指食物，锻炼宝宝的抓握能力和咀嚼能力"
        ),
        FoodRecommendation(
            age: 9,
            category: "后期辅食",
            foods: ["软面包", "小饼干", "软蔬菜块", "软水果块", "肉末"],
            tips: "食物可以切成小块，让宝宝自己抓取，培养自主进食能力"
        ),
        FoodRecommendation(
            age: 10,
            category: "后期辅食",
            foods: ["软米饭", "软面条", "小饺子", "软蔬菜", "软水果"],
            tips: "可以尝试更多种类的食物，注意食物的软硬程度，避免过硬的食物"
        ),
        FoodRecommendation(
            age: 11,
            category: "后期辅食",
            foods: ["软米饭", "软面条", "小包子", "软蔬菜", "软水果"],
            tips: "继续丰富食物种类，可以尝试更多家庭常吃的食物"
        ),
        FoodRecommendation(
            age: 12,
            category: "过渡期",
            foods: ["软米饭", "软面条", "小饺子", "软蔬菜", "软水果", "全蛋"],
            tips: "可以开始尝试全蛋，食物可以更接近成人食物，但要注意软硬程度"
        )
    ]
    
    static func recommendationsForAge(_ ageInMonths: Int) -> [FoodRecommendation] {
        return recommendations.filter { $0.age <= ageInMonths }
    }
}

