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
VOICE_PACKAGE="com.autolink.voicesetting"
HOME_ACTIVITY="com.autolink.voicesetting/.ui.MainActivity"

print_device_usage() {
    echo "用法: $0 [-s device_serial]"
    echo "  -s device_serial  指定台架设备序列号，默认: $DEFAULT_DEVICE_SERIAL"
    echo "  杀掉 ${VOICE_PACKAGE} 后打开首页 ${HOME_ACTIVITY}"
}

wait_for_pid() {
    local pid=""
    local attempt

    for attempt in 1 2 3 4 5; do
        sleep 1
        pid=$(adb_cmd "$ADB_CMD_TIMEOUT" shell pidof "$VOICE_PACKAGE" 2>/dev/null | tr -d '\r' || true)
        if [ -n "$pid" ]; then
            printf '%s\n' "$pid"
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

old_pid=$(adb_cmd "$ADB_CMD_TIMEOUT" shell pidof "$VOICE_PACKAGE" 2>/dev/null | tr -d '\r' || true)
if [ -n "$old_pid" ]; then
    echo "杀掉进程: ${old_pid}"
    adb_cmd "$ADB_CMD_TIMEOUT" shell kill -9 $old_pid || true
fi

start_output=$(adb_cmd "$ADB_CMD_TIMEOUT" shell am start -n "$HOME_ACTIVITY" 2>&1 || true)
if printf '%s\n' "$start_output" | grep -Eq 'Error|Exception|does not exist'; then
    echo "打开首页失败"
    exit 1
fi

if ! new_pid=$(wait_for_pid); then
    echo "打开首页失败"
    exit 1
fi

echo "重启首页成功: ${new_pid}"
