#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COOKIE_FILE="${SCRIPT_DIR}/download_bug_feishu_cookie.sh"
JIRA_COOKIE_FILE="${SCRIPT_DIR}/download_jira_cookie.sh"
JIRA_COOKIE_FILE_FALLBACK="${SCRIPT_DIR}/../download_jira/download_jira_cookie.sh"

PROJECT_KEY="6a4c8fa0bcd74934733780cc"
WORK_ITEM_TYPE="issue"
ISSUE_ID="${1:-7043211990}"
ISSUE_URL="https://project.feishu.cn/sb69eb/issue/detail/${ISSUE_ID}"
ISSUE_API_URL="https://project.feishu.cn/goapi/v2/projects/${PROJECT_KEY}/work_item/${WORK_ITEM_TYPE}/${ISSUE_ID}?"
SAVE_DIR="/home/huangxingke/下载/${ISSUE_ID}"

if [ -z "$ISSUE_ID" ]; then
    echo "用法: downloadFeishu <飞书Issue ID>"
    exit 1
fi

if [ ! -f "$COOKIE_FILE" ]; then
    echo "缺少 Feishu 配置文件: $COOKIE_FILE"
    exit 1
fi

# shellcheck disable=SC1090
source "$COOKIE_FILE"

CURL_EXPORT_FILE="${FEISHU_CURL_EXPORT_FILE:-${SCRIPT_DIR}/download_bug_feishu_request.curl}"

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
user_agent = ''
url = ''
cookie = ''

i = 0
while i < len(parts):
    part = parts[i]
    if part in ('-H', '--header') and i + 1 < len(parts):
        header = parts[i + 1]
        if ':' in header:
            name, value = header.split(':', 1)
            headers[name.strip().lower()] = value.strip()
        i += 2
        continue
    if part in ('-A', '--user-agent') and i + 1 < len(parts):
        user_agent = parts[i + 1]
        i += 2
        continue
    if part in ('-b', '--cookie') and i + 1 < len(parts):
        cookie = parts[i + 1]
        i += 2
        continue
    if not part.startswith('-') and part.startswith('http'):
        url = part
    i += 1

if field_name == 'cookie':
    print(cookie or headers.get('cookie', ''), end='')
elif field_name == 'referer':
    referer = headers.get('referer', '')
    if referer.endswith('/sw.js') and headers.get('x-sw-referer'):
        referer = headers.get('x-sw-referer', '')
    print(referer, end='')
elif field_name == 'user-agent':
    print(user_agent or headers.get('user-agent', ''), end='')
elif field_name == 'url':
    print(url, end='')
PYINNER
}

if [ ! -f "$CURL_EXPORT_FILE" ]; then
    echo "缺少浏览器导出的 cURL 文件: $CURL_EXPORT_FILE"
    echo "请把浏览器中 Copy as cURL (bash) 的内容保存到该文件后重试"
    exit 1
fi

FEISHU_COOKIE=$(extract_curl_field "$CURL_EXPORT_FILE" "cookie")
FEISHU_REFERER=$(extract_curl_field "$CURL_EXPORT_FILE" "referer")
FEISHU_USER_AGENT=$(extract_curl_field "$CURL_EXPORT_FILE" "user-agent")
FEISHU_REQUEST_URL=$(extract_curl_field "$CURL_EXPORT_FILE" "url")

if [ -z "$FEISHU_COOKIE" ]; then
    echo "未能从 $CURL_EXPORT_FILE 提取 Cookie，请确认内容是浏览器导出的 cURL 请求"
    exit 1
fi

MEEGO_CSRF_TOKEN=$(printf '%s' "$FEISHU_COOKIE" | tr ';' '\n' | sed -n 's/^ *meego_csrf_token=//p' | head -n 1)
MEEGO_LOCAL=$(printf '%s' "$FEISHU_COOKIE" | tr ';' '\n' | sed -n 's/^ *meego_local=//p' | head -n 1)

if [ -z "$FEISHU_REFERER" ]; then
    FEISHU_REFERER="$ISSUE_URL"
fi

if [ -z "$FEISHU_USER_AGENT" ]; then
    FEISHU_USER_AGENT="Mozilla/5.0"
fi

if [ -n "$FEISHU_REQUEST_URL" ] && [[ "$FEISHU_REQUEST_URL" == *"/issue/detail/"* ]]; then
    ISSUE_URL="$FEISHU_REQUEST_URL"
fi

JIRA_COOKIE=""
if [ -f "$JIRA_COOKIE_FILE" ]; then
    # shellcheck disable=SC1090
    source "$JIRA_COOKIE_FILE"
    JIRA_COOKIE="${COOKIE:-}"
elif [ -f "$JIRA_COOKIE_FILE_FALLBACK" ]; then
    # shellcheck disable=SC1090
    source "$JIRA_COOKIE_FILE_FALLBACK"
    JIRA_COOKIE="${COOKIE:-}"
fi

build_curl_auth_args() {
    local url="$1"

    if [[ "$url" == https://jira-shzj.auto-link.com.cn/* ]]; then
        if [ -z "$JIRA_COOKIE" ]; then
            echo "缺少 JIRA Cookie，无法下载附件: $url" >&2
            return 1
        fi
        CURL_AUTH_ARGS=(
            -b "$JIRA_COOKIE"
            -H "Referer: https://jira-shzj.auto-link.com.cn/"
            -H "User-Agent: $FEISHU_USER_AGENT"
        )
    else
        CURL_AUTH_ARGS=(
            -b "$FEISHU_COOKIE"
            -H "Referer: $FEISHU_REFERER"
            -H "User-Agent: $FEISHU_USER_AGENT"
        )
    fi
}

fetch_issue_json() {
    curl -f -sS \
        -b "$FEISHU_COOKIE" \
        -H "accept: application/json, text/plain, */*" \
        -H "locale: zh" \
        -H "Referer: $ISSUE_URL" \
        -H "User-Agent: $FEISHU_USER_AGENT" \
        -H "x-content-language: zh" \
        -H "x-content-language-customized: zh" \
        -H "x-lark-gw: 1" \
        -H "x-meego-csrf-token: ${MEEGO_CSRF_TOKEN:-}" \
        -H "x-meego-from: web" \
        -H "x-meego-gw-path: /goapi/v2/projects/:project_key/work_item/:work_item_type/:wi_object_id" \
        -H "x-meego-local: ${MEEGO_LOCAL:-28800}" \
        -H "x-meego-scope: workItemDetail" \
        -H "x-meego-source: web/release_train_1180306529026-1.0.5.7807" \
        -H "x-meego-timezone: 28800/28800" \
        "$ISSUE_API_URL"
}

extract_issue_project_name() {
    local issue_json="$1"

    printf '%s' "$issue_json" | jq -r '
        def scalar_text:
            if type == "string" then .
            elif type == "number" or type == "boolean" then tostring
            else empty
            end;
        def first_scalar:
            if type == "array" then
                map(
                    if type == "object" then
                        (.name // .label // .value // .text // .display_value // .display_name // empty) | scalar_text
                    else
                        scalar_text
                    end
                ) | map(select(length > 0)) | .[0] // empty
            elif type == "object" then
                (.name // .label // .value // .text // .display_value // .display_name // empty) | scalar_text
            else
                scalar_text
            end;

        [
            .. | objects | .jira_CHERY_PROJECT?,
            .. | objects | .field_value_map?.jira_CHERY_PROJECT?,
            .. | objects | select((.field_key? // .key? // .api_name? // .name?) == "jira_CHERY_PROJECT") | (.field_value? // .value? // .values? // .text? // .name? // .display_value? // .display_name?)
        ]
        | map(first_scalar)
        | map(select(type == "string" and length > 0 and . != "null"))
        | .[0] // empty
    ' 2>/dev/null | head -n 1
}

build_save_dir() {
    local issue_id="$1"
    local project_name="$2"
    local sanitized_project

    sanitized_project=$(printf '%s' "$project_name" | tr '/[:space:]' '_' | tr -cd '[:alnum:]_.-')
    sanitized_project=$(printf '%s' "$sanitized_project" | sed 's/_\+/_/g; s/^_//; s/_$//')

    if [ -n "$sanitized_project" ]; then
        printf '/home/huangxingke/下载/%s_%s\n' "$sanitized_project" "$issue_id"
    else
        printf '/home/huangxingke/下载/%s\n' "$issue_id"
    fi
}

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

resolve_filename_from_headers() {
    local url="$1"
    local fallback_name="$2"
    local headers disposition filename

    build_curl_auth_args "$url" || {
        printf '%s\n' "$fallback_name"
        return 0
    }

    headers=$(curl -sSI -L "${CURL_AUTH_ARGS[@]}" "$url" 2>/dev/null || true)
    disposition=$(printf '%s\n' "$headers" | tr -d '\r' | awk 'BEGIN { IGNORECASE = 1 } /^content-disposition:/ { sub(/^[^:]*:[[:space:]]*/, ""); print; exit }')

    if [[ "$disposition" =~ filename\*=UTF-8''([^;]+) ]]; then
        filename="${BASH_REMATCH[1]}"
        python3 - "$filename" <<'PYNAME'
import sys
from urllib.parse import unquote
print(unquote(sys.argv[1]))
PYNAME
        return 0
    fi

    filename=$(printf '%s\n' "$disposition" | sed -n 's/.*filename="\([^"]*\)".*/\1/p')
    if [ -n "$filename" ]; then
        printf '%s\n' "$filename"
        return 0
    fi

    filename=$(printf '%s\n' "$disposition" | sed -n 's/.*filename=\([^;]*\).*/\1/p')
    filename=${filename%\"}
    filename=${filename#\"}
    if [ -n "$filename" ]; then
        printf '%s\n' "$filename"
        return 0
    fi

    printf '%s\n' "$fallback_name"
}

fetch_remote_size() {
    local url="$1"
    build_curl_auth_args "$url" || return 1

    curl -fsSIL \
        "${CURL_AUTH_ARGS[@]}" \
        -L "$url" 2>/dev/null \
        | tr -d "\r" \
        | awk 'BEGIN { IGNORECASE = 1 }
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

download_with_progress() {
    local url="$1"
    local filepath="$2"
    local remote_size="$3"
    local pid current_size percent progress_bar status line display_size tick=0

    build_curl_auth_args "$url" || return 1

    : > "$filepath"
    curl -f -sS \
        "${CURL_AUTH_ARGS[@]}" \
        -L -o "$filepath" "$url" &
    pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        current_size=$(stat -c%s "$filepath" 2>/dev/null || echo 0)
        display_size="$current_size"
        line="   已下载大小: $(format_size "$current_size")"

        if [[ "$remote_size" =~ ^[0-9]+$ ]] && [ "$remote_size" -gt 0 ]; then
            if [ "$display_size" -gt "$remote_size" ]; then
                display_size="$remote_size"
            fi
            percent=$(( display_size * 100 / remote_size ))
            if [ "$percent" -gt 100 ]; then
                percent=100
            fi
            progress_bar=$(build_progress_bar "$percent")
            line+=" / 总大小: $(format_size "$remote_size") ${progress_bar} (${percent}%)"
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
    line="   已下载大小: $(format_size "$current_size")"

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
        progress_bar=$(build_progress_bar "$percent")
        line="   已下载大小: $(format_size "$current_size") / 总大小: $(format_size "$remote_size") ${progress_bar} (${percent}%)"
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

download_attachment() {
    local url="$1"
    local filepath="$2"
    local filename="$3"
    local remote_size

    if should_show_progress "$filename"; then
        remote_size=$(fetch_remote_size "$url")
        if [[ "$remote_size" =~ ^[0-9]+$ ]] && [ "$remote_size" -gt 0 ]; then
            echo "   包总大小: $(format_size "$remote_size")"
        fi
        download_with_progress "$url" "$filepath" "$remote_size"
    else
        build_curl_auth_args "$url" || return 1
        curl -f -sS \
            "${CURL_AUTH_ARGS[@]}" \
            -L -o "$filepath" "$url"
    fi
}

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
                echo "解压 ZIP 分卷: $f（共 $((vol_count + 1)) 个分卷）"
                7z x -y -aoa "$f" >/dev/null 2>&1 \
                    && echo "   ZIP 分卷解压完成" \
                    || { echo "   ZIP 分卷解压失败"; 7z x -y -aoa "$f" 2>&1 | tail -n 20; }
            else
                echo "解压 ZIP: $f"
                unzip -o "$f" -d . >/dev/null 2>&1 \
                    && echo "   ZIP 解压完成" \
                    || echo "   ZIP 解压失败"
            fi
            ;;
        *.tar.gz|*.tgz)
            echo "解压 TAR.GZ: $f"
            tar -xzf "$f" -C . \
                && echo "   TAR.GZ 解压完成" \
                || echo "   TAR.GZ 解压失败"
            ;;
        *.001)
            base="${f%.*}"
            vol_count=$(ls "${base}".[0-9][0-9][0-9] 2>/dev/null | wc -l)
            echo "解压 7z 分卷: $f（共 $vol_count 个分卷）"
            if 7z x -y -aoa "$f" >/dev/null 2>&1; then
                echo "   7z 分卷解压完成"
            elif command -v unar >/dev/null 2>&1 && unar -force-overwrite "$f" >/dev/null 2>&1; then
                echo "   unar 解压完成"
            else
                echo "   7z 分卷解压失败"
                7z x -y -aoa "$f" 2>&1 | tail -n 20
            fi
            ;;
        *.7z)
            echo "解压 7z: $f"
            if 7z x -y -aoa "$f" >/dev/null 2>&1; then
                echo "   7z 解压完成"
            elif command -v unar >/dev/null 2>&1 && unar -force-overwrite "$f" >/dev/null 2>&1; then
                echo "   unar 解压完成"
            else
                echo "   7z 解压失败"
                7z x -y -aoa "$f" 2>&1 | tail -n 20
            fi
            ;;
        *.part1.rar)
            if command -v unrar >/dev/null 2>&1; then
                base="${f%.*}"
                base="${base%.*}"
                vol_count=$(ls "${base}".part[0-9]*.rar 2>/dev/null | wc -l)
                echo "解压 RAR 分卷(新格式): $f（共 $vol_count 个分卷）"
                unrar x -o+ "$f" . >/dev/null 2>&1 \
                    && echo "   RAR 分卷解压完成" \
                    || echo "   RAR 分卷解压失败"
            else
                echo "未安装 unrar，跳过 RAR 文件"
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
                    echo "解压 RAR 分卷(旧格式): $f（共 $vol_count 个分卷）"
                else
                    echo "解压 RAR: $f"
                fi
                unrar x -o+ "$f" . >/dev/null 2>&1 \
                    && echo "   RAR 解压完成" \
                    || echo "   RAR 解压失败"
            else
                echo "未安装 unrar，跳过 RAR 文件"
            fi
            ;;
    esac
}

extract_archives_recursively() {
    local archive lower_name processed_in_pass
    declare -gA extracted_archives_seen=()

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

prepare_save_dir() {
    echo "正在清理旧文件..."
    if [ -e "$SAVE_DIR" ]; then
        chmod -R u+rwX "$SAVE_DIR" 2>/dev/null || true
        find "$SAVE_DIR" -type d -exec chmod u+rwx {} + 2>/dev/null || true
        find "$SAVE_DIR" -type f -exec chmod u+rw {} + 2>/dev/null || true
        rm -rf "$SAVE_DIR"
    fi
    mkdir -p "$SAVE_DIR"
    chmod u+rwx "$SAVE_DIR" 2>/dev/null || true
}

ISSUE_JSON=$(fetch_issue_json)
if ! printf '%s' "$ISSUE_JSON" | jq -e . >/dev/null 2>&1; then
    echo "Feishu issue API 返回的不是合法 JSON"
    printf '%s\n' "$ISSUE_JSON" | head -c 300
    echo
    exit 1
fi

ISSUE_PROJECT_NAME=$(extract_issue_project_name "$ISSUE_JSON")
SAVE_DIR=$(build_save_dir "$ISSUE_ID" "$ISSUE_PROJECT_NAME")

prepare_save_dir

echo "======================================"
echo "开始下载 Feishu Issue: $ISSUE_ID"
echo "Issue 链接: $ISSUE_URL"
echo "保存目录: $SAVE_DIR"
echo "======================================"

COUNT=$(printf '%s' "$ISSUE_JSON" | jq '.data.multi_attachment | length // 0')
if [ "$COUNT" -eq 0 ]; then
    echo "Issue 没有附件，或接口里未返回 multi_attachment"
    exit 1
fi

echo "找到 $COUNT 个附件，开始下载..."

mapfile -t ATTACHMENTS < <(printf '%s' "$ISSUE_JSON" | jq -r '.data.multi_attachment[]? | "\(.url)|\(.name)"')

for attachment in "${ATTACHMENTS[@]}"; do
    IFS='|' read -r url filename <<< "$attachment"
    [ -n "$url" ] || continue
    filename="$(basename "${url%%\?*}")"
    if [ -z "$filename" ] || [[ "$filename" == */* ]] || [[ "$filename" == issue ]]; then
        filename=$(resolve_filename_from_headers "$url" "${filename:-附件}")
    fi
    filepath="${SAVE_DIR}/${filename}"

    echo "下载: $filename"
    if download_attachment "$url" "$filepath" "$filename" && [ -s "$filepath" ]; then
        size=$(du -h "$filepath" | cut -f1)
        echo "下载完成: $filename ($size)"
    else
        echo "下载失败: $filename"
        rm -f "$filepath"
    fi
done

cd "$SAVE_DIR" || exit 1
shopt -s nullglob nocaseglob
extract_archives_recursively

if [ -d "logcat" ]; then
    chmod -R 755 "logcat"
    echo "🔧 已修正 logcat 目录权限: 755"
fi

shopt -u nullglob nocaseglob
cd - >/dev/null || exit 1

echo
echo "下载完成"
echo "当前目录内容:"
ls -lh "$SAVE_DIR" 2>/dev/null || echo "目录为空"
