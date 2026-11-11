#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../voice_build/voice_build_common.sh"

# 任意大小写/误写的 replace* 命令名都绑到设备补全，避免落回当前目录文件名（303 possibilities）
_bind_iflytek_replace_typed_command() {
    local cmd="${1:-}"
    local cmd_lc

    [ -n "${cmd}" ] || return 0
    cmd_lc="${cmd,,}"
    case "${cmd_lc}" in
        replace*local*|replace*out*|replace_local*|replace_out*)
            complete -F _iflytek_sys_device_completion "${cmd}" 2>/dev/null || true
            ;;
    esac
}

_is_iflytek_replace_command() {
    local cmd_lc="${1,,}"
    case "${cmd_lc}" in
        replace*local*|replace*out*|replace_local*|replace_out*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

_iflytek_sys_device_completion() {
    local cur prev device_query reply
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    device_query="${cur}"

    # 把当前行上实际敲出的命令名也绑上（如 replaceOutD01P）
    _bind_iflytek_replace_typed_command "${COMP_WORDS[0]}"

    # 禁止落回文件名；-s 后只补在线设备
    compopt +o default +o bashdefault +o dirnames +o filenames 2>/dev/null

    # 已输入完整 -s 但尚未空格时，先补出 -s（由 bash 加空格），下一次 Tab 再列设备
    if [ "${cur,,}" = "-s" ] && [ "${prev,,}" != "-s" ]; then
        COMPREPLY=("-s")
        return 0
    fi

    if [ "${prev,,}" = "-s" ]; then
        [[ "${device_query}" == */* ]] && device_query=""
        COMPREPLY=()
        while IFS= read -r reply; do
            [ -n "${reply}" ] && COMPREPLY+=("${reply}")
        done < <(collect_device_completion_replies "${device_query}")
        # 设备序列号后不加空格；无在线设备时保持静默，不回落文件名
        compopt -o nospace 2>/dev/null
        return 0
    fi

    COMPREPLY=( $(compgen -W "-s -h" -- "${cur}") )
}

iflytek_sys_completion_repair() {
    local command_name
    local -a commands=(
        ./common_script/reboot_device.sh
        reboot_device.sh
        /usr/local/bin/rebootDevice
        rebootDevice
        rebootdevice
        reboot_device
        ./update_iflytek/update_d01_Int_sys.sh
        ./update_iflytek/update_d01_Int_sys_setting.sh
        ./update_iflytek/update_d01_sys.sh
        ./update_iflytek/update_d01_sys_setting.sh
        ./update_iflytek/update_d01p_int_sys.sh
        ./update_iflytek/update_kp31_int_sys.sh
        ./update_iflytek/update_kp31_sys.sh
        update_d01_Int_sys.sh
        update_d01_Int_sys_setting.sh
        update_d01_sys.sh
        update_d01_sys_setting.sh
        update_d01p_int_sys.sh
        update_kp31_int_sys.sh
        update_kp31_sys.sh
        /usr/local/bin/updateD01IntSys
        /usr/local/bin/updated01IntSys
        /usr/local/bin/updateDO1IntSys
        /usr/local/bin/updatedo1IntSys
        /usr/local/bin/updateD01intSys
        /usr/local/bin/updateDO1intSys
        /usr/local/bin/updatedo1intSys
        /usr/local/bin/updated01intSys
        /usr/local/bin/updateD01IntSysSetting
        /usr/local/bin/updated01IntSysSetting
        /usr/local/bin/updateDO1IntSysSetting
        /usr/local/bin/updatedo1IntSysSetting
        /usr/local/bin/updateD01intSysSetting
        /usr/local/bin/updateDO1intSysSetting
        /usr/local/bin/updatedo1intSysSetting
        /usr/local/bin/updated01intSysSetting
        /usr/local/bin/updateD01Sys
        /usr/local/bin/updated01Sys
        /usr/local/bin/updateDO1Sys
        /usr/local/bin/updatedo1Sys
        /usr/local/bin/updateD01sys
        /usr/local/bin/updateDO1sys
        /usr/local/bin/updatedo1sys
        /usr/local/bin/updated01sys
        /usr/local/bin/updateD01SysSetting
        /usr/local/bin/updated01SysSetting
        /usr/local/bin/updateDO1SysSetting
        /usr/local/bin/updatedo1SysSetting
        /usr/local/bin/updateD01sysSetting
        /usr/local/bin/updateDO1sysSetting
        /usr/local/bin/updatedo1sysSetting
        /usr/local/bin/updated01sysSetting
        /usr/local/bin/updateD01pIntSys
        /usr/local/bin/updated01pIntSys
        /usr/local/bin/updateDO1pIntSys
        /usr/local/bin/updatedo1pIntSys
        /usr/local/bin/updateD01pintSys
        /usr/local/bin/updateDO1pintSys
        /usr/local/bin/updatedo1pintSys
        /usr/local/bin/updated01pintSys
        /usr/local/bin/updateKp31IntSys
        /usr/local/bin/updatekp31IntSys
        /usr/local/bin/updateKp31intSys
        /usr/local/bin/updatekp31intSys
        /usr/local/bin/updateKp31Sys
        /usr/local/bin/updatekp31Sys
        /usr/local/bin/updateKp31sys
        /usr/local/bin/updatekp31sys
        ./update_iflytek/update_iflytek_res_d01.sh
        ./update_iflytek/update_iflytek_res_d01_int.sh
        ./update_iflytek/update_iflytek_res_kp31.sh
        update_iflytek_res_d01.sh
        update_iflytek_res_d01_int.sh
        update_iflytek_res_kp31.sh
        update_iflytek_res_d01
        update_iflytek_res_d01_int
        update_iflytek_res_kp31
        /usr/local/bin/updateIflytekResD01
        /usr/local/bin/updateiflytekResD01
        /usr/local/bin/updateIflytekResd01
        /usr/local/bin/updateiflytekresd01
        /usr/local/bin/updateIflytekResDO1
        /usr/local/bin/updateiflytekResDO1
        /usr/local/bin/updateIflytekResdo1
        /usr/local/bin/updateiflytekresdo1
        /usr/local/bin/updateIflytekResD01Int
        /usr/local/bin/updateiflytekResD01Int
        /usr/local/bin/updateIflytekResd01Int
        /usr/local/bin/updateiflytekresd01Int
        /usr/local/bin/updateIflytekResDO1Int
        /usr/local/bin/updateiflytekResDO1Int
        /usr/local/bin/updateIflytekResdo1Int
        /usr/local/bin/updateiflytekresdo1Int
        /usr/local/bin/updateIflytekResD01int
        /usr/local/bin/updateiflytekResD01int
        /usr/local/bin/updateIflytekResd01int
        /usr/local/bin/updateiflytekresd01int
        /usr/local/bin/updateIflytekResDO1int
        /usr/local/bin/updateiflytekResDO1int
        /usr/local/bin/updateIflytekResdo1int
        /usr/local/bin/updateiflytekresdo1int
        /usr/local/bin/updateIflytekResKp31
        /usr/local/bin/updateiflytekResKp31
        /usr/local/bin/updateIflytekReskp31
        /usr/local/bin/updateiflytekreskp31
        /usr/local/bin/update_iflytek_res_d01
        /usr/local/bin/update_iflytek_res_d01.sh
        /usr/local/bin/update_iflytek_res_d01_int
        /usr/local/bin/update_iflytek_res_d01_int.sh
        /usr/local/bin/update_iflytek_res_kp31
        /usr/local/bin/update_iflytek_res_kp31.sh
        updateD01IntSys
        updated01IntSys
        updateDO1IntSys
        updatedo1IntSys
        updateD01intSys
        updateDO1intSys
        updatedo1intSys
        updated01intSys
        updateD01IntSysSetting
        updated01IntSysSetting
        updateDO1IntSysSetting
        updatedo1IntSysSetting
        updateD01intSysSetting
        updateDO1intSysSetting
        updatedo1intSysSetting
        updated01intSysSetting
        updateD01Sys
        updated01Sys
        updateDO1Sys
        updatedo1Sys
        updateD01sys
        updateDO1sys
        updatedo1sys
        updated01sys
        updateD01SysSetting
        updated01SysSetting
        updateDO1SysSetting
        updatedo1SysSetting
        updateD01sysSetting
        updateDO1sysSetting
        updatedo1sysSetting
        updated01sysSetting
        updateD01pIntSys
        updated01pIntSys
        updateDO1pIntSys
        updatedo1pIntSys
        updateD01pintSys
        updateDO1pintSys
        updatedo1pintSys
        updated01pintSys
        updateKp31IntSys
        updatekp31IntSys
        updateKp31intSys
        updatekp31intSys
        updateKp31Sys
        updatekp31Sys
        updateKp31sys
        updatekp31sys
        updateIflytekResD01
        updateiflytekResD01
        updateIflytekResd01
        updateiflytekresd01
        updateIflytekResDO1
        updateiflytekResDO1
        updateIflytekResdo1
        updateiflytekresdo1
        updateIflytekResD01Int
        updateiflytekResD01Int
        updateIflytekResd01Int
        updateiflytekresd01Int
        updateIflytekResDO1Int
        updateiflytekResDO1Int
        updateIflytekResdo1Int
        updateiflytekresdo1Int
        updateIflytekResD01int
        updateiflytekResD01int
        updateIflytekResd01int
        updateiflytekresd01int
        updateIflytekResDO1int
        updateiflytekResDO1int
        updateIflytekResdo1int
        updateiflytekresdo1int
        updateIflytekResKp31
        updateiflytekResKp31
        updateIflytekReskp31
        updateiflytekreskp31
        # replace* 正式名（PATH 只保留这些，Tab 提示更干净）
        replaceLocal
        replaceLocalD01p
        replaceLocalDO1p
        replaceOut
        replaceOutD01p
        replaceOutDO1p
        # 常见大小写误写仍绑补全，避免 -s 后列出当前目录文件
        replacelocal
        REPLACELOCAL
        ReplaceLocal
        replacelocald01p
        REPLACELOCALD01P
        ReplaceLocalD01p
        replaceLocalD01P
        ReplaceLocalD01P
        REPLACELOCALD01p
        replacelocaldo1p
        REPLACELOCALDO1P
        ReplaceLocalDO1p
        replaceout
        REPLACEOUT
        ReplaceOut
        replaceoutd01p
        REPLACEOUTD01P
        ReplaceOutD01p
        replaceOutD01P
        ReplaceOutD01P
        REPLACEOUTD01p
        replaceoutdo1p
        REPLACEOUTDO1P
        ReplaceOutDO1p
        replace_local
        replace_local.sh
        replace_local_d01p
        replace_local_d01p.sh
        replace_out
        replace_out.sh
        replace_out_d01p
        replace_out_d01p.sh
        ./update_iflytek/replace_local.sh
        ./update_iflytek/replace_local_d01p.sh
        ./update_iflytek/replace_out.sh
        ./update_iflytek/replace_out_d01p.sh
    )

    local -a stale_commands=(
        update_d01_Int_sys
        update_d01_Int_sys_setting
        update_d01_sys
        update_d01_sys_setting
        update_d01p_int_sys
        update_kp31_int_sys
        update_kp31_sys
        /usr/local/bin/update_d01_Int_sys
        /usr/local/bin/update_d01_Int_sys_setting
        /usr/local/bin/update_d01_sys
        /usr/local/bin/update_d01_sys_setting
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
        # 不用全局 -o nospace：否则补全出 -s 后不加空格，再 Tab 无法进入设备补全
        complete -F _iflytek_sys_device_completion "${command_name}"
        case "${command_name}" in
            /*|./*) ;;
            *)
                complete -F _iflytek_sys_device_completion "${HOME}/.local/bin/${command_name}"
                ;;
        esac
    done
}

iflytek_sys_completion_repair
