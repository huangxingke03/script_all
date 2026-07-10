#!/bin/bash

set -e

SCRIPT_DIR="/home/huangxingke/project/Python/script"
TARGET_DIR="${HOME}/.local/bin"
COMPLETION_SCRIPT="${SCRIPT_DIR}/pull_logcat_by_adb_completion.sh"
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
  "${TARGET_DIR}/update_pull_logcat_by_adb" \
  "${TARGET_DIR}/pull_logcat_by_adb" \
  "${TARGET_DIR}/updatePullLogcatByAdb" \
  "${TARGET_DIR}/updatepullLogcatByAdb" \
  "${TARGET_DIR}/updatePullLogcatbyAdb" \
  "${TARGET_DIR}/updatepullLogcatbyAdb" \
  "${TARGET_DIR}/pullLogcatByAdb" \
  "${TARGET_DIR}/pulllogcatByAdb" \
  "${TARGET_DIR}/pullLogcatbyAdb" \
  "${TARGET_DIR}/pulllogcatbyAdb"

cp "${SCRIPT_DIR}/update_pull_logcat_by_adb.sh" "${TARGET_DIR}/updatePullLogcatByAdb"
chmod +x "${TARGET_DIR}/updatePullLogcatByAdb"
ln -sf "${TARGET_DIR}/updatePullLogcatByAdb" "${TARGET_DIR}/updatepullLogcatByAdb"
ln -sf "${TARGET_DIR}/updatePullLogcatByAdb" "${TARGET_DIR}/updatePullLogcatbyAdb"
ln -sf "${TARGET_DIR}/updatePullLogcatByAdb" "${TARGET_DIR}/updatepullLogcatbyAdb"
ln -sf "${TARGET_DIR}/updatePullLogcatByAdb" "${TARGET_DIR}/update_pull_logcat_by_adb"
echo "更新--- ${TARGET_DIR}/updatePullLogcatByAdb 成功----"

cp "${SCRIPT_DIR}/pull_logcat_by_adb.sh" "${TARGET_DIR}/pullLogcatByAdb"
chmod +x "${TARGET_DIR}/pullLogcatByAdb"
ln -sf "${TARGET_DIR}/pullLogcatByAdb" "${TARGET_DIR}/pulllogcatByAdb"
ln -sf "${TARGET_DIR}/pullLogcatByAdb" "${TARGET_DIR}/pullLogcatbyAdb"
ln -sf "${TARGET_DIR}/pullLogcatByAdb" "${TARGET_DIR}/pulllogcatbyAdb"
ln -sf "${TARGET_DIR}/pullLogcatByAdb" "${TARGET_DIR}/pull_logcat_by_adb"
echo "更新--- ${TARGET_DIR}/pullLogcatByAdb 成功----"

ensure_case_insensitive_completion
ensure_completion_source

# shellcheck disable=SC1090
source "${COMPLETION_SCRIPT}"
echo "更新--- 已注册 pullLogcatByAdb 的 -s 设备补全"

echo "提示: 当前 shell 如果还命中旧路径，可执行 hash -r 或重新开一个终端。"
echo "用法: pullLogcatByAdb [-s <device_serial>] [remote_path]"
echo "示例: pullLogcatByAdb /data/log"
