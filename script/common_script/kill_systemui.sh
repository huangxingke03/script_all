#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
COMMON_SH="$SCRIPT_DIR/voice_build_common.sh"
if [ ! -f "$COMMON_SH" ]; then
    echo "错误: 未找到 $COMMON_SH" >&2
    exit 1
fi
source "$COMMON_SH"

DEFAULT_DEVICE_SERIAL="f6e277ff"
DEVICE_SERIAL="$DEFAULT_DEVICE_SERIAL"

SYSTEMUI_PACKAGE="com.android.systemui"

print_device_usage() {
    echo "用法: $0 [-s device_serial]"
    echo "  -s device_serial  指定台架设备序列号，默认: $DEFAULT_DEVICE_SERIAL"
}

ensure_package_installed() {
    local package_name="$1"

    if ! adb -s "$DEVICE_SERIAL" shell pm list packages "$package_name" | grep -qx "package:$package_name"; then
        echo "错误: 设备 $DEVICE_SERIAL 上未安装 $package_name"
        exit 1
    fi
}

has_root_su() {
    adb -s "$DEVICE_SERIAL" shell su 0 id >/dev/null 2>&1
}

run_kill_cmd() {
    local package_name="$1"
    local tool_name="$2"
    local shell_cmd="$3"
    local root_cmd="$4"

    if adb -s "$DEVICE_SERIAL" shell "$shell_cmd"; then
        echo "已通过 $tool_name 杀掉 $package_name"
        return 0
    fi

    if has_root_su; then
        echo "$tool_name 失败，尝试 su 0 $tool_name"
        if adb -s "$DEVICE_SERIAL" shell su 0 "$root_cmd"; then
            echo "已通过 su 0 $tool_name 杀掉 $package_name"
            return 0
        fi
    fi

    return 1
}

kill_package() {
    local package_name="$1"

    ensure_package_installed "$package_name"
    echo "杀进程: $package_name"

    if run_kill_cmd "$package_name" "pkill -f" "pkill -f $package_name" "pkill -f $package_name"; then
        return 0
    fi

    echo "pkill -f 失败，回退到 killall $package_name"
    if run_kill_cmd "$package_name" "killall" "killall $package_name" "killall $package_name"; then
        return 0
    fi

    echo "错误: 无法杀掉 $package_name"
    echo "提示: 普通 adb shell 对 systemui 通常没有权限，设备需要支持 su 0/root 才能成功"
    exit 1
}

parse_device_args "$@"
shift $((OPTIND - 1))

if [ "$#" -gt 0 ]; then
    echo "错误: 不支持的位置参数: $*"
    print_device_usage
    exit 1
fi

ensure_device_ready "$DEVICE_SERIAL"
DEVICE_NAME=$(get_device_display_name "$DEVICE_SERIAL")

echo "当前台架设备: $DEVICE_SERIAL ($DEVICE_NAME)"
kill_package "$SYSTEMUI_PACKAGE"
echo "完成: $SYSTEMUI_PACKAGE"
