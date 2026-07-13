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

_reload_sound_bt_click_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/sound_bt_click_completion.sh"
}

_reload_rename_usb_dir_completion() {
    # shellcheck disable=SC1091
    source "${COMMON_TOOL_DIR}/rename_usb_dir_completion.sh"
}

# Reload every local completion provider after a bulk script update.
reload_local_completions() {
    _reload_random_log_completion
    _reload_iflytek_completion
    _reload_voice_completion
    _reload_scrcpy_completion
    _reload_pull_logcat_by_adb_completion
    _reload_clear_logcat_by_adb_completion
    _reload_sound_bt_click_completion
    _reload_rename_usb_dir_completion
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

_refresh_sound_bt_click_after_update() {
    _run_published_script_update "$@" || return $?
    _reload_sound_bt_click_completion
    _reload_rename_usb_dir_completion
}

# Load current completion definitions immediately when this file is sourced.
reload_local_completions
