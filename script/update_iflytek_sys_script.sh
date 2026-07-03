#!/bin/bash

set -e

SCRIPT_DIR="/home/huangxingke/project/Python/script"
TARGET_DIR="${HOME}/.local/bin"
COMPLETION_SCRIPT="${SCRIPT_DIR}/iflytek_sys_completion.sh"
BASHRC_FILE="${HOME}/.bashrc"
INPUTRC_FILE="${HOME}/.inputrc"
COMPLETION_SOURCE_LINE="[ -f \"${COMPLETION_SCRIPT}\" ] && source \"${COMPLETION_SCRIPT}\""

mkdir -p "${TARGET_DIR}"

OLD_COMMANDS=(
  "${TARGET_DIR}/reboots"
  "${TARGET_DIR}/update_d01_Int_sys"
  "${TARGET_DIR}/update_d01_Int_sys.sh"
  "${TARGET_DIR}/update_d01_sys"
  "${TARGET_DIR}/update_d01_sys.sh"
  "${TARGET_DIR}/update_d01p_int_sys"
  "${TARGET_DIR}/update_d01p_int_sys.sh"
  "${TARGET_DIR}/update_kp31_int_sys"
  "${TARGET_DIR}/update_kp31_int_sys.sh"
  "${TARGET_DIR}/update_kp31_sys"
  "${TARGET_DIR}/update_kp31_sys.sh"
  "${TARGET_DIR}/updateIflytekSysScript"
  "${TARGET_DIR}/updateD01IntSys"
  "${TARGET_DIR}/updated01IntSys"
  "${TARGET_DIR}/updateD01intSys"
  "${TARGET_DIR}/updated01intSys"
  "${TARGET_DIR}/updateD01Sys"
  "${TARGET_DIR}/updated01Sys"
  "${TARGET_DIR}/updateD01sys"
  "${TARGET_DIR}/updated01sys"
  "${TARGET_DIR}/updateD01pIntSys"
  "${TARGET_DIR}/updated01pIntSys"
  "${TARGET_DIR}/updateD01pintSys"
  "${TARGET_DIR}/updated01pintSys"
  "${TARGET_DIR}/updateKp31IntSys"
  "${TARGET_DIR}/updatekp31IntSys"
  "${TARGET_DIR}/updateKp31intSys"
  "${TARGET_DIR}/updatekp31intSys"
  "${TARGET_DIR}/updateKp31Sys"
  "${TARGET_DIR}/updatekp31Sys"
  "${TARGET_DIR}/updateKp31sys"
  "${TARGET_DIR}/updatekp31sys"
)

install_command() {
  local source_file="$1"
  local target_name="$2"

  cp "${SCRIPT_DIR}/${source_file}" "${TARGET_DIR}/${target_name}"
  chmod +x "${TARGET_DIR}/${target_name}"
  echo "更新--- ${TARGET_DIR}/${target_name} 成功"
}

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

cp "${SCRIPT_DIR}/update_iflytek_sys_script.sh" "${TARGET_DIR}/updateIflytekSysScript"
chmod +x "${TARGET_DIR}/updateIflytekSysScript"
echo "更新--- ${TARGET_DIR}/updateIflytekSysScript 成功"

rm -f "${OLD_COMMANDS[@]}"
echo "更新--- 已移除老快捷方式"

install_command reboots.sh reboots

install_command update_d01_Int_sys.sh updateD01IntSys
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/updated01IntSys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/updateD01intSys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/updated01intSys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/update_d01_Int_sys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/update_d01_Int_sys.sh"

install_command update_d01_sys.sh updateD01Sys
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/updated01Sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/updateD01sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/updated01sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/update_d01_sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/update_d01_sys.sh"

install_command update_d01p_int_sys.sh updateD01pIntSys
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/updated01pIntSys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/updateD01pintSys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/updated01pintSys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/update_d01p_int_sys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/update_d01p_int_sys.sh"

install_command update_kp31_int_sys.sh updateKp31IntSys
ln -sf "${TARGET_DIR}/updateKp31IntSys" "${TARGET_DIR}/updatekp31IntSys"
ln -sf "${TARGET_DIR}/updateKp31IntSys" "${TARGET_DIR}/updateKp31intSys"
ln -sf "${TARGET_DIR}/updateKp31IntSys" "${TARGET_DIR}/updatekp31intSys"
ln -sf "${TARGET_DIR}/updateKp31IntSys" "${TARGET_DIR}/update_kp31_int_sys"
ln -sf "${TARGET_DIR}/updateKp31IntSys" "${TARGET_DIR}/update_kp31_int_sys.sh"

install_command update_kp31_sys.sh updateKp31Sys
ln -sf "${TARGET_DIR}/updateKp31Sys" "${TARGET_DIR}/updatekp31Sys"
ln -sf "${TARGET_DIR}/updateKp31Sys" "${TARGET_DIR}/updateKp31sys"
ln -sf "${TARGET_DIR}/updateKp31Sys" "${TARGET_DIR}/updatekp31sys"
ln -sf "${TARGET_DIR}/updateKp31Sys" "${TARGET_DIR}/update_kp31_sys"
ln -sf "${TARGET_DIR}/updateKp31Sys" "${TARGET_DIR}/update_kp31_sys.sh"

ensure_case_insensitive_completion
ensure_completion_source

# shellcheck disable=SC1090
source "${COMPLETION_SCRIPT}"
echo "更新--- 已注册 -s 设备补全"
