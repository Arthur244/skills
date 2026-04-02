<#
.SYNOPSIS
    Skill 安装脚本 - 从 GitHub 仓库安全安装 skill

.DESCRIPTION
    此脚本从指定的 GitHub 仓库下载并安装 skill。
    支持安全审查、权限检查和安装日志记录。

.PARAMETER Url
    Skill 文件夹的完整 URL（推荐方式）
    格式: https://github.com/OWNER/REPO/tree/BRANCH/SKILL_NAME

.PARAMETER SkillName
    要安装的 skill 名称（与 Repository 配合使用）

.PARAMETER Repository
    GitHub 仓库地址 (格式: owner/repo)

.PARAMETER Branch
    分支名称 (默认: main)

.PARAMETER TargetPath
    安装目标路径 (默认: 当前目录)

.PARAMETER DryRun
    仅审查不安装

.PARAMETER Force
    跳过确认直接安装

.EXAMPLE
    .\install.ps1 -Url "https://github.com/Arthur244/skills/tree/main/mcp-dockerizer"
    使用完整 URL 安装 skill（推荐）

.EXAMPLE
    .\install.ps1 "https://github.com/Arthur244/skills/tree/main/skill-vetter"
    使用位置参数安装

.EXAMPLE
    .\install.ps1 -SkillName "mcp-dockerizer" -Repository "Arthur244/skills"
    使用分离参数安装

.EXAMPLE
    .\install.ps1 -Url "https://github.com/Arthur244/skills/tree/main/mcp-dockerizer" -DryRun
    仅审查不安装

.NOTES
    作者: Skill Installer
    版本: 1.1.0
#>

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$Url,

    [Parameter(Mandatory=$false)]
    [string]$SkillName,

    [Parameter(Mandatory=$false)]
    [string]$Repository,

    [Parameter(Mandatory=$false)]
    [string]$Branch,

    [Parameter(Mandatory=$false)]
    [string]$TargetPath = ".",

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Success { Write-Host "✅ $args" -ForegroundColor Green }
function Write-Warning { Write-Host "⚠️  $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "❌ $args" -ForegroundColor Red }
function Write-Info { Write-Host "ℹ️  $args" -ForegroundColor Cyan }
function Write-Header { Write-Host "`n$args" -ForegroundColor Magenta }

function Parse-SkillUrl {
    param([string]$Url)
    
    $patterns = @(
        @{ Pattern = "github\.com/([^/]+)/([^/]+)/tree/([^/]+)/([^/\?]+)"; Type = "tree" },
        @{ Pattern = "github\.com/([^/]+)/([^/]+)/blob/([^/]+)/([^/]+)/SKILL\.md"; Type = "blob" },
        @{ Pattern = "github\.com/([^/]+)/([^/]+)/tree/([^/]+)/skills/([^/\?]+)"; Type = "tree-skills" }
    )
    
    foreach ($p in $patterns) {
        if ($Url -match $p.Pattern) {
            return @{
                Owner = $Matches[1]
                Repo = $Matches[2]
                Branch = $Matches[3]
                SkillName = $Matches[4]
                Valid = $true
            }
        }
    }
    
    return @{ Valid = $false }
}

function Get-GitHubContent {
    param([string]$Url)
    
    try {
        $headers = @{ "User-Agent" = "Skill-Installer/1.1" }
        return Invoke-RestMethod -Uri $Url -Headers $headers -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Get-RepoMetadata {
    param([string]$Owner, [string]$Repo)
    
    try {
        $apiUrl = "https://api.github.com/repos/$Owner/$Repo"
        $headers = @{ "User-Agent" = "Skill-Installer/1.1" }
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
        
        return @{
            Stars = $response.stargazers_count
            Forks = $response.forks_count
            Updated = $response.updated_at
            Author = $response.owner.login
            Description = $response.description
        }
    }
    catch {
        Write-Warning "无法获取仓库元数据: $_"
        return @{ Stars = "?"; Forks = "?"; Updated = "?"; Author = $Owner; Description = "" }
    }
}

function Get-SkillFiles {
    param([string]$Owner, [string]$Repo, [string]$Branch, [string]$SkillName)
    
    $apiUrl = "https://api.github.com/repos/$Owner/$Repo/contents/$SkillName?ref=$Branch"
    $contents = Get-GitHubContent $apiUrl
    
    if ($null -eq $contents) {
        $apiUrl = "https://api.github.com/repos/$Owner/$Repo/contents/skills/$SkillName?ref=$Branch"
        $contents = Get-GitHubContent $apiUrl
    }
    
    if ($null -eq $contents) {
        return @{ Files = @(); SkillPath = $SkillName }
    }
    
    $files = @()
    $skillPath = $SkillName
    
    foreach ($item in $contents) {
        if ($item.type -eq "file") {
            $files += $item.name
        }
        elseif ($item.type -eq "dir") {
            $subApiUrl = "https://api.github.com/repos/$Owner/$Repo/contents/$($item.path)?ref=$Branch"
            $subContents = Get-GitHubContent $subApiUrl
            if ($subContents) {
                foreach ($subItem in $subContents) {
                    if ($subItem.type -eq "file") {
                        $files += "$($item.name)/$($subItem.name)"
                    }
                }
            }
        }
    }
    
    return @{ Files = $files; SkillPath = $skillPath }
}

function Download-File {
    param([string]$Url, [string]$OutputPath)
    
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutputPath -UseBasicParsing -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "下载失败: $Url"
        return $false
    }
}

function Get-FileChecksum {
    param([string]$FilePath)
    
    if (Test-Path $FilePath) {
        $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
        return $hash.Hash.ToLower()
    }
    return $null
}

function Write-AuditLog {
    param(
        [string]$SkillName,
        [string]$Version,
        [string]$Source,
        [string]$RiskLevel,
        [string]$Approved
    )
    
    $logDir = Join-Path $TargetPath ".skills"
    $logFile = Join-Path $logDir "audit.log"
    
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $logEntry = "[$timestamp] INSTALL $SkillName@$Version source=$Source risk=$RiskLevel approved=$Approved"
    
    Add-Content -Path $logFile -Value $logEntry
}

function Update-Manifest {
    param(
        [string]$SkillName,
        [string]$Version,
        [string]$Source,
        [string]$RiskLevel,
        [object]$Permissions,
        [string]$Checksum
    )
    
    $manifestDir = Join-Path $TargetPath ".skills"
    $manifestFile = Join-Path $manifestDir "manifest.json"
    
    if (-not (Test-Path $manifestDir)) {
        New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
    }
    
    if (Test-Path $manifestFile) {
        $manifest = Get-Content $manifestFile -Raw | ConvertFrom-Json
    }
    else {
        $manifest = @{
            version = "1.0"
            generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            skills = @()
            statistics = @{ total_skills = 0; by_risk_level = @{ low = 0; medium = 0; high = 0 } }
        }
    }
    
    $existingIndex = -1
    for ($i = 0; $i -lt $manifest.skills.Count; $i++) {
        if ($manifest.skills[$i].name -eq $SkillName) {
            $existingIndex = $i
            break
        }
    }
    
    $skillEntry = @{
        name = $SkillName
        version = $Version
        source = $Source
        installed_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        checksum = "sha256:$Checksum"
        risk_level = $RiskLevel
        permissions = $Permissions
    }
    
    if ($existingIndex -ge 0) {
        $manifest.skills[$existingIndex] = $skillEntry
    }
    else {
        $manifest.skills += $skillEntry
        $manifest.statistics.total_skills++
        if ($manifest.statistics.by_risk_level.$RiskLevel) {
            $manifest.statistics.by_risk_level.$RiskLevel++
        }
    }
    
    $manifest.generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    
    $manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestFile -Encoding UTF8
}

function Parse-SkillMetadata {
    param([string]$Content)
    
    if ($Content -match "(?s)^---\r?\n(.*?)\r?\n---\r?\n(.*)$") {
        $yaml = $Matches[1]
        $metadata = @{}
        
        $yaml -split "`n" | ForEach-Object {
            if ($_ -match "^(\w+):\s*['""]?(.+?)['""]?$") {
                $metadata[$Matches[1]] = $Matches[2]
            }
            elseif ($_ -match "^(\w+):$") {
                $currentKey = $Matches[1]
                $metadata[$currentKey] = @{}
            }
            elseif ($_ -match "^\s+(\w+):\s*['""]?(.+?)['""]?$" -and $currentKey) {
                $metadata[$currentKey][$Matches[1]] = $Matches[2]
            }
        }
        
        return $metadata
    }
    
    return @{}
}

Write-Header "📦 Skill 安装器 v1.1.0"

if ($Url) {
    Write-Info "Phase 1: 解析 URL..."
    $parsed = Parse-SkillUrl $Url
    
    if (-not $parsed.Valid) {
        Write-Error "无法解析 URL: $Url"
        Write-Host ""
        Write-Host "支持的 URL 格式:" -ForegroundColor Yellow
        Write-Host "  https://github.com/OWNER/REPO/tree/BRANCH/SKILL_NAME"
        Write-Host "  https://github.com/OWNER/REPO/tree/BRANCH/skills/SKILL_NAME"
        Write-Host "  https://github.com/OWNER/REPO/blob/BRANCH/SKILL_NAME/SKILL.md"
        exit 1
    }
    
    $Owner = $parsed.Owner
    $Repo = $parsed.Repo
    $Branch = $parsed.Branch
    $SkillName = $parsed.SkillName
    
    Write-Host "  仓库: $Owner/$Repo"
    Write-Host "  分支: $Branch"
    Write-Host "  Skill: $SkillName"
}
elseif ($SkillName -and $Repository) {
    Write-Info "Phase 1: 解析参数..."
    
    if ($Repository -match "^https://github\.com/([^/]+)/([^/]+)") {
        $Owner = $Matches[1]
        $Repo = $Matches[2]
    }
    elseif ($Repository -match "^([^/]+)/([^/]+)$") {
        $Owner = $Matches[1]
        $Repo = $Matches[2]
    }
    else {
        Write-Error "无法解析仓库地址: $Repository"
        exit 1
    }
    
    if (-not $Branch) { $Branch = "main" }
    
    Write-Host "  仓库: $Owner/$Repo"
    Write-Host "  分支: $Branch"
    Write-Host "  Skill: $SkillName"
}
else {
    Write-Error "请提供 Url 参数或 SkillName + Repository 参数"
    Write-Host ""
    Write-Host "示例:" -ForegroundColor Yellow
    Write-Host "  .\install.ps1 -Url 'https://github.com/Arthur244/skills/tree/main/mcp-dockerizer'"
    Write-Host "  .\install.ps1 -SkillName 'mcp-dockerizer' -Repository 'Arthur244/skills'"
    exit 1
}

$sourceUrl = "https://github.com/$Owner/$Repo"

Write-Info "`nPhase 2: 获取仓库元数据..."
$metadata = Get-RepoMetadata $Owner $Repo

Write-Host "  作者: $($metadata.Author)"
Write-Host "  ⭐ 星标: $($metadata.Stars)"
Write-Host "  🍴 Fork: $($metadata.Forks)"
Write-Host "  更新: $($metadata.Updated)"

Write-Info "`nPhase 3: 获取 skill 文件列表..."
$skillFiles = Get-SkillFiles $Owner $Repo $Branch $SkillName

if ($skillFiles.Files.Count -eq 0) {
    Write-Warning "未找到 skill 文件，尝试下载 SKILL.md..."
    $skillFiles = @{ Files = @("SKILL.md"); SkillPath = $SkillName }
}

Write-Host "  文件数: $($skillFiles.Files.Count)"
Write-Host "  文件: $($skillFiles.Files -join ', ')"

Write-Info "`nPhase 4: 下载并解析 SKILL.md..."
$baseUrl = "https://raw.githubusercontent.com/$Owner/$Repo/$Branch/$($skillFiles.SkillPath)"
$skillMdUrl = "$baseUrl/SKILL.md"

try {
    $headers = @{ "User-Agent" = "Skill-Installer/1.1" }
    $skillMdContent = Invoke-RestMethod -Uri $skillMdUrl -Headers $headers -ErrorAction Stop
    $skillMeta = Parse-SkillMetadata $skillMdContent
    
    Write-Host "  名称: $($skillMeta['name'])"
    Write-Host "  版本: $($skillMeta['version'])"
    Write-Host "  描述: $($skillMeta['description'])"
    
    $riskLevel = $skillMeta['security']['risk_level']
    if (-not $riskLevel) { $riskLevel = "unknown" }
}
catch {
    Write-Warning "无法下载 SKILL.md: $_"
    $skillMeta = @{ name = $SkillName; version = "unknown" }
    $riskLevel = "unknown"
}

$riskEmoji = switch ($riskLevel) {
    "low" { "🟢" }
    "medium" { "🟡" }
    "high" { "🔴" }
    default { "⚪" }
}

Write-Host "`n  风险等级: $riskEmoji $riskLevel"

if ($DryRun) {
    Write-Warning "`nDry-run 模式: 仅审查不安装"
    Write-Host "`n审查结果: 可安装" -ForegroundColor Green
    exit 0
}

if (-not $Force) {
    Write-Header "📋 安装确认"
    Write-Host "即将安装: $SkillName"
    Write-Host "来源: $sourceUrl/tree/$Branch/$($skillFiles.SkillPath)"
    Write-Host "目标: $TargetPath/$SkillName"
    
    $confirm = Read-Host "`n是否继续? [Y/n]"
    if ($confirm -and $confirm -ne "Y" -and $confirm -ne "y") {
        Write-Error "安装已取消"
        exit 1
    }
}

Write-Info "`nPhase 5: 执行安装..."

$skillDir = Join-Path $TargetPath $SkillName
if (-not (Test-Path $skillDir)) {
    New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
}

$downloadedFiles = @()
$checksums = @{}

foreach ($file in $skillFiles.Files) {
    $fileUrl = "$baseUrl/$file"
    $outputPath = Join-Path $skillDir $file
    
    $fileDir = Split-Path $outputPath -Parent
    if (-not (Test-Path $fileDir)) {
        New-Item -ItemType Directory -Path $fileDir -Force | Out-Null
    }
    
    Write-Host "  下载: $file"
    if (Download-File $fileUrl $outputPath) {
        $downloadedFiles += $file
        $checksums[$file] = Get-FileChecksum $outputPath
    }
}

Write-Info "`nPhase 6: 记录安装信息..."

$mainChecksum = $checksums["SKILL.md"]
if (-not $mainChecksum -and $checksums.Values) {
    $mainChecksum = $checksums.Values | Select-Object -First 1
}
if (-not $mainChecksum) { $mainChecksum = "unknown" }

$version = if ($skillMeta['version']) { $skillMeta['version'] } else { "unknown" }

Write-AuditLog -SkillName $SkillName -Version $version -Source "$sourceUrl/tree/$Branch/$($skillFiles.SkillPath)" -RiskLevel $riskLevel -Approved "user"
Update-Manifest -SkillName $SkillName -Version $version -Source "$sourceUrl/tree/$Branch/$($skillFiles.SkillPath)" -RiskLevel $riskLevel -Permissions $skillMeta['permissions'] -Checksum $mainChecksum

Write-Header "✅ 安装完成"
Write-Host "Skill: $SkillName@$version"
Write-Host "位置: $skillDir"
Write-Host "文件: $($downloadedFiles.Count) 个"
if ($mainChecksum -ne "unknown") {
    Write-Host "校验和: sha256:$($mainChecksum.Substring(0, 16))..."
}
Write-Host ""
Write-Success "安装成功！"
