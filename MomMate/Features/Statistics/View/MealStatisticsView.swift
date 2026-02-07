import SwiftUI
import Charts

struct MealStatisticsView: View {
    let records: [MealRecord]
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            // 1. 进食频率趋势 (过去 7 天)
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
                        .foregroundStyle(AppColors.mealGradient)
                        .cornerRadius(AppRadius.xs)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
            }
            .glassCard()
            
            // 2. 餐次类型分布
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
                .frame(height: 200)
                .chartForegroundStyleScale(domain: MealType.allCases.map { $0.rawValue }, range: MealType.allCases.map { $0.color })
            }
            .glassCard()
            
            // 3. 统计摘要
            HStack(spacing: AppSpacing.md) {
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
        .padding(.horizontal, AppSpacing.lg)
    }
    
    // 数据处理逻辑
    private var frequencyData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let now = Date()
        let last7Days = (0..<7).map { calendar.date(byAdding: .day, value: -$0, to: now)! }.reversed()
        
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
