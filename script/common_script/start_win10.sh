#!/usr/bin/env bash
# startWin10 — 启动 libvirt 虚拟机 win10-pct，并打开可退到后台的控制台
#
# Usage:
#   startWin10
#   startWin10 --background
#   startWin10 --viewer-only
#   WIN10_PCT_VM=other-name startWin10
set -u

VM_NAME="${WIN10_PCT_VM:-win10-pct}"
URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"
OPEN_VIEWER=1
VIEWER_ONLY=0

usage() {
  cat <<H
用法: startWin10 [-b|--background|-n|--no-viewer] [-v|--viewer-only] [-h]
  启动虚拟机 ${VM_NAME}（可用环境变量 WIN10_PCT_VM 覆盖）
  默认打开窗口化 virt-viewer（可最小化/关闭控制台，虚拟机继续后台跑）
  -b, --background, -n, --no-viewer
                    只开机，不打开控制台（纯后台）
  -v, --viewer-only 虚拟机已运行时只打开控制台
  控制台提示: 鼠标被抓取时按 Ctrl+Alt 释放，即可切回宿主机/最小化窗口
  关掉控制台 ≠ 关机；关机请用 closeWin10
H
}

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -b|--background|-n|--no-viewer) OPEN_VIEWER=0; shift ;;
    -v|--viewer-only) VIEWER_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "错误: 不支持的参数: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v virsh >/dev/null 2>&1; then
  echo "[!] 未找到 virsh" >&2
  exit 1
fi

dom_state() {
  virsh -c "$URI" domstate "$VM_NAME" 2>/dev/null | tr -d '\r' || true
}

open_viewer() {
  if ! command -v virt-viewer >/dev/null 2>&1; then
    echo "[!] 未找到 virt-viewer" >&2
    return 1
  fi
  # 窗口模式（不要 -f/-k）：可最小化、可 Alt-Tab；Ctrl+Alt 释放鼠标抓取
  # setsid -f：与启动器/终端彻底脱钩，避免“退不了后台”的粘连感
  local -a cmd=(
    virt-viewer
    -c "$URI"
    --attach
    --wait
    --reconnect
    --auto-resize=never
    --hotkeys=toggle-fullscreen=shift+f11,release-cursor=ctrl+alt
    --domain-name
    "$VM_NAME"
  )
  echo "[*] 打开控制台: ${VM_NAME}（可最小化/关闭；Ctrl+Alt 释放鼠标）"
  if command -v setsid >/dev/null 2>&1; then
    setsid -f "${cmd[@]}" >/dev/null 2>&1 < /dev/null
  else
    nohup "${cmd[@]}" >/dev/null 2>&1 < /dev/null &
    disown || true
  fi
  echo "[*] 提示: 关闭控制台窗口后虚拟机仍在后台运行；关机请用 closeWin10"
}

state=$(dom_state)
if [[ -z "$state" ]]; then
  echo "[!] 找不到虚拟机: ${VM_NAME}" >&2
  exit 1
fi

if ((VIEWER_ONLY)); then
  if [[ "$state" != "running" ]]; then
    echo "[!] 虚拟机未运行（${state}），无法只开控制台。请先 startWin10 或去掉 -v" >&2
    exit 1
  fi
  open_viewer || exit 1
  exit 0
fi

case "${state}" in
  running)
    echo "[*] 虚拟机已在运行: ${VM_NAME}"
    ;;
  *)
    echo "[*] 启动虚拟机: ${VM_NAME} (当前状态: ${state})"
    if ! virsh -c "$URI" start "$VM_NAME"; then
      echo "[!] 启动失败: ${VM_NAME}" >&2
      exit 1
    fi
    for _ in $(seq 1 40); do
      state=$(dom_state)
      [[ "$state" == "running" ]] && break
      sleep 0.5
    done
    if [[ "$state" != "running" ]]; then
      echo "[!] 启动超时，当前状态: ${state:-unknown}" >&2
      exit 1
    fi
    echo "[+] 已启动: ${VM_NAME}"
    ;;
esac

if ((OPEN_VIEWER)); then
  open_viewer || exit 0
else
  echo "[+] 已在后台运行: ${VM_NAME}（未打开控制台；需要画面时再执行 startWin10 -v）"
fi
