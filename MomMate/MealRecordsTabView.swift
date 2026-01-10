//
//  MealRecordsTabView.swift
//  MomMate
//
//  Meal records tab view with quick actions
//

import SwiftUI

struct MealRecordsTabView: View {
    @ObservedObject var mealRecordManager: MealRecordManager
    @State private var showingAddMeal = false
    @State private var editingMeal: MealRecord?
    @State private var selectedMealType: MealType? = nil
    @State private var showingRecommendations = false
    @State private var babyAge: Int = 6
    
    // 默认食物选项
    let defaultFoods: [String] = [
        "米糊", "南瓜泥", "胡萝卜泥", "苹果泥", "香蕉泥",
        "土豆泥", "红薯泥", "梨泥", "牛油果泥", "菠菜泥",
        "蛋黄", "豆腐", "鸡肉泥", "鱼肉泥", "西兰花泥"
    ]
    
    var filteredMealRecords: [MealRecord] {
        if let mealType = selectedMealType {
            return mealRecordManager.mealRecordsByType(mealType)
        }
        return mealRecordManager.sortedMealRecords
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color(red: 0.95, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                if mealRecordManager.mealRecords.isEmpty {
                    EmptyMealRecordsViewWithQuickActions(
                        mealRecordManager: mealRecordManager,
                        defaultFoods: defaultFoods
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 今日记录预览
                            if !mealRecordManager.mealRecordsForToday().isEmpty {
                                TodayMealsView(records: mealRecordManager.mealRecordsForToday())
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                            }
                            
                            // 快捷添加卡片
                            QuickAddMealCard(
                                defaultFoods: defaultFoods,
                                onSelect: { mealType, food in
                                    let newRecord = MealRecord(
                                        date: Date(),
                                        mealType: mealType,
                                        foodItems: [food],
                                        amount: "",
                                        notes: ""
                                    )
                                    mealRecordManager.addMealRecord(newRecord)
                                }
                            )
                            .padding(.horizontal, 20)
                            
                            // 辅食推荐按钮
                            Button(action: {
                                showingRecommendations = true
                            }) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text("查看辅食推荐")
                                        .font(.system(size: 16, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.primary)
                                .padding(16)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.yellow.opacity(0.2),
                                            Color.orange.opacity(0.1)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            
                            // 类型筛选
                            MealTypeFilterView(selectedMealType: $selectedMealType)
                                .padding(.horizontal, 20)
                            
                            // 记录列表
                            LazyVStack(spacing: 16) {
                                ForEach(filteredMealRecords) { record in
                                    MealRecordCard(record: record)
                                        .onTapGesture {
                                            editingMeal = record
                                        }
                                        .contextMenu {
                                            Button(role: .destructive, action: {
                                                mealRecordManager.deleteMealRecord(record)
                                            }) {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("吃饭记录")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMeal = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.3))
                    }
                }
            }
            .sheet(isPresented: $showingAddMeal) {
                AddEditMealRecordView(mealRecordManager: mealRecordManager)
            }
            .sheet(item: $editingMeal) { meal in
                AddEditMealRecordView(mealRecordManager: mealRecordManager, mealRecord: meal)
            }
            .sheet(isPresented: $showingRecommendations) {
                FoodRecommendationsView(babyAge: $babyAge)
            }
        }
    }
}

// MARK: - 空状态视图（带快捷操作）
struct EmptyMealRecordsViewWithQuickActions: View {
    @ObservedObject var mealRecordManager: MealRecordManager
    let defaultFoods: [String]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.secondary)
                    
                    Text("还没有吃饭记录")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text("点击下方快捷选项快速添加")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                
                // 快捷添加选项
                VStack(alignment: .leading, spacing: 16) {
                    Text("快捷添加")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.horizontal, 20)
                    
                    // 餐次选择
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(MealType.allCases, id: \.self) { mealType in
                                MealTypeQuickButton(mealType: mealType) {
                                    let newRecord = MealRecord(
                                        date: Date(),
                                        mealType: mealType,
                                        foodItems: [],
                                        amount: "",
                                        notes: ""
                                    )
                                    mealRecordManager.addMealRecord(newRecord)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 常用食物
                    VStack(alignment: .leading, spacing: 12) {
                        Text("常用食物")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 10) {
                            ForEach(defaultFoods, id: \.self) { food in
                                FoodQuickButton(food: food) {
                                    let newRecord = MealRecord(
                                        date: Date(),
                                        mealType: .snack,
                                        foodItems: [food],
                                        amount: "",
                                        notes: ""
                                    )
                                    mealRecordManager.addMealRecord(newRecord)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - 快捷添加卡片
struct QuickAddMealCard: View {
    let defaultFoods: [String]
    let onSelect: (MealType, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.3))
                Text("快捷添加")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
            }
            
            // 餐次快捷按钮
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MealType.allCases, id: \.self) { mealType in
                        MealTypeQuickButton(mealType: mealType) {
                            onSelect(mealType, "")
                        }
                    }
                }
            }
            
            // 常用食物
            VStack(alignment: .leading, spacing: 8) {
                Text("常用食物")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(defaultFoods.prefix(8), id: \.self) { food in
                            FoodQuickButton(food: food) {
                                onSelect(.snack, food)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - 餐次快捷按钮
struct MealTypeQuickButton: View {
    let mealType: MealType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: mealType.icon)
                    .font(.system(size: 16))
                Text(mealType.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(mealType.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(mealType.color.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

// MARK: - 食物快捷按钮
struct FoodQuickButton: View {
    let food: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(food)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.3))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 1.0, green: 0.6, blue: 0.3).opacity(0.1))
                .cornerRadius(16)
        }
    }
}

