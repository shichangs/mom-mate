//
//  MainTabView.swift
//  MomMate
//
//  4-tab navigation root view.
//  Individual tab views are in their respective feature directories.
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
            SleepTabView(
                recordManager: recordManager,
                notesManager: notesManager
            )
            .tabItem {
                Label("睡眠", systemImage: selectedTab == 0 ? "moon.zzz.fill" : "moon.zzz")
            }
            .tag(0)

            MealsTabView(mealRecordManager: mealRecordManager)
                .tabItem {
                    Label("饮食", systemImage: selectedTab == 1 ? "fork.knife.circle.fill" : "fork.knife.circle")
                }
                .tag(1)

            StatisticsTabView(
                recordManager: recordManager,
                mealRecordManager: mealRecordManager
            )
            .tabItem {
                Label("统计", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
            }
            .tag(2)

            GrowthTabView(milestoneManager: milestoneManager)
                .tabItem {
                    Label("成长", systemImage: selectedTab == 3 ? "sparkles" : "sparkles")
                }
                .tag(3)
        }
        .tint(AppColors.primary)
    }
}

// MARK: - 成长 Tab (thin wrapper)
struct GrowthTabView: View {
    @ObservedObject var milestoneManager: MilestoneManager
    @AppStorage(StorageKeys.fontSizeFactor) private var fontSizeFactor: Double = 1.0

    var body: some View {
        MilestonesTabView(milestoneManager: milestoneManager)
            .id(fontSizeFactor)
    }
}
