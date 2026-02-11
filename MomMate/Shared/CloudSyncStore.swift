//
//  CloudSyncStore.swift
//  MomMate
//
//  Reusable cloud sync helper with debounce and error logging.
//  Replaces duplicated save/load/sync logic across all Managers.
//

import Foundation

/// Protocol for managers that observe iCloud sync changes.
/// Conformers get automatic observer setup/teardown via CloudSyncStore.
protocol CloudSyncObserver: AnyObject {
    var store: CloudSyncStore { get }
    func reloadFromStore()
    func pushCurrentDataToCloud()
}

final class CloudSyncStore {
    let storageKey: String
    let cloudStore = NSUbiquitousKeyValueStore.default
    var lastKnownCloudSyncEnabled: Bool

    private var syncWorkItem: DispatchWorkItem?
    private var observerTokens: [NSObjectProtocol] = []

    init(storageKey: String) {
        self.storageKey = storageKey
        self.lastKnownCloudSyncEnabled = Self.computeCloudSyncEnabled()
    }

    // MARK: - Observer helpers

    /// Sets up iCloud and UserDefaults change observers for a manager.
    /// Call from init(), and call `teardownObservers()` in deinit.
    func setupObservers(for observer: CloudSyncObserver) {
        let cloudToken = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore,
            queue: .main
        ) { [weak observer] _ in
            guard let observer, observer.store.isCloudSyncEnabled else { return }
            observer.reloadFromStore()
        }
        let defaultsToken = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: .main
        ) { [weak observer] _ in
            guard let observer else { return }
            let store = observer.store
            let current = store.isCloudSyncEnabled
            guard current != store.lastKnownCloudSyncEnabled else { return }
            store.lastKnownCloudSyncEnabled = current
            if current {
                observer.pushCurrentDataToCloud()
            }
            observer.reloadFromStore()
        }
        observerTokens.append(contentsOf: [cloudToken, defaultsToken])
    }

    func teardownObservers() {
        observerTokens.forEach { NotificationCenter.default.removeObserver($0) }
        observerTokens.removeAll()
    }

    // MARK: - Cloud sync state

    var isCloudSyncEnabled: Bool {
        Self.computeCloudSyncEnabled()
    }

    static func computeCloudSyncEnabled() -> Bool {
        let enabled = UserDefaults.standard.object(forKey: StorageKeys.cloudSyncEnabled) as? Bool ?? true
        let authorized = UserDefaults.standard.bool(forKey: StorageKeys.syncAuthorized)
        return enabled && authorized
    }

    // MARK: - Codable save / load

    func save<T: Encodable>(_ value: T) {
        do {
            let encoded = try JSONEncoder().encode(value)
            UserDefaults.standard.set(encoded, forKey: storageKey)
            if isCloudSyncEnabled {
                cloudStore.set(encoded, forKey: storageKey)
                debouncedSync()
            }
        } catch {
            print("[MomMate] Failed to save \(storageKey): \(error.localizedDescription)")
        }
    }

    func load<T: Decodable>(_ type: T.Type) -> T? {
        let data: Data?
        if isCloudSyncEnabled {
            cloudStore.synchronize()
            data = cloudStore.data(forKey: storageKey) ?? UserDefaults.standard.data(forKey: storageKey)
        } else {
            data = UserDefaults.standard.data(forKey: storageKey)
        }

        guard let data else { return nil }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("[MomMate] Failed to load \(storageKey): \(error.localizedDescription)")
            return nil
        }
    }

    func pushToCloud<T: Encodable>(_ value: T) {
        do {
            let encoded = try JSONEncoder().encode(value)
            cloudStore.set(encoded, forKey: storageKey)
            debouncedSync()
        } catch {
            print("[MomMate] Failed to push \(storageKey) to cloud: \(error.localizedDescription)")
        }
    }

    // MARK: - String save / load (for NotesManager)

    func saveString(_ value: String) {
        UserDefaults.standard.set(value, forKey: storageKey)
        if isCloudSyncEnabled {
            cloudStore.set(value, forKey: storageKey)
            debouncedSync()
        }
    }

    func loadString() -> String {
        if isCloudSyncEnabled {
            cloudStore.synchronize()
            return cloudStore.string(forKey: storageKey)
                ?? UserDefaults.standard.string(forKey: storageKey)
                ?? ""
        }
        return UserDefaults.standard.string(forKey: storageKey) ?? ""
    }

    func pushStringToCloud(_ value: String) {
        cloudStore.set(value, forKey: storageKey)
        debouncedSync()
    }

    // MARK: - Sync status

    private static let lastSyncKey = "sync.lastSyncTimestamp"

    /// Timestamp of last successful sync. Shared across all stores.
    static var lastSyncDate: Date? {
        let ts = UserDefaults.standard.double(forKey: lastSyncKey)
        return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }

    static var lastSyncFormatted: String {
        guard let date = lastSyncDate else { return "从未同步" }
        return DateFormatters.fullDateTimeZhCN.string(from: date)
    }

    private func recordSyncTimestamp() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastSyncKey)
    }

    // MARK: - Debounced sync (1 second)

    private func debouncedSync() {
        syncWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.cloudStore.synchronize()
            self?.recordSyncTimestamp()
        }
        syncWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
}
