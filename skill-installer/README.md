# Skill Installer 🔐

安全优先的 skill 安装工具。用户直接提供文件夹 URL，AI 使用 curl 执行安全审查和安装。

## 功能概述

- **智能路径选择** - 优先使用客户端默认安装路径
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
3. 下载并审查 SKILL.md
4. 检查危险信号
5. 下载所有文件
6. 记录安装日志

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
│ 安全审查    │─── 危险信号 ──→ 拒绝安装
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Step 3:     │
│ 获取文件    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Step 4:     │
│ 下载安装    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Step 5:     │
│ 记录日志    │
└─────────────┘
```

## 相关文件

- `.skills/manifest.json` - 已安装 skill 清单
- `.skills/audit.log` - 审计日志

## 相关 Skill

- [skill-vetter](../skill-vetter) - 安全审查工具
