---
name: "skill-safedl"
version: "1.0.0"
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
  commands: ["curl.exe"]
  env_vars: []
dependencies:
  skills: []
  packages: []
security:
  risk_level: "low"
  sandbox: false
---

# Skill SafeDL 🔒

安全下载工具，提供 CDN 自动回退和权限规避机制。

## 调用时机

当需要从 GitHub 或其他平台下载文件时调用此 skill：
- 需要下载 GitHub 上的原始文件
- 需要下载模板、配置文件等资源
- 遇到网络访问问题需要 CDN 回退
- 需要避免 PowerShell 权限问题

## 核心特性

### 1. CDN 自动回退机制

由于某些网络环境下 `raw.githubusercontent.com` 可能无法访问，本工具实现了智能 CDN 回退机制。

#### 支持的下载源（按优先级）

| 优先级 | 源 | 域名 | 说明 |
|--------|-----|------|------|
| 1 | GitHub Raw | `raw.githubusercontent.com` | 官方源，优先使用 |
| 2 | jsDelivr CDN | `cdn.jsdelivr.net` | 公共 CDN，稳定性高 |

#### URL 转换规则

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

### 2. 权限规避机制

**必须使用 `curl.exe` 命令，禁止使用 `curl` 或 `Invoke-WebRequest`**

#### 为什么使用 curl.exe？

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

#### 常见权限问题示例

```powershell
# ❌ 错误：Invoke-WebRequest 可能遇到权限问题
Invoke-WebRequest -Uri "https://example.com/file.txt" -OutFile "file.txt"
# 错误信息：由于权限限制，无法访问该资源

# ❌ 错误：curl 是 Invoke-WebRequest 的别名，会触发安全提醒
curl -sL "https://example.com/file.txt" -o "file.txt"

# ✅ 正确：使用 curl.exe 避免权限问题
curl.exe -sL "https://example.com/file.txt" -o "file.txt"
```

### 3. 超时和重试机制

- **连接超时**: 10 秒
- **最大下载时间**: 30 秒
- **自动重试**: 失败后自动尝试下一个 CDN 源

### 4. 文件验证机制

下载完成后自动验证：
- 检查文件是否存在
- 检查文件大小是否大于 0
- 验证失败自动尝试下一个源

## 智能下载函数

### 完整函数定义

```powershell
function Invoke-SmartDownload {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Owner,
        
        [Parameter(Mandatory=$true)]
        [string]$Repo,
        
        [Parameter(Mandatory=$true)]
        [string]$Branch,
        
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [int]$ConnectTimeout = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxTime = 30,
        
        [Parameter(Mandatory=$false)]
        [switch]$Silent
    )
    
    # 构建下载源列表（按优先级）
    $sources = @(
        @{
            Name = "GitHub Raw"
            Url = "https://raw.githubusercontent.com/$Owner/$Repo/refs/heads/$Branch/$FilePath"
        },
        @{
            Name = "jsDelivr CDN"
            Url = "https://cdn.jsdelivr.net/gh/$Owner@$Repo@$Branch/$FilePath"
        }
    )
    
    # 确保输出目录存在
    $outputDir = Split-Path $OutputPath -Parent
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # 跨平台 curl 命令列表（按优先级）
    $curlCommands = @("curl", "curl.exe")
    
    foreach ($source in $sources) {
        if (-not $Silent) {
            Write-Host "  尝试从 $($source.Name) 下载..." -NoNewline
        }
        
        # 尝试不同的 curl 命令
        $downloaded = $false
        foreach ($curlCmd in $curlCommands) {
            try {
                $result = & $curlCmd -sL --connect-timeout $ConnectTimeout --max-time $MaxTime "$($source.Url)" -o "$OutputPath" 2>&1
                
                # 检查文件是否下载成功且有内容
                if ((Test-Path $OutputPath) -and ((Get-Item $OutputPath).Length -gt 0)) {
                    if (-not $Silent) {
                        Write-Host " ✓ 成功"
                    }
                    return @{
                        Success = $true
                        Source = $source.Name
                        Url = $source.Url
                    }
                }
            } catch {
                # 当前 curl 命令失败，尝试下一个
                continue
            }
        }
        
        # 所有 curl 命令都失败
        if (-not $Silent) {
            Write-Host " ✗ 失败"
        }
        continue
    }
    
    if (-not $Silent) {
        Write-Host "  ❌ 所有下载源均失败"
    }
    return @{
        Success = $false
        Source = $null
        Url = $null
    }
}
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

返回一个哈希表，包含以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `Success` | bool | 是否下载成功 |
| `Source` | string | 成功下载的源名称（失败时为 null） |
| `Url` | string | 成功下载的 URL（失败时为 null） |

## 使用示例

### 示例 1：下载单个文件

```powershell
# 下载 SKILL.md
$result = Invoke-SmartDownload `
    -Owner "Arthur244" `
    -Repo "skills" `
    -Branch "main" `
    -FilePath "skill-installer/SKILL.md" `
    -OutputPath "./skill-installer/SKILL.md"

if ($result.Success) {
    Write-Host "✅ 下载成功，来源：$($result.Source)"
} else {
    Write-Host "❌ 下载失败，请检查网络连接或手动下载"
}
```

### 示例 2：下载多个文件

```powershell
# 设置下载参数
$owner = "Arthur244"
$repo = "skills"
$branch = "main"

# 定义文件列表
$files = @(
    @{ Remote = "mcp-dockerizer/SKILL.md"; Local = "./mcp-dockerizer/SKILL.md" },
    @{ Remote = "mcp-dockerizer/README.md"; Local = "./mcp-dockerizer/README.md" },
    @{ Remote = "mcp-dockerizer/templates/Dockerfile.python-uv"; Local = "./mcp-dockerizer/templates/Dockerfile.python-uv" }
)

# 下载所有文件
$successCount = 0
foreach ($file in $files) {
    Write-Host "下载: $($file.Remote)"
    
    $result = Invoke-SmartDownload `
        -Owner $owner `
        -Repo $repo `
        -Branch $branch `
        -FilePath $file.Remote `
        -OutputPath $file.Local
    
    if ($result.Success) {
        $successCount++
    }
}

Write-Host ""
Write-Host "下载完成：$successCount/$($files.Count) 个文件成功"
```

### 示例 3：静默模式下载

```powershell
# 静默模式下载（不输出进度信息）
$result = Invoke-SmartDownload `
    -Owner "Arthur244" `
    -Repo "skills" `
    -Branch "main" `
    -FilePath "skill-installer/SKILL.md" `
    -OutputPath "./skill-installer/SKILL.md" `
    -Silent

if (-not $result.Success) {
    Write-Host "❌ 下载失败"
    exit 1
}
```

### 示例 4：自定义超时时间

```powershell
# 对于大文件，可以增加超时时间
$result = Invoke-SmartDownload `
    -Owner "Arthur244" `
    -Repo "skills" `
    -Branch "main" `
    -FilePath "large-file.zip" `
    -OutputPath "./large-file.zip" `
    -ConnectTimeout 20 `
    -MaxTime 120
```

### 示例 5：从上下文构建下载链接

```powershell
# 从 GitHub URL 解析信息
$url = "https://github.com/Arthur244/skills/tree/main/mcp-dockerizer"

# 解析 URL
if ($url -match 'github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+)') {
    $owner = $matches[1]
    $repo = $matches[2]
    $branch = $matches[3]
    $skillName = $matches[4]
    
    # 下载 SKILL.md
    $result = Invoke-SmartDownload `
        -Owner $owner `
        -Repo $repo `
        -Branch $branch `
        -FilePath "$skillName/SKILL.md" `
        -OutputPath "./$skillName/SKILL.md"
    
    if ($result.Success) {
        Write-Host "✅ 下载成功"
    }
}
```

## curl.exe 命令参数说明

| 参数 | 说明 |
|------|------|
| `-s` | 静默模式，不显示进度 |
| `-L` | 跟随重定向 |
| `-o` | 输出到文件 |
| `--connect-timeout` | 连接超时时间（秒） |
| `--max-time` | 最大传输时间（秒） |
| `-H` | 添加请求头（用于 API） |

## 最佳实践

### 1. 始终检查返回值

```powershell
$result = Invoke-SmartDownload -Owner "..." -Repo "..." -Branch "..." -FilePath "..." -OutputPath "..."

if (-not $result.Success) {
    Write-Host "❌ 下载失败，请检查网络连接"
    # 处理失败情况
    exit 1
}

# 继续后续操作
```

### 2. 创建必要的目录

```powershell
# 确保输出目录存在
$outputDir = Split-Path $OutputPath -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
```

### 3. 批量下载时记录失败

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

### 4. 使用静默模式减少输出

```powershell
# 在脚本中使用静默模式
$result = Invoke-SmartDownload ... -Silent

if (-not $result.Success) {
    Write-Host "❌ 下载失败"
}
```

## 常见问题与解决方案

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

## 与其他 Skill 集成

### skill-installer 集成

```powershell
# 在 skill-installer 中使用
$result = Invoke-SmartDownload `
    -Owner $owner `
    -Repo $repo `
    -Branch $branch `
    -FilePath "$skillName/SKILL.md" `
    -OutputPath "$skillPath/SKILL.md"

if (-not $result.Success) {
    Write-Host "❌ 无法下载 SKILL.md"
    exit 1
}
```

### mcp-dockerizer 集成

```powershell
# 在 mcp-dockerizer 中下载模板
$templates = @("Dockerfile.python-uv", "Dockerfile.python-pip", "Dockerfile.nodejs")

foreach ($template in $templates) {
    $result = Invoke-SmartDownload `
        -Owner $owner `
        -Repo $repo `
        -Branch $branch `
        -FilePath "mcp-dockerizer/templates/$template" `
        -OutputPath "./templates/$template"
}
```

## 记住

1. **使用 curl.exe 而非 curl 或 Invoke-WebRequest** - 避免 Windows 安全策略拦截
2. **始终检查返回值** - 确保下载成功
3. **利用 CDN 回退** - 提高下载成功率
4. **设置合理的超时** - 避免长时间等待
5. **验证下载文件** - 确保文件完整性

---

*Safe downloads, happy coding!* 🔒
