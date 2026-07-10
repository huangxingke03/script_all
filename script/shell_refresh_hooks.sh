#!/bin/bash

SCRIPT_DIR="/home/huangxingke/project/Python/script"

_reload_random_log_completion() {
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/random_log_completion.sh"
}

_reload_iflytek_completion() {
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/iflytek_sys_completion.sh"
}

_reload_voice_completion() {
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/voice_assistant_completion.sh"
}

_reload_scrcpy_completion() {
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/scrcpy_completion.sh"
}

_reload_pull_logcat_by_adb_completion() {
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/pull_logcat_by_adb_completion.sh"
}

_reload_clear_logcat_by_adb_completion() {
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/clear_logcat_by_adb_completion.sh"
}

reload_local_completions() {
    _reload_random_log_completion
    _reload_iflytek_completion
    _reload_voice_completion
    _reload_scrcpy_completion
    _reload_pull_logcat_by_adb_completion
    _reload_clear_logcat_by_adb_completion
}

update_random_log_script() {
    command bash "${SCRIPT_DIR}/update_random_log_script.sh" "$@" || return $?
    _reload_random_log_completion
}

updateIflytekSysScript() {
    command bash "${SCRIPT_DIR}/update_iflytek_sys_script.sh" "$@" || return $?
    _reload_iflytek_completion
}

update_voice_build_script() {
    command bash "${SCRIPT_DIR}/update_voice_build_script.sh" "$@" || return $?
    _reload_voice_completion
    _reload_scrcpy_completion
}

updatePullLogcatByAdb() {
    command bash "${SCRIPT_DIR}/update_pull_logcat_by_adb.sh" "$@" || return $?
    _reload_pull_logcat_by_adb_completion
}

updateClearLogcatByAdb() {
    command bash "${SCRIPT_DIR}/update_clear_logcat_by_adb.sh" "$@" || return $?
    _reload_clear_logcat_by_adb_completion
}
