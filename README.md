# Skills

AI 辅助工具技能集合，用于扩展 AI 编程助手的能力。

## 概述

本仓库包含多个可复用的 skill 定义，每个 skill 都是为了解决特定类型的开发任务而设计。这些 skill 可以被支持 skill 系统的 AI 工具（如 Trae IDE）调用。

## 可用 Skills

| Skill | 描述 |
|-------|------|
| [mcp-dockerizer](./mcp-dockerizer) | 将本地 MCP 服务转换为 Docker 部署 |

### mcp-dockerizer

将本地部署的 MCP（Model Context Protocol）服务转换为 Docker 部署，同时保持功能完全一致。

**核心特性**：
- 支持 Node.js、Python (pip/poetry/uv) 等主流运行时
- 采用 Multi-stage Build，镜像体积减少 50%-80%
- 提供完整的 Dockerfile、docker-compose.yml 模板
- 包含 MCP 客户端配置更新指南

## Skill 结构

每个 skill 遵循以下目录结构：

```
skill-name/
├── SKILL.md    # Skill 定义文件（必需）
└── README.md   # Skill 说明文档（可选）
```

### SKILL.md 格式

```yaml
---
name: "skill-name"
description: "Skill 描述，用于 AI 判断调用时机"
---

# Skill 标题

详细的 skill 指令内容...
```

## 使用方法

当用户的需求匹配某个 skill 的描述时，AI 工具会自动调用相应的 skill。例如：

- 用户说："帮我把这个 MCP 服务 dockerize" → 调用 `mcp-dockerizer`
- 用户说："我想在 Docker 中部署这个 MCP" → 调用 `mcp-dockerizer`

## 相关链接

- [MCP (Model Context Protocol)](https://modelcontextprotocol.io/)
- [Trae IDE](https://trae.ai/)
