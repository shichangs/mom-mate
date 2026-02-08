//
//  NotesManager.swift
//  MomMate
//
//  Manages markdown notes storage
//

import Foundation

class NotesManager: ObservableObject {
    @Published var notes: String = ""
    
    private let notesKey = "AppNotes"
    private let cloudSyncEnabledKey = "cloudSyncEnabled"
    private let cloudStore = NSUbiquitousKeyValueStore.default
    private var lastKnownCloudSyncEnabled = UserDefaults.standard.object(forKey: "cloudSyncEnabled") as? Bool ?? true
    
    init() {
        setupObservers()
        loadNotes()
        // 如果没有笔记，初始化默认笔记
        if notes.isEmpty {
            initializeDefaultNotes()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func saveNotes() {
        UserDefaults.standard.set(notes, forKey: notesKey)
        if isCloudSyncEnabled {
            cloudStore.set(notes, forKey: notesKey)
            cloudStore.synchronize()
        }
    }
    
    func loadNotes() {
        if isCloudSyncEnabled {
            cloudStore.synchronize()
            notes = cloudStore.string(forKey: notesKey) ?? UserDefaults.standard.string(forKey: notesKey) ?? ""
            return
        }
        notes = UserDefaults.standard.string(forKey: notesKey) ?? ""
    }
    
    private func initializeDefaultNotes() {
        notes = """
# 宝宝睡眠记录应用 - 开发者文档

## 🏗️ 项目架构

### 技术栈
- **SwiftUI**：UI 框架，iOS 17.0+
- **UserDefaults**：本地数据持久化
- **Combine**：响应式数据流（@Published, ObservableObject）
- **Foundation**：Date, Calendar, DateFormatter 等基础类

### 项目结构
```
MomMate/
├── MomMateApp.swift      # App 入口，使用 MainTabView 作为根视图
├── MainTabView.swift              # 底部 Tab 导航，包含 SleepHomeView
├── ContentView.swift              # 旧版主视图（已废弃，保留用于兼容）
├── SleepRecord.swift              # 数据模型：睡眠记录
├── SleepRecordManager.swift       # 业务逻辑：睡眠记录管理
├── SleepStatistics.swift          # 数据模型：统计数据 + 统计管理器
├── StatisticsView.swift           # UI：统计页面
├── Milestone.swift                # 数据模型：里程碑
├── MilestoneManager.swift        # 业务逻辑：里程碑管理
├── MilestonesView.swift           # UI：里程碑列表
├── MilestonesTabView.swift        # UI：里程碑 Tab 页面
├── MealRecord.swift               # 数据模型：吃饭记录
├── MealRecordManager.swift        # 业务逻辑：吃饭记录管理
├── MealRecordsView.swift          # UI：吃饭记录列表
├── MealRecordsTabView.swift       # UI：吃饭记录 Tab 页面
├── NotesManager.swift             # 业务逻辑：开发者笔记管理
└── NotesView.swift                # UI：开发者笔记查看/编辑
```

## 📦 数据模型

### SleepRecord
```swift
struct SleepRecord: Identifiable, Codable {
    let id: UUID
    let sleepTime: Date
    let wakeTime: Date?
    let duration: TimeInterval?
    
    // 计算属性
    var isSleeping: Bool
    var formattedDuration: String
    var formattedSleepTime: String
    var formattedWakeTime: String?
    var relativeSleepTime: String
    var relativeWakeTime: String?
}
```

**关键实现**：
- `relativeTimeString(from:)`：计算相对时间字符串（"x分钟前"）
- 支持通过 `id` 参数初始化，用于更新现有记录

### SleepStatistics
```swift
struct SleepStatistics {
    let period: String
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let sleepCount: Int
    let date: Date
}
```

**统计周期**：
- 按天：最近 7 天
- 按周：最近 8 周
- 按月：最近 12 个月
- 按年：最近 3 年

## 🔧 核心管理器

### SleepRecordManager
**职责**：管理睡眠记录的 CRUD 操作

**关键方法**：
- `startSleep()` / `startSleep(minutesAgo:)`：开始睡眠记录
- `endCurrentSleep()` / `endCurrentSleep(minutesAgo:)`：结束当前睡眠
- `updateRecord(_:sleepTime:wakeTime:)`：更新记录
- `deleteRecord(_:)`：删除记录
- `generateTestData()`：生成测试数据（过去 3 个月）
- `clearAllData()`：清空所有数据

**数据持久化**：
- 使用 `UserDefaults` 存储
- Key: `"SleepRecords"`
- JSON 编码/解码

### SleepStatisticsManager
**职责**：计算统计数据

**关键方法**：
- `dailyStatistics(from:)`：按天统计
- `weeklyStatistics(from:)`：按周统计
- `monthlyStatistics(from:)`：按月统计
- `yearlyStatistics(from:)`：按年统计
- `chartData(from:)`：转换为图表数据点

**统计逻辑**：
- 只统计已完成的记录（`wakeTime != nil`）
- 使用 `Calendar` 进行日期分组
- 自动过滤无效数据

## 🎨 UI 组件

### 导航结构
```
MainTabView (TabView)
├── Tab 0: SleepHomeView (睡眠)
├── Tab 1: StatisticsView (统计)
├── Tab 2: MilestonesTabView (里程碑)
└── Tab 3: MealRecordsTabView (吃饭)
```

### 主要视图组件
- **SleepingCardView**：正在睡觉状态卡片
- **AwakeCardView**：未睡觉状态卡片
- **QuickTimeButtonsView**：快捷时间按钮组（网格布局）
- **RecentRecordsView**：最近记录预览
- **HistoryView**：历史记录列表
- **EditRecordView**：编辑记录表单
- **ChartCard**：统计图表卡片

### 状态管理
- 使用 `@StateObject` 创建管理器实例
- 使用 `@ObservedObject` 在子视图中观察
- 使用 `@Published` 属性触发 UI 更新
- 使用 `@State` 管理本地 UI 状态

## 🔄 数据流

### 记录创建流程
1. 用户点击"记录入睡" → `SleepRecordManager.startSleep()`
2. 创建 `SleepRecord` 对象（`wakeTime = nil`）
3. 插入到 `records` 数组首位
4. 调用 `saveRecords()` 持久化
5. `@Published` 触发 UI 更新

### 记录更新流程
1. 用户点击历史记录 → 打开 `EditRecordView`
2. 修改时间 → 调用 `updateRecord(_:sleepTime:wakeTime:)`
3. 查找并替换数组中的记录
4. 调用 `saveRecords()` 持久化
5. UI 自动刷新

### 统计计算流程
1. 用户切换统计周期 → `StatisticsView` 更新 `selectedPeriod`
2. 调用 `SleepStatisticsManager` 对应方法
3. 遍历 `SleepRecordManager.records`，按周期分组
4. 计算总时长、平均时长、次数
5. 返回 `[SleepStatistics]` 数组
6. 转换为 `ChartDataPoint` 用于图表

## 🐛 已知问题与限制

### 数据持久化
- **限制**：使用 `UserDefaults`，不适合大量数据
- **影响**：删除应用会丢失所有数据
- **改进方向**：迁移到 Core Data 或 SQLite

### 时间处理
- **精度**：记录时间精确到分钟
- **时区**：使用系统时区，未做特殊处理
- **夏令时**：可能影响跨夏令时的统计

### 统计计算
- **性能**：大量数据时可能较慢（未做优化）
- **内存**：所有记录加载到内存
- **过滤**：只统计已完成的记录（`wakeTime != nil`）

## 📝 版本历史

### v1.0.0 - 初始版本
- 基础睡眠记录功能
- UserDefaults 存储

### v1.1.0 - UI 优化
- 卡片式设计
- 渐变背景和阴影

### v1.2.0 - 相对时间
- 实现 `relativeTimeString(from:)` 方法
- 实时更新相对时间显示

### v1.3.0 - 编辑功能
- 实现 `updateRecord` 方法
- 支持修改入睡和醒来时间

### v1.4.0 - 快捷时间
- `startSleep(minutesAgo:)` / `endCurrentSleep(minutesAgo:)`
- 快捷按钮 UI 组件

### v1.5.0 - 统计功能
- `SleepStatisticsManager` 实现
- 多周期统计（天/周/月/年）
- 图表展示

### v1.6.0 - 测试数据
- `generateTestData()` 方法
- 自动生成过去 3 个月数据

### v1.7.0 - 开发者文档
- `NotesManager` 和 `NotesView`
- Markdown 笔记功能

### v1.8.0 - Tab 导航重构
- 从 `ContentView` 迁移到 `MainTabView`
- 底部 Tab 导航
- 里程碑和吃饭记录功能

## 🚀 技术债务

### 高优先级
- [ ] 迁移到 Core Data（替代 UserDefaults）
- [ ] 添加单元测试
- [ ] 优化统计计算性能（大数据量）

### 中优先级
- [ ] 使用 Swift Charts 框架（替代自定义图表）
- [ ] 添加数据导出功能
- [ ] 支持 iCloud 同步

### 低优先级
- [ ] 深色模式支持
- [ ] Widget 支持
- [ ] 动画效果优化

## 🔍 调试技巧

### 测试数据
```swift
// 在 SleepRecordManager 中调用
recordManager.generateTestData()
```

### 清空数据
```swift
// 在 SleepRecordManager 中调用
recordManager.clearAllData()
```

### 查看 UserDefaults
```swift
// 在调试器中
po UserDefaults.standard.object(forKey: "SleepRecords")
```

## 📌 开发注意事项

1. **ID 冲突**：项目文件中的 ID 必须唯一，避免手动编辑 `project.pbxproj`
2. **数据迁移**：修改数据模型时需要考虑数据迁移逻辑
3. **时区处理**：所有时间使用 `Date`，系统自动处理时区
4. **内存管理**：`@StateObject` 和 `@ObservedObject` 的使用要正确
5. **UI 更新**：确保所有数据修改后调用 `saveRecords()` 等方法

---
*最后更新：\(formatDate(Date()))*
"""
        saveNotes()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private var isCloudSyncEnabled: Bool {
        UserDefaults.standard.object(forKey: cloudSyncEnabledKey) as? Bool ?? true
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudStoreDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserDefaultsDidChange(_:)),
            name: UserDefaults.didChangeNotification,
            object: UserDefaults.standard
        )
    }
    
    private func pushCurrentNotesToCloud() {
        cloudStore.set(notes, forKey: notesKey)
        cloudStore.synchronize()
    }
    
    @objc
    private func handleCloudStoreDidChange(_ notification: Notification) {
        guard isCloudSyncEnabled else { return }
        loadNotes()
    }
    
    @objc
    private func handleUserDefaultsDidChange(_ notification: Notification) {
        let current = isCloudSyncEnabled
        guard current != lastKnownCloudSyncEnabled else { return }
        lastKnownCloudSyncEnabled = current
        
        if current {
            pushCurrentNotesToCloud()
        }
        loadNotes()
    }
}
