# 📦 CodingPlan Usage HAND_OFF 交接文档
> 文档包含所有开发所需的接口、数据结构、认证机制、架构设计信息，拿到即可直接开工，无需再回溯历史信息或重新抓包调试

---

## 🎯 项目概述
### 背景
火山引擎豆包编程助手（CodingPlan）没有官方的用量查询入口，每次需要进网页才能看剩余时长，非常不方便。现有bash脚本已实现完整的查询逻辑，现在需要演进为体验更好的客户端。

### 现有成果
- ✅ API接口100%调通，认证机制完全摸透
- ✅ 完整的curl示例和响应解析逻辑
- ✅ bash脚本已实现所有核心业务逻辑（查询、解析、多账号、凭证有效期计算）
- ✅ 交互逻辑和展示格式已验证，用户认可

### 目标
开发用户体验更好的客户端，可选方向：
1. **Go方向**：跨平台CLI + TUI终端界面，单二进制分发
2. **Swift方向**：macOS原生菜单栏App，原生体验最佳

---

## 🔌 核心API 100% 完整文档
### 基础信息
| 项 | 值 |
|----|----|
| 请求地址 | `https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage` |
| 请求方法 | POST |
| 端口 | 443 (HTTPS) |
| 内容类型 | `application/json` |

### 请求头要求
| Header | 必须 | 值说明 |
|--------|------|--------|
| `content-type` | ✅ | 固定 `application/json` |
| `origin` | ✅ | 固定 `https://console.volcengine.com` |
| `referer` | ✅ | 固定 `https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?LLM=%7B%7D&action=%7B%7D&advancedActiveKey=subscribe&tab=Application` |
| `x-csrf-token` | ✅ | 必须和Cookie中的`csrfToken`值完全一致 |
| `user-agent` | ⚠️ | 建议带正常浏览器UA，避免被拦截 |

### Cookie认证参数
| Cookie Key | 必须 | 值说明 |
|------------|------|--------|
| `connect.sid` | ✅ | 会话ID，服务端生成 |
| `digest` | ✅ | JWT格式的核心认证凭证，包含用户信息和有效期 |
| `csrfToken` | ✅ | CSRF防护令牌，必须和请求头`x-csrf-token`值一致 |

### 请求体
固定为空JSON：
```json
{}
```

### 完整响应示例
```json
{
  "ResponseMetadata": {
    "RequestId": "2026-04-19xxxxxx",
    "Action": "GetCodingPlanUsage",
    "Version": "2024-01-01",
    "Service": "ark",
    "Region": "cn-beijing"
  },
  "Result": {
    "Status": "Running",
    "UpdateTimestamp": 1776589405,
    "QuotaUsage": [
      {
        "Level": "session",
        "Percent": 18.6,
        "ResetTimestamp": 1776605668
      },
      {
        "Level": "weekly",
        "Percent": 29.2,
        "ResetTimestamp": 1776614400
      },
      {
        "Level": "monthly",
        "Percent": 14.7,
        "ResetTimestamp": 1779119999
      }
    ]
  }
}
```

### 字段说明
| 字段 | 类型 | 说明 |
|------|------|------|
| `Result.Status` | String | 服务状态：`Running`/`Expired`/`Exhausted` |
| `Result.UpdateTimestamp` | Int64 | 最后更新时间戳（秒） |
| `QuotaUsage[].Level` | String | 配额类型：`session`(会话5小时)/`weekly`(周)/`monthly`(月) |
| `QuotaUsage[].Percent` | Float64 | 已使用百分比，0-100 |
| `QuotaUsage[].ResetTimestamp` | Int64 | 重置时间戳（秒） |

### 错误场景
| HTTP状态码 | 说明 | 处理方式 |
|------------|------|----------|
| 401/403 | 认证失败/凭证过期 | 提示用户重新导入凭证 |
| 429 | 请求过于频繁 | 限制请求频率，建议最低1分钟一次 |
| 5xx | 服务端错误 | 稍后重试 |

---

## 🔑 JWT凭证解析规则
`digest`字段是标准JWT格式，结构为`header.payload.signature`
### 解析步骤
1. 取中间的`payload`部分，进行Base64Url解码（注意替换`_`→`/`，`-`→`+`，补`=`对齐4字节）
2. 解析JSON获取有效期字段

### Payload核心字段
```json
{
  "exp": 1776699260, // 过期时间戳（秒）
  "iat": 1776526460, // 签发时间戳（秒）
  "name": "username", // 用户名
  "sub": "2114747863", // 用户ID
  "iss": "https://signin.volcengine.com"
}
```

### 有效期说明
- `digest` JWT默认有效期：48小时（2天）
- CSRF Token有效期：和会话一致，一般7天左右

---

## 🧱 核心数据结构
### 1. 业务模型（双版本定义）
#### Go版本
```go
// QuotaInfo 配额信息
type QuotaInfo struct {
	Level           string  `json:"level"`
	Percent         float64 `json:"percent"`
	ResetTimestamp  int64   `json:"resetTimestamp"`
	RemainingPercent float64 `json:"remainingPercent"` // 计算字段：100 - Percent
	RemainingTime   string  `json:"remainingTime"`     // 计算字段：剩余时间友好显示
	ResetTimeStr    string  `json:"resetTimeStr"`      // 计算字段：重置时间友好显示
}

// UsageResponse 完整用量响应
type UsageResponse struct {
	Status     string      `json:"status"`
	UpdateTime int64       `json:"updateTime"`
	Quotas     []QuotaInfo `json:"quotas"`
}

// AccountConfig 账号配置
type AccountConfig struct {
	Name        string `json:"name" yaml:"name"`
	ConnectSID  string `json:"connectSid" yaml:"connectSid"`
	Digest      string `json:"digest" yaml:"digest"`
	CsrfToken   string `json:"csrfToken" yaml:"csrfToken"`
	ExpireAt    int64  `json:"expireAt" yaml:"expireAt"` // 自动计算的凭证过期时间
	IsDefault   bool   `json:"isDefault" yaml:"isDefault"`
}
```

#### Swift版本
```swift
// MARK: - 配额信息模型
struct QuotaInfo: Identifiable {
    let id = UUID()
    let level: String
    let percent: Double
    let resetTimestamp: TimeInterval
    
    // 计算属性
    var remainingPercent: Double { 100 - percent }
    var levelName: String {
        switch level {
        case "session": return "会话限制"
        case "weekly": return "每周限制"
        case "monthly": return "每月限制"
        default: return level
        }
    }
    var totalQuota: String {
        switch level {
        case "session": return "5小时"
        case "weekly": return "40小时"
        case "monthly": return "160小时"
        default: return ""
        }
    }
    var resetTime: Date { Date(timeIntervalSince1970: resetTimestamp) }
    var remainingTime: String {
        let interval = resetTime.timeIntervalSinceNow
        guard interval > 0 else { return "已过期" }
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if days > 0 { return "\(days)天 \(hours)小时" }
        if hours > 0 { return "\(hours)小时 \(minutes)分钟" }
        return "\(minutes)分钟"
    }
}

// MARK: - 用量响应模型
struct UsageResponse: Codable {
    let Result: Result
}

struct Result: Codable {
    let Status: String
    let UpdateTimestamp: TimeInterval
    let QuotaUsage: [QuotaUsage]
}

struct QuotaUsage: Codable {
    let Level: String
    let Percent: Double
    let ResetTimestamp: TimeInterval
}

// MARK: - 账号配置模型
struct AccountConfig: Codable, Identifiable {
    let id = UUID()
    let name: String
    let connectSID: String
    let digest: String
    let csrfToken: String
    let expireAt: TimeInterval
    var isDefault: Bool = false
}
```

---

## 🔐 认证机制完整说明
### 三个参数的作用
| 参数 | 作用 | 有效期 |
|------|------|--------|
| `connect.sid` | 会话标识符 | 和digest一致，2天 |
| `digest` | 核心认证凭证，JWT包含用户信息和签名 | 2天 |
| `csrfToken` | CSRF防护，防止跨站请求伪造 | 7天左右，和会话绑定 |

### 有效性验证方法
调用一次API，返回HTTP 200且包含`ResponseMetadata`即为有效，否则无效。

### 安全存储要求
❌ 禁止明文存储在配置文件中
✅ 推荐存储方式：
- Go：使用`99designs/keyring`库，存储到系统密钥链
- Swift：直接使用系统`Keychain Services`API存储，或者用`KeychainAccess`第三方库简化开发

---

## 🚀 Go 方向开发全指南
### 技术栈选型
| 模块 | 选型 | 说明 |
|------|------|------|
| CLI框架 | `spf13/cobra` | 行业标准，命令行参数解析非常好用 |
| 配置管理 | `spf13/viper` | 支持多格式配置、自动热加载 |
| 网络请求 | 标准库`net/http` | 无需第三方依赖，足够用 |
| JSON解析 | 标准库`encoding/json` | |
| 密钥存储 | `99designs/keyring` | 跨平台系统密钥链访问 |
| TUI框架 | `charmbracelet/bubbletea` | 目前最火的Go TUI框架，生态好开发快 |
| 打包 | Go标准编译 | 直接输出单二进制，无依赖 |

### 项目结构规划
```
codingplan-usage/
├── cmd/                    # 命令入口
│   ├── root.go             # 根命令
│   ├── query.go            # 查询命令
│   ├── import.go           # 导入配置命令
│   ├── config.go           # 配置管理命令
│   └── tui.go              # TUI交互模式命令
├── internal/               # 内部逻辑
│   ├── api/                # API客户端
│   │   └── client.go
│   ├── config/             # 配置管理
│   │   └── manager.go
│   ├── model/              # 数据模型
│   │   └── models.go
│   └── tui/                # TUI界面逻辑
│       ├── app.go
│       └── components/
├── pkg/                    # 公共库
│   ├── jwt/                # JWT解析工具
│   └── utils/              # 工具函数
├── go.mod
├── go.sum
└── main.go
```

### 核心模块代码示例
#### API Client
```go
package api

import (
	"bytes"
	"encoding/json"
	"net/http"
	"time"
)

type Client struct {
	connectSID string
	digest     string
	csrfToken  string
	httpClient *http.Client
}

func NewClient(connectSID, digest, csrfToken string) *Client {
	return &Client{
		connectSID: connectSID,
		digest:     digest,
		csrfToken:  csrfToken,
		httpClient: &http.Client{Timeout: 10 * time.Second},
	}
}

func (c *Client) GetUsage() (*UsageResponse, error) {
	url := "https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage"
	reqBody := []byte("{}")
	
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, err
	}
	
	// 设置请求头
	req.Header.Set("content-type", "application/json")
	req.Header.Set("origin", "https://console.volcengine.com")
	req.Header.Set("referer", "https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?LLM=%7B%7D&action=%7B%7D&advancedActiveKey=subscribe&tab=Application")
	req.Header.Set("x-csrf-token", c.csrfToken)
	
	// 设置Cookie
	req.AddCookie(&http.Cookie{Name: "connect.sid", Value: c.connectSID})
	req.AddCookie(&http.Cookie{Name: "digest", Value: c.digest})
	req.AddCookie(&http.Cookie{Name: "csrfToken", Value: c.csrfToken})
	
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	var response UsageResponse
	if err := json.NewDecoder(resp.Body).Decode(&response); err != nil {
		return nil, err
	}
	
	return &response, nil
}
```

### 编译打包
```bash
# 本机编译
go build -o codingplan-usage main.go

# 交叉编译Windows
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -o codingplan-usage.exe main.go

# 交叉编译Linux
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o codingplan-usage-linux main.go
```

### 后续扩展路线
1. V1.0：CLI核心功能（查询、导入、配置管理）
2. V1.1：TUI交互模式，支持鼠标操作
3. V1.2：后台守护模式，自动刷新+用量不足系统通知
4. V1.3：多账号自动切换能力

---

## 🍎 Swift 方向开发全指南
### 技术栈选型
| 模块 | 选型 | 说明 |
|------|------|------|
| UI框架 | SwiftUI | 原生框架，开发菜单栏App非常高效 |
| 网络请求 | 标准库`URLSession` 或者 `Alamofire` | 简单请求用标准库足够 |
| JSON解析 | `Codable` | 原生解析，无需第三方库 |
| 密钥存储 | `Keychain Services` / `KeychainAccess`(第三方库) | 系统级安全存储 |
| 通知 | `UserNotifications` | 系统通知中心，用量不足推送提醒 |
| 打包 | Xcode 原生打包 | 输出`.app`，支持公证分发 |

### 项目结构规划
```
CodingPlanUsage/
├── CodingPlanUsageApp.swift      # App入口
├── Models/                       # 数据模型
│   ├── QuotaInfo.swift
│   ├── UsageResponse.swift
│   └── AccountConfig.swift
├── ViewModels/                   # 视图模型
│   └── UsageViewModel.swift
├── Services/                     # 服务层
│   ├── APIClient.swift           # API请求服务
│   ├── KeychainService.swift     # 密钥存储服务
│   └── NotificationService.swift # 通知服务
└── Views/                        # 界面组件
    ├── MenuBarExtraView.swift    # 菜单栏弹出界面
    ├── QuotaCardView.swift       # 配额卡片组件
    └── SettingsView.swift        # 设置界面
```

### 核心模块代码示例
#### APIClient
```swift
import Foundation

class APIClient {
    static let shared = APIClient()
    
    func getUsage(account: AccountConfig) async throws -> [QuotaInfo] {
        let url = URL(string: "https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://console.volcengine.com", forHTTPHeaderField: "Origin")
        request.setValue("https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?LLM=%7B%7D&action=%7B%7D&advancedActiveKey=subscribe&tab=Application", forHTTPHeaderField: "Referer")
        request.setValue(account.csrfToken, forHTTPHeaderField: "x-csrf-token")
        
        // 设置Cookie
        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .domain: "console.volcengine.com",
            .path: "/",
            .name: "connect.sid",
            .value: account.connectSID
        ]
        if let cookie = HTTPCookie(properties: cookieProperties) {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
        // 同样设置digest和csrfToken的Cookie...
        
        request.httpBody = "{}".data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let usageResponse = try JSONDecoder().decode(UsageResponse.self, from: data)
        return usageResponse.Result.QuotaUsage.map { quota in
            QuotaInfo(
                level: quota.Level,
                percent: quota.Percent,
                resetTimestamp: quota.ResetTimestamp
            )
        }
    }
}

enum APIError: Error {
    case invalidResponse
    case invalidCredentials
}
```

#### MenuBar App 入口
```swift
import SwiftUI

@main
struct CodingPlanUsageApp: App {
    @StateObject private var viewModel = UsageViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 12) {
                // 标题栏
                HStack {
                    Text("📊 豆包编程助手用量")
                        .font(.headline)
                    Spacer()
                    Button(action: viewModel.refresh) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                Divider()
                
                // 配额列表
                if viewModel.isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity)
                } else if let error = viewModel.error {
                    Text("❌ \(error.localizedDescription)")
                        .foregroundColor(.red)
                } else {
                    ForEach(viewModel.quotas) { quota in
                        QuotaCardView(quota: quota)
                    }
                }
                
                Divider()
                
                // 底部按钮
                HStack {
                    Button("设置") {
                        // 打开设置窗口
                    }
                    Spacer()
                    Button("退出") {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .padding()
            .frame(width: 350)
        } label: {
            // 菜单栏显示内容，直接显示周用量百分比
            Text("\(viewModel.weeklyUsagePercent)%")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏Dock图标，只显示菜单栏
        NSApplication.shared.setActivationPolicy(.accessory)
    }
}
```

### 打包发布说明
1. Xcode选择`Product` → `Archive`
2. 选择`Distribute App` → `Copy App` 输出`.app`包
3. 可选：对App进行签名和公证，避免 Gatekeeper 拦截
4. 可以打包成dmg分发

### 后续扩展路线
1. V1.0：MVP核心功能（菜单栏显示用量、查看详情、手动刷新）
2. V1.1：多账号管理、自动刷新、用量不足推送通知
3. V1.2：浏览器自动导入凭证（无需手动复制curl）
4. V1.3：高级功能（用量统计图表、历史记录、使用趋势分析）

---

## 🗺️ 功能演进 Roadmap
### V1.0 MVP版本（核心功能）
- [ ] 账号配置导入/管理
- [ ] 基础用量查询
- [ ] 友好的UI展示
- [ ] 凭证有效期检测

### V1.1 增强版本
- [ ] 自动刷新用量
- [ ] 用量不足告警通知
- [ ] 多账号切换支持
- [ ] 配置导出/导入

### V1.2 高级功能
- [ ] 浏览器自动登录获取凭证（免手动复制curl）
- [ ] 用量统计和历史趋势
- [ ] 智能使用建议
- [ ] 多平台统一账号同步

---

## ⚠️ 避坑指南
1. **Cookie编码问题**：`connect.sid`开头的`s%3A`是URL编码的`s:`，不要解码，直接原封不动使用
2. **CSRF双校验**：必须同时在Cookie和请求头中带CSRF Token，且值完全一致
3. **请求频率限制**：接口不要请求太频繁，建议最低1分钟一次，避免被限流
4. **凭证安全**：绝对不要明文存储任何凭证信息，务必使用系统密钥链
5. **时区问题**：时间戳都是UTC+8的，显示的时候注意系统时区适配
6. **User-Agent**：请求时建议带正常浏览器UA，避免被WAF拦截

---

## 📦 现有资产清单
| 资产 | 位置 | 说明 |
|------|------|------|
| bash脚本实现 | `/codingplan-query.sh` | 完整可运行的脚本，包含所有核心逻辑 |
| API示例响应 | 本文档 | 完整的JSON响应结构 |
| curl示例 | 本文档 | 可直接运行的curl请求示例 |
| 设计文档 | `/docs/` | 之前的设计和接口分析文档 |
