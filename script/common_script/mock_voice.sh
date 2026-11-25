#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/voice_build_common.sh" ]; then
    COMMON_SH="${SCRIPT_DIR}/voice_build_common.sh"
elif [ -f "${SCRIPT_DIR}/../voice_build/voice_build_common.sh" ]; then
    COMMON_SH="${SCRIPT_DIR}/../voice_build/voice_build_common.sh"
else
    echo "错误: 未找到 voice_build_common.sh" >&2
    exit 1
fi
# shellcheck disable=SC1091
source "${COMMON_SH}"

DEFAULT_DEVICE_SERIAL="${DEFAULT_D01_DEVICE_SERIAL}"
DEVICE_SERIAL="${DEFAULT_DEVICE_SERIAL}"

print_device_usage() {
    echo "用法: $0 [-s device_serial] <指令文本>"
    echo "  -s device_serial  指定台架设备序列号，默认: ${DEFAULT_DEVICE_SERIAL}"
    echo "  指令文本          模拟语音识别文本，例如: 搜索专辑天外来物"
    echo "  示例: $0 -s ${DEFAULT_DEVICE_SERIAL} 搜索专辑天外来物"
}

adb_cmd() {
    adb -s "${DEVICE_SERIAL}" "$@"
}

build_remote_command() {
    python3 - "$1" <<'PY'
import json
import sys
import urllib.parse

text = sys.argv[1]

def uri_escape(value: str) -> str:
    out = []
    for ch in value:
        if ch.isalnum() or ord(ch) > 127 or ch in "-_.~":
            out.append(ch)
        else:
            out.append(urllib.parse.quote(ch, safe=""))
    return "".join(out)

def sq(value: str) -> str:
    return "'" + value.replace("'", "'\\''") + "'"

uri = (
    "vr://com.iflytek.autofly.vr/interaction/getSemantic?text="
    + uri_escape(text)
    + "&mode=2"
)
payload = {
    "dt": "voice_pgs",
    "ps": 1,
    "pt": text,
    "type": 0,
    "sss": 1,
    "slc": 3,
    "sct": 2,
    "sex": 4,
    "vsid": "default",
    "isEnd": False,
}
body = json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
print(
    "am start-foreground-service -a android.intent.action.VIEW "
    "-n com.iflytek.cutefly.speechclient.hmi/com.iflytek.auto.speechclient.sdk.wakeup.WakeUpReceiverService "
    f"-d {sq(uri)}; sleep 0.6; "
    "am start-foreground-service -n com.iflytek.autofly.sceneengine/.VpaDataService "
    "-a com.iflytek.autofly.sceneengine.DATAUPLOAD --es value "
    f"{sq(body)}"
)
PY
}

parse_device_args "$@"
shift $((OPTIND - 1))
if [ "${1:-}" = "--" ]; then
    shift
fi

if [ "$#" -lt 1 ]; then
    echo "错误: 需要传入指令文本"
    print_device_usage
    exit 1
fi

VOICE_TEXT="$*"
if [ -z "${VOICE_TEXT}" ]; then
    echo "错误: 指令文本不能为空"
    print_device_usage
    exit 1
fi

ensure_device_ready "${DEVICE_SERIAL}"
DEVICE_NAME="$(get_device_display_name "${DEVICE_SERIAL}")"
REMOTE_CMD="$(build_remote_command "${VOICE_TEXT}")"

echo "当前台架设备: ${DEVICE_SERIAL} (${DEVICE_NAME})"
echo "模拟语音指令: ${VOICE_TEXT}"
adb_cmd shell "${REMOTE_CMD}"
echo "已发送模拟语音指令"
