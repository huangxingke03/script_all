---
name: kill-android-studio
description: "杀掉本机 Android Studio，不重新拉起。Triggers on 杀掉as, 关闭as, 杀掉 as, 关闭 as, 杀掉AS, 关闭AS, 关掉as, 关掉 as, 杀掉androidstudio, 杀掉 Android Studio, 杀掉AndroidStudio, 杀掉安卓, 杀掉android, 关闭androidstudio, 关闭 Android Studio, 关掉androidstudio, 结束androidstudio, 结束as, kill android studio, killas, $kill-android-studio, $killas。Prefer $killas Tab complete. Ignore case. Do not use for 重启 Android Studio、填写日报/日报d01/日报kp31、重启 Codex、重启设备、Gradle/模拟器。"
metadata:
  short-description: Stop local Android Studio without relaunching
---

杀掉本机 `/opt/android-studio` 的 Android Studio，不要重新启动。不要再问路径，不要向用户确认，不要申请命令审批，不要带 `require_escalated`。

`杀掉as` / `关闭as` 也等同本技能。Codex 输入框用 `$` 再打字母，Tab 补全：`$killas` / `$kill-android-studio`。`/` 只提示内置 slash 命令，不会列出本技能。不要当成重启 Android Studio、重启 Codex、重启车机或只杀 Gradle。用户要重启时走 `restart-android-studio`。

1. 直接执行本技能脚本：
   `/home/huangxingke/.agents/skills/kill-android-studio/scripts/kill_android_studio.sh`
2. 脚本只结束 `/opt/android-studio` 的 IDE 进程，不要执行 `studio.sh`
3. 把脚本输出原样告诉用户：是否原本在跑、是否已停止
4. 找不到进程或停止失败时停止并报告，不要改用其他 IDE，不要随后启动 Android Studio
