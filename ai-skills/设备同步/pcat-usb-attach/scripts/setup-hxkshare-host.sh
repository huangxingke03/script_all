#!/usr/bin/env bash
# Convert HxkShare to host-side Samba (Ubuntu -> Windows VM),
# and harden virbr0 routing against cnem hijack.
set -euo pipefail

USER_NAME="huangxingke"
SHARE_DIR="/home/${USER_NAME}/HxkShare"
FROM_WIN_DIR="/home/${USER_NAME}/FileFromWindow"
CRED="/home/${USER_NAME}/.hxkshare-cred"
ROUTE_SCRIPT="/home/huangxingke/.agents/skills/pcat-usb-attach/scripts/fix-virbr-route.sh"
SMB_CONF_D="/etc/samba/smb.conf.d"
SMB_SHARE_CONF="${SMB_CONF_D}/hxkshare.conf"

mkdir -p "$SHARE_DIR" "$FROM_WIN_DIR" "$SMB_CONF_D"
chown "${USER_NAME}:${USER_NAME}" "$SHARE_DIR" "$FROM_WIN_DIR"
chmod 755 "$SHARE_DIR" "$FROM_WIN_DIR"

# Convenience link for flash packages
ln -sfn "/home/${USER_NAME}/下载" "${SHARE_DIR}/下载" 2>/dev/null || true

chmod +x "$ROUTE_SCRIPT"
"$ROUTE_SCRIPT"

# systemd route keeper
cat > /etc/systemd/system/fix-virbr-route.service <<EOF
[Unit]
Description=Prefer virbr0 for libvirt 192.168.122.0/24
After=network-online.target libvirtd.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=${ROUTE_SCRIPT}
RemainAfterExit=yes
EOF

cat > /etc/systemd/system/fix-virbr-route.timer <<'EOF'
[Unit]
Description=Re-apply virbr0 route every 15s (fight cnem hijack)

[Timer]
OnBootSec=10
OnUnitActiveSec=15
AccuracySec=1s
Unit=fix-virbr-route.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now fix-virbr-route.timer
systemctl start fix-virbr-route.service

# Samba share: Windows maps \\192.168.122.1\HxkShare
cat > "$SMB_SHARE_CONF" <<EOF
[HxkShare]
   path = ${SHARE_DIR}
   browseable = yes
   read only = no
   writable = yes
   force user = ${USER_NAME}
   force group = ${USER_NAME}
   create mask = 0644
   directory mask = 0755
   guest ok = no
EOF

# Ensure main smb.conf includes this share once
if ! grep -q "hxkshare.conf" /etc/samba/smb.conf; then
  printf '\n# Local HxkShare for win10-pct\ninclude = %s\n' "$SMB_SHARE_CONF" >> /etc/samba/smb.conf
fi

# Allow Samba through ufw on virbr only if ufw active
if command -v ufw >/dev/null && ufw status 2>/dev/null | grep -qi 'Status: active'; then
  ufw allow in on virbr0 to any port 445 proto tcp || true
  ufw allow in on virbr0 to any port 139 proto tcp || true
fi

# Set SMB password from existing CIFS cred if present
if [[ -f "$CRED" ]]; then
  SMB_PASS="$(awk -F= '/^password=/{print substr($0,index($0,"=")+1); exit}' "$CRED")"
  SMB_USER="$(awk -F= '/^username=/{print substr($0,index($0,"=")+1); exit}' "$CRED")"
  SMB_USER="${SMB_USER:-$USER_NAME}"
  # Map Windows account name to Linux user for Samba auth simplicity:
  # create Linux-side Samba account for huangxingke using same password.
  printf '%s\n%s\n' "$SMB_PASS" "$SMB_PASS" | smbpasswd -a -s "$USER_NAME" >/dev/null
  smbpasswd -e "$USER_NAME" >/dev/null || true
  unset SMB_PASS
fi

systemctl restart smbd nmbd
systemctl enable smbd nmbd >/dev/null

# Soften broken Windows->host CIFS automounts in fstab:
# keep entries but add x-systemd.after + reconnect; comment if already unusable empty stubs preferred?
# Replace with noauto so Nautilus stops showing dead "FileFromWindow".
FSTAB=/etc/fstab
cp -a "$FSTAB" "${FSTAB}.bak.$(date +%Y%m%d%H%M%S)"
# Comment old CIFS lines (idempotent)
sed -i -E 's|^([^#].*192\.168\.122\.100/HxkShare.*)|# disabled-host-to-guest-cifs \1|' "$FSTAB"
sed -i -E 's|^([^#].*192\.168\.122\.100/FileToUbuntu.*)|# disabled-host-to-guest-cifs \1|' "$FSTAB"

systemctl daemon-reload
systemctl stop home-huangxingke-HxkShare.mount home-huangxingke-FileFromWindow.mount 2>/dev/null || true
systemctl stop home-huangxingke-HxkShare.automount home-huangxingke-FileFromWindow.automount 2>/dev/null || true
systemctl disable home-huangxingke-HxkShare.automount home-huangxingke-FileFromWindow.automount 2>/dev/null || true
umount -l "$SHARE_DIR" 2>/dev/null || true
umount -l "$FROM_WIN_DIR" 2>/dev/null || true

# Drop a README for Windows mapping
cat > "${SHARE_DIR}/README_Windows映射.txt" <<'EOF'
本目录由 Ubuntu 宿主机 Samba 共享。

在 win10-pct 资源管理器地址栏打开：
  \\192.168.122.1\HxkShare

用户名：huangxingke
密码：与原先 HxkShare/CIFS 凭据相同（.hxkshare-cred）

把刷机包直接拷到本目录（或放到「下载」子目录），Windows 即可看见。
EOF
chown -R "${USER_NAME}:${USER_NAME}" "$SHARE_DIR"

testparm -s 2>/dev/null | sed -n '/\[HxkShare\]/,/^\[/p' | head -20
echo "SMB_OK path=${SHARE_DIR}"
echo "Windows: \\\\192.168.122.1\\HxkShare"
