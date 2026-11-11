#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../voice_build/voice_build_common.sh"

_scrcpy_resolve_device_alias() {
    local value="${1,,}"

    case "${value}" in
        d01)
            printf '%s\n' "${DEFAULT_D01_DEVICE_SERIAL}"
            ;;
        kp31)
            printf '%s\n' "${DEFAULT_KP31_DEVICE_SERIAL}"
            ;;
        *)
            printf '%s\n' "$1"
            ;;
    esac
}

_scrcpy_is_default_bench_device() {
    case "$1" in
        "${DEFAULT_D01_DEVICE_SERIAL}"|"${DEFAULT_KP31_DEVICE_SERIAL}"|"63e9fbdd"|"3165e176")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

_scrcpy_has_explicit_audio_option() {
    local arg

    for arg in "$@"; do
        case "${arg}" in
            --no-audio|--audio-codec=*|--audio-encoder=*|--audio-source=*|--require-audio|--no-playback)
                return 0
                ;;
        esac
    done

    return 1
}

scrcpy() {
    local -a args=()
    local arg resolved_serial="" next_is_serial=0

    for arg in "$@"; do
        if [ "${next_is_serial}" -eq 1 ]; then
            resolved_serial="$(_scrcpy_resolve_device_alias "${arg}")"
            args+=("${resolved_serial}")
            next_is_serial=0
            continue
        fi

        case "${arg}" in
            -s|--serial)
                args+=("${arg}")
                next_is_serial=1
                ;;
            --serial=*)
                resolved_serial="$(_scrcpy_resolve_device_alias "${arg#--serial=}")"
                args+=("--serial=${resolved_serial}")
                ;;
            *)
                args+=("${arg}")
                ;;
        esac
    done

    if [ -n "${resolved_serial}" ] && _scrcpy_is_default_bench_device "${resolved_serial}" && ! _scrcpy_has_explicit_audio_option "${args[@]}"; then
        args+=("--audio-codec=aac")
        args+=("--audio-encoder=c2.android.aac.encoder")
    fi

    command scrcpy "${args[@]}"
}

_scrcpy_device_completion() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    compopt +o default +o bashdefault 2>/dev/null


    # 已输入完整 -s 但尚未空格时，先补出 -s（由 bash 加空格），下一次 Tab 再列设备
    if [ "${cur,,}" = "-s" ] && [ "${prev,,}" != "-s" ]; then
        COMPREPLY=("-s")
        return 0
    fi

    if [ "${cur,,}" = "--serial" ] && [ "${prev,,}" != "-s" ] && [ "${prev,,}" != "--serial" ]; then
        COMPREPLY=("--serial")
        return 0
    fi

    if [ "${prev}" = "-s" ] || [ "${prev}" = "--serial" ]; then
        COMPREPLY=( $(collect_device_completion_replies "${cur}") )
        return 0
    fi

    COMPREPLY=( $(compgen -W "-s --serial -h" -- "${cur}") )
}

scrcpy_completion_repair() {
    local command_name
    local -a commands=(
        scrcpy
        /usr/local/bin/scrcpy
        scrn
        scrv
        scra
        /home/huangxingke/.local/bin/scrn
        /home/huangxingke/.local/bin/scrv
        /home/huangxingke/.local/bin/scra
    )

    for command_name in "${commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done

    for command_name in "${commands[@]}"; do
        complete -F _scrcpy_device_completion "${command_name}"
    done
}

scrcpy_completion_repair
