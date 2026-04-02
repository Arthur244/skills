---
name: "skill-installer"
version: "1.2.0"
description: "安全安装 GitHub 上的 skill。用户直接提供 skill 文件夹链接，AI 执行安全审查和安装。"
author: "system"
permissions:
  files:
    read: ["./.skills/**", "./**/SKILL.md"]
    write: ["./.skills/manifest.json", "./.skills/audit.log", "./<skill-name>/**"]
  network:
    outbound: ["api.github.com:443", "raw.githubusercontent.com:443"]
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

### Step 2: 安全审查（必须）

**先下载 SKILL.md 进行审查**：

```powershell
# 创建临时目录
$cachePath = Join-Path $installBasePath ".skills/cache"
New-Item -ItemType Directory -Path $cachePath -Force

# 下载 SKILL.md 进行审查（使用 curl）
curl -sL "https://raw.githubusercontent.com/OWNER/REPO/BRANCH/SKILL_NAME/SKILL.md" -o "$cachePath/SKILL_NAME.SKILL.md"
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

### Step 3: 获取文件列表

使用 GitHub API 获取 skill 文件列表：

```powershell
# 使用 curl 调用 GitHub API
curl -sH "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/OWNER/REPO/contents/SKILL_NAME?ref=BRANCH"
```

解析返回的 JSON 获取文件名列表。

### Step 4: 执行安装

**创建目录并下载所有文件**：

```powershell
# 创建 skill 目录
$skillName = "SKILL_NAME"
$skillPath = Join-Path $installBasePath $skillName
New-Item -ItemType Directory -Path $skillPath -Force

# 下载 SKILL.md（必需）
curl -sL "https://raw.githubusercontent.com/OWNER/REPO/BRANCH/$skillName/SKILL.md" -o "$skillPath/SKILL.md"

# 下载 README.md（如果存在）
curl -sL "https://raw.githubusercontent.com/OWNER/REPO/BRANCH/$skillName/README.md" -o "$skillPath/README.md"

# 下载子目录文件（如 templates/）
# 先创建子目录
$templatesPath = Join-Path $skillPath "templates"
New-Item -ItemType Directory -Path $templatesPath -Force

# 下载子目录中的文件
curl -sL "https://raw.githubusercontent.com/OWNER/REPO/BRANCH/$skillName/templates/Dockerfile.python-uv" -o "$templatesPath/Dockerfile.python-uv"
```

### Step 5: 记录安装信息

```powershell
# 创建 .skills 目录
$skillsDir = Join-Path $installBasePath ".skills"
New-Item -ItemType Directory -Path $skillsDir -Force

# 记录到审计日志
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$auditLogPath = Join-Path $skillsDir "audit.log"
"[$timestamp] INSTALL $skillName@VERSION source=URL risk=LEVEL approved=user" | Add-Content $auditLogPath
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

# === Step 2: 安全审查 ===
$cachePath = Join-Path $installBasePath ".skills/cache"
New-Item -ItemType Directory -Path $cachePath -Force
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/SKILL.md" -o "$cachePath/mcp-dockerizer.SKILL.md"

# 读取并审查 SKILL.md 内容...
# 确认无危险信号后继续

# === Step 3: 获取文件列表 ===
# 从 GitHub API 或已知结构获取文件列表

# === Step 4: 执行安装 ===
$skillPath = Join-Path $installBasePath "mcp-dockerizer"
$templatesPath = Join-Path $skillPath "templates"

New-Item -ItemType Directory -Path $skillPath -Force
New-Item -ItemType Directory -Path $templatesPath -Force

curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/SKILL.md" -o "$skillPath/SKILL.md"
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/README.md" -o "$skillPath/README.md"
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/templates/Dockerfile.python-uv" -o "$templatesPath/Dockerfile.python-uv"
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/templates/Dockerfile.python-pip" -o "$templatesPath/Dockerfile.python-pip"
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/templates/Dockerfile.nodejs" -o "$templatesPath/Dockerfile.nodejs"

# === Step 5: 记录安装 ===
$skillsDir = Join-Path $installBasePath ".skills"
$auditLogPath = Join-Path $skillsDir "audit.log"
New-Item -ItemType Directory -Path $skillsDir -Force
"[2026-04-01T19:00:00Z] INSTALL mcp-dockerizer@1.0.0 source=https://github.com/Arthur244/skills/tree/main/mcp-dockerizer risk=medium approved=user" | Add-Content $auditLogPath
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
2. **必须使用 curl** - 避免权限问题
3. **先审查后安装** - 安全第一
4. **记录审计日志** - 可追溯
5. **告知用户风险** - 透明

---

*Security is not negotiable.* 🔐
