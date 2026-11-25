#!/bin/bash
# mockVoice：命令名忽略大小写；-s 补在线设备。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/voice_build/voice_build_common.sh"

_MOCKVOICE_CANONICAL="${HOME}/.local/bin/mockVoice"
_MOCKVOICE_SOURCE="${SCRIPT_DIR}/mock_voice.sh"
_MOCKVOICE_BIN_DIR="${HOME}/.local/bin"
_MOCKVOICE_COMPLETION_DIR="${HOME}/.local/share/bash-completion/completions"
_MOCKVOICE_ALIAS_NAMES=(
    MockVoice
    MOCKVOICE
    mockvoice
    Mockvoice
    mockVOICE
    mock_voice
)

_mockvoice_install_case_links() {
    local name target
    mkdir -p "${_MOCKVOICE_BIN_DIR}"
    if [[ -x "${_MOCKVOICE_CANONICAL}" && ! -L "${_MOCKVOICE_CANONICAL}" ]]; then
        target="${_MOCKVOICE_CANONICAL}"
    elif [[ -x "${_MOCKVOICE_SOURCE}" ]]; then
        target="${_MOCKVOICE_SOURCE}"
    else
        return 0
    fi
    for name in "${_MOCKVOICE_ALIAS_NAMES[@]}"; do
        ln -sfn "${target}" "${_MOCKVOICE_BIN_DIR}/${name}"
    done
}

_mockvoice_install_completion_files() {
    local name
    mkdir -p "${_MOCKVOICE_COMPLETION_DIR}"
    for name in mockVoice "${_MOCKVOICE_ALIAS_NAMES[@]}"; do
        printf '%s\n' '. /home/huangxingke/project/Python/script/common_script/mock_voice_completion.sh' \
            > "${_MOCKVOICE_COMPLETION_DIR}/${name}"
    done
}

_mockvoice_remove_sim_voice() {
    local name
    local -a stale=(
        simVoice simvoice SimVoice SIMVOICE sim_voice
        ./sim_voice.sh
        ./common_script/sim_voice.sh
        /home/huangxingke/project/Python/script/common_script/sim_voice.sh
    )
    for name in "${stale[@]}"; do
        complete -r "${name}" 2>/dev/null || true
        complete -r "${_MOCKVOICE_BIN_DIR}/${name}" 2>/dev/null || true
        rm -f "${_MOCKVOICE_BIN_DIR}/${name}" "${_MOCKVOICE_COMPLETION_DIR}/${name}"
    done
}

_mock_voice_completion() {
    local cur prev cur_lc prev_lc device_query reply opt
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cur_lc="${cur,,}"
    prev_lc="${prev,,}"
    device_query="${cur}"

    compopt +o default +o bashdefault +o dirnames +o filenames 2>/dev/null || true
    compopt -o nosort 2>/dev/null || true

    # 已输入完整 -s / -S 但尚未空格时，先补出 -s，下一次 Tab 再列设备
    if [ "${cur_lc}" = "-s" ] && [ "${prev_lc}" != "-s" ]; then
        COMPREPLY=("-s")
        return 0
    fi

    if [ "${prev_lc}" = "-s" ]; then
        [[ "${device_query}" == */* ]] && device_query=""
        COMPREPLY=()
        while IFS= read -r reply; do
            [ -n "${reply}" ] && COMPREPLY+=("${reply}")
        done < <(collect_device_completion_replies "${device_query}")
        return 0
    fi

    COMPREPLY=()
    # 还没输入指令时先补 -s / -h；指令文本之后再补唤醒方位
    if [[ "${cur}" == -* ]] || { [ -z "${cur}" ] && [ "${COMP_CWORD}" -le 1 ]; }; then
        for opt in -s -h; do
            if [[ "${opt}" == "${cur_lc}"* ]]; then
                COMPREPLY+=("${opt}")
            fi
        done
        return 0
    fi

    local direction
    for direction in 主驾 副驾 左后 右后; do
        if [[ "${direction}" == "${cur}"* ]]; then
            COMPREPLY+=("${direction}")
        fi
    done
    return 0
}

mock_voice_completion_repair() {
    local command_name
    local -a commands=(
        ./mock_voice.sh
        ./common_script/mock_voice.sh
        "${_MOCKVOICE_SOURCE}"
        "${_MOCKVOICE_CANONICAL}"
        mockVoice
        "${_MOCKVOICE_ALIAS_NAMES[@]}"
    )

    _mockvoice_remove_sim_voice
    _mockvoice_install_case_links
    _mockvoice_install_completion_files

    for command_name in "${commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
        complete -r "${_MOCKVOICE_BIN_DIR}/${command_name}" 2>/dev/null || true
    done
    for command_name in "${commands[@]}"; do
        complete -o nosort -F _mock_voice_completion "${command_name}"
        if [[ "${command_name}" != /* && "${command_name}" != ./* ]]; then
            complete -o nosort -F _mock_voice_completion "${_MOCKVOICE_BIN_DIR}/${command_name}"
        fi
    done
}

mockvoice_completion_repair() { mock_voice_completion_repair; }
MockVoice_completion_repair() { mock_voice_completion_repair; }

mock_voice_completion_repair
