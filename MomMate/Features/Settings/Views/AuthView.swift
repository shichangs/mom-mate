//
//  AuthView.swift
//  MomMate
//
//  Authentication view — 现代极简风格
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @ObservedObject var authManager: AuthManager
    @Binding var showingSheet: Bool
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: AppSpacing.xl) {
                    // Header icon
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "person.badge.key")
                            .font(.system(size: 38, weight: .ultraLight))
                            .foregroundStyle(AppColors.primary)

                        Text("账号与同步")
                            .font(AppTypography.title1)

                        Text("不登录也可以使用，登录仅用于数据同步和备份")
                            .font(AppTypography.subhead)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppSpacing.lg)

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
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))

                            Button(role: .destructive) {
                                authManager.logout()
                            } label: {
                                Text("退出登录（保留本机数据）")
                                    .font(AppTypography.calloutMedium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.md)
                            }
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        }
                    } else {
                        VStack(spacing: AppSpacing.sm) {
                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                errorMessage = authManager.handleAppleSignIn(result)
                                if errorMessage == nil {
                                    showingSheet = false
                                }
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                            LoginButton(icon: "globe", title: "使用谷歌登录") {
                                errorMessage = authManager.startGoogleSignIn()
                            }

                            LoginButton(icon: "message", title: "使用微信登录") {
                                errorMessage = authManager.startWeChatSignIn()
                            }

#if DEBUG
                            LoginButton(icon: "hammer", title: "调试模拟 Apple 登录", color: .orange) {
                                authManager.debugMockSignIn()
                                showingSheet = false
                            }
#endif
                        }

                        Text("已支持 Apple 原生登录；Google/微信需先完成平台参数配置。")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let errorMessage, !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(AppTypography.caption)
                            .foregroundColor(.red.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.xl)
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

// MARK: - 登录按钮
struct LoginButton: View {
    let icon: String
    let title: String
    var color: Color = AppColors.textPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(AppTypography.calloutMedium)
                Spacer()
            }
            .foregroundColor(color)
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        }
    }
}
