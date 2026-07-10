#!/bin/bash

set -e

SCRIPT_DIR="/home/huangxingke/project/Python/script"
TARGET_DIR="${HOME}/.local/bin"
TARGET_COMMAND="${TARGET_DIR}/soundBtClick"
TARGET_COMMAND_VARIANTS=(
  "${TARGET_DIR}/soundbtClick"
  "${TARGET_DIR}/soundBtclick"
  "${TARGET_DIR}/soundbtclick"
)
COMPLETION_SCRIPT="${SCRIPT_DIR}/sound_bt_click_completion.sh"
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
  "${TARGET_DIR}/updateSoundBtClick" \
  "${TARGET_DIR}/soundBtClick" \
  "${TARGET_DIR}/soundbtClick" \
  "${TARGET_DIR}/soundBtclick" \
  "${TARGET_DIR}/soundbtclick" \
  "${TARGET_DIR}/sound_bt_click"

cp "${SCRIPT_DIR}/update_sound_bt_click.sh" "${TARGET_DIR}/updateSoundBtClick"
chmod +x "${TARGET_DIR}/updateSoundBtClick"
echo "更新--- ${TARGET_DIR}/updateSoundBtClick 成功----"

cp "${SCRIPT_DIR}/voice_build_common.sh" "${TARGET_DIR}/voice_build_common.sh"
chmod +x "${TARGET_DIR}/voice_build_common.sh"
echo "更新--- ${TARGET_DIR}/voice_build_common.sh 成功----"

cp "${SCRIPT_DIR}/stwc.sh" "${TARGET_DIR}/stwc"
chmod +x "${TARGET_DIR}/stwc"
echo "更新--- ${TARGET_DIR}/stwc 成功----"

ln -sf "${TARGET_DIR}/stwc" "${TARGET_COMMAND}"
for variant in "${TARGET_COMMAND_VARIANTS[@]}"; do
  ln -sf "${TARGET_DIR}/stwc" "${variant}"
done
echo "更新--- ${TARGET_DIR}/soundBtClick 已链接到 ${TARGET_DIR}/stwc ----"

ensure_case_insensitive_completion
ensure_completion_source

# shellcheck disable=SC1090
source "${COMPLETION_SCRIPT}"
echo "更新--- 已注册 soundBtClick 的 -s 设备补全"

echo "提示: 当前 shell 如果还命中旧路径，可执行 hash -r 或重新开一个终端。"
echo "提示: 安装完成后，当前终端如需立即生效，请手动 source /home/huangxingke/project/Python/script/sound_bt_click_completion.sh"
echo "用法: soundBtClick [-s <device_serial>]"
echo "示例: soundBtClick -s c40b48ac"
