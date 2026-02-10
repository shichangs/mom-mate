# MomMate 项目优化分析

## 一、架构与代码质量

### 1. MainTabView.swift 文件过大 (1,733 行)

**位置**: `MomMate/Main/MainTabView.swift`

单文件包含 20+ 个 View struct（SleepTabView、MealsTabView、StatisticsTabView、各种 Sheet 等），违反单一职责原则。

**建议**: 按功能模块拆分为独立文件：
- `Features/Sleep/Views/SleepTabView.swift`
- `Features/Meal/Views/MealsTabView.swift`
- `Features/Statistics/Views/StatisticsTabView.swift`
- 各 Sheet/弹窗组件独立文件

### 2. 云同步逻辑重复

**位置**:
- `Features/Sleep/Managers/SleepRecordManager.swift` (Lines 208-252)
- `Features/Meal/Managers/MealRecordManager.swift` (Lines 90-135)
- `Features/Notes/Managers/NotesManager.swift` (Lines 323-366)
- `Features/Milestone/Managers/MilestoneManager.swift` (Lines 80-125)

4 个 Manager 中几乎相同的 `setupObservers()`、`saveRecords()`、`loadRecords()` 逻辑。

**建议**: 抽取通用协议或基类：
```swift
protocol CloudSyncable: ObservableObject {
    associatedtype Record: Codable
    var records: [Record] { get set }
    var storageKey: String { get }
}

extension CloudSyncable {
    func setupObservers() { /* 通用实现 */ }
    func saveToCloud() { /* 通用实现 */ }
    func loadFromCloud() { /* 通用实现 */ }
}
```

### 3. 死代码未清理

**位置**: `MomMate/App/ContentView.swift` (Lines 17-183)

`AuthManager`、`AuthView`、`HistoryView`、`EditRecordView`、`HistoryRecordCard` 等类已定义但未在主流程中使用。

**建议**: 移除未使用的代码，或迁移至独立 feature 模块待后续启用。

### 4. 硬编码魔法字符串

**位置**: 分布在多个 Manager 和 View 文件中

`"fontSizeFactor"`、`"SleepRecords"`、`"sync.auth.enabled.v1"` 等字符串散落各处。

**建议**: 创建统一的常量管理：
```swift
enum StorageKeys {
    static let fontSizeFactor = "fontSizeFactor"
    static let sleepRecords = "SleepRecords"
    static let mealRecords = "MealRecords"
    static let syncEnabled = "sync.auth.enabled.v1"
}
```

---

## 二、性能优化

### 5. Timer 导致全视图重渲染

**位置**: `MomMate/Main/MainTabView.swift:69`

```swift
private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
```

每 60 秒更新 `currentTime`，触发整个 TabView 层级的重新计算。

**建议**: 将定时器逻辑下沉到需要它的子视图（如 SleepTabView），避免不必要的重渲染。

### 6. 统计计算无缓存

**位置**: `Features/Sleep/Statistics/SleepStatistics.swift` (Lines 56-154)

`dailyStatistics()`、`weeklyStatistics()`、`monthlyStatistics()` 每次调用都从原始数据重新计算。

**建议**:
- 添加计算缓存，记录最后计算时间和数据版本
- 数据变更时标记缓存失效
- 考虑将耗时计算移到后台线程

### 7. 列表无分页/懒加载

**位置**: `MainTabView.swift` 多处 ForEach 列表

记录量大时 ForEach 一次渲染所有元素。

**建议**: 对历史记录列表实现分页或使用 `LazyVStack` 配合滚动加载。

### 8. 全量序列化

**位置**: 所有 Manager 的 `saveRecords()` 方法

每次保存操作编码完整 records 数组 (`JSONEncoder().encode(records)`)。

**建议**:
- 实现增量更新，仅序列化变更的记录
- 为每条记录添加 `isDirty` 标记
- 对云同步添加 debounce 防抖机制

---

## 三、安全性

### 9. 敏感数据未加密存储

**位置**: 所有 Manager 的 `saveRecords()` 方法

婴儿睡眠、饮食等健康数据以明文 JSON 存储在 UserDefaults 中。

**建议**:
- 迁移至 Core Data 并启用 `NSFileProtectionComplete`
- 或使用 Keychain 存储敏感数据
- 最低限度：对 JSON 数据进行加密后存储

### 10. 云同步无节流控制

**位置**: 各 Manager 的 `saveRecords()` → `cloudStore.synchronize()`

快速连续操作时（如批量删除）会频繁触发同步。

**建议**: 添加 debounce 机制，合并短时间内的多次同步请求。

### 11. 错误静默吞噬

**位置**: `SleepRecordManager.swift:107-131` 及其他 Manager

```swift
guard let encoded = try? JSONEncoder().encode(records) else { return }
```

编解码失败时无日志输出，数据可能丢失而用户无感知。

**建议**:
- 使用 `do-catch` 替代 `try?` 并记录错误日志
- 关键操作失败时向用户展示提示

---

## 四、类型安全

### 12. 元组替代结构体

**位置**: `MainTabView.swift:522-563`

```swift
private var cards: [(String, String, String)] { ... }
```

**建议**: 使用具名结构体：
```swift
struct InsightCard {
    let title: String
    let value: String
    let subtitle: String
}
```

### 13. 强制解包风险

**位置**: `SleepStatistics.swift:64,96`

```swift
let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
```

**建议**: 使用 `guard let` 配合 fallback 值，避免潜在崩溃。

### 14. Model 不必要的 SwiftUI 依赖

**位置**: `Features/Meal/Models/MealRecord.swift:9`

数据模型文件导入了 `SwiftUI`，但仅使用 `Foundation` 类型。

**建议**: 将 `import SwiftUI` 改为 `import Foundation`。

---

## 五、工程化

### 15. CI/CD 流水线不完整

**位置**: `.github/workflows/ios-ci.yml`

当前仅有编译步骤，缺少：
- 单元测试执行 (`xcodebuild test`)
- 代码覆盖率上报
- 静态分析 (SwiftLint)
- 构建产物归档

### 16. 缺少单元测试

项目无测试 Target，所有业务逻辑未被测试覆盖。

**优先测试**:
- 各 Manager 的 CRUD 操作
- `SleepStatistics` 统计计算
- 日期格式化工具方法
- 云同步合并逻辑

### 17. 最低部署目标偏高

当前 iOS 17.0+ 排除了较旧设备用户。

**建议**: 评估 Charts 框架的替代方案，考虑支持 iOS 16.0+ 以覆盖更多用户。

---

## 优先级排序

| 优先级 | 编号 | 优化项 | 影响 |
|--------|------|--------|------|
| P0 | 9 | 敏感数据加密 | 安全/合规 |
| P0 | 11 | 错误处理改进 | 数据可靠性 |
| P1 | 1 | 拆分 MainTabView | 可维护性 |
| P1 | 2 | 提取云同步通用逻辑 | 代码质量 |
| P1 | 6 | 统计缓存 | 性能 |
| P1 | 16 | 添加单元测试 | 质量保障 |
| P2 | 5 | Timer 优化 | 性能 |
| P2 | 8 | 增量序列化 | 性能 |
| P2 | 10 | 同步防抖 | 稳定性 |
| P2 | 15 | CI/CD 完善 | 工程效率 |
| P3 | 3 | 清理死代码 | 代码整洁 |
| P3 | 4 | 常量管理 | 可维护性 |
| P3 | 12-14 | 类型安全改进 | 代码质量 |
| P3 | 17 | 降低部署目标 | 用户覆盖 |
