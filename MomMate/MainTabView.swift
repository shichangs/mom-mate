//
//  MainTabView.swift
//  MomMate
//
//  4-tab navigation with Apple-inspired design
//

import SwiftUI

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
            StatisticsTabView(recordManager: recordManager)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNotes = true }) {
                        Image(systemName: "doc.text")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView(recordManager: recordManager)
            }
            .sheet(isPresented: $showingNotes) {
                NotesView(notesManager: notesManager)
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
    @State private var selectedMealType: MealType? = nil
    
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
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("\(records.count) 次记录")
                        .font(AppTypography.callout)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                IconCircle(
                    icon: "fork.knife",
                    size: 50,
                    iconSize: 22,
                    color: AppColors.meal
                )
            }
            
            if !records.isEmpty {
                Divider()
                
                // 餐次统计
                HStack(spacing: AppSpacing.lg) {
                    ForEach(MealType.allCases.prefix(4), id: \.self) { type in
                        let count = records.filter { $0.mealType == type }.count
                        if count > 0 {
                            VStack(spacing: 2) {
                                Text("\(count)")
                                    .font(AppTypography.title3)
                                    .foregroundColor(type.color)
                                Text(type.rawValue)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
        .cardStyle()
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
                size: 44,
                iconSize: 20,
                color: record.mealType.color
            )
            
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                HStack {
                    Text(record.mealType.rawValue)
                        .font(AppTypography.calloutMedium)
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
            
            Text(record.relativeTime)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.lg)
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
            // 睡眠指示器
            ZStack {
                PulsingCircle(color: AppColors.sleep)
                    .frame(width: 140, height: 140)
                
                PulsingCircle(color: AppColors.sleep)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(AppColors.sleepGradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: AppColors.sleep.opacity(0.4), radius: 20, x: 0, y: 10)
                
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(height: 140)
            
            VStack(spacing: AppSpacing.xs) {
                Text(formatDuration(sleepDuration))
                    .font(AppTypography.display)
                    .foregroundColor(AppColors.textPrimary)
                
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
        .cardStyle(padding: 0)
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
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            ZStack {
                Circle()
                    .fill(AppColors.awakeGradient)
                    .frame(width: 100, height: 100)
                    .shadow(color: AppColors.awake.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: AppSpacing.xs) {
                Text("宝宝醒着")
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.textPrimary)
                
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
        .cardStyle(padding: 0)
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

// MARK: - 统计 Tab 视图
struct StatisticsTabView: View {
    @ObservedObject var recordManager: SleepRecordManager
    
    var body: some View {
        StatisticsView(recordManager: recordManager)
    }
}

// MARK: - 成长 Tab 视图
struct GrowthTabView: View {
    @ObservedObject var milestoneManager: MilestoneManager
    
    var body: some View {
        MilestonesTabView(milestoneManager: milestoneManager)
    }
}
