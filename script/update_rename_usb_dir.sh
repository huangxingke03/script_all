#!/bin/bash

set -e

TARGET_DIR="${HOME}/.local/bin"
SOURCE_DIR="/home/huangxingke/project/Python/script"
COMPLETION_SCRIPT="${SOURCE_DIR}/rename_usb_dir_completion.sh"
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
  "${TARGET_DIR}/update_rename_usb_dir" \
  "${TARGET_DIR}/rename_usb_dir" \
  "${TARGET_DIR}/updateRenameUsbDir" \
  "${TARGET_DIR}/updaterenameUsbDir" \
  "${TARGET_DIR}/updateRenameUsbdir" \
  "${TARGET_DIR}/updaterenameUsbdir" \
  "${TARGET_DIR}/renameUsbDir" \
  "${TARGET_DIR}/renameusbDir" \
  "${TARGET_DIR}/renameUsbdir" \
  "${TARGET_DIR}/renameusbdir"

cp "${SOURCE_DIR}/update_rename_usb_dir.sh" "${TARGET_DIR}/updateRenameUsbDir"
chmod +x "${TARGET_DIR}/updateRenameUsbDir"
ln -sf "${TARGET_DIR}/updateRenameUsbDir" "${TARGET_DIR}/updaterenameUsbDir"
ln -sf "${TARGET_DIR}/updateRenameUsbDir" "${TARGET_DIR}/updateRenameUsbdir"
ln -sf "${TARGET_DIR}/updateRenameUsbDir" "${TARGET_DIR}/updaterenameUsbdir"
ln -sf "${TARGET_DIR}/updateRenameUsbDir" "${TARGET_DIR}/update_rename_usb_dir"
echo "更新--- ${TARGET_DIR}/updateRenameUsbDir 成功----"

cp "${SOURCE_DIR}/rename_usb_dir.sh" "${TARGET_DIR}/renameUsbDir"
chmod +x "${TARGET_DIR}/renameUsbDir"
ln -sf "${TARGET_DIR}/renameUsbDir" "${TARGET_DIR}/renameusbDir"
ln -sf "${TARGET_DIR}/renameUsbDir" "${TARGET_DIR}/renameUsbdir"
ln -sf "${TARGET_DIR}/renameUsbDir" "${TARGET_DIR}/renameusbdir"
ln -sf "${TARGET_DIR}/renameUsbDir" "${TARGET_DIR}/rename_usb_dir"
echo "更新--- ${TARGET_DIR}/renameUsbDir 成功----"

ensure_case_insensitive_completion
ensure_completion_source

# shellcheck disable=SC1090
source "${COMPLETION_SCRIPT}"
echo "更新--- 已注册 renameUsbDir Tab 补全"

echo "提示: 当前 shell 如果还命中旧路径，可执行 hash -r 或重新开一个终端。"
echo "用法: renameUsbDir <修改前目录名> <修改后目录名>"
