//
//  MainTabView.swift
//  MomMate
//
//  4-tab navigation with Apple-inspired design
//

import SwiftUI
import Charts

struct MainTabView: View {
    @StateObject private var recordManager = SleepRecordManager()
    @StateObject private var notesManager = NotesManager()
    @StateObject private var milestoneManager = MilestoneManager()
    @StateObject private var mealRecordManager = MealRecordManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 睡眠 Tab
            SleepTabView(
                recordManager: recordManager,
                notesManager: notesManager
            )
            .tabItem {
                Label("睡眠", systemImage: selectedTab == 0 ? "moon.zzz.fill" : "moon.zzz")
            }
            .tag(0)
            
            // 饮食 Tab
            MealsTabView(mealRecordManager: mealRecordManager)
                .tabItem {
                    Label("饮食", systemImage: selectedTab == 1 ? "fork.knife.circle.fill" : "fork.knife.circle")
                }
                .tag(1)
            
            // 统计 Tab
            StatisticsTabView(
                recordManager: recordManager,
                mealRecordManager: mealRecordManager
            )
            .tabItem {
                Label("统计", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
            }
            .tag(2)
            
            // 成长 Tab
            GrowthTabView(milestoneManager: milestoneManager)
                .tabItem {
                    Label("成长", systemImage: selectedTab == 3 ? "sparkles" : "sparkles")
                }
                .tag(3)
        }
        .tint(AppColors.primary)
    }
}

// MARK: - 睡眠 Tab 主视图
struct SleepTabView: View {
    @ObservedObject var recordManager: SleepRecordManager
    @ObservedObject var notesManager: NotesManager
    @State private var currentTime = Date()
    @State private var showingHistory = false
    @State private var showingNotes = false
    @State private var showingTimePicker = false
    @State private var showingSettings = false
    @AppStorage("fontSizeFactor") private var fontSizeFactor: Double = 1.0
    
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 主状态卡片
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
                        
                        // 最近睡眠记录
                        if !recordManager.completedRecords.isEmpty {
                            RecentSleepSection(
                                records: Array(recordManager.completedRecords.prefix(5)),
                                onShowAll: { showingHistory = true }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
            .navigationTitle("睡眠")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItems(showingSettings: $showingSettings, showingNotes: $showingNotes)
            }
            .id(fontSizeFactor) // 强制重绘以更新字体大小
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

// MARK: - 饮食 Tab 主视图
struct MealsTabView: View {
    @ObservedObject var mealRecordManager: MealRecordManager
    @State private var showingAddMeal = false
    @State private var showingMamaRecipe = false
    @State private var selectedMealType: MealType? = nil
    @AppStorage("fontSizeFactor") private var fontSizeFactor: Double = 1.0
    @AppStorage("customFoods") private var customFoodsData: Data = Data()
    
    var filteredRecords: [MealRecord] {
        if let type = selectedMealType {
            return mealRecordManager.mealRecordsByType(type)
        }
        return mealRecordManager.sortedMealRecords
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                if mealRecordManager.mealRecords.isEmpty {
                    EmptyStateView(
                        icon: "fork.knife.circle",
                        title: "还没有饮食记录",
                        subtitle: "点击右上角添加宝宝的饮食",
                        color: AppColors.meal
                    )
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.xl) {
                            // 今日概览
                            TodaySummaryCard(records: mealRecordManager.mealRecordsForToday())
                            
                            // 餐次筛选
                            MealFilterBar(selectedType: $selectedMealType)
                            
                            // 记录列表
                            VStack(spacing: AppSpacing.sm) {
                                ForEach(filteredRecords) { record in
                                    MealRecordCardView(record: record)
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                mealRecordManager.deleteMealRecord(record)
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xxl)
                    }
                }
            }
            .navigationTitle("饮食")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingMamaRecipe = true }) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.meal)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMeal = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.meal)
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                QuickAddMealSheet(mealRecordManager: mealRecordManager)
            }
            .sheet(isPresented: $showingMamaRecipe) {
                MamaRecipeView()
            }
            .id(fontSizeFactor)
        }
    }
}

// MARK: - 妈妈食谱视图
struct MamaRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("customFoods") private var customFoodsData: Data = Data()
    @State private var newFoodName: String = ""
    
    private var customFoods: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: customFoodsData)) ?? []
        }
    }
    
    private func saveCustomFoods(_ foods: [String]) {
        if let data = try? JSONEncoder().encode(foods) {
            customFoodsData = data
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 说明
                        Text("在这里添加宝宝常吃的食物，添加饮食记录时可以快速选择。")
                            .font(AppTypography.subhead)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.lg)
                        
                        // 添加新食物
                        VStack(spacing: AppSpacing.md) {
                            Text("添加新食物")
                                .font(AppTypography.subheadMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                TextField("食物名称", text: $newFoodName)
                                    .textFieldStyle(.roundedBorder)
                                
                                Button(action: addFood) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(AppColors.meal)
                                }
                                .disabled(newFoodName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
                        // 已添加的食物列表
                        VStack(spacing: AppSpacing.md) {
                            Text("我的食物列表 (\(customFoods.count))")
                                .font(AppTypography.subheadMedium)
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if customFoods.isEmpty {
                                Text("还没有添加任何食物")
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textTertiary)
                                    .padding(.vertical, AppSpacing.xl)
                            } else {
                                FlowLayout(spacing: AppSpacing.sm) {
                                    ForEach(customFoods, id: \.self) { food in
                                        HStack(spacing: AppSpacing.xs) {
                                            Text(food)
                                                .font(AppTypography.subhead)
                                            
                                            Button(action: { removeFood(food) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(AppColors.textTertiary)
                                            }
                                        }
                                        .padding(.horizontal, AppSpacing.md)
                                        .padding(.vertical, AppSpacing.sm)
                                        .background(AppColors.surface)
                                        .cornerRadius(AppRadius.full)
                                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                    .padding(.vertical, AppSpacing.xl)
                }
            }
            .navigationTitle("妈妈食谱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func addFood() {
        let trimmed = newFoodName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var foods = customFoods
        if !foods.contains(trimmed) {
            foods.append(trimmed)
            saveCustomFoods(foods)
        }
        newFoodName = ""
    }
    
    private func removeFood(_ food: String) {
        var foods = customFoods
        foods.removeAll { $0 == food }
        saveCustomFoods(foods)
    }
}

// MARK: - 统计 Tab 主视图
struct StatisticsTabView: View {
    @ObservedObject var recordManager: SleepRecordManager
    @ObservedObject var mealRecordManager: MealRecordManager
    @State private var statisticsMode: StatisticsMode = .sleep
    @AppStorage("fontSizeFactor") private var fontSizeFactor: Double = 1.0
    
    enum StatisticsMode: String, CaseIterable {
        case sleep = "睡眠"
        case meal = "饮食"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 类别选择器 (睡眠/饮食)
                        CustomSegmentedControl(selection: $statisticsMode)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.top, AppSpacing.md)
                        
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
            .navigationBarTitleDisplayMode(.large)
            .id(fontSizeFactor)
        }
    }
}

// MARK: - 成长 Tab 视图
struct GrowthTabView: View {
    @ObservedObject var milestoneManager: MilestoneManager
    @AppStorage("fontSizeFactor") private var fontSizeFactor: Double = 1.0
    
    var body: some View {
        MilestonesTabView(milestoneManager: milestoneManager)
            .id(fontSizeFactor)
    }
}

// 辅助组件：睡眠统计内联展示
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
        VStack(spacing: AppSpacing.lg) {
            // 周期选择器
            Picker("周期", selection: $selectedPeriod) {
                ForEach(PeriodType.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AppSpacing.lg)
            
            // 主要统计数据
            VStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.lg) {
                    // 平均睡眠时长
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
                        .frame(height: 50)
                    
                    // 睡眠次数
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
            .padding(.horizontal, AppSpacing.lg)
            
            // 趋势图表
            if !statistics.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("睡眠趋势")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, AppSpacing.lg)
                    
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
                    .frame(height: 150)
                    .padding(.horizontal, AppSpacing.lg)
                }
                .glassCard(padding: AppSpacing.md)
                .padding(.horizontal, AppSpacing.lg)
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

// 辅助组件：自定义分段选择器
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
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 辅助组件：睡眠页面的工具栏
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

// MARK: - 今日饮食概览卡片
struct TodaySummaryCard: View {
    let records: [MealRecord]
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("今日饮食")
                        .font(AppTypography.title2)
                        .foregroundStyle(AppColors.mealGradient)
                    
                    Text("\(records.count) 次记录")
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                IconCircle(
                    icon: "fork.knife",
                    size: 56,
                    iconSize: 26,
                    color: AppColors.meal,
                    filled: true,
                    gradient: AppColors.mealGradient
                )
            }
            
            if !records.isEmpty {
                Divider()
                
                // 餐次统计 - 使用更丰富的展示
                HStack(spacing: AppSpacing.lg) {
                    ForEach(MealType.allCases.prefix(4), id: \.self) { type in
                        let count = records.filter { $0.mealType == type }.count
                        if count > 0 {
                            VStack(spacing: 4) {
                                Text("\(count)")
                                    .font(AppTypography.title2)
                                    .foregroundColor(type.color)
                                Text(type.rawValue)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .frame(minWidth: 50)
                            .padding(.vertical, AppSpacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .fill(type.color.opacity(0.1))
                            )
                        }
                    }
                    Spacer()
                }
            }
        }
        .glassCard()
    }
}

// MARK: - 餐次筛选栏
struct MealFilterBar: View {
    @Binding var selectedType: MealType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                FilterChip(
                    title: "全部",
                    isSelected: selectedType == nil,
                    color: AppColors.meal
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedType = nil
                    }
                }
                
                ForEach(MealType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.rawValue,
                        isSelected: selectedType == type,
                        color: type.color
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedType = selectedType == type ? nil : type
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 饮食记录卡片
struct MealRecordCardView: View {
    let record: MealRecord
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            IconCircle(
                icon: record.mealType.icon,
                size: 48,
                iconSize: 22,
                color: record.mealType.color,
                filled: true
            )
            
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack {
                    Text(record.mealType.rawValue)
                        .font(AppTypography.bodySemibold)
                        .foregroundColor(AppColors.textPrimary)
                    
                    if !record.foodItems.isEmpty {
                        Text("・")
                            .foregroundColor(AppColors.textTertiary)
                        Text(record.foodItems.joined(separator: "、"))
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Text(record.formattedDate)
                    .font(AppTypography.footnote)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.relativeTime)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .fill(AppColors.surface)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
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
            // 睡眠指示器 - 使用新的呼吸动画
            ZStack {
                BreathingCircle(color: AppColors.sleep, size: 120)
                
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: AppColors.sleep.opacity(0.5), radius: 10, x: 0, y: 4)
            }
            .frame(height: 180)
            
            VStack(spacing: AppSpacing.xs) {
                Text(formatDuration(sleepDuration))
                    .font(AppTypography.timer)
                    .foregroundStyle(AppColors.sleepGradient)
                
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
                .buttonStyle(GradientButtonStyle(gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.accent.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )))
                
                Button(action: onWakeUpCustom) {
                    Text("选择其他时间")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.top, AppSpacing.sm)
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
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 清醒状态卡片
struct AwakeStatusCard: View {
    let onSleep: () -> Void
    let onSleepCustom: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            ZStack {
                // 光晕效果
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColors.awake.opacity(0.3), AppColors.awake.opacity(0)],
                            center: .center,
                            startRadius: 40,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                Circle()
                    .fill(AppColors.awakeGradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: AppColors.awake.opacity(0.4), radius: 20, x: 0, y: 10)
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            
            VStack(spacing: AppSpacing.xs) {
                Text("宝宝醒着")
                    .font(AppTypography.title1)
                    .foregroundStyle(AppColors.awakeGradient)
                
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
                .buttonStyle(GradientButtonStyle(gradient: AppColors.sleepGradient))
                
                Button(action: onSleepCustom) {
                    Text("选择其他时间")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.top, AppSpacing.sm)
        }
        .padding(.vertical, AppSpacing.xxl)
        .padding(.horizontal, AppSpacing.lg)
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
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
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
                    displayedComponents: [.hourAndMinute]
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

// MARK: - 快捷添加吃饭 Sheet
struct QuickAddMealSheet: View {
    @ObservedObject var mealRecordManager: MealRecordManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedMealType: MealType = .snack
    @State private var selectedFoods: Set<String> = []
    
    let commonFoods = [
        "米糊", "南瓜泥", "胡萝卜泥", "苹果泥", "香蕉泥",
        "土豆泥", "鸡蛋", "牛奶", "酸奶", "面条"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    // 餐次选择
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("选择餐次")
                            .font(AppTypography.calloutMedium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: AppSpacing.sm) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                QuickMealTypeButton(
                                    type: type,
                                    isSelected: selectedMealType == type,
                                    action: { selectedMealType = type }
                                )
                            }
                        }
                    }
                    
                    // 常用食物
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("常用食物")
                            .font(AppTypography.calloutMedium)
                            .foregroundColor(AppColors.textSecondary)
                        
                        FlowLayout(spacing: AppSpacing.xs) {
                            ForEach(commonFoods, id: \.self) { food in
                                FoodChipView(
                                    food: food,
                                    isSelected: selectedFoods.contains(food),
                                    action: {
                                        if selectedFoods.contains(food) {
                                            selectedFoods.remove(food)
                                        } else {
                                            selectedFoods.insert(food)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    // 保存按钮
                    Button(action: saveMeal) {
                        Text("保存")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: AppColors.meal))
                    .padding(.top, AppSpacing.lg)
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("添加饮食记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveMeal() {
        let newRecord = MealRecord(
            date: Date(),
            mealType: selectedMealType,
            foodItems: Array(selectedFoods),
            amount: "",
            notes: ""
        )
        mealRecordManager.addMealRecord(newRecord)
        dismiss()
    }
}

// MARK: - 餐次选择按钮
struct QuickMealTypeButton: View {
    let type: MealType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                Text(type.rawValue)
                    .font(AppTypography.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .foregroundColor(isSelected ? .white : AppColors.textPrimary)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(isSelected ? AppColors.meal : AppColors.surface)
            )
        }
    }
}

// MARK: - 食物选择 Chip
struct FoodChipView: View {
    let food: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(food)
                .font(AppTypography.footnote)
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.meal : AppColors.surfaceSecondary)
                )
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// Note: Removed duplicate StatisticsTabView and GrowthTabView definitions

// MARK: - 设置界面 (内联集成以解决构建作用域问题)
struct SettingsView: View {
    @AppStorage("fontSizeFactor") private var fontSizeFactor: Double = 1.0
    @AppStorage("cloudSyncEnabled") private var cloudSyncEnabled: Bool = true
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
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
                            .padding(AppSpacing.lg)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
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
                            .padding(AppSpacing.lg)
                            .frame(maxWidth: .infinity)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
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
                            .padding(AppSpacing.lg)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.lg)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        
                        // 说明
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
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - 饮食统计视图 (内联集成以解决构建作用域问题)
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
