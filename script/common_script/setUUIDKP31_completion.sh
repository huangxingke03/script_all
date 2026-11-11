#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/voice_build/voice_build_common.sh"

_set_uuid_kp31_completion() {
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

set_uuid_kp31_completion_repair() {
    local command_name
    local -a commands=(
        ./common_script/setUUIDKP31.sh
        /home/huangxingke/.local/bin/setUUIDKP31
        /home/huangxingke/.local/bin/setUuidKP31
        /home/huangxingke/.local/bin/setUUIDKp31
        /home/huangxingke/.local/bin/setUuidKp31
        /home/huangxingke/.local/bin/setuuidKP31
        /home/huangxingke/.local/bin/setuuidKp31
        /home/huangxingke/.local/bin/setuuidkp31
        /home/huangxingke/.local/bin/set_uuid_kp31
        setUUIDKP31
        setUuidKP31
        setUUIDKp31
        setUuidKp31
        setuuidKP31
        setuuidKp31
        setuuidkp31
        set_uuid_kp31
    )

    for command_name in "${commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done

    for command_name in "${commands[@]}"; do
        complete -F _set_uuid_kp31_completion "${command_name}"
    done
}

set_uuid_kp31_completion_repair
