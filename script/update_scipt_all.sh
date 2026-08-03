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
INPUTRC_FILE="${HOME}/.inputrc"
BASHRC_FILE="${HOME}/.bashrc"

ensure_case_insensitive_completion() {
  touch "${INPUTRC_FILE}"
  if ! grep -qxF "set completion-ignore-case on" "${INPUTRC_FILE}"; then
    printf '
set completion-ignore-case on
' >> "${INPUTRC_FILE}"
    echo "更新--- 已开启 Bash 大小写不敏感补全，请重新打开终端或执行: bind 'set completion-ignore-case on'"
  else
    echo "更新--- Bash 大小写不敏感补全已开启"
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
    '[ -f /home/huangxingke/project/Python/script/iflytek_sys_completion.sh ] && source /home/huangxingke/project/Python/script/iflytek_sys_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/voice_assistant_completion.sh ] && source /home/huangxingke/project/Python/script/voice_assistant_completion.sh',
    '[ -f "/home/huangxingke/project/Python/script/voice_build/voice_assistant_completion.sh" ] && source "/home/huangxingke/project/Python/script/voice_build/voice_assistant_completion.sh"',
    '[ -f /home/huangxingke/project/Python/script/voice_build/voice_assistant_completion.sh ] && source /home/huangxingke/project/Python/script/voice_build/voice_assistant_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/logcat_sum/random_log_completion.sh ] && source /home/huangxingke/project/Python/script/logcat_sum/random_log_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/logcat_sum/pull_logcat_by_adb_completion.sh ] && source /home/huangxingke/project/Python/script/logcat_sum/pull_logcat_by_adb_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/logcat_sum/clear_logcat_by_adb_completion.sh ] && source /home/huangxingke/project/Python/script/logcat_sum/clear_logcat_by_adb_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/common_script/scrcpy_completion.sh ] && source /home/huangxingke/project/Python/script/common_script/scrcpy_completion.sh',
    '[ -f /home/huangxingke/project/Python/script/common_script/voice_bt_click_completion.sh ] && source /home/huangxingke/project/Python/script/common_script/voice_bt_click_completion.sh',
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
  "${TARGET_DIR}/update_d01_sys" \
  "${TARGET_DIR}/update_d01_sys.sh" \
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
  "${TARGET_DIR}/updateD01Sys" \
  "${TARGET_DIR}/updated01Sys" \
  "${TARGET_DIR}/updateDO1Sys" \
  "${TARGET_DIR}/updatedo1Sys" \
  "${TARGET_DIR}/updateD01sys" \
  "${TARGET_DIR}/updateDO1sys" \
  "${TARGET_DIR}/updatedo1sys" \
  "${TARGET_DIR}/updated01sys" \
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
  "${TARGET_DIR}/updatekp31sys"

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
  "${TARGET_DIR}/voicebtclick" \
  "${TARGET_DIR}/update_rename_usb_dir" \
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
  "${TARGET_DIR}/start_virt_manager"

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

install_script "${COMMON_TOOL_DIR}/reboot_device.sh" "${TARGET_DIR}/rebootDevice"
ln -sf "${TARGET_DIR}/rebootDevice" "${TARGET_DIR}/rebootdevice"
ln -sf "${TARGET_DIR}/rebootDevice" "${TARGET_DIR}/reboot_device"
echo "更新--- ${TARGET_DIR}/rebootDevice 成功----"

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
echo "更新--- ${TARGET_DIR}/killSystemui 成功----"

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
  cp "${COMMON_TOOL_DIR}/virt_manager.desktop" "${APPLICATIONS_DIR}/virt-manager-shortcut.desktop"
  chmod +x "${APPLICATIONS_DIR}/virt-manager-shortcut.desktop"
  echo "更新--- ${APPLICATIONS_DIR}/virt-manager-shortcut.desktop 成功----"
fi

echo "===== 更新统一入口与下载别名 ====="
rm -f   "${TARGET_DIR}/update_scipt_all"   "${TARGET_DIR}/updateSciptAll"   "${TARGET_DIR}/updatesciptAll"   "${TARGET_DIR}/updateSciptall"   "${TARGET_DIR}/updatesciptall"   "${TARGET_DIR}/update_all"   "${TARGET_DIR}/updateAll"   "${TARGET_DIR}/update_download_jira"   "${TARGET_DIR}/updateDownloadJira"   "${TARGET_DIR}/updatedownloadJira"   "${TARGET_DIR}/updateDownloadjira"   "${TARGET_DIR}/updatedownloadjira"   "${TARGET_DIR}/update_download_feishu"   "${TARGET_DIR}/updateDownloadFeishu"   "${TARGET_DIR}/updatedownloadFeishu"   "${TARGET_DIR}/updateDownloadfeishu"   "${TARGET_DIR}/updatedownloadfeishu"   "${TARGET_DIR}/download_jira"   "${TARGET_DIR}/downloadJira"   "${TARGET_DIR}/downloadjira"   "${TARGET_DIR}/download_jira_filtered"   "${TARGET_DIR}/downloadJiraFiltered"   "${TARGET_DIR}/downloadjiraFiltered"   "${TARGET_DIR}/downloadJirafiltered"   "${TARGET_DIR}/downloadjirafiltered"   "${TARGET_DIR}/download_feishu"   "${TARGET_DIR}/downloadFeishu"   "${TARGET_DIR}/downloadfeishu"   "${TARGET_DIR}/download_bug_feishu"   "${TARGET_DIR}/downloadb"   "${TARGET_DIR}/download_feishu_fliter"   "${TARGET_DIR}/downloadFeishuFliter"   "${TARGET_DIR}/downloadfeishuFliter"   "${TARGET_DIR}/downloadFeishufliter"   "${TARGET_DIR}/downloadfeishufliter"

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
ln -sf "${TARGET_DIR}/downloadJiraFiltered" "${TARGET_DIR}/downloadjiraFiltered"
ln -sf "${TARGET_DIR}/downloadJiraFiltered" "${TARGET_DIR}/downloadJirafiltered"
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
ln -sf "${TARGET_DIR}/downloadFeishuFliter" "${TARGET_DIR}/downloadfeishuFliter"
ln -sf "${TARGET_DIR}/downloadFeishuFliter" "${TARGET_DIR}/downloadFeishufliter"
ln -sf "${TARGET_DIR}/downloadFeishuFliter" "${TARGET_DIR}/downloadfeishufliter"
ln -sf "${TARGET_DIR}/downloadFeishuFliter" "${TARGET_DIR}/download_feishu_fliter"
ln -sf "${TARGET_DIR}/downloadFeishuFliter" "${TARGET_DIR}/downloadfeishu_fliter"
echo "更新--- ${TARGET_DIR}/downloadFeishuFliter 成功----"
echo "更新--- ${TARGET_DIR}/downloadfeishufliter 成功----"

ensure_case_insensitive_completion
remove_legacy_completion_sources
ensure_shell_hooks_source

echo "===== 更新完成 ====="
echo "提示: Feishu 下载入口已支持按单号优先匹配专用 cURL，并自动回退到其他项目 cURL。"
echo "提示: 当前 shell 如果还命中旧路径，可执行 hash -r 或重新开一个终端。"
