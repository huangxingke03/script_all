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

wait_for_device_online() {
    adb -s "$DEVICE_SERIAL" wait-for-device
}

restart_adbd_as_root() {
    adb -s "$DEVICE_SERIAL" root
    wait_for_device_online
}

system_partition_is_writable() {
    adb -s "$DEVICE_SERIAL" shell "touch $SYSTEM_RW_TEST_PATH && rm -f $SYSTEM_RW_TEST_PATH" >/dev/null 2>&1
}

remount_and_verify_system() {
    local remount_output

    remount_output=$(adb -s "$DEVICE_SERIAL" remount 2>&1 || true)
    printf "%s\n" "$remount_output"
    system_partition_is_writable
}

ensure_system_writable() {
    local verity_output

    restart_adbd_as_root
    if remount_and_verify_system; then
        return 0
    fi

    echo "检测到 /system 仍为只读，尝试关闭 verity 并自动重启设备"
    verity_output=$(adb -s "$DEVICE_SERIAL" disable-verity 2>&1 || true)
    printf "%s\n" "$verity_output"

    echo "重启设备以使 verity 设置生效"
    adb -s "$DEVICE_SERIAL" reboot
    wait_for_device_online

    restart_adbd_as_root
    if remount_and_verify_system; then
        return 0
    fi

    echo "错误: /system 仍然不可写，请确认设备为 userdebug/eng 且允许 remount"
    exit 1
}

adb_shell_root() {
    adb -s "$DEVICE_SERIAL" shell "$@"
}

push_apk_via_staging() {
    local target_dir
    target_dir=$(dirname "$TARGET_APK_PATH")

    if [ ! -f "$APK_PATH" ]; then
        echo "错误: 未找到 APK: $APK_PATH"
        exit 1
    fi

    adb_shell_root "mkdir -p $target_dir"
    adb -s "$DEVICE_SERIAL" push "$APK_PATH" "$STAGING_APK_PATH"
    adb_shell_root "cp $STAGING_APK_PATH $TARGET_APK_PATH && chmod 644 $TARGET_APK_PATH && rm -f $STAGING_APK_PATH && sync"
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
adb -s "$DEVICE_SERIAL" reboot
