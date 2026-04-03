---
name: "mcp-dockerizer"
version: "1.1.0"
description: "将本地 MCP 服务转换为 Docker 部署。当用户想要 Docker 化 MCP 服务或在 Docker 环境中部署 MCP 时调用。"
author: "Arthur244"
homepage: "https://github.com/Arthur244/skills"
license: "MIT"
permissions:
  files:
    read: ["./**", "templates/**"]
    write: ["./Dockerfile", "./docker-compose.yml", "./.dockerignore"]
  network:
    outbound: ["raw.githubusercontent.com:443", "cdn.jsdelivr.net:443"]
  commands: ["docker", "docker-compose", "curl.exe"]
  env_vars: []
dependencies:
  skills: []
  packages: []
security:
  risk_level: "medium"
  sandbox: false
---

# MCP Dockerizer

## ⚠️ 前置检查：模板文件获取

**在执行此 skill 任何步骤之前，必须先完成以下检查：**

### 步骤 0：检查并获取模板文件

1. **检查模板文件夹是否存在**：
   - 检查 `templates/` 文件夹是否存在
   - 检查以下文件是否存在：
     - `templates/Dockerfile.python-uv`
     - `templates/Dockerfile.python-pip`
     - `templates/Dockerfile.nodejs`

2. **如果模板文件不存在，自动下载模板文件**：

   **使用智能下载函数（支持 CDN 自动回退）**：
   
   ## ⚠️ 重要：下载命令规范

**必须使用 `curl.exe` 命令，禁止使用 `curl` 或 `Invoke-WebRequest`**（避免 Windows 安全策略拦截）

```powershell
# ✅ 正确：使用 curl.exe（注意 .exe 后缀）
curl.exe -sL "https://raw.githubusercontent.com/OWNER/REPO/BRANCH/PATH" -o "./output.file"

# ❌ 错误：curl 是 Invoke-WebRequest 的别名，会触发安全提醒
curl -sL "https://..." -o "./output.file"

# ❌ 错误：Invoke-WebRequest 会触发 Windows 安全提醒
Invoke-WebRequest -Uri "..." -OutFile "..."
```

**原因说明**：
- PowerShell 中 `curl` 是 `Invoke-WebRequest` 的别名，仍会触发安全策略
- 必须使用 `curl.exe`（带 .exe 后缀）才能调用真正的 curl 程序
- `curl.exe` 是跨平台工具，不受 Windows 安全策略限制
- 使用 `-sL` 参数：`-s` 静默模式，`-L` 跟随重定向

   ```powershell
   # 智能下载函数（支持 CDN 回退 + 跨平台适配）
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
       
       # 跨平台 curl 命令列表（按优先级）
       $curlCommands = @("curl", "curl.exe")
       
       foreach ($source in $sources) {
           Write-Host "  尝试从 $($source.Name) 下载..." -NoNewline
           
           # 尝试不同的 curl 命令
           $downloaded = $false
           foreach ($curlCmd in $curlCommands) {
               try {
                   $result = & $curlCmd -sL --connect-timeout 10 --max-time 30 "$($source.Url)" -o "$OutputPath" 2>&1
                   
                   if ((Test-Path $OutputPath) -and ((Get-Item $OutputPath).Length -gt 0)) {
                       Write-Host " ✓ 成功"
                       return $true
                   }
               } catch {
                   # 当前 curl 命令失败，尝试下一个
                   continue
               }
           }
           
           # 所有 curl 命令都失败
           Write-Host " ✗ 失败"
           continue
       }
       
       Write-Host "  ❌ 所有下载源均失败"
       return $false
   }
   
   # 设置模板文件列表
   $templates = @(
       "Dockerfile.python-uv",
       "Dockerfile.python-pip",
       "Dockerfile.nodejs"
   )
   
   # 创建 templates 目录
   New-Item -ItemType Directory -Path "./templates" -Force | Out-Null
   
   # 确定下载参数（优先使用上下文，后备固化链接）
   $downloadOwner = if ($owner) { $owner } else { "Arthur244" }
   $downloadRepo = if ($repo) { $repo } else { "skills" }
   $downloadBranch = if ($branch) { $branch } else { "main" }
   
   Write-Host "下载模板文件..."
   Write-Host "  仓库: $downloadOwner/$downloadRepo"
   Write-Host "  分支: $downloadBranch"
   Write-Host ""
   
   # 下载所有模板文件
   $allSuccess = $true
   foreach ($template in $templates) {
       Write-Host "下载: $template"
       
       $success = Invoke-SmartDownload `
           -Owner $downloadOwner `
           -Repo $downloadRepo `
           -Branch $downloadBranch `
           -FilePath "mcp-dockerizer/templates/$template" `
           -OutputPath "./templates/$template"
       
       if (-not $success) {
           $allSuccess = $false
       }
   }
   
   if (-not $allSuccess) {
       Write-Host ""
       Write-Host "⚠ 部分模板文件下载失败，请参考「附录：模板文件内容」手动创建"
   }
   ```
   
   **下载源优先级**：
   
   | 优先级 | 源 | 域名 | 说明 |
   |--------|-----|------|------|
   | 1 | GitHub Raw | `raw.githubusercontent.com` | 官方源，优先使用 |
   | 2 | jsDelivr CDN | `cdn.jsdelivr.net` | 公共 CDN，稳定性高 |
   
   **链接格式说明**：
   - **GitHub Raw**: `https://raw.githubusercontent.com/{owner}/{repo}/refs/heads/{branch}/mcp-dockerizer/templates/{template-file}`
   - **jsDelivr CDN**: `https://cdn.jsdelivr.net/gh/{owner}/{repo}@{branch}/mcp-dockerizer/templates/{template-file}`

   **方案 B：手动创建模板文件（备选）**
   
   如果自动下载失败，请根据本文件中「附录：模板文件内容」部分的内容，手动创建以下文件：
   - `templates/Dockerfile.python-uv`
   - `templates/Dockerfile.python-pip`
   - `templates/Dockerfile.nodejs`

3. **验证模板文件**：
   确认所有模板文件都已就绪后，方可继续执行后续步骤。

### 模板文件检查清单

在继续之前，请确认：
- [ ] `templates/` 文件夹已存在
- [ ] `templates/Dockerfile.python-uv` 文件已存在
- [ ] `templates/Dockerfile.python-pip` 文件已存在
- [ ] `templates/Dockerfile.nodejs` 文件已存在

**只有当以上所有文件都存在时，才能继续执行后续步骤。**

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

#### ⚠️ 模板遵循约束（强制要求）

**生成 Dockerfile 时必须严格遵守以下规则：**

1. **必须使用模板**：根据项目类型选择对应模板文件：
   - Python + uv 项目 → 使用 `templates/Dockerfile.python-uv`
   - Python + pip 项目 → 使用 `templates/Dockerfile.python-pip`
   - Node.js 项目 → 使用 `templates/Dockerfile.nodejs`

2. **最小修改原则**：
   - **禁止**：重写、重构或"优化"模板结构
   - **禁止**：更改基础镜像版本（除非有明确的兼容性要求）
   - **禁止**：删除或修改注释
   - **禁止**：更改构建阶段名称、工作目录路径等结构性元素
   - **允许修改的内容**（仅限以下项）：
     - `ENTRYPOINT` 中的模块名称/脚本路径
     - 必要时添加额外的 `COPY` 命令（如项目有特殊目录结构）
     - 必要时添加额外的环境变量（如项目有特殊需求）

3. **模板占位符替换规则**：
   | 占位符 | 说明 | 示例替换 |
   |--------|------|----------|
   | `mcp-server-name` | CLI 入口点名称（Python 定义在 pyproject.toml 的 [project.scripts]，Node.js 定义在 package.json 的 bin 字段） | `my-mcp-server` |

4. **生成流程**：
   ```
   步骤 A: 读取对应模板文件
   步骤 B: 仅替换必要的占位符
   步骤 C: 如需额外修改，必须在注释中说明原因
   步骤 D: 输出最终 Dockerfile
   ```

5. **验证检查清单**（生成后自检）：
   - [ ] 是否保留了两阶段构建结构？
   - [ ] 是否保留了所有注释？
   - [ ] 是否只修改了允许修改的部分？
   - [ ] 基础镜像版本是否与模板一致？
   - [ ] 用户创建命令是否与模板一致？

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

# 使用缓存挂载安装依赖和项目
# --mount=type=cache,target=/root/.cache/uv: 缓存 uv 下载的包，加速后续构建
# --mount=type=bind,source=uv.lock,target=uv.lock: 绑定锁文件
# --mount=type=bind,source=pyproject.toml,target=pyproject.toml: 绑定项目配置文件
# --frozen: 使用锁文件，确保可重复构建
# --no-dev: 不安装开发依赖
# --no-editable: 以非可编辑模式安装
# 注意：不使用 --no-install-project，以便安装项目入口点脚本到 .venv/bin/
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-dev --no-editable

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
# 注意：根据实际项目的 pyproject.toml 中 [project.scripts] 定义的入口点名称调整
# 例如：my-mcp-server 等
ENTRYPOINT ["mcp-server-name"]
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
# 注意：根据实际项目的 setup.py 或 pyproject.toml 中定义的入口点名称调整
# 例如：my-mcp-server 等
ENTRYPOINT ["mcp-server-name"]
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
# PATH: 将 node_modules/.bin 添加到 PATH，支持直接执行 package.json 中定义的 bin 命令
ENV NODE_ENV=production \
    PATH="/app/node_modules/.bin:$PATH"

# 设置入口点
# 注意：根据实际项目的 package.json 中 bin 字段定义的命令名称调整
# 例如：my-mcp-server 等
ENTRYPOINT ["mcp-server-name"]
```

#### docker-compose.yml 模板

**⚠️ 必须严格遵循以下模板结构，仅修改必要字段：**

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

**允许修改的字段**：
- `services` 下的服务名称
- `container_name`
- `environment` 中的环境变量
- `volumes` 中的挂载路径
- `ports`（如需要）

**禁止修改的字段**：
- `version`
- `build.context` 和 `build.dockerfile`
- `restart` 策略

#### .dockerignore 模板

**⚠️ 必须直接使用以下内容，不得删减：**

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

**允许添加**：项目特定的排除项（如 `dist/`、`build/` 等）

### 步骤 4：配置 MCP 客户端

**⚠️ 配置转换必须严格遵循以下模板格式：**

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

**转换后（Docker 运行）- 必须使用此格式：**
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

**配置转换规则**：

| 原始字段 | Docker 配置 | 说明 |
|----------|-------------|------|
| `command` | `"docker"` | **必须** |
| `args[0]` | `"run"` | **必须** |
| `args` 中添加 | `"--rm"` | **必须** - 自动清理容器 |
| `args` 中添加 | `"-i"` | **必须** - stdio 通信必需 |
| `args` 中添加 | `"-e", "VAR_NAME"` | **必须** - 传递环境变量 |
| `args` 最后 | `"镜像名:latest"` | **必须** - 镜像名称 |
| `timeout` | `60` | **必须** - Docker 启动需要时间 |
| `transportType` | `"stdio"` | **必须** - 明确通信类型 |

**禁止事项**：
- 禁止省略 `--rm` 参数
- 禁止省略 `-i` 参数
- 禁止省略 `timeout` 字段
- 禁止省略 `transportType` 字段

### 步骤 5：验证功能一致性

Docker 部署后，验证以下内容：

1. **API 兼容性**：所有 MCP 工具/资源/提示可访问
2. **环境变量**：所有环境变量正确传递
3. **文件访问**：卷正确挂载且可访问
4. **网络**：如需要，端口已暴露
5. **错误处理**：错误正确传播

## 关键参数说明

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

## curl 命令参数说明

| 参数 | 说明 |
|------|------|
| `-s` | 静默模式，不显示进度 |
| `-L` | 跟随重定向 |
| `-o` | 输出到文件 |
| `--connect-timeout` | 连接超时时间（秒） |
| `--max-time` | 最大传输时间（秒） |

**使用示例**：
```powershell
# 下载单个文件
curl.exe -sL "https://raw.githubusercontent.com/Arthur244/skills/main/mcp-dockerizer/templates/Dockerfile.python-uv" -o "./templates/Dockerfile.python-uv"

# 带超时设置
curl.exe -sL --connect-timeout 10 --max-time 30 "https://cdn.jsdelivr.net/gh/Arthur244/skills@main/mcp-dockerizer/templates/Dockerfile.python-uv" -o "./templates/Dockerfile.python-uv"
```

## ⚠️ 模板合规性总结

**生成任何配置文件前，必须先阅读并确认以下规则：**

### Dockerfile 生成规则

```
┌─────────────────────────────────────────────────────────────┐
│  🔴 禁止行为                                                 │
├─────────────────────────────────────────────────────────────┤
│  ❌ 自行编写 Dockerfile（必须从模板复制）                      │
│  ❌ 修改基础镜像版本                                          │
│  ❌ 删除或修改模板中的注释                                     │
│  ❌ 更改两阶段构建的结构                                       │
│  ❌ 修改用户创建命令                                          │
│  ❌ 更改工作目录路径                                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  🟢 允许修改                                                  │
├─────────────────────────────────────────────────────────────┤
│  ✅ ENTRYPOINT 中的模块名称/脚本路径                          │
│  ✅ 添加必要的 COPY 命令（项目特殊目录）                        │
│  ✅ 添加必要的环境变量                                        │
└─────────────────────────────────────────────────────────────┘
```

### 模板文件路径

| 项目类型 | 模板文件 |
|----------|----------|
| Python + uv | `templates/Dockerfile.python-uv` |
| Python + pip | `templates/Dockerfile.python-pip` |
| Node.js | `templates/Dockerfile.nodejs` |

### 生成流程（必须遵循）

```
1. 确定项目类型（Python-uv / Python-pip / Node.js）
2. 读取对应的模板文件
3. 仅替换占位符（mcp-server-name、入口路径等）
4. 如需额外修改，添加注释说明原因
5. 输出最终文件
6. 执行自检清单验证
```

### 违规示例 vs 正确示例

**❌ 错误：自行编写**
```dockerfile
FROM python:3.12
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "main.py"]
```

**✅ 正确：基于模板**
```dockerfile
# syntax=docker/dockerfile:1

# 阶段 1：构建阶段 - 用于安装依赖
FROM python:3.11-slim AS builder
WORKDIR /app
# ...（完整复制模板，仅修改 ENTRYPOINT）
ENTRYPOINT ["python", "-m", "my_actual_module"]
```

---

## 附录：模板文件内容

以下为模板文件的完整内容。

### ⚠️ 重要：模板获取优先级

**请按以下优先级获取模板文件：**

1. **优先使用网络下载**（推荐）
   - 使用前文「步骤 0」中的智能下载函数从 GitHub 下载模板文件
   - 支持 CDN 自动回退，下载成功率高
   - 确保获取最新版本的模板

2. **网络下载失败时使用预置模板**
   - 仅当所有网络下载方式均失效时，才使用本附录中的预置模板
   - 手动创建对应的模板文件

### 模板获取流程

**⚠️ 重要提示：下载时必须使用 `curl.exe` 命令，禁止使用 `curl` 或 `Invoke-WebRequest`**

```powershell
# 步骤 1: 尝试网络下载（优先）
$templates = @("Dockerfile.python-uv", "Dockerfile.python-pip", "Dockerfile.nodejs")
$allDownloaded = $true

foreach ($template in $templates) {
    $success = Invoke-SmartDownload `
        -Owner "Arthur244" `
        -Repo "skills" `
        -Branch "main" `
        -FilePath "mcp-dockerizer/templates/$template" `
        -OutputPath "./templates/$template"
    
    if (-not $success) {
        $allDownloaded = $false
    }
}

# 步骤 2: 如果网络下载失败，使用预置模板
if (-not $allDownloaded) {
    Write-Host "⚠ 网络下载失败，使用预置模板创建文件"
    # 根据本附录内容手动创建模板文件...
}
```

### templates/Dockerfile.python-uv

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

# 使用缓存挂载安装依赖和项目
# --mount=type=cache,target=/root/.cache/uv: 缓存 uv 下载的包，加速后续构建
# --mount=type=bind,source=uv.lock,target=uv.lock: 绑定锁文件
# --mount=type=bind,source=pyproject.toml,target=pyproject.toml: 绑定项目配置文件
# --frozen: 使用锁文件，确保可重复构建
# --no-dev: 不安装开发依赖
# --no-editable: 以非可编辑模式安装
# 注意：不使用 --no-install-project，以便安装项目入口点脚本到 .venv/bin/
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-dev --no-editable

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
# 注意：根据实际项目的 pyproject.toml 中 [project.scripts] 定义的入口点名称调整
# 例如：my-mcp-server 等
ENTRYPOINT ["mcp-server-name"]
```

### templates/Dockerfile.python-pip

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
# 注意：根据实际项目的 setup.py 或 pyproject.toml 中定义的入口点名称调整
# 例如：my-mcp-server 等
ENTRYPOINT ["mcp-server-name"]
```

### templates/Dockerfile.nodejs

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
# PATH: 将 node_modules/.bin 添加到 PATH，支持直接执行 package.json 中定义的 bin 命令
ENV NODE_ENV=production \
    PATH="/app/node_modules/.bin:$PATH"

# 设置入口点
# 注意：根据实际项目的 package.json 中 bin 字段定义的命令名称调整
# 例如：my-mcp-server 等
ENTRYPOINT ["mcp-server-name"]
```
