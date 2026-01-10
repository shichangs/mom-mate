//
//  ContentView.swift
//  MomMate
//
//  Main content view - now serves as entry point to MainTabView
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

// MARK: - 历史记录视图
struct HistoryView: View {
    @ObservedObject var recordManager: SleepRecordManager
    @Environment(\.dismiss) var dismiss
    @State private var editingRecord: SleepRecord?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                if recordManager.completedRecords.isEmpty {
                    EmptyStateView(
                        icon: "moon.zzz",
                        title: "还没有记录",
                        subtitle: "记录宝宝的睡眠后会显示在这里"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.md) {
                            ForEach(recordManager.completedRecords) { record in
                                HistoryRecordCard(record: record)
                                    .onTapGesture {
                                        editingRecord = record
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            recordManager.deleteRecord(record)
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                    }
                }
            }
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.primary)
                }
            }
            .sheet(item: $editingRecord) { record in
                EditRecordView(record: record, recordManager: recordManager)
            }
        }
    }
}

// MARK: - 历史记录卡片
struct HistoryRecordCard: View {
    let record: SleepRecord
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // 日期图标
            VStack(spacing: 2) {
                Text(dayOfMonth)
                    .font(AppTypography.title2)
                    .foregroundColor(AppColors.primary)
                Text(monthAbbrev)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(width: 48)
            
            // 详情
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
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
                
                HStack(spacing: AppSpacing.sm) {
                    Label(record.formattedDuration, systemImage: "clock.fill")
                        .font(AppTypography.footnote)
                        .foregroundColor(AppColors.textSecondary)
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
        .shadow(
            color: AppShadow.small.color,
            radius: AppShadow.small.radius,
            x: AppShadow.small.x,
            y: AppShadow.small.y
        )
    }
    
    private var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: record.sleepTime)
    }
    
    private var monthAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: record.sleepTime)
    }
}

// MARK: - 编辑记录视图
struct EditRecordView: View {
    let record: SleepRecord
    @ObservedObject var recordManager: SleepRecordManager
    @Environment(\.dismiss) var dismiss
    
    @State private var sleepTime: Date
    @State private var wakeTime: Date
    
    init(record: SleepRecord, recordManager: SleepRecordManager) {
        self.record = record
        self.recordManager = recordManager
        _sleepTime = State(initialValue: record.sleepTime)
        _wakeTime = State(initialValue: record.wakeTime ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("睡眠时间") {
                    DatePicker("入睡时间", selection: $sleepTime)
                    DatePicker("醒来时间", selection: $wakeTime)
                }
                
                Section {
                    HStack {
                        Text("睡眠时长")
                        Spacer()
                        Text(formattedDuration)
                            .foregroundColor(AppColors.primary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        recordManager.deleteRecord(record)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("删除记录")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var formattedDuration: String {
        let duration = wakeTime.timeIntervalSince(sleepTime)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        }
        return "\(minutes)分钟"
    }
    
    private func saveChanges() {
        var updatedRecord = record
        updatedRecord.sleepTime = sleepTime
        updatedRecord.wakeTime = wakeTime
        recordManager.updateRecord(updatedRecord)
        dismiss()
    }
}

#Preview {
    ContentView()
}
