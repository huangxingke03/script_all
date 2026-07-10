#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/voice_build_common.sh"

DEFAULT_DEVICE_SERIAL=""
DEVICE_SERIAL="${DEFAULT_DEVICE_SERIAL}"
SERVICE_NAME="com.autolink.voiceassistant/com.autolink.voiceassistant.service.VoiceCommonService"
SEMAN_VALUE="1"

print_device_usage() {
    echo "用法: $0 [-s device_serial]"
    echo "  -s device_serial  指定 adb 设备序列号"
}

adb_cmd() {
    if [ -n "${DEVICE_SERIAL}" ]; then
        adb -s "${DEVICE_SERIAL}" "$@"
    else
        adb "$@"
    fi
}

parse_device_args "$@"
shift $((OPTIND - 1))

if [ "$#" -gt 0 ]; then
    echo "错误: 不支持的位置参数: $*"
    print_device_usage
    exit 1
fi

if [ -n "${DEVICE_SERIAL}" ]; then
    ensure_device_ready "${DEVICE_SERIAL}"
fi

echo "执行音按键服务"
adb_cmd shell am startservice     -n "${SERVICE_NAME}"     --es "seman" "${SEMAN_VALUE}"
