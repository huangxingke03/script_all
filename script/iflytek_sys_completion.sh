#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/voice_build_common.sh"

_iflytek_sys_device_completion() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    compopt +o default +o bashdefault 2>/dev/null

    if [ "${prev}" = "-s" ]; then
        COMPREPLY=( $(collect_device_completion_replies "${cur}") )
        return 0
    fi

    COMPREPLY=( $(compgen -W "-s -h" -- "${cur}") )
}

iflytek_sys_completion_repair() {
    local command_name
    local -a commands=(
        ./reboots.sh
        reboots.sh
        /usr/local/bin/reboots
        reboots
        ./update_d01_Int_sys.sh
        ./update_d01_sys.sh
        ./update_d01p_int_sys.sh
        ./update_kp31_int_sys.sh
        ./update_kp31_sys.sh
        update_d01_Int_sys.sh
        update_d01_sys.sh
        update_d01p_int_sys.sh
        update_kp31_int_sys.sh
        update_kp31_sys.sh
        /usr/local/bin/updateD01IntSys
        /usr/local/bin/updated01IntSys
        /usr/local/bin/updateD01intSys
        /usr/local/bin/updated01intSys
        /usr/local/bin/updateD01Sys
        /usr/local/bin/updated01Sys
        /usr/local/bin/updateD01sys
        /usr/local/bin/updated01sys
        /usr/local/bin/updateD01pIntSys
        /usr/local/bin/updated01pIntSys
        /usr/local/bin/updateD01pintSys
        /usr/local/bin/updated01pintSys
        /usr/local/bin/updateKp31IntSys
        /usr/local/bin/updatekp31IntSys
        /usr/local/bin/updateKp31intSys
        /usr/local/bin/updatekp31intSys
        /usr/local/bin/updateKp31Sys
        /usr/local/bin/updatekp31Sys
        /usr/local/bin/updateKp31sys
        /usr/local/bin/updatekp31sys
        updateD01IntSys
        updated01IntSys
        updateD01intSys
        updated01intSys
        updateD01Sys
        updated01Sys
        updateD01sys
        updated01sys
        updateD01pIntSys
        updated01pIntSys
        updateD01pintSys
        updated01pintSys
        updateKp31IntSys
        updatekp31IntSys
        updateKp31intSys
        updatekp31intSys
        updateKp31Sys
        updatekp31Sys
        updateKp31sys
        updatekp31sys
    )

    local -a stale_commands=(
        update_d01_Int_sys
        update_d01_sys
        update_d01p_int_sys
        update_kp31_int_sys
        update_kp31_sys
        /usr/local/bin/update_d01_Int_sys
        /usr/local/bin/update_d01_sys
        /usr/local/bin/update_d01p_int_sys
        /usr/local/bin/update_kp31_int_sys
        /usr/local/bin/update_kp31_sys
    )

    for command_name in "${commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done

    for command_name in "${stale_commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done

    for command_name in "${commands[@]}"; do
        complete -o nospace -F _iflytek_sys_device_completion "${command_name}"
    done
}

iflytek_sys_completion_repair
