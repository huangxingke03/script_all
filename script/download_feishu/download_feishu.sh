#!/bin/bash

if [ -z "${BASH_VERSION:-}" ]; then
    exec bash "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/download_feishu_config.sh"
PROJECT_KEY="6a4c8fa0bcd74934733780cc"
# 车型项目代号。项目字段 field_4586a9 存的是这个工作项 id，展示名要再查一次。
VEHICLE_PROJECT_TYPE_KEY="680b4c0759f79bcc88bc809f"
WORK_ITEM_TYPE="issue"
ISSUE_ID="${1:-7043211990}"
ISSUE_URL="https://project.feishu.cn/sb69eb/issue/detail/${ISSUE_ID}"
ISSUE_API_URL="https://project.feishu.cn/goapi/v2/projects/${PROJECT_KEY}/work_item/${WORK_ITEM_TYPE}/${ISSUE_ID}?"
SAVE_DIR="/home/huangxingke/下载/${ISSUE_ID}"
FEISHU_FILTER_SKIP_SPECIAL="${FEISHU_FILTER_SKIP_SPECIAL:-0}"

if [ -z "$ISSUE_ID" ]; then
    echo "用法: downloadFeishu <飞书Issue ID>"
    exit 1
fi

if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

# Feishu request defaults. Keep these values current if the exported request changes.
FEISHU_REQUEST_URL_DEFAULT="https://project.feishu.cn/goapi/v2/projects/6a4c8fa0bcd74934733780cc/work_item/issue/7042888694?"
FEISHU_REFERER_DEFAULT="https://project.feishu.cn/sb69eb/issue/detail/7042888694?parentUrl=%2Fworkbench&openScene=3"
FEISHU_USER_AGENT_DEFAULT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36"
CURL_EXPORT_FILE="${FEISHU_CURL_EXPORT_FILE:-${SCRIPT_DIR}/download_feishu_request_kp31.curl}"
ISSUE_SPECIFIC_CURL_EXPORT_FILE="${SCRIPT_DIR}/download_feishu_request_${ISSUE_ID}.curl"
FEISHU_COOKIE_FALLBACK="${FEISHU_COOKIE:-${COOKIE:-}}"
FEISHU_REFERER_FALLBACK_VALUE="${FEISHU_REFERER_FALLBACK:-${REFERER:-${FEISHU_REFERER_DEFAULT}}}"
FEISHU_USER_AGENT_FALLBACK_VALUE="${FEISHU_USER_AGENT_FALLBACK:-${USER_AGENT:-${FEISHU_USER_AGENT_DEFAULT}}}"
FEISHU_REQUEST_URL_FALLBACK_VALUE="${FEISHU_REQUEST_URL_FALLBACK:-${REQUEST_URL:-${FEISHU_REQUEST_URL_DEFAULT}}}"

FEISHU_AUTO_SELECT_PROJECTS="${FEISHU_AUTO_SELECT_PROJECTS:-1}"
FEISHU_CURL_FORCE="${FEISHU_CURL_FORCE:-0}"
FEISHU_SOURCE_SCRIPT_DIR="${FEISHU_SOURCE_SCRIPT_DIR:-$HOME/project/Python/script/download_feishu}"

try_download_with_curl_file() {
    local curl_file="$1"
    [ -f "$curl_file" ] || return 1
    FEISHU_CURL_FORCE=1 FEISHU_AUTO_SELECT_PROJECTS=0 FEISHU_CURL_EXPORT_FILE_OVERRIDE="$curl_file" "$0" "$ISSUE_ID"
}

if [ "$FEISHU_CURL_FORCE" != "1" ] && [ "$FEISHU_AUTO_SELECT_PROJECTS" = "1" ]; then
    declare -A candidate_seen=()
    candidate_files=()

    add_candidate_file() {
        local candidate="$1"
        local candidate_key
        [ -f "$candidate" ] || return 0
        candidate_key="$(basename "$candidate")"
        [ -n "${candidate_seen[$candidate_key]:-}" ] && return 0
        candidate_seen["$candidate_key"]=1
        candidate_files+=("$candidate")
    }

    collect_candidates_from_dir() {
        local base_dir="$1"
        local specific="$base_dir/download_feishu_request_${ISSUE_ID}.curl"
        local default="$base_dir/download_feishu_request_kp31.curl"
        local project_aliases=(
            "$base_dir/download_feishu_request_d01.curl"
            "$base_dir/download_feishu_request_d01_int.curl"
        )
        local curl_file

        [ -d "$base_dir" ] || return 0
        add_candidate_file "$specific"
        add_candidate_file "$default"
        for alias_file in "${project_aliases[@]}"; do
            add_candidate_file "$alias_file"
        done
        while IFS= read -r -d '' curl_file; do
            case "$curl_file" in
                "$specific"|"$default"|"${project_aliases[0]}"|"${project_aliases[1]}")
                    continue
                    ;;
            esac
            add_candidate_file "$curl_file"
        done < <(find "$base_dir" -maxdepth 1 -type f -name 'download_feishu_request_*.curl' -print0 | sort -z)
    }

    collect_candidates_from_dir "$SCRIPT_DIR"
    collect_candidates_from_dir "$FEISHU_SOURCE_SCRIPT_DIR"

    if [ "${#candidate_files[@]}" -gt 0 ]; then
        last_status=1
        for candidate in "${candidate_files[@]}"; do
            echo "🔁 尝试 Feishu cURL: $(basename "$candidate")"
            if try_download_with_curl_file "$candidate"; then
                exit 0
            fi
            last_status=$?
        done
        exit "$last_status"
    fi
fi

extract_project_key_from_url() {
    local url="$1"

    python3 - "$url" <<'PYURL'
import re
import sys

url = sys.argv[1]
match = re.search(r'/projects/([^/]+)/work_item/', url)
if match:
    print(match.group(1), end='')
PYURL
}

extract_issue_id_from_url() {
    local url="$1"

    python3 - "$url" <<'PYURL'
import re
import sys

url = sys.argv[1]
match = re.search(r'/issue/detail/(\d+)|/work_item/issue/(\d+)|/log/issue/(\d+)|/issue/(\d+)', url)
if match:
    for group in match.groups():
        if group:
            print(group, end='')
            break
PYURL
}

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
else:
    print(headers.get(field_name, ''), end='')
PYINNER
}

FEISHU_COOKIE=""
FEISHU_REFERER=""
FEISHU_USER_AGENT=""
FEISHU_REQUEST_URL=""
FEISHU_X_TOKEN=""
MG_JIRA_PROJECT_FILE_LIST_URL="https://mg-jira.auto-link.com.cn/api/files/list"
FEISHU_ATTACHMENT_JIRA_COOKIE_RESOLVED="${FEISHU_ATTACHMENT_JIRA_COOKIE:-}"

if [ -n "${FEISHU_CURL_EXPORT_FILE_OVERRIDE:-}" ] && [ -f "$FEISHU_CURL_EXPORT_FILE_OVERRIDE" ]; then
    CURL_EXPORT_FILE="$FEISHU_CURL_EXPORT_FILE_OVERRIDE"
elif [ -n "${FEISHU_CURL_EXPORT_FILE:-}" ] && [ -f "$FEISHU_CURL_EXPORT_FILE" ]; then
    CURL_EXPORT_FILE="$FEISHU_CURL_EXPORT_FILE"
elif [ -f "$ISSUE_SPECIFIC_CURL_EXPORT_FILE" ]; then
    CURL_EXPORT_FILE="$ISSUE_SPECIFIC_CURL_EXPORT_FILE"
fi

if [ -f "$CURL_EXPORT_FILE" ]; then
    FEISHU_COOKIE=$(extract_curl_field "$CURL_EXPORT_FILE" "cookie")
    FEISHU_REFERER=$(extract_curl_field "$CURL_EXPORT_FILE" "referer")
    FEISHU_USER_AGENT=$(extract_curl_field "$CURL_EXPORT_FILE" "user-agent")
    FEISHU_REQUEST_URL=$(extract_curl_field "$CURL_EXPORT_FILE" "url")
    FEISHU_X_TOKEN=$(extract_curl_field "$CURL_EXPORT_FILE" "x-token")
fi

if [ -z "$FEISHU_ATTACHMENT_JIRA_COOKIE_RESOLVED" ] && [ -n "${FEISHU_ATTACHMENT_JIRA_CURL_EXPORT_FILE:-}" ] && [ -f "$FEISHU_ATTACHMENT_JIRA_CURL_EXPORT_FILE" ]; then
    FEISHU_ATTACHMENT_JIRA_COOKIE_RESOLVED=$(extract_curl_field "$FEISHU_ATTACHMENT_JIRA_CURL_EXPORT_FILE" "cookie")
fi

if [ -z "$FEISHU_COOKIE" ]; then
    FEISHU_COOKIE="$FEISHU_COOKIE_FALLBACK"
fi
if [ -z "$FEISHU_REFERER" ]; then
    FEISHU_REFERER="$FEISHU_REFERER_FALLBACK_VALUE"
fi
if [ -z "$FEISHU_USER_AGENT" ]; then
    FEISHU_USER_AGENT="$FEISHU_USER_AGENT_FALLBACK_VALUE"
fi
if [ -z "$FEISHU_REQUEST_URL" ]; then
    FEISHU_REQUEST_URL="$FEISHU_REQUEST_URL_FALLBACK_VALUE"
fi

if [ -n "$FEISHU_REQUEST_URL" ]; then
    extracted_project_key=$(extract_project_key_from_url "$FEISHU_REQUEST_URL")
    if [ -n "$extracted_project_key" ]; then
        PROJECT_KEY="$extracted_project_key"
    fi
fi

ISSUE_URL="https://project.feishu.cn/sb69eb/issue/detail/${ISSUE_ID}"
ISSUE_API_URL="https://project.feishu.cn/goapi/v2/projects/${PROJECT_KEY}/work_item/${WORK_ITEM_TYPE}/${ISSUE_ID}?"

if [ -n "$FEISHU_REQUEST_URL" ] && [[ "$FEISHU_REQUEST_URL" == *"/issue/detail/"* ]]; then
    ISSUE_URL="$FEISHU_REQUEST_URL"
fi

if [ -n "$FEISHU_REFERER" ] && [[ "$FEISHU_REFERER" == *"/issue/detail/"* ]]; then
    ISSUE_URL="$FEISHU_REFERER"
fi

if [ -z "$FEISHU_COOKIE" ]; then
    echo "缺少 Feishu Cookie，请在 $CONFIG_FILE 里配置 FEISHU_COOKIE，或把带 Cookie 的 cURL 保存到 $CURL_EXPORT_FILE"
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

build_curl_auth_args() {
    local url="$1"
    if [ -z "$url" ]; then
        echo "附件链接为空" >&2
        return 1
    fi

    if [[ "$url" == https://jira-shzj.auto-link.com.cn/* ]]; then
        if [ -z "$FEISHU_ATTACHMENT_JIRA_COOKIE_RESOLVED" ]; then
            echo "缺少 JIRA 历史附件 Cookie，无法下载: $url" >&2
            echo "请在 download_feishu_config.sh 里配置 FEISHU_ATTACHMENT_JIRA_CURL_EXPORT_FILE 或 FEISHU_ATTACHMENT_JIRA_COOKIE" >&2
            return 1
        fi
        CURL_AUTH_ARGS=(
            -b "$FEISHU_ATTACHMENT_JIRA_COOKIE_RESOLVED"
            -H "Referer: https://jira-shzj.auto-link.com.cn/"
            -H "User-Agent: $FEISHU_USER_AGENT"
        )
        return 0
    fi

    CURL_AUTH_ARGS=(
        -b "$FEISHU_COOKIE"
        -H "Referer: $FEISHU_REFERER"
        -H "User-Agent: $FEISHU_USER_AGENT"
    )
}

fetch_issue_json() {
    local api_url="${1:-$ISSUE_API_URL}"

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
        "$api_url"
}

build_target_request_url() {
    local request_url="$1"
    local target_issue_id="$2"

    [ -n "$request_url" ] || return 0

    python3 - "$request_url" "$target_issue_id" <<'PYURL'
import re
import sys

request_url = sys.argv[1]
target_issue_id = sys.argv[2]

patterns = (
    r'(/issue/detail/)\d+',
    r'(/work_item/issue/)\d+',
    r'(/log/issue/)\d+',
    r'(/issue/)\d+',
)

updated = request_url
for pattern in patterns:
    updated, count = re.subn(pattern, r'\1' + target_issue_id, updated, count=1)
    if count:
        break

print(updated, end='')
PYURL
}

fetch_feishu_json_from_url() {
    local api_url="$1"

    [ -n "$api_url" ] || return 1

    if [ -n "$FEISHU_X_TOKEN" ]; then
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
            -H "x-meego-local: ${MEEGO_LOCAL:-28800}" \
            -H "x-token: $FEISHU_X_TOKEN" \
            "$api_url"
        return
    fi

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
        -H "x-meego-local: ${MEEGO_LOCAL:-28800}" \
        "$api_url"
}

fetch_mg_jira_local_upload_json() {
    local project_key="$1"
    local work_item_type="$2"
    local work_item_id="$3"

    [ -n "$project_key" ] || return 1
    [ -n "$work_item_type" ] || return 1
    [ -n "$work_item_id" ] || return 1

    curl -f -sS \
        -H 'Accept: */*' \
        -H 'Origin: https://projectplg.feishupkg.com' \
        -H 'Referer: https://projectplg.feishupkg.com/' \
        -H "User-Agent: $FEISHU_USER_AGENT" \
        "${MG_JIRA_PROJECT_FILE_LIST_URL}?project_key=${project_key}&work_item_type_key=${work_item_type}&work_item_id=${work_item_id}"
}

build_mg_jira_download_url() {
    local file_id="$1"
    local project_key="$2"
    local work_item_type="$3"
    local work_item_id="$4"

    [ -n "$file_id" ] || return 1
    [ -n "$project_key" ] || return 1
    [ -n "$work_item_type" ] || return 1
    [ -n "$work_item_id" ] || return 1

    printf 'https://mg-jira.auto-link.com.cn/api/files/download/%s?project_key=%s&work_item_type_key=%s&work_item_id=%s&download=1' \
        "$file_id" "$project_key" "$work_item_type" "$work_item_id"
}

collect_attachment_entries() {
    python3 - "$@" <<'PYATTACH'
import json
import sys
from pathlib import Path

ATTACHMENT_HINTS = ('attach', 'upload', 'file')


def load_json(path_str):
    path = Path(path_str)
    if not path.is_file() or path.stat().st_size == 0:
        return None
    try:
        return json.loads(path.read_text())
    except Exception:
        return None


def should_emit(path_parts, obj):
    path_text = '.'.join(path_parts).lower()
    keys = {str(k).lower() for k in obj.keys()}
    if 'multi_attachment' in path_text:
        return True
    if any(hint in path_text for hint in ATTACHMENT_HINTS):
        return True
    if any(any(hint in key for hint in ATTACHMENT_HINTS) for key in keys):
        return True
    if set(keys).issubset({'url', 'name'}):
        return True
    return False


def walk(node, path_parts, seen, emitted):
    if isinstance(node, dict):
        url = node.get('url')
        name = node.get('name') or node.get('filename') or node.get('file_name')
        if (
            isinstance(url, str)
            and url.startswith('http')
            and isinstance(name, str)
            and name.strip()
            and should_emit(path_parts, node)
        ):
            key = (url.strip(), name.strip())
            if key not in seen:
                seen.add(key)
                emitted.append(key)
        for key, value in node.items():
            walk(value, path_parts + [str(key)], seen, emitted)
    elif isinstance(node, list):
        for idx, value in enumerate(node):
            walk(value, path_parts + [str(idx)], seen, emitted)


seen = set()
emitted = []
for file_path in sys.argv[1:]:
    obj = load_json(file_path)
    if obj is None:
        continue
    walk(obj, [Path(file_path).stem], seen, emitted)

for url, name in emitted:
    print(f'{url}|{name}')
PYATTACH
}

extract_issue_project_name() {
    local issue_json="$1"

    printf '%s' "$issue_json" | jq -r '
        def scalar_text:
            if type == "string" then .
            elif type == "boolean" then tostring
            else empty
            end;
        def useful_text:
            select(type == "string" and length > 0 and . != "null" and . != "项目" and test("[A-Za-z]"));
        def object_texts:
            [
                .label?,
                .display_value?,
                .display_name?,
                .value?,
                .text?,
                .name?,
                .option_label?,
                .option_name?,
                .cn_name?,
                .en_name?
            ]
            | map(
                if type == "string" or type == "boolean" then scalar_text
                else empty
                end
            )
            | map(useful_text);
        def first_scalar:
            if type == "array" then
                map(first_scalar) | map(select(length > 0)) | unique | join(" ")
            elif type == "object" then
                (object_texts | unique | join(" ")) as $direct
                | if ($direct | length) > 0 then $direct
                  else
                      (.field_value? // .values? // .value? // empty) as $nested
                      | if $nested == null or $nested == "" then empty
                        else ($nested | first_scalar)
                        end
                  end
            else
                scalar_text
            end;
        def project_key_match:
            ((.field_key? // .key? // .api_name? // .name? // .id? // "") | tostring) == "jira_CHERY_PROJECT"
            or ((.field_alias? // .alias? // "") | tostring) == "jira_CHERY_PROJECT"
            or ((.field_key? // .key? // .api_name? // .id? // "") | tostring) == "field_4586a9"
            or ((.field_key? // .key? // .api_name? // .id? // "") | tostring) == "field_286612"
            or ((.field_name? // .display_name? // .name? // "") | tostring) == "项目"
            or ((.field_name? // .display_name? // .name? // .label? // .title? // "") | tostring) == "缺陷编号"
            or (
                ((.label? // .title? // "") | tostring) == "项目"
                and (has("field_value") or has("field_key") or has("field_alias") or has("api_name") or has("value") or has("key"))
            );
        def project_value:
            (
                .field_value?
                // .value?
                // .values?
                // .text?
                // .name?
                // .display_value?
                // .display_name?
                // .field_value_map?.jira_CHERY_PROJECT?
                // .field_value_map?.field_4586a9?
                // .jira_CHERY_PROJECT?
                // .field_4586a9?
                // .field_286612?
                // empty
            );

        [
            (.. | objects | .jira_CHERY_PROJECT?),
            (.. | objects | .field_value_map?.jira_CHERY_PROJECT?),
            (.. | objects | .field_4586a9?),
            (.. | objects | .field_value_map?.field_4586a9?),
            (.. | objects | .field_286612?),
            (.. | objects | .field_value_map?.field_286612?),
            (.. | objects | select(project_key_match) | project_value),
            (.. | objects | .fields?.jira_CHERY_PROJECT?),
            (.. | objects | .fields?.field_4586a9?),
            (.. | objects | .custom_fields?.jira_CHERY_PROJECT?),
            (.. | objects | .custom_fields?.field_4586a9?),
            (.. | objects | .custom_field_values?.jira_CHERY_PROJECT?),
            (.. | objects | .custom_field_values?.field_4586a9?),
            (.. | objects | .field_alias_map?.jira_CHERY_PROJECT?),
            (.. | objects | select(has("field_value_map")) | .field_value_map | to_entries[]? | select(.key == "jira_CHERY_PROJECT" or .key == "field_4586a9" or .key == "field_286612") | .value),
            (.. | objects | .items[]? | select(project_key_match) | project_value),
            (.. | objects | select(((.field_name? // .display_name? // .name? // empty) | tostring) == "项目") | project_value),
            (.. | objects | .items[]? | select(((.field_name? // .display_name? // .name? // empty) | tostring) == "项目") | project_value),
            (.. | objects | select(((.field_name? // .display_name? // .name? // .label? // .title? // empty) | tostring) == "缺陷编号") | project_value),
            .data.field_4586a9?,
            .data.for_leopard.field_4586a9?,
            .data.field_286612?,
            .data.for_leopard.field_286612?
        ]
        | map(first_scalar)
        | map(useful_text)
        | unique
        | join(" ")
    ' 2>/dev/null | head -n 1
}

extract_issue_project_debug_snippets() {
    local issue_json="$1"

    printf '%s' "$issue_json" | jq -c '
        def project_key_match:
            ((.field_key? // .key? // .api_name? // .name? // .id? // "") | tostring) == "jira_CHERY_PROJECT"
            or ((.field_alias? // .alias? // "") | tostring) == "jira_CHERY_PROJECT"
            or ((.field_key? // .key? // .api_name? // .id? // "") | tostring) == "field_4586a9"
            or ((.field_key? // .key? // .api_name? // .id? // "") | tostring) == "field_286612"
            or ((.field_name? // .display_name? // .name? // "") | tostring) == "项目"
            or ((.field_name? // .display_name? // .name? // .label? // .title? // "") | tostring) == "缺陷编号"
            or (
                ((.label? // .title? // "") | tostring) == "项目"
                and (has("field_value") or has("field_key") or has("field_alias") or has("api_name") or has("value") or has("key"))
            );

        [
            (.. | objects | select(has("jira_CHERY_PROJECT")) | {path_hint: "jira_CHERY_PROJECT", value: .jira_CHERY_PROJECT}),
            (.. | objects | select(.field_value_map?.jira_CHERY_PROJECT? != null) | {path_hint: "field_value_map.jira_CHERY_PROJECT", value: .field_value_map.jira_CHERY_PROJECT}),
            (.. | objects | select(has("field_4586a9")) | {path_hint: "field_4586a9", value: .field_4586a9}),
            (.. | objects | select(has("field_286612")) | {path_hint: "field_286612", value: .field_286612}),
            (.. | objects | select(project_key_match) | {
                path_hint: (.field_key? // .key? // .api_name? // .field_alias? // .field_name? // .name? // .id? // "jira_CHERY_PROJECT"),
                value: (.field_value? // .value? // .values? // .text? // .name? // .display_value? // .display_name? // .field_value_map?.jira_CHERY_PROJECT? // .jira_CHERY_PROJECT? // .field_4586a9? // .field_286612? // empty)
            }),
            (.. | objects | select(((.field_name? // .display_name? // .name? // empty) | tostring) == "项目") | {
                path_hint: (.field_key? // .field_alias? // .field_name? // .display_name? // .name? // "项目"),
                value: (.field_value? // .value? // .values? // .text? // .name? // .display_value? // .display_name? // empty)
            })
        ]
        | map(select(.value != null))
        | .[:8]
    ' 2>/dev/null
}

extract_issue_title() {
    local issue_json="$1"
    printf '%s' "$issue_json" | jq -r '.data.name // .data.title // .data.summary // empty' 2>/dev/null | head -n 1
}

extract_issue_defect_number() {
    local issue_json="$1"

    printf '%s' "$issue_json" | jq -r '
        .data.field_286612
        // .data.for_leopard.field_286612
        // (
            [
                .. | objects | .field_286612?,
                .. | objects
                | select(((.field_name? // .display_name? // .label? // .title? // empty) | tostring) == "缺陷编号")
                | (.field_value? // .value? // .values? // .text? // .name? // .display_value? // .display_name? // empty),
                .. | objects | .items[]?
                | select(((.field_name? // .display_name? // .label? // .title? // empty) | tostring) == "缺陷编号")
                | (.field_value? // .value? // .values? // .text? // .name? // .display_value? // .display_name? // empty)
            ]
            | map(
                if type == "array" then
                    map(
                        if type == "object" then
                            (.name // .label // .value // .text // .display_value // .display_name // empty)
                        else
                            .
                        end
                    )
                    | map(select(type == "string" and length > 0 and . != "null"))
                    | .[0]
                elif type == "object" then
                    (.name // .label // .value // .text // .display_value // .display_name // empty)
                else
                    .
                end
            )
            | map(select(type == "string" and length > 0 and . != "null"))
            | .[0]
        )
        // empty
    ' 2>/dev/null | head -n 1
}

extract_issue_defect_type() {
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
        def defect_type_match:
            ((.field_name? // .display_name? // .label? // .title? // empty) | tostring) == "缺陷类型";
        def defect_value:
            (
                .field_value?
                // .value?
                // .values?
                // .text?
                // .name?
                // .display_value?
                // .display_name?
                // empty
            );

        [
            .. | objects | select(defect_type_match) | defect_value,
            .. | objects | .items[]? | select(defect_type_match) | defect_value
        ]
        | map(first_scalar)
        | map(select(type == "string" and length > 0 and . != "null"))
        | .[0] // empty
    ' 2>/dev/null | head -n 1
}

detect_project_name_from_text() {
    local source_text="$1"
    local upper_text

    upper_text=$(printf '%s' "$source_text" | tr '[:lower:]' '[:upper:]')

    # Match standalone platform tags and variants such as CHY_KP31, CHERY_KP31_BUG, D01-FL1, or D01-P/D01P.
    if [[ "$upper_text" =~ (^|[^A-Z0-9])(KP31_INT|KP31|D01-FL1|D01FL1|D01_FL1|D01-P|D01P|D01)([^A-Z0-9]|$) ]]; then
        printf '%s
' "${BASH_REMATCH[2]}"
        return 0
    fi

    return 1
}

extract_issue_software_version() {
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
            .data.jira_Software_Version?,
            .data.jira_customfield_11003_8_5?,
            .data.jira_customfield_12606_8_5?,
            .data.for_leopard.jira_customfield_12606_8_5?,
            .. | objects | .jira_Software_Version?,
            .. | objects | .jira_customfield_11003_8_5?,
            .. | objects | .jira_customfield_12606_8_5?,
            .. | objects | .field_value_map?.jira_Software_Version?,
            .. | objects | .field_value_map?.jira_customfield_11003_8_5?,
            .. | objects | .field_value_map?.jira_customfield_12606_8_5?,
            .. | objects | .fields?.jira_Software_Version?,
            .. | objects | .fields?.jira_customfield_11003_8_5?,
            .. | objects | .fields?.jira_customfield_12606_8_5?,
            .. | objects | .custom_fields?.jira_Software_Version?,
            .. | objects | .custom_fields?.jira_customfield_11003_8_5?,
            .. | objects | .custom_fields?.jira_customfield_12606_8_5?,
            .. | objects | .custom_field_values?.jira_Software_Version?,
            .. | objects | .custom_field_values?.jira_customfield_11003_8_5?,
            .. | objects | .custom_field_values?.jira_customfield_12606_8_5?,
            .. | objects | select((.field_key? // .key? // .api_name? // .name? // .id? // empty) == "jira_Software_Version" or (.field_key? // .key? // .api_name? // .name? // .id? // empty) == "jira_customfield_12606_8_5")
              | (.field_value? // .value? // .values? // .text? // .name? // .display_value? // .display_name?),
            .. | objects | .doc_text?,
            .. | objects | .doc_html?
        ]
        | map(first_scalar)
        | map(select(type == "string" and length > 0 and . != "null"))
        | .[0] // empty
    ' 2>/dev/null | head -n 1
}

extract_project_name_from_version() {
    local software_version="$1"
    local upper_version prefix

    upper_version=$(printf '%s' "$software_version" | tr '[:lower:]' '[:upper:]')
    if [[ "$upper_version" =~ (^|[^A-Z0-9])(D01-FL1|D01FL1|D01_FL1)([^A-Z0-9]|$) ]]; then
        printf 'D01-FL1
'
        return 0
    fi
    if [[ "$upper_version" =~ (^|[^A-Z0-9])(D01-P|D01P)([^A-Z0-9]|$) ]]; then
        printf 'D01-P
'
        return 0
    fi
    if [[ "$upper_version" =~ ^([A-Z0-9]+)_ ]]; then
        prefix="${BASH_REMATCH[1]}"
        case "$prefix" in
            KP31|D01)
                printf '%s
' "$prefix"
                return 0
                ;;
            KP31INT)
                printf 'KP31_INT
'
                return 0
                ;;
            D01P)
                printf 'D01-P
'
                return 0
                ;;
        esac
    fi
    return 1
}


normalize_project_name() {
    local project_name="$1"
    local upper_name

    upper_name=$(printf '%s' "$project_name" | tr '[:lower:]' '[:upper:]')

    case "$upper_name" in
        *KP31INT*)
            printf 'KP31_INT
'
            return 0
            ;;
        *KP31*)
            printf 'KP31
'
            return 0
            ;;
        *D01-FL1*|*D01FL1*|*D01_FL1*)
            printf 'D01-FL1
'
            return 0
            ;;
        *D01-P*|*D01P*)
            printf 'D01-P
'
            return 0
            ;;
        *D01*)
            printf 'D01
'
            return 0
            ;;
    esac

    printf '%s
' "$project_name"
}

extract_issue_text_fallback() {
    local issue_json="$1"

    printf '%s' "$issue_json" | jq -r '
        def scalar_text:
            if type == "string" then .
            elif type == "number" or type == "boolean" then tostring
            else empty
            end;
        def flatten_text:
            if type == "array" then
                map(
                    if type == "object" then
                        (.name // .label // .value // .text // .display_value // .display_name // .title // empty) | scalar_text
                    else
                        scalar_text
                    end
                ) | join(" ")
            elif type == "object" then
                (.name // .label // .value // .text // .display_value // .display_name // .title // empty) | scalar_text
            else
                scalar_text
            end;

        [
            .data.title?,
            .data.name?,
            .data.summary?,
            .data.description?,
            .data.tags?,
            .data.labels?,
            .data.field_value_map?,
            .data.fields?,
            .data.custom_fields?,
            .data.custom_field_values?,
            .data.field_value_map?.jira_Software_Version?,
            .data.field_value_map?.jira_MCU_Version?,
            .. | objects | .title?,
            .. | objects | .label?,
            .. | objects | .tags?,
            .. | objects | .labels?,
            .. | objects | .field_name?,
            .. | objects | .display_name?,
            .. | objects | .display_value?,
            .. | objects | .value?,
            .. | objects | .text?
        ]
        | map(flatten_text)
        | map(select(length > 0))
        | join(" ")
    ' 2>/dev/null
}

adapt_right_hand_project_name() {
    local source_text="$1"
    local upper_text token

    upper_text=$(printf '%s' "$source_text" | tr '[:lower:]' '[:upper:]')
    if [[ "$upper_text" != *-RIGHT* && "$upper_text" != *_RIGHT* && "$source_text" != *右舵* ]]; then
        return 1
    fi

    # 右舵项目名来自项目字段本身，例如 CHERY-D01-P-INT-RIGHT，只去掉 CHERY 前缀。
    if [[ "$upper_text" =~ (^|[^A-Z0-9])((CHERY[-_])?[A-Z0-9]+(-[A-Z0-9]+)*-RIGHT)([^A-Z0-9]|$) ]]; then
        token="${BASH_REMATCH[2]}"
        token="${token#CHERY-}"
        token="${token#CHERY_}"
        printf '%s
' "$token"
        return 0
    fi

    return 1
}

resolve_vehicle_project_name() {
    local issue_json="$1"
    local project_id rel_json rel_name api_url

    project_id=$(printf '%s' "$issue_json" | jq -r '
        [
            .data.field_4586a9?,
            .data.for_leopard.field_4586a9?,
            .data.field_value_map?.field_4586a9?
        ]
        | map(
            if type == "number" then tostring
            elif type == "string" then .
            elif type == "object" then (.name // .label // .display_value // .value // empty)
            else empty
            end
        )
        | map(select(type == "string" and length > 0 and . != "null"))
        | .[0] // empty
    ' 2>/dev/null | head -n 1)

    [ -n "$project_id" ] || return 1

    if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
        printf '%s\n' "$project_id"
        return 0
    fi

    [ -n "$PROJECT_KEY" ] || return 1
    api_url="https://project.feishu.cn/goapi/v2/projects/${PROJECT_KEY}/work_item/${VEHICLE_PROJECT_TYPE_KEY}/${project_id}?"
    rel_json=$(fetch_issue_json "$api_url" 2>/dev/null || true)
    rel_name=$(printf '%s' "$rel_json" | jq -r '.data.name // empty' 2>/dev/null | head -n 1)
    [ -n "$rel_name" ] || return 1
    printf '%s\n' "$rel_name"
}

adapt_latest_project_prefix() {
    local source_text="$1"
    local upper

    [ -n "$source_text" ] || return 1
    upper=$(printf '%s' "$source_text" | tr '[:lower:]' '[:upper:]')

    # 只兼容最新项目参数。原有 D01 / D01-FL1 / D01-P / KP31 / KP31_INT / 右舵规则不走这里。
    if [[ "$upper" =~ (^|[^A-Z0-9])(D01-FL1-INT|D01_FL1_INT|D01FL1INT)([^A-Z0-9]|$) ]]; then
        printf 'D01-FL1-INT\n'
        return 0
    fi

    return 1
}

choose_issue_project_name() {
    local issue_json="$1"
    local related prefix inferred

    related=$(resolve_vehicle_project_name "$issue_json" || true)
    if [ -n "$related" ]; then
        RELATED_PROJECT_NAME="$related"
        if prefix=$(adapt_latest_project_prefix "$related"); then
            ISSUE_PROJECT_NAME="$prefix"
            return 0
        fi
    fi

    inferred=$(infer_issue_project_name "$issue_json" || true)
    if [ -n "$inferred" ]; then
        ISSUE_PROJECT_NAME="$inferred"
        return 0
    fi
    return 1
}

infer_issue_project_name() {
    local issue_json="$1"
    local project_name title_text fallback_text upper_text software_version defect_type detected

    project_name=$(extract_issue_project_name "$issue_json")
    if [ -n "$project_name" ]; then
        if detected=$(adapt_right_hand_project_name "$project_name"); then
            printf '%s
' "$detected"
            return 0
        fi
        if detected=$(detect_project_name_from_text "$project_name"); then
            printf '%s
' "$(normalize_project_name "$detected")"
            return 0
        fi
        project_name=$(normalize_project_name "$project_name")
        case "$project_name" in
            KP31_INT|KP31|D01-FL1|D01-P|D01)
                printf '%s
' "$project_name"
                return 0
                ;;
        esac
    fi

    defect_number=$(extract_issue_defect_number "$issue_json")
    if [ -n "$defect_number" ]; then
        if project_name=$(detect_project_name_from_text "$defect_number"); then
            project_name=$(normalize_project_name "$project_name")
            printf '%s
' "$project_name"
            return 0
        fi
    fi

    software_version=$(extract_issue_software_version "$issue_json")
    if project_name=$(extract_project_name_from_version "$software_version"); then
        project_name=$(normalize_project_name "$project_name")
        printf '%s
' "$project_name"
        return 0
    fi

    title_text=$(extract_issue_title "$issue_json")
    upper_text=$(printf '%s' "$title_text" | tr '[:lower:]' '[:upper:]')
    if [[ "$upper_text" =~ [\[【](KP31_INT|KP31|D01-FL1|D01FL1|D01_FL1|D01-P|D01P|D01)[\]】] ]]; then
        project_name=$(normalize_project_name "${BASH_REMATCH[1]}")
        printf '%s
' "$project_name"
        return 0
    fi
    if project_name=$(detect_project_name_from_text "$title_text"); then
        project_name=$(normalize_project_name "$project_name")
        printf '%s
' "$project_name"
        return 0
    fi

    fallback_text=$(extract_issue_text_fallback "$issue_json")
    upper_text=$(printf '%s' "$fallback_text" | tr '[:lower:]' '[:upper:]')
    if [[ "$upper_text" =~ [\[【](KP31_INT|KP31|D01-FL1|D01FL1|D01_FL1|D01-P|D01P|D01)[\]】] ]]; then
        project_name=$(normalize_project_name "${BASH_REMATCH[1]}")
        printf '%s
' "$project_name"
        return 0
    fi
    if project_name=$(detect_project_name_from_text "$fallback_text"); then
        project_name=$(normalize_project_name "$project_name")
        printf '%s
' "$project_name"
        return 0
    fi

    for candidate in KP31_INT KP31 D01-FL1 D01FL1 D01_FL1 D01-P D01P D01; do
        if [[ "$upper_text" == *"$candidate"* ]]; then
            project_name=$(normalize_project_name "$candidate")
            printf '%s
' "$project_name"
            return 0
        fi
    done

    defect_number=$(extract_issue_defect_number "$issue_json")
    if [ -n "$defect_number" ]; then
        if project_name=$(detect_project_name_from_text "$defect_number"); then
            project_name=$(normalize_project_name "$project_name")
            printf '%s
' "$project_name"
            return 0
        fi
    fi

    defect_type=$(extract_issue_defect_type "$issue_json")
    if [ -n "$defect_type" ]; then
        project_name=$(normalize_project_name "$defect_type")
        if [ "$project_name" != "$defect_type" ] || detect_project_name_from_text "$defect_type" >/dev/null; then
            printf '%s
' "$project_name"
            return 0
        fi
    fi

    return 1
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
        *.zip|*.z[0-9][0-9]|*.tar.gz|*.tgz|*.7z|*.[0-9][0-9][0-9]|*.rar|*.r[0-9][0-9]|*.part[0-9]*.rar|*.log|*.log.gz|*.mp4|*.mov|*.mkv|*.txt|*.hprof)
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

build_curl_transfer_args() { CURL_TRANSFER_ARGS=(--fail --silent --show-error --location --continue-at - --retry 3 --retry-delay 1); }

format_duration() {
    local seconds="$1"
    local hours minutes secs

    seconds=${seconds:-0}
    [ "$seconds" -lt 0 ] && seconds=0
    hours=$(( seconds / 3600 ))
    minutes=$(( (seconds % 3600) / 60 ))
    secs=$(( seconds % 60 ))

    if [ "$hours" -gt 0 ]; then
        printf '%d小时%02d分%02d秒' "$hours" "$minutes" "$secs"
    elif [ "$minutes" -gt 0 ]; then
        printf '%d分%02d秒' "$minutes" "$secs"
    else
        printf '%d秒' "$secs"
    fi
}

download_with_progress() {
    local url="$1"
    local filepath="$2"
    local remote_size="$3"
    local pid current_size percent status line display_size tick=0 attempt=0 max_attempts=5 start_time elapsed_time
    local downloaded_size remaining_size

    build_curl_auth_args "$url" || return 1
    start_time=$(date +%s)

    while :; do
        if [ ! -f "$filepath" ]; then
            : > "$filepath"
        fi

        build_curl_transfer_args

        curl \
            "${CURL_TRANSFER_ARGS[@]}" \
            "${CURL_AUTH_ARGS[@]}" \
            -o "$filepath" \
            "$url" &
        pid=$!

        while kill -0 "$pid" 2>/dev/null; do
            current_size=$(stat -c%s "$filepath" 2>/dev/null || echo 0)
            display_size="$current_size"
            elapsed_time=$(( $(date +%s) - start_time ))

            if [[ "$remote_size" =~ ^[0-9]+$ ]] && [ "$remote_size" -gt 0 ]; then
                if [ "$display_size" -gt "$remote_size" ]; then
                    display_size="$remote_size"
                fi
                percent=$(( display_size * 100 / remote_size ))
                if [ "$percent" -gt 100 ]; then
                    percent=100
                fi
                downloaded_size=$(format_size "$display_size")
                remaining_size=$(( remote_size - display_size ))
                [ "$remaining_size" -lt 0 ] && remaining_size=0
                line="   进度: ${percent}% | 已下载: ${downloaded_size} | 剩余: $(format_size "$remaining_size") | 下载时间: $(format_duration "$elapsed_time")"
            else
                percent=$(( tick % 100 ))
                downloaded_size=$(format_size "$display_size")
                line="   进度: ${percent}% | 已下载: ${downloaded_size} | 剩余: 未知 | 下载时间: $(format_duration "$elapsed_time")"
            fi

            printf '\r\033[2K%s' "$line"
            tick=$(( tick + 1 ))
            sleep 1
        done

        wait "$pid"
        status=$?
        current_size=$(stat -c%s "$filepath" 2>/dev/null || echo 0)
        display_size="$current_size"
        elapsed_time=$(( $(date +%s) - start_time ))

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
            downloaded_size=$(format_size "$display_size")
            remaining_size=$(( remote_size - display_size ))
            [ "$remaining_size" -lt 0 ] && remaining_size=0
            line="   进度: ${percent}% | 已下载: ${downloaded_size} | 剩余: $(format_size "$remaining_size") | 下载时间: $(format_duration "$elapsed_time")"
        else
            if [ "$status" -eq 0 ]; then
                percent=100
            else
                percent=$(( tick % 100 ))
            fi
            downloaded_size=$(format_size "$display_size")
            line="   进度: ${percent}% | 已下载: ${downloaded_size} | 剩余: 未知 | 下载时间: $(format_duration "$elapsed_time")"
        fi

        printf '\r\033[2K%s\n' "$line"
        if [ "$status" -eq 0 ]; then
            return 0
        fi

        attempt=$(( attempt + 1 ))
        if [ "$attempt" -ge "$max_attempts" ]; then
            return "$status"
        fi
        echo "   连接中断，尝试续传... ($attempt/$max_attempts)"
        sleep 1
    done
}

downloaded_file_is_login_page() {

    local filepath="$1"
    [ -s "$filepath" ] || return 1

    python3 - "$filepath" <<'PYLOGIN'
import sys
from pathlib import Path
path = Path(sys.argv[1])
data = path.read_bytes()[:4096]
text = data.decode('utf-8', 'ignore').lower()
if '<!doctype html' in text and ('登录 - autolink-jira' in text or 'application-name" content="jira"' in text):
    raise SystemExit(0)
raise SystemExit(1)
PYLOGIN
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
        build_curl_transfer_args
        curl \
            "${CURL_TRANSFER_ARGS[@]}" \
            "${CURL_AUTH_ARGS[@]}" \
            -o "$filepath" \
            "$url"
    fi
}

should_skip_filtered_attachment() {

    local filename="$1"
    local lower_name="${filename,,}"

    [ "${FEISHU_FILTER_SKIP_SPECIAL}" = "1" ] || return 1

    case "$lower_name" in
        can_*.asc|mcu_*.zip|qnx_*.zip)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# downloadFeishuFliter only: for *.hprof, if the target name already exists,
# keep accumulating a numeric suffix (name1.hprof, name2.hprof, ...) instead of
# overwriting. First copy keeps the original name. Other attachments unchanged.
allocate_hprof_save_filename() {
    local save_dir="$1"
    local filename="$2"
    local base n candidate

    [ "${FEISHU_FILTER_SKIP_SPECIAL}" = "1" ] || {
        printf '%s\n' "$filename"
        return 0
    }
    [[ "${filename,,}" == *.hprof ]] || {
        printf '%s\n' "$filename"
        return 0
    }

    candidate="$filename"
    if [ ! -e "${save_dir}/${candidate}" ]; then
        printf '%s\n' "$candidate"
        return 0
    fi

    base="${filename:0:$((${#filename} - 6))}"
    n=1
    candidate="${base}${n}.hprof"
    while [ -e "${save_dir}/${candidate}" ]; do
        n=$((n + 1))
        candidate="${base}${n}.hprof"
    done
    printf '%s\n' "$candidate"
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

render_extract_progress() {
    local current="$1"
    local total="$2"
    local label="${3:-解压进度}"
    local width=24
    local filled=0
    local percent=0
    local bar

    if [ "$total" -gt 0 ]; then
        percent=$(( current * 100 / total ))
        filled=$(( current * width / total ))
    fi
    [ "$filled" -gt "$width" ] && filled=$width
    bar=$(printf '%*s' "$filled" '')
    bar=${bar// /#}
    bar=$(printf '%-*s' "$width" "$bar")
    printf '\r\033[2K%s: [%s] %d%% (%d/%d)' "$label" "$bar" "$percent" "$current" "$total"
}

extract_one_archive() {
    local f="$1"
    local lower_name="${f,,}"
    local archive_dir archive_name archive_stem extract_target_dir base companions has_companion=false

    archive_dir="$(dirname "$f")"
    archive_name="$(basename "$f")"
    [ "$archive_dir" = "." ] && archive_dir="$SAVE_DIR"

    archive_stem="$archive_name"
    case "$lower_name" in
        *.tar.gz) archive_stem="${archive_name%.tar.gz}" ;;
        *.tgz) archive_stem="${archive_name%.tgz}" ;;
        *.part1.rar) archive_stem="${archive_name%.part1.rar}" ;;
        *.rar) archive_stem="${archive_name%.rar}" ;;
        *.zip) archive_stem="${archive_name%.zip}" ;;
        *.7z) archive_stem="${archive_name%.7z}" ;;
        *.001) archive_stem="${archive_name%.001}" ;;
    esac

    group_prefix=""
    if group_prefix=$(top_level_group_prefix "$archive_stem"); then
        extract_target_dir="${archive_dir}/${group_prefix}"
    else
        extract_target_dir="${archive_dir}/${archive_stem}"
    fi
    mkdir -p "$extract_target_dir"

    case "$lower_name" in
        *.zip)
            base="${f%.*}"
            companions=( "${base}".z[0-9][0-9] "${base}".Z[0-9][0-9] )
            for c in "${companions[@]}"; do
                [ -f "$c" ] && has_companion=true && break
            done
            if $has_companion; then
                ( cd "$archive_dir" && 7z x -y -aoa -o"$extract_target_dir" -- "$archive_name" ) >/dev/null 2>&1
            else
                unzip -o "$f" -d "$extract_target_dir" >/dev/null 2>&1
            fi
            ;;
        *.tar.gz|*.tgz)
            tar -xzf "$f" -C "$extract_target_dir" >/dev/null 2>&1
            ;;
        *.001)
            if ( cd "$archive_dir" && 7z x -y -aoa -o"$extract_target_dir" -- "$archive_name" ) >/dev/null 2>&1; then
                :
            elif command -v unar >/dev/null 2>&1 && ( cd "$archive_dir" && unar -force-overwrite -output-directory "$extract_target_dir" "$archive_name" ) >/dev/null 2>&1; then
                :
            else
                ( cd "$archive_dir" && 7z x -y -aoa -o"$extract_target_dir" -- "$archive_name" ) 2>&1 | tail -n 20
                return 1
            fi
            ;;
        *.7z)
            if ( cd "$archive_dir" && 7z x -y -aoa -o"$extract_target_dir" -- "$archive_name" ) >/dev/null 2>&1; then
                :
            elif command -v unar >/dev/null 2>&1 && ( cd "$archive_dir" && unar -force-overwrite -output-directory "$extract_target_dir" "$archive_name" ) >/dev/null 2>&1; then
                :
            else
                ( cd "$archive_dir" && 7z x -y -aoa -o"$extract_target_dir" -- "$archive_name" ) 2>&1 | tail -n 20
                return 1
            fi
            ;;
        *.part1.rar)
            if command -v unrar >/dev/null 2>&1; then
                ( cd "$archive_dir" && unrar x -o+ "$archive_name" "$extract_target_dir/" ) >/dev/null 2>&1
            else
                return 0
            fi
            ;;
        *.rar)
            if command -v unrar >/dev/null 2>&1; then
                if [[ "$lower_name" =~ \.part[0-9]+\.rar$ ]]; then
                    return 0
                fi
                ( cd "$archive_dir" && unrar x -o+ "$archive_name" "$extract_target_dir/" ) >/dev/null 2>&1
            else
                return 0
            fi
            ;;
    esac
}

extract_archives_recursively() {
    local archive_path archive rel_path lower_name processed_in_pass
    local -a pending_archives=()
    local total_archives=0
    local completed_archives=0
    declare -gA extracted_archives_seen=()

    while :; do
        pending_archives=()
        while IFS= read -r -d '' archive_path; do
            [ -f "$archive_path" ] || continue
            rel_path="${archive_path#./}"
            [ -n "$rel_path" ] || rel_path="$(basename "$archive_path")"
            is_supported_archive "$rel_path" || continue
            lower_name="${rel_path,,}"
            case "$lower_name" in
                *.z[0-9][0-9]|*.r[0-9][0-9]) continue ;;
            esac
            if [[ "$lower_name" =~ \.part[0-9]+\.rar$ ]] && [[ "$lower_name" != *.part1.rar ]]; then
                continue
            fi
            if [[ "$lower_name" =~ \.[0-9]{3}$ ]] && [[ "$lower_name" != *.001 ]]; then
                continue
            fi
            [[ -n "${extracted_archives_seen[$rel_path]}" ]] && continue
            pending_archives+=("$archive_path")
        done < <(find . -type f \( -iname "*.zip" -o -iname "*.tar.gz" -o -iname "*.tgz" -o -iname "*.7z" -o -iname "*.001" -o -iname "*.rar" \) -print0 2>/dev/null)

        [ "${#pending_archives[@]}" -gt 0 ] || break
        total_archives=$((completed_archives + ${#pending_archives[@]}))
        processed_in_pass=0

        for archive_path in "${pending_archives[@]}"; do
            rel_path="${archive_path#./}"
            [ -n "$rel_path" ] || rel_path="$(basename "$archive_path")"
            extracted_archives_seen["$rel_path"]=1
            archive="$(basename "$archive_path")"
            render_extract_progress "$completed_archives" "$total_archives"
            ( cd "$(dirname "$archive_path")" || exit 1; extract_one_archive "$archive" )
            completed_archives=$((completed_archives + 1))
            render_extract_progress "$completed_archives" "$total_archives"
            processed_in_pass=1
        done
    done

    if [ "$completed_archives" -gt 0 ]; then
        printf '\n'
    fi
}


extract_gzip_logs() {
    local gzip_path
    local total=0
    local current=0
    local success=0
    local fail=0

    total=$(find . -type f -iname "*.log.gz" -printf '.' 2>/dev/null | wc -c)
    [ "$total" -gt 0 ] || return 0

    while IFS= read -r -d '' gzip_path; do
        if gzip -dkf -- "$gzip_path" >/dev/null 2>&1; then
            success=$((success + 1))
        else
            fail=$((fail + 1))
            printf '\n' >&2
            echo "解压失败: ${gzip_path#./}" >&2
        fi
        current=$((current + 1))
        render_extract_progress "$current" "$total" "解压 gzip 日志"
    done < <(find . -type f -iname "*.log.gz" -print0 2>/dev/null)

    printf '\n'
    if [ "$fail" -gt 0 ]; then
        echo "gzip 日志解压完成: 成功 ${success}, 失败 ${fail}"
    else
        echo "gzip 日志解压完成: ${success} 个"
    fi
}

# Qcore-00000000-2026-09-16_15-51-30 -> Qcore
# Audio-00000000-...（即使只有一份）-> Audio
# sm52_20260916_144046 -> sm52
top_level_group_prefix() {
    local name="$1"
    if [[ "$name" =~ ^([A-Za-z][A-Za-z0-9]*)-[0-9]{4,} ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "$name" =~ ^([A-Za-z][A-Za-z0-9]*)_[0-9]{8}_ ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return 0
    fi
    return 1
}

rehome_top_level_groups() {
    local entry name prefix dest nested moved=0

    while IFS= read -r -d '' entry; do
        [ -d "$entry" ] || continue
        name=$(basename "$entry")
        prefix=$(top_level_group_prefix "$name") || continue
        dest="$SAVE_DIR/$prefix"
        case "$entry" in
            "$dest"|"$dest"/*) continue ;;
        esac
        mkdir -p "$dest"
        if [ -e "$dest/$name" ]; then
            find "$entry" -mindepth 1 -maxdepth 1 -exec mv -n {} "$dest/" \;
            rmdir "$entry" 2>/dev/null || rm -rf "$entry"
        else
            mv -n "$entry" "$dest/"
        fi
        moved=$((moved + 1))
    done < <(find "$SAVE_DIR" -depth -type d -print0)

    while IFS= read -r -d '' nested; do
        [ -d "$nested" ] || continue
        name=$(basename "$nested")
        dest="$SAVE_DIR/$name"
        [ "$nested" = "$dest" ] && continue
        [ -d "$dest" ] || continue
        find "$nested" -mindepth 1 -maxdepth 1 -exec mv -n {} "$dest/" \;
        rmdir "$nested" 2>/dev/null || true
        moved=$((moved + 1))
    done < <(find "$SAVE_DIR" -mindepth 2 -maxdepth 2 -type d -print0)

    if [ "$moved" -gt 0 ]; then
        echo "已收拢 ${moved} 个日志目录到前缀分组"
    fi
}

fix_logcat_permissions() {
    local dir found=0

    while IFS= read -r -d '' dir; do
        chmod -R 755 "$dir"
        echo "🔧 已修正 logcat 目录权限: ${dir#./} -> 755"
        found=1
    done < <(find . -type d -name 'logcat' -print0 2>/dev/null)

    [ "$found" -eq 1 ] || return 0
}

prepare_save_dir() {
    local save_parent save_name existing_path

    echo "正在清理旧文件..."
    save_parent=$(dirname "$SAVE_DIR")
    save_name=$(basename "$SAVE_DIR")

    if [ -d "$save_parent" ]; then
        while IFS= read -r -d '' existing_path; do
            [ -e "$existing_path" ] || continue
            chmod -R u+rwX "$existing_path" 2>/dev/null || true
            find "$existing_path" -type d -exec chmod u+rwx {} + 2>/dev/null || true
            find "$existing_path" -type f -exec chmod u+rw {} + 2>/dev/null || true
            rm -rf "$existing_path"
        done < <(find "$save_parent" -maxdepth 1 \( -name "*${ISSUE_ID}*" -o -name "$save_name" \) -print0 2>/dev/null)
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

RELATED_PROJECT_NAME=""
ISSUE_PROJECT_NAME=""
choose_issue_project_name "$ISSUE_JSON" || true
ISSUE_PROJECT_DEBUG=$(extract_issue_project_debug_snippets "$ISSUE_JSON")
if [ -z "$ISSUE_PROJECT_NAME" ]; then
    # Some issue payloads expose the software version only on the detail body.
    issue_version_fallback=$(printf '%s' "$ISSUE_JSON" | jq -r '.data.jira_customfield_12606_8_5 // .data.for_leopard.jira_customfield_12606_8_5 // empty' 2>/dev/null | head -n 1)
    if project_name=$(extract_project_name_from_version "$issue_version_fallback"); then
        ISSUE_PROJECT_NAME=$project_name
    fi
fi
SAVE_DIR=$(build_save_dir "$ISSUE_ID" "$ISSUE_PROJECT_NAME")
DETAIL_JSON_FILE=$(mktemp)
printf '%s' "$ISSUE_JSON" > "$DETAIL_JSON_FILE"
TEMP_JSON_FILES=("$DETAIL_JSON_FILE")

MG_JIRA_LOCAL_UPLOAD_JSON=""
MG_JIRA_LOCAL_UPLOAD_JSON_FILE=""
MG_JIRA_PROJECT_KEY=$(printf '%s' "$ISSUE_JSON" | jq -r '.data.project_key // .data.project?.project_key // .data.project?.key // empty' 2>/dev/null | head -n 1)
if [ -n "$MG_JIRA_PROJECT_KEY" ]; then
    MG_JIRA_LOCAL_UPLOAD_JSON=$(fetch_mg_jira_local_upload_json "$MG_JIRA_PROJECT_KEY" "$WORK_ITEM_TYPE" "$ISSUE_ID" 2>/dev/null || true)
    if [ -n "$MG_JIRA_LOCAL_UPLOAD_JSON" ] && printf '%s' "$MG_JIRA_LOCAL_UPLOAD_JSON" | jq -e '.ok == true and (.data | type == "array")' >/dev/null 2>&1; then
        MG_JIRA_LOCAL_UPLOAD_JSON=$(printf '%s' "$MG_JIRA_LOCAL_UPLOAD_JSON" | jq --arg project_key "$MG_JIRA_PROJECT_KEY" --arg work_item_type "$WORK_ITEM_TYPE" --arg work_item_id "$ISSUE_ID" '
            .data |= map(. + {
                url: ("https://mg-jira.auto-link.com.cn/api/files/download/" + .id + "?project_key=" + $project_key + "&work_item_type_key=" + $work_item_type + "&work_item_id=" + $work_item_id + "&download=1")
            })
        ')
        MG_JIRA_LOCAL_UPLOAD_JSON_FILE=$(mktemp)
        printf '%s' "$MG_JIRA_LOCAL_UPLOAD_JSON" > "$MG_JIRA_LOCAL_UPLOAD_JSON_FILE"
        TEMP_JSON_FILES+=("$MG_JIRA_LOCAL_UPLOAD_JSON_FILE")
    fi
fi

EXPORTED_REQUEST_JSON_URL=$(build_target_request_url "$FEISHU_REQUEST_URL" "$ISSUE_ID")
EXPORTED_REQUEST_JSON_FILE=""
if [ -n "$EXPORTED_REQUEST_JSON_URL" ] && [ "$EXPORTED_REQUEST_JSON_URL" != "$ISSUE_API_URL" ]; then
    EXPORTED_REQUEST_JSON=$(fetch_feishu_json_from_url "$EXPORTED_REQUEST_JSON_URL" 2>/dev/null || true)
    if [ -n "$EXPORTED_REQUEST_JSON" ] && printf '%s' "$EXPORTED_REQUEST_JSON" | jq -e . >/dev/null 2>&1; then
        EXPORTED_REQUEST_JSON_FILE=$(mktemp)
        printf '%s' "$EXPORTED_REQUEST_JSON" > "$EXPORTED_REQUEST_JSON_FILE"
        TEMP_JSON_FILES+=("$EXPORTED_REQUEST_JSON_FILE")

        # Keep the original naming flow; only fall back to the exported detail/log payload when the work-item API has no project hint.
        if [ -z "$ISSUE_PROJECT_NAME" ]; then
            choose_issue_project_name "$EXPORTED_REQUEST_JSON" || true
            ISSUE_PROJECT_DEBUG=$(extract_issue_project_debug_snippets "$EXPORTED_REQUEST_JSON")
            SAVE_DIR=$(build_save_dir "$ISSUE_ID" "$ISSUE_PROJECT_NAME")
        fi
    fi
fi

cleanup_temp_json_files() {
    local temp_file
    for temp_file in "${TEMP_JSON_FILES[@]}"; do
        [ -n "$temp_file" ] && rm -f "$temp_file"
    done
}
trap cleanup_temp_json_files EXIT

prepare_save_dir

echo "======================================"
echo "开始下载 Feishu Issue: $ISSUE_ID"
echo "Issue 链接: $ISSUE_URL"
echo "项目参数: ${RELATED_PROJECT_NAME:-<empty>}"
echo "ISSUE_PROJECT_NAME: ${ISSUE_PROJECT_NAME:-<empty>}"
echo "项目字段命中片段: ${ISSUE_PROJECT_DEBUG:-[]}"
echo "保存目录: $SAVE_DIR"
echo "======================================"
DOWNLOAD_ALL_START_TIME=$(date +%s)

mapfile -t ATTACHMENTS < <(collect_attachment_entries "${TEMP_JSON_FILES[@]}")
COUNT=${#ATTACHMENTS[@]}
if [ "$COUNT" -eq 0 ]; then
    echo "Issue 没有附件，或接口里未返回可识别的附件对象"
    exit 1
fi

echo "找到 $COUNT 个附件，开始下载..."

for attachment in "${ATTACHMENTS[@]}"; do
    IFS='|' read -r url filename <<< "$attachment"
    [ -n "$url" ] || continue

    # Prefer the attachment name returned by the API, unless it is Feishu's generic placeholder like 文件1.
    filename="${filename:-}"
    if [[ "$filename" =~ ^文件[0-9]+$ ]]; then
        filename=""
    fi
    if [ -z "$filename" ] || [[ "$filename" == */* ]]; then
        filename="$(basename "${url%%\?*}")"
    fi
    if [ -z "$filename" ] || [[ "$filename" == */* ]] || [[ "$filename" == issue ]]; then
        filename=$(resolve_filename_from_headers "$url" "${filename:-附件}")
    fi
    filename=$(python3 - "$filename" <<'PYNAME'
import sys
from urllib.parse import unquote
print(unquote(sys.argv[1]))
PYNAME
)
    if [[ "$url" == https://jira-shzj.auto-link.com.cn/* ]]; then
        mkdir -p "${SAVE_DIR}/jira_file"
        filename="$(allocate_hprof_save_filename "${SAVE_DIR}/jira_file" "$filename")"
        filepath="${SAVE_DIR}/jira_file/${filename}"
    else
        filename="$(allocate_hprof_save_filename "$SAVE_DIR" "$filename")"
        filepath="${SAVE_DIR}/${filename}"
    fi

    if should_skip_filtered_attachment "$filename"; then
        echo "跳过过滤附件: $filename"
        continue
    fi

    echo "下载: $filename"
    if download_attachment "$url" "$filepath" "$filename" && [ -s "$filepath" ]; then
        if downloaded_file_is_login_page "$filepath"; then
            echo "下载失败: $filename (返回了 JIRA 登录页，请检查 FEISHU_ATTACHMENT_JIRA_CURL_EXPORT_FILE / FEISHU_ATTACHMENT_JIRA_COOKIE)"
            rm -f "$filepath"
            continue
        fi
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
chmod -R u+rwX . 2>/dev/null || true
extract_gzip_logs
rehome_top_level_groups
fix_logcat_permissions

shopt -u nullglob nocaseglob
cd - >/dev/null || exit 1

DOWNLOAD_ALL_END_TIME=$(date +%s)
echo "下载完成，总耗时: $(format_duration $(( DOWNLOAD_ALL_END_TIME - DOWNLOAD_ALL_START_TIME )))"
echo
echo "当前目录内容:"
ls -lh "$SAVE_DIR" 2>/dev/null || echo "目录为空"
