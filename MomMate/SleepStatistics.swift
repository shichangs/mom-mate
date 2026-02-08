//
//  SleepStatistics.swift
//  MomMate
//
//  Statistics data models
//

import Foundation

struct SleepStatistics {
    let period: String
    let totalDuration: TimeInterval // 总睡眠时长（秒）
    let averageDuration: TimeInterval // 平均睡眠时长（秒）
    let sleepCount: Int // 睡眠次数
    let date: Date // 日期（用于排序）
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    var formattedAverageDuration: String {
        let hours = Int(averageDuration) / 3600
        let minutes = (Int(averageDuration) % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double // 小时数
    let date: Date
}

class SleepStatisticsManager {
    static let shared = SleepStatisticsManager()
    
    private init() {}
    
    // Sleep records are grouped by wake-up date so overnight sessions are attributed to the day they end.
    private func referenceDate(for record: SleepRecord) -> Date? {
        record.wakeTime
    }
    
    // MARK: - 按天统计
    func dailyStatistics(from records: [SleepRecord], days: Int = 7) -> [SleepStatistics] {
        let calendar = Calendar.current
        let now = Date()
        var statistics: [SleepStatistics] = []
        
        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let dayRecords = records.filter { record in
                guard let date = referenceDate(for: record) else { return false }
                return date >= startOfDay && date < endOfDay
            }
            
            let totalDuration = dayRecords.compactMap { $0.duration }.reduce(0, +)
            let sleepCount = dayRecords.count
            let averageDuration = sleepCount > 0 ? totalDuration / Double(sleepCount) : 0
            
            statistics.append(SleepStatistics(
                period: DateFormatters.dayLabel.string(from: date),
                totalDuration: totalDuration,
                averageDuration: averageDuration,
                sleepCount: sleepCount,
                date: date
            ))
        }
        
        return statistics.reversed()
    }
    
    // MARK: - 按周统计
    func weeklyStatistics(from records: [SleepRecord], weeks: Int = 8) -> [SleepStatistics] {
        let calendar = Calendar.current
        let now = Date()
        var statistics: [SleepStatistics] = []
        
        for i in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now) else { continue }
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart))!
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            
            let weekRecords = records.filter { record in
                guard let date = referenceDate(for: record) else { return false }
                return date >= startOfWeek && date < endOfWeek
            }
            
            let totalDuration = weekRecords.compactMap { $0.duration }.reduce(0, +)
            let sleepCount = weekRecords.count
            let averageDuration = sleepCount > 0 ? totalDuration / Double(sleepCount) : 0
            
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
            let weekLabel = "\(DateFormatters.dayLabel.string(from: startOfWeek))-\(DateFormatters.dayLabel.string(from: weekEnd))"
            
            statistics.append(SleepStatistics(
                period: weekLabel,
                totalDuration: totalDuration,
                averageDuration: averageDuration,
                sleepCount: sleepCount,
                date: startOfWeek
            ))
        }
        
        return statistics.reversed()
    }
    
    // MARK: - 按月统计
    func monthlyStatistics(from records: [SleepRecord], months: Int = 12) -> [SleepStatistics] {
        let calendar = Calendar.current
        let now = Date()
        var statistics: [SleepStatistics] = []
        
        for i in 0..<months {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: now) else { continue }
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            let endOfMonthStart = calendar.startOfDay(for: endOfMonth)
            let endOfMonthEnd = calendar.date(byAdding: .day, value: 1, to: endOfMonthStart)!
            
            let monthRecords = records.filter { record in
                guard let date = referenceDate(for: record) else { return false }
                return date >= startOfMonth && date < endOfMonthEnd
            }
            
            let totalDuration = monthRecords.compactMap { $0.duration }.reduce(0, +)
            let sleepCount = monthRecords.count
            let averageDuration = sleepCount > 0 ? totalDuration / Double(sleepCount) : 0
            
            statistics.append(SleepStatistics(
                period: DateFormatters.monthLabelZh.string(from: monthStart),
                totalDuration: totalDuration,
                averageDuration: averageDuration,
                sleepCount: sleepCount,
                date: startOfMonth
            ))
        }
        
        return statistics.reversed()
    }
    
    // MARK: - 按年统计
    func yearlyStatistics(from records: [SleepRecord], years: Int = 3) -> [SleepStatistics] {
        let calendar = Calendar.current
        let now = Date()
        var statistics: [SleepStatistics] = []
        
        for i in 0..<years {
            guard let yearStart = calendar.date(byAdding: .year, value: -i, to: now) else { continue }
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: yearStart))!
            let endOfYear = calendar.date(byAdding: DateComponents(year: 1), to: startOfYear)!
            
            let yearRecords = records.filter { record in
                guard let date = referenceDate(for: record) else { return false }
                return date >= startOfYear && date < endOfYear
            }
            
            let totalDuration = yearRecords.compactMap { $0.duration }.reduce(0, +)
            let sleepCount = yearRecords.count
            let averageDuration = sleepCount > 0 ? totalDuration / Double(sleepCount) : 0
            
            statistics.append(SleepStatistics(
                period: DateFormatters.yearLabelZh.string(from: yearStart),
                totalDuration: totalDuration,
                averageDuration: averageDuration,
                sleepCount: sleepCount,
                date: startOfYear
            ))
        }
        
        return statistics.reversed()
    }
    
    // MARK: - 转换为图表数据
    func chartData(from statistics: [SleepStatistics]) -> [ChartDataPoint] {
        return statistics.map { stat in
            ChartDataPoint(
                label: stat.period,
                value: stat.totalDuration / 3600.0, // 转换为小时
                date: stat.date
            )
        }
    }
}

#if DEBUG
enum DebugSelfChecks {
    static func run() {
        verifyOvernightRecordAttributedToWakeDay()
    }
    
    private static func verifyOvernightRecordAttributedToWakeDay() {
        let calendar = Calendar.current
        let now = Date()
        let wakeTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now
        let sleepTime = calendar.date(byAdding: .hour, value: -8, to: wakeTime) ?? wakeTime
        let record = SleepRecord(sleepTime: sleepTime, wakeTime: wakeTime)
        
        let stats = SleepStatisticsManager.shared.dailyStatistics(from: [record], days: 2)
        let todayKey = DateFormatters.dayLabel.string(from: wakeTime)
        
        guard let todayStat = stats.first(where: { $0.period == todayKey }) else {
            assertionFailure("DebugSelfChecks: missing today statistics bucket")
            return
        }
        
        assert(todayStat.sleepCount == 1, "DebugSelfChecks: overnight record should be grouped by wake day")
    }
}
#endif
