#!/usr/bin/env bash
# closeWin10 — 关闭 libvirt 虚拟机 win10-pct，释放占用内存
#
# Usage:
#   closeWin10
#   closeWin10 --force
#   WIN10_PCT_VM=other-name closeWin10
set -u

VM_NAME="${WIN10_PCT_VM:-win10-pct}"
URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"
FORCE=0
# 优雅关机等待秒数；超时后 destroy，避免 qemu 继续占内存
SHUTDOWN_WAIT="${WIN10_SHUTDOWN_WAIT:-60}"

usage() {
  cat <<H
用法: closeWin10 [--force|-f] [-h]
  关闭虚拟机 ${VM_NAME}（可用环境变量 WIN10_PCT_VM 覆盖）
  默认先 ACPI 关机，超时再用 destroy 强制断电，确保不继续占内存
  同时关闭该虚拟机的 virt-viewer 窗口
  -f, --force   跳过优雅关机，直接 destroy
H
}

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -f|--force) FORCE=1; shift ;;
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

close_viewers() {
  # 关掉该域的控制台，避免残留 GUI 进程
  pkill -f "virt-viewer.*[[:space:]]${VM_NAME}([[:space:]]|$)" 2>/dev/null || true
}

dom_state() {
  virsh -c "$URI" domstate "$VM_NAME" 2>/dev/null | tr -d '\r' || true
}

wait_shutoff() {
  local secs="$1" i state
  for ((i = 0; i < secs; i++)); do
    state=$(dom_state)
    case "${state}" in
      "shut off"|"shutoff") return 0 ;;
    esac
    sleep 1
  done
  return 1
}

qemu_gone() {
  # libvirt 关闭后 qemu 进程应退出；再扫一眼，避免残留占内存
  ! pgrep -af "qemu.*${VM_NAME}|qemu-system.*-name[[:space:]]*guest=${VM_NAME}" >/dev/null 2>&1
}

state=$(dom_state)
if [[ -z "$state" ]]; then
  echo "[!] 找不到虚拟机: ${VM_NAME}" >&2
  exit 1
fi

close_viewers

case "${state}" in
  "shut off"|"shutoff")
    echo "[*] 虚拟机已关闭: ${VM_NAME}"
    ;;
  paused|pmsuspended|suspended)
    echo "[*] 虚拟机处于 ${state}，强制断电以释放内存..."
    virsh -c "$URI" destroy "$VM_NAME" >/dev/null || true
    ;;
  running|idle|"in shutdown")
    if ((FORCE)); then
      echo "[*] 强制关闭: ${VM_NAME}"
      virsh -c "$URI" destroy "$VM_NAME" || {
        echo "[!] destroy 失败: ${VM_NAME}" >&2
        exit 1
      }
    else
      if [[ "$state" == "in shutdown" ]]; then
        echo "[*] 虚拟机正在关机: ${VM_NAME}，等待结束..."
      else
        echo "[*] 发送关机信号: ${VM_NAME}"
        if ! virsh -c "$URI" shutdown "$VM_NAME"; then
          echo "[!] shutdown 失败，改为强制关闭" >&2
          virsh -c "$URI" destroy "$VM_NAME" || exit 1
        fi
      fi
      if ! wait_shutoff "$SHUTDOWN_WAIT"; then
        echo "[!] 优雅关机超时（${SHUTDOWN_WAIT}s），强制 destroy 以释放内存"
        virsh -c "$URI" destroy "$VM_NAME" || {
          echo "[!] destroy 失败: ${VM_NAME}" >&2
          exit 1
        }
      fi
    fi
    ;;
  *)
    echo "[*] 未知状态 ${state}，尝试 destroy..."
    virsh -c "$URI" destroy "$VM_NAME" >/dev/null || true
    ;;
esac

if ! wait_shutoff 15; then
  echo "[!] 仍未 shut off，当前状态: $(dom_state)" >&2
  exit 1
fi

# 再清一次 viewer；确认 qemu 进程退出
close_viewers
sleep 0.5
if ! qemu_gone; then
  echo "[!] 仍检测到相关 qemu 进程，尝试再次 destroy..."
  virsh -c "$URI" destroy "$VM_NAME" >/dev/null 2>&1 || true
  sleep 1
  if ! qemu_gone; then
    echo "[!] qemu 进程可能仍在，请检查: pgrep -af qemu" >&2
    exit 1
  fi
fi

echo "[+] 已关闭: ${VM_NAME}（shut off，内存已释放）"
