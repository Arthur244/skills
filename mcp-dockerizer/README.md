# MCP Dockerizer Skill

将本地 MCP 服务转换为 Docker 部署的 AI 辅助工具。

## 功能概述

本 skill 引导 AI 工具将现有本地部署的 MCP（Model Context Protocol）服务转换为 Docker 部署，同时保持功能完全一致。

### 核心特性

- **多运行时支持**：支持 Node.js、Python (pip/poetry/uv) 等主流运行时
- **两步式打包**：采用 Multi-stage Build，镜像体积减少 50%-80%
- **功能一致性保证**：确保 Docker 化后功能与原服务完全一致
- **完整工作流程**：从分析到部署的完整引导
- **模板驱动**：提供经过验证的 Dockerfile 模板，确保最佳实践

## 安装

### 方式一：下载完整 skill（推荐）

从 GitHub 下载完整的 skill（包含 templates 文件夹）：

```
https://github.com/Arthur244/skills/tree/main/mcp-dockerizer
```

### 方式二：仅 SKILL.md

如果只下载 SKILL.md 文件，skill 会在执行时检测模板文件是否存在：
- 若不存在，会提示下载完整 skill 或根据 SKILL.md 附录内容手动创建模板文件

### 模板文件检查清单

在继续之前，请确认以下文件都已存在：
- [ ] `templates/Dockerfile.python-uv`
- [ ] `templates/Dockerfile.python-pip`
- [ ] `templates/Dockerfile.nodejs`

**只有当以上所有文件都存在时，才能正常使用此 skill。**

## 使用方法

### 调用时机

当用户提出以下需求时，AI 会自动调用此 skill：
- 想要在 Docker 中部署 MCP 服务
- 要求"dockerize"或"containerize"一个 MCP 服务
- 想要将 MCP 从本地迁移到容器化环境
- 在同一上下文中提到 MCP 和 Docker

### 工作流程

1. **前置检查** - 检查模板文件是否存在
2. **分析 MCP 服务** - 识别运行时、依赖、环境变量等
3. **确定运行时需求** - 包管理器、端口、卷挂载等
4. **生成 Docker 配置** - 基于模板生成 Dockerfile、docker-compose.yml 等
5. **配置 MCP 客户端** - 更新客户端配置文件
6. **验证功能一致性** - 确保 Docker 化后功能正常

## 提供的模板

### Dockerfile 模板

| 模板 | 适用场景 | 基础镜像 | 特性 |
|------|----------|----------|------|
| Python + uv | 现代 Python MCP 服务 | python:3.11-slim | BuildKit 缓存挂载、多阶段构建 |
| Python (pip) | 传统 Python MCP 服务 | python:3.11-slim | BuildKit 缓存挂载、多阶段构建 |
| Node.js | Node.js MCP 服务 | node:20-alpine | BuildKit 缓存挂载、多阶段构建 |

### 其他模板

- `docker-compose.yml` - 服务编排配置
- `.dockerignore` - 构建上下文优化

## 两步式打包优势

| 方案 | Python 镜像 | Node.js 镜像 |
|------|-------------|--------------|
| 单阶段构建 | ~500MB | ~300MB |
| 两步式构建 | ~150MB | ~100MB |

**优势**：
- 镜像体积大幅减小（减少 50%-80%）
- 不包含构建工具和中间文件
- 更安全（更小的攻击面）
- 更快的部署速度

## BuildKit 缓存挂载优势

所有 Dockerfile 模板均使用 BuildKit 缓存挂载功能，进一步提升构建效率：

**优势**：
- 构建缓存持久化，下载的包会被缓存
- 减少网络传输，相同依赖不需要重复下载
- 更快的 CI/CD，在持续集成环境中显著提升构建速度

**各模板缓存策略**：
- **Python + uv**: 缓存 `/root/.cache/uv`
- **Python (pip)**: 缓存 `/root/.cache/pip`
- **Node.js**: 缓存 `/root/.npm`

**使用方法**：
```bash
# 启用 BuildKit 构建
DOCKER_BUILDKIT=1 docker build -t mcp-service:latest .
```

## 关键参数说明

| 参数 | 说明 |
|------|------|
| `-i` | **必需** - 保持 stdin 开启，stdio 通信模式的核心参数 |
| `--rm` | 容器退出后自动删除，避免残留容器 |
| `-e VAR_NAME` | 从宿主机传递环境变量到容器 |
| `timeout: 60` | 超时设置，Docker 启动可能需要更长时间 |
| `transportType: "stdio"` | 明确指定通信类型 |

## MCP 客户端配置转换

### Claude Desktop 配置示例

**转换前（本地运行）：**
```json
{
  "mcpServers": {
    "my-mcp": {
      "command": "uvx",
      "args": ["mcp-service-name"],
      "env": {
        "API_KEY": "your-api-key"
      }
    }
  }
}
```

**转换后（Docker 运行）：**
```json
{
  "mcpServers": {
    "my-mcp": {
      "timeout": 60,
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "-e", "API_KEY",
        "mcp-service:latest"
      ],
      "env": {
        "API_KEY": "your-api-key"
      },
      "transportType": "stdio"
    }
  }
}
```

### 配置转换规则

| 原始字段 | Docker 配置 | 说明 |
|----------|-------------|------|
| `command` | `"docker"` | **必须** |
| `args[0]` | `"run"` | **必须** |
| `args` 中添加 | `"--rm"` | **必须** - 自动清理容器 |
| `args` 中添加 | `"-i"` | **必须** - stdio 通信必需 |
| `args` 中添加 | `"-e", "VAR_NAME"` | **必须** - 传递环境变量 |
| `timeout` | `60` | **必须** - Docker 启动需要时间 |
| `transportType` | `"stdio"` | **必须** - 明确通信类型 |

## 最佳实践

### 安全性
- 始终在容器中使用非 root 用户
- 不要在 Dockerfile 中硬编码密钥
- 使用 `.dockerignore` 排除敏感文件
- 通过环境变量在运行时传递密钥

### 性能
- 使用两步式打包（Multi-stage Build）
- 使用 Alpine/slim 基础镜像减小体积
- 分层缓存依赖（先复制依赖文件，再复制源代码）

### 可维护性
- 固定基础镜像版本
- 文档化所有环境变量
- 如适用，包含健康检查

## 常见问题与解决方案

| 问题 | 解决方案 |
|------|----------|
| 挂载卷权限被拒绝 | 确保容器用户 UID 与宿主机用户匹配，或调整卷权限 |
| 环境变量未传递 | 在 docker run 中使用 `-e VAR_NAME` 或 `--env-file` |
| MCP 客户端无法连接容器 | 对于 stdio MCP，使用 `-i` 标志启用交互模式 |
| 镜像体积过大 | 使用两步式构建、Alpine/slim 基础镜像，优化 `.dockerignore` |

## 快速参考

```bash
# 构建 Docker 镜像
docker build -t mcp-service:latest .

# 交互式运行容器（用于 stdio MCP）
docker run --rm -i -e API_KEY=xxx mcp-service:latest

# 带卷挂载运行
docker run --rm -i -v /host/path:/container/path mcp-service:latest

# 使用 docker-compose 运行
docker-compose up -d

# 查看日志
docker logs mcp-service

# 交互式调试
docker run --rm -it --entrypoint /bin/sh mcp-service:latest

# 查看镜像大小
docker images mcp-service:latest
```

## 文件结构

```
mcp-dockerizer/
├── SKILL.md                        # Skill 定义文件
├── README.md                       # 说明文档
└── templates/                      # Dockerfile 模板
    ├── Dockerfile.python-uv        # Python + uv 模板
    ├── Dockerfile.python-pip       # Python + pip 模板
    └── Dockerfile.nodejs           # Node.js 模板
```

## 相关链接

- [MCP (Model Context Protocol)](https://modelcontextprotocol.io/)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
