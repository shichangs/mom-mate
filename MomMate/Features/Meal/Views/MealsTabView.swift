//
//  MealsTabView.swift
//  MomMate
//
//  Meal tab main view and related components
//  Extracted from MainTabView.swift for single responsibility
//

import SwiftUI

// MARK: - 饮食 Tab 主视图
struct MealsTabView: View {
    @ObservedObject var mealRecordManager: MealRecordManager
    @State private var showingAddMeal = false
    @State private var showingFoodList = false
    @State private var selectedMealType: MealType? = nil
    @AppStorage(StorageKeys.fontSizeFactor) private var fontSizeFactor: Double = 1.0

    var filteredRecords: [MealRecord] {
        if let type = selectedMealType {
            return mealRecordManager.mealRecordsByType(type)
        }
        return mealRecordManager.sortedMealRecords
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if mealRecordManager.mealRecords.isEmpty {
                    VStack(spacing: AppSpacing.lg) {
                        EmptyStateView(
                            icon: "fork.knife.circle",
                            title: "还没有饮食记录",
                            subtitle: "点击右上角添加宝宝的饮食",
                            color: AppColors.meal
                        )

                        FoodListEntryCard {
                            showingFoodList = true
                        }
                        .padding(.horizontal, AppSpacing.lg)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.xl) {
                            TodaySummaryCard(records: mealRecordManager.mealRecordsForToday())

                            FoodListEntryCard {
                                showingFoodList = true
                            }

                            MealFilterBar(selectedType: $selectedMealType)

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("饮食")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFoodList = true }) {
                        Image(systemName: "list.bullet.circle.fill")
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
            .sheet(isPresented: $showingFoodList) {
                FoodListView()
            }
            .id(fontSizeFactor)
        }
    }
}

// MARK: - 食物清单入口卡片
struct FoodListEntryCard: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                IconCircle(
                    icon: "list.bullet",
                    size: 38,
                    iconSize: 16,
                    color: AppColors.meal
                )

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("食物清单")
                        .font(AppTypography.calloutMedium)
                        .foregroundColor(AppColors.textPrimary)
                    Text("统一管理所有食物，支持删除和排序")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 食物目录存储
enum FoodCatalogStore {
    static let key = StorageKeys.foodCatalog
    static let legacyKey = StorageKeys.customFoods
    static let defaultFoods = [
        "米糊", "南瓜泥", "胡萝卜泥", "苹果泥", "香蕉泥",
        "土豆泥", "鸡蛋", "牛奶", "酸奶", "面条"
    ]

    static func load(from data: Data) -> [String] {
        if let decoded = try? JSONDecoder().decode([String].self, from: data), !decoded.isEmpty {
            return normalized(decoded)
        }

        let legacy = (UserDefaults.standard.data(forKey: legacyKey)).flatMap {
            try? JSONDecoder().decode([String].self, from: $0)
        } ?? []

        return normalized(defaultFoods + legacy)
    }

    static func save(_ foods: [String]) -> Data? {
        try? JSONEncoder().encode(normalized(foods))
    }

    private static func normalized(_ foods: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for item in foods {
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || seen.contains(trimmed) {
                continue
            }
            seen.insert(trimmed)
            result.append(trimmed)
        }
        return result
    }
}

// MARK: - 食物清单视图
struct FoodListView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage(FoodCatalogStore.key) private var foodCatalogData: Data = Data()
    @State private var newFoodName: String = ""
    @State private var foods: [String] = []

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("统一管理默认和自定义食物；支持删除和拖拽排序。")
                        .font(AppTypography.subhead)
                        .foregroundColor(AppColors.textSecondary)
                }

                Section("添加新食物") {
                    HStack {
                        TextField("食物名称", text: $newFoodName)
                        Button("添加", action: addFood)
                            .disabled(newFoodName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("食物列表 (\(foods.count))") {
                    ForEach(foods, id: \.self) { food in
                        Text(food)
                            .font(AppTypography.body)
                    }
                    .onDelete(perform: removeFoods)
                    .onMove(perform: moveFoods)
                }
            }
            .navigationTitle("食物清单")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                foods = FoodCatalogStore.load(from: foodCatalogData)
                persistFoods()
            }
        }
    }

    private func addFood() {
        let trimmed = newFoodName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !foods.contains(trimmed) {
            foods.append(trimmed)
            persistFoods()
        }
        newFoodName = ""
    }

    private func removeFoods(at offsets: IndexSet) {
        foods.remove(atOffsets: offsets)
        persistFoods()
    }

    private func moveFoods(from source: IndexSet, to destination: Int) {
        foods.move(fromOffsets: source, toOffset: destination)
        persistFoods()
    }

    private func persistFoods() {
        if let data = FoodCatalogStore.save(foods) {
            foodCatalogData = data
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
                        .foregroundColor(AppColors.meal)

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
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg)
                .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
        )
    }
}

// MARK: - 快捷添加吃饭 Sheet
struct QuickAddMealSheet: View {
    @ObservedObject var mealRecordManager: MealRecordManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedMealType: MealType = .snack
    @State private var selectedFoods: Set<String> = []
    @AppStorage(FoodCatalogStore.key) private var foodCatalogData: Data = Data()

    private var availableFoods: [String] {
        FoodCatalogStore.load(from: foodCatalogData)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
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

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("常用食物")
                            .font(AppTypography.calloutMedium)
                            .foregroundColor(AppColors.textSecondary)

                        FlowLayout(spacing: AppSpacing.xs) {
                            ForEach(availableFoods, id: \.self) { food in
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
                    Button("取消") { dismiss() }
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
