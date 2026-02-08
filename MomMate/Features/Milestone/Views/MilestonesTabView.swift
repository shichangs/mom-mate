//
//  MilestonesTabView.swift
//  MomMate
//
//  Apple-inspired milestones view with timeline layout
//

import SwiftUI

private func milestoneCategoryColor(_ category: MilestoneCategory) -> Color {
    switch category.color {
    case "yellow": return Color(hex: "FFCC00")
    case "blue": return AppColors.primary
    case "purple": return AppColors.milestone
    case "pink": return Color(hex: "FF2D55")
    case "orange": return AppColors.warning
    case "indigo": return Color(hex: "5856D6")
    case "red": return AppColors.secondary
    default: return AppColors.textSecondary
    }
}

struct MilestonesTabView: View {
    @ObservedObject var milestoneManager: MilestoneManager
    @State private var showingAddMilestone = false
    @State private var editingMilestone: Milestone?
    @State private var selectedCategory: MilestoneCategory? = nil
    
    // 默认里程碑选项
    let quickMilestones: [(category: MilestoneCategory, title: String)] = [
        (.firstSmile, "第一次微笑"),
        (.firstRoll, "第一次翻身"),
        (.firstSit, "第一次坐"),
        (.firstCrawl, "第一次爬"),
        (.firstStand, "第一次站"),
        (.firstWalk, "第一次走"),
        (.firstWord, "第一次说话"),
        (.firstTooth, "第一颗牙")
    ]
    
    var filteredMilestones: [Milestone] {
        if let category = selectedCategory {
            return milestoneManager.milestonesByCategory(category)
        }
        return milestoneManager.sortedMilestones
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if milestoneManager.milestones.isEmpty {
                    // 空状态
                    ScrollView {
                        VStack(spacing: AppSpacing.xl) {
                            EmptyMilestoneView()
                                .padding(.top, AppSpacing.xxxl)
                            
                            // 快捷添加
                            QuickAddSection(
                                milestones: quickMilestones,
                                onAdd: addMilestone
                            )
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.bottom, AppSpacing.xxl)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: AppSpacing.xl) {
                            // 快捷添加卡片
                            QuickAddCard(
                                milestones: quickMilestones,
                                onAdd: addMilestone
                            )
                            
                            // 分类筛选
                            CategoryFilterBar(
                                selectedCategory: $selectedCategory
                            )
                            
                            // 里程碑时间线
                            MilestoneTimeline(
                                milestones: filteredMilestones,
                                onTap: { milestone in
                                    editingMilestone = milestone
                                },
                                onDelete: { milestone in
                                    milestoneManager.deleteMilestone(milestone)
                                }
                            )
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, AppSpacing.xxl)
                    }
                }
            }
            .navigationTitle("成长里程碑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("成长里程碑")
                        .font(AppTypography.title3)
                        .foregroundColor(AppColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMilestone = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.milestone)
                    }
                }
            }
            .sheet(isPresented: $showingAddMilestone) {
                AddMilestoneSheet(milestoneManager: milestoneManager)
            }
            .sheet(item: $editingMilestone) { milestone in
                EditMilestoneSheet(
                    milestone: milestone,
                    milestoneManager: milestoneManager
                )
            }
        }
    }
    
    private func addMilestone(_ category: MilestoneCategory, _ title: String) {
        let newMilestone = Milestone(
            date: Date(),
            title: title,
            description: "",
            category: category
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            milestoneManager.addMilestone(newMilestone)
        }
    }
}

// MARK: - 空状态视图
struct EmptyMilestoneView: View {
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.milestone.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(AppColors.milestone)
            }
            
            Text("记录宝宝的成长时刻")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Text("每一个里程碑都值得被记住")
                .font(AppTypography.subhead)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - 快捷添加区块
struct QuickAddSection: View {
    let milestones: [(category: MilestoneCategory, title: String)]
    let onAdd: (MilestoneCategory, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("快捷添加")
                .font(AppTypography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.sm) {
                ForEach(milestones, id: \.title) { item in
                    QuickMilestoneCard(
                        category: item.category,
                        title: item.title,
                        color: milestoneCategoryColor(item.category),
                        action: { onAdd(item.category, item.title) }
                    )
                }
            }
        }
    }
}

// MARK: - 快捷里程碑卡片
struct QuickMilestoneCard: View {
    let category: MilestoneCategory
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(color.opacity(0.14))
                        .frame(width: 34, height: 34)
                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(AppTypography.subheadMedium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
            )
        }
    }
}

// MARK: - 快捷添加卡片 (有记录时)
struct QuickAddCard: View {
    let milestones: [(category: MilestoneCategory, title: String)]
    let onAdd: (MilestoneCategory, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("快捷添加")
                .font(AppTypography.calloutMedium)
                .foregroundColor(AppColors.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(milestones, id: \.title) { item in
                        Button(action: { onAdd(item.category, item.title) }) {
                            HStack(spacing: AppSpacing.xs) {
                                ZStack {
                                    Circle()
                                        .fill(milestoneCategoryColor(item.category).opacity(0.14))
                                        .frame(width: 22, height: 22)
                                    Image(systemName: item.category.icon)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(milestoneCategoryColor(item.category))
                                }
                                Text(item.title)
                                    .font(AppTypography.footnote)
                            }
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(AppColors.surface)
                            .cornerRadius(AppRadius.full)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.full)
                                    .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 分类筛选栏
struct CategoryFilterBar: View {
    @Binding var selectedCategory: MilestoneCategory?
    
    let categories: [MilestoneCategory] = MilestoneCategory.allCases
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                // All 按钮
                FilterChip(
                    title: "全部",
                    isSelected: selectedCategory == nil,
                    color: AppColors.primary
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                }
                
                ForEach(categories, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        color: milestoneCategoryColor(category)
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 筛选 Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.footnoteMedium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.12))
                )
        }
    }
}

// MARK: - 里程碑时间线
struct MilestoneTimeline: View {
    let milestones: [Milestone]
    let onTap: (Milestone) -> Void
    let onDelete: (Milestone) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                MilestoneTimelineItem(
                    milestone: milestone,
                    isLast: index == milestones.count - 1,
                    onTap: { onTap(milestone) }
                )
                .contextMenu {
                    Button(role: .destructive) {
                        onDelete(milestone)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
    }
}

// MARK: - 时间线项
struct MilestoneTimelineItem: View {
    let milestone: Milestone
    let isLast: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            // 时间线
            VStack(spacing: 0) {
                Circle()
                    .fill(milestoneCategoryColor(milestone.category))
                    .frame(width: 12, height: 12)
                
                if !isLast {
                    Rectangle()
                        .fill(AppColors.textTertiary.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)
            
            // 内容卡片
            Button(action: onTap) {
                HStack(spacing: AppSpacing.md) {
                    IconCircle(
                        icon: milestone.category.icon,
                        size: 44,
                        iconSize: 20,
                        color: milestoneCategoryColor(milestone.category)
                    )
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(milestone.title)
                            .font(AppTypography.calloutMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(milestone.relativeDate)
                            .font(AppTypography.footnote)
                            .foregroundColor(AppColors.textSecondary)
                        
                        if !milestone.description.isEmpty {
                            Text(milestone.description)
                                .font(AppTypography.footnote)
                                .foregroundColor(AppColors.textTertiary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .cornerRadius(AppRadius.lg)
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, isLast ? 0 : AppSpacing.md)
    }
}

// MARK: - 添加里程碑 Sheet
struct AddMilestoneSheet: View {
    @ObservedObject var milestoneManager: MilestoneManager
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: MilestoneCategory = .firstSmile
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("里程碑标题", text: $title)
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(MilestoneCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
                
                Section("备注") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("添加里程碑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveMilestone()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveMilestone() {
        let milestone = Milestone(
            date: date,
            title: title,
            description: description,
            category: selectedCategory
        )
        milestoneManager.addMilestone(milestone)
        dismiss()
    }
}

// MARK: - 编辑里程碑 Sheet
struct EditMilestoneSheet: View {
    let milestone: Milestone
    @ObservedObject var milestoneManager: MilestoneManager
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var selectedCategory: MilestoneCategory
    @State private var date: Date
    
    init(milestone: Milestone, milestoneManager: MilestoneManager) {
        self.milestone = milestone
        self.milestoneManager = milestoneManager
        _title = State(initialValue: milestone.title)
        _description = State(initialValue: milestone.description)
        _selectedCategory = State(initialValue: milestone.category)
        _date = State(initialValue: milestone.date)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("里程碑标题", text: $title)
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(MilestoneCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
                
                Section("备注") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(role: .destructive) {
                        milestoneManager.deleteMilestone(milestone)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("删除里程碑")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑里程碑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        updateMilestone()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func updateMilestone() {
        var updatedMilestone = milestone
        updatedMilestone.title = title
        updatedMilestone.description = description
        updatedMilestone.category = selectedCategory
        updatedMilestone.date = date
        milestoneManager.updateMilestone(updatedMilestone)
        dismiss()
    }
}
