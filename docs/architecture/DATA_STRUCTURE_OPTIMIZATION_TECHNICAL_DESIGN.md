# Data Structure Optimization Technical Design

- 文档日期：2026-02-12
- 适用项目：MomMate iOS
- 目标：在不改变核心用户流程的前提下，降低记录查询复杂度、减少重复计算、提升数据一致性。

## 1. 背景问题

改造前主要问题：

1. 记录更新依赖数组线性查找，`update/delete` 为 `O(n)`。
2. 统计页和首页摘要大量使用 `records.filter`，每次渲染重复全量扫描。
3. 睡眠记录存在冗余字段（`duration` 与 `sleepTime/wakeTime` 双写）。
4. 食物清单使用 `AppStorage + [String]`，缺少稳定标识与顺序元数据。

## 2. 设计原则

1. 行为兼容优先：不改变页面入口与用户关键路径。
2. 渐进演进：保持 `UserDefaults + iCloud KVS` 存储基线，先优化内存结构与读写路径。
3. 单一事实源：移除可由其他字段推导的冗余存储。
4. 可迁移：新结构需兼容旧数据并支持一次性迁移。

## 3. 数据结构设计

## 3.1 Sleep 模块

`SleepRecordManager` 增加：

1. `recordIndexByID: [UUID: Int]`  
用于 `update/end/delete` 常数时间定位记录。

2. `completedRecordsCache: [SleepRecord]` / `currentSleepRecordCache: SleepRecord?`  
避免视图层重复筛选进行中记录和历史记录。

3. `wakeDaySummaries: [Date: DaySummary]`  
按“醒来当天”聚合：
- `totalDuration`
- `count`

提供查询接口：
- `sleepDaySummary(for:)`
- `sleepRangeSummary(start:end:)`

## 3.2 Meal 模块

`MealRecordManager` 增加：

1. `recordIndexByID: [UUID: Int]`
2. `sortedMealRecordsCache: [MealRecord]`
3. `mealRecordsByTypeCache: [MealType: [MealRecord]]`
4. `todayRecordsCache: [MealRecord]`
5. `daySummaries: [Date: DaySummary]`（每日总次数 + 分类型次数）

提供查询接口：
- `mealDaySummary(for:)`
- `mealRangeSummary(start:end:)`

## 3.3 Milestone 模块

`MilestoneManager` 增加：

1. `milestoneIndexByID: [UUID: Int]`
2. `sortedMilestonesCache: [Milestone]`
3. `milestonesByCategoryCache: [MilestoneCategory: [Milestone]]`
4. `milestoneCountByCategory: [MilestoneCategory: Int]`

提供查询接口：
- `milestoneCount(for:)`
- `unlockedCategoryCount`

## 3.4 Food Catalog 结构化

新增结构：

```swift
struct FoodItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var sortOrder: Int
    var isArchived: Bool
}
```

新增管理器：
- `FoodCatalogManager`（持久化 key: `StorageKeys.foodCatalog`）
- 支持新增、删除、拖拽排序、去重（忽略前后空格和大小写）

兼容迁移：
- 从旧 key `savedFoodList` 自动迁移到 `foodCatalog`

## 4. 一致性与正确性

## 4.1 睡眠记录 ID 一致性修复

`endSleep(for:)` 更新记录时保留原 `id`，避免结束睡眠后记录身份变化导致后续编辑/同步关联不稳定。

## 4.2 冗余字段收敛

`SleepRecord.duration` 改为计算属性：
- 由 `wakeTime.timeIntervalSince(sleepTime)` 推导
- 消除双写与不一致风险

## 5. 查询复杂度变化（关键路径）

1. 记录更新定位：`O(n)` -> `O(1)`（索引命中）
2. 日/区间统计：`O(days * records)` -> `O(days)`（按天桶累加）
3. 分类筛选计数：`O(categories * records)` -> `O(categories)`（分类缓存）

## 6. 落地范围（本次已实现）

1. `SleepRecord` 模型去冗余 + ID 一致性修复。
2. Sleep/Meal/Milestone 三个 Manager 的索引与聚合缓存。
3. 统计页（`StatisticsTabView`）改为读取聚合接口。
4. 睡眠首页摘要改为读取按天聚合。
5. 里程碑分类筛选计数改为缓存读取。
6. 饮食食物清单改为 `FoodItem` 结构化管理并完成旧数据迁移。
7. 日期区间计算去除强制解包，降低崩溃风险。

## 7. 验证

1. 构建：
- `xcodebuild -project MomMate.xcodeproj -scheme MomMate -destination 'platform=iOS Simulator,name=iPhone 17' build`

2. 测试：
- `xcodebuild -project MomMate.xcodeproj -scheme MomMate -destination 'platform=iOS Simulator,name=iPhone 17' test`

> 说明：本机无 `iPhone 16` 模拟器，改用可用目标 `iPhone 17`。
