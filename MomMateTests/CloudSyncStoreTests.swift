//
//  CloudSyncStoreTests.swift
//  MomMateTests
//
//  Unit tests for CloudSyncStore
//

import XCTest
@testable import MomMate

final class CloudSyncStoreTests: XCTestCase {

    private var store: CloudSyncStore!

    override func setUp() {
        super.setUp()
        store = CloudSyncStore(storageKey: "test.cloudSyncStore.\(UUID().uuidString)")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.cloudSyncEnabled)
        UserDefaults.standard.removeObject(forKey: StorageKeys.syncAuthorized)
        UserDefaults.standard.removeObject(forKey: StorageKeys.sessionStore)
        UserDefaults.standard.removeObject(forKey: store.storageKey)
        super.tearDown()
    }

    func testSaveAndLoadCodable() {
        let records = [
            SleepRecord(sleepTime: Date(), wakeTime: Date().addingTimeInterval(3600)),
            SleepRecord(sleepTime: Date().addingTimeInterval(-7200), wakeTime: Date().addingTimeInterval(-3600))
        ]
        store.save(records)

        let loaded = store.load([SleepRecord].self)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 2)
    }

    func testLoadReturnsNilForMissingKey() {
        let loaded = store.load([SleepRecord].self)
        XCTAssertNil(loaded)
    }

    func testSaveAndLoadString() {
        store.saveString("Hello, MomMate!")
        let loaded = store.loadString()
        XCTAssertEqual(loaded, "Hello, MomMate!")
    }

    func testLoadStringReturnsEmptyForMissingKey() {
        let loaded = store.loadString()
        XCTAssertEqual(loaded, "")
    }

    func testComputeCloudSyncEnabled() {
        // Default: cloudSyncEnabled defaults to true, but syncAuthorized defaults to false
        UserDefaults.standard.removeObject(forKey: StorageKeys.cloudSyncEnabled)
        UserDefaults.standard.set(false, forKey: StorageKeys.syncAuthorized)

        XCTAssertFalse(CloudSyncStore.computeCloudSyncEnabled())

        UserDefaults.standard.set(true, forKey: StorageKeys.syncAuthorized)
        XCTAssertTrue(CloudSyncStore.computeCloudSyncEnabled())

        // Cleanup
        UserDefaults.standard.removeObject(forKey: StorageKeys.syncAuthorized)
    }

    @MainActor
    func testAuthRestoreSessionEnablesSyncAuthorization() throws {
        let session = SocialSession(
            provider: .apple,
            userID: "test.user",
            displayName: "Test User"
        )
        let data = try JSONEncoder().encode(session)
        UserDefaults.standard.set(data, forKey: StorageKeys.sessionStore)
        UserDefaults.standard.set(false, forKey: StorageKeys.syncAuthorized)

        let manager = AuthManager()

        XCTAssertTrue(manager.isAuthenticated)
        XCTAssertEqual(manager.provider, .apple)
        XCTAssertEqual(manager.displayName, "Test User")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: StorageKeys.syncAuthorized))
    }

    @MainActor
    func testAuthLogoutClearsSessionAndDisablesSyncAuthorization() throws {
        let session = SocialSession(
            provider: .apple,
            userID: "test.user",
            displayName: "Test User"
        )
        let data = try JSONEncoder().encode(session)
        UserDefaults.standard.set(data, forKey: StorageKeys.sessionStore)

        let manager = AuthManager()
        XCTAssertTrue(manager.isAuthenticated)

        manager.logout()

        XCTAssertFalse(manager.isAuthenticated)
        XCTAssertNil(manager.provider)
        XCTAssertNil(manager.displayName)
        XCTAssertNil(UserDefaults.standard.data(forKey: StorageKeys.sessionStore))
        XCTAssertFalse(UserDefaults.standard.bool(forKey: StorageKeys.syncAuthorized))
    }
}
