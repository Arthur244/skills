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
New-Item -ItemType Directory -Path "./.skills/cache" -Force

# 下载 SKILL.md 进行审查（使用 curl）
curl -sL "https://raw.githubusercontent.com/OWNER/REPO/BRANCH/SKILL_NAME/SKILL.md" -o "./.skills/cache/SKILL_NAME.SKILL.md"
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
New-Item -ItemType Directory -Path "./$skillName" -Force

# 下载 SKILL.md（必需）
curl -sL "https://raw.githubusercontent.com/OWNER/REPO/BRANCH/$skillName/SKILL.md" -o "./$skillName/SKILL.md"

# 下载 README.md（如果存在）
curl -sL "https://raw.githubusercontent.com/OWNER/REPO/BRANCH/$skillName/README.md" -o "./$skillName/README.md"

# 下载子目录文件（如 templates/）
# 先创建子目录
New-Item -ItemType Directory -Path "./$skillName/templates" -Force

# 下载子目录中的文件
curl -sL "https://raw.githubusercontent.com/OWNER/REPO/BRANCH/$skillName/templates/Dockerfile.python-uv" -o "./$skillName/templates/Dockerfile.python-uv"
```

### Step 5: 记录安装信息

```powershell
# 创建 .skills 目录
New-Item -ItemType Directory -Path "./.skills" -Force

# 记录到审计日志
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
"[$timestamp] INSTALL $skillName@VERSION source=URL risk=LEVEL approved=user" | Add-Content "./.skills/audit.log"
```

## 完整安装示例

用户输入：`帮我安装 https://github.com/Arthur244/skills/tree/main/mcp-dockerizer`

AI 执行：

```powershell
# === Step 1: 解析 URL ===
# owner=Arthur244, repo=skills, branch=main, skill_name=mcp-dockerizer

# === Step 2: 安全审查 ===
New-Item -ItemType Directory -Path "./.skills/cache" -Force
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/SKILL.md" -o "./.skills/cache/mcp-dockerizer.SKILL.md"

# 读取并审查 SKILL.md 内容...
# 确认无危险信号后继续

# === Step 3: 获取文件列表 ===
# 从 GitHub API 或已知结构获取文件列表

# === Step 4: 执行安装 ===
New-Item -ItemType Directory -Path "./mcp-dockerizer" -Force
New-Item -ItemType Directory -Path "./mcp-dockerizer/templates" -Force

curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/SKILL.md" -o "./mcp-dockerizer/SKILL.md"
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/README.md" -o "./mcp-dockerizer/README.md"
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/templates/Dockerfile.python-uv" -o "./mcp-dockerizer/templates/Dockerfile.python-uv"
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/templates/Dockerfile.python-pip" -o "./mcp-dockerizer/templates/Dockerfile.python-pip"
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/templates/Dockerfile.nodejs" -o "./mcp-dockerizer/templates/Dockerfile.nodejs"

# === Step 5: 记录安装 ===
New-Item -ItemType Directory -Path "./.skills" -Force
"[2026-04-01T19:00:00Z] INSTALL mcp-dockerizer@1.0.0 source=https://github.com/Arthur244/skills/tree/main/mcp-dockerizer risk=medium approved=user" | Add-Content "./.skills/audit.log"
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

1. **必须使用 curl** - 避免权限问题
2. **先审查后安装** - 安全第一
3. **记录审计日志** - 可追溯
4. **告知用户风险** - 透明

---

*Security is not negotiable.* 🔐
