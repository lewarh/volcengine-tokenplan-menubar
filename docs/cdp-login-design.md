# CDP自助登录工具设计

## 功能目标
通过Chrome DevTools Protocol自动控制浏览器，实现无需手动复制Cookie的自助登录，自动提取并保存认证信息。

## 技术选型
- **CDP库**: `github.com/chromedp/chromedp` (Go语言成熟的CDP客户端)
- **浏览器支持**: Chrome / Edge / Chromium 内核浏览器
- **跨平台**: 支持macOS/Windows/Linux

## 工作流程
```
1. 启动浏览器 → 2. 打开火山引擎登录页面 → 3. 等待用户完成登录 → 
4. 自动跳转到CodingPlan页面 → 5. 提取必要的Cookie和CSRF Token → 
6. 验证认证信息有效性 → 7. 保存到配置文件 → 8. 关闭浏览器
```

## 详细设计
### 1. 启动配置
```go
opts := append(chromedp.DefaultExecAllocatorOptions[:],
    chromedp.Flag("headless", false), // 显示浏览器窗口让用户操作
    chromedp.Flag("disable-extensions", false),
    chromedp.Flag("incognito", true), // 无痕模式，避免污染用户原有会话
    chromedp.WindowSize(1024, 768),
)
```

### 2. 页面导航
- 首先导航到登录页面: `https://signin.volcengine.com/`
- 或者直接导航到目标页面: `https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement`
- 检测到用户登录完成后（判断是否跳转到控制台页面），自动提取Cookie

### 3. Cookie提取
需要提取的Cookie字段：
- `connect.sid`
- `digest`
- `csrfToken`
- `userInfo` (可选，用于显示用户信息)

同时需要从页面中提取 `x-csrf-token`，可以通过两种方式：
1. 从Cookie中获取csrfToken值
2. 从页面的meta标签中提取: `<meta name="csrf-token" content="xxx">`

### 4. 有效性验证
提取完成后，自动调用一次查询接口，验证认证信息是否有效：
- 如果验证成功，保存到配置文件
- 如果验证失败，提示用户重新登录

### 5. 配置保存
配置文件格式：
```yaml
accounts:
  - name: 个人火山账号
    type: codingplan
    connect_sid: "s%3A9a5deffb-04a3-4028-a516-b1c224314976.M8yJbO9qszxunV1hvy6f%2BApU4akgzD4PI%2B416pkfWTY"
    digest: "eyJhbGciOiJSUzI1NiIsImtpZCI6ImE5YzBkZmFjYmZiNDExZjA4OWMwMDAxNjNlMDcwOGJkIn0..."
    csrf_token: "2f237a038f098f0ee7a4653b18389e09"
    expire_at: 1776699260 # digest过期时间
    user_info:
      user_id: "2114747863"
      user_name: "songlairui"
```

### 6. 命令设计
```bash
# 启动登录流程
codingplan-usage login

# 登录并指定账号名称
codingplan-usage login --name "公司账号"
```

## 安全考虑
1. **敏感信息加密**: 配置文件中的Cookie等敏感信息需要加密存储，避免明文泄露
2. **权限控制**: 配置文件权限设置为600，仅当前用户可读写
3. **无痕模式**: 使用浏览器无痕模式，登录完成后不残留任何信息
4. **自动过期提醒**: 根据digest的过期时间，在快过期时提醒用户重新登录

## 优势
1. **无需手动复制Cookie**: 用户只需要正常登录，工具自动提取信息
2. **安全可靠**: 不涉及用户密码，所有认证流程都在官方页面完成
3. **自动验证**: 自动验证认证信息有效性，避免配置错误
4. **多账号支持**: 可以保存多个账号的认证信息，方便切换
