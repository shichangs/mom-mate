# MomMate 项目开发规范

- 版本：v1.0
- 生效日期：2026-02-08
- 适用范围：`MomMate` 项目仓库

## 1. 目标

本规范用于统一 MomMate 项目的开发流程、代码质量标准与文档维护要求，确保功能演进可追踪、可验收、可维护。

## 2. 基本原则

- 小步提交：每个改动聚焦单一问题。
- 先定义后开发：需求、边界、验收条件先明确。
- 文档与代码一致：功能行为变更必须同步更新产品文档。
- 可回归：所有改动都应提供可验证结果（手测或自动化）。

## 3. 分支与提交规范

- 分支命名：`feature/*`、`fix/*`、`refactor/*`、`docs/*`
- Commit 建议格式：`type(scope): summary`
- `type` 建议值：`feat`、`fix`、`refactor`、`docs`、`test`、`chore`

示例：

```text
feat(sleep): support custom wake-up time
docs(prd): update meal statistics acceptance criteria
```

## 4. PR 要求

每个 PR 至少应包含：

- 改动背景与目标
- 主要改动点
- 风险与回滚方式
- 验证结果（截图/录屏/测试说明）
- 文档同步说明（必须包含 PRD 更新情况）

## 5. 文档强制同步规则（必遵守）

凡出现以下任一类型改动，必须同步更新对应文档：

- 新增/删除功能
- 交互流程变化（入口、步骤、状态、空态）
- 数据模型或持久化策略变化
- 统计口径、计算逻辑或展示变化
- 非功能指标变化（性能、稳定性、隐私）
- 验收标准变化

### 5.1 变更与文档映射（必执行）

- 产品功能/交互/验收变化：更新 `docs/product/PRD.md`
- 测试步骤或回归口径变化：更新 `docs/testing/REGRESSION_CHECKLIST.md`
- 项目使用方式、目录结构、能力说明变化：更新 `README.md` 或 `docs/README.md`
- 代码组织、分层、技术方案变化：更新 `docs/architecture/*.md`
- 开发流程、提交流程变化：更新 `docs/process/DEVELOPMENT_GUIDELINES.md`

### 5.2 PR 检查清单（必须勾选）

提交 PR 时必须确认：

- [ ] 我已评估本次改动影响的文档范围（PRD/回归/README/架构/流程）
- [ ] 我已同步更新所有受影响的文档（`.md`）
- [ ] 我已在 PR 描述中写明“更新了哪些文档、对应章节/段落”

### 5.3 无需更新文档的情况（例外）

以下纯工程性改动可不更新文档，但需在 PR 说明原因：

- 纯格式化（无行为变化）
- 注释/文案错别字修正（不影响需求语义）
- 构建脚本或 CI 调整（不影响产品能力）
- 仅测试代码变更（不影响线上行为）

## 6. iOS 代码规范（Swift/SwiftUI）

- 保持 View 轻量：业务逻辑优先放在 Manager/Model 层。
- 命名清晰：变量和方法名表达业务语义，避免缩写。
- 状态最小化：避免重复状态和跨层级隐式耦合。
- UI 可访问：关键文案可读、按钮可点击区域合理。
- 持久化一致性：同一域模型避免双写冲突。

## 7. 测试与验收

- 功能改动至少包含手动验收路径。
- 涉及统计/时间逻辑时，必须覆盖边界场景（跨天、空数据、补录）。
- 发现行为变更时，应至少同步更新 `docs/product/PRD.md` 与 `docs/testing/REGRESSION_CHECKLIST.md` 对应章节。
- 合并前需通过 CI 构建检查（见 `.github/workflows/ios-ci.yml`）。

## 8. 文档清单与职责

- `docs/product/PRD.md`：产品需求基线（功能范围、验收标准、版本规划）
- `docs/process/DEVELOPMENT_GUIDELINES.md`：开发流程与质量约束（本文档）
- `docs/testing/REGRESSION_CHECKLIST.md`：回归测试清单
- `README.md`：项目介绍、运行方式、目录结构

## 9. 执行机制

- 代码评审默认检查文档同步情况（不仅 PRD）。
- 未按规范同步受影响文档的功能性 PR 不应合并。
- 当文档与当前行为冲突时，以“先修正文档再合并代码”为默认策略。
