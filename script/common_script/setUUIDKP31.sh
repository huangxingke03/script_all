#!/bin/bash

set -euo pipefail

DEVICE_SERIAL=""
TARGET_UUID="WP00KP31N50200000180A7PV00000019"

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

ensure_device_ready

echo "开始设置 UUID: ${TARGET_UUID}"
echo "[1/7] adb root"
adb_cmd root
echo "[2/7] adb wait-for-device"
adb_cmd wait-for-device
echo "[3/7] adb remount"
adb_cmd remount
echo "[4/7] setprop persist.vendor.autolink.support_custom_code 1"
adb_cmd shell setprop persist.vendor.autolink.support_custom_code 1
echo "[5/7] setprop ro.vendor.autolink.car.uuid ${TARGET_UUID}"
adb_cmd shell setprop ro.vendor.autolink.car.uuid "${TARGET_UUID}"
echo "[6/7] adb shell sync && stop && start"
adb_cmd shell sync
adb_cmd shell stop
adb_cmd shell start
echo "[7/7] 等待设备恢复并查询 UUID"
adb_cmd wait-for-device
sleep 5

echo "当前 UUID 相关属性:"
adb_cmd shell getprop | grep uuid
