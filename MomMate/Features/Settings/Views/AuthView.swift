//
//  AuthView.swift
//  MomMate
//
//  Authentication view for login/logout
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
                AppColors.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: AppSpacing.lg) {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "person.badge.key.fill")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                            .accessibilityHidden(true)
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
                            .accessibilityLabel("退出登录")
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
                            .accessibilityLabel("使用 Google 登录")

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
                            .accessibilityLabel("使用微信登录")

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
                            .accessibilityLabel("错误：\(errorMessage)")
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
