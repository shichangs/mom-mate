//
//  MealsTabView.swift
//  MomMate
//
//  Meal tab — 现代极简风格
//

import SwiftUI

// MARK: - 饮食 Tab 主视图
struct MealsTabView: View {
    @ObservedObject var mealRecordManager: MealRecordManager
    @StateObject private var foodCatalogManager = FoodCatalogManager()
    @State private var showingAddSheet = false
    @State private var showingFoodList = false
    @State private var selectedFilter: MealType?
    @State private var showFAB = true
    @AppStorage(StorageKeys.fontSizeFactor) private var fontSizeFactor: Double = 1.0

    private var filteredRecords: [MealRecord] {
        let sorted = mealRecordManager.sortedMealRecords
        if let filter = selectedFilter {
            return sorted.filter { $0.mealType == filter }
        }
        return sorted
    }

    private var todayRecords: [MealRecord] {
        mealRecordManager.mealRecordsForToday()
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 今日概览
                        MealDailySummary(records: todayRecords)

                        // 食物清单入口
                        FoodListEntryButton(onTap: { showingFoodList = true })

                        // 筛选栏
                        MealFilterBar(
                            selectedFilter: $selectedFilter,
                            mealRecordManager: mealRecordManager
                        )

                        // 记录列表
                        if filteredRecords.isEmpty {
                            EmptyStateView(
                                icon: "fork.knife",
                                title: "暂无记录",
                                subtitle: "点击右下角 + 添加饮食记录"
                            )
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(filteredRecords.enumerated()), id: \.element.id) { index, record in
                                    SwipeDeleteRow(onDelete: {
                                        withAnimation { mealRecordManager.deleteMealRecord(record) }
                                    }) {
                                        MealRecordRow(record: record)
                                    }

                                    if index < filteredRecords.count - 1 {
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
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, 100)
                }

                // Floating add button — scroll-aware
                if showFAB {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                HapticManager.light()
                                showingAddSheet = true
                            }) {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(FloatingButtonStyle(color: AppColors.meal))
                            .padding(.trailing, AppSpacing.xl)
                            .padding(.bottom, AppSpacing.lg)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            .navigationTitle("饮食")
            .navigationBarTitleDisplayMode(.inline)
            .id(fontSizeFactor)
            .sheet(isPresented: $showingAddSheet) {
                QuickAddMealSheet(
                    mealRecordManager: mealRecordManager,
                    foodCatalogManager: foodCatalogManager
                )
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppRadius.xxl)
            }
            .sheet(isPresented: $showingFoodList) {
                FoodListView(foodCatalogManager: foodCatalogManager)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppRadius.xxl)
            }
        }
    }
}

// MARK: - 今日饮食概览
struct MealDailySummary: View {
    let records: [MealRecord]

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppColors.meal)
                .frame(width: 3, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text("今日饮食")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)

                HStack(alignment: .lastTextBaseline, spacing: AppSpacing.xs) {
                    Text("\(records.count) 次记录")
                        .font(AppTypography.title2)
                        .foregroundColor(AppColors.textPrimary)
                }
            }

            Spacer()

            if !records.isEmpty {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(mealTypeSummary(), id: \.type) { item in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(item.color)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .background(
                    Capsule()
                        .fill(AppColors.surfaceSecondary)
                )
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.mealTint)
        .cornerRadius(AppRadius.lg)
    }

    private func mealTypeSummary() -> [(type: String, color: Color)] {
        var result: [(type: String, color: Color)] = []
        let types = Set(records.map { $0.mealType })
        for type in MealType.allCases where types.contains(type) {
            result.append((type: type.rawValue, color: type.color))
        }
        return result
    }
}

// MARK: - 食物清单入口
struct FoodListEntryButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.meal)

                VStack(alignment: .leading, spacing: 1) {
                    Text("妈妈食谱")
                        .font(AppTypography.calloutMedium)
                        .foregroundColor(AppColors.textPrimary)
                    Text("管理常用食材与辅食清单")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.lg)
        }
    }
}

// MARK: - 筛选栏
struct MealFilterBar: View {
    @Binding var selectedFilter: MealType?
    let mealRecordManager: MealRecordManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                FilterChip(
                    title: "全部",
                    count: mealRecordManager.mealRecords.count,
                    isSelected: selectedFilter == nil,
                    color: AppColors.primary
                ) {
                    withAnimation(AppAnimation.springSnappy) { selectedFilter = nil }
                }

                ForEach(MealType.allCases, id: \.self) { type in
                    let count = mealRecordManager.mealRecordsByType(type).count
                    FilterChip(
                        title: type.rawValue,
                        count: count,
                        isSelected: selectedFilter == type,
                        color: AppColors.meal
                    ) {
                        withAnimation(AppAnimation.springSnappy) {
                            selectedFilter = selectedFilter == type ? nil : type
                        }
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.xxs) {
                Text(title)
                if count > 0 {
                    Text("\(count)")
                        .foregroundColor(isSelected ? .white.opacity(0.7) : color.opacity(0.5))
                }
            }
            .font(AppTypography.footnoteMedium)
            .foregroundColor(isSelected ? .white : AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? color : AppColors.surfaceSecondary)
            )
        }
    }
}

// MARK: - 饮食记录行
struct MealRecordRow: View {
    let record: MealRecord

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 餐次小色块
            RoundedRectangle(cornerRadius: 3)
                .fill(record.mealType.color.opacity(0.6))
                .frame(width: 6, height: 28)
                .padding(.leading, 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xs) {
                    Text(record.mealType.rawValue)
                        .font(AppTypography.calloutMedium)
                        .foregroundColor(AppColors.textPrimary)

                    if !record.foodItems.isEmpty {
                        Text(record.foodItems.joined(separator: "、"))
                            .font(AppTypography.callout)
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                if !record.amount.isEmpty || !record.notes.isEmpty {
                    Text([record.amount, record.notes].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(relativeTimeString(record.date))
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
    }
    
    private func relativeTimeString(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小时前"
        } else if interval < 172800 {
            return "昨天"
        } else {
            return DateFormatters.monthDayZh.string(from: date)
        }
    }
}

// MARK: - 快捷添加饮食 Sheet
struct QuickAddMealSheet: View {
    @ObservedObject var mealRecordManager: MealRecordManager
    @ObservedObject var foodCatalogManager: FoodCatalogManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedType: MealType = .lunch
    @State private var selectedFoodIDs: Set<UUID> = []
    @State private var amount: String = ""
    @State private var notes: String = ""
    @State private var date = Date()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // 餐次选择
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("餐次")
                            .font(AppTypography.calloutMedium)
                            .foregroundColor(AppColors.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.xs) {
                                ForEach(MealType.allCases, id: \.self) { type in
                                    Button(action: {
                                        HapticManager.selection()
                                        withAnimation(AppAnimation.springBouncy) {
                                            selectedType = type
                                        }
                                    }) {
                                        VStack(spacing: AppSpacing.xxs) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 18, weight: .light))
                                            Text(type.rawValue)
                                                .font(AppTypography.caption)
                                        }
                                        .foregroundColor(selectedType == type ? .white : AppColors.textSecondary)
                                        .padding(.horizontal, AppSpacing.md)
                                        .padding(.vertical, AppSpacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppRadius.md)
                                                .fill(selectedType == type ? AppColors.meal : AppColors.surfaceSecondary)
                                        )
                                        .scaleEffect(selectedType == type ? 1.05 : 1.0)
                                    }
                                }
                            }
                        }
                    }

                    // 食材选择
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("食材")
                            .font(AppTypography.calloutMedium)
                            .foregroundColor(AppColors.textSecondary)

                        if foodCatalogManager.activeItems.isEmpty {
                            Text("暂无食材，请先在食谱中添加")
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textTertiary)
                        } else {
                            FlowLayout(spacing: AppSpacing.xs) {
                                ForEach(foodCatalogManager.activeItems) { food in
                                    let isSelected = selectedFoodIDs.contains(food.id)
                                    Button(action: {
                                        if isSelected {
                                            selectedFoodIDs.remove(food.id)
                                        } else {
                                            selectedFoodIDs.insert(food.id)
                                        }
                                    }) {
                                        Text(food.name)
                                            .font(AppTypography.footnoteMedium)
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
                        }
                    }

                    // 食量 & 备注
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("详情")
                            .font(AppTypography.calloutMedium)
                            .foregroundColor(AppColors.textSecondary)

                        TextField("食量（如：一碗、50ml）", text: $amount)
                            .font(AppTypography.body)
                            .padding(AppSpacing.sm)
                            .background(AppColors.surfaceSecondary)
                            .cornerRadius(AppRadius.md)

                        TextField("备注（可选）", text: $notes)
                            .font(AppTypography.body)
                            .padding(AppSpacing.sm)
                            .background(AppColors.surfaceSecondary)
                            .cornerRadius(AppRadius.md)
                    }

                    // 时间
                    DatePicker("时间", selection: $date, in: ...Date())
                        .font(AppTypography.body)

                    // 保存按钮
                    Button(action: save) {
                        Text("保存")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: AppColors.meal))
                    .disabled(selectedFoodIDs.isEmpty && amount.isEmpty)
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("添加饮食")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() {
        let selectedFoods = foodCatalogManager.activeItems
            .filter { selectedFoodIDs.contains($0.id) }
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.name)

        let record = MealRecord(
            date: date,
            mealType: selectedType,
            foodItems: selectedFoods,
            amount: amount,
            notes: notes
        )
        mealRecordManager.addMealRecord(record)
        dismiss()
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }

        return (size: CGSize(width: maxWidth, height: currentY + rowHeight), positions: positions)
    }
}

// MARK: - 食物清单视图
struct FoodListView: View {
    @ObservedObject var foodCatalogManager: FoodCatalogManager
    @Environment(\.dismiss) var dismiss
    @State private var newFoodName = ""

    private var canAddFood: Bool {
        !newFoodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 添加区域
                    HStack(spacing: AppSpacing.sm) {
                        TextField("添加食材名称", text: $newFoodName)
                            .font(AppTypography.body)
                            .padding(AppSpacing.sm)
                            .background(AppColors.surfaceSecondary)
                            .cornerRadius(AppRadius.md)

                        Button(action: addFood) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(canAddFood ? AppColors.meal : AppColors.textTertiary)
                        }
                        .disabled(!canAddFood)
                    }
                    .padding(AppSpacing.lg)

                    Divider()
                        .foregroundColor(AppColors.divider)

                    if foodCatalogManager.activeItems.isEmpty {
                        EmptyStateView(
                            icon: "carrot",
                            title: "暂无食材",
                            subtitle: "在上方输入框添加常用食材"
                        )
                    } else {
                        List {
                            ForEach(foodCatalogManager.activeItems) { food in
                                Text(food.name)
                                    .font(AppTypography.body)
                                    .foregroundColor(AppColors.textPrimary)
                                    .listRowBackground(AppColors.surface)
                            }
                            .onDelete { offsets in
                                foodCatalogManager.removeFoods(at: offsets)
                            }
                            .onMove { source, destination in
                                foodCatalogManager.moveFoods(from: source, to: destination)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("妈妈食谱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(AppColors.primary)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func addFood() {
        guard canAddFood else { return }
        foodCatalogManager.addFood(named: newFoodName)
        newFoodName = ""
    }
}
