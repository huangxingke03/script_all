#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/voice_build/voice_build_common.sh"

_sound_bt_click_completion() {
    local cur prev device_query reply
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    device_query="${cur}"

    compopt +o default +o bashdefault +o dirnames +o filenames 2>/dev/null

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

sound_bt_click_completion_repair() {
    local command_name
    local -a commands=(
        ./common_script/sound_bt_click.sh
        /home/huangxingke/.local/bin/soundBtClick
        /home/huangxingke/.local/bin/soundbtClick
        /home/huangxingke/.local/bin/soundBtclick
        /home/huangxingke/.local/bin/soundbtclick
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
        complete -o nospace -F _sound_bt_click_completion "${command_name}"
    done
}

sound_bt_click_completion_repair
