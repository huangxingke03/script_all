#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

# =============================================
# JIRA 附件下载工具（过滤版）
# 用法: download_jira_filtered <JIRA单号>
# 示例: download_jira_filtered CHYKP31-1028
#       download_jira_filtered DP-5927
# =============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JIRA_CURL_EXPORT_FILE="${JIRA_CURL_EXPORT_FILE:-${SCRIPT_DIR}/download_jira_request.curl}"

extract_curl_field() {
    local curl_file="$1"
    local field_name="$2"

    python3 - "$curl_file" "$field_name" <<'PYINNER'
import shlex
import sys
from pathlib import Path

curl_file = Path(sys.argv[1])
field_name = sys.argv[2].lower()
text = curl_file.read_text().replace('\\\n', ' ')
parts = shlex.split(text)
headers = {}
url = ''
cookie = ''

for i, part in enumerate(parts):
    if part in ('-H', '--header') and i + 1 < len(parts):
        header = parts[i + 1]
        if ':' in header:
            name, value = header.split(':', 1)
            headers[name.strip().lower()] = value.strip()
    elif part in ('-b', '--cookie') and i + 1 < len(parts):
        cookie = parts[i + 1]
    elif not part.startswith('-') and part.startswith('http'):
        url = part

if field_name == 'cookie':
    print(cookie or headers.get('cookie', ''), end='')
elif field_name == 'url':
    print(url, end='')
PYINNER
}

if [ ! -f "$JIRA_CURL_EXPORT_FILE" ]; then
    echo "❌ 缺少 JIRA cURL 配置文件: $JIRA_CURL_EXPORT_FILE"
    exit 1
fi

COOKIE=$(extract_curl_field "$JIRA_CURL_EXPORT_FILE" "cookie")
if [ -z "$COOKIE" ]; then
    echo "❌ 未能从 $JIRA_CURL_EXPORT_FILE 提取 Cookie，请确认内容包含 -b 或 Cookie 头"
    exit 1
fi

if [ -z "$1" ]; then
    echo "用法: download_jira_filtered <JIRA单号>"
    echo "示例: download_jira_filtered CHYKP31-1028"
    exit 1
fi

TICKET=$1
SAVE_DIR="/home/huangxingke/下载/${TICKET}"

# ==================== 每次下载前清空旧文件 ====================
echo "🧹 正在清理旧文件..."
rm -rf "$SAVE_DIR"          # 删除旧文件夹及所有内容
mkdir -p "$SAVE_DIR"

echo "══════════════════════════════════════"
echo "🚀 开始下载 JIRA: $TICKET（过滤 mcu_/qnx_ 前缀和 .asc 附件）"
echo "保存目录: $SAVE_DIR （旧文件已清理）"
echo "══════════════════════════════════════"

# 判断附件是否需要显示下载进度条
should_show_progress() {
    local lower_name="${1,,}"
    case "$lower_name" in
        *.zip|*.z[0-9][0-9]|*.tar.gz|*.tgz|*.7z|*.[0-9][0-9][0-9]|*.rar|*.r[0-9][0-9]|*.part[0-9]*.rar|*.log|*.mp4|*.mov|*.mkv|*.txt)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

normalize_attachment_name() {
    local raw_name="$1"

    raw_name="${raw_name/$'\r'/}"
    raw_name="${raw_name##*/}"
    raw_name="${raw_name##*\\}"
    raw_name="${raw_name#"${raw_name%%[![:space:]]*}"}"
    raw_name="${raw_name%"${raw_name##*[![:space:]]}"}"

    printf '%s' "$raw_name"
}

should_skip_attachment() {
    local lower_name

    lower_name="$(normalize_attachment_name "$1")"
    lower_name="${lower_name,,}"
    case "$lower_name" in
        mcu_*|qnx_*|*.asc)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}


should_skip_extract_path() {
    local normalized_path lower_path

    normalized_path="$(normalize_attachment_name "$1")"
    normalized_path="${normalized_path#./}"
    lower_path="${normalized_path,,}"

    case "$lower_path" in
        qnx_log/*|*/qnx_log/*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

format_size() {
    local bytes="$1"

    awk -v bytes="$bytes" 'BEGIN {
        split("B KB MB GB TB", units, " ")
        size = bytes + 0
        idx = 1
        while (size >= 1024 && idx < 5) {
            size /= 1024
            idx++
        }
        if (idx == 1) {
            printf "%d %s", bytes, units[idx]
        } else {
            printf "%.1f %s", size, units[idx]
        }
    }'
}

fetch_remote_size() {
    local url="$1"

    curl -fsSIL -b "$COOKIE" -L "$url" 2>/dev/null         | tr -d "\r"         | awk 'BEGIN { IGNORECASE = 1 }
            /^content-length:/ { size = $2 }
            END {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", size)
                print size
            }'
}

build_progress_bar() {
    local percent="$1"
    local width=24
    local filled=$(( percent * width / 100 ))
    local empty=$(( width - filled ))
    local bar_filled bar_empty

    printf -v bar_filled '%*s' "$filled" ''
    printf -v bar_empty '%*s' "$empty" ''
    bar_filled=${bar_filled// /=}
    bar_empty=${bar_empty// /-}
    printf '[%s%s]' "$bar_filled" "$bar_empty"
}

build_activity_bar() {
    local tick="$1"
    local width=24
    local pos=$(( tick % width ))
    local i bar='['

    for (( i=0; i<width; i++ )); do
        if [ "$i" -eq "$pos" ]; then
            bar+='#'
        else
            bar+='-'
        fi
    done
    bar+=']'
    printf '%s' "$bar"
}

download_with_progress() {
    local url="$1"
    local filepath="$2"
    local remote_size="$3"
    local pid current_size percent progress_bar status line display_size tick=0

    : > "$filepath"
    curl -f -sS -b "$COOKIE" -L -o "$filepath" "$url" &
    pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        current_size=$(stat -c%s "$filepath" 2>/dev/null || echo 0)
        display_size="$current_size"
        line="   已下载包大小: $(format_size "$current_size")"

        if [[ "$remote_size" =~ ^[0-9]+$ ]] && [ "$remote_size" -gt 0 ]; then
            if [ "$display_size" -gt "$remote_size" ]; then
                display_size="$remote_size"
            fi
            percent=$(( display_size * 100 / remote_size ))
            if [ "$percent" -gt 100 ]; then
                percent=100
            fi
            progress_bar=$(build_progress_bar "$percent")
            line+=" / 总包大小: $(format_size "$remote_size") ${progress_bar} (${percent}%)"
        else
            percent=$(( tick % 100 ))
            progress_bar=$(build_progress_bar "$percent")
            line+=" ${progress_bar} (${percent}%)"
        fi

        printf '\r\033[2K%s' "$line"
        tick=$(( tick + 1 ))
        sleep 1
    done

    wait "$pid"
    status=$?
    current_size=$(stat -c%s "$filepath" 2>/dev/null || echo 0)
    display_size="$current_size"
    line="   已下载包大小: $(format_size "$current_size")"

    if [[ "$remote_size" =~ ^[0-9]+$ ]] && [ "$remote_size" -gt 0 ]; then
        if [ "$status" -eq 0 ]; then
            current_size="$remote_size"
            display_size="$remote_size"
            percent=100
        else
            if [ "$display_size" -gt "$remote_size" ]; then
                display_size="$remote_size"
            fi
            percent=$(( display_size * 100 / remote_size ))
            if [ "$percent" -gt 100 ]; then
                percent=100
            fi
        fi
        line="   已下载包大小: $(format_size "$current_size")"
        progress_bar=$(build_progress_bar "$percent")
        line+=" / 总包大小: $(format_size "$remote_size") ${progress_bar} (${percent}%)"
    else
        if [ "$status" -eq 0 ]; then
            percent=100
        else
            percent=$(( tick % 100 ))
        fi
        progress_bar=$(build_progress_bar "$percent")
        line+=" ${progress_bar} (${percent}%)"
    fi

    printf '\r\033[2K%s\n' "$line"
    return "$status"
}

# 下载附件；压缩包、日志、视频显示实时进度，其它文件静默下载
download_attachment() {
    local url="$1"
    local filepath="$2"
    local filename="$3"
    local remote_size

    if should_show_progress "$filename"; then
        remote_size=$(fetch_remote_size "$url")
        if [[ "$remote_size" =~ ^[0-9]+$ ]] && [ "$remote_size" -gt 0 ]; then
            echo "   📦 包总大小: $(format_size "$remote_size")"
        fi
        download_with_progress "$url" "$filepath" "$remote_size"
    else
        curl -f -s -b "$COOKIE" -L -o "$filepath" "$url"
    fi
}

if ! command -v jq >/dev/null 2>&1; then
    echo "❌ 未安装 jq，请先安装：sudo apt install jq"
    exit 1
fi

# 获取附件列表
JSON=$(curl -s -b "$COOKIE"   -H "Content-Type: application/json"   -H "X-Atlassian-Token: no-check"   "https://jira-shzj.auto-link.com.cn/rest/api/2/issue/${TICKET}?fields=attachment")

# 权限检查
if echo "$JSON" | grep -q "您没有查看特定问题的权限\|必须登录"; then
    echo "❌ Cookie 失效或无权限，请更新 Cookie 后重试"
    exit 1
fi

if ! echo "$JSON" | jq -e . >/dev/null 2>&1; then
    echo "❌ JIRA 接口返回的不是合法 JSON，可能是登录页或网关异常"
    echo "响应片段:"
    echo "$JSON" | head -c 300
    echo ""
    exit 1
fi

API_ERROR=$(echo "$JSON" | jq -r '(.errorMessages // [])[]?, (.errors // {} | to_entries[]? | "\(.key): \(.value)")')
if [ -n "$API_ERROR" ]; then
    echo "❌ JIRA 接口返回错误:"
    echo "$API_ERROR"
    exit 1
fi

if ! echo "$JSON" | jq -e '.fields and (.fields | has("attachment"))' >/dev/null 2>&1; then
    echo "❌ JIRA 响应里没有 attachment 字段，响应结构异常"
    echo "响应片段:"
    echo "$JSON" | jq -c '.' | head -c 300
    echo ""
    exit 1
fi

COUNT=$(echo "$JSON" | jq '.fields.attachment | length')
echo "✅ 找到 $COUNT 个附件，开始下载..."

# 下载循环
mapfile -t ATTACHMENTS < <(echo "$JSON" | jq -r '.fields.attachment[]? | [.content, .filename] | @tsv')

for attachment in "${ATTACHMENTS[@]}"; do
    IFS=$'\t' read -r url filename <<< "$attachment"
    if [ -n "$url" ] && [ -n "$filename" ]; then
        filename="$(normalize_attachment_name "$filename")"
        if should_skip_attachment "$filename"; then
            echo "⏭️ 跳过附件: $filename"
            continue
        fi

        filepath="${SAVE_DIR}/${filename}"
        echo "⬇️ 下载: $filename"

        if download_attachment "$url" "$filepath" "$filename" && [ -s "$filepath" ]; then
            size=$(du -h "$filepath" | cut -f1)
            echo "✅ 下载完成: $filename ($size)"
            case "$filename" in
                *.zip|*.z[0-9][0-9])
                    echo "   📦 检测到 ZIP 文件: $filename，等待全部文件下载完毕后统一解压"
                    ;;
                *.tar.gz|*.tgz)
                    echo "   📦 检测到 TAR.GZ 文件: $filename，等待全部文件下载完毕后统一解压"
                    ;;
                *.7z|*.[0-9][0-9][0-9])
                    echo "   📦 检测到 7z 文件: $filename，等待全部文件下载完毕后统一解压"
                    ;;
                *.rar|*.r[0-9][0-9])
                    echo "   📦 检测到 RAR 文件: $filename，等待全部文件下载完毕后统一解压"
                    ;;
                *.log|*.mp4|*.mov|*.mkv|*.txt)
                    echo "   📄 日志/视频文件，无需解压"
                    ;;
                *)
                    echo "   📎 其他格式，跳过解压"
                    ;;
            esac
        else
            echo "❌ 下载失败: $filename"
        fi
    fi
done

# ==================== 统一解压（全部文件下载完毕后执行）====================
cd "$SAVE_DIR" || exit 1
shopt -s nullglob nocaseglob

declare -A extracted_archives_seen removed_archives_seen

is_supported_archive() {
    local lower_name="${1,,}"
    case "$lower_name" in
        *.zip|*.tar.gz|*.tgz|*.7z|*.001|*.rar|*.part1.rar)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

extract_one_archive() {
    local f="$1"
    local lower_name="${f,,}"
    local archive_dir archive_name archive_stem extract_target_dir base companions has_companion=false vol_count

    archive_dir="$(dirname "$f")"
    archive_name="$(basename "$f")"
    [ "$archive_dir" = "." ] && archive_dir="$SAVE_DIR"

    archive_stem="$archive_name"
    case "$lower_name" in
        *.tar.gz)
            archive_stem="${archive_name%.tar.gz}"
            ;;
        *.tgz)
            archive_stem="${archive_name%.tgz}"
            ;;
        *.part1.rar)
            archive_stem="${archive_name%.part1.rar}"
            ;;
        *.rar)
            archive_stem="${archive_name%.rar}"
            ;;
        *.zip)
            archive_stem="${archive_name%.zip}"
            ;;
        *.7z)
            archive_stem="${archive_name%.7z}"
            ;;
        *.001)
            archive_stem="${archive_name%.001}"
            ;;
    esac

    extract_target_dir="${archive_dir}/${archive_stem}"
    mkdir -p "$extract_target_dir"

    case "$lower_name" in
        *.zip)
            base="${f%.*}"
            companions=( "${base}".z[0-9][0-9] "${base}".Z[0-9][0-9] )
            for c in "${companions[@]}"; do
                [ -f "$c" ] && has_companion=true && break
            done
            if $has_companion; then
                vol_count=$(ls "${base}".z[0-9][0-9] "${base}".Z[0-9][0-9] 2>/dev/null | wc -l)
                echo "📦 解压 ZIP 分卷: $f -> $extract_target_dir（共 $((vol_count + 1)) 个分卷）"
                (
                    cd "$archive_dir" &&
                    7z x -y -aoa "-o$extract_target_dir" "$archive_name"
                ) >/dev/null 2>&1 && echo "   ✅ ZIP 分卷解压完成" || {
                    echo "   ❌ ZIP 分卷解压失败："
                    (
                        cd "$archive_dir" &&
                        7z x -y -aoa "-o$extract_target_dir" "$archive_name"
                    ) 2>&1 | tail -n 20
                    printf '   💡 手动：cd "%s" && 7z x -o"%s" "%s"
' "$archive_dir" "$extract_target_dir" "$archive_name"
                }
            else
                echo "📦 解压 ZIP: $f -> $extract_target_dir"
                unzip -o "$f" -d "$extract_target_dir" >/dev/null 2>&1 && echo "   ✅ ZIP 解压完成" || { echo "   ❌ ZIP 解压失败"; printf '   💡 手动：cd "%s" && unzip "%s" -d "%s"
' "$archive_dir" "$archive_name" "$extract_target_dir"; }
            fi
            ;;
        *.tar.gz|*.tgz)
            echo "📦 解压 TAR.GZ: $f -> $extract_target_dir"
            tar -xzf "$f" -C "$extract_target_dir" && echo "   ✅ TAR.GZ 解压完成" || { echo "   ❌ TAR.GZ 解压失败"; printf '   💡 手动：cd "%s" && tar -xzf "%s" -C "%s"
' "$archive_dir" "$archive_name" "$extract_target_dir"; }
            ;;
        *.001)
            base="${f%.*}"
            vol_count=$(ls "${base}".[0-9][0-9][0-9] 2>/dev/null | wc -l)
            echo "📦 解压 7z 分卷: $f -> $extract_target_dir（共 $vol_count 个分卷）"
            if (
                cd "$archive_dir" &&
                7z x -y -aoa "-o$extract_target_dir" "$archive_name"
            ) >/dev/null 2>&1; then
                echo "   ✅ 7z 分卷解压完成"
            elif command -v unar >/dev/null 2>&1 && (
                cd "$archive_dir" &&
                unar -force-overwrite -output-directory "$extract_target_dir" "$archive_name"
            ) >/dev/null 2>&1; then
                echo "   ✅ unar 解压完成"
            else
                echo "   ❌ 7z 分卷解压失败："
                (
                    cd "$archive_dir" &&
                    7z x -y -aoa "-o$extract_target_dir" "$archive_name"
                ) 2>&1 | tail -n 20
                printf '   💡 手动：cd "%s" && 7z x -o"%s" "%s"
' "$archive_dir" "$extract_target_dir" "$archive_name"
            fi
            ;;
        *.7z)
            echo "📦 解压 7z: $f -> $extract_target_dir"
            if (
                cd "$archive_dir" &&
                7z x -y -aoa "-o$extract_target_dir" "$archive_name"
            ) >/dev/null 2>&1; then
                echo "   ✅ 7z 解压完成"
            elif command -v unar >/dev/null 2>&1 && (
                cd "$archive_dir" &&
                unar -force-overwrite -output-directory "$extract_target_dir" "$archive_name"
            ) >/dev/null 2>&1; then
                echo "   ✅ unar 解压完成"
            else
                echo "   ❌ 7z 解压失败："
                (
                    cd "$archive_dir" &&
                    7z x -y -aoa "-o$extract_target_dir" "$archive_name"
                ) 2>&1 | tail -n 20
                printf '   💡 手动：cd "%s" && 7z x -o"%s" "%s"
' "$archive_dir" "$extract_target_dir" "$archive_name"
            fi
            ;;
        *.part1.rar)
            if command -v unrar >/dev/null 2>&1; then
                base="${f%.*}"
                base="${base%.*}"
                vol_count=$(ls "${base}".part[0-9]*.rar 2>/dev/null | wc -l)
                echo "📦 解压 RAR 分卷(新格式): $f -> $extract_target_dir（共 $vol_count 个分卷）"
                (
                    cd "$archive_dir" &&
                    unrar x -o+ "$archive_name" "$extract_target_dir/"
                ) >/dev/null 2>&1 && echo "   ✅ RAR 分卷解压完成" || { echo "   ❌ RAR 分卷解压失败"; printf '   💡 手动：cd "%s" && unrar x "%s" "%s/"
' "$archive_dir" "$archive_name" "$extract_target_dir"; }
            else
                echo "⚠️ 未安装 unrar，RAR 文件跳过（安装：sudo apt install unrar）"
            fi
            ;;
        *.rar)
            if command -v unrar >/dev/null 2>&1; then
                if [[ "$lower_name" =~ \.part[0-9]+\.rar$ ]]; then
                    return 0
                fi
                base="${f%.*}"
                if ls "${base}".r[0-9][0-9] &>/dev/null; then
                    vol_count=$(( $(ls "${base}".r[0-9][0-9] 2>/dev/null | wc -l) + 1 ))
                    echo "📦 解压 RAR 分卷(旧格式): $f -> $extract_target_dir（共 $vol_count 个分卷）"
                else
                    echo "📦 解压 RAR: $f -> $extract_target_dir"
                fi
                (
                    cd "$archive_dir" &&
                    unrar x -o+ "$archive_name" "$extract_target_dir/"
                ) >/dev/null 2>&1 && echo "   ✅ RAR 解压完成" || { echo "   ❌ RAR 解压失败"; printf '   💡 手动：cd "%s" && unrar x "%s" "%s/"
' "$archive_dir" "$archive_name" "$extract_target_dir"; }
            else
                echo "⚠️ 未安装 unrar，RAR 文件跳过（安装：sudo apt install unrar）"
            fi
            ;;
    esac
}

extract_archives_recursively() {
    local archive lower_name processed_in_pass
    local -a archives=()
    local -A skipped_extract_paths_seen=()

    while :; do
        processed_in_pass=0
        archives=()
        while IFS= read -r -d '' archive; do
            archive="${archive#./}"
            archives+=( "$archive" )
        done < <(find . -type f -print0)

        for archive in "${archives[@]}"; do
            [ -f "$archive" ] || continue
            is_supported_archive "$archive" || continue

            lower_name="${archive,,}"
            case "$lower_name" in
                *.z[0-9][0-9]|*.r[0-9][0-9])
                    continue
                    ;;
            esac
            if [[ "$lower_name" =~ \.part[0-9]+\.rar$ ]] && [[ "$lower_name" != *.part1.rar ]]; then
                continue
            fi
            if [[ "$lower_name" =~ \.[0-9]{3}$ ]] && [[ "$lower_name" != *.001 ]]; then
                continue
            fi

            if should_skip_extract_path "$archive"; then
                [[ -n "${skipped_extract_paths_seen[$archive]}" ]] && continue
                echo "⏭️ 跳过目录内压缩包解压: $archive"
                skipped_extract_paths_seen["$archive"]=1
                continue
            fi

            if should_skip_attachment "$archive"; then
                [[ -n "${removed_archives_seen[$archive]}" ]] && continue
                echo "⏭️ 删除过滤压缩包: $archive"
                rm -f -- "$archive"
                removed_archives_seen["$archive"]=1
                processed_in_pass=1
                continue
            fi

            [[ -n "${extracted_archives_seen[$archive]}" ]] && continue
            extracted_archives_seen["$archive"]=1
            extract_one_archive "$archive"
            processed_in_pass=1
        done

        [ "$processed_in_pass" -eq 1 ] || break
    done
}

fix_logcat_permissions() {
    local dir found=0

    while IFS= read -r -d '' dir; do
        chmod -R 755 "$dir"
        echo "🔧 已修正 logcat 目录权限: ${dir#./} -> 755"
        found=1
    done < <(find . -type d -name 'logcat' -print0)

    [ "$found" -eq 1 ] || return 0
}

extract_archives_recursively
fix_logcat_permissions

shopt -u nullglob nocaseglob
cd - > /dev/null

echo ""
echo "🎉 下载完成！"
echo "📁 当前目录内容："
ls -lh "$SAVE_DIR" 2>/dev/null || echo "目录为空"
