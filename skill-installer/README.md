# Skill Installer 🔐

安全优先的 skill 安装工具。用户直接提供文件夹 URL，AI 使用 curl 执行安全审查和安装。

## 功能概述

- **智能路径选择** - 优先使用客户端默认安装路径
- **自动 .gitignore 检查** - 检查并提示添加 `.skills/` 忽略规则
- **直接 URL 安装** - 用户直接提供 skill 文件夹链接
- **安全审查** - 自动检测危险信号
- **curl 下载** - 避免 Invoke-WebRequest 权限问题
- **审计日志** - 记录所有安装操作

## 使用方法

### 直接提供 URL 给 AI（推荐）

```
用户: 帮我安装 https://github.com/Arthur244/skills/tree/main/mcp-dockerizer
```

AI 会自动：
1. 确定安装路径（优先使用默认路径）
2. 解析 URL 提取信息
3. **⚠️ 强烈建议安装 skill-vetter 进行安全审查**
4. 下载并审查 SKILL.md
5. 检查危险信号
6. 下载所有文件
7. 检查 .gitignore 并提示添加 `.skills/` 忽略规则
8. 记录安装日志

### 支持的 URL 格式

```
https://github.com/OWNER/REPO/tree/BRANCH/SKILL_NAME
https://github.com/OWNER/REPO/tree/BRANCH/skills/SKILL_NAME
```

### 设置默认安装路径

通过环境变量设置客户端默认安装路径：

```powershell
# Windows PowerShell
$env:SKILL_DEFAULT_PATH = "C:\Skills"

# Linux/macOS
export SKILL_DEFAULT_PATH="/home/user/skills"
```

**路径优先级**：
1. 环境变量 `SKILL_DEFAULT_PATH`（客户端默认路径）
2. 当前工作目录 `.`（预定义默认路径）

### 自动 .gitignore 检查

安装过程中会自动检查 `.gitignore` 文件：

**检查逻辑**：
1. 检查安装目录下是否存在 `.gitignore` 文件
2. 检查 `.gitignore` 中是否已包含 `.skills/` 忽略规则
3. 如果未包含，提示用户是否添加

**为什么需要忽略 `.skills/`**：
- `.skills/` 目录包含本地安装的 skill 和审计日志
- 这些文件是运行时生成的，不应提交到版本控制
- 避免将本地配置和日志污染到远程仓库

**自动添加的内容**：
```gitignore
# 本地 skill 管理目录（安装时生成）
.skills/
```

### ⚠️ 强烈建议安装 skill-vetter

**重要安全提示：安装完成后会强烈建议安装 `skill-vetter` 用于审查后续安装的 skill 的安全性！**

安装过程中会显示醒目的提示框：

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║  ⚠️  重要安全提示                                                ║
║                                                                  ║
║  检测到您尚未安装 skill-vetter 安全审查工具！                    ║
║                                                                  ║
║  skill-vetter 可以帮助您：                                       ║
║  • 检查 skill 来源可信度                                         ║
║  • 识别危险信号和可疑模式                                        ║
║  • 分析权限范围                                                  ║
║  • 对 skill 进行风险等级分类                                     ║
║                                                                  ║
║  🔒 强烈建议安装此工具以保护您的系统安全！                       ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

**skill-vetter 功能**：
- 🔒 **安全第一** - 在安装未知来源的 skill 前进行安全检查
- 🛡️ **风险识别** - 自动识别危险信号和可疑模式
- 📊 **权限分析** - 分析 skill 所需的权限范围
- ⚠️ **风险分级** - 对 skill 进行风险等级分类

**内置下载链接**：
- GitHub: `https://github.com/Arthur244/skills/tree/main/skill-vetter`
- 直接下载: `https://raw.githubusercontent.com/Arthur244/skills/refs/heads/main/skill-vetter/SKILL.md`

**为什么需要安装？**
- 没有安全审查工具，您可能会安装恶意 skill
- skill-vetter 可以帮助识别潜在的安全风险
- 保护您的系统和数据安全

## 为什么使用 curl

**`curl` 比 `Invoke-WebRequest` 更可靠**：

| 特性 | curl | Invoke-WebRequest |
|------|------|-------------------|
| Windows 内置 | ✅ Win10+ | ✅ |
| 权限问题 | ❌ 无 | ⚠️ 常见 |
| 执行策略 | ❌ 不需要 | ⚠️ 可能受限 |
| 代理支持 | ✅ 自动 | ⚠️ 需配置 |

## 安装流程

```
用户提供 URL
     │
     ▼
┌─────────────┐
│ Step 0:     │
│ 确定路径    │─── 检查 SKILL_DEFAULT_PATH
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Step 1:     │
│ 解析 URL    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Step 2:     │
│ 推荐工具    │─── 提示安装 skill-vetter
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Step 3:     │
│ 安全审查    │─── 危险信号 ──→ 拒绝安装
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Step 4:     │
│ 获取文件    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Step 5:     │
│ 下载安装    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Step 6:     │
│ 记录日志    │
└─────────────┘
```

## 相关文件

- `.skills/manifest.json` - 已安装 skill 清单
- `.skills/audit.log` - 审计日志

## 相关 Skill

- [skill-vetter](../skill-vetter) - 安全审查工具
