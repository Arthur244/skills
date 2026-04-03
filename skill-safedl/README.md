# Skill SafeDL 🔒

安全下载工具，提供 CDN 自动回退和权限规避机制。

## 功能概述

本 skill 提供安全的文件下载功能，特别适用于从 GitHub 等平台下载文件。

### 核心特性

- **CDN 自动回退** - GitHub Raw 失败时自动切换到 jsDelivr CDN
- **权限规避** - 使用 curl 而非 Invoke-WebRequest，避免 PowerShell 权限问题
- **超时控制** - 可配置的连接和下载超时时间
- **文件验证** - 自动验证下载文件是否有效
- **批量下载** - 支持批量下载多个文件

## 为什么需要这个 Skill？

### 问题 1：网络访问受限

某些网络环境下 `raw.githubusercontent.com` 可能无法访问，导致下载失败。

**解决方案**：自动回退到 jsDelivr CDN，提高下载成功率。

### 问题 2：PowerShell 权限问题

使用 `Invoke-WebRequest` 可能遇到权限限制：

```powershell
# ❌ 可能失败
Invoke-WebRequest -Uri "..." -OutFile "..."
# 错误：由于权限限制，无法访问该资源
```

**解决方案**：使用 `curl` 命令，避免权限问题：

```powershell
# ✅ 推荐
curl -sL "..." -o "..."
```

## 安装

从 GitHub 下载完整的 skill：

```
https://github.com/Arthur244/skills/tree/main/skill-safedl
```

## 使用方法

### 基本用法

```powershell
# 下载单个文件
$result = Invoke-SmartDownload `
    -Owner "Arthur244" `
    -Repo "skills" `
    -Branch "main" `
    -FilePath "skill-installer/SKILL.md" `
    -OutputPath "./skill-installer/SKILL.md"

if ($result.Success) {
    Write-Host "✅ 下载成功"
} else {
    Write-Host "❌ 下载失败"
}
```

### 批量下载

```powershell
# 定义文件列表
$files = @(
    @{ Remote = "mcp-dockerizer/SKILL.md"; Local = "./mcp-dockerizer/SKILL.md" },
    @{ Remote = "mcp-dockerizer/README.md"; Local = "./mcp-dockerizer/README.md" }
)

# 下载所有文件
foreach ($file in $files) {
    Invoke-SmartDownload `
        -Owner "Arthur244" `
        -Repo "skills" `
        -Branch "main" `
        -FilePath $file.Remote `
        -OutputPath $file.Local
}
```

### 静默模式

```powershell
# 不输出进度信息
$result = Invoke-SmartDownload ... -Silent
```

### 自定义超时

```powershell
# 对于大文件，增加超时时间
$result = Invoke-SmartDownload `
    -ConnectTimeout 20 `
    -MaxTime 120 `
    ...
```

## CDN 回退机制

### 支持的下载源

| 优先级 | 源 | 说明 |
|--------|-----|------|
| 1 | GitHub Raw | 官方源，优先使用 |
| 2 | jsDelivr CDN | 公共 CDN，稳定性高 |

### URL 转换示例

```
原始: https://raw.githubusercontent.com/Arthur244/skills/refs/heads/main/skill-installer/SKILL.md
CDN:  https://cdn.jsdelivr.net/gh/Arthur244/skills@main/skill-installer/SKILL.md
```

## 函数参数

| 参数 | 类型 | 必需 | 默认值 | 说明 |
|------|------|------|--------|------|
| `$Owner` | string | ✅ | - | GitHub 仓库所有者 |
| `$Repo` | string | ✅ | - | GitHub 仓库名称 |
| `$Branch` | string | ✅ | - | 分支名称 |
| `$FilePath` | string | ✅ | - | 文件路径 |
| `$OutputPath` | string | ✅ | - | 本地输出路径 |
| `$ConnectTimeout` | int | ❌ | 10 | 连接超时（秒） |
| `$MaxTime` | int | ❌ | 30 | 最大下载时间（秒） |
| `$Silent` | switch | ❌ | false | 静默模式 |

## 返回值

返回一个哈希表：

| 字段 | 类型 | 说明 |
|------|------|------|
| `Success` | bool | 是否下载成功 |
| `Source` | string | 成功下载的源名称 |
| `Url` | string | 成功下载的 URL |

## 最佳实践

1. **始终检查返回值** - 确保下载成功
2. **使用静默模式** - 在脚本中减少输出
3. **设置合理超时** - 避免长时间等待
4. **批量下载记录失败** - 便于排查问题

## 与其他 Skill 集成

本 skill 已被以下 skill 使用：

- **skill-installer** - 用于下载 skill 文件
- **mcp-dockerizer** - 用于下载模板文件

## 常见问题

### 所有下载源均失败

**解决方案**：
1. 检查网络连接
2. 验证文件路径是否正确
3. 确认仓库和分支是否存在

### 下载的文件为空

**解决方案**：
- 函数会自动检测并尝试下一个源
- 检查文件是否真实存在

## 文件结构

```
skill-safedl/
├── SKILL.md          # Skill 定义文件
└── README.md         # 说明文档
```

## 相关链接

- [jsDelivr CDN](https://www.jsdelivr.com/)
- [curl 文档](https://curl.se/docs/)

## 许可证

MIT License
