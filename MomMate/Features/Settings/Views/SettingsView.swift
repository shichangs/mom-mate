//
//  SettingsView.swift
//  MomMate
//
//  Settings view — 现代极简风格
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(StorageKeys.fontSizeFactor) private var fontSizeFactor: Double = 1.0
    @AppStorage(StorageKeys.cloudSyncEnabled) private var cloudSyncEnabled: Bool = true
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager()
    @State private var showingAuthSheet = false

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
        }
    }
}
