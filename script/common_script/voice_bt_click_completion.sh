#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/voice_build/voice_build_common.sh"

_voice_bt_click_completion() {
    local cur prev device_query reply
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    device_query="${cur}"

    compopt +o default +o bashdefault +o dirnames +o filenames 2>/dev/null


    # 已输入完整 -s 但尚未空格时，先补出 -s（由 bash 加空格），下一次 Tab 再列设备
    if [ "${cur,,}" = "-s" ] && [ "${prev,,}" != "-s" ]; then
        COMPREPLY=("-s")
        return 0
    fi

    if [ "${prev}" = "-s" ]; then
        [[ "${device_query}" == */* ]] && device_query=""
        COMPREPLY=()
        while IFS= read -r reply; do
            [ -n "${reply}" ] && COMPREPLY+=("${reply}")
        done < <(collect_device_completion_replies "${device_query}")
        return 0
    fi

    COMPREPLY=( $(compgen -W "-s -h" -- "${cur}") )
}

voice_bt_click_completion_repair() {
    local command_name
    local -a commands=(
        ./common_script/voice_bt_click.sh
        /home/huangxingke/.local/bin/voiceBtClick
        /home/huangxingke/.local/bin/voicebtClick
        /home/huangxingke/.local/bin/voiceBtclick
        /home/huangxingke/.local/bin/voicebtclick
        /home/huangxingke/.local/bin/voice_bt_click
        /home/huangxingke/.local/bin/soundBtClick
        /home/huangxingke/.local/bin/soundbtClick
        /home/huangxingke/.local/bin/soundBtclick
        /home/huangxingke/.local/bin/soundbtclick
        voiceBtClick
        voicebtClick
        voiceBtclick
        voicebtclick
        voice_bt_click
        soundBtClick
        soundbtClick
        soundBtclick
        soundbtclick
    )

    local -a stale_commands=(
        ./sound_bt_click.sh
        sound_bt_click.sh
        sound_bt_click
    )

    for command_name in "${commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done
    for command_name in "${stale_commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done
    for command_name in "${commands[@]}"; do
        complete -F _voice_bt_click_completion "${command_name}"
    done
}

voice_bt_click_completion_repair
