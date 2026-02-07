//
//  SDSleepRecord.swift
//  MomMate
//
//  SwiftData model for sleep records with CloudKit sync support
//

import Foundation
import SwiftData

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
    
    var isSleeping: Bool {
        return wakeTime == nil
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "进行中" }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }
    
    var formattedSleepTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: sleepTime)
    }
    
    var formattedWakeTime: String? {
        guard let wakeTime = wakeTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: wakeTime)
    }
    
    func relativeTimeString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        let minutes = Int(abs(interval)) / 60
        
        if minutes < 1 {
            return "刚刚"
        } else if minutes < 60 {
            return "\(minutes)分钟前"
        } else {
            let hours = minutes / 60
            if hours < 24 {
                return "\(hours)小时前"
            } else {
                let days = hours / 24
                return "\(days)天前"
            }
        }
    }
    
    var relativeSleepTime: String {
        return relativeTimeString(from: sleepTime)
    }
    
    var relativeWakeTime: String? {
        guard let wakeTime = wakeTime else { return nil }
        return relativeTimeString(from: wakeTime)
    }
    
    // 从旧模型转换
    convenience init(from record: SleepRecord) {
        self.init(id: record.id, sleepTime: record.sleepTime, wakeTime: record.wakeTime)
    }
    
    // 转换为旧模型（用于兼容现有视图）
    func toSleepRecord() -> SleepRecord {
        return SleepRecord(id: id, sleepTime: sleepTime, wakeTime: wakeTime)
    }
}
