#!/bin/bash

# Keep shell-local completion reload helpers separate from the actual publish script.
# `update_scipt_all.sh` installs commands into `~/.local/bin`; this file lets the
# current shell session reload completion definitions without opening a new terminal.

ROOT_DIR="/home/huangxingke/project/Python/script"
LOGCAT_DIR="${ROOT_DIR}/logcat_sum"
COMMON_TOOL_DIR="${ROOT_DIR}/common_script"
IFLYTEK_DIR="${ROOT_DIR}/update_iflytek"

_reload_random_log_completion() {
    # shellcheck disable=SC1091
    source "${LOGCAT_DIR}/random_log_completion.sh"
}

_reload_iflytek_completion() {
    # shellcheck disable=SC1091
    source "${IFLYTEK_DIR}/iflytek_sys_completion.sh"
}

_reload_voice_completion() {
    # shellcheck disable=SC1091
    source "${ROOT_DIR}/voice_build/voice_assistant_completion.sh"
}

_reload_scrcpy_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/scrcpy_completion.sh"
}

_reload_pull_logcat_by_adb_completion() {
    # shellcheck disable=SC1091
    source "${LOGCAT_DIR}/pull_logcat_by_adb_completion.sh"
}

_reload_clear_logcat_by_adb_completion() {
    # shellcheck disable=SC1091
    source "${LOGCAT_DIR}/clear_logcat_by_adb_completion.sh"
}

_reload_voice_bt_click_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/voice_bt_click_completion.sh"
}

_reload_rename_usb_dir_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/rename_usb_dir_completion.sh"
}

_reload_set_uuid_kp31_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/setUUIDKP31_completion.sh"
}

_reload_start_boot_guide_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/startBootGuideKP31_completion.sh"
}

_reload_reset_vat_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/resetVat_completion.sh"
}

_reload_reset_vst_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/resetVst_completion.sh"
}

_reload_set_sales_area_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/setSalesArea_completion.sh"
}

_reload_download_completion() {
    # shellcheck disable=SC1091
    source "${ROOT_DIR}/download_completion.sh"
}

_reload_pcatusb_completion() {
    # shellcheck disable=SC1091
    source "/home/huangxingke/.agents/skills/pcat-usb-attach/scripts/pcatusb_completion.sh"
}

_reload_syncftu_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/syncftu_completion.sh"
}

_reload_startwin10_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/startWin10_completion.sh"
}

_reload_closewin10_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/closeWin10_completion.sh"
}

# Reload every local completion provider after a bulk script update.
reload_local_completions() {
    _reload_random_log_completion
    _reload_iflytek_completion
    _reload_voice_completion
    _reload_scrcpy_completion
    _reload_pull_logcat_by_adb_completion
    _reload_clear_logcat_by_adb_completion
    _reload_voice_bt_click_completion
    _reload_rename_usb_dir_completion
    _reload_set_uuid_kp31_completion
    _reload_start_boot_guide_completion
    _reload_reset_vat_completion
    _reload_reset_vst_completion
    _reload_set_sales_area_completion
    _reload_download_completion
    _reload_pcatusb_completion
    _reload_syncftu_completion
    _reload_startwin10_completion
    _reload_closewin10_completion
}

# Internal helper for refreshing published scripts without shadowing the installed
# commands in ~/.local/bin.
_run_published_script_update() {
    command bash "${ROOT_DIR}/update_scipt_all.sh" "$@" || return $?
}

# Legacy completion refresh helpers remain private to this shell session.
_refresh_random_log_after_update() {
    _run_published_script_update "$@" || return $?
    _reload_random_log_completion
}

_refresh_iflytek_after_update() {
    _run_published_script_update "$@" || return $?
    _reload_iflytek_completion
}

_refresh_voice_build_after_update() {
    _run_published_script_update "$@" || return $?
    _reload_voice_completion
    _reload_scrcpy_completion
}

_refresh_pull_logcat_after_update() {
    _run_published_script_update "$@" || return $?
    _reload_pull_logcat_by_adb_completion
}

_refresh_clear_logcat_after_update() {
    _run_published_script_update "$@" || return $?
    _reload_clear_logcat_by_adb_completion
}

_refresh_voice_bt_click_after_update() {
    _run_published_script_update "$@" || return $?
    _reload_voice_bt_click_completion
    _reload_rename_usb_dir_completion
    _reload_set_uuid_kp31_completion
    _reload_start_boot_guide_completion
    _reload_reset_vat_completion
    _reload_reset_vst_completion
    _reload_set_sales_area_completion
}

# bash-completion 找不到专用补全时会把命令绑到 _minimal，再列出当前目录。
# 这些命令的 -s 只能补在线设备，不能落回文件名。
_install_device_completion_files() {
    local dir="${HOME}/.local/share/bash-completion/completions"
    local name
    mkdir -p "${dir}"
    for name in setSalesArea setsalesarea SetSalesArea SETSALESAREA set_sales_area; do
        printf '%s\n' '. /home/huangxingke/project/Python/script/common_script/setSalesArea_completion.sh' > "${dir}/${name}"
    done
    for name in resetVat resetvat ResetVat RESETVAT reset_vat; do
        printf '%s\n' '. /home/huangxingke/project/Python/script/common_script/resetVat_completion.sh' > "${dir}/${name}"
    done
    for name in resetVst resetvst ResetVst RESETVST reset_vst; do
        printf '%s\n' '. /home/huangxingke/project/Python/script/common_script/resetVst_completion.sh' > "${dir}/${name}"
    done
    # 含常见误写 replaceOutD01P，避免未绑定时 -s Tab 列出当前目录 300+ 文件
    for name in replaceLocal replaceLocalD01p replaceLocalDO1p replaceOut replaceOutD01p replaceOutDO1p \
                replacelocal REPLACELOCAL ReplaceLocal \
                replacelocald01p REPLACELOCALD01P ReplaceLocalD01p replaceLocalD01P ReplaceLocalD01P \
                replacelocaldo1p REPLACELOCALDO1P ReplaceLocalDO1p \
                replaceout REPLACEOUT ReplaceOut \
                replaceoutd01p REPLACEOUTD01P ReplaceOutD01p replaceOutD01P ReplaceOutD01P \
                replaceoutdo1p REPLACEOUTDO1P ReplaceOutDO1p \
                replace_local replace_local.sh replace_local_d01p replace_local_d01p.sh \
                replace_out replace_out.sh replace_out_d01p replace_out_d01p.sh; do
        printf '%s\n' '. /home/huangxingke/project/Python/script/update_iflytek/iflytek_sys_completion.sh' > "${dir}/${name}"
    done
    for name in pcatusb PCATUSB Pcatusb PcatUsb pcatUSB PCatusb \
                pcatattach PCATATTACH Pcatattach PcatAttach pcatAttach \
                pcat-usb-attach PCAT-USB-ATTACH Pcat-Usb-Attach pcat-Usb-Attach; do
        printf '%s\n' '. /home/huangxingke/.agents/skills/pcat-usb-attach/scripts/pcatusb_completion.sh' > "${dir}/${name}"
    done
    for name in syncftu SYNCFTU Syncftu SyncFtu syncFtu \
                syncFileToUbuntu syncfiletoubuntu SyncFileToUbuntu SYNCFILETOUBUNTU \
                sync-filetoubuntu SYNC-FILETOUBUNTU Sync-FileToUbuntu; do
        printf '%s\n' '. /home/huangxingke/project/Python/script/common_script/syncftu_completion.sh' > "${dir}/${name}"
    done
    for name in startWin10 STARTWIN10 StartWin10 startwin10 Startwin10 startWIN10 \
                start_win10 start-win10 \
                startWin10Pct startwin10pct startWin10PCT start_win10_pct \
                win10pct Win10Pct WIN10PCT; do
        printf '%s\n' '. /home/huangxingke/project/Python/script/common_script/startWin10_completion.sh' > "${dir}/${name}"
    done
    for name in closeWin10 CLOSEWIN10 CloseWin10 closewin10 Closewin10 closeWIN10 \
                close_win10 close-win10 \
                stopWin10 STOPWIN10 stopwin10 stop_win10; do
        printf '%s\n' '. /home/huangxingke/project/Python/script/common_script/closeWin10_completion.sh' > "${dir}/${name}"
    done
}

_repair_device_command_completions() {
    local spec
    spec="$(complete -p setsalesarea 2>/dev/null || true)"
    [[ "${spec}" == *"_set_sales_area_completion"* ]] || set_sales_area_completion_repair
    spec="$(complete -p resetvat 2>/dev/null || true)"
    [[ "${spec}" == *"_reset_vat_completion"* ]] || reset_vat_completion_repair
    spec="$(complete -p resetvst 2>/dev/null || true)"
    [[ "${spec}" == *"_reset_vst_completion"* ]] || reset_vst_completion_repair
    spec="$(complete -p pcatusb 2>/dev/null || true)"
    [[ "${spec}" == *"_pcatusb_completion"* ]] || pcatusb_completion_repair
    spec="$(complete -p syncftu 2>/dev/null || true)"
    [[ "${spec}" == *"_syncftu_completion"* ]] || syncftu_completion_repair
    spec="$(complete -p startWin10 2>/dev/null || true)"
    [[ "${spec}" == *"_startwin10_completion"* ]] || startwin10_completion_repair
    spec="$(complete -p closeWin10 2>/dev/null || true)"
    [[ "${spec}" == *"_closewin10_completion"* ]] || closewin10_completion_repair
    # iflytek/replace* 任一命令若被绑到 _minimal / 未注册，整组重绑
    for spec in \
        "$(complete -p replaceLocal 2>/dev/null || true)" \
        "$(complete -p replaceoutd01p 2>/dev/null || true)" \
        "$(complete -p replaceout 2>/dev/null || true)" \
        "$(complete -p replacelocald01p 2>/dev/null || true)" \
        "$(complete -p updateD01Sys 2>/dev/null || true)" \
        "$(complete -p updateD01IntSys 2>/dev/null || true)"
    do
        if [[ "${spec}" != *"_iflytek_sys_device_completion"* ]]; then
            iflytek_sys_completion_repair
            break
        fi
    done
}

if [[ -z "${_device_completion_loader_wrapped:-}" ]] && declare -F _completion_loader >/dev/null; then
    eval "$(declare -f _completion_loader | sed '1s/^_completion_loader /_completion_loader_device_orig /')"
    _completion_loader() {
        local cmd_lc="${1,,}"
        case "${cmd_lc}" in
            setsalesarea|set_sales_area)
                set_sales_area_completion_repair
                return 124
                ;;
            resetvat|reset_vat)
                reset_vat_completion_repair
                return 124
                ;;
            resetvst|reset_vst)
                reset_vst_completion_repair
                return 124
                ;;
            replace*)
                # 任意大小写 replaceLocal/replaceOut*（含 replaceOutD01P）都走设备补全
                case "${cmd_lc}" in
                    replace*local*|replace*out*|replace_local*|replace_out*)
                        if declare -F iflytek_sys_completion_repair >/dev/null; then
                            iflytek_sys_completion_repair
                        else
                            # shellcheck disable=SC1091
                            source "${IFLYTEK_DIR}/iflytek_sys_completion.sh"
                        fi
                        complete -F _iflytek_sys_device_completion "${1}" 2>/dev/null || true
                        return 124
                        ;;
                esac
                ;;
            syncftu|syncfiletoubuntu|sync-filetoubuntu)
                if declare -F syncftu_completion_repair >/dev/null; then
                    syncftu_completion_repair
                else
                    # shellcheck disable=SC1091
                    source "${COMMON_TOOL_DIR}/syncftu_completion.sh"
                fi
                complete -o nosort -F _syncftu_completion "${1}" 2>/dev/null || true
                return 124
                ;;
            syncfile*)
                if declare -F syncftu_completion_repair >/dev/null; then
                    syncftu_completion_repair
                else
                    # shellcheck disable=SC1091
                    source "${COMMON_TOOL_DIR}/syncftu_completion.sh"
                fi
                complete -o nosort -F _syncftu_completion "${1}" 2>/dev/null || true
                return 124
                ;;
            startwin10|startwin10pct|win10pct|start_win10|start-win10)
                if declare -F startwin10_completion_repair >/dev/null; then
                    startwin10_completion_repair
                else
                    # shellcheck disable=SC1091
                    source "${COMMON_TOOL_DIR}/startWin10_completion.sh"
                fi
                complete -o nosort -F _startwin10_completion "${1}" 2>/dev/null || true
                return 124
                ;;
            closewin10|stopwin10|close_win10|close-win10|stop_win10)
                if declare -F closewin10_completion_repair >/dev/null; then
                    closewin10_completion_repair
                else
                    # shellcheck disable=SC1091
                    source "${COMMON_TOOL_DIR}/closeWin10_completion.sh"
                fi
                complete -o nosort -F _closewin10_completion "${1}" 2>/dev/null || true
                return 124
                ;;
            pcatusb|pcatattach|pcat-usb-attach)
                if declare -F pcatusb_completion_repair >/dev/null; then
                    pcatusb_completion_repair
                else
                    # shellcheck disable=SC1091
                    source "/home/huangxingke/.agents/skills/pcat-usb-attach/scripts/pcatusb_completion.sh"
                fi
                complete -o nosort -F _pcatusb_completion "${1}" 2>/dev/null || true
                return 124
                ;;
        esac
        _completion_loader_device_orig "$@"
    }
    _device_completion_loader_wrapped=1
fi

if [[ "${PROMPT_COMMAND:-}" != *"_repair_device_command_completions"* ]]; then
    PROMPT_COMMAND="_repair_device_command_completions${PROMPT_COMMAND:+;${PROMPT_COMMAND}}"
fi

# Load current completion definitions immediately when this file is sourced.
_install_device_completion_files
reload_local_completions
