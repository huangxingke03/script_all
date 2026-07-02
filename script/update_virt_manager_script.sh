#!/bin/bash

set -e

TARGET_DIR="${HOME}/.local/bin"
APPLICATIONS_DIR="${HOME}/.local/share/applications"
SOURCE_DIR="/home/huangxingke/project/Python/script"

mkdir -p "${TARGET_DIR}"
mkdir -p "${APPLICATIONS_DIR}"

rm -f \
  "${TARGET_DIR}/update_virt_manager_script" \
  "${TARGET_DIR}/start_virt_manager" \
  "${TARGET_DIR}/updateVirtManagerScript" \
  "${TARGET_DIR}/updatevirtManagerScript" \
  "${TARGET_DIR}/updateVirtmanagerScript" \
  "${TARGET_DIR}/updatevirtmanagerScript" \
  "${TARGET_DIR}/virtManager" \
  "${TARGET_DIR}/virtmanager" \
  "${TARGET_DIR}/startVirtManager" \
  "${TARGET_DIR}/startvirtManager" \
  "${TARGET_DIR}/startVirtmanager" \
  "${TARGET_DIR}/startvirtmanager"

cp "${SOURCE_DIR}/update_virt_manager_script.sh" "${TARGET_DIR}/updateVirtManagerScript"
chmod +x "${TARGET_DIR}/updateVirtManagerScript"
ln -sf "${TARGET_DIR}/updateVirtManagerScript" "${TARGET_DIR}/updatevirtManagerScript"
ln -sf "${TARGET_DIR}/updateVirtManagerScript" "${TARGET_DIR}/updateVirtmanagerScript"
ln -sf "${TARGET_DIR}/updateVirtManagerScript" "${TARGET_DIR}/updatevirtmanagerScript"
ln -sf "${TARGET_DIR}/updateVirtManagerScript" "${TARGET_DIR}/update_virt_manager_script"
echo "更新--- ${TARGET_DIR}/updateVirtManagerScript 成功----"

cp "${SOURCE_DIR}/start_virt_manager.sh" "${TARGET_DIR}/virtManager"
chmod +x "${TARGET_DIR}/virtManager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/virtmanager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/startVirtManager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/startvirtManager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/startVirtmanager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/startvirtmanager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/start_virt_manager"
echo "更新--- ${TARGET_DIR}/virtManager 成功----"

cp "${SOURCE_DIR}/virt_manager.desktop" "${APPLICATIONS_DIR}/virt-manager-shortcut.desktop"
chmod +x "${APPLICATIONS_DIR}/virt-manager-shortcut.desktop"
echo "更新--- ${APPLICATIONS_DIR}/virt-manager-shortcut.desktop 成功----"

echo "提示: 当前 shell 如果还命中旧路径，可执行 hash -r 或重新开一个终端。"
echo "提示: 现在可在显示应用中搜索 Virt Manager 或 虚拟机管理器快捷方式。"
echo "用法: virtManager"
