#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "$SCRIPT_DIR/voice_build_common.sh" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/voice_build_common.sh"
elif [ -f "$SCRIPT_DIR/../voice_build/voice_build_common.sh" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/../voice_build/voice_build_common.sh"
else
    echo "错误: 未找到 voice_build_common.sh" >&2
    exit 1
fi

DEFAULT_DEVICE_SERIAL="f6e277ff"
DEVICE_SERIAL="$DEFAULT_DEVICE_SERIAL"
VOICE_PACKAGE="com.autolink.voiceassistant"

print_device_usage() {
    echo "用法: $0 [-s device_serial]"
    echo "  -s device_serial  指定台架设备序列号，默认: $DEFAULT_DEVICE_SERIAL"
    echo "  杀掉进程重启 ${VOICE_PACKAGE}"
}

wait_for_restarted_pid() {
    local old_pid="$1"
    local new_pid=""
    local attempt

    for attempt in 1 2 3 4 5; do
        sleep 1
        new_pid=$(adb_cmd "$ADB_CMD_TIMEOUT" shell pidof "$VOICE_PACKAGE" 2>/dev/null | tr -d '\r' || true)
        if [ -n "$new_pid" ] && [ "$new_pid" != "$old_pid" ]; then
            printf '%s\n' "$new_pid"
            return 0
        fi
    done
    return 1
}

parse_device_args "$@"
shift $((OPTIND - 1))

if [ "$#" -gt 0 ]; then
    echo "错误: 不支持的位置参数: $*"
    print_device_usage
    exit 1
fi

ensure_device_ready "$DEVICE_SERIAL"
if ! adbd_is_root; then
    restart_adbd_as_root
fi

echo "杀掉进程重启: ${VOICE_PACKAGE}"
echo "当前台架设备: ${DEVICE_SERIAL} ($(get_device_display_name "$DEVICE_SERIAL"))"

old_pid=$(adb_cmd "$ADB_CMD_TIMEOUT" shell pidof "$VOICE_PACKAGE" | tr -d '\r')
if [ -z "$old_pid" ]; then
    echo "错误: 设备上没有 ${VOICE_PACKAGE} 进程"
    exit 1
fi

echo "杀掉进程: ${old_pid}"
adb_cmd "$ADB_CMD_TIMEOUT" shell kill -9 $old_pid || true

if ! new_pid=$(wait_for_restarted_pid "$old_pid"); then
    echo "错误: 杀掉进程后语音助手未重启"
    exit 1
fi

echo "语音助手已重启，新进程: ${new_pid}"
