# MCP Dockerizer Skill

将本地 MCP 服务转换为 Docker 部署的 AI 辅助工具。

## 功能概述

本 skill 引导 AI 工具将现有本地部署的 MCP（Model Context Protocol）服务转换为 Docker 部署，同时保持功能完全一致。

### 核心特性

- **多运行时支持**：支持 Node.js、Python (pip/poetry/uv) 等主流运行时
- **两步式打包**：采用 Multi-stage Build，镜像体积减少 50%-80%
- **功能一致性保证**：确保 Docker 化后功能与原服务完全一致
- **完整工作流程**：从分析到部署的完整引导

## 使用方法

### 调用时机

当用户提出以下需求时，AI 会自动调用此 skill：
- 想要在 Docker 中部署 MCP 服务
- 要求"dockerize"或"containerize"一个 MCP 服务
- 想要将 MCP 从本地迁移到容器化环境
- 在同一上下文中提到 MCP 和 Docker

### 工作流程

1. **分析 MCP 服务** - 识别运行时、依赖、环境变量等
2. **确定运行时需求** - 包管理器、端口、卷挂载等
3. **生成 Docker 配置** - Dockerfile、docker-compose.yml 等
4. **配置 MCP 客户端** - 更新客户端配置文件
5. **验证功能一致性** - 确保 Docker 化后功能正常

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

## 实际案例

### mcp-caiyun-weather 项目

原始配置（本地运行）：
```json
{
  "mcpServers": {
    "caiyun-weather": {
      "command": "uvx",
      "args": ["mcp-caiyun-weather"],
      "env": {
        "CAIYUN_WEATHER_API_TOKEN": "YOUR_API_KEY_HERE"
      }
    }
  }
}
```

Docker 化后配置：
```json
{
  "mcpServers": {
    "caiyun-weather": {
      "timeout": 60,
      "command": "docker",
      "args": [
        "run",
        "-i",
        "-e",
        "CAIYUN_WEATHER_API_TOKEN=YOUR_API_TOKEN_HERE",
        "--rm",
        "mcp/caiyun-weather"
      ],
      "transportType": "stdio"
    }
  }
}
```

## 关键参数说明

| 参数 | 说明 |
|------|------|
| `-i` | **必需** - 保持 stdin 开启，stdio 通信模式的核心参数 |
| `--rm` | 容器退出后自动删除，避免残留容器 |
| `-e VAR_NAME` | 从宿主机传递环境变量到容器 |
| `timeout: 60` | 超时设置，Docker 启动可能需要更长时间 |
| `transportType: "stdio"` | 明确指定通信类型 |

## 快速参考

```bash
# 构建 Docker 镜像
docker build -t mcp-service:latest .

# 交互式运行容器（用于 stdio MCP）
docker run --rm -i -e API_KEY=xxx mcp-service:latest

# 带卷挂载运行
docker run --rm -i -v /host/path:/container/path mcp-service:latest

# 查看镜像大小
docker images mcp-service:latest
```

## 文件结构

```
.trae/skills/mcp-dockerizer/
└── SKILL.md          # Skill 定义文件
```

## 相关链接

- [MCP (Model Context Protocol)](https://modelcontextprotocol.io/)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [mcp-caiyun-weather 示例项目](https://github.com/caiyunapp/mcp-caiyun-weather)
