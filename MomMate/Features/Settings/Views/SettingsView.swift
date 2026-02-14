//
//  SettingsView.swift
//  MomMate
//
//  Settings view — 现代极简风格
//

import SwiftUI

struct DataClearOptions {
    var sleep: Bool = true
    var meal: Bool = true
    var milestone: Bool = true

    var hasSelection: Bool {
        sleep || meal || milestone
    }
}

struct SettingsView: View {
    let onClearData: (DataClearOptions) -> Void
    @AppStorage(StorageKeys.fontSizeFactor) private var fontSizeFactor: Double = 1.0
    @AppStorage(StorageKeys.cloudSyncEnabled) private var cloudSyncEnabled: Bool = true
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager()
    @State private var showingAuthSheet = false
    @State private var showingClearDataSheet = false
    @State private var showingClearedAlert = false
    @State private var confirmCountdown = 5
    @State private var clearOptions = DataClearOptions()
    @State private var countdownTask: Task<Void, Never>?

    private let versionHighlights: [String: [String]] = [
        "1.0.1": [
            "设置页新增版本号显示，便于确认当前安装版本。",
            "设置页新增简洁更新信息，帮助快速了解本次变化。"
        ]
    ]

    private var shortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }

    private var buildVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
    }

    private var displayVersion: String {
        "v\(shortVersion) (\(buildVersion))"
    }

    private var currentVersionHighlights: [String] {
        versionHighlights[shortVersion] ?? ["体验优化与问题修复。"]
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 账号入口
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("账号")
                                .font(AppTypography.calloutMedium)
                                .foregroundColor(AppColors.textSecondary)

                            Button {
                                showingAuthSheet = true
                            } label: {
                                HStack(spacing: AppSpacing.md) {
                                    Image(systemName: authManager.syncButtonIcon)
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(authManager.syncButtonColor)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(authManager.syncButtonTitle)
                                            .font(AppTypography.calloutMedium)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text("管理第三方登录与同步状态")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textTertiary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                .padding(AppSpacing.md)
                                .background(AppColors.surface)
                                .cornerRadius(AppRadius.lg)
                            }
                        }

                        // 云端同步
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("数据同步")
                                .font(AppTypography.calloutMedium)
                                .foregroundColor(AppColors.textSecondary)

                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "icloud")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(cloudSyncEnabled ? AppColors.primary : AppColors.textTertiary)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("iCloud 云端同步")
                                            .font(AppTypography.calloutMedium)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text(cloudSyncEnabled ? "数据将在设备间自动同步" : "同步已关闭")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textTertiary)
                                    }

                                    Spacer()

                                    Toggle("", isOn: $cloudSyncEnabled)
                                        .labelsHidden()
                                        .tint(AppColors.primary)
                                }
                                .padding(AppSpacing.md)

                                if cloudSyncEnabled {
                                    Divider()
                                        .foregroundColor(AppColors.divider)
                                        .padding(.leading, AppSpacing.md)

                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(AppColors.textTertiary)
                                        Text("上次同步：\(CloudSyncStore.lastSyncFormatted)")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textTertiary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.xs)
                                }
                            }
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                        }

                        // 数据管理
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("数据管理")
                                .font(AppTypography.calloutMedium)
                                .foregroundColor(AppColors.textSecondary)

                            Button {
                                clearOptions = DataClearOptions()
                                showingClearDataSheet = true
                                startConfirmCountdown()
                            } label: {
                                HStack(spacing: AppSpacing.md) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.red.opacity(0.85))
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("清空数据")
                                            .font(AppTypography.calloutMedium)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text("支持按模块选择要清空的数据")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textTertiary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                .padding(AppSpacing.md)
                                .background(AppColors.surface)
                                .cornerRadius(AppRadius.lg)
                            }
                        }

                        // 文字大小
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("文字大小")
                                .font(AppTypography.calloutMedium)
                                .foregroundColor(AppColors.textSecondary)

                            VStack(spacing: AppSpacing.md) {
                                // 预览
                                VStack(spacing: AppSpacing.xxs) {
                                    Text("预览效果")
                                        .font(AppTypography.title3)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("调整下方滑块改变文字大小")
                                        .font(AppTypography.footnote)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(AppColors.surfaceSecondary)
                                .cornerRadius(AppRadius.md)

                                // 滑块
                                HStack {
                                    Image(systemName: "textformat.size.smaller")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.textTertiary)

                                    Slider(value: $fontSizeFactor, in: 0.8...1.5, step: 0.1)
                                        .tint(AppColors.primary)

                                    Image(systemName: "textformat.size.larger")
                                        .font(.system(size: 18))
                                        .foregroundColor(AppColors.textTertiary)
                                }

                                Text(String(format: "当前: %.1fx", fontSizeFactor))
                                    .font(AppTypography.captionMedium)
                                    .foregroundColor(AppColors.primary)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                        }

                        Text("调整后，App 内所有文字大小将随之变化。")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("版本信息")
                                .font(AppTypography.calloutMedium)
                                .foregroundColor(AppColors.textSecondary)

                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack(spacing: AppSpacing.md) {
                                    Image(systemName: "number.circle")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.primary)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("当前版本")
                                            .font(AppTypography.calloutMedium)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text(displayVersion)
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textTertiary)
                                    }
                                }

                                Divider()
                                    .foregroundColor(AppColors.divider)

                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text("本次更新")
                                        .font(AppTypography.captionMedium)
                                        .foregroundColor(AppColors.textSecondary)

                                    ForEach(currentVersionHighlights, id: \.self) { item in
                                        Text("• \(item)")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textTertiary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.vertical, AppSpacing.xl)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAuthSheet) {
                AuthView(authManager: authManager, showingSheet: $showingAuthSheet)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppRadius.xxl)
            }
            .sheet(isPresented: $showingClearDataSheet, onDismiss: {
                cancelConfirmCountdown()
            }) {
                NavigationView {
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.red.opacity(0.85))
                            .padding(.top, AppSpacing.md)

                        Text("确认清空数据？")
                            .font(AppTypography.title2)
                            .foregroundColor(AppColors.textPrimary)

                        Text("该操作不可撤销，请先选择要清空的数据类型。")
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.lg)

                        VStack(spacing: AppSpacing.xs) {
                            ClearOptionRow(
                                title: "睡眠记录",
                                subtitle: "清空所有睡眠记录",
                                isOn: $clearOptions.sleep
                            )
                            ClearOptionRow(
                                title: "饮食记录",
                                subtitle: "清空所有饮食记录",
                                isOn: $clearOptions.meal
                            )
                            ClearOptionRow(
                                title: "成长里程碑",
                                subtitle: "清空所有里程碑记录",
                                isOn: $clearOptions.milestone
                            )
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        Spacer()

                        Button(role: .destructive) {
                            onClearData(clearOptions)
                            showingClearDataSheet = false
                            showingClearedAlert = true
                        } label: {
                            Text(confirmCountdown > 0 ? "确认清空（\(confirmCountdown)s）" : "确认清空")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .red.opacity(0.85)))
                        .disabled(confirmCountdown > 0 || !clearOptions.hasSelection)
                        .padding(.horizontal, AppSpacing.lg)

                        if !clearOptions.hasSelection {
                            Text("请至少选择一项数据")
                                .font(AppTypography.caption)
                                .foregroundColor(.red.opacity(0.75))
                        }

                        Button("取消") {
                            showingClearDataSheet = false
                        }
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.bottom, AppSpacing.lg)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("关闭") { showingClearDataSheet = false }
                        }
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
            .alert("数据已清空", isPresented: $showingClearedAlert) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text("所选数据已被删除。")
            }
            .onDisappear {
                cancelConfirmCountdown()
            }
        }
    }

    private func startConfirmCountdown() {
        cancelConfirmCountdown()
        confirmCountdown = 5
        countdownTask = Task {
            while confirmCountdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                await MainActor.run {
                    confirmCountdown -= 1
                }
            }
        }
    }

    private func cancelConfirmCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
    }
}

private struct ClearOptionRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isOn ? AppColors.primary : AppColors.textTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.calloutMedium)
                        .foregroundColor(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }

                Spacer()
            }
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)
        }
    }
}
