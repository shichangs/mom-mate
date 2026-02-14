//
//  AuthManager.swift
//  MomMate
//
//  Authentication manager handling Apple Sign-In, Google, WeChat auth
//

import SwiftUI
import AuthenticationServices

// MARK: - Auth types

enum AuthProvider: String, Codable {
    case apple = "Apple"
    case google = "Google"
    case wechat = "微信"

    var displayTitle: String {
        switch self {
        case .apple: return "苹果"
        case .google: return "谷歌"
        case .wechat: return "微信"
        }
    }
}

struct SocialSession: Codable {
    let provider: AuthProvider
    let userID: String
    let displayName: String
}

struct LocalDataSnapshot: Codable {
    let sleepRecordCount: Int
    let mealRecordCount: Int
    let milestoneCount: Int
    let hasNotes: Bool
    let capturedAt: Date
}

// MARK: - AuthManager

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var displayName: String?
    @Published private(set) var provider: AuthProvider?

    private let defaults = UserDefaults.standard

    init() {
        restoreSession()
    }

    var syncButtonTitle: String {
        isAuthenticated ? "同步已开启\(userBadge)" : "登录以同步"
    }

    var syncButtonIcon: String {
        isAuthenticated ? "checkmark.icloud.fill" : "icloud"
    }

    var syncButtonColor: Color {
        isAuthenticated ? AppColors.accent : AppColors.textSecondary
    }

    var userBadge: String {
        guard let provider else { return "" }
        let name = displayName ?? "\(provider.displayTitle)用户"
        return " · \(name)"
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) -> String? {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return "无法获取 Apple 登录凭证"
            }

            let formatter = PersonNameComponentsFormatter()
            let fullName = credential.fullName.flatMap { formatter.string(from: $0) } ?? ""
            let nameCandidate = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            let emailCandidate = (credential.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedName = nameCandidate.isEmpty ? (emailCandidate.isEmpty ? "Apple 用户" : emailCandidate) : nameCandidate
            saveSession(
                SocialSession(
                    provider: .apple,
                    userID: credential.user,
                    displayName: resolvedName
                )
            )
            return nil
        case .failure(let error):
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                return "已取消登录"
            }
            return "Apple 登录失败，请稍后重试"
        }
    }

    func startGoogleSignIn() -> String? {
        notConfiguredMessage(for: .google)
    }

    func startWeChatSignIn() -> String? {
        notConfiguredMessage(for: .wechat)
    }

#if DEBUG
    func debugMockSignIn() {
        let mockSession = SocialSession(
            provider: .apple,
            userID: "debug.mock.apple.user",
            displayName: "调试 Apple 用户"
        )
        saveSession(mockSession)
    }
#endif

    func logout() {
        isAuthenticated = false
        displayName = nil
        provider = nil
        defaults.removeObject(forKey: StorageKeys.sessionStore)
        defaults.set(false, forKey: StorageKeys.syncAuthorized)
    }

    private func restoreSession() {
        guard let data = defaults.data(forKey: StorageKeys.sessionStore) else {
            defaults.set(false, forKey: StorageKeys.syncAuthorized)
            return
        }
        do {
            let session = try JSONDecoder().decode(SocialSession.self, from: data)
            applySession(session)
            defaults.set(true, forKey: StorageKeys.syncAuthorized)
        } catch {
            print("[MomMate] Failed to restore auth session: \(error.localizedDescription)")
            defaults.set(false, forKey: StorageKeys.syncAuthorized)
        }
    }

    private func saveSession(_ session: SocialSession) {
        do {
            let data = try JSONEncoder().encode(session)
            defaults.set(data, forKey: StorageKeys.sessionStore)
            defaults.set(true, forKey: StorageKeys.syncAuthorized)
            captureFirstSyncSnapshotIfNeeded(userID: session.userID)
            applySession(session)
        } catch {
            print("[MomMate] Failed to save auth session: \(error.localizedDescription)")
        }
    }

    private func applySession(_ session: SocialSession) {
        provider = session.provider
        displayName = session.displayName
        isAuthenticated = true
    }

    private func notConfiguredMessage(for provider: AuthProvider) -> String {
        "\(provider.displayTitle)登录已接入入口，需先配置该平台的客户端 ID / 应用 ID 和回调地址。"
    }

    private func captureFirstSyncSnapshotIfNeeded(userID: String) {
        let escapedUserID = userID.replacingOccurrences(of: ".", with: "_")
        let markerKey = "sync.initialMigration.done.\(escapedUserID)"
        guard !defaults.bool(forKey: markerKey) else { return }

        let snapshot = LocalDataSnapshot(
            sleepRecordCount: decodeArrayCount(forKey: StorageKeys.sleepRecords),
            mealRecordCount: decodeArrayCount(forKey: StorageKeys.mealRecords),
            milestoneCount: decodeArrayCount(forKey: StorageKeys.milestones),
            hasNotes: !(defaults.string(forKey: StorageKeys.notes) ?? "").isEmpty,
            capturedAt: Date()
        )

        do {
            let data = try JSONEncoder().encode(snapshot)
            defaults.set(data, forKey: "sync.initialMigration.snapshot.\(escapedUserID)")
        } catch {
            print("[MomMate] Failed to save sync snapshot: \(error.localizedDescription)")
        }
        defaults.set(true, forKey: markerKey)
    }

    private func decodeArrayCount(forKey key: String) -> Int {
        guard let data = defaults.data(forKey: key),
              let object = try? JSONSerialization.jsonObject(with: data),
              let array = object as? [Any] else { return 0 }
        return array.count
    }
}
