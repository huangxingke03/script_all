#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/voice_build/voice_build_common.sh"

DEFAULT_DEVICE_SERIAL="f6e277ff"
DEVICE_SERIAL="${DEFAULT_DEVICE_SERIAL}"
SERVICE_NAME="com.autolink.voiceassistant/com.autolink.voiceassistant.service.VoiceCommonService"
SEMAN_VALUE="1"

print_device_usage() {
    echo "用法: $0 [-s device_serial]"
    echo "  -s device_serial  指定台架设备序列号，默认: ${DEFAULT_DEVICE_SERIAL}"
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

ensure_device_ready "${DEVICE_SERIAL}"
DEVICE_NAME=$(get_device_display_name "${DEVICE_SERIAL}")

echo "当前台架设备: ${DEVICE_SERIAL} (${DEVICE_NAME})"
echo "执行音按键服务"
adb_cmd shell am startservice     -n "${SERVICE_NAME}"     --es "seman" "${SEMAN_VALUE}"
echo "已触发音按键服务"
