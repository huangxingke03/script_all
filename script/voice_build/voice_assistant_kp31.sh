#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# Reuse shared device parsing and build checks from the script directory.
source "$SCRIPT_DIR/voice_build_common.sh"

DEFAULT_DEVICE_SERIAL="3d3fd206"
DEVICE_SERIAL="$DEFAULT_DEVICE_SERIAL"
PROJECT_DIR="/home/huangxingke/work/code/workCode/kp31/VoiceAssistant"
APK_PATH="$PROJECT_DIR/app/build/outputs/apk/debug/ALVoiceAssistant-debug.apk"
TARGET_APK_PATH="/system/app/ALVoiceAssistant/ALVoiceAssistant.apk"
SYSTEM_RW_TEST_PATH="/system/.voice_assistant_rw_test"
STAGING_APK_PATH="/data/local/tmp/ALVoiceAssistant-debug.apk"

push_apk_via_staging() {
    local target_dir
    target_dir=$(dirname "$TARGET_APK_PATH")

    if [ ! -f "$APK_PATH" ]; then
        echo "错误: 未找到 APK: $APK_PATH"
        exit 1
    fi

    adb_shell_root "mkdir -p $target_dir"
    adb_cmd 60 push "$APK_PATH" "$STAGING_APK_PATH"
    adb_shell_root "cp $STAGING_APK_PATH $TARGET_APK_PATH && chmod 644 $TARGET_APK_PATH && rm -f $STAGING_APK_PATH"
}

deploy_apk_with_retry() {
    local attempt

    for attempt in 1 2; do
        if push_apk_via_staging; then
            return 0
        fi

        if [ "$attempt" -lt 2 ]; then
            echo "检测到推包失败，重新建立 adb root/remount 后重试一次"
            wait_for_device_online
            ensure_system_writable
            sleep 1
        fi
    done

    echo "错误: 推送语音测试包失败"
    exit 1
}

parse_device_args "$@"
ensure_device_ready "$DEVICE_SERIAL"
prepare_gradle_build "$PROJECT_DIR"

echo "当前台架设备: $DEVICE_SERIAL"
ensure_system_writable
deploy_apk_with_retry
echo "推送语音最新测试包到台架成功"
sleep 1
echo "开始重启台架"
adb_cmd "$ADB_CMD_TIMEOUT" reboot
