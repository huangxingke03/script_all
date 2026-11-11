#!/usr/bin/env bash
# syncftu — Windows VM FileToUbuntu -> Ubuntu ~/FileToUbuntu
#
# Usage:
#   syncftu
#   syncftu -s <device_serial>
#   syncftu --quiet
#   syncftu --fix-route
#
# Canonical: project/Python/script/common_script/
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED="${HXKSHARE_CRED:-/home/huangxingke/.hxkshare-cred}"
DEST="${FILETOUBUNTU_DEST:-/home/huangxingke/FileToUbuntu}"
VM_HOST="${FILETOUBUNTU_HOST:-192.168.122.100}"
SHARE_NAME="${FILETOUBUNTU_SHARE:-FileToUbuntu}"
ROUTE_SCRIPT="${SCRIPT_DIR}/fix_virbr_route.sh"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/sync-filetoubuntu.lock"
LOG="${SYNC_FTU_LOG:-${XDG_RUNTIME_DIR:-/tmp}/sync-ftu-${UID}.log}"

QUIET=0
FIX_ROUTE=0
DEVICE_SERIAL=""

usage() {
  cat <<H
用法: syncftu [-s device_serial] [--quiet|-q] [--fix-route|-f] [-h]
  通用脚本 syncftu（与 pcatusb 无关）
  源: \\\\${VM_HOST}\\${SHARE_NAME}
  目标: ${DEST}
  -s device_serial   指定关联台架设备（可选；仅校验在线，不影响 SMB 同步）
  -q, --quiet        静默
  -f, --fix-route    修复 virbr0 路由后再同步
H
}

while [[ $# -gt 0 ]]; do
  case "${1}" in
    -s)
      if [[ $# -lt 2 || "${2}" == -* ]]; then
        echo "错误: -s 需要设备序列号" >&2
        usage >&2
        exit 1
      fi
      DEVICE_SERIAL="$2"
      shift 2
      ;;
    -q|--quiet)
      QUIET=1
      shift
      ;;
    -f|--fix-route)
      FIX_ROUTE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      # 兼容旧写法：位置参数忽略大小写识别
      case "${1,,}" in
        -q|--quiet) QUIET=1; shift ;;
        -f|--fix-route) FIX_ROUTE=1; shift ;;
        *)
          echo "错误: 不支持的参数: $1" >&2
          usage >&2
          exit 1
          ;;
      esac
      ;;
  esac
done

log() { ((QUIET)) || printf '%s\n' "$*"; }
die() { printf '%s\n' "$*" >&2; exit 1; }

exec 9>"$LOCK" || true
if ! flock -n 9; then
  log "[!] 已有同步在跑，跳过"
  exit 0
fi

if [[ -n "$DEVICE_SERIAL" ]]; then
  if ! command -v adb >/dev/null 2>&1; then
    die "[!] 未找到 adb，无法校验 -s ${DEVICE_SERIAL}"
  fi
  state=$(adb -s "$DEVICE_SERIAL" get-state 2>/dev/null | tr -d '\r' || true)
  if [[ "$state" != "device" ]]; then
    die "[!] 设备未在线: ${DEVICE_SERIAL} (state=${state:-unknown})"
  fi
  log "[*] 关联设备: ${DEVICE_SERIAL}"
fi

run_route_fix() {
  [[ -x "$ROUTE_SCRIPT" ]] || return 0
  if [[ $(id -u) -eq 0 ]]; then
    "$ROUTE_SCRIPT" || true
  else
    pkexec "$ROUTE_SCRIPT" 2>/dev/null || true
  fi
}

# Default route must hit virbr0; ping -I virbr0 alone masks cnem hijack.
route_via_virbr() {
  ip route get "$VM_HOST" 2>/dev/null | grep -q ' dev virbr0'
}

vm_reachable() {
  route_via_virbr && ping -c 1 -W 1 "$VM_HOST" >/dev/null 2>&1
}

need_fix=0
if ((FIX_ROUTE)); then
  need_fix=1
elif ! route_via_virbr; then
  need_fix=1
fi

if ((need_fix)); then
  log "[*] 修复 virbr0 路由..."
  run_route_fix
fi

if ! vm_reachable; then
  if ((need_fix==0)); then
    die "[!] 虚拟机 ${VM_HOST} 不可达。请执行: syncftu --fix-route"
  fi
  die "[!] 虚拟机 ${VM_HOST} 仍不可达（检查 win10-pct / 路由是否被 cnem 抢走）"
fi

[[ -f "$CRED" ]] || die "[!] 缺少凭据: $CRED"
SMB_USER=$(awk -F= '$1=="username"{print substr($0,length($1)+2); exit}' "$CRED")
SMB_PASS=$(awk -F= '$1=="password"{print substr($0,length($1)+2); exit}' "$CRED")
[[ -n "$SMB_USER" && -n "$SMB_PASS" ]] || die "[!] 凭据不完整: $CRED"

mkdir -p "$DEST"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

log "[*] 同步 //${VM_HOST}/${SHARE_NAME} -> ${DEST}"
if ! timeout 60 smbclient "//${VM_HOST}/${SHARE_NAME}" -U "${SMB_USER}%${SMB_PASS}" -m SMB3 \
  -c "lcd $TMP; prompt OFF; mget *" >"$LOG" 2>&1; then
  die "[!] smbclient 失败，详见 $LOG"
fi

count=$(find "$TMP" -mindepth 1 | wc -l | tr -d ' ')
if [[ "$count" -eq 0 ]]; then
  log "[!] 远端目录为空，未改本地文件"
  exit 0
fi

cp -a "$TMP"/. "$DEST"/
log "[+] 完成，同步 ${count} 项 -> ${DEST}"
((QUIET)) || ls -la "$DEST" | head -30
