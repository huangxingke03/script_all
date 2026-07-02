#!/bin/bash

set -e

TARGET_DIR="${HOME}/.local/bin"
SCRIPT_DIR="/home/huangxingke/project/Python/script"

mkdir -p "${TARGET_DIR}"

cp "${SCRIPT_DIR}/update_voice_build_script.sh" "${TARGET_DIR}/update_voice_build_script"
chmod +x "${TARGET_DIR}/update_voice_build_script"

rm -f \
  "${TARGET_DIR}/voice_assistant_d01" \
  "${TARGET_DIR}/voice_setting_d01" \
  "${TARGET_DIR}/voice_assistant_kp31" \
  "${TARGET_DIR}/voice_setting_kp31" \
  "${TARGET_DIR}/xunfeikp31" \
  "${TARGET_DIR}/Xunfeikp31" \
  "${TARGET_DIR}/XunFeiKp31" \
  "${TARGET_DIR}/xunfeiKp31" \
  "${TARGET_DIR}/xunfeiKP31" \
  "${TARGET_DIR}/stwc" \
  "${TARGET_DIR}/stwc.sh" \
  "${TARGET_DIR}/Stwc" \
  "${TARGET_DIR}/STwc" \
  "${TARGET_DIR}/STWC" \
  "${TARGET_DIR}/StWc" \
  "${TARGET_DIR}/StWC" \
  "${TARGET_DIR}/StwC" \
  "${TARGET_DIR}/STWc" \
  "${TARGET_DIR}/STwC" \
  "${TARGET_DIR}/sTwc" \
  "${TARGET_DIR}/sTWc" \
  "${TARGET_DIR}/sTwC" \
  "${TARGET_DIR}/sTWC" \
  "${TARGET_DIR}/stWc" \
  "${TARGET_DIR}/stWC" \
  "${TARGET_DIR}/stwC" \
  "${TARGET_DIR}/voiceAssistantD01" \
  "${TARGET_DIR}/voiceassistantD01" \
  "${TARGET_DIR}/voiceAssistantd01" \
  "${TARGET_DIR}/voiceassistantd01" \
  "${TARGET_DIR}/voiceAssistantKp31" \
  "${TARGET_DIR}/voiceassistantKp31" \
  "${TARGET_DIR}/voiceAssistantkp31" \
  "${TARGET_DIR}/voiceassistantkp31" \
  "${TARGET_DIR}/voiceSettingD01" \
  "${TARGET_DIR}/voicesettingD01" \
  "${TARGET_DIR}/voiceSettingd01" \
  "${TARGET_DIR}/voicesettingd01" \
  "${TARGET_DIR}/voiceSettingKp31" \
  "${TARGET_DIR}/voicesettingKp31" \
  "${TARGET_DIR}/voiceSettingkp31" \
  "${TARGET_DIR}/voicesettingkp31" \
  "${TARGET_DIR}/restartSystemUi" \
  "${TARGET_DIR}/restartsystemUi" \
  "${TARGET_DIR}/restartSystemui" \
  "${TARGET_DIR}/restartsystemui" \
  "${TARGET_DIR}/rsui" \
  "${TARGET_DIR}/Rsui" \
  "${TARGET_DIR}/RSui" \
  "${TARGET_DIR}/RSUI" \
  "${TARGET_DIR}/RsUi" \
  "${TARGET_DIR}/RsUI" \
  "${TARGET_DIR}/RsuI" \
  "${TARGET_DIR}/RSuI" \
  "${TARGET_DIR}/rSui" \
  "${TARGET_DIR}/rSUi" \
  "${TARGET_DIR}/rSUI" \
  "${TARGET_DIR}/rsUi" \
  "${TARGET_DIR}/rsUI" \
  "${TARGET_DIR}/rsuI" \
  "${TARGET_DIR}/rSuI" \
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
  "${TARGET_DIR}/voice_build_common.sh"

echo "更新--- 共享语音打包脚本"
cp "${SCRIPT_DIR}/voice_build_common.sh" "${TARGET_DIR}/voice_build_common.sh"
chmod +x "${TARGET_DIR}/voice_build_common.sh"
echo "更新---共享语音打包脚本更新成功"

echo "更新--- VoiceCommonService 快捷脚本"
cp "${SCRIPT_DIR}/stwc.sh" "${TARGET_DIR}/stwc"
chmod +x "${TARGET_DIR}/stwc"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/stwc.sh"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/Stwc"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/STwc"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/STWC"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/StWc"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/StWC"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/StwC"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/STWc"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/STwC"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/sTwc"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/sTWc"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/sTwC"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/sTWC"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/stWc"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/stWC"
ln -sf "${TARGET_DIR}/stwc" "${TARGET_DIR}/stwC"
echo "更新---VoiceCommonService 快捷脚本更新成功"

cp "${SCRIPT_DIR}/voice_assistant_d01.sh" "${TARGET_DIR}/voiceAssistantD01"
echo "更新--- D01语音助手打包推包脚本"
chmod +x "${TARGET_DIR}/voiceAssistantD01"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voiceassistantD01"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voiceAssistantd01"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voiceassistantd01"
ln -sf "${TARGET_DIR}/voiceAssistantD01" "${TARGET_DIR}/voice_assistant_d01"
echo "更新---D01语音助手打包推包脚本更新成功"

cp "${SCRIPT_DIR}/voice_setting_d01.sh" "${TARGET_DIR}/voiceSettingD01"
echo "更新--- D01语音设置打包推包脚本"
chmod +x "${TARGET_DIR}/voiceSettingD01"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voicesettingD01"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voiceSettingd01"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voicesettingd01"
ln -sf "${TARGET_DIR}/voiceSettingD01" "${TARGET_DIR}/voice_setting_d01"
echo "更新---D01语音设置打包推包脚本更新成功"

cp "${SCRIPT_DIR}/voice_assistant_kp31.sh" "${TARGET_DIR}/voiceAssistantKp31"
echo "更新--- KP31语音助手打包推包脚本"
chmod +x "${TARGET_DIR}/voiceAssistantKp31"
ln -sf "${TARGET_DIR}/voiceAssistantKp31" "${TARGET_DIR}/voiceassistantKp31"
ln -sf "${TARGET_DIR}/voiceAssistantKp31" "${TARGET_DIR}/voiceAssistantkp31"
ln -sf "${TARGET_DIR}/voiceAssistantKp31" "${TARGET_DIR}/voiceassistantkp31"
ln -sf "${TARGET_DIR}/voiceAssistantKp31" "${TARGET_DIR}/voice_assistant_kp31"
echo "更新---KP31语音助手打包推包脚本更新成功"

cp "${SCRIPT_DIR}/voice_setting_kp31.sh" "${TARGET_DIR}/voiceSettingKp31"
echo "更新--- KP31语音设置打包推包脚本"
chmod +x "${TARGET_DIR}/voiceSettingKp31"
ln -sf "${TARGET_DIR}/voiceSettingKp31" "${TARGET_DIR}/voicesettingKp31"
ln -sf "${TARGET_DIR}/voiceSettingKp31" "${TARGET_DIR}/voiceSettingkp31"
ln -sf "${TARGET_DIR}/voiceSettingKp31" "${TARGET_DIR}/voicesettingkp31"
ln -sf "${TARGET_DIR}/voiceSettingKp31" "${TARGET_DIR}/voice_setting_kp31"
echo "更新---KP31语音设置打包推包脚本更新成功"

cp "${SCRIPT_DIR}/xunfeikp31" "${TARGET_DIR}/xunfeikp31"
echo "更新--- KP31讯飞设置页快捷脚本"
chmod +x "${TARGET_DIR}/xunfeikp31"
ln -sf "${TARGET_DIR}/xunfeikp31" "${TARGET_DIR}/Xunfeikp31"
ln -sf "${TARGET_DIR}/xunfeikp31" "${TARGET_DIR}/XunFeiKp31"
ln -sf "${TARGET_DIR}/xunfeikp31" "${TARGET_DIR}/xunfeiKp31"
ln -sf "${TARGET_DIR}/xunfeikp31" "${TARGET_DIR}/xunfeiKP31"
echo "更新---KP31讯飞设置页快捷脚本更新成功"

cp "${SCRIPT_DIR}/kill_systemui.sh" "${TARGET_DIR}/killSystemui"
echo "更新--- SystemUI 重启快捷脚本"
chmod +x "${TARGET_DIR}/killSystemui"
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
echo "更新---SystemUI 重启快捷脚本更新成功"
