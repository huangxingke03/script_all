#!/bin/bash

SCRCPY_D01_SERIAL="f6e277ff"
SCRCPY_KP31_SERIAL="3d3fd206"
SCRCPY_GEN4_GVM_SERIAL="63e9fbdd"

_scrcpy_resolve_device_alias() {
    local value="${1,,}"

    case "${value}" in
        d01)
            printf '%s\n' "${SCRCPY_D01_SERIAL}"
            ;;
        kp31)
            printf '%s\n' "${SCRCPY_KP31_SERIAL}"
            ;;
        *)
            printf '%s\n' "$1"
            ;;
    esac
}

_scrcpy_known_device_aliases() {
    printf '%s\n' \
        d01 \
        D01 \
        kp31 \
        KP31
}

_scrcpy_is_default_bench_device() {
    case "$1" in
        "${SCRCPY_D01_SERIAL}"|"${SCRCPY_KP31_SERIAL}"|"${SCRCPY_GEN4_GVM_SERIAL}")
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
    local cur cur_lower prev line serial state model device_name transport_id alias
    local -a prefix_suggestions fuzzy_suggestions
    cur="${COMP_WORDS[COMP_CWORD]}"
    cur_lower="${cur,,}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Disable filename fallback so `-s` only suggests devices.
    compopt +o default +o bashdefault 2>/dev/null

    if [ "${prev}" = "-s" ] || [ "${prev}" = "--serial" ]; then
        prefix_suggestions=()
        fuzzy_suggestions=()

        while IFS= read -r alias; do
            [ -z "${alias}" ] && continue

            if [[ "${alias,,}" == "${cur_lower}"* ]]; then
                prefix_suggestions+=("${alias}")
            elif [[ "${alias,,}" == *"${cur_lower}"* ]]; then
                fuzzy_suggestions+=("${alias}")
            fi
        done < <(_scrcpy_known_device_aliases)

        while IFS= read -r line; do
            [ -z "${line}" ] && continue
            case "${line}" in
                List\ of\ devices* ) continue ;;
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
            COMPREPLY=( $(printf '%s\n' "${prefix_suggestions[@]}" | awk '!seen[$0]++') )
        else
            COMPREPLY=( $(printf '%s\n' "${fuzzy_suggestions[@]}" | awk '!seen[$0]++') )
        fi
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
        complete -o nospace -F _scrcpy_device_completion "${command_name}"
    done
}

scrcpy_completion_repair
