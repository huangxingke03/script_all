#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/voice_build/voice_build_common.sh"

_start_boot_guide_completion() {
    local cur prev cur_lc prev_lc device_query reply opt
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cur_lc="${cur,,}"
    prev_lc="${prev,,}"
    device_query="${cur}"

    compopt +o default +o bashdefault +o dirnames +o filenames 2>/dev/null


    # 已输入完整 -s 但尚未空格时，先补出 -s（由 bash 加空格），下一次 Tab 再列设备
    if [ "${cur_lc}" = "-s" ] && [ "${prev_lc}" != "-s" ]; then
        COMPREPLY=("-s")
        return 0
    fi

    if [ "${prev_lc}" = "-s" ]; then
        [[ "${device_query}" == */* ]] && device_query=""
        COMPREPLY=()
        while IFS= read -r reply; do
            [ -n "${reply}" ] && COMPREPLY+=("${reply}")
        done < <(collect_device_completion_replies "${device_query}")
        return 0
    fi

    COMPREPLY=()
    for opt in -s -h; do
        if [[ "${opt}" == "${cur_lc}"* ]]; then
            COMPREPLY+=("${opt}")
        fi
    done
}

start_boot_guide_completion_repair() {
    local command_name
    local -a commands=(
        ./common_script/startBootGuideKP31.sh
        /home/huangxingke/.local/bin/startBootGuideKP31
        /home/huangxingke/.local/bin/startBootGuideKp31
        /home/huangxingke/.local/bin/startbootGuideKP31
        /home/huangxingke/.local/bin/startbootguidekp31
        /home/huangxingke/.local/bin/start_boot_guide_kp31
        startBootGuideKP31
        startBootGuideKp31
        startbootGuideKP31
        startbootguidekp31
        start_boot_guide_kp31
    )

    for command_name in "${commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done

    for command_name in "${commands[@]}"; do
        complete -F _start_boot_guide_completion "${command_name}"
    done
}

start_boot_guide_completion_repair
