#!/usr/bin/env bash
# syncftu — standalone sync: Windows VM FileToUbuntu -> Ubuntu ~/FileToUbuntu
#
# Usage:
#   syncftu                 sync once (print status)
#   syncftu --quiet         silent (timer)
#   syncftu --fix-route     pkexec fix virbr route, then sync
#
# Canonical location: project/Python/script/common_script/
# Independent of pcatusb / pcat-usb-attach.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRED="${HXKSHARE_CRED:-/home/huangxingke/.hxkshare-cred}"
DEST="${FILETOUBUNTU_DEST:-/home/huangxingke/FileFromWindow}"
VM_HOST="${FILETOUBUNTU_HOST:-192.168.122.100}"
SHARE_NAME="${FILETOUBUNTU_SHARE:-FileToUbuntu}"
ROUTE_SCRIPT="${SCRIPT_DIR}/fix_virbr_route.sh"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/sync-filetoubuntu.lock"
LOG="${SYNC_FTU_LOG:-${XDG_RUNTIME_DIR:-/tmp}/sync-ftu-${UID}.log}"

QUIET=0
FIX_ROUTE=0
for arg in "$@"; do
  case "${arg,,}" in
    -q|--quiet) QUIET=1 ;;
    -f|--fix-route) FIX_ROUTE=1 ;;
    -h|--help)
      cat <<H
用法: syncftu [--quiet|-q] [--fix-route|-f]
  通用脚本 syncftu（与 pcatusb 无关）
  源: \\\\${VM_HOST}\\${SHARE_NAME}
  目标: ${DEST}
H
      exit 0
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

run_route_fix() {
  [[ -x "$ROUTE_SCRIPT" ]] || return 0
  if [[ $(id -u) -eq 0 ]]; then
    "$ROUTE_SCRIPT" || true
  else
    pkexec "$ROUTE_SCRIPT" 2>/dev/null || true
  fi
}

if ((FIX_ROUTE)); then
  log "[*] 修复 virbr0 路由..."
  run_route_fix
fi

if ! ping -c 1 -W 1 -I virbr0 "$VM_HOST" >/dev/null 2>&1; then
  if ((FIX_ROUTE==0)); then
    die "[!] 虚拟机 ${VM_HOST} 不可达。请执行: syncftu --fix-route"
  fi
  die "[!] 虚拟机 ${VM_HOST} 仍不可达（检查 win10-pct 是否在跑）"
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

# 只覆盖/追加，不删除本地已有文件
cp -a "$TMP"/. "$DEST"/
log "[+] 完成，同步 ${count} 项 -> ${DEST}"
((QUIET)) || ls -la "$DEST" | head -30
