//
//  SleepRecordTests.swift
//  MomMateTests
//
//  Unit tests for SleepRecord model
//

import XCTest
@testable import MomMate

final class SleepRecordTests: XCTestCase {

    func testSleepRecordDurationCalculation() {
        let sleepTime = Date()
        let wakeTime = sleepTime.addingTimeInterval(3600 * 8) // 8 hours
        let record = SleepRecord(sleepTime: sleepTime, wakeTime: wakeTime)

        XCTAssertNotNil(record.duration)
        XCTAssertEqual(record.duration ?? 0, 3600 * 8, accuracy: 0.1)
        XCTAssertFalse(record.isSleeping)
    }

    func testSleepRecordIsSleepingWhenNoWakeTime() {
        let record = SleepRecord(sleepTime: Date())

        XCTAssertTrue(record.isSleeping)
        XCTAssertNil(record.duration)
        XCTAssertNil(record.wakeTime)
    }

    func testFormattedDurationInProgress() {
        let record = SleepRecord(sleepTime: Date())
        XCTAssertEqual(record.formattedDuration, "进行中")
    }

    func testFormattedDurationWithHours() {
        let sleepTime = Date()
        let wakeTime = sleepTime.addingTimeInterval(3600 * 2 + 1800) // 2h30m
        let record = SleepRecord(sleepTime: sleepTime, wakeTime: wakeTime)

        XCTAssertEqual(record.formattedDuration, "2小时30分钟")
    }

    func testFormattedDurationMinutesOnly() {
        let sleepTime = Date()
        let wakeTime = sleepTime.addingTimeInterval(45 * 60) // 45 min
        let record = SleepRecord(sleepTime: sleepTime, wakeTime: wakeTime)

        XCTAssertEqual(record.formattedDuration, "0小时45分钟")
    }

    func testSleepRecordCodable() throws {
        let original = SleepRecord(sleepTime: Date(), wakeTime: Date().addingTimeInterval(3600))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SleepRecord.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.sleepTime.timeIntervalSince1970, original.sleepTime.timeIntervalSince1970, accuracy: 0.001)
    }
}
