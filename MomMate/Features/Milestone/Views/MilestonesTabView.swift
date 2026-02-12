//
//  MilestonesTabView.swift
//  MomMate
//
//  Growth/Milestones tab — 现代极简风格
//

import SwiftUI

struct MilestonesTabView: View {
    @ObservedObject var milestoneManager: MilestoneManager
    @State private var showingAddSheet = false
    @State private var selectedCategory: MilestoneCategory?
    @State private var editingMilestone: Milestone?
    @AppStorage(StorageKeys.fontSizeFactor) private var fontSizeFactor: Double = 1.0

    private var filteredMilestones: [Milestone] {
        let sorted = milestoneManager.sortedMilestones
        if let category = selectedCategory {
            return sorted.filter { $0.category == category }
        }
        return sorted
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        // 快捷添加
                        QuickMilestoneRow(milestoneManager: milestoneManager)

                        // 分类筛选
                        MilestoneCategoryFilter(
                            selectedCategory: $selectedCategory,
                            milestones: milestoneManager.milestones
                        )

                        // 时间线
                        if filteredMilestones.isEmpty {
                            VStack(spacing: AppSpacing.lg) {
                                let totalKey = MilestoneCategory.allCases.count
                                let recorded = Set(milestoneManager.milestones.map { $0.category }).count
                                ProgressRing(
                                    progress: Double(recorded) / Double(totalKey),
                                    color: AppColors.milestone,
                                    lineWidth: 4,
                                    size: 80
                                )
                                Text("已解锁 \(recorded)/\(totalKey) 类里程碑")
                                    .font(AppTypography.calloutMedium)
                                    .foregroundColor(AppColors.textSecondary)
                                Text("记录宝宝的每一个重要时刻")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.xxl)
                        } else {
                            MilestoneTimelineView(
                                milestones: filteredMilestones,
                                milestoneManager: milestoneManager,
                                onEdit: { milestone in editingMilestone = milestone }
                            )
                        }
                    }
                    .padding(.horizontal, AppSpacing.lg)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, 100)
                }

                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(FloatingButtonStyle(color: AppColors.milestone))
                        .padding(.trailing, AppSpacing.xl)
                        .padding(.bottom, AppSpacing.lg)
                    }
                }
            }
            .navigationTitle("成长")
            .navigationBarTitleDisplayMode(.inline)
            .id(fontSizeFactor)
            .sheet(isPresented: $showingAddSheet) {
                AddMilestoneSheet(milestoneManager: milestoneManager)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppRadius.xxl)
            }
            .sheet(item: $editingMilestone) { milestone in
                EditMilestoneSheet(milestone: milestone, milestoneManager: milestoneManager)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(AppRadius.xxl)
            }
        }
    }
}

// MARK: - 快捷添加行
struct QuickMilestoneRow: View {
    @ObservedObject var milestoneManager: MilestoneManager

    private let quickOptions: [(title: String, category: MilestoneCategory)] = [
        ("翻身", .firstRoll),
        ("坐稳", .firstSit),
        ("爬行", .firstCrawl),
        ("站立", .firstStand),
        ("说话", .firstWord),
        ("微笑", .firstSmile),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(quickOptions, id: \.title) { option in
                    Button(action: {
                        HapticManager.success()
                        withAnimation(AppAnimation.springBouncy) {
                            let milestone = Milestone(
                                date: Date(),
                                title: option.title,
                                category: option.category
                            )
                            milestoneManager.addMilestone(milestone)
                        }
                    }) {
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: option.category.icon)
                                .font(.system(size: 12, weight: .medium))
                            Text(option.title)
                        }
                        .font(AppTypography.footnoteMedium)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(
                            Capsule()
                                .fill(AppColors.surfaceSecondary)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - 分类筛选
struct MilestoneCategoryFilter: View {
    @Binding var selectedCategory: MilestoneCategory?
    let milestones: [Milestone]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                FilterChip(
                    title: "全部",
                    count: milestones.count,
                    isSelected: selectedCategory == nil,
                    color: AppColors.milestone
                ) {
                    withAnimation(AppAnimation.springSnappy) { selectedCategory = nil }
                }

                ForEach(MilestoneCategory.allCases, id: \.self) { category in
                    let count = milestones.filter { $0.category == category }.count
                    if count > 0 {
                        FilterChip(
                            title: category.rawValue,
                            count: count,
                            isSelected: selectedCategory == category,
                            color: Color(category.color)
                        ) {
                            withAnimation(AppAnimation.springSnappy) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 时间线
struct MilestoneTimelineView: View {
    let milestones: [Milestone]
    let milestoneManager: MilestoneManager
    let onEdit: (Milestone) -> Void
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 1.0

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    // 时间线竖线 + 圆点
                    VStack(spacing: 0) {
                        if index > 0 {
                            Rectangle()
                                .fill(AppColors.border)
                                .frame(width: 1, height: 16)
                        } else {
                            Spacer()
                                .frame(height: 16)
                        }

                        Circle()
                            .fill(Color(milestone.category.color))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == 0 ? pulseScale : 1.0)
                            .opacity(index == 0 ? pulseOpacity : 1.0)

                        if index < milestones.count - 1 {
                            Rectangle()
                                .fill(AppColors.border)
                                .frame(width: 1)
                        }
                    }
                    .frame(width: 8)

                    // 内容
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        HStack {
                            Text(milestone.title)
                                .font(AppTypography.calloutMedium)
                                .foregroundColor(AppColors.textPrimary)

                            Spacer()

                            Text(milestone.relativeDate)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }

                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: milestone.category.icon)
                                .font(.system(size: 10, weight: .medium))
                            Text(milestone.category.rawValue)
                                .font(AppTypography.caption)
                                .foregroundColor(Color(milestone.category.color))

                            if !milestone.description.isEmpty {
                                Text("·")
                                    .foregroundColor(AppColors.textTertiary)
                                Text(milestone.description)
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.sm)
                    .contentShape(Rectangle())
                    .onTapGesture { onEdit(milestone) }
                    .contextMenu {
                        Button(role: .destructive) {
                            milestoneManager.deleteMilestone(milestone)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.4
                pulseOpacity = 0.5
            }
        }
    }
}

// MARK: - 添加里程碑 Sheet
struct AddMilestoneSheet: View {
    @ObservedObject var milestoneManager: MilestoneManager
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var selectedCategory: MilestoneCategory = .other
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    TextField("里程碑名称", text: $title)
                        .font(AppTypography.title2)
                        .padding(AppSpacing.sm)

                    // 分类选择
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("分类")
                            .font(AppTypography.calloutMedium)
                            .foregroundColor(AppColors.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.xs) {
                                ForEach(MilestoneCategory.allCases, id: \.self) { category in
                                    Button(action: { selectedCategory = category }) {
                                        HStack(spacing: AppSpacing.xxs) {
                                            Image(systemName: category.icon)
                                                .font(.system(size: 14, weight: .medium))
                                            Text(category.rawValue)
                                        }
                                        .font(AppTypography.footnoteMedium)
                                        .foregroundColor(selectedCategory == category ? .white : Color(category.color))
                                        .padding(.horizontal, AppSpacing.sm)
                                        .padding(.vertical, AppSpacing.xs)
                                        .background(
                                            Capsule()
                                                .fill(selectedCategory == category ? Color(category.color) : Color(category.color).opacity(0.08))
                                        )
                                    }
                                }
                            }
                        }
                    }

                    DatePicker("日期", selection: $date, in: ...Date(), displayedComponents: .date)
                        .font(AppTypography.body)

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("备注")
                            .font(AppTypography.calloutMedium)
                            .foregroundColor(AppColors.textSecondary)

                        TextField("可选备注", text: $notes, axis: .vertical)
                            .font(AppTypography.body)
                            .lineLimit(3...6)
                            .padding(AppSpacing.sm)
                            .background(AppColors.surfaceSecondary)
                            .cornerRadius(AppRadius.md)
                    }

                    Button(action: save) {
                        Text("保存")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: AppColors.milestone))
                    .disabled(title.isEmpty)
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("新里程碑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private func save() {
        let milestone = Milestone(
            date: date,
            title: title,
            description: notes,
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
    @State private var selectedCategory: MilestoneCategory
    @State private var date: Date
    @State private var notes: String

    init(milestone: Milestone, milestoneManager: MilestoneManager) {
        self.milestone = milestone
        self.milestoneManager = milestoneManager
        _title = State(initialValue: milestone.title)
        _selectedCategory = State(initialValue: milestone.category)
        _date = State(initialValue: milestone.date)
        _notes = State(initialValue: milestone.description)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    TextField("里程碑名称", text: $title)
                        .font(AppTypography.title2)
                        .padding(AppSpacing.sm)

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("分类")
                            .font(AppTypography.calloutMedium)
                            .foregroundColor(AppColors.textSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppSpacing.xs) {
                                ForEach(MilestoneCategory.allCases, id: \.self) { category in
                                    Button(action: { selectedCategory = category }) {
                                        HStack(spacing: AppSpacing.xxs) {
                                            Image(systemName: category.icon)
                                                .font(.system(size: 14, weight: .medium))
                                            Text(category.rawValue)
                                        }
                                        .font(AppTypography.footnoteMedium)
                                        .foregroundColor(selectedCategory == category ? .white : Color(category.color))
                                        .padding(.horizontal, AppSpacing.sm)
                                        .padding(.vertical, AppSpacing.xs)
                                        .background(
                                            Capsule()
                                                .fill(selectedCategory == category ? Color(category.color) : Color(category.color).opacity(0.08))
                                        )
                                    }
                                }
                            }
                        }
                    }

                    DatePicker("日期", selection: $date, in: ...Date(), displayedComponents: .date)
                        .font(AppTypography.body)

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("备注")
                            .font(AppTypography.calloutMedium)
                            .foregroundColor(AppColors.textSecondary)

                        TextField("可选备注", text: $notes, axis: .vertical)
                            .font(AppTypography.body)
                            .lineLimit(3...6)
                            .padding(AppSpacing.sm)
                            .background(AppColors.surfaceSecondary)
                            .cornerRadius(AppRadius.md)
                    }

                    Button(action: save) {
                        Text("保存")
                    }
                    .buttonStyle(PrimaryButtonStyle(color: AppColors.milestone))
                    .disabled(title.isEmpty)

                    Button(role: .destructive) {
                        milestoneManager.deleteMilestone(milestone)
                        dismiss()
                    } label: {
                        Text("删除此里程碑")
                            .font(AppTypography.footnote)
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private func save() {
        var updated = milestone
        updated.title = title
        updated.category = selectedCategory
        updated.date = date
        updated.description = notes
        milestoneManager.updateMilestone(updated)
        dismiss()
    }
}
