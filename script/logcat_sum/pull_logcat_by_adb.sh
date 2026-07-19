#!/bin/bash

DEFAULT_D01_DEVICE_SERIAL="f6e277ff"
DEFAULT_KP31_DEVICE_SERIAL="3d3fd206"
DOWNLOAD_ROOT="/home/huangxingke/下载"
DEFAULT_REMOTE_PATH="/log"
REMOTE_PATH="${DEFAULT_REMOTE_PATH}"
TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"

resolve_connected_device_serial() {
    local query="$1"
    local line serial state
    local -a exact_matches=() prefix_matches=()

    while IFS= read -r line; do
        [ -z "${line}" ] && continue
        case "${line}" in
            List\ of\ devices* )
                continue
                ;;
        esac

        serial=$(awk '{print $1}' <<< "${line}")
        state=$(awk '{print $2}' <<< "${line}")
        [ "${state}" != "device" ] && continue

        if [ "${serial}" = "${query}" ]; then
            exact_matches+=("${serial}")
        elif [[ "${serial}" == "${query}"* ]]; then
            prefix_matches+=("${serial}")
        fi
    done < <(adb devices -l 2>/dev/null)

    if [ ${#exact_matches[@]} -eq 1 ]; then
        printf '%s\n' "${exact_matches[0]}"
        return 0
    fi

    if [ ${#prefix_matches[@]} -eq 1 ]; then
        printf '%s\n' "${prefix_matches[0]}"
        return 0
    fi

    if [ ${#prefix_matches[@]} -gt 1 ]; then
        echo "错误: 设备序列号前缀 ${query} 匹配到多个设备: ${prefix_matches[*]}" >&2
        return 1
    fi

    return 1
}

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

parse_device_args() {
    local opt
    local resolved_serial

    OPTIND=1
    while getopts ":s:h" opt; do
        case "$opt" in
            s)
                DEVICE_SERIAL="$OPTARG"
                ;;
            h)
                print_usage
                exit 0
                ;;
            :)
                echo "错误: -$OPTARG 需要传入设备序列号"
                print_usage
                exit 1
                ;;
            \?)
                echo "错误: 不支持的参数 -$OPTARG"
                print_usage
                exit 1
                ;;
        esac
    done

    if [ -n "${DEVICE_SERIAL}" ] && resolved_serial=$(resolve_connected_device_serial "${DEVICE_SERIAL}" 2>/dev/null); then
        DEVICE_SERIAL="${resolved_serial}"
    fi
}

ensure_device_ready() {
    local device_status

    adb start-server >/dev/null
    device_status=$(adb devices | sed '1d' | awk -v serial="$1" '$1 == serial {print $2}')
    if [ -z "${device_status}" ]; then
        echo "错误: adb devices 中未找到设备序列号 $1"
        exit 1
    fi

    if [ "${device_status}" != "device" ]; then
        echo "错误: 设备 $1 当前状态为 ${device_status}，必须为 device 才能继续"
        exit 1
    fi
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

TARGET_NAME="$(basename "${REMOTE_PATH}")"
[ -n "${TARGET_NAME}" ] || TARGET_NAME="pull"
TARGET_NAME="${TARGET_NAME//[^a-zA-Z0-9._-]/_}"

TARGET_SERIAL="${DEVICE_SERIAL}"
if [ -z "${TARGET_SERIAL}" ]; then
    TARGET_SERIAL=$(adb get-serialno 2>/dev/null)
fi
[ -n "${TARGET_SERIAL}" ] || TARGET_SERIAL="unknown_device"
TARGET_SERIAL="${TARGET_SERIAL//[^a-zA-Z0-9._-]/_}"

TARGET_PREFIX="${TARGET_SERIAL}"
if [ "${TARGET_SERIAL}" = "${DEFAULT_D01_DEVICE_SERIAL}" ] || [ "${TARGET_SERIAL}" = "3165e176" ]; then
    TARGET_PREFIX="D01_${TARGET_SERIAL}"
elif [ "${TARGET_SERIAL}" = "${DEFAULT_KP31_DEVICE_SERIAL}" ] || [ "${TARGET_SERIAL}" = "c40b48ac" ]; then
    TARGET_PREFIX="KP31_${TARGET_SERIAL}"
fi

TARGET_DIR="${DOWNLOAD_ROOT}/${TARGET_PREFIX}_${TARGET_NAME}_${TIMESTAMP}"
mkdir -p "${TARGET_DIR}"

echo "执行 adb root"
adb_cmd root

echo "执行 adb remount"
adb_cmd remount

echo "拉取设备 ${REMOTE_PATH} 到 ${TARGET_DIR}"
adb_cmd pull "${REMOTE_PATH}" "${TARGET_DIR}"

echo "完成: ${REMOTE_PATH} 已拉取到 ${TARGET_DIR}"
