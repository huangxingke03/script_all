#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/voice_build/voice_build_common.sh"

DEVICE_SERIAL=""

print_usage() {
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

ensure_device_ready() {
    local device_status
    local device_count

    adb start-server >/dev/null
    if [ -n "${DEVICE_SERIAL}" ]; then
        device_status=$(adb devices | sed '1d' | awk -v serial="${DEVICE_SERIAL}" '$1 == serial {print $2}')
        if [ -z "${device_status}" ]; then
            echo "错误: adb devices 中未找到设备序列号 ${DEVICE_SERIAL}"
            exit 1
        fi
        if [ "${device_status}" != "device" ]; then
            echo "错误: 设备 ${DEVICE_SERIAL} 当前状态为 ${device_status}，必须为 device 才能继续"
            exit 1
        fi
        return 0
    fi

    device_count=$(adb devices | sed '1d' | awk '$2 == "device" {count++} END {print count + 0}')
    if [ "${device_count}" -gt 1 ]; then
        echo "错误: 检测到多个在线设备，请使用 -s 指定设备序列号"
        exit 1
    fi
}

ensure_root_ready() {
    adb_cmd root >/dev/null 2>&1 || {
        echo "错误: adb root 失败，请确认设备已开启 root 权限"
        exit 1
    }
}

while getopts ":s:h" opt; do
    case "${opt}" in
        s)
            DEVICE_SERIAL="${OPTARG}"
            ;;
        h)
            print_print_usage
            exit 0
            ;;
        :)
            echo "错误: -${OPTARG} 需要传入设备序列号"
            print_print_usage
            exit 1
            ;;
        \?)
            echo "错误: 不支持的参数 -${OPTARG}"
            print_print_usage
            exit 1
            ;;
    esac
done

ensure_device_ready
ensure_root_ready
adb_cmd reboot
