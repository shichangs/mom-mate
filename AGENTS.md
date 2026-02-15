# MomMate 开发规则

## 首条消息处理
如果用户在首条消息里没有给出明确任务：
1. 先阅读 `README.md`。
2. 询问要处理的模块（`Sleep`、`Meal`、`Milestone`、`Statistics`、`Auth & Sync`、`Design System`、`Docs`）。
3. 根据模块并行阅读相关文档：
- `docs/product/PRD.md`
- `docs/process/DEVELOPMENT_GUIDELINES.md`
- `docs/testing/REGRESSION_CHECKLIST.md`
- `docs/architecture/CODE_STRUCTURE_REFACTOR_PLAN.md`
- `docs/architecture/AUTH_SYNC_TECHNICAL_DESIGN.md`
- `docs/architecture/UI_UX_DIRECTION_02_EMOTIONAL_GROWTH.md`

## 项目基线
- 平台：iOS 17.0+
- 技术栈：Swift 5.9+、SwiftUI、Combine
- 仓库根目录：`./`
- 产品基线文档：`docs/product/PRD.md`（当前 v1.4）

## 代码质量
- 保持 View 层轻量，业务逻辑优先放在 Manager/Model 层。
- 命名必须表达业务语义，避免晦涩缩写。
- 最小化重复状态与跨层隐式耦合。
- 保证可访问性基线：文本可读、点击区域合理、字体缩放后关键操作不被遮挡。
- 避免魔法字符串（如存储键、鉴权键）；改动相关代码时应抽取常量。
- 纯重构/文件迁移任务不得混入行为改动。
- 删除看似有意图的功能或代码前必须先确认。
- 当一次任务涉及较多代码修改（跨多个文件或单文件大范围变更）时，必须先评估是否需要同步重构原有代码结构，并在结果中说明是否执行重构及原因。

## 架构与目录约束
- 遵循按功能分层：`MomMate/Features/*`，共享能力放在 `MomMate/Shared/*`。
- 优先拆分超大文件，避免继续堆叠单体 View。
- 模块边界保持一致：
  - `Sleep`：`Models/Managers/Statistics/Views`
  - `Meal`：`Models/Managers/Views`
  - `Milestone`：`Models/Managers/Views`
  - `Notes`、`Auth & Sync` 保持独立功能边界

## 命令规范
- 代码变更后（非纯文档变更）必须执行：
  - `xcodebuild -project MomMate.xcodeproj -scheme MomMate -destination 'platform=iOS Simulator,name=iPhone 17' build`
- 若本机不存在该模拟器，使用可用 destination 并在结果里说明。
- 未经用户要求，不运行启动类命令（如 `open`、`xed`、主动拉起模拟器流程）。
- 未经用户明确要求，不提交 commit。

## 版本号与变更说明（强制）
- 每次发布用户可感知更新时，必须递增小版本号（`CFBundleShortVersionString` 的 patch 位）。
- 设置页必须展示当前版本号与构建号，格式为：`v主版本.次版本.小版本 (构建号)`。
- 设置页必须向用户展示简洁的“本次更新”变更信息，且内容与当前版本对应。

## 经验教训沉淀（强制）
- 每次遇到问题或完成重要改动后，必须在 `./PROGRESS.md` 记录：
  - 遇到了什么问题
  - 如何解决的
  - 以后如何避免
  - 对应 `git commit ID`
- 同样的问题不应重复发生。

## 测试与验证
- 手工回归基线使用 `docs/testing/REGRESSION_CHECKLIST.md`。
- 任何行为改动都要覆盖受影响条目并汇报结果。
- 涉及时间/统计逻辑时，必须验证边界场景：
  - 跨天
  - 空数据
  - 补录
- 若无法执行构建或测试，需明确说明阻塞原因。

## 文档同步（强制）
- 改动影响功能/交互/数据/验收时，必须同步更新文档：
  - 产品行为：`docs/product/PRD.md`
  - 回归步骤或预期：`docs/testing/REGRESSION_CHECKLIST.md`
  - 开发流程：`docs/process/DEVELOPMENT_GUIDELINES.md`
  - 技术方案/架构：`docs/architecture/*.md`
  - 项目说明或目录：`README.md` 或 `docs/README.md`
- 若无需更新文档，需在总结或 PR 说明中写清原因。
- 发现“行为变更”时，至少同步更新：
  - `docs/product/PRD.md`
  - `docs/testing/REGRESSION_CHECKLIST.md`
- 代码评审默认检查文档同步，不仅检查 PRD。
- 未按规范同步受影响文档的功能性改动，不应合并。
- 未满足文档准入要求的 PR，不允许合并。

### 文档同步触发条件（命中任一即触发）
- 新增/删除功能。
- 交互流程变化（入口、步骤、状态、空态）。
- 数据模型、持久化或同步策略变化。
- 统计口径、计算逻辑或展示变化。
- 非功能指标变化（性能、稳定性、隐私）。
- 验收标准变化。

### PR 文档检查项（提交前自检）
- [ ] 已评估本次改动影响的文档范围（PRD/回归/README/架构/流程）
- [ ] 已同步更新所有受影响文档
- [ ] 已在 PR 描述写明更新文件与章节

## Changelog 规范
- 建议维护文件：`docs/CHANGELOG.md`（若不存在，首次引入时在 PR 中说明）。
- 推荐结构：
  - `## [Unreleased]`
  - `### Added`
  - `### Changed`
  - `### Fixed`
  - `### Removed`
  - `### Docs`
- 所有未发布改动先写入 `Unreleased`，发布后再归档到版本号章节（如 `## [1.2.0] - 2026-02-12`）。
- 新条目追加到对应小节末尾，不重复创建同名小节。
- 已发布版本章节视为冻结，禁止回写或改写历史描述。

### 何时必须更新 Changelog
- 新增/删除用户可感知功能。
- 交互路径、统计口径、数据存储行为发生变化。
- 修复线上可见缺陷（崩溃、错误统计、数据异常等）。
- 对外文档或使用方式发生实质变化（可写入 `Docs`）。

### 条目写法要求
- 使用“动词 + 结果 + 范围”的短句，避免实现细节。
- 一条只描述一个变更点，禁止混合多个独立改动。
- 建议附带模块前缀，便于检索，例如：
  - `[Sleep] 修复跨天补录后时长显示错误`
  - `[Meal] 新增食物清单拖拽排序`
- 若有关联任务，末尾补充引用：`(refs #123)`。

### 与其他文档联动
- Changelog 记录“发生了什么”；PRD/回归清单记录“应该如何工作与如何验证”。
- 若 Changelog 中存在行为变更条目，需同步检查：
  - `docs/product/PRD.md`
  - `docs/testing/REGRESSION_CHECKLIST.md`

## PR 基本要求
每个 PR 至少包含：
- 改动背景与目标
- 主要改动点
- 风险与回滚方案
- 验证证据（构建/测试/手测）
- 文档同步说明（更新了哪些文件、哪些章节）

## Git 与并行协作安全
多人/多代理并行开发时，必须遵守以下规则：

### 提交规则
- 只提交本次会话改动的文件。
- 禁止 `git add -A`、`git add .`。
- 只允许 `git add <明确文件路径>`。
- 提交前执行 `git status`，确认暂存区仅包含本次改动文件。
- 未经明确要求，不允许 amend commit。

### 禁止操作
- `git reset --hard`
- `git checkout .` 或 `git checkout -- <path>`（除非用户明确要求）
- `git clean -fd`
- `git stash`（除非用户明确要求）
- `git commit --no-verify`
- `git push --force`

### Rebase 冲突规则
- 仅解决本次会话涉及文件的冲突。
- 若冲突出现在未改动文件，停止并询问用户。

## 工具使用规则
- 文本/文件检索优先使用 `rg` / `rg --files`。
- 修改前必须完整阅读目标文件。
- 默认使用非交互命令。
- 非用户明确要求，不执行破坏性命令。

## 输出风格
- 回答保持简洁、技术化、可执行。
- 代码注释、commit、PR 文案中不使用 emoji。
- 明确汇报结果、阻塞项和下一步动作。
