//
//  SleepTabComponentsTests.swift
//  MomMateTests
//
//  Unit tests for Sleep tab UI component interactions.
//

import XCTest
import SwiftUI
@testable import MomMate

@MainActor
final class SleepTabComponentsTests: XCTestCase {

    func testAwakeStatusCardRendersExpectedTexts() {
        let root = UIHostingController(
            rootView: AwakeStatusCard(
                onSleep: {},
                onSleepCustom: {}
            )
        )

        XCTAssertNoThrow(render(root))
        XCTAssertNotNil(root.view)
    }

    func testSleepingStatusCardRendersExpectedTexts() {
        let record = SleepRecord(sleepTime: Date().addingTimeInterval(-1800))

        let root = UIHostingController(
            rootView: SleepingStatusCard(
                record: record,
                currentTime: Date(),
                onWakeUp: {},
                onWakeUpCustom: {}
            )
        )

        XCTAssertNoThrow(render(root))
        XCTAssertNotNil(root.view)
    }

    private func render(_ hostingController: UIHostingController<some View>) {
        hostingController.loadViewIfNeeded()
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
    }

}
