# Auth & Sync Technical Design (Guest First)

- 文档日期：2026-02-08
- 适用项目：MomMate iOS
- 目标：支持“未登录可用”，登录仅用于数据同步和备份。

## 1. 设计目标

1. 首次使用无门槛：不登录即可记录睡眠/饮食/成长（Notes 为内部调试能力，不作为用户功能入口）。
2. 登录不影响本机数据：登录/退出都不清空本地记录。
3. 登录后再同步：仅当“用户开启同步 && 已登录账号”时触发 iCloud KVS 同步。
4. 可回溯：首次从游客转登录时，记录一次本地数据快照元信息。

## 2. 账号状态模型

- `guest`：未登录，允许本地读写，不进行云同步。
- `signedIn(provider, userID, displayName)`：已登录，可参与同步（受设置项控制）。

对应持久化键：
- `auth.social_session.v1`：第三方登录会话（provider/userID/displayName）。
- `sync.auth.enabled.v1`：同步授权开关（由登录态驱动）。

## 3. 同步开关判定

各数据 Manager 的有效同步条件统一为：

`isCloudSyncEnabled = cloudSyncEnabled && sync.auth.enabled.v1`

说明：
- `cloudSyncEnabled`：设置页用户手动开关。
- `sync.auth.enabled.v1`：是否已登录账号。
- 只有两个条件都为 true 才进行 iCloud KVS 读写与推送。

## 4. 游客后登录的数据处理

当前实现策略：

1. 用户在游客态产生的数据始终保留在本机 `UserDefaults`。
2. 首次登录成功时，记录一次“迁移快照元信息”：
- sleep/meal/milestone 本地记录条数
- 是否存在 notes
- 采集时间
3. 快照仅用于审计和排障，不更改业务数据内容。
4. 当 `sync.auth.enabled.v1` 由 false 变 true 时，各 Manager 会通过现有观察逻辑触发一次上云推送（前提 `cloudSyncEnabled=true`）。

快照相关键：
- `sync.initialMigration.done.<userID>`
- `sync.initialMigration.snapshot.<userID>`

## 5. UI/交互设计

1. 应用主入口始终进入主页面（不再登录门禁）。
2. 在设置页提供“账号与同步”入口。
3. 账号页：
- 未登录：展示 Apple / Google / 微信登录按钮。
- 已登录：展示当前账号和“退出登录（保留本机数据）”。
4. Google/微信在未配置参数前，显示明确提示而不崩溃。

## 6. 现阶段边界

1. Apple 登录入口已接入；真实 Apple 登录受团队 capability 配置限制（Personal Team 下不可用），Debug Mock 登录可用于联调。Google/微信当前仅完成入口层接入。
2. 当前同步仍基于 iCloud KVS（项目既有能力），未接入独立后端。
3. 未实现复杂冲突解决（例如双端同时编辑同一条记录的细粒度合并）。

## 7. 后续演进建议

1. 引入统一 `SyncEngine`（任务队列、重试、冲突策略）。
2. 记录级字段补充 `updatedAt/deletedAt` 支持增量与 tombstone。
3. 增加“上次同步时间、失败原因、重试按钮”等可观测性。
