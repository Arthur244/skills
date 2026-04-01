---
name: "mcp-dockerizer"
description: "将本地 MCP 服务转换为 Docker 部署。当用户想要 Docker 化 MCP 服务或在 Docker 环境中部署 MCP 时调用。"
---

# MCP Dockerizer

本 skill 引导 AI 工具将现有本地部署的 MCP（Model Context Protocol）服务转换为 Docker 部署，同时保持功能完全一致。

## 调用时机

当以下情况时调用此 skill：
- 用户想要在 Docker 中部署 MCP 服务
- 用户要求"dockerize"或"containerize"一个 MCP 服务
- 用户想要将 MCP 从本地迁移到容器化环境
- 用户在同一上下文中提到 MCP 和 Docker

## 工作流程

### 步骤 1：分析 MCP 服务

首先，分析现有 MCP 服务以了解其结构和需求。

#### Node.js MCP 服务

检查以下内容：
- `package.json` - 依赖和脚本
- 入口文件（通常是 `index.js`、`src/index.js`，或在 package.json 中定义）
- Node.js 版本要求
- 环境变量使用情况
- 文件系统访问模式

```bash
# 查看 package.json
cat package.json

# 检查环境变量使用
grep -r "process.env" --include="*.js" --include="*.ts"

# 检查文件系统操作
grep -r "fs\." --include="*.js" --include="*.ts"
```

#### Python MCP 服务

检查以下内容：
- `pyproject.toml`、`requirements.txt` 或 `setup.py` - 依赖
- 入口文件（通常在 pyproject.toml 中定义或主脚本）
- Python 版本要求
- 环境变量使用情况
- 文件系统访问模式

```bash
# 查看依赖
cat pyproject.toml 2>/dev/null || cat requirements.txt 2>/dev/null

# 检查环境变量使用
grep -r "os.environ\|os.getenv" --include="*.py"

# 检查文件系统操作
grep -r "open(\|Path(" --include="*.py"
```

### 步骤 2：确定运行时需求

确定以下内容：
1. **运行时**：Node.js 版本或 Python 版本
2. **包管理器**：npm/yarn/pnpm 或 pip/poetry/uv
3. **环境变量**：列出所有必需和可选的环境变量
4. **端口**：任何需要暴露的 HTTP/WebSocket 端口
5. **卷挂载**：需要持久化的文件系统路径

### 步骤 3：生成 Docker 配置

#### 两步式打包方案说明

所有模板均采用**两步式打包（Multi-stage Build）**，核心思想：
1. **构建阶段（Builder Stage）**：使用完整镜像安装依赖、编译代码
2. **运行阶段（Runtime Stage）**：使用精简镜像，只复制必要的运行时文件

**优势**：
- 镜像体积大幅减小（可减少 50%-80%）
- 不包含构建工具和中间文件
- 更安全（更小的攻击面）
- 更快的部署速度

#### Python + uv Dockerfile 模板（推荐用于现代 Python MCP）

```dockerfile
# syntax=docker/dockerfile:1

# 阶段 1：构建阶段 - 用于安装依赖
FROM python:3.11-slim AS builder

# 设置工作目录
WORKDIR /app

# 安装 uv 包管理器
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# 设置环境变量
# UV_COMPILE_BYTECODE=1: 编译 Python 字节码，提升启动速度
# UV_LINK_MODE=copy: 复制文件而非硬链接，避免跨文件系统问题
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

# 使用缓存挂载安装依赖
# --mount=type=cache,target=/root/.cache/uv: 缓存 uv 下载的包，加速后续构建
# --mount=type=bind,source=uv.lock,target=uv.lock: 绑定锁文件
# --mount=type=bind,source=pyproject.toml,target=pyproject.toml: 绑定项目配置文件
# --frozen: 使用锁文件，确保可重复构建
# --no-install-project: 只安装依赖，不安装项目本身
# --no-dev: 不安装开发依赖
# --no-editable: 以非可编辑模式安装
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable

# 阶段 2：运行阶段 - 精简的生产镜像
FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 从构建阶段复制虚拟环境
COPY --from=builder /app/.venv /app/.venv

# 复制源代码
COPY . .

# 创建非 root 用户（安全最佳实践）
RUN useradd -m -u 1001 mcpuser && \
    chown -R mcpuser:mcpuser /app

# 切换到非 root 用户
USER mcpuser

# 设置环境变量
# PATH: 将虚拟环境添加到 PATH
# PYTHONUNBUFFERED=1: 禁用输出缓冲，便于查看日志
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

# 设置入口点
# 注意：根据实际项目调整模块名称
ENTRYPOINT ["python", "-m", "mcp_server_name"]
```

#### Python (pip) Dockerfile 模板

```dockerfile
# syntax=docker/dockerfile:1

# 阶段 1：构建阶段 - 用于安装依赖
FROM python:3.11-slim AS builder

# 设置工作目录
WORKDIR /app

# 安装系统依赖（如需要编译的 Python 包）
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 使用缓存挂载创建虚拟环境并安装依赖
# --mount=type=cache,target=/root/.cache/pip: 缓存 pip 下载的包，加速后续构建
# --mount=type=bind,source=requirements.txt,target=requirements.txt: 绑定依赖文件
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install -r requirements.txt

# 阶段 2：运行阶段 - 精简的生产镜像
FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 从构建阶段复制虚拟环境
COPY --from=builder /opt/venv /opt/venv

# 复制源代码
COPY . .

# 创建非 root 用户（安全最佳实践）
RUN useradd -m -u 1001 mcpuser && \
    chown -R mcpuser:mcpuser /app

# 切换到非 root 用户
USER mcpuser

# 设置环境变量
# PATH: 将虚拟环境添加到 PATH
# PYTHONUNBUFFERED=1: 禁用输出缓冲，便于查看日志
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1

# 设置入口点
# 注意：根据实际项目调整模块名称或脚本路径
ENTRYPOINT ["python", "-m", "mcp_server"]
```

#### Node.js Dockerfile 模板

```dockerfile
# syntax=docker/dockerfile:1

# 阶段 1：构建阶段 - 用于安装依赖和构建
FROM node:20-alpine AS builder

# 设置工作目录
WORKDIR /app

# 使用缓存挂载安装依赖
# --mount=type=cache,target=/root/.npm: 缓存 npm 下载的包，加速后续构建
# --mount=type=bind,source=package.json,target=package.json: 绑定 package.json
# --mount=type=bind,source=package-lock.json,target=package-lock.json: 绑定 lock 文件
# npm ci: 根据 package-lock.json 精确安装，确保可重复构建
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    npm ci --only=production

# 复制源代码
COPY . .

# 如果有构建步骤，在这里执行
# RUN npm run build

# 阶段 2：运行阶段 - 精简的生产镜像
FROM node:20-alpine

# 设置工作目录
WORKDIR /app

# 从构建阶段复制必要文件
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
# 如果有构建输出目录：
# COPY --from=builder /app/dist ./dist

# 创建非 root 用户（安全最佳实践）
RUN addgroup -g 1001 -S mcpuser && \
    adduser -S mcpuser -u 1001 -G mcpuser && \
    chown -R mcpuser:mcpuser /app

# 切换到非 root 用户
USER mcpuser

# 设置环境变量
# NODE_ENV=production: 生产环境模式
ENV NODE_ENV=production

# 设置入口点
# 注意：根据实际项目调整入口文件路径
ENTRYPOINT ["node", "src/index.js"]
```

#### docker-compose.yml 模板

```yaml
version: '3.8'

services:
  mcp-service:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: mcp-service
    restart: unless-stopped
    environment:
      - ENV_VAR_NAME=value
    volumes:
      - ./data:/app/data
      - ./config:/app/config
    # 如需 HTTP/WebSocket 端口，取消注释
    # ports:
    #   - "3000:3000"
```

#### .dockerignore 模板

```
node_modules
__pycache__
*.pyc
.git
.gitignore
.env
.env.*
*.md
Dockerfile
docker-compose.yml
.dockerignore
.venv
venv
.idea
.vscode
```

### 步骤 4：配置 MCP 客户端

更新 MCP 客户端配置以使用 Docker 容器。

#### Claude Desktop 配置 (claude_desktop_config.json)

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

### 步骤 5：验证功能一致性

Docker 部署后，验证以下内容：

1. **API 兼容性**：所有 MCP 工具/资源/提示可访问
2. **环境变量**：所有环境变量正确传递
3. **文件访问**：卷正确挂载且可访问
4. **网络**：如需要，端口已暴露
5. **错误处理**：错误正确传播

## 实际案例分析：mcp-caiyun-weather

以下是基于 [mcp-caiyun-weather](https://github.com/caiyunapp/mcp-caiyun-weather) 项目的 Docker 化分析。

### 原始配置（本地运行）

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

### Docker 化后配置

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

### 关键差异分析

| 项目 | 原始配置 | Docker 配置 |
|------|----------|-------------|
| command | `uvx` | `docker` |
| args | `["mcp-caiyun-weather"]` | `["run", "-i", "-e", "...", "--rm", "mcp/caiyun-weather"]` |
| timeout | 无 | `60` |
| transportType | 无 | `"stdio"` |

### 关键参数说明

| 参数 | 说明 |
|------|------|
| `-i` | **必需** - 保持 stdin 开启，stdio 通信模式的核心参数 |
| `--rm` | 容器退出后自动删除，避免残留容器 |
| `-e VAR_NAME` | 从宿主机传递环境变量到容器 |
| `-e VAR_NAME=value` | 直接设置环境变量值 |
| `timeout: 60` | 超时设置，Docker 启动可能需要更长时间 |
| `transportType: "stdio"` | 明确指定通信类型 |

### 环境变量传递方式

**推荐方式**：使用 `-e VAR_NAME` 配合客户端 env 配置
```json
{
  "args": ["run", "--rm", "-i", "-e", "API_KEY", "mcp-service"],
  "env": {
    "API_KEY": "your-api-key"
  }
}
```

**备选方式**：直接在 args 中设置值
```json
{
  "args": ["run", "--rm", "-i", "-e", "API_KEY=your-api-key", "mcp-service"]
}
```

## 最佳实践

### 安全性
- 始终在容器中使用非 root 用户
- 不要在 Dockerfile 中硬编码密钥
- 使用 `.dockerignore` 排除敏感文件
- 通过环境变量在运行时传递密钥

### 性能
- **使用两步式打包（Multi-stage Build）**：镜像体积可减少 50%-80%
- 使用 Alpine/slim 基础镜像减小体积
- 分层缓存依赖（先复制依赖文件，再复制源代码）

### 可维护性
- 固定基础镜像版本
- 文档化所有环境变量
- 如适用，包含健康检查

### 镜像体积对比

| 方案 | Python 镜像 | Node.js 镜像 |
|------|-------------|--------------|
| 单阶段构建 | ~500MB | ~300MB |
| 两步式构建 | ~150MB | ~100MB |

## 常见问题与解决方案

### 问题：挂载卷权限被拒绝
**解决方案**：确保容器用户 UID 与宿主机用户匹配，或调整卷权限。

### 问题：环境变量未传递
**解决方案**：在 docker run 中使用 `-e VAR_NAME` 或 `--env-file`，或在 docker-compose.yml 中定义。

### 问题：MCP 客户端无法连接容器
**解决方案**：对于基于 stdio 的 MCP，使用 `-i` 标志启用交互模式。对于基于 HTTP 的，使用 `-p` 暴露端口。

### 问题：镜像体积过大
**解决方案**：使用两步式构建、Alpine/slim 基础镜像，优化 `.dockerignore`。

## 快速参考命令

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
