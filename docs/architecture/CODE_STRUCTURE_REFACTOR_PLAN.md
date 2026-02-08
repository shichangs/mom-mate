# 代码结构重构方案（Feature + MVVM/Manager）

## 目标

- 不改变功能行为，仅优化代码组织结构。
- 采用“按功能模块分组”的目录方式，降低维护成本。
- 为后续引入完整 MVVM（或继续 Manager 模式）留出清晰边界。

## 推荐目标目录

```text
MomMate/
├── App/
│   ├── MomMateApp.swift
│   └── ContentView.swift
├── Shared/
│   ├── Design/
│   │   └── DesignSystem.swift
│   ├── Components/
│   │   └── (通用组件)
│   └── Utilities/
│       └── (Date/Formatter/Helper)
├── Features/
│   ├── Sleep/
│   │   ├── Models/
│   │   │   └── SleepRecord.swift
│   │   ├── Managers/
│   │   │   └── SleepRecordManager.swift
│   │   ├── Statistics/
│   │   │   └── SleepStatistics.swift
│   │   └── Views/
│   │       └── (Sleep 相关页面/组件)
│   ├── Meal/
│   │   ├── Models/
│   │   │   └── MealRecord.swift
│   │   ├── Managers/
│   │   │   └── MealRecordManager.swift
│   │   └── Views/
│   │       └── (Meal 相关页面/组件)
│   ├── Milestone/
│   │   ├── Models/
│   │   │   └── Milestone.swift
│   │   ├── Managers/
│   │   │   └── MilestoneManager.swift
│   │   └── Views/
│   │       └── (Milestone 相关页面/组件)
│   ├── Statistics/
│   │   └── Views/
│   │       └── (统计聚合页)
│   └── Notes/
│       ├── Managers/
│       │   └── NotesManager.swift
│       └── Views/
│           └── NotesView.swift
└── Main/
    └── MainTabView.swift
```

## 当前文件映射建议

### App 层
- `MomMate/MomMateApp.swift` -> `MomMate/App/MomMateApp.swift`
- `MomMate/ContentView.swift` -> `MomMate/App/ContentView.swift`

### Shared 层
- `MomMate/DesignSystem.swift` -> `MomMate/Shared/Design/DesignSystem.swift`

### Sleep 功能
- `MomMate/SleepRecord.swift` -> `MomMate/Features/Sleep/Models/SleepRecord.swift`
- `MomMate/SleepRecordManager.swift` -> `MomMate/Features/Sleep/Managers/SleepRecordManager.swift`
- `MomMate/SleepStatistics.swift` -> `MomMate/Features/Sleep/Statistics/SleepStatistics.swift`

### Meal 功能
- `MomMate/MealRecord.swift` -> `MomMate/Features/Meal/Models/MealRecord.swift`
- `MomMate/MealRecordManager.swift` -> `MomMate/Features/Meal/Managers/MealRecordManager.swift`

### Milestone 功能
- `MomMate/Milestone.swift` -> `MomMate/Features/Milestone/Models/Milestone.swift`
- `MomMate/MilestoneManager.swift` -> `MomMate/Features/Milestone/Managers/MilestoneManager.swift`
- `MomMate/MilestonesTabView.swift` -> `MomMate/Features/Milestone/Views/MilestonesTabView.swift`

### Notes 功能
- `MomMate/NotesManager.swift` -> `MomMate/Features/Notes/Managers/NotesManager.swift`
- `MomMate/NotesView.swift` -> `MomMate/Features/Notes/Views/NotesView.swift`

### Main/Navigation
- `MomMate/MainTabView.swift` -> `MomMate/Main/MainTabView.swift`

## 实施步骤（建议分 4 个 PR）

1. PR-1：只迁移目录，不改逻辑  
- 移动文件 + 修复 `xcodeproj` 路径引用。  
- 保证编译通过。

2. PR-2：提炼 Shared  
- 抽取通用组件/工具到 `Shared`。  
- 清理重复实现（如重复页面内组件）。

3. PR-3：功能模块边界清理  
- 将 `MainTabView` 中过长代码按 feature 拆分为子文件。  
- 不改行为，只拆结构。

4. PR-4：MVVM 渐进化  
- 在复杂页面先引入 `ViewModel`（例如 Statistics）。  
- 与现有 `Manager` 共存，避免一次性大改。

## 迁移规则

- 单次 PR 不超过 15 个文件移动，避免冲突过大。
- 每次迁移后必须执行一次完整 build。
- 行为变更为 0：禁止在目录迁移 PR 里混入功能改动。
- 每个 PR 必须同步更新 `docs/product/PRD.md` 的“影响范围”说明（如无行为变更，明确写“无行为变更，仅结构调整”）。

## 验收标准

- 工程可成功编译。
- 现有页面行为不变。
- 新成员可在 30 秒内定位任一功能的 Model/Manager/View 文件。
