#!/usr/bin/env bash
# Attach Qualcomm EDL/9008 (or given VID:PID) to win10-pct for PCAT.
# Usage: pcatusb [VID:PID]   default 05c6:9008
set -euo pipefail

VM="${VM_NAME:-win10-pct}"
VIDPID="${1:-05c6:9008}"
VID="${VIDPID%%:*}"
PID="${VIDPID##*:}"
VID="0x${VID#0x}"
PID="0x${PID#0x}"
VID_HEX="${VID#0x}"
PID_HEX="${PID#0x}"

if ! command -v virsh >/dev/null 2>&1; then
  echo "[!] virsh not found. Install libvirt client first." >&2
  exit 1
fi

STATE="$(virsh domstate "$VM" 2>/dev/null || true)"
if [[ "$STATE" != "running" ]]; then
  echo "[!] VM '$VM' is not running (state: ${STATE:-unknown})."
  echo "    Start it first, e.g.: virsh start $VM"
  exit 1
fi

echo "[*] Looking for USB ${VID_HEX}:${PID_HEX} ..."
if ! lsusb | grep -qi "${VID_HEX}:${PID_HEX}"; then
  echo "[!] 未找到 ${VIDPID}（宿主机 lsusb 无此设备）"
  echo "    Tip: 先让板子进 EDL/9008，再插到 Ubuntu，然后重跑 pcatusb ${VIDPID}"
  echo "    1) Board -> EDL/9008 (dip/short as flash doc)."
  echo "    2) Power on WITHOUT USB to PC, then plug USB to Ubuntu."
  echo "    3) Re-run: pcatusb ${VIDPID}"
  echo
  echo "Current lsusb:"
  lsusb
  exit 1
fi
FOUND_LINE="$(lsusb | grep -i "${VID_HEX}:${PID_HEX}" | head -n1)"
echo "[+] 已找到 9008: ${FOUND_LINE}"
echo "    Tip: 设备已就绪，下一步卸载 qcserial 并透传到 ${VM}。"

# Host qcserial binds 9008 as ttyUSB and breaks Windows PCAT / Firehose.
# Local-only sudo password fallback (prefer NOPASSWD sudoers when available).
PCATUSB_SUDO_PASS="${PCATUSB_SUDO_PASS:-092603clABC}"
pcatusb_sudo() {
  if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo -n "$@"
    return
  fi
  printf '%s\n' "${PCATUSB_SUDO_PASS}" | sudo -S -p '' "$@"
}

echo "[*] Unloading host qcserial/usb_wwan (keep 9008 free for VM PCAT) ..."
if command -v sudo >/dev/null 2>&1; then
  pcatusb_sudo modprobe -r qcserial 2>/dev/null || true
  pcatusb_sudo modprobe -r usb_wwan 2>/dev/null || true
else
  modprobe -r qcserial 2>/dev/null || true
  modprobe -r usb_wwan 2>/dev/null || true
fi
if lsmod | grep -qE '^(qcserial|usb_wwan) '; then
  echo "[!] Still loaded: $(lsmod | awk '/^(qcserial|usb_wwan) /{print $1}' | paste -sd' ' -)"
  echo "    Run once: sudo modprobe -r qcserial usb_wwan"
  echo "    Then re-run: pcatusb ${VIDPID}"
else
  echo "[+] Host qcserial/usb_wwan not loaded"
fi

TMP="$(mktemp)"
REDIR_TMP="$(mktemp)"
trap 'rm -f "$TMP" "$REDIR_TMP"' EXIT
cat >"$TMP" <<XML
<hostdev mode='subsystem' type='usb' managed='yes'>
  <source>
    <vendor id='${VID}'/>
    <product id='${PID}'/>
  </source>
</hostdev>
XML

# Drop leftover experimental qemu usb-host nodes from older pcatusb attempts.
virsh qemu-monitor-command "$VM" --hmp 'device_del q9008' >/dev/null 2>&1 || true

free_usb_port() {
  # qemu-xhci default only has 4 ports; tablet+2x spice redir can fill them.
  cat >"$REDIR_TMP" <<'XML'
<redirdev bus='usb' type='spicevmc'>
  <address type='usb' bus='0' port='3'/>
</redirdev>
XML
  virsh detach-device "$VM" "$REDIR_TMP" --live >/dev/null 2>&1 || true
}

echo "[*] Attaching ${VID_HEX}:${PID_HEX} -> VM ${VM}"
virsh detach-device "$VM" "$TMP" --live >/dev/null 2>&1 || true
sleep 0.3

if virsh attach-device "$VM" "$TMP" --live; then
  echo "[+] 透传成功: ${VID_HEX}:${PID_HEX} -> ${VM}"
  echo "    Tip: Windows 设备管理器看 QDLoader 9008，然后 PCAT Connect / 刷新。"
  exit 0
fi

echo "[!] attach-device failed. Freeing a USB port and retrying..."
free_usb_port
virsh detach-device "$VM" "$TMP" --live >/dev/null 2>&1 || true
sleep 0.5
if virsh attach-device "$VM" "$TMP" --live; then
  echo "[+] 透传成功(已腾出 USB 口): ${VID_HEX}:${PID_HEX} -> ${VM}"
  echo "    Tip: Windows 设备管理器看 QDLoader 9008，然后 PCAT Connect / 刷新。"
  exit 0
fi

echo "[!] still failing. Last resort detach+attach..."
virsh detach-device "$VM" "$TMP" --live >/dev/null 2>&1 || true
sleep 1
virsh attach-device "$VM" "$TMP" --live
echo "[+] 透传成功(重试后): ${VID_HEX}:${PID_HEX} -> ${VM}"
echo "    Tip: Windows 设备管理器看 QDLoader 9008，然后 PCAT Connect / 刷新。"
