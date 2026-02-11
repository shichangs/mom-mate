//
//  SleepTabView.swift
//  MomMate
//
//  Sleep tab main view and related components
//  Extracted from MainTabView.swift for single responsibility
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

    // Timer scoped to this view only (not the entire TabView)
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var todaySleepDuration: TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        return recordManager.completedRecords
            .filter { record in
                guard let wakeTime = record.wakeTime else { return false }
                return wakeTime >= today && wakeTime < tomorrow
            }
            .compactMap(\.duration)
            .reduce(0, +)
    }

    private var yesterdaySleepDuration: TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        return recordManager.completedRecords
            .filter { record in
                guard let wakeTime = record.wakeTime else { return false }
                return wakeTime >= yesterday && wakeTime < today
            }
            .compactMap(\.duration)
            .reduce(0, +)
    }

    private var todaySleepCount: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        return recordManager.completedRecords.filter { record in
            guard let wakeTime = record.wakeTime else { return false }
            return wakeTime >= today && wakeTime < tomorrow
        }.count
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        EmotionalDailySummaryCard(
                            todayDuration: todaySleepDuration,
                            yesterdayDuration: yesterdaySleepDuration,
                            sleepCount: todaySleepCount
                        )

                        if let currentRecord = recordManager.currentSleepRecord {
                            SleepingStatusCard(
                                record: currentRecord,
                                currentTime: currentTime,
                                onWakeUp: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        recordManager.endCurrentSleep()
                                    }
                                },
                                onWakeUpCustom: {
                                    showingTimePicker = true
                                }
                            )
                        } else {
                            AwakeStatusCard(
                                onSleep: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        recordManager.startSleep()
                                    }
                                },
                                onSleepCustom: {
                                    showingTimePicker = true
                                }
                            )
                        }

                        if !recordManager.completedRecords.isEmpty {
                            RecentSleepSection(
                                records: Array(recordManager.completedRecords.prefix(5)),
                                onShowAll: { showingHistory = true }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationTitle("睡眠")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("睡眠")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                }
                ToolbarItems(showingSettings: $showingSettings, showingNotes: $showingNotes)
            }
            .id(fontSizeFactor)
            .sheet(isPresented: $showingHistory) {
                HistoryView(recordManager: recordManager)
            }
            .sheet(isPresented: $showingNotes) {
                NotesView(notesManager: notesManager)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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

// MARK: - 今日睡眠状态概览卡片
struct EmotionalDailySummaryCard: View {
    let todayDuration: TimeInterval
    let yesterdayDuration: TimeInterval
    let sleepCount: Int

    private var deltaText: String {
        let delta = (todayDuration - yesterdayDuration) / 3600
        if delta == 0 { return "与昨天持平" }
        return delta > 0 ? "比昨天多 \(Int(delta)) 小时" : "比昨天少 \(abs(Int(delta))) 小时"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("今日睡眠状态")
                .font(AppTypography.captionMedium)
                .foregroundColor(.white.opacity(0.85))

            HStack(alignment: .lastTextBaseline, spacing: AppSpacing.xs) {
                Text(formatDuration(todayDuration))
                    .font(AppTypography.title1)
                    .foregroundColor(.white)
                Text("已记录 \(sleepCount) 次")
                    .font(AppTypography.caption)
                    .foregroundColor(.white.opacity(0.8))
            }

            Text(deltaText)
                .font(AppTypography.footnote)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(AppColors.primary)
        .cornerRadius(AppRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColors.primary.opacity(0.15), lineWidth: 1)
        )
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
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(AppColors.sleep)
                    .frame(width: 96, height: 96)

                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(height: 136)

            VStack(spacing: AppSpacing.xs) {
                Text(formatDuration(sleepDuration))
                    .font(AppTypography.timerSmall)
                    .foregroundColor(AppColors.sleep)

                Text("宝宝正在睡觉")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)

                Text("\(formatTime(record.sleepTime)) 入睡")
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
            }

            VStack(spacing: AppSpacing.sm) {
                Button(action: onWakeUp) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "sun.max.fill")
                        Text("记录醒来")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: AppColors.accent))
                .accessibilityLabel("记录宝宝醒来")
                .accessibilityHint("点击标记宝宝已醒来")

                Button(action: onWakeUpCustom) {
                    Text("选择其他时间")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.top, AppSpacing.sm)
        }
        .padding(.vertical, AppSpacing.xl)
        .padding(.horizontal, AppSpacing.md)
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

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                Circle()
                    .fill(AppColors.awake)
                    .frame(width: 84, height: 84)

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(spacing: AppSpacing.xs) {
                Text("宝宝醒着")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.awake)

                Text("点击下方按钮记录入睡")
                    .font(AppTypography.callout)
                    .foregroundColor(AppColors.textSecondary)
            }

            VStack(spacing: AppSpacing.sm) {
                Button(action: onSleep) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "moon.fill")
                        Text("记录入睡")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(color: AppColors.sleep))
                .accessibilityLabel("记录宝宝入睡")
                .accessibilityHint("点击标记宝宝已入睡")

                Button(action: onSleepCustom) {
                    Text("选择其他时间")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.top, AppSpacing.sm)
        }
        .padding(.vertical, AppSpacing.xl)
        .padding(.horizontal, AppSpacing.md)
        .glassCard(padding: 0)
    }
}

// MARK: - 最近睡眠记录区块
struct RecentSleepSection: View {
    let records: [SleepRecord]
    let onShowAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            SectionHeader(title: "最近记录", showChevron: true, action: onShowAll)

            VStack(spacing: 0) {
                ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                    SleepRecordRowView(record: record)

                    if index < records.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(AppColors.surface)
            .cornerRadius(AppRadius.lg)
        }
    }
}

// MARK: - 睡眠记录行
struct SleepRecordRowView: View {
    let record: SleepRecord

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            IconCircle(
                icon: "moon.zzz.fill",
                size: 40,
                iconSize: 18,
                color: AppColors.sleep
            )

            VStack(alignment: .leading, spacing: 2) {
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

                Text(record.formattedDuration)
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Text(relativeDateString(record.sleepTime))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
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
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - 睡眠页面工具栏
struct ToolbarItems: ToolbarContent {
    @Binding var showingSettings: Bool
    @Binding var showingNotes: Bool

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
                    .foregroundColor(AppColors.primary)
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { showingNotes = true }) {
                Image(systemName: "doc.text")
                    .foregroundColor(AppColors.primary)
            }
        }
    }
}
