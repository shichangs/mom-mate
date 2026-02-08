# Third-Party Login TODO

- 文档日期：2026-02-08
- 项目：MomMate iOS
- 目标：完成 Apple / Google / 微信第三方登录全量可用

## 当前状态

- Apple 登录：已接入并可在 App 内触发登录。
- Google 登录：已接入按钮与错误提示，尚未完成平台参数配置与 SDK 打通。
- 微信登录：已接入按钮与错误提示，尚未完成平台参数配置与 SDK 打通。

## 待办清单

1. Apple 开发者账号升级（新增阻塞项）
- 注册并开通 Apple Developer Program（付费账号）。
- 将 Xcode Team 从 Personal Team 切换到付费团队。
- 在 Target 中启用 `Sign In with Apple` capability。

2. Google 登录参数准备
- 获取 iOS OAuth Client ID。
- 确认 URL Scheme（通常基于 reversed client id）。
- 在 Xcode 中写入 URL Types / 回调配置。

3. Google 登录代码打通
- 集成 Google Sign-In SDK。
- 在登录页按钮中触发 Google 登录流程。
- 登录成功后写入统一会话（与 Apple 保持同一数据结构）。

4. 微信登录参数准备
- 获取微信开放平台 AppID（如需，补充 Universal Link 与回调域名）。
- 在 Xcode 中写入 URL Types / 回调配置。

5. 微信登录代码打通
- 集成微信登录 SDK。
- 在登录页按钮中触发微信授权流程。
- 登录成功后写入统一会话（与 Apple / Google 保持一致）。

6. 登录态与用户体验完善
- 游客可用：保持当前“未登录也可使用主功能”策略。
- 退出登录：保持现有退出能力并清理会话。
- 失败提示：区分“取消授权”“网络失败”“配置缺失”。

7. 测试与验收
- Apple / Google / 微信分别执行成功登录、取消登录、失败重试用例。
- 重启 App 后验证会话恢复。
- 退出后验证回到登录页。

## 需要你提供的信息（阻塞项）

- Google OAuth Client ID。
- 微信开放平台 AppID（以及你确认采用的回调方式）。
- Apple Developer Program 付费团队（用于启用 Sign In with Apple capability）。

## 完成定义（DoD）

- 三种登录方式均可完成授权并进入主页面。
- 会话可持久化恢复，退出后可清理。
- 构建通过，关键登录流程手测通过。
