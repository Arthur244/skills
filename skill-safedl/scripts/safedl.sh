#!/usr/bin/env bash

set -euo pipefail

SMARTDL_CONNECT_TIMEOUT="${SMARTDL_CONNECT_TIMEOUT:-10}"
SMARTDL_MAX_TIME="${SMARTDL_MAX_TIME:-30}"
SMARTDL_SILENT="${SMARTDL_SILENT:-false}"

smart_download() {
    local owner="${1:-}"
    local repo="${2:-}"
    local branch="${3:-}"
    local file_path="${4:-}"
    local output_path="${5:-}"
    local connect_timeout="${6:-$SMARTDL_CONNECT_TIMEOUT}"
    local max_time="${7:-$SMARTDL_MAX_TIME}"
    local silent="${8:-$SMARTDL_SILENT}"
    
    if [[ -z "$owner" || -z "$repo" || -z "$branch" || -z "$file_path" || -z "$output_path" ]]; then
        echo "错误: 缺少必需参数" >&2
        echo "用法: smart_download <owner> <repo> <branch> <file_path> <output_path> [connect_timeout] [max_time] [silent]" >&2
        return 1
    fi
    
    local github_url="https://raw.githubusercontent.com/${owner}/${repo}/refs/heads/${branch}/${file_path}"
    local jsdelivr_url="https://cdn.jsdelivr.net/gh/${owner}/${repo}@${branch}/${file_path}"
    
    local output_dir
    output_dir=$(dirname "$output_path")
    if [[ -n "$output_dir" && ! -d "$output_dir" ]]; then
        mkdir -p "$output_dir"
    fi
    
    local sources=("GitHub Raw|$github_url" "jsDelivr CDN|$jsdelivr_url")
    
    for source in "${sources[@]}"; do
        local name="${source%%|*}"
        local url="${source##*|}"
        
        if [[ "$silent" != "true" ]]; then
            echo -n "  尝试从 $name 下载..."
        fi
        
        if curl -sL --connect-timeout "$connect_timeout" --max-time "$max_time" "$url" -o "$output_path" 2>/dev/null; then
            if [[ -f "$output_path" && -s "$output_path" ]]; then
                if [[ "$silent" != "true" ]]; then
                    echo " ✓ 成功"
                fi
                echo "SUCCESS|$name|$url"
                return 0
            fi
        fi
        
        if [[ "$silent" != "true" ]]; then
            echo " ✗ 失败"
        fi
    done
    
    if [[ "$silent" != "true" ]]; then
        echo "  ❌ 所有下载源均失败"
    fi
    echo "FAILED||"
    return 1
}

get_smart_file() {
    local url="${1:-}"
    local output_path="${2:-}"
    local connect_timeout="${3:-$SMARTDL_CONNECT_TIMEOUT}"
    local max_time="${4:-$SMARTDL_MAX_TIME}"
    local silent="${5:-$SMARTDL_SILENT}"
    
    if [[ -z "$url" || -z "$output_path" ]]; then
        echo "错误: 缺少必需参数" >&2
        echo "用法: get_smart_file <url> <output_path> [connect_timeout] [max_time] [silent]" >&2
        return 1
    fi
    
    local output_dir
    output_dir=$(dirname "$output_path")
    if [[ -n "$output_dir" && ! -d "$output_dir" ]]; then
        mkdir -p "$output_dir"
    fi
    
    if curl -sL --connect-timeout "$connect_timeout" --max-time "$max_time" "$url" -o "$output_path" 2>/dev/null; then
        if [[ -f "$output_path" && -s "$output_path" ]]; then
            if [[ "$silent" != "true" ]]; then
                echo "✓ 下载成功: $output_path"
            fi
            echo "SUCCESS|$url"
            return 0
        fi
    fi
    
    if [[ "$silent" != "true" ]]; then
        echo "❌ 下载失败: $url"
    fi
    echo "FAILED|$url"
    return 1
}

convert_to_jsdelivr_url() {
    local github_raw_url="${1:-}"
    
    if [[ "$github_raw_url" =~ raw\.githubusercontent\.com/([^/]+)/([^/]+)/refs/heads/([^/]+)/(.+) ]]; then
        local owner="${BASH_REMATCH[1]}"
        local repo="${BASH_REMATCH[2]}"
        local branch="${BASH_REMATCH[3]}"
        local path="${BASH_REMATCH[4]}"
        
        echo "https://cdn.jsdelivr.net/gh/${owner}/${repo}@${branch}/${path}"
        return 0
    fi
    
    echo ""
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        download)
            shift
            smart_download "$@"
            ;;
        get)
            shift
            get_smart_file "$@"
            ;;
        convert)
            shift
            convert_to_jsdelivr_url "$@"
            ;;
        *)
            echo "SafeDL - 安全下载工具"
            echo ""
            echo "用法:"
            echo "  $0 download <owner> <repo> <branch> <file_path> <output_path> [timeout] [max_time] [silent]"
            echo "  $0 get <url> <output_path> [timeout] [max_time] [silent]"
            echo "  $0 convert <github_raw_url>"
            echo ""
            echo "环境变量:"
            echo "  SMARTDL_CONNECT_TIMEOUT  连接超时（默认: 10秒）"
            echo "  SMARTDL_MAX_TIME         最大下载时间（默认: 30秒）"
            echo "  SMARTDL_SILENT           静默模式（默认: false）"
            ;;
    esac
fi
