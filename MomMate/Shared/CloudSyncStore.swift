//
//  CloudSyncStore.swift
//  MomMate
//
//  Reusable cloud sync helper with debounce and error logging.
//  Replaces duplicated save/load/sync logic across all Managers.
//

import Foundation

final class CloudSyncStore {
    let storageKey: String
    let cloudStore = NSUbiquitousKeyValueStore.default
    var lastKnownCloudSyncEnabled: Bool

    private var syncWorkItem: DispatchWorkItem?

    init(storageKey: String) {
        self.storageKey = storageKey
        self.lastKnownCloudSyncEnabled = Self.computeCloudSyncEnabled()
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

    // MARK: - Debounced sync (1 second)

    private func debouncedSync() {
        syncWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.cloudStore.synchronize()
        }
        syncWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
}
