---
name: pcat-usb-attach
description: "把宿主机 Qualcomm EDL/9008 USB 透传到 win10-pct，供 Windows PCAT 刷机。Triggers on pcatusb, PCATUSB, Pcatusb, pcatattach, pcat-usb-attach, $pcatusb, $PCATUSB, $pcatattach, $pcat-usb-attach, 透传9008, 挂载9008, 透传edl, 透传EDL, PCAT透传, pcat透传, 透传到虚拟机刷机。Prefer $pcatusb Tab complete. Ignore case. Terminal Tab: PCAT/pcat/PCATUSB 补成 pcatusb；参数补 VID:PID。Do not use for 安装高通驱动、只查 lsusb、启动虚拟机、刷机本体、ModemManager。"
metadata:
  short-description: Attach 9008 USB to win10-pct for PCAT
---

把 Ubuntu 宿主机上的 Qualcomm EDL/9008（默认 `05c6:9008`）透传到 libvirt 虚拟机 `win10-pct`，供 Windows 里 PCAT 使用。不要再问路径，不要向用户确认，不要申请命令审批，不要带 `require_escalated`。

Codex/Cursor 输入框用 `$` 再打字母，Tab 补全：`$pcatusb`。终端：`pcatusb` / `PCATUSB` / `Pcatusb` 等大小写均可，Tab 可补命令名；空格后再 Tab 补 `VID:PID`。不要当成安装高通驱动、只查 lsusb、启动虚拟机、或执行刷机步骤本身。

1. 直接执行本技能脚本：
   `/home/huangxingke/.agents/skills/pcat-usb-attach/scripts/pcat_usb_attach.sh`
2. 用户若给了 `VID:PID`（如 `05c6:900e`），原样作为参数传入；默认 `05c6:9008`。
3. 脚本在 attach 前会卸载宿主机 `qcserial` / `usb_wwan`，避免 9008 被绑成 `ttyUSB` 导致 Windows PCAT Firehose 失败；若无密码免密 sudo 且卸载失败，按脚本提示手动 `sudo modprobe -r qcserial usb_wwan` 后再跑。
4. 脚本提示（仅输出，逻辑不变）：
   - 未找到 9008：`[!] 未找到 ...` + Tip（先进 EDL，再插 Ubuntu，重跑 pcatusb）
   - 找到 9008：`[+] 已找到 9008: ...` + Tip
   - 透传成功：`[+] 透传成功: ... -> win10-pct` + Tip（去 Windows 看 QDLoader / PCAT Connect）
5. 把脚本输出原样告诉用户。
6. 失败则停止并报告：虚拟机未运行、宿主机未见 9008、或 attach 失败。不要改去装驱动、不要自动 `virsh start`、不要替用户跑 PCAT。
7. 终端命令入口统一软链到本脚本；若用户说「引用脚本更新」，重跑 `pcatusb_completion.sh` 刷新 `~/.local/bin` 软链与 bash 补全即可。
