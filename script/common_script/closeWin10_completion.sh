#!/bin/bash
# closeWin10：命令名忽略大小写；参数 Tab 提示 -f/--force/-h。

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_CLOSEWIN10_CANONICAL="${HOME}/.local/bin/closeWin10"
_CLOSEWIN10_SOURCE="${SCRIPT_DIR}/close_win10.sh"
_CLOSEWIN10_BIN_DIR="${HOME}/.local/bin"
_CLOSEWIN10_COMPLETION_DIR="${HOME}/.local/share/bash-completion/completions"
_CLOSEWIN10_ALIAS_NAMES=(
  CLOSEWIN10 CloseWin10 closewin10 Closewin10 closeWIN10
  close_win10 close-win10
  stopWin10 STOPWIN10 stopwin10 stop_win10
)

_closewin10_install_case_links() {
  local name target
  mkdir -p "${_CLOSEWIN10_BIN_DIR}"
  if [[ -x "${_CLOSEWIN10_CANONICAL}" && ! -L "${_CLOSEWIN10_CANONICAL}" ]]; then
    target="${_CLOSEWIN10_CANONICAL}"
  elif [[ -x "${_CLOSEWIN10_SOURCE}" ]]; then
    target="${_CLOSEWIN10_SOURCE}"
  else
    return 0
  fi
  for name in "${_CLOSEWIN10_ALIAS_NAMES[@]}"; do
    ln -sfn "$target" "${_CLOSEWIN10_BIN_DIR}/${name}"
  done
}

_closewin10_install_completion_files() {
  local name
  mkdir -p "${_CLOSEWIN10_COMPLETION_DIR}"
  for name in closeWin10 "${_CLOSEWIN10_ALIAS_NAMES[@]}"; do
    printf '%s\n' '. /home/huangxingke/project/Python/script/common_script/closeWin10_completion.sh' \
      > "${_CLOSEWIN10_COMPLETION_DIR}/${name}"
  done
}

_closewin10_completion() {
  local cur cur_lc opt
  cur="${COMP_WORDS[COMP_CWORD]}"
  cur_lc="${cur,,}"

  COMPREPLY=()
  compopt +o default +o bashdefault +o dirnames +o filenames 2>/dev/null || true
  compopt -o nosort 2>/dev/null || true

  for opt in -f --force -h --help; do
    if [[ "${opt,,}" == "${cur_lc}"* ]]; then
      COMPREPLY+=("${opt}")
    fi
  done
  return 0
}

closewin10_completion_repair() {
  local command_name
  local -a commands=(
    ./common_script/close_win10.sh
    "${_CLOSEWIN10_SOURCE}"
    "${_CLOSEWIN10_CANONICAL}"
    closeWin10
    "${_CLOSEWIN10_ALIAS_NAMES[@]}"
  )

  _closewin10_install_case_links
  _closewin10_install_completion_files

  for command_name in "${commands[@]}"; do
    complete -r "${command_name}" 2>/dev/null || true
  done
  for command_name in "${commands[@]}"; do
    complete -o nosort -F _closewin10_completion "${command_name}"
  done
}

closeWin10_completion_repair() { closewin10_completion_repair; }

closewin10_completion_repair
