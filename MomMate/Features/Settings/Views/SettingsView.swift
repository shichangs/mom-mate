//
//  SettingsView.swift
//  MomMate
//
//  Settings view with font size, cloud sync, and auth
//  Extracted from MainTabView.swift for single responsibility
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
                        // 账号与同步入口
                        VStack(spacing: AppSpacing.md) {
                            Text("账号")
                                .font(AppTypography.subheadMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button {
                                showingAuthSheet = true
                            } label: {
                                HStack(spacing: AppSpacing.md) {
                                    Image(systemName: authManager.syncButtonIcon)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(authManager.syncButtonColor)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                        Text(authManager.syncButtonTitle)
                                            .font(AppTypography.bodyMedium)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text("管理第三方登录与同步状态")
                                            .font(AppTypography.caption)
                                            .foregroundColor(AppColors.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                .padding(AppSpacing.lg)
                                .background(AppColors.surface)
                                .cornerRadius(AppRadius.lg)
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)

                        // 云端同步设置
                        VStack(spacing: AppSpacing.md) {
                            Text("数据同步")
                                .font(AppTypography.subheadMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack {
                                Image(systemName: "icloud.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(cloudSyncEnabled ? AppColors.primary : AppColors.textTertiary)

                                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                    Text("iCloud 云端同步")
                                        .font(AppTypography.bodyMedium)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(cloudSyncEnabled ? "数据将在您的设备间自动同步" : "同步已关闭")
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textSecondary)
                                }

                                Spacer()

                                Toggle("", isOn: $cloudSyncEnabled)
                                    .labelsHidden()
                                    .tint(AppColors.primary)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.lg)
                                    .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, AppSpacing.md)

                        // 预览卡片
                        VStack(spacing: AppSpacing.md) {
                            Text("预览效果")
                                .font(AppTypography.subheadMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(spacing: AppSpacing.sm) {
                                Text("这是一段预览文字")
                                    .font(AppTypography.title2)
                                    .foregroundColor(AppColors.textPrimary)

                                Text("调整下方的滑块可以改变全屏文字的大小。")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(AppSpacing.md)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.lg)
                                    .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, AppSpacing.md)

                        // 调节滑块
                        VStack(spacing: AppSpacing.md) {
                            Text("文字大小调节")
                                .font(AppTypography.subheadMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(spacing: AppSpacing.lg) {
                                HStack {
                                    Image(systemName: "textformat.size.smaller")
                                        .font(.system(size: 14))

                                    Slider(value: $fontSizeFactor, in: 0.8...1.5, step: 0.1)
                                        .tint(AppColors.primary)

                                    Image(systemName: "textformat.size.larger")
                                        .font(.system(size: 20))
                                }

                                Text(String(format: "当前缩放: %.1fx", fontSizeFactor))
                                    .font(AppTypography.footnoteMedium)
                                    .foregroundColor(AppColors.primary)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.lg)
                                    .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, AppSpacing.md)

                        Text("调整后，App 内的所有文字大小将随之变化。")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                            .padding(.horizontal, AppSpacing.xl)
                            .multilineTextAlignment(.center)
                    }
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
            }
        }
    }
}
