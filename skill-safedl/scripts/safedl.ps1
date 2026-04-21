function Invoke-SmartDownload {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Owner,
        
        [Parameter(Mandatory=$true)]
        [string]$Repo,
        
        [Parameter(Mandatory=$true)]
        [string]$Branch,
        
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [int]$ConnectTimeout = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxTime = 30,
        
        [Parameter(Mandatory=$false)]
        [switch]$Silent
    )
    
    $sources = @(
        @{
            Name = "GitHub Raw"
            Url = "https://raw.githubusercontent.com/$Owner/$Repo/refs/heads/$Branch/$FilePath"
        },
        @{
            Name = "jsDelivr CDN"
            Url = "https://cdn.jsdelivr.net/gh/$Owner/$Repo@$Branch/$FilePath"
        }
    )
    
    $outputDir = Split-Path $OutputPath -Parent
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    $curlCommands = @("curl.exe", "curl")
    $isWindows = $IsWindows -or ($env:OS -eq "Windows_NT")
    
    if ($isWindows) {
        $curlCommands = @("curl.exe", "curl")
    } else {
        $curlCommands = @("curl")
    }
    
    foreach ($source in $sources) {
        if (-not $Silent) {
            Write-Host "  尝试从 $($source.Name) 下载..." -NoNewline
        }
        
        $downloaded = $false
        foreach ($curlCmd in $curlCommands) {
            try {
                $result = & $curlCmd -sL --connect-timeout $ConnectTimeout --max-time $MaxTime "$($source.Url)" -o "$OutputPath" 2>&1
                
                if ((Test-Path $OutputPath) -and ((Get-Item $OutputPath).Length -gt 0)) {
                    if (-not $Silent) {
                        Write-Host " ✓ 成功"
                    }
                    return @{
                        Success = $true
                        Source = $source.Name
                        Url = $source.Url
                    }
                }
            } catch {
                continue
            }
        }
        
        if (-not $Silent) {
            Write-Host " ✗ 失败"
        }
        continue
    }
    
    if (-not $Silent) {
        Write-Host "  ❌ 所有下载源均失败"
    }
    return @{
        Success = $false
        Source = $null
        Url = $null
    }
}

function Get-SmartFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [int]$ConnectTimeout = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxTime = 30,
        
        [Parameter(Mandatory=$false)]
        [switch]$Silent
    )
    
    $outputDir = Split-Path $OutputPath -Parent
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    $curlCommands = @("curl.exe", "curl")
    $isWindows = $IsWindows -or ($env:OS -eq "Windows_NT")
    
    if ($isWindows) {
        $curlCommands = @("curl.exe", "curl")
    } else {
        $curlCommands = @("curl")
    }
    
    foreach ($curlCmd in $curlCommands) {
        try {
            $result = & $curlCmd -sL --connect-timeout $ConnectTimeout --max-time $MaxTime "$Url" -o "$OutputPath" 2>&1
            
            if ((Test-Path $OutputPath) -and ((Get-Item $OutputPath).Length -gt 0)) {
                if (-not $Silent) {
                    Write-Host "✓ 下载成功: $OutputPath"
                }
                return @{
                    Success = $true
                    Url = $Url
                }
            }
        } catch {
            continue
        }
    }
    
    if (-not $Silent) {
        Write-Host "❌ 下载失败: $Url"
    }
    return @{
        Success = $false
        Url = $Url
    }
}

function ConvertTo-JsDelivrUrl {
    param(
        [Parameter(Mandatory=$true)]
        [string]$GitHubRawUrl
    )
    
    if ($GitHubRawUrl -match 'raw\.githubusercontent\.com/([^/]+)/([^/]+)/refs/heads/([^/]+)/(.+)') {
        $owner = $matches[1]
        $repo = $matches[2]
        $branch = $matches[3]
        $path = $matches[4]
        
        return "https://cdn.jsdelivr.net/gh/$owner/$repo@$branch/$path"
    }
    
    return $null
}

Export-ModuleMember -Function Invoke-SmartDownload, Get-SmartFile, ConvertTo-JsDelivrUrl
