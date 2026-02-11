//
//  MilestoneTests.swift
//  MomMateTests
//
//  Unit tests for Milestone model
//

import XCTest
@testable import MomMate

final class MilestoneTests: XCTestCase {

    func testMilestoneCreation() {
        let milestone = Milestone(
            date: Date(),
            title: "第一次微笑",
            description: "今天宝宝第一次对我微笑了",
            category: .firstSmile
        )

        XCTAssertEqual(milestone.title, "第一次微笑")
        XCTAssertEqual(milestone.category, .firstSmile)
        XCTAssertFalse(milestone.description.isEmpty)
    }

    func testMilestoneCategoryCases() {
        XCTAssertEqual(MilestoneCategory.allCases.count, 12)
    }

    func testMilestoneCategoryIcons() {
        for category in MilestoneCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category.rawValue) has empty icon")
        }
    }

    func testMilestoneCategoryColors() {
        for category in MilestoneCategory.allCases {
            XCTAssertFalse(category.color.isEmpty, "\(category.rawValue) has empty color")
        }
    }

    func testRelativeDateToday() {
        let milestone = Milestone(date: Date(), title: "Test", category: .other)
        XCTAssertEqual(milestone.relativeDate, "今天")
    }

    func testRelativeDateYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let milestone = Milestone(date: yesterday, title: "Test", category: .other)
        XCTAssertEqual(milestone.relativeDate, "昨天")
    }

    func testMilestoneCodable() throws {
        let original = Milestone(
            date: Date(),
            title: "第一次走",
            category: .firstWalk
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Milestone.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, "第一次走")
        XCTAssertEqual(decoded.category, .firstWalk)
    }
}
