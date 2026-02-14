//
//  StatisticsTabView.swift
//  MomMate
//
//  Statistics tab — 现代极简风格
//

import SwiftUI
import Charts

// MARK: - 时间范围
enum StatsRange: String, CaseIterable {
    case week = "周"
    case month = "月"
    case year = "年"

    var strideUnit: Calendar.Component {
        switch self {
        case .week: return .day
        case .month: return .day
        case .year: return .month
        }
    }

    var dateFormat: Date.FormatStyle {
        switch self {
        case .week:  return .dateTime.day()
        case .month: return .dateTime.day()
        case .year:  return .dateTime.month(.abbreviated)
        }
    }

    /// 指定 anchor date 所对应的区间 [start, end)
    func dateRange(for anchor: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        switch self {
        case .week:
            // 周一 ~ 周日
            let weekday = cal.component(.weekday, from: anchor)
            let daysToMonday = (weekday == 1) ? -6 : (2 - weekday)
            let startOfAnchor = cal.startOfDay(for: anchor)
            let monday = cal.date(byAdding: .day, value: daysToMonday, to: startOfAnchor) ?? startOfAnchor
            let nextMonday = cal.date(byAdding: .day, value: 7, to: monday)
                ?? cal.date(byAdding: .day, value: 1, to: monday)
                ?? monday
            return (monday, nextMonday)
        case .month:
            let comps = cal.dateComponents([.year, .month], from: anchor)
            let start = cal.date(from: comps) ?? cal.startOfDay(for: anchor)
            let end = cal.date(byAdding: .month, value: 1, to: start)
                ?? cal.date(byAdding: .day, value: 30, to: start)
                ?? start
            return (start, end)
        case .year:
            let comps = cal.dateComponents([.year], from: anchor)
            let start = cal.date(from: comps) ?? cal.startOfDay(for: anchor)
            let end = cal.date(byAdding: .year, value: 1, to: start)
                ?? cal.date(byAdding: .day, value: 365, to: start)
                ?? start
            return (start, end)
        }
    }

    /// 向前/后翻一个周期
    func shift(_ anchor: Date, by delta: Int) -> Date {
        let cal = Calendar.current
        switch self {
        case .week:
            return cal.date(byAdding: .weekOfYear, value: delta, to: anchor) ?? anchor
        case .month:
            return cal.date(byAdding: .month, value: delta, to: anchor) ?? anchor
        case .year:
            return cal.date(byAdding: .year, value: delta, to: anchor) ?? anchor
        }
    }

    /// 显示文本
    func label(for anchor: Date) -> String {
        let (start, end) = dateRange(for: anchor)
        let cal = Calendar.current
        switch self {
        case .week:
            let lastDay = cal.date(byAdding: .day, value: -1, to: end) ?? start
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "zh_CN")
            fmt.dateFormat = "M月d日"
            return "\(fmt.string(from: start)) ~ \(fmt.string(from: lastDay))"
        case .month:
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "zh_CN")
            fmt.dateFormat = "yyyy年M月"
            return fmt.string(from: start)
        case .year:
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "zh_CN")
            fmt.dateFormat = "yyyy年"
            return fmt.string(from: start)
        }
    }

    /// 区间天数（用于平均值计算）
    func daysCount(for anchor: Date) -> Int {
        let (start, end) = dateRange(for: anchor)
        return Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1
    }
}

struct StatisticsTabView: View {
    @ObservedObject var recordManager: SleepRecordManager
    @ObservedObject var mealRecordManager: MealRecordManager
    @State private var selectedMode: StatsMode = .sleep
    @State private var selectedRange: StatsRange = .week
    @State private var anchorDate: Date = Date()
    @AppStorage(StorageKeys.fontSizeFactor) private var fontSizeFactor: Double = 1.0

    enum StatsMode: String, CaseIterable {
        case sleep = "睡眠"
        case meal = "饮食"
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.md) {
                        // 分段控制（睡眠/饮食）+ 时间控制合并
                        StatsSegmentControl(selectedMode: $selectedMode)

                        // 时间范围 + 导航合为一行
                        StatsTimeControl(
                            selectedRange: $selectedRange,
                            anchorDate: $anchorDate
                        )

                        // 概览数据
                        StatsOverviewRow(
                            mode: selectedMode,
                            range: selectedRange,
                            anchorDate: anchorDate,
                            sleepManager: recordManager,
                            mealManager: mealRecordManager
                        )

                        // 详细图表
                        if selectedMode == .sleep {
                            SleepStatsContent(
                                sleepManager: recordManager,
                                range: selectedRange,
                                anchorDate: anchorDate
                            )
                        } else {
                            MealStatsContent(
                                mealManager: mealRecordManager,
                                range: selectedRange,
                                anchorDate: anchorDate
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.xs)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .navigationTitle("统计")
            .navigationBarTitleDisplayMode(.inline)
            .id(fontSizeFactor)
        }
    }
}

// MARK: - 分段控制 — 紧凑下划线
struct StatsSegmentControl: View {
    @Binding var selectedMode: StatisticsTabView.StatsMode
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StatisticsTabView.StatsMode.allCases, id: \.self) { mode in
                VStack(spacing: 4) {
                    Text(mode.rawValue)
                        .font(selectedMode == mode ? AppTypography.bodyMedium : AppTypography.body)
                        .foregroundColor(selectedMode == mode ? AppColors.textPrimary : AppColors.textTertiary)

                    if selectedMode == mode {
                        Capsule()
                            .fill(AppColors.primary)
                            .frame(width: 24, height: 2)
                            .matchedGeometryEffect(id: "indicator", in: animation)
                    } else {
                        Capsule()
                            .fill(Color.clear)
                            .frame(width: 24, height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticManager.selection()
                    withAnimation(AppAnimation.springSnappy) {
                        selectedMode = mode
                    }
                }
            }
        }
    }
}

// MARK: - 时间控制（范围选择 + 翻页导航合一）
struct StatsTimeControl: View {
    @Binding var selectedRange: StatsRange
    @Binding var anchorDate: Date

    private var isCurrentPeriod: Bool {
        let (start, _) = selectedRange.dateRange(for: Date())
        let (aStart, _) = selectedRange.dateRange(for: anchorDate)
        return start == aStart
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // 周 / 月 / 年 分段控制
            HStack(spacing: 0) {
                ForEach(StatsRange.allCases, id: \.self) { range in
                    Button {
                        HapticManager.selection()
                        withAnimation(AppAnimation.springSnappy) {
                            selectedRange = range
                            anchorDate = Date()
                        }
                    } label: {
                        Text(range.rawValue)
                            .font(.system(size: 14, weight: selectedRange == range ? .semibold : .medium))
                            .foregroundColor(selectedRange == range ? AppColors.textPrimary : AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                selectedRange == range
                                    ? RoundedRectangle(cornerRadius: 8).fill(AppColors.surface)
                                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
                                    : nil
                            )
                    }
                }
            }
            .padding(3)
            .background(AppColors.surfaceSecondary)
            .cornerRadius(10)

            // < 日期范围 > 导航
            HStack(spacing: AppSpacing.sm) {
                Button {
                    HapticManager.light()
                    withAnimation(AppAnimation.springSnappy) {
                        anchorDate = selectedRange.shift(anchorDate, by: -1)
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 28, height: 28)
                }

                Text(selectedRange.label(for: anchorDate))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)

                Button {
                    HapticManager.light()
                    withAnimation(AppAnimation.springSnappy) {
                        anchorDate = selectedRange.shift(anchorDate, by: 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isCurrentPeriod ? AppColors.textTertiary.opacity(0.3) : AppColors.textSecondary)
                        .frame(width: 28, height: 28)
                }
                .disabled(isCurrentPeriod)
            }
        }
    }
}

// MARK: - 概览数据行
struct StatsOverviewRow: View {
    let mode: StatisticsTabView.StatsMode
    let range: StatsRange
    let anchorDate: Date
    let sleepManager: SleepRecordManager
    let mealManager: MealRecordManager

    private var dateRange: (start: Date, end: Date) {
        range.dateRange(for: anchorDate)
    }

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            if mode == .sleep {
                OverviewMetric(title: "日均睡眠时长", value: averageSleepDuration, unit: "", color: AppColors.sleep)
                OverviewMetric(title: "总睡眠时长", value: totalSleepHours, unit: "", color: AppColors.sleep)
                OverviewMetric(title: "日均睡眠次数", value: averageSleepCount, unit: "次", color: AppColors.sleep)
            } else {
                OverviewMetric(title: "总进食次数", value: "\(totalMealCount)", unit: "次", color: AppColors.meal)
                OverviewMetric(title: "日均进食次数", value: String(format: "%.1f", averageDailyMeals), unit: "次/天", color: AppColors.meal)
                OverviewMetric(title: "日均喝水量", value: "\(averageDailyWaterML)", unit: "ml/天", color: AppColors.meal)
            }
        }
    }

    private var sleepSummary: (duration: TimeInterval, count: Int) {
        let (start, end) = dateRange
        return sleepManager.sleepRangeSummary(start: start, end: end)
    }

    private var mealSummary: (totalCount: Int, mealCount: Int, waterCount: Int, typeCounts: [MealType: Int], totalWaterML: Int) {
        let (start, end) = dateRange
        return mealManager.mealRangeSummary(start: start, end: end)
    }

    private var days: Int { range.daysCount(for: anchorDate) }

    private var averageSleepDuration: String {
        guard sleepSummary.count > 0 else { return "0时" }
        let total = sleepSummary.duration
        let avg = total / Double(days)
        let hours = Int(avg) / 3600
        let minutes = (Int(avg) % 3600) / 60
        return "\(hours)时 \(minutes)分"
    }

    private var totalSleepHours: String {
        let total = sleepSummary.duration
        return "\(Int(total) / 3600)时"
    }

    private var averageSleepCount: String {
        String(format: "%.1f", Double(sleepSummary.count) / Double(days))
    }

    private var totalMealCount: Int { mealSummary.mealCount }

    private var averageDailyMeals: Double {
        Double(mealSummary.mealCount) / Double(days)
    }

    private var averageDailyWaterML: Int {
        Int(round(Double(mealSummary.totalWaterML) / Double(days)))
    }
}

struct OverviewMetric: View {
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1)
                .fill(color)
                .frame(width: 2)
                .padding(.vertical, AppSpacing.sm)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)

                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)

                    if !unit.isEmpty {
                        Text(unit)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(.leading, AppSpacing.sm)
            .padding(.vertical, AppSpacing.sm)
            .padding(.trailing, AppSpacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(AppColors.border.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - 通用趋势图表
struct TrendChart: View {
    let data: [(date: Date, value: Double)]
    let range: StatsRange
    let color: Color
    let yLabel: String

    var body: some View {
        Chart {
            ForEach(data, id: \.date) { item in
                BarMark(
                    x: .value("日期", item.date, unit: range.strideUnit),
                    y: .value(yLabel, item.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.25), color.opacity(0.65)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(range == .year ? AppRadius.sm : AppRadius.xs)
            }
        }
        .frame(height: 200)
        .chartXAxis {
            switch range {
            case .week:
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.day())
                }
            case .month:
                // 每 5 天显示一个标签，避免重叠
                AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                    AxisValueLabel(format: .dateTime.day())
                }
            case .year:
                AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month(.narrow))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { AxisValueLabel() }
        }
    }
}

// MARK: - 睡眠统计
struct SleepStatsContent: View {
    let sleepManager: SleepRecordManager
    let range: StatsRange
    let anchorDate: Date

    private var trendData: [(date: Date, value: Double)] {
        let cal = Calendar.current
        let (start, end) = range.dateRange(for: anchorDate)

        if range == .year {
            // 按月汇总 — 12 个月
            return (0..<12).map { i in
                let monthDate = cal.date(byAdding: .month, value: i, to: start) ?? start
                let monthEnd = cal.date(byAdding: .month, value: 1, to: monthDate)
                    ?? cal.date(byAdding: .day, value: 30, to: monthDate)
                    ?? monthDate
                let summary = sleepManager.sleepRangeSummary(start: monthDate, end: monthEnd)
                let daysInMonth = max(1, cal.dateComponents([.day], from: monthDate, to: monthEnd).day ?? 1)
                let avgHours = summary.duration / Double(daysInMonth) / 3600
                return (date: monthDate, value: avgHours)
            }
        } else {
            let days = cal.dateComponents([.day], from: start, to: end).day ?? 1
            return (0..<days).map { i in
                let date = cal.date(byAdding: .day, value: i, to: start) ?? start
                let summary = sleepManager.sleepDaySummary(for: date)
                let totalHours = summary.duration / 3600
                return (date: date, value: totalHours)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(chartTitle)
                .font(AppTypography.calloutMedium)
                .foregroundColor(AppColors.textSecondary)

            TrendChart(
                data: trendData,
                range: range,
                color: AppColors.sleep,
                yLabel: "时长"
            )
        }
        .glassCard()
    }

    private var chartTitle: String {
        switch range {
        case .week:  return "每日睡眠时长"
        case .month: return "每日睡眠时长"
        case .year:  return "月日均睡眠时长"
        }
    }
}

// MARK: - 饮食统计
struct MealStatsContent: View {
    let mealManager: MealRecordManager
    let range: StatsRange
    let anchorDate: Date
    
    private var dateRange: (start: Date, end: Date) {
        range.dateRange(for: anchorDate)
    }

    private var trendData: [(date: Date, value: Double)] {
        let cal = Calendar.current
        let (start, end) = dateRange

        if range == .year {
            return (0..<12).map { i in
                let monthDate = cal.date(byAdding: .month, value: i, to: start) ?? start
                let daysInMonth = cal.range(of: .day, in: .month, for: monthDate)?.count ?? 30
                let monthEnd = cal.date(byAdding: .month, value: 1, to: monthDate)
                    ?? cal.date(byAdding: .day, value: daysInMonth, to: monthDate)
                    ?? monthDate
                let summary = mealManager.mealRangeSummary(start: monthDate, end: monthEnd)
                return (date: monthDate, value: Double(summary.mealCount) / Double(daysInMonth))
            }
        } else {
            let days = cal.dateComponents([.day], from: start, to: end).day ?? 1
            return (0..<days).map { i in
                let date = cal.date(byAdding: .day, value: i, to: start) ?? start
                let summary = mealManager.mealDaySummary(for: date)
                return (date: date, value: Double(summary.mealCount))
            }
        }
    }

    private var waterTrendData: [(date: Date, value: Double)] {
        let cal = Calendar.current
        let (start, end) = dateRange

        if range == .year {
            return (0..<12).map { i in
                let monthDate = cal.date(byAdding: .month, value: i, to: start) ?? start
                let daysInMonth = cal.range(of: .day, in: .month, for: monthDate)?.count ?? 30
                let monthEnd = cal.date(byAdding: .month, value: 1, to: monthDate)
                    ?? cal.date(byAdding: .day, value: daysInMonth, to: monthDate)
                    ?? monthDate
                let summary = mealManager.mealRangeSummary(start: monthDate, end: monthEnd)
                return (date: monthDate, value: Double(summary.totalWaterML) / Double(daysInMonth))
            }
        } else {
            let days = cal.dateComponents([.day], from: start, to: end).day ?? 1
            return (0..<days).map { i in
                let date = cal.date(byAdding: .day, value: i, to: start) ?? start
                let summary = mealManager.mealDaySummary(for: date)
                return (date: date, value: Double(summary.totalWaterML))
            }
        }
    }

    private var typeDistribution: [(type: String, count: Int)] {
        let (start, end) = dateRange
        let summary = mealManager.mealRangeSummary(start: start, end: end)
        return MealType.allCases
            .map { type in
            (type: type.rawValue, count: summary.typeCounts[type] ?? 0)
        }.filter { $0.count > 0 }
    }

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            // 频率趋势
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(chartTitle)
                    .font(AppTypography.calloutMedium)
                    .foregroundColor(AppColors.textSecondary)

                TrendChart(
                    data: trendData,
                    range: range,
                    color: AppColors.meal,
                    yLabel: "次数"
                )
            }
            .glassCard()

            // 喝水趋势
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(waterChartTitle)
                    .font(AppTypography.calloutMedium)
                    .foregroundColor(AppColors.textSecondary)

                TrendChart(
                    data: waterTrendData,
                    range: range,
                    color: .cyan,
                    yLabel: "ml"
                )
            }
            .glassCard()

            // 类型分布
            if !typeDistribution.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("饮食类型分布（含饮水）")
                        .font(AppTypography.calloutMedium)
                        .foregroundColor(AppColors.textSecondary)

                    Chart {
                        ForEach(typeDistribution, id: \.type) { item in
                            SectorMark(
                                angle: .value("次数", item.count),
                                innerRadius: .ratio(0.65),
                                angularInset: 2
                            )
                            .foregroundStyle(by: .value("类型", item.type))
                            .cornerRadius(AppRadius.sm)
                        }
                    }
                    .frame(height: 200)
                    .chartForegroundStyleScale(
                        domain: MealType.allCases.map { $0.rawValue },
                        range: MealType.allCases.map { $0.color.opacity(0.7) }
                    )

                    VStack(spacing: AppSpacing.xs) {
                        ForEach(typeDistribution, id: \.type) { item in
                            HStack(spacing: AppSpacing.xs) {
                                Circle()
                                    .fill(color(for: item.type).opacity(0.7))
                                    .frame(width: 8, height: 8)

                                Text(item.type)
                                    .font(AppTypography.footnote)
                                    .foregroundColor(AppColors.textSecondary)

                                Spacer()

                                Text("\(item.count) 次")
                                    .font(AppTypography.footnoteMedium)
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                    }
                }
                .glassCard()
            }
        }
    }

    private func color(for typeName: String) -> Color {
        MealType.allCases.first(where: { $0.rawValue == typeName })?.color ?? AppColors.secondary
    }

    private var chartTitle: String {
        switch range {
        case .week:  return "每日进食次数"
        case .month: return "每日进食次数"
        case .year:  return "月均进食次数"
        }
    }

    private var waterChartTitle: String {
        switch range {
        case .week:  return "每日喝水量（ml）"
        case .month: return "每日喝水量（ml）"
        case .year:  return "月均每日喝水量（ml）"
        }
    }
}
