#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# Reuse shared device parsing and build checks from the script directory.
source "$SCRIPT_DIR/voice_build_common.sh"

DEFAULT_DEVICE_SERIAL="f6e277ff"
DEVICE_SERIAL="$DEFAULT_DEVICE_SERIAL"
PROJECT_DIR="/home/huangxingke/work/code/workCode/d01/VoiceAssistant"
APK_PATH="$PROJECT_DIR/app/build/outputs/apk/debug/ALVoiceAssistant-debug.apk"
TARGET_APK_PATH="/system/app/ALVoiceAssistant/ALVoiceAssistant.apk"

parse_device_args "$@"
ensure_device_ready "$DEVICE_SERIAL"
prepare_gradle_build "$PROJECT_DIR"

echo "当前台架设备: $DEVICE_SERIAL"
adb -s "$DEVICE_SERIAL" root
adb -s "$DEVICE_SERIAL" remount
adb -s "$DEVICE_SERIAL" push "$APK_PATH" "$TARGET_APK_PATH"
echo "推送语音最新测试包到台架成功"
sleep 1
echo "开始重启台架"
adb -s "$DEVICE_SERIAL" reboot
