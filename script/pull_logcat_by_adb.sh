#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/voice_build_common.sh"

DOWNLOAD_ROOT="/home/huangxingke/下载"
DEFAULT_DEVICE_SERIAL=""
REMOTE_PATH="/log"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

adb_cmd() {
    if [ -n "${DEVICE_SERIAL}" ]; then
        adb -s "${DEVICE_SERIAL}" "$@"
    else
        adb "$@"
    fi
}

print_device_usage() {
    echo "用法: $0 [-s device_serial] [remote_path]"
    echo "  -s device_serial  指定 adb 设备序列号"
    echo "  remote_path       可选，默认: /log"
}

parse_device_args "$@"
shift $((OPTIND - 1))

if [ "$#" -gt 1 ]; then
    echo "错误: 最多只支持 1 个远端路径参数: $*"
    print_device_usage
    exit 1
fi

if [ "$#" -eq 1 ]; then
    REMOTE_PATH="$1"
fi

if [ -n "${DEVICE_SERIAL}" ]; then
    ensure_device_ready "${DEVICE_SERIAL}"
fi

TARGET_BASENAME=$(basename "${REMOTE_PATH}")
[ -n "${TARGET_BASENAME}" ] || TARGET_BASENAME="pull"
TARGET_BASENAME="${TARGET_BASENAME//[^a-zA-Z0-9._-]/_}"

TARGET_SERIAL="${DEVICE_SERIAL}"
if [ -z "${TARGET_SERIAL}" ]; then
    TARGET_SERIAL=$(adb get-serialno 2>/dev/null)
fi
[ -n "${TARGET_SERIAL}" ] || TARGET_SERIAL="unknown_device"
TARGET_SERIAL="${TARGET_SERIAL//[^a-zA-Z0-9._-]/_}"

TARGET_PREFIX="${TARGET_SERIAL}"
if [ "${TARGET_SERIAL}" = "3165e176" ]; then
    TARGET_PREFIX="D01_${TARGET_SERIAL}"
elif [ "${TARGET_SERIAL}" = "c40b48ac" ]; then
    TARGET_PREFIX="KP31_${TARGET_SERIAL}"
fi

TARGET_DIR="${DOWNLOAD_ROOT}/${TARGET_PREFIX}_${TARGET_BASENAME}_${TIMESTAMP}"
mkdir -p "${TARGET_DIR}"

echo "执行 adb root"
adb_cmd root

echo "执行 adb remount"
adb_cmd remount

echo "拉取设备 ${REMOTE_PATH} 到 ${TARGET_DIR}"
adb_cmd pull "${REMOTE_PATH}" "${TARGET_DIR}"

echo "完成: ${REMOTE_PATH} 已拉取到 ${TARGET_DIR}"
