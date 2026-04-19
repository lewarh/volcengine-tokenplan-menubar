# OpenCLI 能力设计

## 功能目标
提供简洁易用的命令行工具，实现用量查询、账号管理、用量激活等功能，支持集成到其他工作流中。

## 命令结构
```
codingplan-usage
├── query       # 查询用量
├── login       # CDP自助登录
├── config      # 配置管理
│   ├── add     # 添加账号
│   ├── remove  # 删除账号
│   ├── list    # 列出所有账号
│   └── set-default # 设置默认账号
├── activate    # 手动激活用量（触发接口调用更新计时）
├── status      # 显示状态栏信息（用于集成到菜单栏/状态栏）
└── version     # 显示版本信息
```

## 详细命令设计

### 1. query 命令
**功能**: 查询账号用量
**用法**:
```bash
# 查询默认账号用量
codingplan-usage query

# 查询指定账号用量
codingplan-usage query --account "公司账号"

# 查询所有账号用量
codingplan-usage query --all

# 输出JSON格式（用于脚本集成）
codingplan-usage query --json

# 简洁输出（用于状态栏显示）
codingplan-usage query --short
```

**输出示例**:
```
📊 用量查询结果
────────────────────────────────────────
账号: 个人火山账号
套餐类型: 专业版 (5小时/周)
总配额: 5.0 小时
已使用: 2.3 小时
剩余: 2.7 小时
使用率: 46.0%
周使用进度: ■■■■□□□ 46%
到期时间: 2026-04-20 12:54:20
状态: ✅ 正常
────────────────────────────────────────
智能建议: 本周剩余2.7小时，建议平均每天使用0.9小时，可在周末前用完配额。
```

**短输出（状态栏用）**:
```
💻 个人: 2.7h/5h (46%) | 🏢 公司: 12.5h/20h (62%)
```

### 2. login 命令
**功能**: 启动CDP自助登录流程
**用法**:
```bash
# 登录并自动命名账号
codingplan-usage login

# 登录并指定账号名称
codingplan-usage login --name "个人账号"

# 登录并设置为默认账号
codingplan-usage login --name "公司账号" --default
```

### 3. config 命令
**功能**: 配置管理
**用法**:
```bash
# 列出所有账号
codingplan-usage config list

# 添加账号（手动配置模式）
codingplan-usage config add --name "个人账号" \
  --connect-sid "xxx" \
  --digest "xxx" \
  --csrf-token "xxx"

# 删除账号
codingplan-usage config remove "个人账号"

# 设置默认账号
codingplan-usage config set-default "公司账号"

# 显示配置文件路径
codingplan-usage config path
```

### 4. activate 命令
**功能**: 手动激活用量，触发接口调用更新计时（解决idle期间不更新的问题）
**用法**:
```bash
# 激活默认账号
codingplan-usage activate

# 激活指定账号
codingplan-usage activate --account "个人账号"

# 激活所有账号
codingplan-usage activate --all

# 定时激活（每小时一次）
codingplan-usage activate --daemon --interval 3600
```

### 5. status 命令
**功能**: 输出状态栏格式的信息，用于集成到系统菜单栏、状态栏等
**用法**:
```bash
# 默认输出，适合大部分状态栏
codingplan-usage status

# 输出适合yabai/sketchybar的格式
codingplan-usage status --format sketchybar

# 输出适合ubersicht的格式
codingplan-usage status --format ubersicht

# 输出JSON格式
codingplan-usage status --json
```

### 6. 全局参数
```bash
# 指定配置文件路径
--config ~/.codingplan-usage.yaml

# 静默模式，不输出多余信息
--quiet

# 调试模式，输出详细日志
--debug
```

## 集成能力
### 1. 状态栏集成
- **macOS**: 支持集成到sketchybar、iBar、BitBar等
- **Windows**: 支持集成到系统托盘
- **Linux**: 支持集成到polybar等

### 2. 脚本集成
所有命令都支持JSON输出，方便脚本调用：
```bash
# 获取剩余用量
remaining=$(codingplan-usage query --json | jq -r '.remaining')

# 使用率低于10%发送通知
if (( $(echo "$remaining < 0.5" | bc -l) )); then
  osascript -e 'display notification "用量即将耗尽，请及时切换账号" with title "CodingPlan 提醒"'
fi
```

### 3. 定时任务
支持作为定时任务运行，自动提醒用量状态：
```bash
# crontab 示例：每小时检查一次用量
0 * * * * /usr/local/bin/codingplan-usage query --quiet --alert-threshold 10
```

## 智能建议算法
根据套餐类型和使用情况，提供个性化建议：
1. **5小时周套餐**: 计算周使用率，给出每日使用建议
2. **月度套餐**: 计算日均使用量，提醒是否会超额
3. **用量不足10%**: 强烈提醒及时切换账号
4. **快到期时**: 提醒套餐即将到期，及时续费或更换
