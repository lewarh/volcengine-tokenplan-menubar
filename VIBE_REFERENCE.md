# Vibe 参考

下面这条命令参考了 `voice-input-src` README 的风格，适合直接驱动 Codex 完成一个 macOS menubar 应用的开发。

特点：

- 以 `codex exec` 非交互执行
- 目标明确、约束完整
- 不包含具体代码片段
- 不提前约束内部数据结构设计

## Codex 指令

```bash
codex exec \
  --model gpt-5.4 \
  --sandbox danger-full-access \
  --ask-for-approval never \
  --cd /ABSOLUTE/PATH/TO/PROJECT \
  "请在当前项目中开发一个 macOS 原生菜单栏应用，用于查看火山引擎 CodingPlan 的订阅用量。具体要求：

1. 应用形态必须是 menubar utility，只在菜单栏中运行，点击图标后弹出原生风格的浮层界面，不需要 Dock 图标，不需要对外发布能力，本机可运行即可。
2. menubar 标题默认展示最重要的一项摘要信息：5 小时限制的剩余百分比。展示必须简短、稳定、可快速扫读。
3. 点击后打开的浮层应优先展示三档配额：5 小时限制、周限制、总量。信息层级要清晰，默认先看配额，不先看账号或配置说明。
4. 每个档位要展示已用比例和重置节奏，其中：
   - 5 小时限制同时展示已用进度、重置进度、重置时间或剩余时间；
   - 周限制和总量要更简洁，不展示多余信息；
   - 所有文案使用中文，避免英文 label 混杂。
5. UI 风格要接近成熟的原生 menubar 工具：紧凑、克制、对齐统一、边距合理、信息密度高但不拥挤。优先优化排版、列对齐、边缘间距、分隔线、底部工具栏的一致性。
6. 不要让配置区域常驻主界面。配置或重新导入应放在独立面板中。默认主面板只关注用量。
7. 最低可用配置方式是导入浏览器里复制出的 GetCodingPlanUsage cURL。程序必须能从 cURL 中解析出 connect.sid、digest、csrfToken，并自动解析用户名，不要求用户再手动输入用户名。
8. 应提供重新导入能力，也应提供删除已导入账号数据的能力。删除后若没有账号，应自然回到导入态。
9. 本地存储不要使用会触发额外系统弹窗的方案。避免 Keychain 授权密码框；使用本地私有文件存储即可，并确保目录和文件权限安全。
10. 网络请求逻辑要以火山控制台实际接口为准，接口调用、请求头、Cookie、CSRF 校验、错误处理，都必须兼容真实请求。
11. 未导入时，应用应直接进入导入态或显示明确的导入引导，不要显示误导性的错误状态。
12. menubar 弹层定位必须稳定，锚定在菜单栏图标下方，不可表现为围绕点击点弹出。
13. menubar 弹层的出现要尽量快速，避免明显的开场动画、渐变拖沓、材质延迟等影响响应感知的问题。
14. 界面中必须提供刷新、重新导入、删除数据、退出应用等完整的用户路径。
15. 所有实现优先使用 Swift 和原生 macOS 技术栈。工程使用 Swift Package Manager。代码结构清晰，文件职责明确，便于后续继续扩展。
16. 在开发过程中主动完成必要的构建与测试验证，确保工程最终可以成功编译运行。
17. 最终输出应包括：完成的代码改动、关键交互说明、运行方式、已完成的验证项，以及仍可继续优化的非阻塞项。

执行要求：
- 不要只给方案，直接完成实现。
- 不要停在半成品界面。
- 不要在文档中输出代码教学。
- 不要在开发指令中塞入具体代码片段或内部数据结构设计。
- 默认自行做产品判断，把 menubar 工具打磨到可直接使用的程度。"
```

## 必须补充给 Agent 的接口上下文

如果要让 agent 真正把应用做出来，除了上面的目标描述，还必须把下面这些火山引擎上下文写进提示词里。否则它只能停留在猜测层面：

### 1) 用户进入页面的来源地址

- 火山控制台订阅页：
  - `https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?advancedActiveKey=subscribe`
- 导入 cURL 时，应明确要求用户从浏览器开发者工具的 Network 面板中，找到 `GetCodingPlanUsage` 请求，并执行 “Copy as cURL”。

### 2) 实际调用的接口地址

- 用量查询接口：
  - `https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage`
- 请求方法：
  - `POST`
- 请求体：
  - 空 JSON，也就是 `{}`。

### 3) 发请求必须满足的关键要求

至少要在任务描述里明确这些点：

- `content-type` 必须是 `application/json`
- `origin` 必须是 `https://console.volcengine.com`
- `referer` 必须指向火山控制台订阅页对应的 `openManagement` 页面
- 请求头 `x-csrf-token` 必须存在
- Cookie 中必须包含：
  - `connect.sid`
  - `digest`
  - `csrfToken`
- 且 **请求头里的 `x-csrf-token` 必须和 Cookie 里的 `csrfToken` 完全一致**

### 4) cURL 导入时必须解析的关键字段

任务描述里要明确告诉 agent：

- 从 cURL 的 Cookie 中提取：
  - `connect.sid`
  - `digest`
  - `csrfToken`
- 如果 Cookie 里没有 `csrfToken`，允许从请求头 `x-csrf-token` 中补取
- `digest` 是 JWT，可从中解析出用户名和过期时间
- 用户名应优先从 `digest` 的 payload 中恢复，不要求用户手填

### 5) 鉴权与错误处理的最小规则

这些规则也建议放进任务描述：

- 401 / 403：视为认证失效，需要重新导入 cURL
- 429：视为请求频率过高，应提示稍后重试
- 5xx：视为服务端错误，应提示稍后重试
- 如果本地没有导入数据，不应显示“错误”，而应进入导入态

### 6) 推荐加入原始开发指令中的增强版段落

你可以把下面这段自然语言直接拼进上面的 `codex exec` 提示词里：

```text
补充接口上下文：
- 用户获取 cURL 的页面是 https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?advancedActiveKey=subscribe
- 实际查询接口是 https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage
- 请求方法为 POST，请求体为 {}
- 必须带 content-type: application/json、origin: https://console.volcengine.com、referer 指向 openManagement 页面
- 必须带 x-csrf-token，请确保它与 Cookie 中的 csrfToken 完全一致
- 必须从 cURL 中解析 connect.sid、digest、csrfToken
- digest 是 JWT，可用于恢复用户名和凭证过期时间
- 401/403 视为需要重新导入，429 视为请求过频，5xx 视为服务端错误
```

## 使用建议

- 把 `/ABSOLUTE/PATH/TO/PROJECT` 替换成你的项目绝对路径。
- 如果是在已有仓库里继续迭代，建议先确保工作区干净，避免把历史实验改动混在一起。
- 如果希望 agent 自动联网查验上游接口或参考资料，可以保留当前配置；如果只想做纯本地实现，可按需删减联网相关要求。
