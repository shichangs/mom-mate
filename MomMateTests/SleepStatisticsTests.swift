//
//  SleepStatisticsTests.swift
//  MomMateTests
//
//  Unit tests for SleepStatisticsManager
//

import XCTest
@testable import MomMate

final class SleepStatisticsTests: XCTestCase {

    let manager = SleepStatisticsManager.shared

    override func setUp() {
        super.setUp()
        manager.invalidateCache()
    }

    func testDailyStatisticsWithNoRecords() {
        let stats = manager.dailyStatistics(from: [], days: 7)
        XCTAssertEqual(stats.count, 7)
        for stat in stats {
            XCTAssertEqual(stat.sleepCount, 0)
            XCTAssertEqual(stat.totalDuration, 0)
        }
    }

    func testDailyStatisticsGroupsByWakeDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let wakeTime = calendar.date(byAdding: .hour, value: 7, to: today)!
        let sleepTime = calendar.date(byAdding: .hour, value: -1, to: today)! // Slept at 11pm yesterday

        let record = SleepRecord(sleepTime: sleepTime, wakeTime: wakeTime)
        let stats = manager.dailyStatistics(from: [record], days: 2)
        let todayKey = DateFormatters.dayLabel.string(from: wakeTime)

        let todayStat = stats.first(where: { $0.period == todayKey })
        XCTAssertNotNil(todayStat)
        XCTAssertEqual(todayStat?.sleepCount, 1)
    }

    func testWeeklyStatistics() {
        let calendar = Calendar.current
        let now = Date()
        let sleepTime = calendar.date(byAdding: .hour, value: -8, to: now)!
        let record = SleepRecord(sleepTime: sleepTime, wakeTime: now)

        let stats = manager.weeklyStatistics(from: [record], weeks: 1)
        XCTAssertEqual(stats.count, 1)
        XCTAssertGreaterThanOrEqual(stats[0].sleepCount, 1)
    }

    func testMonthlyStatistics() {
        let stats = manager.monthlyStatistics(from: [], months: 3)
        XCTAssertEqual(stats.count, 3)
    }

    func testYearlyStatistics() {
        let stats = manager.yearlyStatistics(from: [], years: 2)
        XCTAssertEqual(stats.count, 2)
    }

    func testChartDataConversion() {
        let stat = SleepStatistics(
            period: "01/01",
            totalDuration: 7200,
            averageDuration: 3600,
            sleepCount: 2,
            date: Date()
        )
        let chartData = manager.chartData(from: [stat])

        XCTAssertEqual(chartData.count, 1)
        XCTAssertEqual(chartData[0].value, 2.0, accuracy: 0.01) // 7200/3600
        XCTAssertEqual(chartData[0].label, "01/01")
    }

    func testFormattedTotalDuration() {
        let stat = SleepStatistics(
            period: "test",
            totalDuration: 3600 * 2 + 1800, // 2h30m
            averageDuration: 0,
            sleepCount: 0,
            date: Date()
        )
        XCTAssertEqual(stat.formattedTotalDuration, "2小时30分钟")
    }

    func testFormattedTotalDurationMinutesOnly() {
        let stat = SleepStatistics(
            period: "test",
            totalDuration: 1800, // 30m
            averageDuration: 0,
            sleepCount: 0,
            date: Date()
        )
        XCTAssertEqual(stat.formattedTotalDuration, "30分钟")
    }

    func testCacheInvalidation() {
        let records = [SleepRecord(sleepTime: Date().addingTimeInterval(-3600), wakeTime: Date())]

        let stats1 = manager.dailyStatistics(from: records, days: 7)
        let stats2 = manager.dailyStatistics(from: records, days: 7)
        // Should return same cached result
        XCTAssertEqual(stats1.count, stats2.count)

        manager.invalidateCache()
        let stats3 = manager.dailyStatistics(from: records, days: 7)
        XCTAssertEqual(stats3.count, 7) // Still valid after recompute
    }

    func testStatsRangeMonthDaysCountFor31DayMonth() {
        // March 2026 has 31 days
        let marchDate = DateComponents(calendar: .current, year: 2026, month: 3, day: 15).date!
        XCTAssertEqual(StatsRange.month.daysCount(for: marchDate), 31)
    }

    func testStatsRangeMonthDaysCountForLeapYearFebruary() {
        // February 2024 has 29 days
        let leapFebDate = DateComponents(calendar: .current, year: 2024, month: 2, day: 10).date!
        XCTAssertEqual(StatsRange.month.daysCount(for: leapFebDate), 29)
    }
}
