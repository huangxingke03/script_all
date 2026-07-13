#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../voice_build_common.sh"

DEFAULT_DEVICE_SERIAL="$DEFAULT_KP31_DEVICE_SERIAL"
DEVICE_SERIAL="$DEFAULT_DEVICE_SERIAL"
CLEAR_CACHE=0
PACKAGE_NAME="com.iflytek.cutefly.speechclient.hmi"
TARGET_COMPONENT="com.iflytek.cutefly.speechclient.hmi/.SettingActivity"

print_usage() {
    echo "用法: $0 [-s device_serial] [-c|-C|--clear-cache|--CLEAR-CACHE]"
    echo "  -s device_serial                指定台架设备序列号，默认: $DEFAULT_DEVICE_SERIAL"
    echo "  -c, -C, --clear-cache          启动前清除讯飞应用缓存"
    echo "  -h, --help, --HELP             显示帮助"
    echo "  默认行为: 只重启并启动设置页，不清缓存"
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -s)
                if [ -z "${2:-}" ]; then
                    echo "错误: -s 需要传入设备序列号"
                    print_usage
                    exit 1
                fi
                DEVICE_SERIAL="$2"
                shift 2
                ;;
            -[cC]|--[cC][lL][eE][aA][rR]-[cC][aA][cC][hH][eE])
                CLEAR_CACHE=1
                shift
                ;;
            -h|--help|--HELP)
                print_usage
                exit 0
                ;;
            *)
                echo "错误: 不支持的参数 $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

parse_args "$@"
ensure_device_ready "$DEVICE_SERIAL"

echo "当前台架设备: $DEVICE_SERIAL"
if [ "$CLEAR_CACHE" -eq 1 ]; then
    echo "清除讯飞应用缓存: $PACKAGE_NAME"
    adb -s "$DEVICE_SERIAL" shell pm clear "$PACKAGE_NAME"
else
    echo "默认模式: 不清缓存，只重启讯飞应用"
fi

adb -s "$DEVICE_SERIAL" shell am force-stop "$PACKAGE_NAME"
adb -s "$DEVICE_SERIAL" shell am start -n "$TARGET_COMPONENT"
