//
//  NotesManagerTests.swift
//  MomMateTests
//
//  Unit tests for NotesManager persistence behavior.
//

import XCTest
@testable import MomMate

final class NotesManagerTests: XCTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.notes)
        UserDefaults.standard.removeObject(forKey: StorageKeys.cloudSyncEnabled)
        UserDefaults.standard.removeObject(forKey: StorageKeys.syncAuthorized)
        super.tearDown()
    }

    func testSaveAndReloadNotesPersistsLatestContent() {
        UserDefaults.standard.set(false, forKey: StorageKeys.cloudSyncEnabled)
        UserDefaults.standard.set(false, forKey: StorageKeys.syncAuthorized)

        let manager = NotesManager()
        let expected = "# Notes\n\ncustom content"
        manager.notes = expected
        manager.saveNotes()

        let reloaded = NotesManager()
        XCTAssertEqual(reloaded.notes, expected)
    }
}
