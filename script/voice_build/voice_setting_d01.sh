#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# Reuse shared device parsing and build checks from the script directory.
source "$SCRIPT_DIR/voice_build_common.sh"

DEFAULT_DEVICE_SERIAL="f6e277ff"
DEVICE_SERIAL="$DEFAULT_DEVICE_SERIAL"
PROJECT_DIR="/home/huangxingke/work/code/workCode/d01/VoiceSetting"
APK_PATH="$PROJECT_DIR/app/build/outputs/apk/debug/ALVoiceSetting-debug.apk"

parse_device_args "$@"
ensure_device_ready "$DEVICE_SERIAL"
prepare_gradle_build "$PROJECT_DIR"

echo "当前台架设备: $DEVICE_SERIAL"
adb -s "$DEVICE_SERIAL" root
adb -s "$DEVICE_SERIAL" remount
echo "覆盖安装语音设置最新包"
adb -s "$DEVICE_SERIAL" install -r -d "$APK_PATH"
echo "安装完成"
