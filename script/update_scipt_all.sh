#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="/home/huangxingke/project/Python/script"
if [ -d "${SCRIPT_DIR}/download_jira" ] && [ -d "${SCRIPT_DIR}/download_feishu" ]; then
  ROOT_DIR="${SCRIPT_DIR}"
else
  ROOT_DIR="${SOURCE_ROOT}"
fi
JIRA_DIR="${ROOT_DIR}/download_jira"
FEISHU_DIR="${ROOT_DIR}/download_feishu"
LOGCAT_DIR="${ROOT_DIR}/logcat_sum"
COMMON_TOOL_DIR="${ROOT_DIR}/common_script"
IFLYTEK_DIR="${ROOT_DIR}/update_iflytek"
VOICE_BUILD_DIR="${ROOT_DIR}/voice_build"
TARGET_DIR="${HOME}/.local/bin"
APPLICATIONS_DIR="${HOME}/.local/share/applications"
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
if [ -z "${DESKTOP_DIR}" ] || [ ! -d "${DESKTOP_DIR}" ]; then
  if [ -d "${HOME}/桌面" ]; then
    DESKTOP_DIR="${HOME}/桌面"
  else
    DESKTOP_DIR="${HOME}/Desktop"
  fi
fi
INPUTRC_FILE="${HOME}/.inputrc"
BASHRC_FILE="${HOME}/.bashrc"

install_desktop_shortcut() {
  local src="$1"
  local basename_dst="$2"
  local dst_app="${APPLICATIONS_DIR}/${basename_dst}"
  local dst_desk="${DESKTOP_DIR}/${basename_dst}"
  mkdir -p "${APPLICATIONS_DIR}"
  cp "${src}" "${dst_app}"
  chmod +x "${dst_app}"
  if command -v gio >/dev/null 2>&1; then
    gio set "${dst_app}" metadata::trusted true 2>/dev/null || true
  fi
  echo "更新--- ${dst_app} 成功----"
  if [ -d "${DESKTOP_DIR}" ]; then
    cp "${src}" "${dst_desk}"
    chmod +x "${dst_desk}"
    if command -v gio >/dev/null 2>&1; then
      gio set "${dst_desk}" metadata::trusted true 2>/dev/null || true
    fi
    echo "更新--- ${dst_desk} 成功----"
  fi
}

ensure_case_insensitive_completion() {
  touch "${INPUTRC_FILE}"
  local result
  result=$(python3 - "$INPUTRC_FILE" <<'PYINNER'
from pathlib import Path
import sys
path = Path(sys.argv[1])
wanted = [
    ("completion-ignore-case", "on"),
    ("show-all-if-ambiguous", "off"),
    ("show-all-if-unmodified", "on"),
    ("completion-query-items", "100"),
    ("page-completions", "on"),
]
wanted_map = dict(wanted)
lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
seen = set()
out = []
changed = False
for line in lines:
    stripped = line.strip()
    if stripped.startswith("set "):
        parts = stripped.split(None, 2)
        if len(parts) >= 3 and parts[1] in wanted_map:
            key = parts[1]
            new_line = f"set {key} {wanted_map[key]}"
            if key in seen:
                changed = True
                continue
            seen.add(key)
            if line != new_line:
                changed = True
            out.append(new_line)
            continue
    out.append(line)
for key, value in wanted:
    if key not in seen:
        out.append(f"set {key} {value}")
        changed = True
text = "\n".join(out).rstrip() + "\n"
old = path.read_text(encoding="utf-8") if path.exists() else ""
if old != text:
    path.write_text(text, encoding="utf-8")
    changed = True
print("CHANGED" if changed else "UNCHANGED")
PYINNER
)
  if [ "$result" = "CHANGED" ]; then
    echo "更新--- 已开启 Bash 补全：忽略大小写；voic 先补成 voice，再 Tab 列出。请重新打开终端，或执行: bind 'set completion-ignore-case on'; bind 'set show-all-if-ambiguous off'; bind 'set show-all-if-unmodified on'; bind 'set completion-query-items 100'"
  else
    echo "更新--- Bash 补全配置已开启"
  fi
}
ensure_shell_hooks_source() {
  local hooks_script="${ROOT_DIR}/shell_refresh_hooks.sh"
  local source_line="[ -f "${hooks_script}" ] && source "${hooks_script}""

  touch "${BASHRC_FILE}"
  if ! grep -qxF "${source_line}" "${BASHRC_FILE}"; then
    printf '
%s
' "${source_line}" >> "${BASHRC_FILE}"
    echo "更新--- 已写入 shell hooks 加载配置: ${hooks_script}"
  else
    echo "更新--- shell hooks 加载配置已存在: ${hooks_script}"
  fi
}

remove_legacy_completion_sources() {
  touch "${BASHRC_FILE}"
  python3 - "$BASHRC_FILE" <<'PYINNER'
import sys
from pathlib import Path
path = Path(sys.argv[1])
remove = {
    '[ -f /home/huangxingke/project/Python/script/random_log_completion.sh ] && source /home/huangxingke/project/Python/script/random_log_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/pull_logcat_by_adb_completion.sh ] && source /home/huangxingke/project/Python/script/pull_logcat_by_adb_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/clear_logcat_by_adb_completion.sh ] && source /home/huangxingke/project/Python/script/clear_logcat_by_adb_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/scrcpy_completion.sh ] && source /home/huangxingke/project/Python/script/scrcpy_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/voice_bt_click_completion.sh ] && source /home/huangxingke/project/Python/script/voice_bt_click_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/common_script/setUUIDKP31_completion.sh ] && source /home/huangxingke/project/Python/script/common_script/setUUIDKP31_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/iflytek_sys_completion.sh ] && source /home/huangxingke/project/Python/script/iflytek_sys_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/voice_assistant_completion.sh ] && source /home/huangxingke/project/Python/script/voice_assistant_completion.sh',
    '[ -f "/home/huangxingke/project/Python/script/voice_build/voice_assistant_completion.sh" ] && source "/home/huangxingke/project/Python/script/voice_build/voice_assistant_completion.sh"',
    '[ -f /home/huangxingke/project/Python/script/voice_build/voice_assistant_completion.sh ] && source /home/huangxingke/project/Python/script/voice_build/voice_assistant_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/logcat_sum/random_log_completion.sh ] && source /home/huangxingke/project/Python/script/logcat_sum/random_log_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/logcat_sum/pull_logcat_by_adb_completion.sh ] && source /home/huangxingke/project/Python/script/logcat_sum/pull_logcat_by_adb_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/logcat_sum/clear_logcat_by_adb_completion.sh ] && source /home/huangxingke/project/Python/script/logcat_sum/clear_logcat_by_adb_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/common_script/scrcpy_completion.sh ] && source /home/huangxingke/project/Python/script/common_script/scrcpy_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/common_script/voice_bt_click_completion.sh ] && source /home/huangxingke/project/Python/script/common_script/voice_bt_click_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/common_script/setUUIDKP31_completion.sh ] && source /home/huangxingke/project/Python/script/common_script/setUUIDKP31_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/update_iflytek/iflytek_sys_completion.sh ] && source /home/huangxingke/project/Python/script/update_iflytek/iflytek_sys_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/rename_usb_dir_completion.sh ] && source /home/huangxingke/project/Python/script/rename_usb_dir_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/common_script/rename_usb_dir_completion.sh ] && source /home/huangxingke/project/Python/script/common_script/rename_usb_dir_completion.sh',
}
lines = path.read_text().splitlines()
kept = [line for line in lines if line not in remove]
path.write_text("\n".join(kept) + ("\n" if kept else ""))
PYINNER
}

install_script() {
  local source_path="$1"
  local target_path="$2"
  cp "${source_path}" "${target_path}"
  chmod +x "${target_path}"
}

mkdir -p "${TARGET_DIR}"
mkdir -p "${APPLICATIONS_DIR}"

echo "===== 更新 JIRA 下载脚本 ====="
rm -f "${TARGET_DIR}/download_jira_cookie.sh"
cp "${JIRA_DIR}/download_jira_request.curl" "${TARGET_DIR}/download_jira_request.curl"
echo "更新--- ${TARGET_DIR}/download_jira_request.curl 成功----"

echo "===== 更新 Feishu 下载脚本 ====="
rm -f "${TARGET_DIR}/download_bug_feishu_cookie.sh" "${TARGET_DIR}/download_feishu_cookie.sh"
install_script "${FEISHU_DIR}/download_feishu_config.sh" "${TARGET_DIR}/download_feishu_config.sh"
echo "更新--- ${TARGET_DIR}/download_feishu_config.sh 成功----"
cp "${FEISHU_DIR}/download_feishu_request_kp31.curl" "${TARGET_DIR}/download_feishu_request_kp31.curl"
echo "更新--- ${TARGET_DIR}/download_feishu_request_kp31.curl 成功----"
cp "${FEISHU_DIR}/download_feishu_request_d01.curl" "${TARGET_DIR}/download_feishu_request_d01.curl"
echo "更新--- ${TARGET_DIR}/download_feishu_request_d01.curl 成功----"
cp "${FEISHU_DIR}/download_feishu_request_d01_int.curl" "${TARGET_DIR}/download_feishu_request_d01_int.curl"
echo "更新--- ${TARGET_DIR}/download_feishu_request_d01_int.curl 成功----"

echo "===== 更新 Iflytek 脚本 ====="
rm -f \
  "${TARGET_DIR}/update_d01_Int_sys" \
  "${TARGET_DIR}/update_d01_Int_sys.sh" \
  "${TARGET_DIR}/update_d01_Int_sys_setting" \
  "${TARGET_DIR}/update_d01_Int_sys_setting.sh" \
  "${TARGET_DIR}/update_d01_sys" \
  "${TARGET_DIR}/update_d01_sys.sh" \
  "${TARGET_DIR}/update_d01_sys_setting" \
  "${TARGET_DIR}/update_d01_sys_setting.sh" \
  "${TARGET_DIR}/update_d01p_int_sys" \
  "${TARGET_DIR}/update_d01p_int_sys.sh" \
  "${TARGET_DIR}/update_kp31_int_sys" \
  "${TARGET_DIR}/update_kp31_int_sys.sh" \
  "${TARGET_DIR}/update_kp31_sys" \
  "${TARGET_DIR}/update_kp31_sys.sh" \
  "${TARGET_DIR}/updateIflytekSysScript" \
  "${TARGET_DIR}/updateD01IntSys" \
  "${TARGET_DIR}/updated01IntSys" \
  "${TARGET_DIR}/updateDO1IntSys" \
  "${TARGET_DIR}/updatedo1IntSys" \
  "${TARGET_DIR}/updateD01intSys" \
  "${TARGET_DIR}/updateDO1intSys" \
  "${TARGET_DIR}/updatedo1intSys" \
  "${TARGET_DIR}/updated01intSys" \
  "${TARGET_DIR}/updateD01IntSysSetting" \
  "${TARGET_DIR}/updated01IntSysSetting" \
  "${TARGET_DIR}/updateDO1IntSysSetting" \
  "${TARGET_DIR}/updatedo1IntSysSetting" \
  "${TARGET_DIR}/updateD01intSysSetting" \
  "${TARGET_DIR}/updateDO1intSysSetting" \
  "${TARGET_DIR}/updatedo1intSysSetting" \
  "${TARGET_DIR}/updated01intSysSetting" \
  "${TARGET_DIR}/updateD01Sys" \
  "${TARGET_DIR}/updated01Sys" \
  "${TARGET_DIR}/updateDO1Sys" \
  "${TARGET_DIR}/updatedo1Sys" \
  "${TARGET_DIR}/updateD01sys" \
  "${TARGET_DIR}/updateDO1sys" \
  "${TARGET_DIR}/updatedo1sys" \
  "${TARGET_DIR}/updated01sys" \
  "${TARGET_DIR}/updateD01SysSetting" \
  "${TARGET_DIR}/updated01SysSetting" \
  "${TARGET_DIR}/updateDO1SysSetting" \
  "${TARGET_DIR}/updatedo1SysSetting" \
  "${TARGET_DIR}/updateD01sysSetting" \
  "${TARGET_DIR}/updateDO1sysSetting" \
  "${TARGET_DIR}/updatedo1sysSetting" \
  "${TARGET_DIR}/updated01sysSetting" \
  "${TARGET_DIR}/replaceLocal" \
  "${TARGET_DIR}/replacelocal" \
  "${TARGET_DIR}/replace_local" \
  "${TARGET_DIR}/replace_local.sh" \
  "${TARGET_DIR}/replaceLocalD01p" \
  "${TARGET_DIR}/replacelocald01p" \
  "${TARGET_DIR}/replaceLocalDO1p" \
  "${TARGET_DIR}/replacelocaldo1p" \
  "${TARGET_DIR}/replace_local_d01p" \
  "${TARGET_DIR}/replace_local_d01p.sh" \
  "${TARGET_DIR}/replaceOut" \
  "${TARGET_DIR}/replaceout" \
  "${TARGET_DIR}/replace_out" \
  "${TARGET_DIR}/replace_out.sh" \
  "${TARGET_DIR}/replaceOutD01p" \
  "${TARGET_DIR}/replaceoutd01p" \
  "${TARGET_DIR}/replaceOutDO1p" \
  "${TARGET_DIR}/replaceoutdo1p" \
  "${TARGET_DIR}/replace_out_d01p" \
  "${TARGET_DIR}/replace_out_d01p.sh" \
  "${TARGET_DIR}/updateD01pIntSys" \
  "${TARGET_DIR}/updated01pIntSys" \
  "${TARGET_DIR}/updateDO1pIntSys" \
  "${TARGET_DIR}/updatedo1pIntSys" \
  "${TARGET_DIR}/updateD01pintSys" \
  "${TARGET_DIR}/updateDO1pintSys" \
  "${TARGET_DIR}/updatedo1pintSys" \
  "${TARGET_DIR}/updated01pintSys" \
  "${TARGET_DIR}/updateKp31IntSys" \
  "${TARGET_DIR}/updatekp31IntSys" \
  "${TARGET_DIR}/updateKp31intSys" \
  "${TARGET_DIR}/updatekp31intSys" \
  "${TARGET_DIR}/updateKp31Sys" \
  "${TARGET_DIR}/updatekp31Sys" \
  "${TARGET_DIR}/updateKp31sys" \
  "${TARGET_DIR}/updatekp31sys" \
  "${TARGET_DIR}/update_iflytek_res_d01" \
  "${TARGET_DIR}/update_iflytek_res_d01.sh" \
  "${TARGET_DIR}/updateIflytekResD01" \
  "${TARGET_DIR}/updateiflytekResD01" \
  "${TARGET_DIR}/updateIflytekResd01" \
  "${TARGET_DIR}/updateiflytekresd01" \
  "${TARGET_DIR}/updateIflytekResDO1" \
  "${TARGET_DIR}/updateiflytekResDO1" \
  "${TARGET_DIR}/updateIflytekResdo1" \
  "${TARGET_DIR}/updateiflytekresdo1" \
  "${TARGET_DIR}/update_iflytek_res_d01_int" \
  "${TARGET_DIR}/update_iflytek_res_d01_int.sh" \
  "${TARGET_DIR}/updateIflytekResD01Int" \
  "${TARGET_DIR}/updateiflytekResD01Int" \
  "${TARGET_DIR}/updateIflytekResd01Int" \
  "${TARGET_DIR}/updateiflytekresd01Int" \
  "${TARGET_DIR}/updateIflytekResDO1Int" \
  "${TARGET_DIR}/updateiflytekResDO1Int" \
  "${TARGET_DIR}/updateIflytekResdo1Int" \
  "${TARGET_DIR}/updateiflytekresdo1Int" \
  "${TARGET_DIR}/updateIflytekResD01int" \
  "${TARGET_DIR}/updateiflytekResD01int" \
  "${TARGET_DIR}/updateIflytekResd01int" \
  "${TARGET_DIR}/updateiflytekresd01int" \
  "${TARGET_DIR}/updateIflytekResDO1int" \
  "${TARGET_DIR}/updateiflytekResDO1int" \
  "${TARGET_DIR}/updateIflytekResdo1int" \
  "${TARGET_DIR}/updateiflytekresdo1int" \
  "${TARGET_DIR}/update_iflytek_res_kp31" \
  "${TARGET_DIR}/update_iflytek_res_kp31.sh" \
  "${TARGET_DIR}/updateIflytekResKp31" \
  "${TARGET_DIR}/updateiflytekResKp31" \
  "${TARGET_DIR}/updateIflytekReskp31" \
  "${TARGET_DIR}/updateiflytekreskp31"

install_script "${IFLYTEK_DIR}/update_d01_Int_sys.sh" "${TARGET_DIR}/updateD01IntSys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/updated01IntSys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/updateDO1IntSys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/updatedo1IntSys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/updateD01intSys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/updateDO1intSys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/updatedo1intSys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/updated01intSys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/update_d01_Int_sys"
ln -sf "${TARGET_DIR}/updateD01IntSys" "${TARGET_DIR}/update_d01_Int_sys.sh"
echo "更新--- ${TARGET_DIR}/updateD01IntSys 成功----"

install_script "${IFLYTEK_DIR}/update_d01_Int_sys_setting.sh" "${TARGET_DIR}/updateD01IntSysSetting"
ln -sf "${TARGET_DIR}/updateD01IntSysSetting" "${TARGET_DIR}/updated01IntSysSetting"
ln -sf "${TARGET_DIR}/updateD01IntSysSetting" "${TARGET_DIR}/updateDO1IntSysSetting"
ln -sf "${TARGET_DIR}/updateD01IntSysSetting" "${TARGET_DIR}/updatedo1IntSysSetting"
ln -sf "${TARGET_DIR}/updateD01IntSysSetting" "${TARGET_DIR}/updateD01intSysSetting"
ln -sf "${TARGET_DIR}/updateD01IntSysSetting" "${TARGET_DIR}/updateDO1intSysSetting"
ln -sf "${TARGET_DIR}/updateD01IntSysSetting" "${TARGET_DIR}/updatedo1intSysSetting"
ln -sf "${TARGET_DIR}/updateD01IntSysSetting" "${TARGET_DIR}/updated01intSysSetting"
ln -sf "${TARGET_DIR}/updateD01IntSysSetting" "${TARGET_DIR}/update_d01_Int_sys_setting"
ln -sf "${TARGET_DIR}/updateD01IntSysSetting" "${TARGET_DIR}/update_d01_Int_sys_setting.sh"
echo "更新--- ${TARGET_DIR}/updateD01IntSysSetting 成功----"

install_script "${IFLYTEK_DIR}/update_d01_sys.sh" "${TARGET_DIR}/updateD01Sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/updated01Sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/updateDO1Sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/updatedo1Sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/updateD01sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/updateDO1sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/updatedo1sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/updated01sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/update_d01_sys"
ln -sf "${TARGET_DIR}/updateD01Sys" "${TARGET_DIR}/update_d01_sys.sh"
echo "更新--- ${TARGET_DIR}/updateD01Sys 成功----"

install_script "${IFLYTEK_DIR}/update_d01_sys_setting.sh" "${TARGET_DIR}/updateD01SysSetting"
ln -sf "${TARGET_DIR}/updateD01SysSetting" "${TARGET_DIR}/updated01SysSetting"
ln -sf "${TARGET_DIR}/updateD01SysSetting" "${TARGET_DIR}/updateDO1SysSetting"
ln -sf "${TARGET_DIR}/updateD01SysSetting" "${TARGET_DIR}/updatedo1SysSetting"
ln -sf "${TARGET_DIR}/updateD01SysSetting" "${TARGET_DIR}/updateD01sysSetting"
ln -sf "${TARGET_DIR}/updateD01SysSetting" "${TARGET_DIR}/updateDO1sysSetting"
ln -sf "${TARGET_DIR}/updateD01SysSetting" "${TARGET_DIR}/updatedo1sysSetting"
ln -sf "${TARGET_DIR}/updateD01SysSetting" "${TARGET_DIR}/updated01sysSetting"
ln -sf "${TARGET_DIR}/updateD01SysSetting" "${TARGET_DIR}/update_d01_sys_setting"
ln -sf "${TARGET_DIR}/updateD01SysSetting" "${TARGET_DIR}/update_d01_sys_setting.sh"
echo "更新--- ${TARGET_DIR}/updateD01SysSetting 成功----"

# replace* 发布正式名 + 全小写别名（小写可直接 Tab/执行）；去掉 replace_out.sh 等杂别名。
# do1 另发 DO1 别名。旧的 replace_local.sh 等仍在上方 stale 列表删除。
install_script "${IFLYTEK_DIR}/replace_local.sh" "${TARGET_DIR}/replaceLocal"
ln -sf "${TARGET_DIR}/replaceLocal" "${TARGET_DIR}/replacelocal"
echo "更新--- ${TARGET_DIR}/replaceLocal 成功----"

install_script "${IFLYTEK_DIR}/replace_local_d01p.sh" "${TARGET_DIR}/replaceLocalD01p"
ln -sf "${TARGET_DIR}/replaceLocalD01p" "${TARGET_DIR}/replacelocald01p"
ln -sf "${TARGET_DIR}/replaceLocalD01p" "${TARGET_DIR}/replaceLocalDO1p"
ln -sf "${TARGET_DIR}/replaceLocalD01p" "${TARGET_DIR}/replacelocaldo1p"
echo "更新--- ${TARGET_DIR}/replaceLocalD01p 成功----"

install_script "${IFLYTEK_DIR}/replace_out.sh" "${TARGET_DIR}/replaceOut"
ln -sf "${TARGET_DIR}/replaceOut" "${TARGET_DIR}/replaceout"
echo "更新--- ${TARGET_DIR}/replaceOut 成功----"

install_script "${IFLYTEK_DIR}/replace_out_d01p.sh" "${TARGET_DIR}/replaceOutD01p"
ln -sf "${TARGET_DIR}/replaceOutD01p" "${TARGET_DIR}/replaceoutd01p"
ln -sf "${TARGET_DIR}/replaceOutD01p" "${TARGET_DIR}/replaceOutDO1p"
ln -sf "${TARGET_DIR}/replaceOutD01p" "${TARGET_DIR}/replaceoutdo1p"
echo "更新--- ${TARGET_DIR}/replaceOutD01p 成功----"

install_script "${IFLYTEK_DIR}/update_d01p_int_sys.sh" "${TARGET_DIR}/updateD01pIntSys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/updated01pIntSys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/updateDO1pIntSys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/updatedo1pIntSys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/updateD01pintSys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/updateDO1pintSys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/updatedo1pintSys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/updated01pintSys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/update_d01p_int_sys"
ln -sf "${TARGET_DIR}/updateD01pIntSys" "${TARGET_DIR}/update_d01p_int_sys.sh"
echo "更新--- ${TARGET_DIR}/updateD01pIntSys 成功----"

install_script "${IFLYTEK_DIR}/update_kp31_int_sys.sh" "${TARGET_DIR}/updateKp31IntSys"
ln -sf "${TARGET_DIR}/updateKp31IntSys" "${TARGET_DIR}/updatekp31IntSys"
ln -sf "${TARGET_DIR}/updateKp31IntSys" "${TARGET_DIR}/updateKp31intSys"
ln -sf "${TARGET_DIR}/updateKp31IntSys" "${TARGET_DIR}/updatekp31intSys"
ln -sf "${TARGET_DIR}/updateKp31IntSys" "${TARGET_DIR}/update_kp31_int_sys"
ln -sf "${TARGET_DIR}/updateKp31IntSys" "${TARGET_DIR}/update_kp31_int_sys.sh"
echo "更新--- ${TARGET_DIR}/updateKp31IntSys 成功----"

install_script "${IFLYTEK_DIR}/update_kp31_sys.sh" "${TARGET_DIR}/updateKp31Sys"
ln -sf "${TARGET_DIR}/updateKp31Sys" "${TARGET_DIR}/updatekp31Sys"
ln -sf "${TARGET_DIR}/updateKp31Sys" "${TARGET_DIR}/updateKp31sys"
ln -sf "${TARGET_DIR}/updateKp31Sys" "${TARGET_DIR}/updatekp31sys"
ln -sf "${TARGET_DIR}/updateKp31Sys" "${TARGET_DIR}/update_kp31_sys"
ln -sf "${TARGET_DIR}/updateKp31Sys" "${TARGET_DIR}/update_kp31_sys.sh"
echo "更新--- ${TARGET_DIR}/updateKp31Sys 成功----"

install_script "${IFLYTEK_DIR}/update_iflytek_res_d01.sh" "${TARGET_DIR}/updateIflytekResD01"
ln -sf "${TARGET_DIR}/updateIflytekResD01" "${TARGET_DIR}/updateiflytekResD01"
ln -sf "${TARGET_DIR}/updateIflytekResD01" "${TARGET_DIR}/updateIflytekResd01"
ln -sf "${TARGET_DIR}/updateIflytekResD01" "${TARGET_DIR}/updateiflytekresd01"
ln -sf "${TARGET_DIR}/updateIflytekResD01" "${TARGET_DIR}/updateIflytekResDO1"
ln -sf "${TARGET_DIR}/updateIflytekResD01" "${TARGET_DIR}/updateiflytekResDO1"
ln -sf "${TARGET_DIR}/updateIflytekResD01" "${TARGET_DIR}/updateIflytekResdo1"
ln -sf "${TARGET_DIR}/updateIflytekResD01" "${TARGET_DIR}/updateiflytekresdo1"
ln -sf "${TARGET_DIR}/updateIflytekResD01" "${TARGET_DIR}/update_iflytek_res_d01"
ln -sf "${TARGET_DIR}/updateIflytekResD01" "${TARGET_DIR}/update_iflytek_res_d01.sh"
echo "更新--- ${TARGET_DIR}/updateIflytekResD01 成功----"

install_script "${IFLYTEK_DIR}/update_iflytek_res_d01_int.sh" "${TARGET_DIR}/updateIflytekResD01Int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateiflytekResD01Int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateIflytekResd01Int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateiflytekresd01Int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateIflytekResDO1Int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateiflytekResDO1Int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateIflytekResdo1Int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateiflytekresdo1Int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateIflytekResD01int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateiflytekResD01int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateIflytekResd01int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateiflytekresd01int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateIflytekResDO1int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateiflytekResDO1int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateIflytekResdo1int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/updateiflytekresdo1int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/update_iflytek_res_d01_int"
ln -sf "${TARGET_DIR}/updateIflytekResD01Int" "${TARGET_DIR}/update_iflytek_res_d01_int.sh"
echo "更新--- ${TARGET_DIR}/updateIflytekResD01Int 成功----"

install_script "${IFLYTEK_DIR}/update_iflytek_res_kp31.sh" "${TARGET_DIR}/updateIflytekResKp31"
ln -sf "${TARGET_DIR}/updateIflytekResKp31" "${TARGET_DIR}/updateiflytekResKp31"
ln -sf "${TARGET_DIR}/updateIflytekResKp31" "${TARGET_DIR}/updateIflytekReskp31"
ln -sf "${TARGET_DIR}/updateIflytekResKp31" "${TARGET_DIR}/updateiflytekreskp31"
ln -sf "${TARGET_DIR}/updateIflytekResKp31" "${TARGET_DIR}/update_iflytek_res_kp31"
ln -sf "${TARGET_DIR}/updateIflytekResKp31" "${TARGET_DIR}/update_iflytek_res_kp31.sh"
echo "更新--- ${TARGET_DIR}/updateIflytekResKp31 成功----"

ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updateIflytekSysScript"
echo "更新--- ${TARGET_DIR}/updateIflytekSysScript 成功----"

echo "===== 更新 Voice Build 脚本 ====="
rm -f   "${TARGET_DIR}/voice_build_common.sh"   "${TARGET_DIR}/voice_assistant_d01"   "${TARGET_DIR}/voice_assistant_kp31"   "${TARGET_DIR}/voice_assistant_t12a"   "${TARGET_DIR}/voice_setting_d01"   "${TARGET_DIR}/voice_setting_kp31"   "${TARGET_DIR}/voiceAssistantD01"   "${TARGET_DIR}/voiceassistantD01"   "${TARGET_DIR}/voiceAssistantDO1"   "${TARGET_DIR}/voiceassistantDO1"   "${TARGET_DIR}/voiceAssistantd01"   "${TARGET_DIR}/voiceassistantd01"   "${TARGET_DIR}/voiceAssistantdo1"   "${TARGET_DIR}/voiceassistantdo1"   "${TARGET_DIR}/voiceAssistantKp31"   "${TARGET_DIR}/voiceassistantKp31"   "${TARGET_DIR}/voiceAssistantkp31"   "${TARGET_DIR}/voiceassistantkp31"   "${TARGET_DIR}/voiceAssistantT12a"   "${TARGET_DIR}/voiceassistantT12a"   "${TARGET_DIR}/voiceAssistantt12a"   "${TARGET_DIR}/voiceassistantt12a"   "${TARGET_DIR}/voiceSettingD01"   "${TARGET_DIR}/voicesettingD01"   "${TARGET_DIR}/voiceSettingDO1"   "${TARGET_DIR}/voicesettingDO1"   "${TARGET_DIR}/voiceSettingd01"   "${TARGET_DIR}/voicesettingd01"   "${TARGET_DIR}/voiceSettingdo1"   "${TARGET_DIR}/voicesettingdo1"   "${TARGET_DIR}/voiceSettingKp31"   "${TARGET_DIR}/voicesettingKp31"   "${TARGET_DIR}/voiceSettingkp31"   "${TARGET_DIR}/voicesettingkp31"   "${TARGET_DIR}/update_voice_build_script"   "${TARGET_DIR}/restartSystemUi"   "${TARGET_DIR}/restartsystemUi"   "${TARGET_DIR}/restartSystemui"   "${TARGET_DIR}/restartsystemui"   "${TARGET_DIR}/rsui"   "${TARGET_DIR}/Rsui"   "${TARGET_DIR}/RSui"   "${TARGET_DIR}/RSUI"   "${TARGET_DIR}/RsUi"   "${TARGET_DIR}/RsUI"   "${TARGET_DIR}/RsuI"   "${TARGET_DIR}/RSuI"   "${TARGET_DIR}/rSui"   "${TARGET_DIR}/rSUi"   "${TARGET_DIR}/rSUI"   "${TARGET_DIR}/rsUi"   "${TARGET_DIR}/rsUI"   "${TARGET_DIR}/rsuI"   "${TARGET_DIR}/rSuI"

install_script "${VOICE_BUILD_DIR}/voice_build_common.sh" "${TARGET_DIR}/voice_build_common.sh"
echo "更新--- ${TARGET_DIR}/voice_build_common.sh 成功----"

install_script "${VOICE_BUILD_DIR}/voice_assistant_d01.sh" "${TARGET_DIR}/voiceAssistantD01"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voiceassistantD01"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voiceAssistantDO1"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voiceassistantDO1"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voiceAssistantd01"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voiceassistantd01"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voiceAssistantdo1"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voiceassistantdo1"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voice_assistant_d01"
echo "更新--- ${TARGET_DIR}/voiceAssistantD01 成功----"

install_script "${VOICE_BUILD_DIR}/voice_setting_d01.sh" "${TARGET_DIR}/voiceSettingD01"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voicesettingD01"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voiceSettingDO1"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voicesettingDO1"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voiceSettingd01"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voicesettingd01"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voiceSettingdo1"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voicesettingdo1"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voice_setting_d01"
echo "更新--- ${TARGET_DIR}/voiceSettingD01 成功----"

install_script "${VOICE_BUILD_DIR}/voice_assistant_kp31.sh" "${TARGET_DIR}/voiceAssistantKp31"
ln -sf "${TARGET_DIR}/voiceAssistantKp31" "${TARGET_DIR}/voiceassistantKp31"
ln -sf "${TARGET_DIR}/voiceAssistantKp31" "${TARGET_DIR}/voiceAssistantkp31"
ln -sf "${TARGET_DIR}/voiceAssistantKp31" "${TARGET_DIR}/voiceassistantkp31"
ln -sf "${TARGET_DIR}/voiceAssistantKp31" "${TARGET_DIR}/voice_assistant_kp31"
echo "更新--- ${TARGET_DIR}/voiceAssistantKp31 成功----"

install_script "${VOICE_BUILD_DIR}/voice_setting_kp31.sh" "${TARGET_DIR}/voiceSettingKp31"
ln -sf "${TARGET_DIR}/voiceSettingKp31" "${TARGET_DIR}/voicesettingKp31"
ln -sf "${TARGET_DIR}/voiceSettingKp31" "${TARGET_DIR}/voiceSettingkp31"
ln -sf "${TARGET_DIR}/voiceSettingKp31" "${TARGET_DIR}/voicesettingkp31"
ln -sf "${TARGET_DIR}/voiceSettingKp31" "${TARGET_DIR}/voice_setting_kp31"
echo "更新--- ${TARGET_DIR}/voiceSettingKp31 成功----"

install_script "${VOICE_BUILD_DIR}/voice_assistant_t12a.sh" "${TARGET_DIR}/voiceAssistantT12a"
ln -sf "${TARGET_DIR}/voiceAssistantT12a" "${TARGET_DIR}/voiceassistantT12a"
ln -sf "${TARGET_DIR}/voiceAssistantT12a" "${TARGET_DIR}/voiceAssistantt12a"
ln -sf "${TARGET_DIR}/voiceAssistantT12a" "${TARGET_DIR}/voiceassistantt12a"
ln -sf "${TARGET_DIR}/voiceAssistantT12a" "${TARGET_DIR}/voice_assistant_t12a"
echo "更新--- ${TARGET_DIR}/voiceAssistantT12a 成功----"

install_script "${VOICE_BUILD_DIR}/make_voice_assistant_api_kp31.sh" "${TARGET_DIR}/makeVoiceAssistantApiKp31"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiKp31" "${TARGET_DIR}/makevoiceAssistantApiKp31"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiKp31" "${TARGET_DIR}/makeVoiceAssistantApikp31"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiKp31" "${TARGET_DIR}/makevoiceAssistantApikp31"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiKp31" "${TARGET_DIR}/makevoiceassistantapikp31"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiKp31" "${TARGET_DIR}/make_voice_assistant_api_kp31"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiKp31" "${TARGET_DIR}/make_voice_assistant_api_kp31.sh"
echo "更新--- ${TARGET_DIR}/makeVoiceAssistantApiKp31 成功----"

install_script "${VOICE_BUILD_DIR}/make_voice_assistant_api_d01.sh" "${TARGET_DIR}/makeVoiceAssistantApiD01"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiD01" "${TARGET_DIR}/makevoiceAssistantApiD01"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiD01" "${TARGET_DIR}/makeVoiceAssistantApiDO1"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiD01" "${TARGET_DIR}/makevoiceAssistantApiDO1"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiD01" "${TARGET_DIR}/makeVoiceAssistantApid01"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiD01" "${TARGET_DIR}/makevoiceAssistantApid01"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiD01" "${TARGET_DIR}/makevoiceassistantapid01"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiD01" "${TARGET_DIR}/makeVoiceAssistantApido1"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiD01" "${TARGET_DIR}/makevoiceAssistantApido1"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiD01" "${TARGET_DIR}/makevoiceassistantapido1"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiD01" "${TARGET_DIR}/make_voice_assistant_api_d01"
ln -sf "${TARGET_DIR}/makeVoiceAssistantApiD01" "${TARGET_DIR}/make_voice_assistant_api_d01.sh"
echo "更新--- ${TARGET_DIR}/makeVoiceAssistantApiD01 成功----"

ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/update_voice_build_script"
echo "更新--- ${TARGET_DIR}/update_voice_build_script 成功----"

echo "===== 更新日志脚本 ====="
rm -f   "${TARGET_DIR}/start_random_log"   "${TARGET_DIR}/stop_random_log"   "${TARGET_DIR}/startRandomLog"   "${TARGET_DIR}/startrandomLog"   "${TARGET_DIR}/startRandomlog"   "${TARGET_DIR}/startrandomlog"   "${TARGET_DIR}/stopRandomLog"   "${TARGET_DIR}/stoprandomLog"   "${TARGET_DIR}/stopRandomlog"   "${TARGET_DIR}/stoprandomlog"   "${TARGET_DIR}/pull_logcat_by_adb"   "${TARGET_DIR}/pullLogcatByAdb"   "${TARGET_DIR}/pullLogcatbyAdb"   "${TARGET_DIR}/pulllogcatByAdb"   "${TARGET_DIR}/pulllogcatbyAdb"   "${TARGET_DIR}/clear_logcat_by_adb"   "${TARGET_DIR}/clearLogcatByAdb"   "${TARGET_DIR}/clearlogcatByAdb"   "${TARGET_DIR}/clearLogcatbyAdb"   "${TARGET_DIR}/clearlogcatbyAdb"   "${TARGET_DIR}/update_random_log_script"   "${TARGET_DIR}/update_pull_logcat_by_adb"   "${TARGET_DIR}/updatePullLogcatByAdb"   "${TARGET_DIR}/updatepullLogcatByAdb"   "${TARGET_DIR}/updatePullLogcatbyAdb"   "${TARGET_DIR}/updatepullLogcatbyAdb"   "${TARGET_DIR}/update_clear_logcat_by_adb"   "${TARGET_DIR}/updateClearLogcatByAdb"   "${TARGET_DIR}/updateclearLogcatByAdb"   "${TARGET_DIR}/updateClearLogcatbyAdb"   "${TARGET_DIR}/updateclearLogcatbyAdb"

install_script "${LOGCAT_DIR}/start_random_log.sh" "${TARGET_DIR}/startRandomLog"
ln -sf "${TARGET_DIR}/startRandomLog" "${TARGET_DIR}/startrandomLog"
ln -sf "${TARGET_DIR}/startRandomLog" "${TARGET_DIR}/startRandomlog"
ln -sf "${TARGET_DIR}/startRandomLog" "${TARGET_DIR}/startrandomlog"
ln -sf "${TARGET_DIR}/startRandomLog" "${TARGET_DIR}/start_random_log"
echo "更新--- ${TARGET_DIR}/startRandomLog 成功----"

install_script "${LOGCAT_DIR}/stop_random_log.sh" "${TARGET_DIR}/stopRandomLog"
ln -sf "${TARGET_DIR}/stopRandomLog" "${TARGET_DIR}/stoprandomLog"
ln -sf "${TARGET_DIR}/stopRandomLog" "${TARGET_DIR}/stopRandomlog"
ln -sf "${TARGET_DIR}/stopRandomLog" "${TARGET_DIR}/stoprandomlog"
ln -sf "${TARGET_DIR}/stopRandomLog" "${TARGET_DIR}/stop_random_log"
echo "更新--- ${TARGET_DIR}/stopRandomLog 成功----"

install_script "${LOGCAT_DIR}/pull_logcat_by_adb.sh" "${TARGET_DIR}/pullLogcatByAdb"
ln -sf "${TARGET_DIR}/pullLogcatByAdb" "${TARGET_DIR}/pullLogcatbyAdb"
ln -sf "${TARGET_DIR}/pullLogcatByAdb" "${TARGET_DIR}/pulllogcatByAdb"
ln -sf "${TARGET_DIR}/pullLogcatByAdb" "${TARGET_DIR}/pulllogcatbyAdb"
ln -sf "${TARGET_DIR}/pullLogcatByAdb" "${TARGET_DIR}/pull_logcat_by_adb"
echo "更新--- ${TARGET_DIR}/pullLogcatByAdb 成功----"

install_script "${LOGCAT_DIR}/clear_logcat_by_adb.sh" "${TARGET_DIR}/clearLogcatByAdb"
ln -sf "${TARGET_DIR}/clearLogcatByAdb" "${TARGET_DIR}/clearlogcatByAdb"
ln -sf "${TARGET_DIR}/clearLogcatByAdb" "${TARGET_DIR}/clearLogcatbyAdb"
ln -sf "${TARGET_DIR}/clearLogcatByAdb" "${TARGET_DIR}/clearlogcatbyAdb"
ln -sf "${TARGET_DIR}/clearLogcatByAdb" "${TARGET_DIR}/clear_logcat_by_adb"
echo "更新--- ${TARGET_DIR}/clearLogcatByAdb 成功----"

echo "===== 更新通用工具 ====="
rm -f \
  "${TARGET_DIR}/startIflytekPage" \
  "${TARGET_DIR}/startiflytekPage" \
  "${TARGET_DIR}/startIflytekpage" \
  "${TARGET_DIR}/startiflytekpage" \
  "${TARGET_DIR}/start_iflytek_page" \
  "${TARGET_DIR}/startQnxD01" \
  "${TARGET_DIR}/startqnxD01" \
  "${TARGET_DIR}/startQnxDO1" \
  "${TARGET_DIR}/startqnxDO1" \
  "${TARGET_DIR}/startQnxd01" \
  "${TARGET_DIR}/startqnxd01" \
  "${TARGET_DIR}/startQnxdo1" \
  "${TARGET_DIR}/startqnxdo1" \
  "${TARGET_DIR}/start_qnx_d01" \
  "${TARGET_DIR}/rebootDevice" \
  "${TARGET_DIR}/rebootdevice" \
  "${TARGET_DIR}/reboot_device" \
  "${TARGET_DIR}/killSystemui" \
  "${TARGET_DIR}/killsystemUi" \
  "${TARGET_DIR}/killsystemui" \
  "${TARGET_DIR}/ksui" \
  "${TARGET_DIR}/Ksui" \
  "${TARGET_DIR}/KSui" \
  "${TARGET_DIR}/KSUI" \
  "${TARGET_DIR}/KsUi" \
  "${TARGET_DIR}/KsUI" \
  "${TARGET_DIR}/KsuI" \
  "${TARGET_DIR}/KSuI" \
  "${TARGET_DIR}/kSui" \
  "${TARGET_DIR}/kSUi" \
  "${TARGET_DIR}/kSUI" \
  "${TARGET_DIR}/ksUi" \
  "${TARGET_DIR}/ksUI" \
  "${TARGET_DIR}/ksuI" \
  "${TARGET_DIR}/kSuI" \
  "${TARGET_DIR}/voiceBtClick" \
  "${TARGET_DIR}/voicebtClick" \
  "${TARGET_DIR}/voiceBtclick" \
  "/voicebtclick" \
  "/setUUIDKP31" \
  "/setUuidKP31" \
  "/setUUIDKp31" \
  "/setUuidKp31" \
  "/setuuidKP31" \
  "/setuuidKp31" \
  "/setuuidkp31" \
  "/set_uuid_kp31" \
  "/update_rename_usb_dir" \
  "${TARGET_DIR}/updateRenameUsbDir" \
  "${TARGET_DIR}/updaterenameUsbDir" \
  "${TARGET_DIR}/updateRenameUsbdir" \
  "${TARGET_DIR}/updaterenameUsbdir" \
  "${TARGET_DIR}/renameUsbDir" \
  "${TARGET_DIR}/renameusbDir" \
  "${TARGET_DIR}/renameUsbdir" \
  "${TARGET_DIR}/renameusbdir" \
  "${TARGET_DIR}/rename_usb_dir" \
  "${TARGET_DIR}/update_virt_manager_script" \
  "${TARGET_DIR}/updateVirtManagerScript" \
  "${TARGET_DIR}/updatevirtManagerScript" \
  "${TARGET_DIR}/updateVirtmanagerScript" \
  "${TARGET_DIR}/updatevirtmanagerScript" \
  "${TARGET_DIR}/virtManager" \
  "${TARGET_DIR}/virtmanager" \
  "${TARGET_DIR}/startVirtManager" \
  "${TARGET_DIR}/startvirtManager" \
  "${TARGET_DIR}/startVirtmanager" \
  "${TARGET_DIR}/startvirtmanager" \
  "${TARGET_DIR}/start_virt_manager" \
  "${TARGET_DIR}/startWin10" \
  "${TARGET_DIR}/STARTWIN10" \
  "${TARGET_DIR}/StartWin10" \
  "${TARGET_DIR}/startwin10" \
  "${TARGET_DIR}/Startwin10" \
  "${TARGET_DIR}/startWIN10" \
  "${TARGET_DIR}/startWin10Pct" \
  "${TARGET_DIR}/startwin10pct" \
  "${TARGET_DIR}/startWin10PCT" \
  "${TARGET_DIR}/start_win10_pct" \
  "${TARGET_DIR}/start_win10" \
  "${TARGET_DIR}/start-win10" \
  "${TARGET_DIR}/win10pct" \
  "${TARGET_DIR}/Win10Pct" \
  "${TARGET_DIR}/WIN10PCT" \
  "${TARGET_DIR}/closeWin10" \
  "${TARGET_DIR}/CLOSEWIN10" \
  "${TARGET_DIR}/CloseWin10" \
  "${TARGET_DIR}/closewin10" \
  "${TARGET_DIR}/Closewin10" \
  "${TARGET_DIR}/closeWIN10" \
  "${TARGET_DIR}/close_win10" \
  "${TARGET_DIR}/close-win10" \
  "${TARGET_DIR}/stopWin10" \
  "${TARGET_DIR}/STOPWIN10" \
  "${TARGET_DIR}/stopwin10" \
  "${TARGET_DIR}/stop_win10" \
  "${TARGET_DIR}/startBootGuide" \
  "${TARGET_DIR}/startbootGuide" \
  "${TARGET_DIR}/startBootguide" \
  "${TARGET_DIR}/startbootguide" \
  "${TARGET_DIR}/start_boot_guide" \
  "${TARGET_DIR}/startBootGuideKP31" \
  "${TARGET_DIR}/startBootGuideKp31" \
  "${TARGET_DIR}/startbootGuideKP31" \
  "${TARGET_DIR}/startbootguidekp31" \
  "${TARGET_DIR}/start_boot_guide_kp31" \
  "${TARGET_DIR}/resetVat" \
  "${TARGET_DIR}/resetvat" \
  "${TARGET_DIR}/ResetVat" \
  "${TARGET_DIR}/RESETVAT" \
  "${TARGET_DIR}/reset_vat" \
  "${TARGET_DIR}/resetVst" \
  "${TARGET_DIR}/resetvst" \
  "${TARGET_DIR}/ResetVst" \
  "${TARGET_DIR}/RESETVST" \
  "${TARGET_DIR}/reset_vst" \
  "${TARGET_DIR}/setSalesArea" \
  "${TARGET_DIR}/setsalesarea" \
  "${TARGET_DIR}/SetSalesArea" \
  "${TARGET_DIR}/SETSALESAREA" \
  "${TARGET_DIR}/set_sales_area"

install_script "${COMMON_TOOL_DIR}/start_iflytek_page.sh" "${TARGET_DIR}/startIflytekPage"
ln -sf "${TARGET_DIR}/startIflytekPage" "${TARGET_DIR}/startiflytekPage"
ln -sf "${TARGET_DIR}/startIflytekPage" "${TARGET_DIR}/startIflytekpage"
ln -sf "${TARGET_DIR}/startIflytekPage" "${TARGET_DIR}/startiflytekpage"
ln -sf "${TARGET_DIR}/startIflytekPage" "${TARGET_DIR}/start_iflytek_page"
echo "更新--- ${TARGET_DIR}/startIflytekPage 成功----"

install_script "${COMMON_TOOL_DIR}/start_qnx_d01.sh" "${TARGET_DIR}/startQnxD01"
ln -sf "${TARGET_DIR}/startQnxD01" "${TARGET_DIR}/startqnxD01"
ln -sf "${TARGET_DIR}/startQnxD01" "${TARGET_DIR}/startQnxDO1"
ln -sf "${TARGET_DIR}/startQnxD01" "${TARGET_DIR}/startqnxDO1"
ln -sf "${TARGET_DIR}/startQnxD01" "${TARGET_DIR}/startQnxd01"
ln -sf "${TARGET_DIR}/startQnxD01" "${TARGET_DIR}/startqnxd01"
ln -sf "${TARGET_DIR}/startQnxD01" "${TARGET_DIR}/startQnxdo1"
ln -sf "${TARGET_DIR}/startQnxD01" "${TARGET_DIR}/startqnxdo1"
ln -sf "${TARGET_DIR}/startQnxD01" "${TARGET_DIR}/start_qnx_d01"
echo "更新--- ${TARGET_DIR}/startQnxD01 成功----"

install_script "${COMMON_TOOL_DIR}/startBootGuideKP31.sh" "${TARGET_DIR}/startBootGuideKP31"
ln -sf "${TARGET_DIR}/startBootGuideKP31" "${TARGET_DIR}/startBootGuideKp31"
ln -sf "${TARGET_DIR}/startBootGuideKP31" "${TARGET_DIR}/startbootGuideKP31"
ln -sf "${TARGET_DIR}/startBootGuideKP31" "${TARGET_DIR}/startbootguidekp31"
ln -sf "${TARGET_DIR}/startBootGuideKP31" "${TARGET_DIR}/start_boot_guide_kp31"
echo "更新--- ${TARGET_DIR}/startBootGuideKP31 成功----"

install_script "${COMMON_TOOL_DIR}/reboot_device.sh" "${TARGET_DIR}/rebootDevice"
ln -sf "${TARGET_DIR}/rebootDevice" "${TARGET_DIR}/rebootdevice"
ln -sf "${TARGET_DIR}/rebootDevice" "${TARGET_DIR}/reboot_device"
echo "更新--- ${TARGET_DIR}/rebootDevice 成功----"

install_script "${COMMON_TOOL_DIR}/resetVat.sh" "${TARGET_DIR}/resetVat"
ln -sf "${TARGET_DIR}/resetVat" "${TARGET_DIR}/resetvat"
ln -sf "${TARGET_DIR}/resetVat" "${TARGET_DIR}/ResetVat"
ln -sf "${TARGET_DIR}/resetVat" "${TARGET_DIR}/RESETVAT"
ln -sf "${TARGET_DIR}/resetVat" "${TARGET_DIR}/reset_vat"
echo "更新--- ${TARGET_DIR}/resetVat 成功----"

install_script "${COMMON_TOOL_DIR}/resetVst.sh" "${TARGET_DIR}/resetVst"
ln -sf "${TARGET_DIR}/resetVst" "${TARGET_DIR}/resetvst"
ln -sf "${TARGET_DIR}/resetVst" "${TARGET_DIR}/ResetVst"
ln -sf "${TARGET_DIR}/resetVst" "${TARGET_DIR}/RESETVST"
ln -sf "${TARGET_DIR}/resetVst" "${TARGET_DIR}/reset_vst"
echo "更新--- ${TARGET_DIR}/resetVst 成功----"

install_script "${COMMON_TOOL_DIR}/kill_systemui.sh" "${TARGET_DIR}/killSystemui"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/killsystemUi"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/killsystemui"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/ksui"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/Ksui"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/KSui"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/KSUI"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/KsUi"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/KsUI"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/KsuI"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/KSuI"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/kSui"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/kSUi"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/kSUI"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/ksUi"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/ksUI"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/ksuI"
ln -sf "${TARGET_DIR}/killSystemui" "${TARGET_DIR}/kSuI"
install_script "${COMMON_TOOL_DIR}/voice_bt_click.sh" "${TARGET_DIR}/voiceBtClick"
ln -sf "${TARGET_DIR}/voiceBtClick" "${TARGET_DIR}/voicebtClick"
ln -sf "${TARGET_DIR}/voiceBtClick" "${TARGET_DIR}/voiceBtclick"
ln -sf "${TARGET_DIR}/voiceBtClick" "${TARGET_DIR}/voicebtclick"
ln -sf "${TARGET_DIR}/voiceBtClick" "${TARGET_DIR}/voice_bt_click"
ln -sf "${TARGET_DIR}/voiceBtClick" "${TARGET_DIR}/soundBtClick"
ln -sf "${TARGET_DIR}/voiceBtClick" "${TARGET_DIR}/soundbtClick"
ln -sf "${TARGET_DIR}/voiceBtClick" "${TARGET_DIR}/soundBtclick"
ln -sf "${TARGET_DIR}/voiceBtClick" "${TARGET_DIR}/soundbtclick"
echo "更新--- ${TARGET_DIR}/voiceBtClick 成功----"

install_script "${COMMON_TOOL_DIR}/setSalesArea.sh" "${TARGET_DIR}/setSalesArea"
ln -sf "${TARGET_DIR}/setSalesArea" "${TARGET_DIR}/setsalesarea"
ln -sf "${TARGET_DIR}/setSalesArea" "${TARGET_DIR}/SetSalesArea"
ln -sf "${TARGET_DIR}/setSalesArea" "${TARGET_DIR}/SETSALESAREA"
ln -sf "${TARGET_DIR}/setSalesArea" "${TARGET_DIR}/set_sales_area"
echo "更新--- ${TARGET_DIR}/setSalesArea 成功----"

install_script "${COMMON_TOOL_DIR}/setUUIDKP31.sh" "${TARGET_DIR}/setUUIDKP31"
ln -sf "${TARGET_DIR}/setUUIDKP31" "${TARGET_DIR}/setUuidKP31"
ln -sf "${TARGET_DIR}/setUUIDKP31" "${TARGET_DIR}/setUUIDKp31"
ln -sf "${TARGET_DIR}/setUUIDKP31" "${TARGET_DIR}/setUuidKp31"
ln -sf "${TARGET_DIR}/setUUIDKP31" "${TARGET_DIR}/setuuidKP31"
ln -sf "${TARGET_DIR}/setUUIDKP31" "${TARGET_DIR}/setuuidKp31"
ln -sf "${TARGET_DIR}/setUUIDKP31" "${TARGET_DIR}/setuuidkp31"
ln -sf "${TARGET_DIR}/setUUIDKP31" "${TARGET_DIR}/set_uuid_kp31"
echo "更新--- ${TARGET_DIR}/setUUIDKP31 成功----"

install_script "${COMMON_TOOL_DIR}/rename_usb_dir.sh" "${TARGET_DIR}/renameUsbDir"
ln -sf "${TARGET_DIR}/renameUsbDir" "${TARGET_DIR}/renameusbDir"
ln -sf "${TARGET_DIR}/renameUsbDir" "${TARGET_DIR}/renameUsbdir"
ln -sf "${TARGET_DIR}/renameUsbDir" "${TARGET_DIR}/renameusbdir"
ln -sf "${TARGET_DIR}/renameUsbDir" "${TARGET_DIR}/rename_usb_dir"
echo "更新--- ${TARGET_DIR}/renameUsbDir 成功----"

ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updateRenameUsbDir"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updaterenameUsbDir"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updateRenameUsbdir"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updaterenameUsbdir"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/update_rename_usb_dir"
echo "更新--- ${TARGET_DIR}/updateRenameUsbDir 成功----"

install_script "${COMMON_TOOL_DIR}/start_virt_manager.sh" "${TARGET_DIR}/virtManager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/virtmanager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/startVirtManager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/startvirtManager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/startVirtmanager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/startvirtmanager"
ln -sf "${TARGET_DIR}/virtManager" "${TARGET_DIR}/start_virt_manager"
echo "更新--- ${TARGET_DIR}/virtManager 成功----"

ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updateVirtManagerScript"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updatevirtManagerScript"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updateVirtmanagerScript"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updatevirtmanagerScript"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/update_virt_manager_script"
echo "更新--- ${TARGET_DIR}/updateVirtManagerScript 成功----"

if [ -f "${COMMON_TOOL_DIR}/virt_manager.desktop" ]; then
  install_desktop_shortcut "${COMMON_TOOL_DIR}/virt_manager.desktop" "virt-manager-shortcut.desktop"
fi

install_script "${COMMON_TOOL_DIR}/start_win10.sh" "${TARGET_DIR}/startWin10"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/STARTWIN10"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/StartWin10"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/startwin10"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/Startwin10"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/startWIN10"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/start_win10"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/start-win10"
# 兼容旧名
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/startWin10Pct"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/startwin10pct"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/startWin10PCT"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/start_win10_pct"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/win10pct"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/Win10Pct"
ln -sf "${TARGET_DIR}/startWin10" "${TARGET_DIR}/WIN10PCT"
echo "更新--- ${TARGET_DIR}/startWin10 成功----"

# 清理旧桌面文件名
rm -f "${APPLICATIONS_DIR}/start-win10-pct.desktop" "${DESKTOP_DIR}/start-win10-pct.desktop" 2>/dev/null || true
if [ -f "${COMMON_TOOL_DIR}/start_win10.desktop" ]; then
  install_desktop_shortcut "${COMMON_TOOL_DIR}/start_win10.desktop" "startWin10.desktop"
fi

install_script "${COMMON_TOOL_DIR}/close_win10.sh" "${TARGET_DIR}/closeWin10"
ln -sf "${TARGET_DIR}/closeWin10" "${TARGET_DIR}/CLOSEWIN10"
ln -sf "${TARGET_DIR}/closeWin10" "${TARGET_DIR}/CloseWin10"
ln -sf "${TARGET_DIR}/closeWin10" "${TARGET_DIR}/closewin10"
ln -sf "${TARGET_DIR}/closeWin10" "${TARGET_DIR}/Closewin10"
ln -sf "${TARGET_DIR}/closeWin10" "${TARGET_DIR}/closeWIN10"
ln -sf "${TARGET_DIR}/closeWin10" "${TARGET_DIR}/close_win10"
ln -sf "${TARGET_DIR}/closeWin10" "${TARGET_DIR}/close-win10"
ln -sf "${TARGET_DIR}/closeWin10" "${TARGET_DIR}/stopWin10"
ln -sf "${TARGET_DIR}/closeWin10" "${TARGET_DIR}/STOPWIN10"
ln -sf "${TARGET_DIR}/closeWin10" "${TARGET_DIR}/stopwin10"
ln -sf "${TARGET_DIR}/closeWin10" "${TARGET_DIR}/stop_win10"
echo "更新--- ${TARGET_DIR}/closeWin10 成功----"

if [ -f "${COMMON_TOOL_DIR}/close_win10.desktop" ]; then
  install_desktop_shortcut "${COMMON_TOOL_DIR}/close_win10.desktop" "closeWin10.desktop"
fi

# syncftu: Windows VM FileToUbuntu -> Ubuntu ~/FileToUbuntu
install_script "${COMMON_TOOL_DIR}/fix_virbr_route.sh" "${TARGET_DIR}/fixVirbrRoute"
install_script "${COMMON_TOOL_DIR}/sync_filetoubuntu.sh" "${TARGET_DIR}/syncftu"
ln -sf "${TARGET_DIR}/syncftu" "${TARGET_DIR}/SYNCFTU"
ln -sf "${TARGET_DIR}/syncftu" "${TARGET_DIR}/Syncftu"
ln -sf "${TARGET_DIR}/syncftu" "${TARGET_DIR}/SyncFtu"
ln -sf "${TARGET_DIR}/syncftu" "${TARGET_DIR}/syncFtu"
ln -sf "${TARGET_DIR}/syncftu" "${TARGET_DIR}/syncFileToUbuntu"
ln -sf "${TARGET_DIR}/syncftu" "${TARGET_DIR}/syncfiletoubuntu"
ln -sf "${TARGET_DIR}/syncftu" "${TARGET_DIR}/SyncFileToUbuntu"
ln -sf "${TARGET_DIR}/syncftu" "${TARGET_DIR}/SYNCFILETOUBUNTU"
ln -sf "${TARGET_DIR}/syncftu" "${TARGET_DIR}/sync-filetoubuntu"
ln -sf "${TARGET_DIR}/syncftu" "${TARGET_DIR}/sync-filetoubuntu-from-vm.sh"
echo "更新--- ${TARGET_DIR}/syncftu 成功----"

echo "===== 更新统一入口与下载别名 ====="
rm -f   "${TARGET_DIR}/update_scipt_all"   "${TARGET_DIR}/updateSciptAll"   "${TARGET_DIR}/updatesciptAll"   "${TARGET_DIR}/updateSciptall"   "${TARGET_DIR}/updatesciptall"   "${TARGET_DIR}/update_all"   "${TARGET_DIR}/updateAll"   "${TARGET_DIR}/update_download_jira"   "${TARGET_DIR}/updateDownloadJira"   "${TARGET_DIR}/updatedownloadJira"   "${TARGET_DIR}/updateDownloadjira"   "${TARGET_DIR}/updatedownloadjira"   "${TARGET_DIR}/update_download_feishu"   "${TARGET_DIR}/updateDownloadFeishu"   "${TARGET_DIR}/updatedownloadFeishu"   "${TARGET_DIR}/updateDownloadfeishu"   "${TARGET_DIR}/updatedownloadfeishu"   "${TARGET_DIR}/download_jira"   "${TARGET_DIR}/downloadJira"   "${TARGET_DIR}/downloadjira"   "${TARGET_DIR}/download_jira_filtered"   "${TARGET_DIR}/downloadJiraFiltered"   "${TARGET_DIR}/downloadjiraFiltered"   "${TARGET_DIR}/downloadJirafiltered"   "${TARGET_DIR}/downloadjirafiltered"   "${TARGET_DIR}/download_feishu"   "${TARGET_DIR}/downloadFeishu"   "${TARGET_DIR}/downloadfeishu"   "${TARGET_DIR}/download_bug_feishu"   "${TARGET_DIR}/downloadb"   "${TARGET_DIR}/download_feishu_fliter"   "${TARGET_DIR}/downloadFeishuFliter"   "${TARGET_DIR}/downloadfeishuFliter"   "${TARGET_DIR}/downloadFeishufliter"   "${TARGET_DIR}/downloadfeishufliter"   "${TARGET_DIR}/downloadfeishu_fliter"   "${TARGET_DIR}/dfres"   "${TARGET_DIR}/downloadBugFeishu"   "${TARGET_DIR}/downloadBugfeishu"   "${TARGET_DIR}/downloadbugFeishu"   "${TARGET_DIR}/downloadbugfeishu"

install_script "${ROOT_DIR}/update_scipt_all.sh" "${TARGET_DIR}/updateSciptAll"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updatesciptAll"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updateSciptall"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updatesciptall"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/update_scipt_all"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updateAll"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/update_all"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updateDownloadJira"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updatedownloadJira"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updateDownloadjira"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updatedownloadjira"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/update_download_jira"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updateDownloadFeishu"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updatedownloadFeishu"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updateDownloadfeishu"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/updatedownloadfeishu"
ln -sf "${TARGET_DIR}/updateSciptAll" "${TARGET_DIR}/update_download_feishu"
echo "更新--- ${TARGET_DIR}/updateSciptAll 成功----"

install_script "${JIRA_DIR}/download_jira.sh" "${TARGET_DIR}/downloadJira"
ln -sf "${TARGET_DIR}/downloadJira" "${TARGET_DIR}/downloadjira"
ln -sf "${TARGET_DIR}/downloadJira" "${TARGET_DIR}/download_jira"
echo "更新--- ${TARGET_DIR}/downloadJira 成功----"

install_script "${JIRA_DIR}/download_jira_filtered.sh" "${TARGET_DIR}/downloadJiraFiltered"
ln -sf "${TARGET_DIR}/downloadJiraFiltered" "${TARGET_DIR}/downloadjirafiltered"
ln -sf "${TARGET_DIR}/downloadJiraFiltered" "${TARGET_DIR}/download_jira_filtered"
echo "更新--- ${TARGET_DIR}/downloadJiraFiltered 成功----"

install_script "${FEISHU_DIR}/download_feishu.sh" "${TARGET_DIR}/downloadFeishu"
ln -sf "${TARGET_DIR}/downloadFeishu" "${TARGET_DIR}/downloadfeishu"
ln -sf "${TARGET_DIR}/downloadFeishu" "${TARGET_DIR}/download_bug_feishu"
ln -sf "${TARGET_DIR}/downloadFeishu" "${TARGET_DIR}/download_feishu"
ln -sf "${TARGET_DIR}/downloadFeishu" "${TARGET_DIR}/downloadb"
echo "更新--- ${TARGET_DIR}/downloadFeishu 成功----"

install_script "${FEISHU_DIR}/download_feishu_fliter.sh" "${TARGET_DIR}/downloadFeishuFliter"
ln -sf "${TARGET_DIR}/downloadFeishuFliter" "${TARGET_DIR}/downloadfeishufliter"
ln -sf "${TARGET_DIR}/downloadFeishuFliter" "${TARGET_DIR}/download_feishu_fliter"
ln -sf "${TARGET_DIR}/downloadFeishuFliter" "${TARGET_DIR}/dfres"
echo "更新--- ${TARGET_DIR}/downloadFeishuFliter 成功----"
echo "更新--- ${TARGET_DIR}/downloadfeishufliter 成功----"
echo "更新--- ${TARGET_DIR}/dfres 成功----"

ensure_case_insensitive_completion
remove_legacy_completion_sources
ensure_shell_hooks_source

echo "===== 更新完成 ====="
echo "提示: Feishu 下载入口已支持按单号优先匹配专用 cURL，并自动回退到其他项目 cURL。"
echo "提示: 当前 shell 如果还命中旧路径，可执行 hash -r 或重新开一个终端。"
