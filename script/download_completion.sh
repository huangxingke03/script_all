#!/bin/bash

# First-word completion for download* and voice* commands.
# Keep PATH aliases for typing, but Tab only shows canonical names so
# `download` / `downloadf` / `voice` / `voicea` / `voices` can continue completing.
# When ignore-case is on, rewrite the typed prefix to the canonical common
# prefix so Tab actually inserts `voiceAssistant` instead of only listing.

_download_initial_completion() {
    local cur lc name common
    cur="${COMP_WORDS[COMP_CWORD]}"
    lc="${cur,,}"

    local -a names=() matches=()

    if [[ "$lc" == down* ]]; then
        names=(
            downloadb
            downloadFeishu
            downloadFeishuFliter
            downloadJira
            downloadJiraFiltered
        )
    elif [[ "$lc" == voice* ]]; then
        names=(
            voiceAssistantD01
            voiceAssistantKp31
            voiceAssistantT12a
            voiceBtClick
            voiceSettingD01
            voiceSettingKp31
            voice_assistant_d01
            voice_assistant_kp31
            voice_assistant_t12a
            voice_bt_click
            voice_setting_d01
            voice_setting_kp31
        )
    elif [[ "$lc" == startb* || "$lc" == start_b* ]]; then
        names=(startBootGuideKP31)
        # start_boot_guide_kp31 也折成同一个正式命令名。
        [[ "$lc" == start_b* ]] && lc="startb"
    elif [[ "$lc" == reset* ]]; then
        names=(resetVat resetVst)
        # reset_vat / reset_vst 折成正式命令前缀再匹配。
        if [[ "$lc" == reset_vat* ]]; then
            lc="resetvat"
        elif [[ "$lc" == reset_vst* ]]; then
            lc="resetvst"
        fi
    elif [[ "$lc" == setsales* || "$lc" == setsa* || "$lc" == set_s* ]]; then
        names=(setSalesArea)
        # setsalesarea / SETSALESAREA / set_sales_area 都折成正式命令名。
        lc="sets"
    elif [[ "$lc" == replace* ]]; then
        # 正式名：replaceo → replaceOut*，replacel → replaceLocal*；勿再强制只补 replaceLocal
        names=(
            replaceLocal
            replaceLocalD01p
            replaceLocalDO1p
            replaceOut
            replaceOutD01p
            replaceOutDO1p
        )
        # replace_local* / replace_out* 折成无下划线前缀再匹配
        if [[ "$lc" == replace_local_d01p* || "$lc" == replace_local_do1p* ]]; then
            lc="replacelocald01p"
        elif [[ "$lc" == replace_local* ]]; then
            lc="replacelocal"
        elif [[ "$lc" == replace_out_d01p* || "$lc" == replace_out_do1p* ]]; then
            lc="replaceoutd01p"
        elif [[ "$lc" == replace_out* ]]; then
            lc="replaceout"
        fi
    elif [[ "$lc" == scrn || "$lc" == scra || "$lc" == scrv || "$lc" == scrh || "$lc" == scrna ]]; then
        # 命令已经打全时只补这一条，避免 scrn 被 scrna 和大小写别名挡住。
        names=("$lc")
    else
        return 1
    fi

    COMPREPLY=()
    for name in "${names[@]}"; do
        if [[ "${name,,}" == "$lc"* ]]; then
            matches+=("$name")
        fi
    done

    # Never fall back to PATH aliases; those reintroduce case variants.
    compopt +o default +o bashdefault 2>/dev/null

    if ((${#matches[@]} == 0)); then
        return 0
    fi

    if ((${#matches[@]} == 1)); then
        COMPREPLY=("${matches[0]}")
        return 0
    fi

    common="${matches[0]}"
    for name in "${matches[@]:1}"; do
        while [[ -n "$common" && "$name" != "$common"* ]]; do
            common="${common%?}"
        done
    done

    # Case-insensitive typing (`voicea`) would otherwise only list matches
    # without rewriting to the canonical prefix (`voiceAssistant`).
    if [[ "$common" != "$cur" ]]; then
        COMPREPLY=("$common")
        compopt -o nospace 2>/dev/null
        return 0
    fi

    COMPREPLY=("${matches[@]}")
    return 0
}

complete -o bashdefault -o default -I -F _download_initial_completion
