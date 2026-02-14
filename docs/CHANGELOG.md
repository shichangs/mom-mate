# Changelog

## [Unreleased]

### Added

 - [Sleep][Notes] 新增睡眠页工具栏“开发者文档”入口，可直接打开 Notes 页面。
- [Test] 新增 SleepTab 组件交互测试（入睡/醒来/选择其他时间按钮回调触发）。
- [Test] 新增 NotesManager 持久化测试（保存后重建 Manager 可读到最新内容）。

### Changed

- [Statistics] 统一睡眠统计口径与文案为“日均睡眠时长 / 总睡眠时长 / 日均睡眠次数”。
- [Statistics] 睡眠年视图改为“月日均睡眠时长”（按当月天数平均）。
- [Statistics] 统一饮食统计摘要文案为“总进食次数 / 日均进食次数 / 主要进食类型”。
- [Sleep] 拆分 SleepTab 组件文件，提取状态卡片与工具栏组件以降低主文件复杂度。
- [Sleep] 统一历史记录与最近记录的行样式，保持时长与时间线展示一致。
- [App] 统一全局界面语言为中文，并使时间选择器按中文本地化展示。

### Fixed

### Removed

### Docs
- [Docs] 新增“当前实现状态快照（2026-02-13）”，明确各模块已实现/部分实现边界。
- [Docs] 重写 README 的功能清单，按代码现状整理 Sleep/Meal/Milestone/Statistics/Auth & Sync 能力。
- [Docs] 更新回归测试清单中的统计用例，改为周/月/年周期并补充“下一周期禁用”检查点。
- [Docs] 补充鉴权与同步联动回归项（登录恢复/退出后 syncAuthorized 状态与会话清理）。
- [Docs] 新增统计周期边界回归项（31 天月份与闰年 2 月 29 天）。
- [Docs] Notes 回归清单新增“登录并开启同步后重启仍保持最新内容”检查点。
- [Docs] 在 README 与 PRD 新增“统计口径速查表”，统一后续实现与评审口径。
