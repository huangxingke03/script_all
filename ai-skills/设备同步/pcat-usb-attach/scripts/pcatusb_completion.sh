#!/usr/bin/env bash
# pcatusb / pcatattach / pcat-usb-attach：命令名大小写可 Tab，参数补 VID:PID。

_PCATUSB_SCRIPT="/home/huangxingke/.agents/skills/pcat-usb-attach/scripts/pcat_usb_attach.sh"
_PCATUSB_BIN_DIR="${HOME}/.local/bin"
_PCATUSB_COMPLETION_DIR="${HOME}/.local/share/bash-completion/completions"

# 常见大小写写法；执行统一落到 canonical 名。
_PCATUSB_CANONICAL_NAMES=(pcatusb pcatattach pcat-usb-attach)
_PCATUSB_NAME_VARIANTS=(
  pcatusb PCATUSB Pcatusb PcatUsb pcatUSB PCatusb
  pcatattach PCATATTACH Pcatattach PcatAttach pcatAttach
  pcat-usb-attach PCAT-USB-ATTACH Pcat-Usb-Attach pcat-Usb-Attach
)

_pcatusb_install_case_links() {
  local name
  mkdir -p "${_PCATUSB_BIN_DIR}"
  [[ -x "${_PCATUSB_SCRIPT}" ]] || return 0
  for name in "${_PCATUSB_NAME_VARIANTS[@]}"; do
    ln -sfn "${_PCATUSB_SCRIPT}" "${_PCATUSB_BIN_DIR}/${name}"
  done
}

_pcatusb_install_completion_files() {
  local name
  mkdir -p "${_PCATUSB_COMPLETION_DIR}"
  for name in "${_PCATUSB_NAME_VARIANTS[@]}"; do
    printf '%s\n' '. /home/huangxingke/.agents/skills/pcat-usb-attach/scripts/pcatusb_completion.sh' \
      > "${_PCATUSB_COMPLETION_DIR}/${name}"
  done
}

_pcatusb_completion() {
  local cur prev cur_lc item
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  cur_lc="${cur,,}"
  COMPREPLY=()
  compopt +o default +o bashdefault +o dirnames +o filenames 2>/dev/null || true
  compopt -o nosort 2>/dev/null || true

  # 第一个参数：当前宿主机 USB VID:PID（优先 05c6），大小写不敏感匹配
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    while IFS= read -r item; do
      [[ -n ${item} && ${item,,} == "${cur_lc}"* ]] && COMPREPLY+=("${item}")
    done < <(
      {
        printf '%s\n' '05c6:9008' '05c6:900e' '05c6:901d' '05c6:90db' '18d1:d00d'
        lsusb 2>/dev/null | awk '{print tolower($6)}' | awk -F: 'NF==2{print $1":"$2}'
      } | awk 'NF && !seen[$0]++'
    )
    return 0
  fi

  # 第二个及以后：无额外参数
  return 0
}

pcatusb_completion_repair() {
  local command_name
  local -a commands=("${_PCATUSB_NAME_VARIANTS[@]}" "${_PCATUSB_CANONICAL_NAMES[@]}")
  commands+=(
    "${_PCATUSB_SCRIPT}"
    "${_PCATUSB_BIN_DIR}/pcatusb"
    "${_PCATUSB_BIN_DIR}/pcatattach"
    "${_PCATUSB_BIN_DIR}/pcat-usb-attach"
  )

  _pcatusb_install_case_links
  _pcatusb_install_completion_files

  for command_name in "${commands[@]}"; do
    complete -r "${command_name}" 2>/dev/null || true
  done
  for command_name in "${commands[@]}"; do
    complete -o nosort -F _pcatusb_completion "${command_name}"
  done
}

pcatusb_completion_repair
