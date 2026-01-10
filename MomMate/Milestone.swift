//
//  Milestone.swift
//  MomMate
//
//  Milestone data model
//

import Foundation

struct Milestone: Identifiable, Codable {
    let id: UUID
    var date: Date
    var title: String
    var description: String
    var category: MilestoneCategory
    
    init(id: UUID = UUID(), date: Date, title: String, description: String = "", category: MilestoneCategory = .other) {
        self.id = id
        self.date = date
        self.title = title
        self.description = description
        self.category = category
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var relativeDate: String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: now)
        
        if let days = components.day {
            if days == 0 {
                return "今天"
            } else if days == 1 {
                return "昨天"
            } else if days < 7 {
                return "\(days)天前"
            } else if days < 30 {
                let weeks = days / 7
                return "\(weeks)周前"
            } else if days < 365 {
                let months = days / 30
                return "\(months)个月前"
            } else {
                let years = days / 365
                return "\(years)年前"
            }
        }
        return formattedDate
    }
}

enum MilestoneCategory: String, Codable, CaseIterable {
    case firstSmile = "第一次微笑"
    case firstRoll = "第一次翻身"
    case firstSit = "第一次坐"
    case firstCrawl = "第一次爬"
    case firstStand = "第一次站"
    case firstWalk = "第一次走"
    case firstWord = "第一次说话"
    case firstTooth = "第一颗牙"
    case firstSolid = "第一次吃辅食"
    case sleep = "睡眠相关"
    case health = "健康相关"
    case other = "其他"
    
    var icon: String {
        switch self {
        case .firstSmile: return "face.smiling"
        case .firstRoll: return "arrow.triangle.2.circlepath"
        case .firstSit: return "figure.seated.side"
        case .firstCrawl: return "figure.walk"
        case .firstStand: return "figure.stand"
        case .firstWalk: return "figure.walk.circle"
        case .firstWord: return "bubble.left.and.bubble.right"
        case .firstTooth: return "mouth"
        case .firstSolid: return "fork.knife"
        case .sleep: return "moon.zzz"
        case .health: return "heart"
        case .other: return "star"
        }
    }
    
    var color: String {
        switch self {
        case .firstSmile: return "yellow"
        case .firstRoll, .firstSit, .firstCrawl, .firstStand, .firstWalk: return "blue"
        case .firstWord: return "purple"
        case .firstTooth: return "pink"
        case .firstSolid: return "orange"
        case .sleep: return "indigo"
        case .health: return "red"
        case .other: return "gray"
        }
    }
}

