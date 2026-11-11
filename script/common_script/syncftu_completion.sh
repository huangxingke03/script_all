#!/bin/bash
# syncftu：命令名忽略大小写；-s 后 Tab 补在线 adb 设备。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${REPO_ROOT}/voice_build/voice_build_common.sh"

_SYNCFTU_CANONICAL="${HOME}/.local/bin/syncftu"
_SYNCFTU_SOURCE="${SCRIPT_DIR}/sync_filetoubuntu.sh"
_SYNCFTU_BIN_DIR="${HOME}/.local/bin"
_SYNCFTU_COMPLETION_DIR="${HOME}/.local/share/bash-completion/completions"
_SYNCFTU_ALIAS_NAMES=(
  SYNCFTU Syncftu SyncFtu syncFtu
  syncFileToUbuntu syncfiletoubuntu SyncFileToUbuntu SYNCFILETOUBUNTU
  sync-filetoubuntu SYNC-FILETOUBUNTU Sync-FileToUbuntu
  sync-filetoubuntu-from-vm.sh
)

_syncftu_install_case_links() {
  local name target
  mkdir -p "${_SYNCFTU_BIN_DIR}"
  if [[ -x "${_SYNCFTU_CANONICAL}" && ! -L "${_SYNCFTU_CANONICAL}" ]]; then
    target="${_SYNCFTU_CANONICAL}"
  elif [[ -x "${_SYNCFTU_SOURCE}" ]]; then
    target="${_SYNCFTU_SOURCE}"
  else
    return 0
  fi
  for name in "${_SYNCFTU_ALIAS_NAMES[@]}"; do
    ln -sfn "$target" "${_SYNCFTU_BIN_DIR}/${name}"
  done
}

_syncftu_install_completion_files() {
  local name
  mkdir -p "${_SYNCFTU_COMPLETION_DIR}"
  for name in syncftu "${_SYNCFTU_ALIAS_NAMES[@]}"; do
    printf '%s\n' '. /home/huangxingke/project/Python/script/common_script/syncftu_completion.sh' \
      > "${_SYNCFTU_COMPLETION_DIR}/${name}"
  done
}

_syncftu_completion() {
  local cur prev cur_lc prev_lc device_query reply opt
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  cur_lc="${cur,,}"
  prev_lc="${prev,,}"
  device_query="${cur}"

  COMPREPLY=()
  compopt +o default +o bashdefault +o dirnames +o filenames 2>/dev/null || true
  compopt -o nosort 2>/dev/null || true

  # 已输入完整 -s 但尚未空格时，先补出 -s，下一次 Tab 再列设备
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
  for opt in -s -q --quiet -f --fix-route -h --help; do
    if [[ "${opt,,}" == "${cur_lc}"* ]]; then
      COMPREPLY+=("${opt}")
    fi
  done
  return 0
}

syncftu_completion_repair() {
  local command_name
  local -a commands=(
    ./common_script/sync_filetoubuntu.sh
    "${_SYNCFTU_SOURCE}"
    "${_SYNCFTU_CANONICAL}"
    syncftu
    "${_SYNCFTU_ALIAS_NAMES[@]}"
  )

  _syncftu_install_case_links
  _syncftu_install_completion_files

  for command_name in "${commands[@]}"; do
    complete -r "${command_name}" 2>/dev/null || true
  done
  for command_name in "${commands[@]}"; do
    complete -o nosort -F _syncftu_completion "${command_name}"
  done
}

syncftu_completion_repair
