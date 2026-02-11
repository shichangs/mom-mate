//
//  MealRecordTests.swift
//  MomMateTests
//
//  Unit tests for MealRecord model
//

import XCTest
@testable import MomMate

final class MealRecordTests: XCTestCase {

    func testMealRecordCreation() {
        let record = MealRecord(
            date: Date(),
            mealType: .breakfast,
            foodItems: ["米糊", "苹果泥"],
            amount: "适量",
            notes: "宝宝吃得很开心"
        )

        XCTAssertEqual(record.mealType, .breakfast)
        XCTAssertEqual(record.foodItems.count, 2)
        XCTAssertEqual(record.amount, "适量")
    }

    func testMealTypeCases() {
        XCTAssertEqual(MealType.allCases.count, 5)
        XCTAssertEqual(MealType.breakfast.rawValue, "早餐")
        XCTAssertEqual(MealType.lunch.rawValue, "午餐")
        XCTAssertEqual(MealType.dinner.rawValue, "晚餐")
        XCTAssertEqual(MealType.snack.rawValue, "加餐")
        XCTAssertEqual(MealType.milk.rawValue, "奶")
    }

    func testMealTypeIcons() {
        XCTAssertFalse(MealType.breakfast.icon.isEmpty)
        XCTAssertFalse(MealType.lunch.icon.isEmpty)
        XCTAssertFalse(MealType.dinner.icon.isEmpty)
    }

    func testMealRecordCodable() throws {
        let original = MealRecord(
            date: Date(),
            mealType: .lunch,
            foodItems: ["鸡蛋"],
            amount: "半碗",
            notes: ""
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MealRecord.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.mealType, .lunch)
        XCTAssertEqual(decoded.foodItems, ["鸡蛋"])
    }
}
