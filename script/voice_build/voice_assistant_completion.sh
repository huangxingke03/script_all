#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/voice_build_common.sh"

_voice_device_completion() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Never fall back to filename completion for -s device suggestions.
    compopt +o default +o bashdefault 2>/dev/null

    if [ "$prev" = "-s" ]; then
        COMPREPLY=( $(collect_device_completion_replies "${cur}") )
        return 0
    fi

    COMPREPLY=( $(compgen -W "-s -c -C --clear-cache --CLEAR-CACHE -h --help --HELP" -- "$cur") )
}

_voice_completion_reset() {
    local command_name
    local -a all_commands=(
        ./voice_assistant_d01.sh
        ./voice_assistant_kp31.sh
        ./voice_assistant_t12a.sh
        ./voice_setting_d01.sh
        ./voice_setting_kp31.sh
        ./common_script/start_iflytek_page.sh
        ./voice_build/voice_assistant_d01.sh
        ./voice_build/voice_assistant_kp31.sh
        ./voice_build/voice_assistant_t12a.sh
        ./voice_build/voice_setting_d01.sh
        ./voice_build/voice_setting_kp31.sh
        ./common_script/kill_systemui.sh
        voice_assistant_d01.sh
        voice_assistant_kp31.sh
        voice_assistant_t12a.sh
        voice_setting_d01.sh
        voice_setting_kp31.sh
        startIflytekPage
        startiflytekPage
        startIflytekpage
        startiflytekpage
        start_iflytek_page
        /usr/local/bin/voiceAssistantD01
        /usr/local/bin/voiceassistantD01
        /usr/local/bin/voiceAssistantd01
        /usr/local/bin/voiceassistantd01
        /usr/local/bin/voiceAssistantKp31
        /usr/local/bin/voiceassistantKp31
        /usr/local/bin/voiceAssistantkp31
        /usr/local/bin/voiceassistantkp31
        voiceAssistantT12a
        voiceassistantT12a
        voiceAssistantt12a
        voiceassistantt12a
        /usr/local/bin/voiceAssistantT12a
        /usr/local/bin/voiceassistantT12a
        /usr/local/bin/voiceAssistantt12a
        /usr/local/bin/voiceassistantt12a
        /usr/local/bin/voiceSettingD01
        /usr/local/bin/voicesettingD01
        /usr/local/bin/voiceSettingd01
        /usr/local/bin/voicesettingd01
        /usr/local/bin/voiceSettingKp31
        /usr/local/bin/voicesettingKp31
        /usr/local/bin/voiceSettingkp31
        /usr/local/bin/voicesettingkp31
        /usr/local/bin/startIflytekPage
        /usr/local/bin/startiflytekPage
        /usr/local/bin/startIflytekpage
        /usr/local/bin/startiflytekpage
        /usr/local/bin/start_iflytek_page
        /usr/local/bin/killSystemui
        /usr/local/bin/killsystemUi
        /usr/local/bin/killsystemui
        /usr/local/bin/ksui
        /usr/local/bin/Ksui
        /usr/local/bin/KSui
        /usr/local/bin/KSUI
        /usr/local/bin/KsUi
        /usr/local/bin/KsUI
        /usr/local/bin/KsuI
        /usr/local/bin/KSuI
        /usr/local/bin/kSui
        /usr/local/bin/kSUi
        /usr/local/bin/kSUI
        /usr/local/bin/ksUi
        /usr/local/bin/ksUI
        /usr/local/bin/ksuI
        /usr/local/bin/kSuI
        voiceAssistantD01
        voiceassistantD01
        voiceAssistantd01
        voiceassistantd01
        voiceAssistantKp31
        voiceassistantKp31
        voiceAssistantkp31
        voiceassistantkp31
        voiceAssistantT12a
        voiceassistantT12a
        voiceAssistantt12a
        voiceassistantt12a
        voiceSettingD01
        voicesettingD01
        voiceSettingd01
        voicesettingd01
        voiceSettingKp31
        voicesettingKp31
        voiceSettingkp31
        voicesettingkp31
        startIflytekPage
        startiflytekPage
        startIflytekpage
        startiflytekpage
        start_iflytek_page
        killSystemui
        killsystemUi
        killsystemui
        ksui
        Ksui
        KSui
        KSUI
        KsUi
        KsUI
        KsuI
        KSuI
        kSui
        kSUi
        kSUI
        ksUi
        ksUI
        ksuI
        kSuI
    )

    for command_name in "${all_commands[@]}"; do
        complete -r "$command_name" 2>/dev/null || true
    done
}

_voice_completion_bind() {
    local command_name
    local -a supported_commands=(
        ./voice_assistant_d01.sh
        ./voice_assistant_kp31.sh
        ./voice_assistant_t12a.sh
        ./voice_setting_d01.sh
        ./voice_setting_kp31.sh
        ./common_script/start_iflytek_page.sh
        ./voice_build/voice_assistant_d01.sh
        ./voice_build/voice_assistant_kp31.sh
        ./voice_build/voice_assistant_t12a.sh
        ./voice_build/voice_setting_d01.sh
        ./voice_build/voice_setting_kp31.sh
        voice_assistant_d01.sh
        voice_assistant_kp31.sh
        voice_assistant_t12a.sh
        voice_setting_d01.sh
        voice_setting_kp31.sh
        startIflytekPage
        startiflytekPage
        startIflytekpage
        startiflytekpage
        start_iflytek_page
        /usr/local/bin/voiceAssistantD01
        /usr/local/bin/voiceassistantD01
        /usr/local/bin/voiceAssistantd01
        /usr/local/bin/voiceassistantd01
        /usr/local/bin/voiceAssistantKp31
        /usr/local/bin/voiceassistantKp31
        /usr/local/bin/voiceAssistantkp31
        /usr/local/bin/voiceassistantkp31
        voiceAssistantT12a
        voiceassistantT12a
        voiceAssistantt12a
        voiceassistantt12a
        /usr/local/bin/voiceAssistantT12a
        /usr/local/bin/voiceassistantT12a
        /usr/local/bin/voiceAssistantt12a
        /usr/local/bin/voiceassistantt12a
        /usr/local/bin/voiceSettingD01
        /usr/local/bin/voicesettingD01
        /usr/local/bin/voiceSettingd01
        /usr/local/bin/voicesettingd01
        /usr/local/bin/voiceSettingKp31
        /usr/local/bin/voicesettingKp31
        /usr/local/bin/voiceSettingkp31
        /usr/local/bin/voicesettingkp31
        /usr/local/bin/startIflytekPage
        /usr/local/bin/startiflytekPage
        /usr/local/bin/startIflytekpage
        /usr/local/bin/startiflytekpage
        /usr/local/bin/start_iflytek_page
        /usr/local/bin/killSystemui
        /usr/local/bin/killsystemUi
        /usr/local/bin/killsystemui
        /usr/local/bin/ksui
        /usr/local/bin/Ksui
        /usr/local/bin/KSui
        /usr/local/bin/KSUI
        /usr/local/bin/KsUi
        /usr/local/bin/KsUI
        /usr/local/bin/KsuI
        /usr/local/bin/KSuI
        /usr/local/bin/kSui
        /usr/local/bin/kSUi
        /usr/local/bin/kSUI
        /usr/local/bin/ksUi
        /usr/local/bin/ksUI
        /usr/local/bin/ksuI
        /usr/local/bin/kSuI
        voiceAssistantD01
        voiceassistantD01
        voiceAssistantd01
        voiceassistantd01
        voiceAssistantKp31
        voiceassistantKp31
        voiceAssistantkp31
        voiceassistantkp31
        voiceAssistantT12a
        voiceassistantT12a
        voiceAssistantt12a
        voiceassistantt12a
        voiceSettingD01
        voicesettingD01
        voiceSettingd01
        voicesettingd01
        voiceSettingKp31
        voicesettingKp31
        voiceSettingkp31
        voicesettingkp31
        startIflytekPage
        startiflytekPage
        startIflytekpage
        startiflytekpage
        start_iflytek_page
        killSystemui
        killsystemUi
        killsystemui
        ksui
        Ksui
        KSui
        KSUI
        KsUi
        KsUI
        KsuI
        KSuI
        kSui
        kSUi
        kSUI
        ksUi
        ksUI
        ksuI
        kSuI
    )

    for command_name in "${supported_commands[@]}"; do
        complete -o nospace -F _voice_device_completion "$command_name"
    done
}

voice_completion_repair() {
    _voice_completion_reset
    _voice_completion_bind
}

voice_completion_repair
