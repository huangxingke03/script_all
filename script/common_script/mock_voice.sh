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
    echo "用法: $0 [-s device_serial] <指令文本> [主驾|副驾|左后|右后]"
    echo "  -s device_serial  指定台架设备序列号，默认: ${DEFAULT_DEVICE_SERIAL}"
    echo "  指令文本          模拟语音识别文本，例如: 搜索专辑天外来物"
    echo "  唤醒方位          放在指令文本最后。主驾=left，副驾=right，左后=left_behind，右后=right_behind。默认主驾"
    echo "  示例: $0 -s ${DEFAULT_DEVICE_SERIAL} 查询专辑冬天里的一把火 主驾"
}

adb_cmd() {
    adb -s "${DEVICE_SERIAL}" "$@"
}

build_remote_command() {
    python3 - "$1" "$2" <<'PY'
import json
import sys
import urllib.parse

text = sys.argv[1]
direction = sys.argv[2]

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
    + "&mode=1"
)
# WakeUpReceiver 监听 vr://com.iflytek.autofly.vr/sr/status/start?direction=
wake_uri = (
    "vr://com.iflytek.autofly.vr/sr/status/start?direction="
    + uri_escape(direction)
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
# shell(uid 2000) 不能发 ACTION_VIEW，需 root 代发才能进 WakeUpReceiver
wake_broadcast = (
    "am broadcast -a android.intent.action.VIEW "
    "-c android.intent.category.BROWSABLE "
    "-p com.autolink.voiceassistant "
    f"-d {sq(wake_uri)}"
)
print(
    f"if [ \"$(id -u)\" = 0 ]; then {wake_broadcast}; "
    f"else su 0 {wake_broadcast}; fi && sleep 0.2 && "
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

WAKE_DIRECTION="left"
WAKE_DIRECTION_LABEL="主驾"
if [ "$#" -ge 2 ]; then
    case "${!#}" in
        主驾|left)
            WAKE_DIRECTION="left"
            WAKE_DIRECTION_LABEL="主驾"
            set -- "${@:1:$#-1}"
            ;;
        副驾|right)
            WAKE_DIRECTION="right"
            WAKE_DIRECTION_LABEL="副驾"
            set -- "${@:1:$#-1}"
            ;;
        左后|left_behind)
            WAKE_DIRECTION="left_behind"
            WAKE_DIRECTION_LABEL="左后"
            set -- "${@:1:$#-1}"
            ;;
        右后|right_behind)
            WAKE_DIRECTION="right_behind"
            WAKE_DIRECTION_LABEL="右后"
            set -- "${@:1:$#-1}"
            ;;
    esac
fi

VOICE_TEXT="$*"
if [ -z "${VOICE_TEXT}" ]; then
    echo "错误: 指令文本不能为空"
    print_device_usage
    exit 1
fi

# 会话号为空时直接发。被占用时只在这一条开始前重启一次，连续的后面几条不再重启。
# 这段初始化是讯飞引擎起来的时间，提前发文本会被拦截，不能跳过。
IFLYTEK_PKG="com.iflytek.cutefly.speechclient.hmi"

iflytek_pid() {
    adb_cmd shell pidof "${IFLYTEK_PKG}" 2>/dev/null | tr -d '\r' | awk '{print $1}' || true
}

device_log_mark() {
    adb_cmd shell date +%m-%d_%H:%M:%S.%3N | tr -d '\r' | tr '_' ' '
}

# 0 = 可以直接发；1 = 会话号被占用，需要重启
session_is_clean() {
    local pid="$1"
    adb -s "${DEVICE_SERIAL}" logcat -d -s SrTraceIdHolder:I SrBusinessManager:E CarByteDanceAdapterImpl:I 2>/dev/null \
        | python3 -c 'import sys
pid = sys.argv[1]
seen_init = False
last_task = None
lock_after = False
for raw in sys.stdin:
    line = raw.replace("\r", "")
    fields = line.split()
    if pid not in fields and f"({pid})" not in line:
        continue
    if "SrBusinessManager" in line and "onInitCompleted()" in line:
        seen_init = True
        last_task = None
        lock_after = False
        continue
    if "generateTaskId:" in line:
        last_task = line.split("generateTaskId:", 1)[1].strip()
        lock_after = False
        continue
    if "SrTraceIdHolder" in line and ("lockNewSession" in line or "fillIfAbsent" in line):
        lock_after = True
if lock_after:
    sys.exit(1)
if last_task and last_task.startswith("d01fl_"):
    sys.exit(0)
if seen_init and not last_task:
    sys.exit(0)
sys.exit(1)' "${pid}"
}

reset_iflytek_session() {
    local old_pid new_pid mark i hit
    old_pid="$(iflytek_pid)"
    mark="$(device_log_mark)"
    if [ -n "${old_pid}" ]; then
        adb_cmd shell su 0 kill -9 "${old_pid}"
    fi
    new_pid=""
    for i in $(seq 1 40); do
        new_pid="$(iflytek_pid)"
        if [ -n "${new_pid}" ] && [ "${new_pid}" != "${old_pid}" ]; then
            break
        fi
        new_pid=""
        sleep 0.25
    done
    if [ -z "${new_pid}" ]; then
        echo "错误: 讯飞语音没有重新启动" >&2
        exit 1
    fi
    for i in $(seq 1 80); do
        hit="$(adb -s "${DEVICE_SERIAL}" logcat -d -T "${mark}" \
            | grep -a -F "${new_pid}" \
            | grep -a -F "SrBusinessManager: onInitCompleted()" \
            | head -n 1 || true)"
        if [ -n "${hit}" ]; then
            return 0
        fi
        sleep 0.3
    done
    echo "错误: 讯飞语音初始化未完成" >&2
    exit 1
}

# 只认本条文本发出之后的 dispatchSemantic，避免把上一条当成这一条。
wait_semantic_dispatched() {
    local mark="$1"
    local text="$2"
    local i result
    for i in $(seq 1 40); do
        result="$(adb -s "${DEVICE_SERIAL}" logcat -d -T "${mark}" -s CarByteDanceAdapterImpl:I VALog_VRManager:I \
            | python3 -c 'import sys
text = sys.argv[1]
send_ts = None
for raw in sys.stdin:
    line = raw.replace("\r", "").rstrip("\n")
    fields = line.split()
    if len(fields) < 2:
        continue
    ts = fields[0] + " " + fields[1]
    if "sendASRResult" in line and line.endswith("text:" + text):
        send_ts = ts
    if send_ts and "dispatchSemantic : request =" in line and ts >= send_ts:
        print("ok")
        raise SystemExit
print("wait")' "${text}")"
        if [ "${result}" = "ok" ]; then
            return 0
        fi
        sleep 0.3
    done
    echo "警告: 未在时限内看到语义下发" >&2
}

ensure_device_ready "${DEVICE_SERIAL}"
DEVICE_NAME="$(get_device_display_name "${DEVICE_SERIAL}")"
REMOTE_CMD="$(build_remote_command "${VOICE_TEXT}" "${WAKE_DIRECTION}")"

echo "当前台架设备: ${DEVICE_SERIAL} (${DEVICE_NAME})"
echo "唤醒方位: ${WAKE_DIRECTION_LABEL} (${WAKE_DIRECTION})"
echo "模拟语音指令: ${VOICE_TEXT}"
CURRENT_PID="$(iflytek_pid)"
if [ -n "${CURRENT_PID}" ] && session_is_clean "${CURRENT_PID}"; then
    echo "直接下发"
else
    echo "会话号被占用，重新初始化"
    reset_iflytek_session
fi
DISPATCH_MARK="$(device_log_mark)"
adb_cmd shell "${REMOTE_CMD}"
wait_semantic_dispatched "${DISPATCH_MARK}" "${VOICE_TEXT}"
echo "已发送模拟语音指令"
