//
//  SleepTabComponents.swift
//  MomMate
//
//  Shared UI components extracted from SleepTabView.
//

import SwiftUI

// MARK: - 正在睡觉状态卡片
struct SleepingStatusCard: View {
    let record: SleepRecord
    let currentTime: Date
    let onWakeUp: () -> Void
    let onWakeUpCustom: () -> Void

    private var sleepDuration: TimeInterval {
        currentTime.timeIntervalSince(record.sleepTime)
    }

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            ZStack {
                BreathingCircle(color: AppColors.sleep, size: 88)

                Image(systemName: "moon.zzz")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(AppColors.sleep)
            }
            .frame(height: 120)

            VStack(spacing: AppSpacing.xs) {
                Text(formatDuration(sleepDuration))
                    .font(AppTypography.timer)
                    .foregroundColor(AppColors.textPrimary)

                Text("正在睡觉")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)

                Text("\(formatTime(record.sleepTime)) 入睡")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            VStack(spacing: AppSpacing.sm) {
                Button(action: onWakeUp) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "sun.max")
                        Text("记录醒来")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: AppColors.accent))

                Button(action: onWakeUpCustom) {
                    Text("选择其他时间")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(.vertical, AppSpacing.xxl)
        .padding(.horizontal, AppSpacing.lg)
        .glassCard(padding: 0)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        }
        return String(format: "%d分钟", minutes)
    }

    private func formatTime(_ date: Date) -> String {
        DateFormatters.time24ZhCN.string(from: date)
    }
}

// MARK: - 清醒状态卡片
struct AwakeStatusCard: View {
    let onSleep: () -> Void
    let onSleepCustom: () -> Void
    @State private var sunRotation: Double = 0

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [AppColors.awake.opacity(0.08), AppColors.awake.opacity(0.02), AppColors.awake.opacity(0.08)],
                            center: .center
                        )
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(sunRotation))

                Circle()
                    .fill(AppColors.awake.opacity(0.08))
                    .frame(width: 88, height: 88)

                Image(systemName: "sun.max")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(AppColors.awake)
            }
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    sunRotation = 360
                }
            }

            VStack(spacing: AppSpacing.xs) {
                Text("宝宝醒着")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)

                Text("点击下方按钮记录入睡")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textTertiary)
            }

            VStack(spacing: AppSpacing.sm) {
                Button(action: onSleep) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "moon")
                        Text("记录入睡")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: AppColors.sleep))

                Button(action: onSleepCustom) {
                    Text("选择其他时间")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(.vertical, AppSpacing.xxl)
        .padding(.horizontal, AppSpacing.lg)
        .glassCard(padding: 0)
    }
}

// MARK: - 工具栏
struct ToolbarItems: ToolbarContent {
    @Binding var showingSettings: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}
