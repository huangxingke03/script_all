#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# Reuse shared device parsing and build checks from the script directory.
source "$SCRIPT_DIR/voice_build_common.sh"

DEFAULT_DEVICE_SERIAL="3d3fd206"
DEVICE_SERIAL="$DEFAULT_DEVICE_SERIAL"
PROJECT_DIR="/home/huangxingke/work/code/workCode/kp31/VoiceSetting"
APK_PATH="$PROJECT_DIR/app/build/outputs/apk/debug/ALVoiceSetting-debug.apk"
SYSTEM_RW_TEST_PATH="/system/.voice_setting_rw_test"

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

parse_device_args "$@"
ensure_device_ready "$DEVICE_SERIAL"
prepare_gradle_build "$PROJECT_DIR"

echo "当前台架设备: $DEVICE_SERIAL"
ensure_system_writable
echo "覆盖安装语音设置最新包"
adb -s "$DEVICE_SERIAL" install -r -d "$APK_PATH"
echo "安装完成"
