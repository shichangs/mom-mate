//
//  SleepTabView.swift
//  MomMate
//
//  Sleep tab — 现代极简风格
//

import SwiftUI

// MARK: - 睡眠 Tab 主视图
struct SleepTabView: View {
    @ObservedObject var recordManager: SleepRecordManager
    @ObservedObject var notesManager: NotesManager
    @State private var currentTime = Date()
    @State private var showingHistory = false
    @State private var showingNotes = false
    @State private var showingTimePicker = false
    @State private var showingSettings = false
    @AppStorage(StorageKeys.fontSizeFactor) private var fontSizeFactor: Double = 1.0

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var todaySleepDuration: TimeInterval {
        recordManager.sleepDaySummary(for: Date()).duration
    }

    private var yesterdaySleepDuration: TimeInterval {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return recordManager.sleepDaySummary(for: yesterday).duration
    }

    private var todaySleepCount: Int {
        recordManager.sleepDaySummary(for: Date()).count
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 今日概览 — 简约横条
                        SleepDailySummary(
                            todayDuration: todaySleepDuration,
                            yesterdayDuration: yesterdaySleepDuration,
                            sleepCount: todaySleepCount
                        )

                        // 当前状态卡片
                        if let currentRecord = recordManager.currentSleepRecord {
                            SleepingStatusCard(
                                record: currentRecord,
                                currentTime: currentTime,
                                onWakeUp: {
                                    HapticManager.success()
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        recordManager.endCurrentSleep()
                                    }
                                },
                                onWakeUpCustom: {
                                    HapticManager.light()
                                    showingTimePicker = true
                                }
                            )
                        } else {
                            AwakeStatusCard(
                                onSleep: {
                                    HapticManager.medium()
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        recordManager.startSleep()
                                    }
                                },
                                onSleepCustom: {
                                    HapticManager.light()
                                    showingTimePicker = true
                                }
                            )
                        }

                        // 最近记录
                        if !recordManager.completedRecords.isEmpty {
                            RecentSleepSection(
                                records: Array(recordManager.completedRecords.prefix(5)),
                                recordManager: recordManager,
                                onShowAll: { showingHistory = true }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .navigationTitle("睡眠")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItems(showingSettings: $showingSettings)
            }
            .id(fontSizeFactor)
            .sheet(isPresented: $showingHistory) {
                HistoryView(recordManager: recordManager)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppRadius.xxl)
            }
            .sheet(isPresented: $showingNotes) {
                NotesView(notesManager: notesManager)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppRadius.xxl)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppRadius.xxl)
            }
            .sheet(isPresented: $showingTimePicker) {
                TimePickerSheet(
                    isSleeping: recordManager.currentSleepRecord != nil,
                    onConfirm: { minutesAgo in
                        if recordManager.currentSleepRecord != nil {
                            recordManager.endCurrentSleep(minutesAgo: minutesAgo)
                        } else {
                            recordManager.startSleep(minutesAgo: minutesAgo)
                        }
                    }
                )
            }
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
    }
}

// MARK: - 今日睡眠概览 — 极简横条
struct SleepDailySummary: View {
    let todayDuration: TimeInterval
    let yesterdayDuration: TimeInterval
    let sleepCount: Int

    private var deltaText: String {
        let delta = (todayDuration - yesterdayDuration) / 3600
        if delta == 0 { return "与昨天持平" }
        return delta > 0 ? "比昨天多 \(Int(delta))h" : "比昨天少 \(abs(Int(delta)))h"
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 左侧色条
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.sleep)
                .frame(width: 3, height: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("今日睡眠")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                
                HStack(alignment: .lastTextBaseline, spacing: AppSpacing.xs) {
                    Text(formatDuration(todayDuration))
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("·  \(sleepCount) 次")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            Text(deltaText)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .background(
                    Capsule()
                        .fill(AppColors.surfaceSecondary)
                )
        }
        .padding(AppSpacing.md)
        .background(AppColors.sleepTint)
        .cornerRadius(AppRadius.lg)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

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
            // 状态图标 — 简约
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
                // Sun halo rotation
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

// MARK: - 最近睡眠记录
struct RecentSleepSection: View {
    let records: [SleepRecord]
    let recordManager: SleepRecordManager
    let onShowAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "最近记录", showChevron: true, action: onShowAll)

            VStack(spacing: 0) {
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    SwipeDeleteRow(onDelete: {
                        withAnimation { recordManager.deleteRecord(record) }
                    }) {
                        SleepRecordRowView(record: record)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))

                    if index < records.count - 1 {
                        Divider()
                            .foregroundColor(AppColors.divider)
                            .padding(.leading, 50)
                    }
                }
            }
            .background(AppColors.surface)
            .cornerRadius(AppRadius.lg)
        }
    }
}

// MARK: - 睡眠记录行 — 重新设计
struct SleepRecordRowView: View {
    let record: SleepRecord

    private static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 睡眠时长（主角）
            VStack(spacing: 0) {
                Text(durationHours)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                Text(durationMinutes)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(width: 48)

            // 竖线色条
            RoundedRectangle(cornerRadius: 1)
                .fill(AppColors.sleep.opacity(0.4))
                .frame(width: 2, height: 32)

            // 时间线：入睡 → 醒来
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 9))
                        .foregroundColor(AppColors.sleep)
                    Text(Self.timeOnly.string(from: record.sleepTime))
                        .font(AppTypography.footnoteMedium)
                        .foregroundColor(AppColors.textPrimary)

                    if let wakeTime = record.wakeTime {
                        Text("→")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textTertiary)
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 9))
                            .foregroundColor(AppColors.awake)
                        Text(Self.timeOnly.string(from: wakeTime))
                            .font(AppTypography.footnoteMedium)
                            .foregroundColor(AppColors.textPrimary)
                    } else {
                        Text("· 睡眠中")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.sleep)
                    }
                }
            }

            Spacer()

            Text(relativeDateString(record.sleepTime))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Helpers
    private var durationHours: String {
        guard let d = record.duration else { return "—" }
        return "\(Int(d) / 3600)时"
    }

    private var durationMinutes: String {
        guard let d = record.duration else { return "" }
        return "\((Int(d) % 3600) / 60)分"
    }

    private func relativeDateString(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            return DateFormatters.monthDayZh.string(from: date)
        }
    }
}

// MARK: - 时间选择器 Sheet
struct TimePickerSheet: View {
    let isSleeping: Bool
    let onConfirm: (Int) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var selectedTime = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Text(isSleeping ? "选择醒来时间" : "选择入睡时间")
                    .font(AppTypography.title2)
                    .padding(.top, AppSpacing.xl)

                DatePicker(
                    "",
                    selection: $selectedTime,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Button(action: {
                    let minutesAgo = Int(Date().timeIntervalSince(selectedTime) / 60)
                    onConfirm(max(0, minutesAgo))
                    dismiss()
                }) {
                    Text("确认")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppSpacing.lg)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
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
