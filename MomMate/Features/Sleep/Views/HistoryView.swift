//
//  HistoryView.swift
//  MomMate
//
//  Sleep history — 现代极简风格
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var recordManager: SleepRecordManager
    @Environment(\.dismiss) var dismiss
    @State private var editingRecord: SleepRecord?

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()

                if recordManager.completedRecords.isEmpty {
                    EmptyStateView(
                        icon: "moon.zzz",
                        title: "还没有记录",
                        subtitle: "记录宝宝的睡眠后会显示在这里"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(recordManager.completedRecords.enumerated()), id: \.element.id) { index, record in
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

                                if index < recordManager.completedRecords.count - 1 {
                                    Divider()
                                        .foregroundColor(AppColors.divider)
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .background(AppColors.surface)
                        .cornerRadius(AppRadius.lg)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                    }
                }
            }
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
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
            VStack(spacing: 2) {
                Text(dayOfMonth)
                    .font(AppTypography.title3)
                    .foregroundColor(AppColors.textPrimary)
                Text(monthAbbrev)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xs) {
                    Text(record.formattedSleepTime)
                        .font(AppTypography.calloutMedium)

                    if let wakeTime = record.formattedWakeTime {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(AppColors.textTertiary)
                        Text(wakeTime)
                            .font(AppTypography.calloutMedium)
                    }
                }
                .foregroundColor(AppColors.textPrimary)

                Text(record.formattedDuration)
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
    }

    private var dayOfMonth: String {
        DateFormatters.dayNumber.string(from: record.sleepTime)
    }

    private var monthAbbrev: String {
        DateFormatters.monthZh.string(from: record.sleepTime)
    }
}

// MARK: - 编辑记录
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
                    DatePicker("入睡时间", selection: $sleepTime, in: ...Date())
                    DatePicker("醒来时间", selection: $wakeTime, in: sleepTime...Date())
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
                    Button("取消") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { saveChanges() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        wakeTime > sleepTime
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
        guard canSave else { return }
        var updatedRecord = record
        updatedRecord.sleepTime = sleepTime
        updatedRecord.wakeTime = wakeTime
        recordManager.updateRecord(updatedRecord)
        dismiss()
    }
}
