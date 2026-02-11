//
//  SleepStatistics.swift
//  MomMate
//
//  Statistics data models with safe date handling
//

import Foundation

struct SleepStatistics {
    let period: String
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let sleepCount: Int
    let date: Date

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
    let value: Double
    let date: Date
}

class SleepStatisticsManager {
    static let shared = SleepStatisticsManager()

    private init() {}

    // MARK: - Cache

    private struct CacheKey: Hashable {
        let signature: Int
        let kind: String
        let param: Int
    }

    private var cache: [CacheKey: [SleepStatistics]] = [:]

    /// Call when records change to invalidate cached statistics.
    func invalidateCache() {
        cache.removeAll()
    }

    private func recordsSignature(_ records: [SleepRecord]) -> Int {
        var hasher = Hasher()
        hasher.combine(records.count)
        for record in records {
            hasher.combine(record.id)
            hasher.combine(record.sleepTime.timeIntervalSince1970.bitPattern)
            hasher.combine(record.wakeTime?.timeIntervalSince1970.bitPattern ?? 0)
            hasher.combine(record.duration?.bitPattern ?? 0)
        }
        return hasher.finalize()
    }

    private func cached(records: [SleepRecord], kind: String, param: Int, compute: () -> [SleepStatistics]) -> [SleepStatistics] {
        let key = CacheKey(signature: recordsSignature(records), kind: kind, param: param)
        if let hit = cache[key] { return hit }
        let result = compute()
        cache[key] = result
        return result
    }

    private func referenceDate(for record: SleepRecord) -> Date? {
        record.wakeTime
    }

    // MARK: - 按天统计
    func dailyStatistics(from records: [SleepRecord], days: Int = 7) -> [SleepStatistics] {
        cached(records: records, kind: "daily", param: days) {
            _dailyStatistics(from: records, days: days)
        }
    }

    private func _dailyStatistics(from records: [SleepRecord], days: Int) -> [SleepStatistics] {
        let calendar = Calendar.current
        let now = Date()
        var statistics: [SleepStatistics] = []

        for i in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }

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
        cached(records: records, kind: "weekly", param: weeks) {
            _weeklyStatistics(from: records, weeks: weeks)
        }
    }

    private func _weeklyStatistics(from records: [SleepRecord], weeks: Int) -> [SleepStatistics] {
        let calendar = Calendar.current
        let now = Date()
        var statistics: [SleepStatistics] = []

        for i in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -i, to: now),
                  let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)),
                  let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else { continue }

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
        cached(records: records, kind: "monthly", param: months) {
            _monthlyStatistics(from: records, months: months)
        }
    }

    private func _monthlyStatistics(from records: [SleepRecord], months: Int) -> [SleepStatistics] {
        let calendar = Calendar.current
        let now = Date()
        var statistics: [SleepStatistics] = []

        for i in 0..<months {
            guard let monthStart = calendar.date(byAdding: .month, value: -i, to: now),
                  let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart)),
                  let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else { continue }

            let endOfMonthStart = calendar.startOfDay(for: endOfMonth)
            guard let endOfMonthEnd = calendar.date(byAdding: .day, value: 1, to: endOfMonthStart) else { continue }

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
        cached(records: records, kind: "yearly", param: years) {
            _yearlyStatistics(from: records, years: years)
        }
    }

    private func _yearlyStatistics(from records: [SleepRecord], years: Int) -> [SleepStatistics] {
        let calendar = Calendar.current
        let now = Date()
        var statistics: [SleepStatistics] = []

        for i in 0..<years {
            guard let yearStart = calendar.date(byAdding: .year, value: -i, to: now),
                  let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: yearStart)),
                  let endOfYear = calendar.date(byAdding: DateComponents(year: 1), to: startOfYear) else { continue }

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
                value: stat.totalDuration / 3600.0,
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
