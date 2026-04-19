# Phase 1: 基础查询能力 SPEC

## 阶段目标
完成火山CodingPlan用量查询的核心功能，实现从接口分析到命令行查询的完整流程。

## 核心任务
### 1. 接口分析与授权调研
#### 1.1 火山CodingPlan接口分析
- 目标：获取完整的查询API接口信息
- 输入：用户提供的curl请求示例
- 输出：
  - 接口地址
  - 请求方法
  - 请求头参数 (特别是授权相关)
  - 请求体格式
  - 响应数据结构
  - 错误码说明

#### 1.2 授权方式分析
- 认证方式识别 (API Key / Token / Cookie / OAuth等)
- 令牌有效期分析
- 刷新机制调研
- 安全存储方案设计

### 2. 基础功能实现
#### 2.1 配置管理
- 配置文件格式设计 (YAML/TOML)
- 多账号/多订阅配置支持
- 敏感信息加密存储
- 配置验证逻辑

配置示例：
```yaml
accounts:
  - name: 个人火山账号
    type: codingplan
    api_key: xxxxxx
    secret: xxxxxx
    endpoint: https://xxx.volcengineapi.com
  - name: 公司火山账号
    type: codingplan
    api_key: xxxxxx
    secret: xxxxxx
```

#### 2.2 API客户端实现
- 签名逻辑实现 (火山API签名规范)
- 请求封装与错误处理
- 响应解析与数据结构化
- 重试机制与超时处理

#### 2.3 命令行查询功能
- 基础查询命令：`codingplan-usage query`
- 支持指定账号查询
- 支持查询所有账号
- 格式化输出 (表格/JSON/纯文本)

输出示例：
```
📊 用量查询结果
────────────────────────────────────────
账号: 个人火山账号
套餐类型: 专业版
总用量: 100小时
已使用: 45.5小时
剩余: 54.5小时
使用率: 45.5%
到期时间: 2026-05-19
────────────────────────────────────────
账号: 公司火山账号
套餐类型: 企业版
总用量: 500小时
已使用: 120.3小时
剩余: 379.7小时
使用率: 24.1%
到期时间: 2026-06-30
```

### 3. 数据结构设计
#### 3.1 用量数据结构
```go
type Usage struct {
    AccountName   string    `json:"account_name"`
    PlanType      string    `json:"plan_type"`
    TotalQuota    float64   `json:"total_quota"` // 总配额
    UsedQuota     float64   `json:"used_quota"`  // 已使用
    Remaining     float64   `json:"remaining"`   // 剩余
    UsageRate     float64   `json:"usage_rate"`  // 使用率百分比
    ExpireTime    time.Time `json:"expire_time"` // 到期时间
    LastUpdated   time.Time `json:"last_updated"`// 最后更新时间
    Status        string    `json:"status"`      // 状态: active/expired/exhausted
}
```

#### 3.2 接口响应结构
根据实际API返回定义对应的结构体，包含所有必要字段。

## 验收标准
1. 能够成功配置至少一个火山CodingPlan账号
2. 执行查询命令能够正确返回用量数据
3. 输出格式清晰易读
4. 错误处理完善 (网络错误、授权错误、配额不足等)
5. 代码结构清晰，易于扩展其他平台

## 技术实现要点
- 使用Go标准库为主，尽量减少第三方依赖
- 模块化设计，将API客户端、配置管理、命令行处理分离
- 遵循Go语言编码规范
- 包含基础的单元测试
