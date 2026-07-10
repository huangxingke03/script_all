#!/bin/bash

set -e

SCRIPT_DIR="/home/huangxingke/project/Python/script"
TARGET_DIR="${HOME}/.local/bin"
COMPLETION_SCRIPT="${SCRIPT_DIR}/clear_logcat_by_adb_completion.sh"
BASHRC_FILE="${HOME}/.bashrc"
INPUTRC_FILE="${HOME}/.inputrc"
COMPLETION_SOURCE_LINE="[ -f \"${COMPLETION_SCRIPT}\" ] && source \"${COMPLETION_SCRIPT}\""

mkdir -p "${TARGET_DIR}"

ensure_case_insensitive_completion() {
  touch "${INPUTRC_FILE}"
  if ! grep -qxF "set completion-ignore-case on" "${INPUTRC_FILE}"; then
    printf '\nset completion-ignore-case on\n' >> "${INPUTRC_FILE}"
    echo "更新--- 已开启 Bash 大小写不敏感补全，请重新打开终端或执行: bind 'set completion-ignore-case on'"
  else
    echo "更新--- Bash 大小写不敏感补全已开启"
  fi
}

ensure_completion_source() {
  touch "${BASHRC_FILE}"
  if ! grep -qxF "${COMPLETION_SOURCE_LINE}" "${BASHRC_FILE}"; then
    printf '\n%s\n' "${COMPLETION_SOURCE_LINE}" >> "${BASHRC_FILE}"
    echo "更新--- 已写入 Bash 补全加载配置"
  else
    echo "更新--- Bash 补全加载配置已存在"
  fi
}

rm -f \
  "${TARGET_DIR}/update_clear_logcat_by_adb" \
  "${TARGET_DIR}/clear_logcat_by_adb" \
  "${TARGET_DIR}/updateClearLogcatByAdb" \
  "${TARGET_DIR}/updateclearLogcatByAdb" \
  "${TARGET_DIR}/updateClearLogcatbyAdb" \
  "${TARGET_DIR}/updateclearLogcatbyAdb" \
  "${TARGET_DIR}/clearLogcatByAdb" \
  "${TARGET_DIR}/clearlogcatByAdb" \
  "${TARGET_DIR}/clearLogcatbyAdb" \
  "${TARGET_DIR}/clearlogcatbyAdb"

cp "${SCRIPT_DIR}/update_clear_logcat_by_adb.sh" "${TARGET_DIR}/updateClearLogcatByAdb"
chmod +x "${TARGET_DIR}/updateClearLogcatByAdb"
ln -sf "${TARGET_DIR}/updateClearLogcatByAdb" "${TARGET_DIR}/updateclearLogcatByAdb"
ln -sf "${TARGET_DIR}/updateClearLogcatByAdb" "${TARGET_DIR}/updateClearLogcatbyAdb"
ln -sf "${TARGET_DIR}/updateClearLogcatByAdb" "${TARGET_DIR}/updateclearLogcatbyAdb"
ln -sf "${TARGET_DIR}/updateClearLogcatByAdb" "${TARGET_DIR}/update_clear_logcat_by_adb"
echo "更新--- ${TARGET_DIR}/updateClearLogcatByAdb 成功----"

cp "${SCRIPT_DIR}/clear_logcat_by_adb.sh" "${TARGET_DIR}/clearLogcatByAdb"
chmod +x "${TARGET_DIR}/clearLogcatByAdb"
ln -sf "${TARGET_DIR}/clearLogcatByAdb" "${TARGET_DIR}/clearlogcatByAdb"
ln -sf "${TARGET_DIR}/clearLogcatByAdb" "${TARGET_DIR}/clearLogcatbyAdb"
ln -sf "${TARGET_DIR}/clearLogcatByAdb" "${TARGET_DIR}/clearlogcatbyAdb"
ln -sf "${TARGET_DIR}/clearLogcatByAdb" "${TARGET_DIR}/clear_logcat_by_adb"
echo "更新--- ${TARGET_DIR}/clearLogcatByAdb 成功----"

ensure_case_insensitive_completion
ensure_completion_source

# shellcheck disable=SC1090
source "${COMPLETION_SCRIPT}"
echo "更新--- 已注册 clearLogcatByAdb 的 -s 设备补全"

echo "提示: 当前 shell 如果还命中旧路径，可执行 hash -r 或重新开一个终端。"
echo "用法: clearLogcatByAdb [-s <device_serial>] [remote_path]"
echo "示例: clearLogcatByAdb /data/log"
