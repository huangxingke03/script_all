#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/voice_build/voice_build_common.sh"

_random_log_completion() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    compopt +o default +o bashdefault 2>/dev/null


    # 已输入完整 -s 但尚未空格时，先补出 -s（由 bash 加空格），下一次 Tab 再列设备
    if [ "${cur,,}" = "-s" ] && [ "${prev,,}" != "-s" ]; then
        COMPREPLY=("-s")
        return 0
    fi

    if [ "${prev}" = "-s" ]; then
        COMPREPLY=( $(collect_device_completion_replies "${cur}") )
        return 0
    fi

    COMPREPLY=( $(compgen -W "-s -h start stop" -- "${cur}") )
}

random_log_completion_repair() {
    local command_name
    local -a commands=(
        ./start_random_log.sh
        ./stop_random_log.sh
        ~/.local/bin/startRandomLog
        ~/.local/bin/startrandomLog
        ~/.local/bin/startRandomlog
        ~/.local/bin/startrandomlog
        ~/.local/bin/stopRandomLog
        ~/.local/bin/stoprandomLog
        ~/.local/bin/stopRandomlog
        ~/.local/bin/stoprandomlog
        startRandomLog
        startrandomLog
        startRandomlog
        startrandomlog
        stopRandomLog
        stoprandomLog
        stopRandomlog
        stoprandomlog
    )

    local -a stale_commands=(
        start_random_log
        stop_random_log
        /usr/local/bin/startRandomLog
        /usr/local/bin/startrandomLog
        /usr/local/bin/startRandomlog
        /usr/local/bin/startrandomlog
        /usr/local/bin/stopRandomLog
        /usr/local/bin/stoprandomLog
        /usr/local/bin/stopRandomlog
        /usr/local/bin/stoprandomlog
        /usr/local/bin/start_random_log
        /usr/local/bin/stop_random_log
    )

    for command_name in "${commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done

    for command_name in "${stale_commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done

    for command_name in "${commands[@]}"; do
        complete -F _random_log_completion "${command_name}"
    done
}

random_log_completion_repair
