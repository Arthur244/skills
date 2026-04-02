---
name: "skill-ghdl"
version: "1.0.0"
description: "GitHub 文件智能下载工具，支持 CDN 自动回退，解决 raw.githubusercontent.com 访问受限问题。"
author: "system"
homepage: "https://github.com/Arthur244/skills"
license: "MIT"
permissions:
  files:
    read: []
    write: []
  network:
    outbound: ["raw.githubusercontent.com:443", "cdn.jsdelivr.net:443", "api.github.com:443"]
  commands: ["curl"]
  env_vars: []
dependencies:
  skills: []
  packages: []
security:
  risk_level: "low"
  sandbox: false
---

# GitHub Downloader (skill-ghdl)

智能 GitHub 文件下载工具，支持 CDN 自动回退机制，有效解决 `raw.githubusercontent.com` 在某些网络环境下无法访问的问题。

## 调用时机

- 用户需要从 GitHub 下载单个文件
- 用户说："帮我下载这个 GitHub 文件：[URL]"
- 用户说："从 GitHub 获取文件"
- 其他 skill 需要从 GitHub 下载文件时调用此 skill
- `raw.githubusercontent.com` 访问失败时

## 核心功能

### 🔄 CDN 自动回退机制

当 GitHub Raw 服务无法访问时，自动切换到 jsDelivr CDN，大幅提高下载成功率。

**支持的下载源（按优先级）**：

| 优先级 | 源 | 域名 | 说明 |
|--------|-----|------|------|
| 1 | GitHub Raw | `raw.githubusercontent.com` | 官方源，优先使用 |
| 2 | jsDelivr CDN | `cdn.jsdelivr.net` | 公共 CDN，稳定性高 |

### URL 格式支持

本工具支持以下 URL 格式：

| 格式 | 示例 | 说明 |
|------|------|------|
| GitHub Raw | `https://raw.githubusercontent.com/owner/repo/refs/heads/branch/path/file.md` | 原始文件链接 |
| GitHub Blob | `https://github.com/owner/repo/blob/branch/path/file.md` | GitHub 页面链接 |
| jsDelivr | `https://cdn.jsdelivr.net/gh/owner/repo@branch/path/file.md` | CDN 链接 |

## 智能下载函数

### 核心函数：Invoke-SmartDownload

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
            Url = "https://cdn.jsdelivr.net/gh/$Owner/$Repo@$Branch/$FilePath"
        }
    )
    
    foreach ($source in $sources) {
        if (-not $Silent) {
            Write-Host "  尝试从 $($source.Name) 下载..." -NoNewline
        }
        
        try {
            # 使用 curl 下载，设置超时
            $result = curl -sL --connect-timeout $ConnectTimeout --max-time $MaxTime "$($source.Url)" -o "$OutputPath" 2>&1
            
            # 检查文件是否下载成功且有内容
            if ((Test-Path $OutputPath) -and ((Get-Item $OutputPath).Length -gt 0)) {
                if (-not $Silent) {
                    Write-Host " ✓ 成功"
                }
                return @{
                    Success = $true
                    Source = $source.Name
                    Url = $source.Url
                    OutputPath = $OutputPath
                }
            } else {
                if (-not $Silent) {
                    Write-Host " ✗ 失败（空文件）"
                }
                # 删除空文件
                if (Test-Path $OutputPath) {
                    Remove-Item $OutputPath -Force
                }
                continue
            }
        } catch {
            if (-not $Silent) {
                Write-Host " ✗ 失败（$($_.Exception.Message)）"
            }
            continue
        }
    }
    
    if (-not $Silent) {
        Write-Host "  ❌ 所有下载源均失败"
    }
    return @{
        Success = $false
        Source = $null
        Url = $null
        OutputPath = $OutputPath
        Error = "所有下载源均失败"
    }
}
```

### URL 解析函数：ConvertTo-GitHubInfo

```powershell
function ConvertTo-GitHubInfo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url
    )
    
    $result = @{
        Owner = $null
        Repo = $null
        Branch = $null
        FilePath = $null
        IsValid = $false
    }
    
    # 格式 1: GitHub Raw URL
    # https://raw.githubusercontent.com/owner/repo/refs/heads/branch/path/file.md
    if ($Url -match "raw\.githubusercontent\.com/([^/]+)/([^/]+)/refs/heads/([^/]+)/(.+)") {
        $result.Owner = $matches[1]
        $result.Repo = $matches[2]
        $result.Branch = $matches[3]
        $result.FilePath = $matches[4]
        $result.IsValid = $true
    }
    # 格式 2: GitHub Blob URL
    # https://github.com/owner/repo/blob/branch/path/file.md
    elseif ($Url -match "github\.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)") {
        $result.Owner = $matches[1]
        $result.Repo = $matches[2]
        $result.Branch = $matches[3]
        $result.FilePath = $matches[4]
        $result.IsValid = $true
    }
    # 格式 3: jsDelivr URL
    # https://cdn.jsdelivr.net/gh/owner/repo@branch/path/file.md
    elseif ($Url -match "cdn\.jsdelivr\.net/gh/([^/]+)@([^/@]+)(?:@([^/]+))?/(.+)") {
        $result.Owner = $matches[1]
        # jsDelivr 格式可能是 owner@repo@branch 或 owner/repo@branch
        if ($Url -match "cdn\.jsdelivr\.net/gh/([^/]+)/([^@]+)@([^/]+)/(.+)") {
            $result.Owner = $matches[1]
            $result.Repo = $matches[2]
            $result.Branch = $matches[3]
            $result.FilePath = $matches[4]
        } else {
            $result.Repo = $matches[2]
            $result.Branch = $matches[3]
            $result.FilePath = $matches[4]
        }
        $result.IsValid = $true
    }
    
    return $result
}
```

### 一键下载函数：Invoke-GitHubDownload

```powershell
function Invoke-GitHubDownload {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [int]$ConnectTimeout = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxTime = 30,
        
        [Parameter(Mandatory=$false)]
        [switch]$Silent
    )
    
    # 解析 URL
    $info = ConvertTo-GitHubInfo -Url $Url
    
    if (-not $info.IsValid) {
        Write-Host "❌ 无效的 GitHub URL 格式: $Url"
        return @{ Success = $false; Error = "无效的 URL 格式" }
    }
    
    if (-not $Silent) {
        Write-Host "解析 GitHub URL:"
        Write-Host "  Owner: $($info.Owner)"
        Write-Host "  Repo: $($info.Repo)"
        Write-Host "  Branch: $($info.Branch)"
        Write-Host "  FilePath: $($info.FilePath)"
        Write-Host ""
    }
    
    # 调用智能下载
    return Invoke-SmartDownload `
        -Owner $info.Owner `
        -Repo $info.Repo `
        -Branch $info.Branch `
        -FilePath $info.FilePath `
        -OutputPath $OutputPath `
        -ConnectTimeout $ConnectTimeout `
        -MaxTime $MaxTime `
        -Silent:$Silent
}
```

## 使用示例

### 示例 1：下载单个文件

```powershell
# 下载 SKILL.md 文件
$result = Invoke-GitHubDownload `
    -Url "https://raw.githubusercontent.com/Arthur244/skills/refs/heads/main/skill-installer/SKILL.md" `
    -OutputPath "./skill-installer/SKILL.md"

if ($result.Success) {
    Write-Host "✅ 下载成功，来源: $($result.Source)"
} else {
    Write-Host "❌ 下载失败"
}
```

### 示例 2：批量下载多个文件

```powershell
# 定义要下载的文件列表
$files = @(
    @{
        Url = "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/templates/Dockerfile.python-uv"
        Output = "./templates/Dockerfile.python-uv"
    },
    @{
        Url = "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/templates/Dockerfile.python-pip"
        Output = "./templates/Dockerfile.python-pip"
    },
    @{
        Url = "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/templates/Dockerfile.nodejs"
        Output = "./templates/Dockerfile.nodejs"
    }
)

# 创建输出目录
New-Item -ItemType Directory -Path "./templates" -Force | Out-Null

# 批量下载
$results = @()
foreach ($file in $files) {
    $result = Invoke-GitHubDownload -Url $file.Url -OutputPath $file.Output
    $results += $result
}

# 汇总结果
$successCount = ($results | Where-Object { $_.Success }).Count
Write-Host ""
Write-Host "下载完成: $successCount / $($files.Count) 成功"
```

### 示例 3：使用 GitHub Blob URL

```powershell
# 支持 GitHub 页面链接格式
$result = Invoke-GitHubDownload `
    -Url "https://github.com/Arthur244/skills/blob/main/skill-installer/SKILL.md" `
    -OutputPath "./SKILL.md"
```

### 示例 4：静默模式（用于脚本集成）

```powershell
# 静默模式，不输出任何信息
$result = Invoke-GitHubDownload `
    -Url "https://raw.githubusercontent.com/Arthur244/skills/main/README.md" `
    -OutputPath "./README.md" `
    -Silent

if ($result.Success) {
    # 处理下载成功
} else {
    # 处理下载失败
}
```

## 与其他 Skill 集成

其他 skill 可以通过以下方式集成此下载功能：

### 方法 1：复制函数定义

将 `Invoke-SmartDownload` 和 `ConvertTo-GitHubInfo` 函数复制到目标 skill 中使用。

### 方法 2：直接调用（推荐）

在 skill 中直接使用智能下载函数：

```powershell
# 在 skill 中使用智能下载
$downloaded = Invoke-SmartDownload `
    -Owner "Arthur244" `
    -Repo "skills" `
    -Branch "main" `
    -FilePath "skill-vetter/SKILL.md" `
    -OutputPath "./skill-vetter/SKILL.md"

if (-not $downloaded.Success) {
    Write-Host "❌ 下载失败"
    exit 1
}
```

## URL 转换规则

### GitHub Raw → jsDelivr

```
原始: https://raw.githubusercontent.com/{owner}/{repo}/refs/heads/{branch}/{path}
CDN:  https://cdn.jsdelivr.net/gh/{owner}/{repo}@{branch}/{path}
```

**示例**：
```
原始: https://raw.githubusercontent.com/Arthur244/skills/refs/heads/main/skill-installer/SKILL.md
CDN:  https://cdn.jsdelivr.net/gh/Arthur244/skills@main/skill-installer/SKILL.md
```

### GitHub Blob → GitHub Raw

```
Blob:  https://github.com/{owner}/{repo}/blob/{branch}/{path}
Raw:   https://raw.githubusercontent.com/{owner}/{repo}/refs/heads/{branch}/{path}
```

**示例**：
```
Blob:  https://github.com/Arthur244/skills/blob/main/skill-installer/SKILL.md
Raw:   https://raw.githubusercontent.com/Arthur244/skills/refs/heads/main/skill-installer/SKILL.md
```

## 错误处理

### 常见错误及解决方案

| 错误 | 原因 | 解决方案 |
|------|------|----------|
| 空文件 | 下载被阻止或文件不存在 | 自动切换到 CDN |
| 连接超时 | 网络问题 | 自动切换到 CDN |
| 404 Not Found | 文件路径错误 | 检查 URL 是否正确 |
| 所有源失败 | 网络完全不可用 | 检查网络连接或使用代理 |

### 返回值结构

```powershell
@{
    Success = $true/$false          # 是否成功
    Source = "GitHub Raw"/"jsDelivr CDN"/$null  # 成功的下载源
    Url = "https://..."             # 实际使用的 URL
    OutputPath = "./file.md"        # 输出路径
    Error = "错误信息"               # 失败时的错误信息
}
```

## 最佳实践

1. **优先使用 GitHub Raw URL**：官方源最可靠，CDN 作为后备
2. **设置合理的超时**：默认 10 秒连接超时，30 秒最大下载时间
3. **检查返回值**：始终检查 `Success` 字段确认下载结果
4. **批量下载时使用静默模式**：减少输出干扰
5. **创建目录后再下载**：确保输出目录存在

## 记住

1. **自动回退** - GitHub Raw 失败时自动切换到 jsDelivr CDN
2. **多格式支持** - 支持 GitHub Raw、Blob、jsDelivr 三种 URL 格式
3. **超时控制** - 可配置连接超时和最大下载时间
4. **文件验证** - 自动检查下载文件是否有效
5. **静默模式** - 支持脚本集成时禁用输出
6. **详细返回值** - 返回下载源、URL 等详细信息

---

*Download smarter, not harder.* 🚀
