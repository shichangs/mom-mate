//
//  StatisticsView.swift
//  BabySleepTracker
//
//  Apple-inspired statistics view with clean charts and data visualization
//

import SwiftUI

struct StatisticsView: View {
    @ObservedObject var recordManager: SleepRecordManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedPeriod: PeriodType = .week
    
    enum PeriodType: String, CaseIterable {
        case day = "天"
        case week = "周"
        case month = "月"
        case year = "年"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 周期选择器
                        SegmentedPeriodPicker(selectedPeriod: $selectedPeriod)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.top, AppSpacing.md)
                        
                        if let stats = currentStatistics, !stats.isEmpty {
                            // 总览卡片
                            SummaryCard(statistics: stats)
                                .padding(.horizontal, AppSpacing.lg)
                            
                            // 趋势图
                            TrendChartCard(
                                data: SleepStatisticsManager.shared.chartData(from: stats),
                                period: selectedPeriod
                            )
                            .padding(.horizontal, AppSpacing.lg)
                            
                            // 详细列表
                            DetailedStatsList(statistics: stats)
                                .padding(.horizontal, AppSpacing.lg)
                        } else {
                            EmptyStateView(
                                icon: "chart.bar.doc.horizontal",
                                title: "暂无统计数据",
                                subtitle: "记录一些睡眠数据后即可查看统计"
                            )
                            .cardStyle()
                            .padding(.horizontal, AppSpacing.lg)
                        }
                    }
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .navigationTitle("睡眠统计")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
    
    private var currentStatistics: [SleepStatistics]? {
        let completedRecords = recordManager.completedRecords
        switch selectedPeriod {
        case .day:
            return SleepStatisticsManager.shared.dailyStatistics(from: completedRecords)
        case .week:
            return SleepStatisticsManager.shared.weeklyStatistics(from: completedRecords)
        case .month:
            return SleepStatisticsManager.shared.monthlyStatistics(from: completedRecords)
        case .year:
            return SleepStatisticsManager.shared.yearlyStatistics(from: completedRecords)
        }
    }
}

// MARK: - 分段选择器
struct SegmentedPeriodPicker: View {
    @Binding var selectedPeriod: StatisticsView.PeriodType
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(StatisticsView.PeriodType.allCases, id: \.self) { period in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedPeriod = period
                    }
                }) {
                    Text(period.rawValue)
                        .font(AppTypography.subheadMedium)
                        .foregroundColor(selectedPeriod == period ? .white : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .fill(selectedPeriod == period ? AppColors.primary : Color.clear)
                        )
                }
            }
        }
        .padding(AppSpacing.xxs)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .shadow(
            color: AppShadow.small.color,
            radius: AppShadow.small.radius,
            x: AppShadow.small.x,
            y: AppShadow.small.y
        )
    }
}

// MARK: - 总览卡片
struct SummaryCard: View {
    let statistics: [SleepStatistics]
    
    private var totalDuration: TimeInterval {
        statistics.reduce(0) { $0 + $1.totalDuration }
    }
    
    private var averageDuration: TimeInterval {
        let total = statistics.reduce(0) { $0 + $1.averageDuration }
        return statistics.isEmpty ? 0 : total / Double(statistics.count)
    }
    
    private var totalCount: Int {
        statistics.reduce(0) { $0 + $1.sleepCount }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 主数据 - 平均睡眠时长
            VStack(spacing: AppSpacing.xs) {
                Text(formatDuration(averageDuration, style: .full))
                    .font(AppTypography.displayMedium)
                    .foregroundColor(AppColors.primary)
                
                Text("平均睡眠时长")
                    .font(AppTypography.subhead)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.vertical, AppSpacing.xl)
            
            Divider()
                .padding(.horizontal, AppSpacing.lg)
            
            // 次要数据
            HStack(spacing: 0) {
                StatItem(
                    value: formatDuration(totalDuration, style: .short),
                    label: "总时长",
                    color: AppColors.accent
                )
                
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    value: "\(totalCount)",
                    label: "睡眠次数",
                    color: AppColors.warning
                )
            }
            .padding(.vertical, AppSpacing.lg)
        }
        .background(AppColors.surface)
        .cornerRadius(AppRadius.xl)
        .shadow(
            color: AppShadow.medium.color,
            radius: AppShadow.medium.radius,
            x: AppShadow.medium.x,
            y: AppShadow.medium.y
        )
    }
    
    private func formatDuration(_ duration: TimeInterval, style: DurationStyle) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        switch style {
        case .full:
            if hours > 0 {
                return "\(hours)小时\(minutes)分"
            } else {
                return "\(minutes)分钟"
            }
        case .short:
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }
    
    enum DurationStyle {
        case full, short
    }
}

// MARK: - 统计项
struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(AppTypography.title2)
                .foregroundColor(color)
            
            Text(label)
                .font(AppTypography.footnote)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 趋势图卡片
struct TrendChartCard: View {
    let data: [ChartDataPoint]
    let period: StatisticsView.PeriodType
    
    private var maxValue: Double {
        max(data.map { $0.value }.max() ?? 1, 1)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("睡眠趋势")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            if data.isEmpty {
                EmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "暂无数据",
                    subtitle: "开始记录睡眠后查看趋势",
                    color: AppColors.primary
                )
                .frame(height: 200)
            } else {
                // 简洁的柱状图
                GeometryReader { geometry in
                    let barWidth = (geometry.size.width - CGFloat(data.count - 1) * 8) / CGFloat(data.count)
                    let maxHeight = geometry.size.height - 30
                    
                    VStack(spacing: 0) {
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
                }
                .frame(height: 180)
            }
        }
        .cardStyle()
    }
}

// MARK: - 详细统计列表
struct DetailedStatsList: View {
    let statistics: [SleepStatistics]
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("详细数据")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            VStack(spacing: 0) {
                ForEach(Array(statistics.prefix(10).enumerated()), id: \.element.period) { index, stat in
                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text(stat.period)
                                    .font(AppTypography.calloutMedium)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                HStack(spacing: AppSpacing.md) {
                                    Label(stat.formattedTotalDuration, systemImage: "clock.fill")
                                    Label("\(stat.sleepCount)次", systemImage: "moon.zzz.fill")
                                }
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text(stat.formattedAverageDuration)
                                .font(AppTypography.calloutMedium)
                                .foregroundColor(AppColors.accent)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                        
                        if index < min(statistics.count - 1, 9) {
                            Divider()
                                .padding(.leading, AppSpacing.md)
                        }
                    }
                }
            }
            .background(AppColors.surface)
            .cornerRadius(AppRadius.lg)
        }
    }
}
