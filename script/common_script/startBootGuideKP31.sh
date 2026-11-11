#!/bin/bash

set -euo pipefail

DEVICE_SERIAL=""
PROVISION_PKG="com.autolink.app.provision"
DEFAULT_ACTIVITY="${PROVISION_PKG}/${PROVISION_PKG}.DefaultActivity"
AGREEMENTS_ACTIVITY="${PROVISION_PKG}/${PROVISION_PKG}.AgreementsPoliciesActivity"
AUTHORIZE_ACTIVITY="${PROVISION_PKG}/${PROVISION_PKG}.AuthorizeSetActivity"

print_usage() {
    echo "用法: $0 [-s device_serial]"
    echo "  -s device_serial  指定 adb 设备序列号"
    echo "  拉起 KP31 开机引导：重置首次开机标记、启用引导页面并启动 DefaultActivity"
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

ensure_device_ready

echo "开始拉起 KP31 开机引导"
if [ -n "${DEVICE_SERIAL}" ]; then
    echo "当前设备: ${DEVICE_SERIAL}"
fi

echo "[1/8] adb root"
adb_cmd root

echo "[2/8] adb wait-for-device（root 后等待 adbd 恢复）"
adb_cmd wait-for-device

echo "[3/8] settings put global first_begin_boot 0"
adb_cmd shell settings put global first_begin_boot 0

echo "[4/8] settings put secure user_setup_complete 0"
adb_cmd shell settings put secure user_setup_complete 0

echo "[5/8] pm enable DefaultActivity"
adb_cmd shell pm enable "${DEFAULT_ACTIVITY}"

echo "[6/8] pm enable AgreementsPoliciesActivity"
adb_cmd shell pm enable "${AGREEMENTS_ACTIVITY}"

echo "[7/8] pm enable AuthorizeSetActivity"
adb_cmd shell pm enable "${AUTHORIZE_ACTIVITY}"

echo "[8/8] am start DefaultActivity"
adb_cmd shell am start -n "${DEFAULT_ACTIVITY}"

echo "KP31 开机引导已启动: ${DEFAULT_ACTIVITY}"
