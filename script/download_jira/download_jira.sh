#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

# =============================================
# JIRA 一键下载工具（全局版）
# 用法: download_jira <JIRA单号>
# 示例: download_jira CHYKP31-1028
#       download_jira DP-5927
# =============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COOKIE_FILE="${SCRIPT_DIR}/download_jira_cookie.sh"

if [ ! -f "$COOKIE_FILE" ]; then
    echo "❌ 缺少 Cookie 配置文件: $COOKIE_FILE"
    exit 1
fi

# shellcheck disable=SC1090
source "$COOKIE_FILE"

if [ -z "$COOKIE" ]; then
    echo "❌ Cookie 配置为空，请检查: $COOKIE_FILE"
    exit 1
fi

if [ -z "$1" ]; then
    echo "用法: download_jira <JIRA单号>"
    echo "示例: download_jira CHYKP31-1028"
    exit 1
fi

TICKET=$1
SAVE_DIR="/home/huangxingke/下载/${TICKET}"

# ==================== 每次下载前清空旧文件 ====================
echo "🧹 正在清理旧文件..."
rm -rf "$SAVE_DIR"          # 删除旧文件夹及所有内容
mkdir -p "$SAVE_DIR"

echo "══════════════════════════════════════"
echo "🚀 开始下载 JIRA: $TICKET"
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
mapfile -t ATTACHMENTS < <(echo "$JSON" | jq -r '.fields.attachment[]? | "\(.content)|\(.filename)"')

for attachment in "${ATTACHMENTS[@]}"; do
    IFS='|' read -r url filename <<< "$attachment"
    if [ -n "$url" ] && [ -n "$filename" ]; then
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

declare -A extracted_archives_seen

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
    local base companions has_companion=false vol_count

    case "$lower_name" in
        *.zip)
            base="${f%.*}"
            companions=( "${base}".z[0-9][0-9] "${base}".Z[0-9][0-9] )
            for c in "${companions[@]}"; do
                [ -f "$c" ] && has_companion=true && break
            done
            if $has_companion; then
                vol_count=$(ls "${base}".z[0-9][0-9] "${base}".Z[0-9][0-9] 2>/dev/null | wc -l)
                echo "📦 解压 ZIP 分卷: $f（共 $((vol_count + 1)) 个分卷）"
                7z x -y -aoa "$f" >/dev/null 2>&1 \
                    && echo "   ✅ ZIP 分卷解压完成" \
                    || { echo "   ❌ ZIP 分卷解压失败："; 7z x -y -aoa "$f" 2>&1 | tail -n 20; echo "   💡 手动：cd \"$SAVE_DIR\" && 7z x \"$f\""; }
            else
                echo "📦 解压 ZIP: $f"
                unzip -o "$f" -d . >/dev/null 2>&1 \
                    && echo "   ✅ ZIP 解压完成" \
                    || { echo "   ❌ ZIP 解压失败"; echo "   💡 手动：cd \"$SAVE_DIR\" && unzip \"$f\""; }
            fi
            ;;
        *.tar.gz|*.tgz)
            echo "📦 解压 TAR.GZ: $f"
            tar -xzf "$f" -C . \
                && echo "   ✅ TAR.GZ 解压完成" \
                || { echo "   ❌ TAR.GZ 解压失败"; echo "   💡 手动：cd \"$SAVE_DIR\" && tar -xzf \"$f\""; }
            ;;
        *.001)
            base="${f%.*}"
            vol_count=$(ls "${base}".[0-9][0-9][0-9] 2>/dev/null | wc -l)
            echo "📦 解压 7z 分卷: $f（共 $vol_count 个分卷）"
            if 7z x -y -aoa "$f" >/dev/null 2>&1; then
                echo "   ✅ 7z 分卷解压完成"
            elif command -v unar >/dev/null 2>&1 && unar -force-overwrite "$f" >/dev/null 2>&1; then
                echo "   ✅ unar 解压完成"
            else
                echo "   ❌ 7z 分卷解压失败："
                7z x -y -aoa "$f" 2>&1 | tail -n 20
                echo "   💡 手动：cd \"$SAVE_DIR\" && 7z x \"$f\""
            fi
            ;;
        *.7z)
            echo "📦 解压 7z: $f"
            if 7z x -y -aoa "$f" >/dev/null 2>&1; then
                echo "   ✅ 7z 解压完成"
            elif command -v unar >/dev/null 2>&1 && unar -force-overwrite "$f" >/dev/null 2>&1; then
                echo "   ✅ unar 解压完成"
            else
                echo "   ❌ 7z 解压失败："
                7z x -y -aoa "$f" 2>&1 | tail -n 20
                echo "   💡 手动：cd \"$SAVE_DIR\" && 7z x \"$f\""
            fi
            ;;
        *.part1.rar)
            if command -v unrar >/dev/null 2>&1; then
                base="${f%.*}"
                base="${base%.*}"
                vol_count=$(ls "${base}".part[0-9]*.rar 2>/dev/null | wc -l)
                echo "📦 解压 RAR 分卷(新格式): $f（共 $vol_count 个分卷）"
                unrar x -o+ "$f" . >/dev/null 2>&1 \
                    && echo "   ✅ RAR 分卷解压完成" \
                    || { echo "   ❌ RAR 分卷解压失败"; echo "   💡 手动：cd \"$SAVE_DIR\" && unrar x \"$f\""; }
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
                    echo "📦 解压 RAR 分卷(旧格式): $f（共 $vol_count 个分卷）"
                else
                    echo "📦 解压 RAR: $f"
                fi
                unrar x -o+ "$f" . >/dev/null 2>&1 \
                    && echo "   ✅ RAR 解压完成" \
                    || { echo "   ❌ RAR 解压失败"; echo "   💡 手动：cd \"$SAVE_DIR\" && unrar x \"$f\""; }
            else
                echo "⚠️ 未安装 unrar，RAR 文件跳过（安装：sudo apt install unrar）"
            fi
            ;;
    esac
}

extract_archives_recursively() {
    local archive lower_name processed_in_pass

    while :; do
        processed_in_pass=0
        for archive in *; do
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

            [[ -n "${extracted_archives_seen[$archive]}" ]] && continue
            extracted_archives_seen["$archive"]=1
            extract_one_archive "$archive"
            processed_in_pass=1
        done

        [ "$processed_in_pass" -eq 1 ] || break
    done
}

extract_archives_recursively

if [ -d "logcat" ]; then

    chmod -R 755 "logcat"
    echo "🔧 已修正 logcat 目录权限: 755"
fi

shopt -u nullglob nocaseglob
cd - > /dev/null

echo ""
echo "🎉 下载完成！"
echo "📁 当前目录内容："
ls -lh "$SAVE_DIR" 2>/dev/null || echo "目录为空"
