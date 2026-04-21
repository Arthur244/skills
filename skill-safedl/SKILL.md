---
name: "skill-safedl"
version: "1.1.0"
description: "安全下载工具，提供 CDN 自动回退和权限规避机制。用于从 GitHub 等平台安全下载文件。"
author: "Arthur244"
homepage: "https://github.com/Arthur244/skills"
license: "MIT"
permissions:
  files:
    read: []
    write: []
  network:
    outbound: ["raw.githubusercontent.com:443", "cdn.jsdelivr.net:443", "api.github.com:443"]
  commands: ["curl", "curl.exe"]
  env_vars: []
dependencies:
  skills: []
  packages: []
security:
  risk_level: "low"
  sandbox: false
---

# Skill SafeDL

安全下载工具，提供 CDN 自动回退和权限规避机制，支持 Windows/Linux/macOS 多平台。

## 调用时机

当需要从 GitHub 或其他平台下载文件时调用此 skill：
- 需要下载 GitHub 上的原始文件
- 需要下载模板、配置文件等资源
- 遇到网络访问问题需要 CDN 回退
- 需要避免 PowerShell 权限问题

## 核心特性

### 1. CDN 自动回退机制

支持多下载源自动切换：

| 优先级 | 源 | 说明 |
|--------|-----|------|
| 1 | GitHub Raw | 官方源，优先使用 |
| 2 | jsDelivr CDN | 公共 CDN，稳定性高 |

### 2. 跨平台支持

提供两种脚本实现：
- **PowerShell** (`scripts/safedl.ps1`) - Windows 平台
- **Bash** (`scripts/safedl.sh`) - Linux/macOS 平台

### 3. 权限规避

使用 `curl` 命令而非 `Invoke-WebRequest`，避免 Windows 安全策略限制。

## 快速开始

### Windows (PowerShell)

```powershell
# 加载模块
. "./scripts/safedl.ps1"

# 下载文件
$result = Invoke-SmartDownload `
    -Owner "Arthur244" `
    -Repo "skills" `
    -Branch "main" `
    -FilePath "skill-installer/SKILL.md" `
    -OutputPath "./skill-installer/SKILL.md"

if ($result.Success) {
    Write-Host "✅ 下载成功，来源：$($result.Source)"
}
```

### Linux/macOS (Bash)

```bash
# 直接执行
./scripts/safedl.sh download "Arthur244" "skills" "main" "skill-installer/SKILL.md" "./output.md"

# 或作为函数库
source "./scripts/safedl.sh"
smart_download "Arthur244" "skills" "main" "skill-installer/SKILL.md" "./output.md"
```

## 可用函数

### PowerShell 函数

| 函数 | 说明 |
|------|------|
| `Invoke-SmartDownload` | 从 GitHub 下载文件（支持 CDN 回退） |
| `Get-SmartFile` | 从任意 URL 下载文件 |
| `ConvertTo-JsDelivrUrl` | 将 GitHub Raw URL 转换为 jsDelivr CDN URL |

### Bash 函数

| 函数 | 说明 |
|------|------|
| `smart_download` | 从 GitHub 下载文件（支持 CDN 回退） |
| `get_smart_file` | 从任意 URL 下载文件 |
| `convert_to_jsdelivr_url` | 将 GitHub Raw URL 转换为 jsDelivr CDN URL |

## 参数说明

### Invoke-SmartDownload / smart_download

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| Owner | string | ✅ | - | GitHub 仓库所有者 |
| Repo | string | ✅ | - | GitHub 仓库名称 |
| Branch | string | ✅ | - | 分支名称 |
| FilePath | string | ✅ | - | 文件路径 |
| OutputPath | string | ✅ | - | 本地输出路径 |
| ConnectTimeout | int | ❌ | 10 | 连接超时（秒） |
| MaxTime | int | ❌ | 30 | 最大下载时间（秒） |
| Silent | switch | ❌ | false | 静默模式 |

## 返回值

返回包含以下字段的哈希表/字符串：

| 字段 | 类型 | 说明 |
|------|------|------|
| Success | bool | 是否下载成功 |
| Source | string | 成功下载的源名称 |
| Url | string | 成功下载的 URL |

## 最佳实践

1. **始终检查返回值** - 确保下载成功后再进行后续操作
2. **使用静默模式** - 在脚本中减少不必要的输出
3. **设置合理超时** - 对于大文件，增加超时时间
4. **批量下载记录失败** - 便于排查问题

## 详细文档

- [使用指南](references/usage-guide.md) - 详细使用说明和最佳实践
- [README](references/README.md) - 功能概述

## 记住

1. **Windows 使用 curl.exe** - 避免 PowerShell 安全策略拦截
2. **始终检查返回值** - 确保下载成功
3. **利用 CDN 回退** - 提高下载成功率
4. **跨平台兼容** - 选择适合当前系统的脚本
