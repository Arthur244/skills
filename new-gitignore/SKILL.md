---
name: gitignore
description: Generates .gitignore file for Git version control exclusions. Defines files and directories to exclude from version control like node_modules, build artifacts, and local environment files.
---

# Git Ignore Skill

## Purpose
Generate the `.gitignore` file for version control exclusions.

## Output
Create the file: `.gitignore`

## ⚠️ 模板遵循约束

**生成 .gitignore 时必须遵循以下规则：**

1. **必须包含基础排除项**：每个 .gitignore 都应包含以下基础内容
2. **根据项目类型添加对应规则**：识别项目类型后添加对应的排除规则
3. **保持分类清晰**：按类别组织，使用注释分隔

## 排除规则分类

### 1. 操作系统文件

```
# macOS
.DS_Store
.AppleDouble
.LSOverride
._*

# Windows
Thumbs.db
ehthumbs.db
Desktop.ini
$RECYCLE.BIN/
*.lnk

# Linux
*~
.directory
```

### 2. 编辑器和 IDE

```
# VS Code
.vscode/

# JetBrains IDEs (IntelliJ, PyCharm, WebStorm, etc.)
.idea/
*.iml
*.ipr
*.iws

# Sublime Text
*.sublime-workspace
*.sublime-project

# Vim
*.swp
*.swo
*.un~

# Emacs
*~
\#*\#
/.emacs.desktop
/.emacs.desktop.lock
*.elc
auto-save-list
tramp

# Cursor
.cursor/

# Zed
.zed/
```

### 3. 环境变量和敏感文件

```
# Environment files
.env
.env.local
.env.*.local
*.local

# Secrets
*.pem
*.key
*.crt
secrets/
.secrets/
```

### 4. Node.js

```
# Dependencies
node_modules/

# Build output
dist/
dist-ssr/
build/
.next/
.nuxt/
.output/
.cache/

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# Lock files (可选，根据团队约定)
# package-lock.json
# yarn.lock
# pnpm-lock.yaml

# Test coverage
coverage/
.nyc_output/
```

### 5. Python

```
# Byte-compiled / optimized
__pycache__/
*.py[cod]
*$py.class
*.so

# Virtual environments
.venv/
venv/
ENV/
env/

# Distribution / packaging
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/
.nox/

# mypy
.mypy_cache/

# ruff
.ruff_cache/

# uv
.uv/
uv.lock
```

### 6. Rust

```
# Build output
target/
Cargo.lock

# IDE
**/*.rs.bk
```

### 7. Go

```
# Build output
bin/
pkg/
*.exe
*.exe~
*.dll
*.so
*.dylib

# Test
*.test
*.out
go.work
go.work.sum
```

### 8. Java / JVM

```
# Build output
target/
build/
out/
*.class
*.jar
*.war
*.ear

# Gradle
.gradle/
gradle-app.setting
!gradle-wrapper.jar

# Maven
pom.xml.tag
pom.xml.releaseBackup
pom.xml.versionsBackup
pom.xml.next
release.properties
dependency-reduced-pom.xml
```

### 9. .NET / C#

```
# Build output
bin/
obj/
*.dll
*.exe
*.pdb
*.cache

# Visual Studio
.vs/
*.suo
*.user
*.userosscache
*.sln.docstates

# Rider
.idea/
```

### 10. Docker

```
# Docker
.docker/
docker-compose.override.yml
```

### 11. 数据库

```
# Database
*.db
*.sqlite
*.sqlite3
*.sql.bak
```

### 12. AI / LLM 工具缓存

```
# AI tools
.aider*
.claude/
.cursor/
.windsurf/
.copilot/
```

### 13. 其他常用工具

```
# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
.terraform.lock.hcl

# Ansible
.ansible/

# Vagrant
.vagrant/

# Chef
.chef/

# Packer
packer_cache/
```

## 生成流程

1. **识别项目类型**：检查项目根目录的特征文件
   - `package.json` → Node.js
   - `pyproject.toml` / `requirements.txt` → Python
   - `Cargo.toml` → Rust
   - `go.mod` → Go
   - `pom.xml` / `build.gradle` → Java
   - `*.csproj` → .NET

2. **组合排除规则**：
   - 始终包含：操作系统文件 + 编辑器 + 环境变量
   - 根据项目类型添加对应规则
   - 可选添加：AI 工具缓存、其他工具

3. **输出文件**：生成完整的 `.gitignore` 文件

## 示例输出

**Node.js 项目**：
```
# macOS
.DS_Store

# Editor
.vscode/
.idea/

# Environment
.env
.env.local
.env.*.local

# Node.js
node_modules/
dist/
coverage/
*.log

# AI tools
.cursor/
.claude/
```

**Python 项目**：
```
# macOS
.DS_Store

# Editor
.vscode/
.idea/

# Environment
.env
.env.local

# Python
__pycache__/
.venv/
*.py[cod]
.pytest_cache/
.mypy_cache/
.ruff_cache/

# AI tools
.cursor/
.claude/
```
