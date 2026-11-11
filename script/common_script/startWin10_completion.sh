#!/bin/bash
# startWin10：命令名忽略大小写；参数 Tab 提示 -n/--no-viewer/-h。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_STARTWIN10_CANONICAL="${HOME}/.local/bin/startWin10"
_STARTWIN10_SOURCE="${SCRIPT_DIR}/start_win10.sh"
_STARTWIN10_BIN_DIR="${HOME}/.local/bin"
_STARTWIN10_COMPLETION_DIR="${HOME}/.local/share/bash-completion/completions"
_STARTWIN10_ALIAS_NAMES=(
  STARTWIN10 StartWin10 startwin10 Startwin10 startWIN10
  startWin10Pct startwin10pct startWin10PCT start_win10_pct
  start_win10 start-win10
  win10pct Win10Pct WIN10PCT
)

_startwin10_install_case_links() {
  local name target
  mkdir -p "${_STARTWIN10_BIN_DIR}"
  if [[ -x "${_STARTWIN10_CANONICAL}" && ! -L "${_STARTWIN10_CANONICAL}" ]]; then
    target="${_STARTWIN10_CANONICAL}"
  elif [[ -x "${_STARTWIN10_SOURCE}" ]]; then
    target="${_STARTWIN10_SOURCE}"
  else
    return 0
  fi
  for name in "${_STARTWIN10_ALIAS_NAMES[@]}"; do
    ln -sfn "$target" "${_STARTWIN10_BIN_DIR}/${name}"
  done
}

_startwin10_install_completion_files() {
  local name
  mkdir -p "${_STARTWIN10_COMPLETION_DIR}"
  for name in startWin10 "${_STARTWIN10_ALIAS_NAMES[@]}"; do
    printf '%s\n' '. /home/huangxingke/project/Python/script/common_script/startWin10_completion.sh' \
      > "${_STARTWIN10_COMPLETION_DIR}/${name}"
  done
}

_startwin10_completion() {
  local cur cur_lc opt
  cur="${COMP_WORDS[COMP_CWORD]}"
  cur_lc="${cur,,}"

  COMPREPLY=()
  compopt +o default +o bashdefault +o dirnames +o filenames 2>/dev/null || true
  compopt -o nosort 2>/dev/null || true

  for opt in -b --background -n --no-viewer -v --viewer-only -h --help; do
    if [[ "${opt,,}" == "${cur_lc}"* ]]; then
      COMPREPLY+=("${opt}")
    fi
  done
  return 0
}

startwin10_completion_repair() {
  local command_name
  local -a commands=(
    ./common_script/start_win10.sh
    "${_STARTWIN10_SOURCE}"
    "${_STARTWIN10_CANONICAL}"
    startWin10
    "${_STARTWIN10_ALIAS_NAMES[@]}"
  )

  _startwin10_install_case_links
  _startwin10_install_completion_files

  for command_name in "${commands[@]}"; do
    complete -r "${command_name}" 2>/dev/null || true
  done
  for command_name in "${commands[@]}"; do
    complete -o nosort -F _startwin10_completion "${command_name}"
  done
}

# 兼容旧函数名
startWin10_completion_repair() { startwin10_completion_repair; }

startwin10_completion_repair
