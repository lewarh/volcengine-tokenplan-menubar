# Volcengine TokenPlan Menubar

一个只做一件事的 macOS 菜单栏应用：  
直接在 menubar 查看火山引擎 TokenPlan / CodingPlan 的用量。

## 功能

- menubar 直接显示 5 小时限制的剩余百分比
- 点击后查看三档配额：
  - 5 小时限制
  - 周限制
  - 总量
- 支持手动刷新
- 支持重新导入 cURL
- 支持删除已导入账号数据
- 仅使用本地私有文件保存导入信息，不走 Keychain 弹窗

## 使用方式

### 1. 获取 cURL

1. 打开火山引擎控制台：
   - `https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?advancedActiveKey=subscribe`
2. 打开浏览器开发者工具
3. 在 `Network` 中搜索：
   - `GetCodingPlanUsage`
4. 找到该请求后，复制它的：
   - `Copy as cURL (bash)`
5. 回到应用，进入导入界面，直接粘贴即可

### 2. 本地运行

```bash
make run
```

### 3. 构建

```bash
make build
```

### 4. 打包 `.app` 和 `.dmg`

```bash
make dmg
```

生成产物：

- `dist/Volcengine TokenPlan Menubar.app`
- `dist/Volcengine-TokenPlan-Menubar.dmg`

## Release

仓库的 GitHub Release 会附带 `.dmg` 安装包。

- 推送 `v*` tag 后，GitHub Actions 会自动构建并上传 DMG
- 当前 release workflow 位于：
  - `.github/workflows/release-dmg.yml`

## 开发

- Swift Package Manager
- macOS 原生 menubar 应用
- 参考开发指令：
  - `VIBE_REFERENCE.md`
