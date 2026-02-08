//
//  ContentView.swift
//  MomMate
//
//  Main content view - now serves as entry point to MainTabView
//

import SwiftUI
import AuthenticationServices

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

// MARK: - 第三方认证
enum AuthProvider: String, Codable {
    case apple = "Apple"
    case google = "Google"
    case wechat = "微信"
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

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var displayName: String?
    @Published private(set) var provider: AuthProvider?
    
    private let defaults = UserDefaults.standard
    private let sessionStoreKey = "auth.social_session.v1"
    private let syncAuthorizedKey = "sync.auth.enabled.v1"
    private let sleepRecordsKey = "SleepRecords"
    private let mealRecordsKey = "MealRecords"
    private let milestonesKey = "Milestones"
    private let notesKey = "AppNotes"
    
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
        let name = displayName ?? "\(provider.rawValue)用户"
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
            displayName: "Debug Apple User"
        )
        saveSession(mockSession)
    }
#endif
    
    func logout() {
        isAuthenticated = false
        displayName = nil
        provider = nil
        defaults.removeObject(forKey: sessionStoreKey)
        defaults.set(false, forKey: syncAuthorizedKey)
    }
    
    private func restoreSession() {
        guard let data = defaults.data(forKey: sessionStoreKey),
              let session = try? JSONDecoder().decode(SocialSession.self, from: data) else {
            defaults.set(false, forKey: syncAuthorizedKey)
            return
        }
        
        applySession(session)
        defaults.set(true, forKey: syncAuthorizedKey)
    }
    
    private func saveSession(_ session: SocialSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: sessionStoreKey)
        defaults.set(true, forKey: syncAuthorizedKey)
        captureFirstSyncSnapshotIfNeeded(userID: session.userID)
        applySession(session)
    }
    
    private func applySession(_ session: SocialSession) {
        provider = session.provider
        displayName = session.displayName
        isAuthenticated = true
    }
    
    private func notConfiguredMessage(for provider: AuthProvider) -> String {
        "\(provider.rawValue) 登录已接入入口，需先配置该平台的 Client ID / AppID 和回调 URL。"
    }
    
    private func captureFirstSyncSnapshotIfNeeded(userID: String) {
        let escapedUserID = userID.replacingOccurrences(of: ".", with: "_")
        let markerKey = "sync.initialMigration.done.\(escapedUserID)"
        guard !defaults.bool(forKey: markerKey) else { return }
        
        let snapshot = LocalDataSnapshot(
            sleepRecordCount: decodeArrayCount(forKey: sleepRecordsKey),
            mealRecordCount: decodeArrayCount(forKey: mealRecordsKey),
            milestoneCount: decodeArrayCount(forKey: milestonesKey),
            hasNotes: !(defaults.string(forKey: notesKey) ?? "").isEmpty,
            capturedAt: Date()
        )
        
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: "sync.initialMigration.snapshot.\(escapedUserID)")
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

struct AuthView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var showingSheet: Bool
    
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: AppSpacing.lg) {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "person.badge.key.fill")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                        Text("账号与同步")
                            .font(AppTypography.largeTitle)
                        Text("不登录也可以使用，登录仅用于数据同步和备份")
                            .font(AppTypography.subhead)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    if authManager.isAuthenticated {
                        VStack(spacing: AppSpacing.md) {
                            HStack {
                                Text("当前账号")
                                Spacer()
                                Text(authManager.userBadge.replacingOccurrences(of: " · ", with: ""))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .font(AppTypography.body)
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            
                            Button(role: .destructive) {
                                authManager.logout()
                            } label: {
                                Text("退出登录（保留本机数据）")
                                    .font(AppTypography.bodySemibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.md)
                            }
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                    } else {
                        VStack(spacing: AppSpacing.md) {
                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                errorMessage = authManager.handleAppleSignIn(result)
                                if errorMessage == nil {
                                    showingSheet = false
                                }
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            
                            Button {
                                errorMessage = authManager.startGoogleSignIn()
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "globe")
                                    Text("使用 Google 登录")
                                    Spacer()
                                }
                                .font(AppTypography.bodySemibold)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            }
                            
                            Button {
                                errorMessage = authManager.startWeChatSignIn()
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "message.fill")
                                    Text("使用微信登录")
                                    Spacer()
                                }
                                .font(AppTypography.bodySemibold)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            }
                            
#if DEBUG
                            Button {
                                authManager.debugMockSignIn()
                                showingSheet = false
                            } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Image(systemName: "hammer.fill")
                                    Text("Debug Mock Apple 登录")
                                    Spacer()
                                }
                                .font(AppTypography.bodySemibold)
                                .foregroundColor(Color.orange)
                                .padding(AppSpacing.md)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            }
#endif
                        }
                        
                        Text("已支持 Apple 原生登录；Google/微信需先完成平台参数配置。")
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(AppTypography.footnote)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xl)
            }
            .navigationTitle("账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { showingSheet = false }
                }
            }
        }
    }
}

// MARK: - 历史记录视图
struct HistoryView: View {
    @ObservedObject var recordManager: SleepRecordManager
    @Environment(\.dismiss) var dismiss
    @State private var editingRecord: SleepRecord?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                if recordManager.completedRecords.isEmpty {
                    EmptyStateView(
                        icon: "moon.zzz",
                        title: "还没有记录",
                        subtitle: "记录宝宝的睡眠后会显示在这里"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(recordManager.completedRecords) { record in
                                HistoryRecordCard(record: record)
                                    .onTapGesture {
                                        editingRecord = record
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            recordManager.deleteRecord(record)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                    }
                }
            }
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.primary)
                }
            }
            .sheet(item: $editingRecord) { record in
                EditRecordView(record: record, recordManager: recordManager)
            }
        }
    }
}

// MARK: - 历史记录卡片
struct HistoryRecordCard: View {
    let record: SleepRecord
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 日期图标
            VStack(spacing: 2) {
                Text(dayOfMonth)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.primary)
                Text(monthAbbrev)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(width: 48)
            
            // 详情
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.xs) {
                    Text(record.formattedSleepTime)
                        .font(AppTypography.calloutMedium)
                    
                    if let wakeTime = record.formattedWakeTime {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppColors.textTertiary)
                        Text(wakeTime)
                            .font(AppTypography.calloutMedium)
                    }
                }
                .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.sm) {
                    Label(record.formattedDuration, systemImage: "clock.fill")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.lg)
        .shadow(
            color: AppShadow.small.color,
            radius: AppShadow.small.radius,
            x: AppShadow.small.x,
            y: AppShadow.small.y
        )
    }
    
    private var dayOfMonth: String {
        DateFormatters.dayNumber.string(from: record.sleepTime)
    }
    
    private var monthAbbrev: String {
        DateFormatters.monthZh.string(from: record.sleepTime)
    }
}

// MARK: - 编辑记录视图
struct EditRecordView: View {
    let record: SleepRecord
    @ObservedObject var recordManager: SleepRecordManager
    @Environment(\.dismiss) var dismiss
    
    @State private var sleepTime: Date
    @State private var wakeTime: Date
    
    init(record: SleepRecord, recordManager: SleepRecordManager) {
        self.record = record
        self.recordManager = recordManager
        _sleepTime = State(initialValue: record.sleepTime)
        _wakeTime = State(initialValue: record.wakeTime ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("睡眠时间") {
                    DatePicker("入睡时间", selection: $sleepTime, in: ...Date())
                    DatePicker("醒来时间", selection: $wakeTime, in: sleepTime...Date())
                }
                
                Section {
                    HStack {
                        Text("睡眠时长")
                        Spacer()
                        Text(formattedDuration)
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        recordManager.deleteRecord(record)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("删除记录")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private var canSave: Bool {
        wakeTime > sleepTime
    }
    
    private var formattedDuration: String {
        let duration = wakeTime.timeIntervalSince(sleepTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        }
        return "\(minutes)分钟"
    }
    
    private func saveChanges() {
        guard canSave else { return }
        var updatedRecord = record
        updatedRecord.sleepTime = sleepTime
        updatedRecord.wakeTime = wakeTime
        recordManager.updateRecord(updatedRecord)
        dismiss()
    }
}

#Preview {
    ContentView()
}
