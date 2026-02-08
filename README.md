# MomMate (Baby Growth Tracker)

一个优雅且功能全面的婴儿成长追踪应用，采用 **Apple 风格设计系统**，旨在帮助父母轻松记录和分析宝宝的日常活动。

## ✨ 设计亮点

### Premium UI Design

- **Glassmorphism 毛玻璃效果**：卡片使用 `.ultraThinMaterial` 营造通透质感
- **三层渐变系统**：每个功能模块拥有专属的三色渐变配色
- **情绪化色彩**：`安睡紫`、`活力橙`、`成长绿`、`喜悦紫` 等语义化配色
- **呼吸动画 (BreathingCircle)**：睡眠状态使用三层脉冲动画
- **多层阴影 (Layered Shadows)**：营造高级的深度感
- **弹性动画**：按钮交互采用 Spring 物理动画

## 🚀 功能特点

### 😴 睡眠追踪 (Sleep Tracking)

- **实时监测**：一键开启/结束睡眠计时，实时显示睡眠状态
- **呼吸动画**：睡眠中使用优雅的三层脉冲动画指示
- **历史记录**：清晰的列表展示，支持编辑和删除睡眠记录
- **深度分析**：每日/每小时睡眠时长统计，睡眠趋势图表

### 🍼 进食记录 (Meal Records)

- **细分记录**：支持记录早餐、午餐、晚餐、零食、母乳、奶粉
- **快速添加**：常用食物一键选择
- **分类统计**：按类型汇总进食量和次数

### 🏆 成长里程碑 (Milestones)

- **记录惊喜**：记录宝宝成长过程中的每一个第一次
- **分类管理**：身体发育、认知能力和语言社交
- **时间轴展示**：直观展示成长历程

### 📊 统计分析 (Statistics)

- **多维度视图**：汇总当日所有活动概览
- **趋势预测**：通过图表直观展示宝宝的成长变化
- **进度环 (ProgressRing)**：带动画的进度可视化

## 🎨 设计系统 (Design System)

### 色彩体系

```swift
// 情绪化色彩
static let sleep = Color(hex: "6366F1")      // 安睡紫
static let awake = Color(hex: "F59E0B")      // 活力橙
static let meal = Color(hex: "10B981")       // 成长绿
static let milestone = Color(hex: "A855F7")  // 喜悦紫

// 高级渐变
static let sleepGradient = LinearGradient(
    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6"), Color(hex: "A78BFA")],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### 组件库

- `GlassCardStyle` - 毛玻璃卡片
- `ElevatedCardStyle` - 多层阴影卡片
- `GradientButtonStyle` - 渐变按钮
- `FloatingButtonStyle` - 悬浮按钮
- `BreathingCircle` - 呼吸动画圆
- `ProgressRing` - 进度环
- `StatsCard` - 统计卡片

### 动画预设

```swift
static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
static let springSmooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
```

## 📁 项目结构

```
MomMate/
├── MomMate/
│   ├── MomMateApp.swift        # 应用入口
│   ├── MainTabView.swift       # 主导航视图 (Tab Bar)
│   ├── ContentView.swift       # 内容视图入口
│   ├── DesignSystem.swift      # 🎨 设计系统 (颜色/字体/组件)
│   ├── SleepRecord.swift       # 睡眠数据模型
│   ├── SleepRecordManager.swift # 睡眠数据管理器
│   ├── SleepStatistics.swift   # 睡眠统计逻辑
│   ├── MealRecord.swift        # 进食数据模型
│   ├── MealRecordManager.swift # 进食数据管理器
│   ├── Milestone.swift         # 里程碑数据模型
│   ├── MilestoneManager.swift  # 里程碑数据管理器
│   └── Assets.xcassets/        # 资源文件
└── MomMate.xcodeproj/          # Xcode 项目文件
```

## 🛠 技术栈

- **SwiftUI**：现代化声明式 UI 开发
- **Combine**：响应式数据处理和状态管理
- **iOS 17.0+**：最低支持系统版本
- **Xcode 15.0+** / **Swift 5.9+**

## 📚 项目文档规范

- `PRD.md`：产品需求基线文档（功能范围、验收标准、版本规划）
- `DEVELOPMENT_GUIDELINES.md`：项目开发规范（分支、PR、质量与文档流程）
- 强制规则：每次涉及功能/交互/数据/验收标准的改动，必须同步更新 `PRD.md`

## 📄 许可证

本项目仅供个人学习和交流使用。
