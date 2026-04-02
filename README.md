# Skills

AI 辅助工具技能集合，用于扩展 AI 编程助手的能力。

## 概述

本仓库是一个 **Skill 分发中心**，包含多个可复用的 skill 定义。其他工具和用户可以从此仓库安全地下载和安装 skill。

## 可用 Skills

| Skill | 风险等级 | 描述 |
|-------|----------|------|
| [skill-creator](./skill-template) | 🟢 低 | 快速创建标准化的 skill |
| [skill-installer](./skill-installer) | 🟡 中 | 安全安装 GitHub 上的 skill |
| [skill-vetter](./skill-vetter) | 🟢 低 | 安全优先的 AI 代理技能审查工具 |
| [mcp-dockerizer](./mcp-dockerizer) | 🟡 中 | 将本地 MCP 服务转换为 Docker 部署 |

### skill-creator

快速创建标准化的 skill，基于模板生成 SKILL.md 和 README.md。

**核心特性**：
- 模板化创建 - 基于标准模板生成 skill 文件
- 交互式引导 - 收集必要信息并生成完整 skill
- 自动索引 - 更新 skills-index.json
- 权限配置 - 根据功能自动设置权限

### skill-installer

安全优先的 skill 安装工具，自动审查来源、验证权限、记录安装日志。

**核心特性**：
- 来源验证 - 评估来源可信度
- 代码审查 - 自动检测危险信号
- 权限验证 - 检查权限是否合规
- 审计日志 - 记录所有安装操作

### skill-vetter

安全优先的 AI 代理技能审查工具，在安装任何 skill 之前进行安全检查。

**核心特性**：
- 来源检查 - 评估 skill 的来源可信度
- 代码审查 - 识别危险信号和可疑模式
- 权限评估 - 分析 skill 所需的权限范围
- 风险分级 - 对 skill 进行风险等级分类

### mcp-dockerizer

将本地部署的 MCP（Model Context Protocol）服务转换为 Docker 部署，同时保持功能完全一致。

**核心特性**：
- 支持 Node.js、Python (pip/poetry/uv) 等主流运行时
- 采用 Multi-stage Build，镜像体积减少 50%-80%
- 提供完整的 Dockerfile、docker-compose.yml 模板
- 包含 MCP 客户端配置更新指南

## 安装方法

### 方法一：直接提供 URL 给 AI（推荐）

直接将 skill 文件夹链接发给 AI，AI 会自动执行安全审查和安装：

```
用户: 帮我安装 https://github.com/Arthur244/skills/tree/main/mcp-dockerizer

AI 会自动：
1. 解析 URL 提取信息
2. 下载并审查 SKILL.md
3. 检查危险信号
4. 下载所有文件
5. 记录安装日志
```

**支持的 URL 格式**：
```
https://github.com/OWNER/REPO/tree/BRANCH/SKILL_NAME
https://github.com/OWNER/REPO/tree/BRANCH/skills/SKILL_NAME
```

**示例链接**：
- mcp-dockerizer: `https://github.com/Arthur244/skills/tree/main/mcp-dockerizer`
- skill-vetter: `https://github.com/Arthur244/skills/tree/main/skill-vetter`
- skill-installer: `https://github.com/Arthur244/skills/tree/main/skill-installer`

### 方法二：使用安装脚本

如果已有 install.ps1 脚本：

```powershell
# 使用完整 URL 安装
.\install.ps1 "https://github.com/Arthur244/skills/tree/main/mcp-dockerizer"

# 仅审查不安装
.\install.ps1 "https://github.com/Arthur244/skills/tree/main/mcp-dockerizer" -DryRun
```

### 方法三：使用 curl 直接下载

```powershell
# 创建目录
New-Item -ItemType Directory -Path "./mcp-dockerizer" -Force

# 下载 SKILL.md（使用 curl 避免 Invoke-WebRequest 权限问题）
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/SKILL.md" -o "./mcp-dockerizer/SKILL.md"

# 下载 README.md
curl -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/README.md" -o "./mcp-dockerizer/README.md"
```

## 仓库结构

```
skills/
├── schemas/                      # JSON Schema 验证文件
│   ├── skill-metadata.json       # SKILL.md 元数据格式
│   └── skills-index.json         # 索引文件格式
│
├── skill-template/               # Skill 模板文件
│   ├── SKILL.md.template         # SKILL.md 模板
│   └── README.md                 # 模板使用说明
│
├── skill-installer/              # 安装工具 skill
│   ├── SKILL.md
│   └── README.md
│
├── skill-vetter/                 # 审查工具 skill
│   ├── SKILL.md
│   └── README.md
│
├── mcp-dockerizer/               # Docker 化工具 skill
│   ├── SKILL.md
│   ├── README.md
│   └── templates/
│
├── skills-index.json             # 公开索引文件
├── install.ps1                   # 安装脚本
└── README.md
```

## SKILL.md 元数据格式

```yaml
---
name: "skill-name"
version: "1.0.0"
description: "Skill 描述"
author: "username"
homepage: "https://github.com/OWNER/REPO"
license: "MIT"

permissions:
  files:
    read: ["./src/**"]
    write: ["./output/**"]
  network:
    outbound: ["api.example.com:443"]
  commands: ["git", "npm"]
  env_vars: ["API_KEY"]

dependencies:
  skills: []
  packages: []

security:
  risk_level: "low"    # low | medium | high
  sandbox: false
---

# Skill 内容...
```

## 安全架构

### 安装流程

```
用户请求安装 skill
        │
        ▼
┌───────────────┐
│ Phase 1: 来源 │
│   验证        │─── 不信任 ──→ 警告，加强审查
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ Phase 2: 代码 │
│   审查        │─── 危险信号 ──→ 拒绝安装
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ Phase 3: 风险 │
│   评估        │─── 高风险 ──→ 用户确认
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ Phase 4: 安装 │
│   执行        │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ Phase 5: 记录 │
│   日志        │
└───────────────┘
```

### 风险等级处理

| 风险等级 | 信任来源 | 非信任来源 |
|----------|----------|------------|
| 🟢 LOW | 自动安装 | 展示信息后安装 |
| 🟡 MEDIUM | 展示确认 | 需要用户批准 |
| 🔴 HIGH | 需要批准 | 强烈警告 + 批准 |
| ⛔ EXTREME | 拒绝安装 | 拒绝安装 |

## 使用方法

当用户的需求匹配某个 skill 的描述时，AI 工具会自动调用相应的 skill。例如：

- 用户说："帮我安装 xxx skill" → 调用 `skill-installer`
- 用户说："帮我审查这个 skill 是否安全" → 调用 `skill-vetter`
- 用户说："帮我把这个 MCP 服务 dockerize" → 调用 `mcp-dockerizer`

## 从此仓库安装 Skill

### 作为 AI 工具使用

将此仓库添加到你的 AI 工具的 skill 搜索路径中：

```
https://github.com/Arthur244/skills
```

AI 工具会自动读取 `skills-index.json` 发现可用的 skill。

### 程序化访问

```bash
# 获取索引
curl -s https://raw.githubusercontent.com/Arthur244/skills/main/skills-index.json

# 获取指定 skill 的元数据
curl -s https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/SKILL.md
```

## 相关链接

- [MCP (Model Context Protocol)](https://modelcontextprotocol.io/)
- [Trae IDE](https://trae.ai/)
