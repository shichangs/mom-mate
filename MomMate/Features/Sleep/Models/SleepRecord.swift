//
//  SleepRecord.swift
//  MomMate
//
//  Data model for sleep records
//

import Foundation

struct SleepRecord: Identifiable, Codable {
    let id: UUID
    var sleepTime: Date
    var wakeTime: Date?
    
    init(id: UUID = UUID(), sleepTime: Date, wakeTime: Date? = nil) {
        self.id = id
        self.sleepTime = sleepTime
        self.wakeTime = wakeTime
    }

    var duration: TimeInterval? {
        guard let wakeTime else { return nil }
        return wakeTime.timeIntervalSince(sleepTime)
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
        DateFormatters.fullDateTimeZhCN.string(from: sleepTime)
    }
    
    var formattedWakeTime: String? {
        guard let wakeTime = wakeTime else { return nil }
        return DateFormatters.fullDateTimeZhCN.string(from: wakeTime)
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
}
