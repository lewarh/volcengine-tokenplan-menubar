# CodingPlan MenuBar

一个基于 SwiftPM 的 macOS 菜单栏应用，直接在菜单栏查看火山引擎 CodingPlan 用量。

## 交互设计

- 菜单栏：显示“最紧张配额”的缩写和剩余百分比，例如 `W71`
  - `S` = 会话配额
  - `W` = 周配额
  - `M` = 月配额
- 弹出面板：展示
  - 当前账号、服务状态、最近更新时间
  - 凭证剩余有效期
  - 三类配额卡片：已用、剩余、重置时间、剩余时间
  - 手动刷新、打开控制台、粘贴/导入 cURL

设计原则：

- 菜单栏只显示一个“最值得立刻关注”的信号，避免把三类配额都塞进窄空间
- 弹层补足上下文，避免用户再打开网页确认
- cURL 导入留在同一面板内，减少配置心智负担

## 运行

```bash
cd /Users/larysong/repo/coding-plan-usage/swift-menubar
swift run CodingPlanMenuBar
```

## 获取 cURL

1. 打开 [火山控制台订阅页](https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?advancedActiveKey=subscribe)
2. 打开浏览器开发者工具
3. 在 Network 中找到 `GetCodingPlanUsage`
4. 右键请求，选择 “Copy as cURL”
5. 回到应用，点“粘贴剪贴板”或直接贴入导入框
