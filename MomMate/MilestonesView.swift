//
//  MilestonesView.swift
//  MomMate
//
//  Milestones view
//

import SwiftUI

@available(*, deprecated, message: "Use MilestonesTabView in MilestonesTabView.swift")
struct MilestonesView: View {
    @ObservedObject var milestoneManager: MilestoneManager
    @Environment(\.dismiss) var dismiss
    @State private var showingAddMilestone = false
    @State private var editingMilestone: Milestone?
    @State private var selectedCategory: MilestoneCategory? = nil
    
    var filteredMilestones: [Milestone] {
        if let category = selectedCategory {
            return milestoneManager.milestonesByCategory(category)
        }
        return milestoneManager.sortedMilestones
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color(red: 0.95, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                if milestoneManager.milestones.isEmpty {
                    EmptyMilestonesView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 分类筛选
                            CategoryFilterView(selectedCategory: $selectedCategory)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                            
                            // 里程碑列表
                            LazyVStack(spacing: 16) {
                                ForEach(filteredMilestones) { milestone in
                                    MilestoneCard(milestone: milestone)
                                        .onTapGesture {
                                            editingMilestone = milestone
                                        }
                                        .contextMenu {
                                            Button(role: .destructive, action: {
                                                milestoneManager.deleteMilestone(milestone)
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
            .navigationTitle("成长里程碑")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMilestone = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    }
                }
            }
            .sheet(isPresented: $showingAddMilestone) {
                AddEditMilestoneView(milestoneManager: milestoneManager)
            }
            .sheet(item: $editingMilestone) { milestone in
                AddEditMilestoneView(milestoneManager: milestoneManager, milestone: milestone)
            }
        }
    }
}

// MARK: - 空状态视图
struct EmptyMilestonesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("还没有里程碑")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text("点击右上角的 + 按钮\n记录宝宝的成长时刻")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 分类筛选视图
struct CategoryFilterView: View {
    @Binding var selectedCategory: MilestoneCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 全部
                CategoryChip(
                    title: "全部",
                    icon: "list.bullet",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                // 各个分类
                ForEach(MilestoneCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - 分类标签
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : Color(red: 0.4, green: 0.6, blue: 1.0))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color(red: 0.4, green: 0.6, blue: 1.0) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - 里程碑卡片
struct MilestoneCard: View {
    let milestone: Milestone
    
    var body: some View {
        HStack(spacing: 16) {
            // 图标
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: milestone.category.icon)
                    .font(.system(size: 24))
                    .foregroundColor(categoryColor)
            }
            
            // 内容
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(milestone.title)
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Text(milestone.relativeDate)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Text(milestone.formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                if !milestone.description.isEmpty {
                    Text(milestone.description)
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
    
    private var categoryColor: Color {
        switch milestone.category.color {
        case "yellow": return .yellow
        case "blue": return Color(red: 0.4, green: 0.6, blue: 1.0)
        case "purple": return .purple
        case "pink": return .pink
        case "orange": return .orange
        case "indigo": return .indigo
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - 添加/编辑里程碑视图
struct AddEditMilestoneView: View {
    @ObservedObject var milestoneManager: MilestoneManager
    @Environment(\.dismiss) var dismiss
    
    let milestone: Milestone?
    
    @State private var date: Date
    @State private var title: String
    @State private var description: String
    @State private var category: MilestoneCategory
    
    init(milestoneManager: MilestoneManager, milestone: Milestone? = nil) {
        self.milestoneManager = milestoneManager
        self.milestone = milestone
        
        if let milestone = milestone {
            _date = State(initialValue: milestone.date)
            _title = State(initialValue: milestone.title)
            _description = State(initialValue: milestone.description)
            _category = State(initialValue: milestone.category)
        } else {
            _date = State(initialValue: Date())
            _title = State(initialValue: "")
            _description = State(initialValue: "")
            _category = State(initialValue: .other)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.95, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        DatePicker("日期", selection: $date, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                    } header: {
                        Label("日期", systemImage: "calendar")
                    }
                    
                    Section {
                        TextField("标题", text: $title)
                    } header: {
                        Label("标题", systemImage: "text.bubble")
                    }
                    
                    Section {
                        Picker("分类", selection: $category) {
                            ForEach(MilestoneCategory.allCases, id: \.self) { cat in
                                HStack {
                                    Image(systemName: cat.icon)
                                    Text(cat.rawValue)
                                }
                                .tag(cat)
                            }
                        }
                    } header: {
                        Label("分类", systemImage: "tag")
                    }
                    
                    Section {
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    } header: {
                        Label("描述", systemImage: "text.alignleft")
                    } footer: {
                        Text("记录这个里程碑的详细情况")
                    }
                    
                    Section {
                        Button(action: {
                            if let existingMilestone = milestone {
                                let updated = Milestone(
                                    id: existingMilestone.id,
                                    date: date,
                                    title: title,
                                    description: description,
                                    category: category
                                )
                                milestoneManager.updateMilestone(updated)
                            } else {
                                let newMilestone = Milestone(
                                    date: date,
                                    title: title,
                                    description: description,
                                    category: category
                                )
                                milestoneManager.addMilestone(newMilestone)
                            }
                            dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text(milestone == nil ? "添加" : "保存")
                                    .font(.system(size: 17, weight: .semibold))
                                Spacer()
                            }
                        }
                        .disabled(title.isEmpty)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(milestone == nil ? "添加里程碑" : "编辑里程碑")
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
