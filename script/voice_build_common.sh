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
        *)
            return 1
            ;;
    esac
}

collect_device_completion_replies() {
    local cur="$1"
    local cur_lower="${cur,,}"
    local line serial state model device_name transport_id
    local alias_serial=""
    local -a prefix_suggestions=() fuzzy_suggestions=()

    if alias_serial=$(resolve_device_completion_hint "${cur}" 2>/dev/null); then
        prefix_suggestions+=("${alias_serial}")
    elif [ "${cur_lower}" = "d" ] || [ "${cur_lower}" = "d0" ]; then
        prefix_suggestions+=("${DEFAULT_D01_DEVICE_SERIAL}")
    elif [ "${cur_lower}" = "k" ] || [ "${cur_lower}" = "kp" ] || [ "${cur_lower}" = "kp3" ]; then
        prefix_suggestions+=("${DEFAULT_KP31_DEVICE_SERIAL}")
    fi

    if [[ -n "${cur}" && "${DEFAULT_D01_DEVICE_SERIAL}" == "${cur}"* ]]; then
        prefix_suggestions+=("${DEFAULT_D01_DEVICE_SERIAL}")
    fi

    if [[ -n "${cur}" && "${DEFAULT_KP31_DEVICE_SERIAL}" == "${cur}"* ]]; then
        prefix_suggestions+=("${DEFAULT_KP31_DEVICE_SERIAL}")
    fi

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

        model=$(sed -n 's/.*model:\([^[:space:]]*\).*/\1/p' <<< "${line}")
        device_name=$(sed -n 's/.*device:\([^[:space:]]*\).*/\1/p' <<< "${line}")
        transport_id=$(sed -n 's/.*transport_id:\([^[:space:]]*\).*/\1/p' <<< "${line}")

        if [[ "${serial}" == "${cur}"* ]] || [[ -n "${model}" && "${model}" == "${cur}"* ]] || [[ -n "${device_name}" && "${device_name}" == "${cur}"* ]] || [[ -n "${transport_id}" && "${transport_id}" == "${cur}"* ]]; then
            prefix_suggestions+=("${serial}")
        elif [[ "${serial}" == *"${cur}"* ]] || [[ -n "${model}" && "${model}" == *"${cur}"* ]] || [[ -n "${device_name}" && "${device_name}" == *"${cur}"* ]] || [[ -n "${transport_id}" && "${transport_id}" == *"${cur}"* ]]; then
            fuzzy_suggestions+=("${serial}")
        fi
    done < <(adb devices -l 2>/dev/null)

    if [ ${#prefix_suggestions[@]} -gt 0 ]; then
        printf '%s\n' "${prefix_suggestions[@]}" | awk '!seen[$0]++'
    else
        printf '%s\n' "${fuzzy_suggestions[@]}" | awk '!seen[$0]++'
    fi
}

parse_device_args() {
    local opt

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
