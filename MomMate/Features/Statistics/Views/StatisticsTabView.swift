//
//  StatisticsTabView.swift
//  MomMate
//
//  Statistics tab view and related components
//  Extracted from MainTabView.swift for single responsibility
//

import SwiftUI
import Charts

// MARK: - Insight card data model (replaces unnamed tuple)
struct InsightCard {
    let title: String
    let value: String
    let subtitle: String
}

// MARK: - 统计 Tab 主视图
struct StatisticsTabView: View {
    @ObservedObject var recordManager: SleepRecordManager
    @ObservedObject var mealRecordManager: MealRecordManager
    @State private var statisticsMode: StatisticsMode = .sleep
    @AppStorage(StorageKeys.fontSizeFactor) private var fontSizeFactor: Double = 1.0

    enum StatisticsMode: String, CaseIterable {
        case sleep = "睡眠"
        case meal = "饮食"
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        CustomSegmentedControl(selection: $statisticsMode)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.top, AppSpacing.md)

                        InsightOverviewRow(
                            mode: statisticsMode,
                            sleepRecords: recordManager.completedRecords,
                            mealRecords: mealRecordManager.mealRecords
                        )
                        .padding(.horizontal, AppSpacing.lg)

                        if statisticsMode == .sleep {
                            SleepPreviewStats(recordManager: recordManager)
                        } else {
                            MealStatisticsView(records: mealRecordManager.mealRecords)
                        }
                    }
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .navigationTitle("统计分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("统计分析")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .id(fontSizeFactor)
        }
    }
}

// MARK: - 概览数据行
struct InsightOverviewRow: View {
    let mode: StatisticsTabView.StatisticsMode
    let sleepRecords: [SleepRecord]
    let mealRecords: [MealRecord]

    private var cards: [InsightCard] {
        if mode == .sleep {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

            let todayDuration = sleepRecords.filter { record in
                guard let wakeTime = record.wakeTime else { return false }
                return wakeTime >= today && wakeTime < tomorrow
            }.compactMap(\.duration).reduce(0, +)

            let yesterdayDuration = sleepRecords.filter { record in
                guard let wakeTime = record.wakeTime else { return false }
                return wakeTime >= yesterday && wakeTime < today
            }.compactMap(\.duration).reduce(0, +)

            let delta = (todayDuration - yesterdayDuration) / 3600
            let trend = delta == 0 ? "持平" : (delta > 0 ? "+\(Int(delta))h" : "\(Int(delta))h")

            return [
                InsightCard(title: "今日睡眠", value: formatDuration(todayDuration), subtitle: "醒来记录汇总"),
                InsightCard(title: "昨日对比", value: trend, subtitle: "以睡醒当日归属"),
                InsightCard(title: "记录次数", value: "\(sleepRecords.count)", subtitle: "累计有效睡眠")
            ]
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today

        let todayMeals = mealRecords.filter { $0.date >= today && $0.date < tomorrow }
        let average = Double(mealRecords.count) / 7.0
        let topType = MealType.allCases
            .map { type in (type.rawValue, mealRecords.filter { $0.mealType == type }.count) }
            .max(by: { $0.1 < $1.1 })?.0 ?? "暂无"

        return [
            InsightCard(title: "今日饮食", value: "\(todayMeals.count) 次", subtitle: "自然日统计"),
            InsightCard(title: "近7日均值", value: String(format: "%.1f 次/天", average), subtitle: "粗粒度趋势"),
            InsightCard(title: "最高类型", value: topType, subtitle: "累计出现最多")
        ]
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(Array(cards.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(item.title)
                        .font(AppTypography.captionMedium)
                        .foregroundColor(AppColors.textSecondary)
                    Text(item.value)
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                    Text(item.subtitle)
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
                )
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - 自定义分段选择器
struct CustomSegmentedControl<T: RawRepresentable & CaseIterable>: View where T.RawValue == String, T: Hashable {
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(T.allCases), id: \.self) { item in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = item
                    }
                }) {
                    Text(item.rawValue)
                        .font(AppTypography.subheadMedium)
                        .foregroundColor(selection == item ? .white : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .fill(selection == item ? AppColors.primary : Color.clear)
                        )
                }
            }
        }
        .padding(AppSpacing.xxs)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
        )
    }
}

// MARK: - 睡眠统计内联展示
struct SleepPreviewStats: View {
    @ObservedObject var recordManager: SleepRecordManager
    @State private var selectedPeriod: PeriodType = .week

    enum PeriodType: String, CaseIterable {
        case day = "今日"
        case week = "本周"
        case month = "本月"
    }

    private var statistics: [SleepStatistics] {
        let completedRecords = recordManager.completedRecords
        switch selectedPeriod {
        case .day:
            return SleepStatisticsManager.shared.dailyStatistics(from: completedRecords)
        case .week:
            return SleepStatisticsManager.shared.weeklyStatistics(from: completedRecords)
        case .month:
            return SleepStatisticsManager.shared.monthlyStatistics(from: completedRecords)
        }
    }

    private var averageDuration: TimeInterval {
        let total = statistics.reduce(0) { $0 + $1.averageDuration }
        return statistics.isEmpty ? 0 : total / Double(statistics.count)
    }

    private var totalCount: Int {
        statistics.reduce(0) { $0 + $1.sleepCount }
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Picker("周期", selection: $selectedPeriod) {
                ForEach(PeriodType.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.md)

            VStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.md) {
                    VStack(spacing: AppSpacing.xs) {
                        Text(formatDuration(averageDuration))
                            .font(AppTypography.displaySmall)
                            .foregroundColor(AppColors.sleep)
                        Text("平均时长")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 40)

                    VStack(spacing: AppSpacing.xs) {
                        Text("\(totalCount)")
                            .font(AppTypography.displaySmall)
                            .foregroundColor(AppColors.primary)
                        Text("睡眠次数")
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .glassCard()
            .padding(.horizontal, AppSpacing.md)

            if !statistics.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("睡眠趋势")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.md)

                    GeometryReader { geometry in
                        let data = SleepStatisticsManager.shared.chartData(from: statistics)
                        let barWidth = max((geometry.size.width - CGFloat(data.count - 1) * 8) / CGFloat(max(data.count, 1)), 10)
                        let maxValue = max(data.map { $0.value }.max() ?? 1, 1)
                        let maxHeight = geometry.size.height - 30

                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(data) { point in
                                VStack(spacing: AppSpacing.xxs) {
                                    RoundedRectangle(cornerRadius: AppRadius.sm)
                                        .fill(AppColors.sleepGradient)
                                        .frame(
                                            width: barWidth,
                                            height: max(CGFloat(point.value / maxValue) * maxHeight, 4)
                                        )

                                    Text(point.label)
                                        .font(AppTypography.caption)
                                        .foregroundColor(AppColors.textTertiary)
                                        .frame(width: barWidth)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                }
                            }
                        }
                    }
                    .frame(height: 132)
                    .padding(.horizontal, AppSpacing.md)
                }
                .glassCard(padding: AppSpacing.sm)
                .padding(.horizontal, AppSpacing.md)
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - 饮食统计视图
struct MealStatisticsView: View {
    let records: [MealRecord]

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("进食频率 (过去 7 天)")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)

                Chart {
                    ForEach(frequencyData, id: \.date) { item in
                        BarMark(
                            x: .value("日期", item.date, unit: .day),
                            y: .value("次数", item.count)
                        )
                        .foregroundStyle(AppColors.meal)
                        .cornerRadius(AppRadius.xs)
                    }
                }
                .frame(height: 176)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            }
            .glassCard()

            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("进食类型分布")
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)

                Chart {
                    ForEach(typeDistribution, id: \.type) { item in
                        SectorMark(
                            angle: .value("次数", item.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("类型", item.type))
                        .cornerRadius(AppRadius.sm)
                    }
                }
                .frame(height: 176)
                .chartForegroundStyleScale(domain: MealType.allCases.map { $0.rawValue }, range: MealType.allCases.map { $0.color })
            }
            .glassCard()

            HStack(spacing: AppSpacing.sm) {
                StatsCard(
                    title: "平均每日",
                    value: String(format: "%.1f次", averageDailyCount),
                    subtitle: "过去 7 天",
                    icon: "clock.fill",
                    accentColor: AppColors.meal,
                    gradient: AppColors.mealGradient
                )

                StatsCard(
                    title: "主要类型",
                    value: topMealType?.rawValue ?? "无",
                    subtitle: "出现频率最高",
                    icon: "star.fill",
                    accentColor: AppColors.awake,
                    gradient: AppColors.awakeGradient
                )
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private var frequencyData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        let last7Days = (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: now) }.reversed()

        return last7Days.map { date in
            let count = records.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
            return (date: date, count: count)
        }
    }

    private var typeDistribution: [(type: String, count: Int)] {
        MealType.allCases.map { type in
            let count = records.filter { $0.mealType == type }.count
            return (type: type.rawValue, count: count)
        }.filter { $0.count > 0 }
    }

    private var averageDailyCount: Double {
        let counts = frequencyData.map { Double($0.count) }
        return counts.reduce(0, +) / Double(max(1, counts.count))
    }

    private var topMealType: MealType? {
        let counts = MealType.allCases.map { type in
            (type: type, count: records.filter { $0.mealType == type }.count)
        }
        return counts.max(by: { $0.count < $1.count })?.type
    }
}
