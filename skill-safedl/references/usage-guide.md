# SafeDL 使用指南

本文档提供 SafeDL 的详细使用说明和最佳实践。

## 目录

- [CDN 自动回退机制](#cdn-自动回退机制)
- [权限规避机制](#权限规避机制)
- [PowerShell 使用指南](#powershell-使用指南)
- [Bash 使用指南](#bash-使用指南)
- [最佳实践](#最佳实践)
- [常见问题](#常见问题)

## CDN 自动回退机制

由于某些网络环境下 `raw.githubusercontent.com` 可能无法访问，本工具实现了智能 CDN 回退机制。

### 支持的下载源（按优先级）

| 优先级 | 源 | 域名 | 说明 |
|--------|-----|------|------|
| 1 | GitHub Raw | `raw.githubusercontent.com` | 官方源，优先使用 |
| 2 | jsDelivr CDN | `cdn.jsdelivr.net` | 公共 CDN，稳定性高 |

### URL 转换规则

```
GitHub Raw 格式:
https://raw.githubusercontent.com/{owner}/{repo}/refs/heads/{branch}/{path}

jsDelivr CDN 格式:
https://cdn.jsdelivr.net/gh/{owner}/{repo}@{branch}/{path}
```

**示例转换**：
```
原始: https://raw.githubusercontent.com/Arthur244/skills/refs/heads/main/skill-installer/SKILL.md
CDN:  https://cdn.jsdelivr.net/gh/Arthur244/skills@main/skill-installer/SKILL.md
```

## 权限规避机制

### 为什么使用 curl？

| 特性 | curl.exe | curl (别名) | Invoke-WebRequest |
|------|----------|-------------|-------------------|
| Windows 内置 | ✅ Win10+ | ⚠️ 别名 | ✅ |
| 权限问题 | ❌ 无 | ⚠️ 有 | ⚠️ 常见 |
| 执行策略 | ❌ 不需要 | ⚠️ 需要 | ⚠️ 可能受限 |
| 代理支持 | ✅ 自动 | ⚠️ 需配置 | ⚠️ 需配置 |
| 超时控制 | ✅ 简单 | ⚠️ 简单 | ⚠️ 复杂 |
| 重定向跟随 | ✅ 自动 | ⚠️ 自动 | ⚠️ 需配置 |

**重要说明**：
- PowerShell 中 `curl` 是 `Invoke-WebRequest` 的别名，仍会触发安全策略
- 必须使用 `curl.exe`（带 .exe 后缀）才能调用真正的 curl 程序
- `curl.exe` 是跨平台工具，不受 Windows 安全策略限制

### 常见权限问题示例

```powershell
# ❌ 错误：Invoke-WebRequest 可能遇到权限问题
Invoke-WebRequest -Uri "https://example.com/file.txt" -OutFile "file.txt"

# ❌ 错误：curl 是 Invoke-WebRequest 的别名，会触发安全提醒
curl -sL "https://example.com/file.txt" -o "file.txt"

# ✅ 正确：使用 curl.exe 避免权限问题
curl.exe -sL "https://example.com/file.txt" -o "file.txt"
```

## PowerShell 使用指南

### 加载模块

```powershell
# 方法 1：直接加载脚本
. "./scripts/safedl.ps1"

# 方法 2：导入为模块
Import-Module "./scripts/safedl.ps1" -Force
```

### 下载 GitHub 文件

```powershell
# 下载单个文件
$result = Invoke-SmartDownload `
    -Owner "Arthur244" `
    -Repo "skills" `
    -Branch "main" `
    -FilePath "skill-installer/SKILL.md" `
    -OutputPath "./skill-installer/SKILL.md"

if ($result.Success) {
    Write-Host "✅ 下载成功，来源：$($result.Source)"
} else {
    Write-Host "❌ 下载失败"
}
```

### 下载任意 URL

```powershell
# 使用 Get-SmartFile 下载任意 URL
$result = Get-SmartFile `
    -Url "https://example.com/file.txt" `
    -OutputPath "./file.txt"
```

### URL 转换

```powershell
# 将 GitHub Raw URL 转换为 jsDelivr CDN URL
$jsdelivrUrl = ConvertTo-JsDelivrUrl -GitHubRawUrl "https://raw.githubusercontent.com/owner/repo/refs/heads/main/file.txt"
```

### 参数说明

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `$Owner` | string | ✅ | - | GitHub 仓库所有者 |
| `$Repo` | string | ✅ | - | GitHub 仓库名称 |
| `$Branch` | string | ✅ | - | 分支名称 |
| `$FilePath` | string | ✅ | - | 文件路径（相对于仓库根目录） |
| `$OutputPath` | string | ✅ | - | 本地输出路径 |
| `$ConnectTimeout` | int | ❌ | 10 | 连接超时（秒） |
| `$MaxTime` | int | ❌ | 30 | 最大下载时间（秒） |
| `$Silent` | switch | ❌ | false | 静默模式 |

### 返回值

返回一个哈希表：

| 字段 | 类型 | 说明 |
|------|------|------|
| `Success` | bool | 是否下载成功 |
| `Source` | string | 成功下载的源名称（失败时为 null） |
| `Url` | string | 成功下载的 URL（失败时为 null） |

## Bash 使用指南

### 直接执行

```bash
# 下载 GitHub 文件
./scripts/safedl.sh download "Arthur244" "skills" "main" "skill-installer/SKILL.md" "./skill-installer/SKILL.md"

# 下载任意 URL
./scripts/safedl.sh get "https://example.com/file.txt" "./file.txt"

# URL 转换
./scripts/safedl.sh convert "https://raw.githubusercontent.com/owner/repo/refs/heads/main/file.txt"
```

### 作为函数库使用

```bash
# 加载函数
source "./scripts/safedl.sh"

# 调用函数
smart_download "Arthur244" "skills" "main" "skill-installer/SKILL.md" "./output.md"
get_smart_file "https://example.com/file.txt" "./file.txt"
convert_to_jsdelivr_url "https://raw.githubusercontent.com/owner/repo/refs/heads/main/file.txt"
```

### 环境变量配置

```bash
# 设置默认超时时间
export SMARTDL_CONNECT_TIMEOUT=15
export SMARTDL_MAX_TIME=60

# 启用静默模式
export SMARTDL_SILENT=true
```

### 参数说明

| 参数 | 位置 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `owner` | $1 | ✅ | - | GitHub 仓库所有者 |
| `repo` | $2 | ✅ | - | GitHub 仓库名称 |
| `branch` | $3 | ✅ | - | 分支名称 |
| `file_path` | $4 | ✅ | - | 文件路径 |
| `output_path` | $5 | ✅ | - | 本地输出路径 |
| `connect_timeout` | $6 | ❌ | 10 | 连接超时（秒） |
| `max_time` | $7 | ❌ | 30 | 最大下载时间（秒） |
| `silent` | $8 | ❌ | false | 静默模式 |

## 最佳实践

### 1. 始终检查返回值

```powershell
# PowerShell
$result = Invoke-SmartDownload ...
if (-not $result.Success) {
    Write-Host "❌ 下载失败"
    exit 1
}
```

```bash
# Bash
result=$(smart_download ...)
if [[ "$result" != SUCCESS* ]]; then
    echo "❌ 下载失败"
    exit 1
fi
```

### 2. 批量下载时记录失败

```powershell
$failedFiles = @()

foreach ($file in $files) {
    $result = Invoke-SmartDownload ...
    if (-not $result.Success) {
        $failedFiles += $file.Remote
    }
}

if ($failedFiles.Count -gt 0) {
    Write-Host "⚠ 以下文件下载失败："
    $failedFiles | ForEach-Object { Write-Host "  - $_" }
}
```

### 3. 使用静默模式减少输出

```powershell
$result = Invoke-SmartDownload ... -Silent
```

```bash
SMARTDL_SILENT=true smart_download ...
```

### 4. 自定义超时时间

```powershell
# 对于大文件，增加超时时间
$result = Invoke-SmartDownload `
    -ConnectTimeout 20 `
    -MaxTime 120 `
    ...
```

## 常见问题

### 问题 1：所有下载源均失败

**可能原因**：
- 网络连接问题
- 文件路径错误
- 仓库或分支不存在

**解决方案**：
```powershell
# 1. 检查网络连接
Test-Connection "raw.githubusercontent.com"

# 2. 验证 URL 格式
# 确保路径正确：owner/repo/branch/filepath

# 3. 尝试手动下载
# 在浏览器中打开 URL 验证
```

### 问题 2：下载的文件为空

**可能原因**：
- 文件不存在
- 权限问题
- 网络中断

**解决方案**：
```powershell
# 检查文件大小
if ((Get-Item $OutputPath).Length -eq 0) {
    Write-Host "⚠ 文件为空，可能下载失败"
    Remove-Item $OutputPath
}
```

### 问题 3：超时错误

**解决方案**：
```powershell
# 增加超时时间
$result = Invoke-SmartDownload `
    -ConnectTimeout 20 `
    -MaxTime 60 `
    ...
```

## curl 命令参数说明

| 参数 | 说明 |
|------|------|
| `-s` | 静默模式，不显示进度 |
| `-L` | 跟随重定向 |
| `-o` | 输出到文件 |
| `--connect-timeout` | 连接超时时间（秒） |
| `--max-time` | 最大传输时间（秒） |
| `-H` | 添加请求头（用于 API） |
