#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/voice_build/voice_build_common.sh"

_clear_logcat_by_adb_completion() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    compopt +o default +o bashdefault 2>/dev/null

    if [ "${prev}" = "-s" ]; then
        COMPREPLY=( $(collect_device_completion_replies "${cur}") )
        return 0
    fi

    COMPREPLY=( $(compgen -W "-s -h /log /data/log" -- "${cur}") )
}

clear_logcat_by_adb_completion_repair() {
    local command_name
    local -a commands=(
        ./clear_logcat_by_adb.sh
        ~/.local/bin/clearLogcatByAdb
        ~/.local/bin/clearlogcatByAdb
        ~/.local/bin/clearLogcatbyAdb
        ~/.local/bin/clearlogcatbyAdb
        clearLogcatByAdb
        clearlogcatByAdb
        clearLogcatbyAdb
        clearlogcatbyAdb
    )

    local -a stale_commands=(
        clear_logcat_by_adb.sh
        clear_logcat_by_adb
        /usr/local/bin/clearLogcatByAdb
        /usr/local/bin/clearlogcatByAdb
        /usr/local/bin/clearLogcatbyAdb
        /usr/local/bin/clearlogcatbyAdb
        /usr/local/bin/clear_logcat_by_adb
    )

    for command_name in "${commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done

    for command_name in "${stale_commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done

    for command_name in "${commands[@]}"; do
        complete -o nospace -F _clear_logcat_by_adb_completion "${command_name}"
    done
}

clear_logcat_by_adb_completion_repair
