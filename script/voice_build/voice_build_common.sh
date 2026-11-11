#!/bin/bash

DEFAULT_D01_DEVICE_SERIAL="f6e277ff"
DEFAULT_KP31_DEVICE_SERIAL="3d3fd206"

resolve_device_completion_hint() {
    local value="${1,,}"

    case "${value}" in
        d01)
            printf '%s\n' "${DEFAULT_D01_DEVICE_SERIAL}"
            ;;
        kp31)
            printf '%s\n' "${DEFAULT_KP31_DEVICE_SERIAL}"
            ;;
        gen4)
            printf '%s\n' "63e9fbdd"
            ;;
        gen4_arm64|gen4arm64)
            printf '%s\n' "3165e176"
            ;;
        *)
            return 1
            ;;
    esac
}

resolve_connected_device_serial() {
    local query="$1"
    local line serial state
    local -a exact_matches=() prefix_matches=()

    while IFS= read -r line; do
        [ -z "${line}" ] && continue
        case "${line}" in
            List\ of\ devices* )
                continue
                ;;
        esac

        serial=$(awk '{print $1}' <<< "${line}")
        state=$(awk '{print $2}' <<< "${line}")
        [ "${state}" != "device" ] && continue

        if [ "${serial}" = "${query}" ]; then
            exact_matches+=("${serial}")
        elif [[ "${serial}" == "${query}"* ]]; then
            prefix_matches+=("${serial}")
        fi
    done < <(adb devices -l 2>/dev/null)

    if [ ${#exact_matches[@]} -eq 1 ]; then
        printf '%s\n' "${exact_matches[0]}"
        return 0
    fi

    if [ ${#prefix_matches[@]} -eq 1 ]; then
        printf '%s\n' "${prefix_matches[0]}"
        return 0
    fi

    if [ ${#prefix_matches[@]} -gt 1 ]; then
        echo "错误: 设备序列号前缀 ${query} 匹配到多个设备: ${prefix_matches[*]}" >&2
        return 1
    fi

    return 1
}

collect_device_completion_replies() {
    local cur="$1"
    local cur_lower="${cur,,}"
    local line serial state model device_name transport_id connected_serials
    local alias_serial
    local -a prefix_suggestions=() fuzzy_suggestions=()

    # First pass: collect connected device serials from adb.
    while IFS= read -r line; do
        [ -z "${line}" ] && continue
        case "${line}" in
            List\ of\ devices* )
                continue
                ;;
        esac

        serial=$(awk '{print $1}' <<< "${line}")
        state=$(awk '{print $2}' <<< "${line}")
        [ "${state}" != "device" ] && continue
        connected_serials+=" ${serial} "

        model=$(sed -n 's/.*model:\([^[:space:]]*\).*/\1/p' <<< "${line}")
        device_name=$(sed -n 's/.*device:\([^[:space:]]*\).*/\1/p' <<< "${line}")
        transport_id=$(sed -n 's/.*transport_id:\([^[:space:]]*\).*/\1/p' <<< "${line}")

        if [[ "${serial}" == "${cur}"* ]] || [[ -n "${model}" && "${model}" == "${cur}"* ]] || [[ -n "${device_name}" && "${device_name}" == "${cur}"* ]] || [[ -n "${transport_id}" && "${transport_id}" == "${cur}"* ]]; then
            prefix_suggestions+=("${serial}")
        elif [[ "${serial}" == *"${cur}"* ]] || [[ -n "${model}" && "${model}" == *"${cur}"* ]] || [[ -n "${device_name}" && "${device_name}" == *"${cur}"* ]] || [[ -n "${transport_id}" && "${transport_id}" == *"${cur}"* ]]; then
            fuzzy_suggestions+=("${serial}")
        fi
    done < <(adb devices -l 2>/dev/null)

    # Second pass: add default/alias serials only when the device is actually connected.
    if alias_serial=$(resolve_device_completion_hint "${cur}" 2>/dev/null); then
        if [[ "${connected_serials}" == *" ${alias_serial} "* ]]; then
            prefix_suggestions+=("${alias_serial}")
        fi
    elif [ "${cur_lower}" = "d" ] || [ "${cur_lower}" = "d0" ]; then
        if [[ "${connected_serials}" == *" ${DEFAULT_D01_DEVICE_SERIAL} "* ]]; then
            prefix_suggestions+=("${DEFAULT_D01_DEVICE_SERIAL}")
        fi
    elif [ "${cur_lower}" = "k" ] || [ "${cur_lower}" = "kp" ] || [ "${cur_lower}" = "kp3" ]; then
        if [[ "${connected_serials}" == *" ${DEFAULT_KP31_DEVICE_SERIAL} "* ]]; then
            prefix_suggestions+=("${DEFAULT_KP31_DEVICE_SERIAL}")
        fi
    fi

    if [ ${#prefix_suggestions[@]} -gt 0 ]; then
        printf '%s\n' "${prefix_suggestions[@]}" | awk '!seen[$0]++'
    elif [ ${#fuzzy_suggestions[@]} -gt 0 ]; then
        printf '%s\n' "${fuzzy_suggestions[@]}" | awk '!seen[$0]++'
    else
        printf '%s\n' ${connected_serials} | awk 'NF && !seen[$0]++'
    fi
}

parse_device_args() {
    local opt
    local resolved_serial

    while getopts ":s:h" opt; do
        case "$opt" in
            s)
                DEVICE_SERIAL="$OPTARG"
                ;;
            h)
                print_device_usage
                exit 0
                ;;
            :)
                echo "错误: -$OPTARG 需要传入设备序列号"
                print_device_usage
                exit 1
                ;;
            \?)
                echo "错误: 不支持的参数 -$OPTARG"
                print_device_usage
                exit 1
                ;;
        esac
    done

    if [ -n "${DEVICE_SERIAL}" ] && resolved_serial=$(resolve_connected_device_serial "${DEVICE_SERIAL}" 2>/dev/null); then
        DEVICE_SERIAL="${resolved_serial}"
    fi
}

print_device_usage() {
    echo "用法: $0 [-s device_serial]"
    echo "  -s device_serial  指定台架设备序列号，默认: $DEFAULT_DEVICE_SERIAL"
}

ensure_device_ready() {
    local device_status

    adb start-server >/dev/null
    device_status=$(adb devices | sed '1d' | awk -v serial="$1" '$1 == serial {print $2}')
    if [ -z "$device_status" ]; then
        echo "错误: adb devices 中未找到设备序列号 $1"
        exit 1
    fi

    if [ "$device_status" != "device" ]; then
        echo "错误: 设备 $1 当前状态为 $device_status，必须为 device 才能继续"
        exit 1
    fi
}

get_device_display_name() {
    local serial="$1"
    local device_line
    local model_name
    local device_name

    device_line=$(adb devices -l | awk -v serial="$serial" '$1 == serial {print; exit}')
    model_name=$(printf '%s\n' "$device_line" | sed -n 's/.*model:\([^[:space:]]*\).*/\1/p')
    device_name=$(printf '%s\n' "$device_line" | sed -n 's/.*device:\([^[:space:]]*\).*/\1/p')

    if [ -n "$model_name" ] && [ -n "$device_name" ]; then
        echo "$model_name ($device_name)"
    elif [ -n "$model_name" ]; then
        echo "$model_name"
    elif [ -n "$device_name" ]; then
        echo "$device_name"
    else
        echo "未知设备名"
    fi
}

prepare_gradle_build() {
    local project_dir="$1"

    cd "$project_dir"
    echo "切换项目根目录,开始打测试包"
    chmod +x gradlew
    ./gradlew assembleD
    echo "语音测试包打包完成"
}

ADB_CMD_TIMEOUT="${ADB_CMD_TIMEOUT:-20}"
ADB_WAIT_TIMEOUT="${ADB_WAIT_TIMEOUT:-90}"
ADB_REBOOT_WAIT_TIMEOUT="${ADB_REBOOT_WAIT_TIMEOUT:-180}"

adb_cmd() {
    local timeout_seconds="${1:-$ADB_CMD_TIMEOUT}"
    shift
    timeout "$timeout_seconds" adb -s "$DEVICE_SERIAL" "$@"
}

wait_for_device_online() {
    local timeout_seconds="${1:-$ADB_WAIT_TIMEOUT}"

    echo "等待设备重新上线: $DEVICE_SERIAL"
    if ! adb_cmd "$timeout_seconds" wait-for-device; then
        echo "错误: 等待设备上线超时 (${timeout_seconds} 秒): $DEVICE_SERIAL"
        exit 1
    fi
}

adbd_is_root() {
    local uid

    uid=$(adb_cmd "$ADB_CMD_TIMEOUT" shell id -u 2>/dev/null | tr -d '\r') || return 1
    [ "$uid" = "0" ]
}

restart_adbd_as_root() {
    if adbd_is_root; then
        echo "adbd 已是 root，跳过 adb root"
        return 0
    fi

    echo "正在执行 adb root"
    if ! adb_cmd "$ADB_CMD_TIMEOUT" root; then
        echo "错误: adb root 超时或失败，请检查 USB/adb 连接后重试"
        exit 1
    fi
    wait_for_device_online
}

system_partition_is_writable() {
    adb_cmd "$ADB_CMD_TIMEOUT" shell "touch $SYSTEM_RW_TEST_PATH && rm -f $SYSTEM_RW_TEST_PATH" >/dev/null 2>&1
}

device_blocks_system_remount() {
    local props state flash_locked vbmeta

    props=$(adb_cmd "$ADB_CMD_TIMEOUT" shell 'printf "%s\n" "$(getprop ro.boot.verifiedbootstate)" "$(getprop ro.boot.flash.locked)" "$(getprop ro.boot.vbmeta.device_state)"' 2>/dev/null | tr -d '\r') || return 1
    state=$(printf '%s\n' "$props" | sed -n '1p')
    flash_locked=$(printf '%s\n' "$props" | sed -n '2p')
    vbmeta=$(printf '%s\n' "$props" | sed -n '3p')
    [ "$state" = "green" ] || [ "$flash_locked" = "1" ] || [ "$vbmeta" = "locked" ]
}

remount_and_verify_system() {
    local remount_output

    echo "正在 remount /system"
    remount_output=$(adb_cmd "$ADB_CMD_TIMEOUT" remount 2>&1 || true)
    printf "%s\n" "$remount_output"
    if system_partition_is_writable; then
        return 0
    fi

    echo "adb remount 未放开 /system，尝试 remount /"
    adb_shell_root "mount -o rw,remount / || mount -o rw,remount /system" >/dev/null 2>&1 || true
    system_partition_is_writable
}

ensure_system_writable() {
    local verity_output

    if [ -z "${SYSTEM_RW_TEST_PATH:-}" ]; then
        echo "错误: 未设置 SYSTEM_RW_TEST_PATH"
        exit 1
    fi

    if system_partition_is_writable; then
        echo "/system 已可写，跳过 remount"
        return 0
    fi

    restart_adbd_as_root
    if system_partition_is_writable || remount_and_verify_system; then
        return 0
    fi

    if device_blocks_system_remount; then
        echo "错误: 设备 bootloader 已锁定，/system 无法 remount，已跳过 disable-verity 和重启"
        echo "当前为锁定的 user 版本，请换 userdebug/eng 或已解锁设备后再推系统分区"
        exit 1
    fi

    echo "检测到 /system 仍为只读，尝试关闭 verity 并自动重启设备"
    verity_output=$(adb_cmd "$ADB_CMD_TIMEOUT" disable-verity 2>&1 || true)
    printf "%s\n" "$verity_output"
    if printf '%s\n' "$verity_output" | grep -q "Device is locked"; then
        echo "错误: disable-verity 返回设备已锁定，不再重启"
        exit 1
    fi

    echo "重启设备以使 verity 设置生效"
    adb_cmd "$ADB_CMD_TIMEOUT" reboot || true
    wait_for_device_online "$ADB_REBOOT_WAIT_TIMEOUT"

    restart_adbd_as_root
    if system_partition_is_writable || remount_and_verify_system; then
        return 0
    fi

    echo "错误: /system 仍然不可写，请确认设备为 userdebug/eng 且允许 remount"
    exit 1
}

adb_shell_root() {
    adb_cmd "$ADB_CMD_TIMEOUT" shell "$@"
}
