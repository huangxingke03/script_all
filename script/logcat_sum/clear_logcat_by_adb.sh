#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/voice_build/voice_build_common.sh"

DEFAULT_REMOTE_PATH="/log"
REMOTE_PATH="${DEFAULT_REMOTE_PATH}"

adb_cmd() {
    if [ -n "${DEVICE_SERIAL}" ]; then
        adb -s "${DEVICE_SERIAL}" "$@"
    else
        adb "$@"
    fi
}

print_usage() {
    echo "用法: $0 [-s device_serial] [remote_path]"
    echo "  -s device_serial  指定 adb 设备序列号"
    echo "  remote_path       可选，默认: ${DEFAULT_REMOTE_PATH}"
}

parse_device_args "$@"
shift $((OPTIND - 1))

if [ "$#" -gt 1 ]; then
    echo "错误: 最多只支持 1 个远端路径参数: $*"
    print_usage
    exit 1
fi

if [ "$#" -eq 1 ]; then
    REMOTE_PATH="$1"
fi

if [ -n "${DEVICE_SERIAL}" ]; then
    ensure_device_ready "${DEVICE_SERIAL}"
fi

echo "执行 adb root"
adb_cmd root

echo "执行 adb remount"
adb_cmd remount

echo "清空设备目录 ${REMOTE_PATH} 下的日志内容"
adb_cmd shell "find '${REMOTE_PATH}' -mindepth 1 -delete"

echo "完成: ${REMOTE_PATH} 下的内容已清空"
