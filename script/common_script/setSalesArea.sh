#!/bin/bash

set -euo pipefail

DEVICE_SERIAL=""
SALES_AREA_PROP="persist.vendor.oem.cfg.vci.b.sales.area.icc"
SALES_AREA_VALUE=""

print_usage() {
    echo "用法: $0 [-s device_serial] <sales_area_value>"
    echo "  -s device_serial      指定 adb 设备序列号。多台设备在线时必须指定"
    echo "  sales_area_value      销售区域信号值，例如 7"
    echo "  执行 adb root 后设置 ${SALES_AREA_PROP}"
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
    if [ "${device_count}" -eq 0 ]; then
        echo "错误: 未检测到在线 adb 设备"
        exit 1
    fi
    if [ "${device_count}" -gt 1 ]; then
        echo "错误: 检测到多个在线设备，请使用 -s 指定设备序列号"
        exit 1
    fi
}

while getopts ":s:h" opt; do
    case "${opt}" in
        s)
            DEVICE_SERIAL="${OPTARG}"
            ;;
        h)
            print_usage
            exit 0
            ;;
        :)
            echo "错误: -${OPTARG} 需要传入参数"
            print_usage
            exit 1
            ;;
        \?)
            echo "错误: 不支持的参数 -${OPTARG}"
            print_usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if [ "$#" -ne 1 ]; then
    echo "错误: 需要传入一个销售区域信号值"
    print_usage
    exit 1
fi

SALES_AREA_VALUE="$1"
if ! [[ "${SALES_AREA_VALUE}" =~ ^[0-9]+$ ]]; then
    echo "错误: 销售区域信号值必须是十进制数字: ${SALES_AREA_VALUE}"
    exit 1
fi

ensure_device_ready

echo "设置销售区域: ${SALES_AREA_PROP}=${SALES_AREA_VALUE}"
if [ -n "${DEVICE_SERIAL}" ]; then
    echo "当前设备: ${DEVICE_SERIAL}"
fi

echo "[1/3] adb root"
adb_cmd root
echo "[2/3] adb wait-for-device"
adb_cmd wait-for-device
echo "[3/3] setprop ${SALES_AREA_PROP} ${SALES_AREA_VALUE}"
adb_cmd shell setprop "${SALES_AREA_PROP}" "${SALES_AREA_VALUE}"

current_value=$(adb_cmd shell getprop "${SALES_AREA_PROP}" | tr -d '\r')
echo "当前 ${SALES_AREA_PROP}=${current_value}"
