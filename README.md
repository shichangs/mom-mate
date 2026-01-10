# Baby Sleep Tracker

一个优雅且功能全面的婴儿成长追踪应用，旨在帮助父母轻松记录和分析宝宝的日常活动，包括睡眠、进食和重要里程碑。

## 功能特点

### 😴 睡眠追踪 (Sleep Tracking)

- **实时监测**：一键开启/结束睡眠计时，实时显示睡眠状态。
- **历史记录**：清晰的列表展示，支持编辑和删除睡眠记录。
- **深度分析**：
  - 每日/每小时睡眠时长统计。
  - 睡眠趋势图表，帮助识别宝宝的作息规律。
  - 今日/平均睡眠数据对比。

### 🍼 进食记录 (Meal Records)

- **细分记录**：支持记录母乳、奶粉和辅食。
- **分类统计**：
  - 按类型汇总进食量和次数。
  - 进食趋势分析。

### 🏆 成长里程碑 (Milestones)

- **记录惊喜**：记录宝宝成长过程中的每一个第一次（翻身、爬行、走路等）。
- **分类管理**：分为身体发育、认知能力和语言社交。
- **图文并茂**：详细记录里程碑发生的日期和备注。

### 📊 统计分析 (Statistics)

- **多维度视图**：汇总当日所有活动概览。
- **趋势预测**：通过图表直观展示宝宝的成长变化。

## 技术栈

- **SwiftUI**：采用现代化的声明式 UI 开发。
- **Combine**：用于响应式数据处理和状态管理。
- **Design System**：自研 Apple 设计风格的 UI 系统，包含高颜值的颜色方案和流畅的动画。
- **iOS 17.0+**：最低支持系统版本。

## 项目结构

```
MomMate/
├── MomMate/
│   ├── MomMateApp.swift   # 应用入口
│   ├── MainTabView.swift           # 主导航视图
│   ├── SleepRecord.swift           # 睡眠数据模型
│   ├── SleepRecordManager.swift    # 睡眠数据管理器
│   ├── MealRecord.swift            # 进食数据模型
│   ├── MealRecordManager.swift     # 进食数据管理器
│   ├── Milestone.swift             # 里程碑数据模型
│   ├── MilestoneManager.swift      # 里程碑数据管理器
│   ├── DesignSystem.swift          # 全局设计系统
│   └── Assets.xcassets/            # 资源文件
└── MomMate.xcodeproj/     # Xcode 项目文件
```

## 开发环境

- Xcode 15.0+
- Swift 5.9+
- iOS 17.0+

## 许可证

本项目仅供个人学习和交流使用。
