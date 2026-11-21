---
name: restart-android-studio
description: "重启本机 Android Studio：先结束现有进程，再按任务栏快捷方式拉起；重启后对比并同步已记录的字体大小。Triggers on 重启as, 重启AS, 重启androidstudio, 重启 Android Studio, 重启AndroidStudio, 重启安卓, 重启android, restart android studio, restartas, $restart-android-studio, $restartas。Prefer $restartas Tab complete. Ignore case. Do not use for 杀掉as、关闭as、填写日报/日报d01/日报kp31、重启 Codex、重启设备、Gradle/模拟器。"
metadata:
  short-description: Restart Android Studio and restore recorded fonts
---

重启本机 `/opt/android-studio` 的 Android Studio。不要再问路径，不要向用户确认，不要申请命令审批，不要带 `require_escalated`。

Codex 输入框用 `$` 再打字母，Tab 补全：`$restartas` / `$restart-android-studio`。`/` 只提示内置 slash 命令，不会列出本技能。不要当成 `杀掉as`/`关闭as`、重启 Codex、重启车机或只杀 Gradle。

已记录字体基线（`assets/as-font-baseline.json`，不要改）：
- 界面 `15.0`
- 编辑器 `14`
- 终端 `16`
- 控制台 默认

1. 直接执行本技能脚本：
   `/home/huangxingke/.agents/skills/restart-android-studio/scripts/restart_android_studio.sh`
2. 脚本先结束 `/opt/android-studio` 的 IDE 进程，再按任务栏图标同样的方式启动：从 gnome-shell 继承 DISPLAY/XAUTHORITY/DBus，用 `setsid -f gtk-launch --display jetbrains-studio`（`~/.local/share/applications/jetbrains-studio.desktop`）。不要 `systemd-run --collect`（gtk-launch 退出后会把 IDE 一起杀掉）。不要直接执行 `studio.sh`，不要把启动输出重定向到日志文件
3. 以 X 窗口出现为准，不要只看到 java 进程就报成功
4. 进程停干净后、启动前，用 `scripts/sync_android_studio_fonts.py` 对比基线字体；不一致则写回配置。界面字号要生效还必须写 `overrideLafFonts=true` 和 `fontScale=1.0`（缺了新 UI 会继续用默认 Inter 13，启动时还可能把记录字号还原成默认）。窗口起来后再核对一次，仍不一致则再停一次、同步后再拉起。不要改基线文件，不要改无关配置
5. 把脚本输出原样告诉用户：是否原本在跑、窗口是否已打开、字体是否已与记录一致或已同步
6. 找不到快捷方式、进程起来但窗口未出现或启动失败时停止并报告，不要改用其他 IDE，不要退回 `studio.sh`
