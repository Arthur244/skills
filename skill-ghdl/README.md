# GitHub Downloader (skill-ghdl)

智能 GitHub 文件下载工具，支持 CDN 自动回退机制。

## 功能特点

- 🔄 **CDN 自动回退** - GitHub Raw 失败时自动切换到 jsDelivr CDN
- 🔗 **多格式 URL 支持** - 支持 GitHub Raw、Blob、jsDelivr 三种格式
- ⏱️ **超时控制** - 可配置连接超时和最大下载时间
- ✅ **文件验证** - 自动检查下载文件是否有效
- 🔇 **静默模式** - 支持脚本集成时禁用输出
- 📊 **详细返回值** - 返回下载源、URL 等详细信息

## 快速开始

### 下载单个文件

```powershell
# 使用 GitHub Raw URL
$result = Invoke-GitHubDownload `
    -Url "https://raw.githubusercontent.com/Arthur244/skills/refs/heads/main/skill-installer/SKILL.md" `
    -OutputPath "./SKILL.md"

# 使用 GitHub Blob URL
$result = Invoke-GitDownload `
    -Url "https://github.com/Arthur244/skills/blob/main/skill-installer/SKILL.md" `
    -OutputPath "./SKILL.md"
```

### 批量下载

```powershell
$files = @(
    @{ Url = "https://raw.githubusercontent.com/.../file1.md"; Output = "./file1.md" },
    @{ Url = "https://raw.githubusercontent.com/.../file2.md"; Output = "./file2.md" }
)

foreach ($file in $files) {
    Invoke-GitHubDownload -Url $file.Url -OutputPath $file.Output
}
```

## 核心函数

| 函数 | 说明 |
|------|------|
| `Invoke-SmartDownload` | 核心下载函数，支持 CDN 回退 |
| `ConvertTo-GitHubInfo` | URL 解析函数，提取 owner/repo/branch/path |
| `Invoke-GitHubDownload` | 一键下载函数，自动解析 URL 并下载 |

## 支持的 URL 格式

| 格式 | 示例 |
|------|------|
| GitHub Raw | `https://raw.githubusercontent.com/owner/repo/refs/heads/branch/path/file.md` |
| GitHub Blob | `https://github.com/owner/repo/blob/branch/path/file.md` |
| jsDelivr | `https://cdn.jsdelivr.net/gh/owner/repo@branch/path/file.md` |

## 与其他 Skill 集成

将 `Invoke-SmartDownload` 函数复制到目标 skill 中使用：

```powershell
$downloaded = Invoke-SmartDownload `
    -Owner "Arthur244" `
    -Repo "skills" `
    -Branch "main" `
    -FilePath "skill-vetter/SKILL.md" `
    -OutputPath "./skill-vetter/SKILL.md"

if (-not $downloaded.Success) {
    Write-Host "❌ 下载失败"
    exit 1
}
```

## License

MIT
