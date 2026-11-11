#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# Reuse shared device parsing and build checks from the script directory.
source "$SCRIPT_DIR/voice_build_common.sh"

DEFAULT_DEVICE_SERIAL="3d3fd206"
DEVICE_SERIAL="$DEFAULT_DEVICE_SERIAL"
PROJECT_DIR="/home/huangxingke/work/code/workCode/kp31/VoiceSetting"
APK_PATH="$PROJECT_DIR/app/build/outputs/apk/debug/ALVoiceSetting-debug.apk"

parse_device_args "$@"
ensure_device_ready "$DEVICE_SERIAL"
prepare_gradle_build "$PROJECT_DIR"

echo "当前台架设备: $DEVICE_SERIAL"
echo "覆盖安装不依赖 /system 可写，跳过 remount"
echo "覆盖安装语音设置最新包"
if ! adb_cmd 120 install -r -d "$APK_PATH"; then
    echo "错误: 安装语音设置测试包失败或超时"
    exit 1
fi
echo "安装完成"
