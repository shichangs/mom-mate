//
//  MealRecordsView.swift
//  MomMate
//
//  Meal records view
//

import SwiftUI

@available(*, deprecated, message: "Use MealsTabView in MainTabView.swift")
struct MealRecordsView: View {
    @ObservedObject var mealRecordManager: MealRecordManager
    @Environment(\.dismiss) var dismiss
    @State private var showingAddMeal = false
    @State private var editingMeal: MealRecord?
    @State private var selectedMealType: MealType? = nil
    @State private var showingRecommendations = false
    @State private var babyAge: Int = 6 // 默认6个月
    
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
                    EmptyMealRecordsView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 今日记录预览
                            if !mealRecordManager.mealRecordsForToday().isEmpty {
                                TodayMealsView(records: mealRecordManager.mealRecordsForToday())
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                            }
                            
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
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

// MARK: - 空状态视图
struct EmptyMealRecordsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("还没有吃饭记录")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text("点击右上角的 + 按钮\n记录宝宝的吃饭情况")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 今日记录视图
struct TodayMealsView: View {
    let records: [MealRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日记录")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text("\(records.count)次")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            ForEach(records) { record in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(record.mealType.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: record.mealType.icon)
                            .foregroundColor(record.mealType.color)
                            .font(.system(size: 18))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.mealType.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                        if !record.foodItems.isEmpty {
                            Text(record.foodItems.joined(separator: "、"))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Text(record.formattedTime)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - 类型筛选视图
struct MealTypeFilterView: View {
    @Binding var selectedMealType: MealType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部
                MealTypeChip(
                    title: "全部",
                    icon: "list.bullet",
                    isSelected: selectedMealType == nil
                ) {
                    selectedMealType = nil
                }
                
                // 各个类型
                ForEach(MealType.allCases, id: \.self) { type in
                    MealTypeChip(
                        title: type.rawValue,
                        icon: type.icon,
                        isSelected: selectedMealType == type,
                        color: type.color
                    ) {
                        selectedMealType = selectedMealType == type ? nil : type
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - 类型标签
struct MealTypeChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var color: Color = Color(red: 1.0, green: 0.6, blue: 0.3)
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? color : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - 记录卡片
struct MealRecordCard: View {
    let record: MealRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(record.mealType.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: record.mealType.icon)
                        .font(.system(size: 22))
                        .foregroundColor(record.mealType.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.mealType.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(record.formattedDate)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(record.relativeTime)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            if !record.foodItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("食物：")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(record.foodItems.joined(separator: "、"))
                        .font(.system(size: 16))
                }
            }
            
            if !record.amount.isEmpty {
                HStack {
                    Text("食量：")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(record.amount)
                        .font(.system(size: 16))
                }
            }
            
            if !record.notes.isEmpty {
                Text(record.notes)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - 添加/编辑记录视图
struct AddEditMealRecordView: View {
    @ObservedObject var mealRecordManager: MealRecordManager
    @Environment(\.dismiss) var dismiss
    
    let mealRecord: MealRecord?
    
    @State private var date: Date
    @State private var mealType: MealType
    @State private var foodItems: [String]
    @State private var foodItemText: String
    @State private var amount: String
    @State private var notes: String
    
    init(mealRecordManager: MealRecordManager, mealRecord: MealRecord? = nil) {
        self.mealRecordManager = mealRecordManager
        self.mealRecord = mealRecord
        
        if let mealRecord = mealRecord {
            _date = State(initialValue: mealRecord.date)
            _mealType = State(initialValue: mealRecord.mealType)
            _foodItems = State(initialValue: mealRecord.foodItems)
            _foodItemText = State(initialValue: mealRecord.foodItems.joined(separator: "、"))
            _amount = State(initialValue: mealRecord.amount)
            _notes = State(initialValue: mealRecord.notes)
        } else {
            _date = State(initialValue: Date())
            _mealType = State(initialValue: .breakfast)
            _foodItems = State(initialValue: [])
            _foodItemText = State(initialValue: "")
            _amount = State(initialValue: "")
            _notes = State(initialValue: "")
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.95, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        DatePicker("时间", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                    } header: {
                        Label("时间", systemImage: "clock")
                    }
                    
                    Section {
                        Picker("类型", selection: $mealType) {
                            ForEach(MealType.allCases, id: \.self) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.rawValue)
                                }
                                .tag(type)
                            }
                        }
                    } header: {
                        Label("餐次", systemImage: "fork.knife")
                    }
                    
                    Section {
                        TextField("食物（用、分隔）", text: $foodItemText)
                            .onChange(of: foodItemText) { newValue in
                                foodItems = newValue.split(separator: "、").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                            }
                    } header: {
                        Label("食物", systemImage: "leaf.fill")
                    } footer: {
                        Text("多个食物用顿号（、）分隔")
                    }
                    
                    Section {
                        TextField("食量（如：半碗、100ml）", text: $amount)
                    } header: {
                        Label("食量", systemImage: "gauge")
                    }
                    
                    Section {
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                    } header: {
                        Label("备注", systemImage: "note.text")
                    }
                    
                    Section {
                        Button(action: {
                            if let existingRecord = mealRecord {
                                let updated = MealRecord(
                                    id: existingRecord.id,
                                    date: date,
                                    mealType: mealType,
                                    foodItems: foodItems,
                                    amount: amount,
                                    notes: notes
                                )
                                mealRecordManager.updateMealRecord(updated)
                            } else {
                                let newRecord = MealRecord(
                                    date: date,
                                    mealType: mealType,
                                    foodItems: foodItems,
                                    amount: amount,
                                    notes: notes
                                )
                                mealRecordManager.addMealRecord(newRecord)
                            }
                            dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text(mealRecord == nil ? "添加" : "保存")
                                    .font(.system(size: 17, weight: .semibold))
                                Spacer()
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(mealRecord == nil ? "添加记录" : "编辑记录")
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
}

// MARK: - 辅食推荐视图
struct FoodRecommendationsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var babyAge: Int
    
    var recommendations: [FoodRecommendation] {
        FoodRecommendation.recommendationsForAge(babyAge)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.95, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 年龄选择
                        VStack(alignment: .leading, spacing: 12) {
                            Text("宝宝月龄")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Picker("月龄", selection: $babyAge) {
                                ForEach(4...24, id: \.self) { age in
                                    Text("\(age)个月").tag(age)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 150)
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        
                        // 推荐列表
                        ForEach(recommendations, id: \.age) { recommendation in
                            RecommendationCard(recommendation: recommendation)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("辅食推荐")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 推荐卡片
struct RecommendationCard: View {
    let recommendation: FoodRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(recommendation.age)个月")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.3))
                
                Text(recommendation.category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(red: 1.0, green: 0.6, blue: 0.3).opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("推荐食物")
                    .font(.system(size: 16, weight: .semibold))
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(recommendation.foods, id: \.self) { food in
                        Text(food)
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(red: 1.0, green: 0.6, blue: 0.3).opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            if !recommendation.tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("温馨提示")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(recommendation.tips)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(12)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
