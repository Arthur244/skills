# AI 工具 Skills 安装路径参考

## 路径层级说明

| 层级 | 说明 | 适用场景 |
|------|------|----------|
| 项目级 | 当前项目目录下 | 仅当前项目使用的 skill |
| 用户级 | 用户配置目录下 | 所有项目共享的 skill |

## 工具路径对照表

| 工具 | 系统支持 | 项目级路径 | 用户级路径 (Windows) | 用户级路径 (macOS/Linux) |
|------|----------|------------|---------------------|-------------------------|
| Trae (国内版) | Win/Mac | `./skills/` | `%USERPROFILE%\.trae-cn\skills\` | `~/.trae-cn/skills/` |
| Trae (国际版) | Win/Mac | `./skills/` | `%USERPROFILE%\.trae\skills\` | `~/.trae/skills/` |
| Cursor | Win/Mac/Linux | `./skills/` | `%APPDATA%\Cursor\User\skills\` | `~/.cursor/skills/` |
| Claude Code | Win/Mac/Linux | `./skills/` | `%APPDATA%\claude\skills\` | `~/.claude/skills/` |
| OpenCode | Mac/Linux | `./skills/` | - | `~/.config/opencode/skills/` |
| OpenClaw | Win/Mac/Linux | `./skills/` | `./skills/` | `./skills/` |

## 环境变量检测

| 工具 | 检测环境变量 | 检测配置目录 | 说明 |
|------|--------------|--------------|------|
| Trae (国内版) | `TRAE_*` | `.trae-cn/` | 优先检测环境变量，其次检测配置目录 |
| Trae (国际版) | `TRAE_*` | `.trae/` | 通过配置目录区分版本 |
| Cursor | `CURSOR_*` | `.cursor/` | 存在环境变量则判定为 Cursor |
| Claude Code | `CLAUDE_CODE_*` | `.claude/` | 存在环境变量则判定为 Claude Code |
| OpenCode | - | `.config/opencode/` | 仅通过配置目录检测 |
| OpenClaw | - | - | 仅支持项目级安装 |

## 检测优先级

1. **环境变量检测**（最可靠）
   - 检查特定工具的环境变量前缀
   - 如 `TRAE_`、`CURSOR_`、`CLAUDE_CODE_` 等

2. **配置目录检测**（次要）
   - 检查用户目录下是否存在工具配置目录
   - 如 `~/.trae-cn/`、`~/.cursor/`、`~/.claude/` 等

3. **进程信息检测**（备用）
   - 检查父进程名称
   - 如 `Trae`、`Cursor`、`claude` 等

## 路径展开规则

### Windows

| 变量 | 展开为 | 示例 |
|------|--------|------|
| `%USERPROFILE%` | 用户主目录 | `C:\Users\Arthur` |
| `%APPDATA%` | 应用数据目录 | `C:\Users\Arthur\AppData\Roaming` |

### macOS/Linux

| 变量 | 展开为 | 示例 |
|------|--------|------|
| `~` | 用户主目录 | `/Users/Arthur` 或 `/home/arthur` |
| `$HOME` | 用户主目录 | 同上 |

## 使用示例

### 检测当前工具

```powershell
# Windows (PowerShell)
if ($env:TRAE_CN -or (Test-Path "$env:USERPROFILE\.trae-cn")) {
    $tool = "Trae"
    $version = "domestic"
    $userPath = "$env:USERPROFILE\.trae-cn\skills\"
}
```

```bash
# Unix (Bash)
if [[ -n "$TRAE_CN" ]] || [[ -d "$HOME/.trae-cn" ]]; then
    tool="Trae"
    version="domestic"
    userPath="$HOME/.trae-cn/skills/"
fi
```

### 确定安装路径

```powershell
# 项目级
$projectPath = "./skills/"

# 用户级
$userPath = "$env:USERPROFILE\.trae-cn\skills\"

# 根据用户选择
if ($level -eq "user") {
    $installPath = $userPath
} else {
    $installPath = $projectPath
}
```
