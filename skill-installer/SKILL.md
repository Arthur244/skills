---
name: "skill-installer"
version: "1.3.1"
description: "安全安装 GitHub 上的 skill。用户直接提供 skill 文件夹链接，AI 执行安全审查和安装。"
author: "system"
permissions:
  files:
    read: ["./.skills/**", "./**/SKILL.md"]
    write: ["./.skills/manifest.json", "./.skills/audit.log", "./<skill-name>/**"]
  network:
    outbound: ["api.github.com:443", "raw.githubusercontent.com:443", "cdn.jsdelivr.net:443"]
  commands: ["curl"]
  env_vars: []
dependencies:
  skills: ["skill-vetter"]
  packages: []
security:
  risk_level: "medium"
  sandbox: false
---

# Skill Installer 🔐

安全优先的 skill 安装协议。用户直接提供 skill 文件夹链接，AI 执行安全审查和安装。

## 调用时机

- 用户提供 GitHub skill 文件夹链接，如：`https://github.com/Arthur244/skills/tree/main/mcp-dockerizer`
- 用户说："帮我安装这个 skill：[URL]"
- 用户说："从这个链接安装 skill"

## 🔄 CDN 回退机制

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

### 智能下载函数

```powershell
function Invoke-SmartDownload {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$Branch,
        [string]$FilePath,
        [string]$OutputPath
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
    
    foreach ($source in $sources) {
        Write-Host "  尝试从 $($source.Name) 下载..." -NoNewline
        
        try {
            # 使用 curl 下载，设置超时和重试
            $result = curl -sL --connect-timeout 10 --max-time 30 "$($source.Url)" -o "$OutputPath" 2>&1
            
            # 检查文件是否下载成功且有内容
            if ((Test-Path $OutputPath) -and ((Get-Item $OutputPath).Length -gt 0)) {
                Write-Host " ✓ 成功"
                return $true
            } else {
                Write-Host " ✗ 失败（空文件）"
                continue
            }
        } catch {
            Write-Host " ✗ 失败（$($_.Exception.Message)）"
            continue
        }
    }
    
    Write-Host "  ❌ 所有下载源均失败"
    return $false
}
```

### 使用示例

```powershell
# 下载 SKILL.md
$downloaded = Invoke-SmartDownload `
    -Owner "Arthur244" `
    -Repo "skills" `
    -Branch "main" `
    -FilePath "skill-installer/SKILL.md" `
    -OutputPath "./skill-installer/SKILL.md"

if (-not $downloaded) {
    Write-Host "❌ 下载失败，请检查网络连接或手动下载"
    exit 1
}
```

## ⚠️ 重要：下载命令规范

**必须使用 `curl` 命令，禁止使用 `Invoke-WebRequest`**（避免权限问题）

```powershell
# ✅ 正确：使用 curl（推荐）
curl -sL "https://raw.githubusercontent.com/OWNER/REPO/BRANCH/SKILL_NAME/SKILL.md" -o "./SKILL_NAME/SKILL.md"

# ❌ 错误：Invoke-WebRequest 可能遇到权限问题
Invoke-WebRequest -Uri "..." -OutFile "..."
```

## 快速安装流程

### Step 0: 确定安装路径（优先询问）

**优先询问客户端默认安装路径**：

```powershell
# 尝试获取客户端默认 skill 安装路径
$defaultSkillPath = $env:SKILL_DEFAULT_PATH

if ($defaultSkillPath) {
    Write-Host "✓ 检测到默认安装路径: $defaultSkillPath"
    $installBasePath = $defaultSkillPath
} else {
    Write-Host "⚠ 未检测到默认安装路径，使用当前目录"
    $installBasePath = "."
}

# 确保安装目录存在
if (-not (Test-Path $installBasePath)) {
    New-Item -ItemType Directory -Path $installBasePath -Force | Out-Null
}
```

**路径优先级**：
1. 环境变量 `SKILL_DEFAULT_PATH`（客户端默认路径）
2. 当前工作目录 `.`（预定义默认路径）

**说明**：
- 如果客户端设置了 `SKILL_DEFAULT_PATH` 环境变量，skill 将安装到该路径
- 如果未设置，则安装到当前工作目录
- 用户也可以在安装时手动指定路径，覆盖默认值

### Step 1: 解析 URL

从用户提供的 URL 中提取信息：

```
URL 格式: https://github.com/OWNER/REPO/tree/BRANCH/SKILL_NAME

示例:
输入: https://github.com/Arthur244/skills/tree/main/mcp-dockerizer
解析: owner=Arthur244, repo=skills, branch=main, skill_name=mcp-dockerizer
```

### Step 2: ⚠️ 强烈建议安装安全审查工具

**重要提示：在安全审查之前，强烈建议先安装 `skill-vetter` 用于审查 skill 的安全性！**

```powershell
# 初始化安全审查能力标志
$script:hasSecurityVetter = $false

# 检查是否已安装 skill-vetter
$vetterPath = Join-Path $installBasePath "skill-vetter/SKILL.md"

if (Test-Path $vetterPath) {
    $script:hasSecurityVetter = $true
    Write-Host ""
    Write-Host "✅ 检测到已安装 skill-vetter，可以继续安全审查。"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗"
    Write-Host "║                                                                  ║"
    Write-Host "║  ⚠️  重要安全提示                                                ║"
    Write-Host "║                                                                  ║"
    Write-Host "║  检测到您尚未安装 skill-vetter 安全审查工具！                    ║"
    Write-Host "║                                                                  ║"
    Write-Host "║  skill-vetter 可以帮助您：                                       ║"
    Write-Host "║  • 检查 skill 来源可信度                                         ║"
    Write-Host "║  • 识别危险信号和可疑模式                                        ║"
    Write-Host "║  • 分析权限范围                                                  ║"
    Write-Host "║  • 对 skill 进行风险等级分类                                     ║"
    Write-Host "║                                                                  ║"
    Write-Host "║  🔒 强烈建议安装此工具以保护您的系统安全！                       ║"
    Write-Host "║                                                                  ║"
    Write-Host "╚══════════════════════════════════════════════════════════════════╝"
    Write-Host ""
    Write-Host "是否现在安装 skill-vetter? (等待30秒，无响应则跳过)"
    Write-Host ""
    
    # 使用异步方式等待用户输入，30秒超时
    $installVetter = $null
    $job = Start-Job -ScriptBlock {
        $input = Read-Host "请输入 Y 确认安装，或输入 N 跳过 (Y/n)"
        return $input
    }
    
    # 等待30秒
    if (Wait-Job $job -Timeout 30) {
        $installVetter = Receive-Job $job
    } else {
        Write-Host ""
        Write-Host "⏱️  30秒内未收到响应，自动跳过安装 skill-vetter"
    }
    Remove-Job $job -Force -ErrorAction SilentlyContinue
    
    if ($installVetter -and $installVetter -ne 'n' -and $installVetter -ne 'N') {
        Write-Host ""
        Write-Host "=========================================="
        Write-Host "  正在安装 skill-vetter..."
        Write-Host "=========================================="
        Write-Host ""
        
        # 创建 skill-vetter 目录
        $vetterDir = Join-Path $installBasePath "skill-vetter"
        New-Item -ItemType Directory -Path $vetterDir -Force | Out-Null
        
        # 确定下载参数
        $downloadOwner = if ($owner) { $owner } else { "Arthur244" }
        $downloadRepo = if ($repo) { $repo } else { "skills" }
        $downloadBranch = if ($branch) { $branch } else { "main" }
        
        Write-Host "下载模板文件..."
        Write-Host "  仓库: $downloadOwner/$downloadRepo"
        Write-Host "  分支: $downloadBranch"
        Write-Host ""
        
        # 下载 SKILL.md（使用智能下载函数）
        $result = Invoke-SmartDownload `
            -Owner $downloadOwner `
            -Repo $downloadRepo `
            -Branch $downloadBranch `
            -FilePath "skill-vetter/SKILL.md" `
            -OutputPath "$vetterDir/SKILL.md"
        
        # 下载 README.md
        Invoke-SmartDownload `
            -Owner $downloadOwner `
            -Repo $downloadRepo `
            -Branch $downloadBranch `
            -FilePath "skill-vetter/README.md" `
            -OutputPath "$vetterDir/README.md"
        
        if (Test-Path "$vetterDir/SKILL.md") {
            $script:hasSecurityVetter = $true
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════════╗"
            Write-Host "║                                                                  ║"
            Write-Host "║  ✅ skill-vetter 安装成功！                                      ║"
            Write-Host "║                                                                  ║"
            Write-Host "║  安装位置: $vetterDir"
            Write-Host "║                                                                  ║"
            Write-Host "║  现在您可以安全地审查后续安装的 skill 了！                       ║"
            Write-Host "║                                                                  ║"
            Write-Host "╚══════════════════════════════════════════════════════════════════╝"
            Write-Host ""
        } else {
            Write-Host ""
            Write-Host "╔══════════════════════════════════════════════════════════════════╗"
            Write-Host "║                                                                  ║"
            Write-Host "║  ❌ skill-vetter 安装失败                                        ║"
            Write-Host "║                                                                  ║"
            Write-Host "║  将跳过安全审查步骤，请手动安装后重新运行。                      ║"
            Write-Host "║  URL: https://github.com/Arthur244/skills/tree/main/skill-vetter ║"
            Write-Host "║                                                                  ║"
            Write-Host "╚══════════════════════════════════════════════════════════════════╝"
            Write-Host ""
        }
    } else {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════════════╗"
        Write-Host "║                                                                  ║"
        Write-Host "║  ⚠️  您已选择跳过安装 skill-vetter                               ║"
        Write-Host "║                                                                  ║"
        Write-Host "║  后续将跳过安全审查步骤，无法评估 skill 安全性！                 ║"
        Write-Host "║                                                                  ║"
        Write-Host "║  稍后您可以手动安装：                                            ║"
        Write-Host "║  URL: https://github.com/Arthur244/skills/tree/main/skill-vetter ║"
        Write-Host "║                                                                  ║"
        Write-Host "╚══════════════════════════════════════════════════════════════════╝"
        Write-Host ""
    }
}
```

**下载链接策略**：

skill-vetter 的下载采用智能链接策略：

1. **优先从上下文构建链接**：
   - 如果当前正在从某个仓库安装 skill，会尝试从同一仓库下载 skill-vetter
   - 使用 `$owner/$repo/$branch` 等上下文信息构建链接
   - 自动测试链接可用性

2. **固化后备链接**：
   - 如果上下文链接不可用，使用官方仓库的固化链接
   - **GitHub 页面**: `https://github.com/Arthur244/skills/tree/main/skill-vetter`
   - **SKILL.md 原始文件**: `https://raw.githubusercontent.com/Arthur244/skills/refs/heads/main/skill-vetter/SKILL.md`
   - **README.md 原始文件**: `https://raw.githubusercontent.com/Arthur244/skills/refs/heads/main/skill-vetter/README.md`

3. **CDN 自动回退**：
   - 使用 `Invoke-SmartDownload` 函数自动尝试多个下载源
   - GitHub Raw 失败时自动切换到 jsDelivr CDN
   - 提高下载成功率，解决网络访问问题

**链接格式**：
```
上下文链接: https://raw.githubusercontent.com/{owner}/{repo}/refs/heads/{branch}/skill-vetter/SKILL.md
固化链接:   https://raw.githubusercontent.com/Arthur244/skills/refs/heads/main/skill-vetter/SKILL.md
CDN 回退:   https://cdn.jsdelivr.net/gh/Arthur244/skills@main/skill-vetter/SKILL.md
```

**为什么需要 skill-vetter？**
- 🔒 **安全第一** - 在安装未知来源的 skill 前进行安全检查
- 🛡️ **风险识别** - 自动识别危险信号和可疑模式
- 📊 **权限分析** - 分析 skill 所需的权限范围
- ⚠️ **风险分级** - 对 skill 进行风险等级分类

### Step 3: 安全审查

**检查安全审查能力并执行审查**：

```powershell
# 检查是否有安全审查能力
if ($script:hasSecurityVetter) {
    # 有 skill-vetter，执行安全审查
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "  执行安全审查..."
    Write-Host "=========================================="
    Write-Host ""
    
    # 创建临时目录
    $cachePath = Join-Path $installBasePath ".skills/cache"
    New-Item -ItemType Directory -Path $cachePath -Force

    # 下载 SKILL.md 进行审查（使用智能下载函数，自动 CDN 回退）
    $downloaded = Invoke-SmartDownload `
        -Owner "OWNER" `
        -Repo "REPO" `
        -Branch "BRANCH" `
        -FilePath "SKILL_NAME/SKILL.md" `
        -OutputPath "$cachePath/SKILL_NAME.SKILL.md"

    if (-not $downloaded) {
        Write-Host "❌ 无法下载 SKILL.md，请检查网络连接"
        exit 1
    }
    
    # 读取并审查 SKILL.md 内容
    $skillContent = Get-Content "$cachePath/SKILL_NAME.SKILL.md" -Raw
    
    # 执行安全审查检查清单
    $securityIssues = @()
    
    # 检查敏感目录访问
    if ($skillContent -match '~/.ssh|~/.aws|~/.config') {
        $securityIssues += "访问敏感目录（~/.ssh、~/.aws、~/.config）"
    }
    
    # 检查敏感文件访问
    if ($skillContent -match 'MEMORY\.md|USER\.md|SOUL\.md|IDENTITY\.md') {
        $securityIssues += "访问敏感文件（MEMORY.md、USER.md 等）"
    }
    
    # 检查外部数据发送
    if ($skillContent -match 'Invoke-WebRequest|curl.*-X.*POST|HttpClient') {
        $securityIssues += "可能向外部服务器发送数据"
    }
    
    # 检查凭据请求
    if ($skillContent -match 'credential|token|api.key|password|secret') {
        $securityIssues += "请求凭据/令牌/API 密钥"
    }
    
    # 检查代码混淆
    if ($skillContent -match 'base64|eval\(|exec\(|Invoke-Expression') {
        $securityIssues += "可能包含混淆或动态执行代码"
    }
    
    # 检查权限提升
    if ($skillContent -match 'sudo|runas|Administrator') {
        $securityIssues += "请求提升权限"
    }
    
    # 输出审查结果
    if ($securityIssues.Count -gt 0) {
        Write-Host ""
        Write-Host "╔══════════════════════════════════════════════════════════════════╗"
        Write-Host "║                                                                  ║"
        Write-Host "║  🚨 安全审查发现以下问题：                                       ║"
        Write-Host "║                                                                  ║"
        foreach ($issue in $securityIssues) {
            Write-Host "║  • $issue"
        }
        Write-Host "║                                                                  ║"
        Write-Host "║  ⛔ 建议拒绝安装此 skill                                         ║"
        Write-Host "║                                                                  ║"
        Write-Host "╚══════════════════════════════════════════════════════════════════╝"
        Write-Host ""
        exit 1
    } else {
        Write-Host "✅ 安全审查通过，未发现明显安全问题"
    }
} else {
    # 没有 skill-vetter，跳过安全审查
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════╗"
    Write-Host "║                                                                  ║"
    Write-Host "║  ⚠️  安全审查能力缺失                                            ║"
    Write-Host "║                                                                  ║"
    Write-Host "║  未安装 skill-vetter，无法执行安全审查。                         ║"
    Write-Host "║                                                                  ║"
    Write-Host "║  ⚠️  警告：无法评估此 skill 的安全性！                           ║"
    Write-Host "║                                                                  ║"
    Write-Host "║  建议：                                                          ║"
    Write-Host "║  1. 手动检查 SKILL.md 中的权限声明                               ║"
    Write-Host "║  2. 确认 skill 来源可信                                          ║"
    Write-Host "║  3. 安装 skill-vetter 后重新审查                                 ║"
    Write-Host "║                                                                  ║"
    Write-Host "╚══════════════════════════════════════════════════════════════════╝"
    Write-Host ""
    Write-Host "⏭️  跳过安全审查步骤，继续安装流程..."
    Write-Host ""
}
```

**审查检查清单**：

```
🚨 发现以下情况立即拒绝安装：
─────────────────────────────────────────
• 访问 ~/.ssh、~/.aws、~/.config 等敏感目录
• 访问 MEMORY.md、USER.md、SOUL.md、IDENTITY.md
• 向外部服务器发送数据
• 请求凭据/令牌/API 密钥
• 使用 base64 解码隐藏内容
• 使用 eval() 或 exec() 执行外部输入
• 混淆或压缩的代码
• 请求 sudo/root 权限
─────────────────────────────────────────
```

### Step 4: 获取文件列表

使用 GitHub API 获取 skill 文件列表：

```powershell
# 使用 curl 调用 GitHub API
curl -sH "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/OWNER/REPO/contents/SKILL_NAME?ref=BRANCH"
```

解析返回的 JSON 获取文件名列表。

### Step 5: 执行安装

**创建目录并下载所有文件**：

```powershell
# 创建 skill 目录
$skillName = "SKILL_NAME"
$skillPath = Join-Path $installBasePath $skillName
New-Item -ItemType Directory -Path $skillPath -Force

# 下载 SKILL.md（必需，使用智能下载函数）
$downloaded = Invoke-SmartDownload `
    -Owner "OWNER" `
    -Repo "REPO" `
    -Branch "BRANCH" `
    -FilePath "$skillName/SKILL.md" `
    -OutputPath "$skillPath/SKILL.md"

if (-not $downloaded) {
    Write-Host "❌ 无法下载 SKILL.md"
    exit 1
}

# 下载 README.md（如果存在，使用智能下载函数）
Invoke-SmartDownload `
    -Owner "OWNER" `
    -Repo "REPO" `
    -Branch "BRANCH" `
    -FilePath "$skillName/README.md" `
    -OutputPath "$skillPath/README.md"

# 下载子目录文件（如 templates/）
# 先创建子目录
$templatesPath = Join-Path $skillPath "templates"
New-Item -ItemType Directory -Path $templatesPath -Force

# 下载子目录中的文件（使用智能下载函数）
Invoke-SmartDownload `
    -Owner "OWNER" `
    -Repo "REPO" `
    -Branch "BRANCH" `
    -FilePath "$skillName/templates/Dockerfile.python-uv" `
    -OutputPath "$templatesPath/Dockerfile.python-uv"
```

### Step 6: 记录安装信息

**检查 .gitignore 并创建 .skills 目录**：

```powershell
# 创建 .skills 目录（确保存在）
$skillsDir = Join-Path $installBasePath ".skills"
if (-not (Test-Path $skillsDir)) {
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    Write-Host "✓ 已创建 .skills 目录: $skillsDir"
}

# 检查 .gitignore 中是否包含 .skills/ 忽略规则
$gitignorePath = Join-Path $installBasePath ".gitignore"
$needsGitignoreEntry = $true

if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    if ($gitignoreContent -match '\.skills[/\\]?' -or $gitignoreContent -match '^\.skills$') {
        Write-Host "✓ .gitignore 已包含 .skills/ 忽略规则"
        $needsGitignoreEntry = $false
    }
}

# 如果 .gitignore 中没有 .skills/ 忽略规则，询问用户
if ($needsGitignoreEntry) {
    Write-Host ""
    Write-Host "⚠ 检测到 .gitignore 中未包含 .skills/ 忽略规则"
    Write-Host "  .skills/ 目录包含本地安装的 skill 和审计日志，通常不应提交到版本控制。"
    Write-Host ""
    $addToGitignore = Read-Host "是否将 .skills/ 添加到 .gitignore? (Y/n)"
    
    if ($addToGitignore -ne 'n' -and $addToGitignore -ne 'N') {
        # 确保 .gitignore 文件存在
        if (-not (Test-Path $gitignorePath)) {
            New-Item -ItemType File -Path $gitignorePath -Force | Out-Null
        }
        
        # 添加 .skills/ 到 .gitignore
        Add-Content -Path $gitignorePath -Value "`n# 本地 skill 管理目录（安装时生成）`n.skills/"
        Write-Host "✓ 已将 .skills/ 添加到 .gitignore"
    } else {
        Write-Host "  已跳过添加 .gitignore 规则"
    }
}

# 记录到审计日志
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$auditLogPath = Join-Path $skillsDir "audit.log"

# 确保日志文件路径存在
if (-not (Test-Path $auditLogPath)) {
    # 确保父目录存在
    $auditLogDir = Split-Path $auditLogPath -Parent
    if (-not (Test-Path $auditLogDir)) {
        New-Item -ItemType Directory -Path $auditLogDir -Force | Out-Null
        Write-Host "✓ 已创建日志目录: $auditLogDir"
    }
    # 创建空的日志文件
    New-Item -ItemType File -Path $auditLogPath -Force | Out-Null
    Write-Host "✓ 已创建审计日志文件: $auditLogPath"
}

# 写入日志
"[$timestamp] INSTALL $skillName@VERSION source=URL risk=LEVEL approved=user" | Add-Content $auditLogPath
Write-Host "✓ 已记录安装信息到审计日志"
```

## 完整安装示例

用户输入：`帮我安装 https://github.com/Arthur244/skills/tree/main/mcp-dockerizer`

AI 执行：

```powershell
# === Step 0: 确定安装路径 ===
$defaultSkillPath = $env:SKILL_DEFAULT_PATH
if ($defaultSkillPath) {
    Write-Host "✓ 检测到默认安装路径: $defaultSkillPath"
    $installBasePath = $defaultSkillPath
} else {
    Write-Host "⚠ 未检测到默认安装路径，使用当前目录"
    $installBasePath = "."
}

# === Step 1: 解析 URL ===
# owner=Arthur244, repo=skills, branch=main, skill_name=mcp-dockerizer
$owner = "Arthur244"
$repo = "skills"
$branch = "main"
$skillName = "mcp-dockerizer"

# 构建基础 URL（从上下文）
$rawBase = "https://raw.githubusercontent.com/$owner/$repo/refs/heads/$branch"

# === Step 2: 推荐安装安全审查工具 ===
# 初始化安全审查能力标志
$script:hasSecurityVetter = $false

$vetterPath = Join-Path $installBasePath "skill-vetter/SKILL.md"
if (Test-Path $vetterPath) {
    $script:hasSecurityVetter = $true
    Write-Host "✅ 检测到已安装 skill-vetter"
} else {
    # 提示用户安装，30秒超时
    Write-Host "⚠ 未检测到 skill-vetter，建议安装以进行安全审查"
    # ... 等待用户响应或超时跳过 ...
}

# === Step 3: 安全审查 ===
if ($script:hasSecurityVetter) {
    Write-Host "执行安全审查..."
    $cachePath = Join-Path $installBasePath ".skills/cache"
    New-Item -ItemType Directory -Path $cachePath -Force

    # 使用智能下载函数（自动 CDN 回退）
    $downloaded = Invoke-SmartDownload `
        -Owner $owner `
        -Repo $repo `
        -Branch $branch `
        -FilePath "$skillName/SKILL.md" `
        -OutputPath "$cachePath/$skillName.SKILL.md"

    if (-not $downloaded) {
        Write-Host "❌ 无法下载 SKILL.md 进行审查"
        exit 1
    }

    # 读取并审查 SKILL.md 内容...
    # 确认无危险信号后继续
    Write-Host "✅ 安全审查通过"
} else {
    Write-Host "⚠️ 跳过安全审查（缺少 skill-vetter），无法评估安全性"
}

# === Step 4: 获取文件列表 ===
# 从 GitHub API 或已知结构获取文件列表

# === Step 5: 执行安装 ===
$skillPath = Join-Path $installBasePath $skillName
$templatesPath = Join-Path $skillPath "templates"

New-Item -ItemType Directory -Path $skillPath -Force
New-Item -ItemType Directory -Path $templatesPath -Force

# 使用智能下载函数下载所有文件
Invoke-SmartDownload -Owner $owner -Repo $repo -Branch $branch -FilePath "$skillName/SKILL.md" -OutputPath "$skillPath/SKILL.md"
Invoke-SmartDownload -Owner $owner -Repo $repo -Branch $branch -FilePath "$skillName/README.md" -OutputPath "$skillPath/README.md"
Invoke-SmartDownload -Owner $owner -Repo $repo -Branch $branch -FilePath "$skillName/templates/Dockerfile.python-uv" -OutputPath "$templatesPath/Dockerfile.python-uv"
Invoke-SmartDownload -Owner $owner -Repo $repo -Branch $branch -FilePath "$skillName/templates/Dockerfile.python-pip" -OutputPath "$templatesPath/Dockerfile.python-pip"
Invoke-SmartDownload -Owner $owner -Repo $repo -Branch $branch -FilePath "$skillName/templates/Dockerfile.nodejs" -OutputPath "$templatesPath/Dockerfile.nodejs"

# === Step 6: 记录安装 ===
$skillsDir = Join-Path $installBasePath ".skills"

# 确保 .skills 目录存在
if (-not (Test-Path $skillsDir)) {
    New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null
    Write-Host "✓ 已创建 .skills 目录: $skillsDir"
}

# 检查 .gitignore
$gitignorePath = Join-Path $installBasePath ".gitignore"
if ((Test-Path $gitignorePath) -and ((Get-Content $gitignorePath -Raw) -match '\.skills[/\\]?')) {
    Write-Host "✓ .gitignore 已包含 .skills/ 忽略规则"
} else {
    Write-Host "⚠ 建议将 .skills/ 添加到 .gitignore"
    # 询问用户是否添加...
}

# 记录到审计日志
$auditLogPath = Join-Path $skillsDir "audit.log"

# 确保日志文件路径存在
if (-not (Test-Path $auditLogPath)) {
    # 确保父目录存在
    $auditLogDir = Split-Path $auditLogPath -Parent
    if (-not (Test-Path $auditLogDir)) {
        New-Item -ItemType Directory -Path $auditLogDir -Force | Out-Null
        Write-Host "✓ 已创建日志目录: $auditLogDir"
    }
    # 创建空的日志文件
    New-Item -ItemType File -Path $auditLogPath -Force | Out-Null
    Write-Host "✓ 已创建审计日志文件: $auditLogPath"
}

"[2026-04-01T19:00:00Z] INSTALL mcp-dockerizer@1.0.0 source=https://github.com/Arthur244/skills/tree/main/mcp-dockerizer risk=medium approved=user" | Add-Content $auditLogPath
Write-Host "✓ 已记录安装信息到审计日志"
```

## curl 命令参数说明

| 参数 | 说明 |
|------|------|
| `-s` | 静默模式，不显示进度 |
| `-L` | 跟随重定向 |
| `-o` | 输出到文件 |
| `-H` | 添加请求头（用于 API） |

## 常见 skill 文件结构

```
skill-name/
├── SKILL.md          # 必需：Skill 定义
├── README.md         # 可选：说明文档
└── templates/        # 可选：模板文件
    └── *.template
```

## 风险等级处理

| 风险等级 | 处理方式 |
|----------|----------|
| 🟢 LOW | 审查通过后直接安装 |
| 🟡 MEDIUM | 展示权限需求，用户确认后安装 |
| 🔴 HIGH | 强烈警告，需用户明确批准 |
| ⛔ EXTREME | 拒绝安装 |

## 输出格式

### 安装成功

```
✅ Skill 安装成功
═══════════════════════════════════════
Skill: mcp-dockerizer@1.0.0
来源: https://github.com/Arthur244/skills/tree/main/mcp-dockerizer
位置: ./mcp-dockerizer/
文件: 5 个
风险等级: 🟡 MEDIUM
═══════════════════════════════════════
```

### 安装拒绝

```
❌ Skill 安装被拒绝
═══════════════════════════════════════
Skill: suspicious-skill
拒绝原因: 检测到访问敏感目录 ~/.ssh
═══════════════════════════════════════
```

## 记住

1. **优先使用默认路径** - 检查 `SKILL_DEFAULT_PATH` 环境变量
2. **使用智能下载函数** - 自动 CDN 回退，提高下载成功率
3. **先审查后安装** - 安全第一
4. **推荐安装 skill-vetter** - 用于审查后续 skill 的安全性
5. **记录审计日志** - 可追溯
6. **告知用户风险** - 透明

---

*Security is not negotiable.* 🔐
