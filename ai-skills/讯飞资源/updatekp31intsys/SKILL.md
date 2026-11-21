---
name: updatekp31intsys
description: "按 update_kp31_int_sys.sh 原逻辑更新 KP31 国际版讯飞资源。Triggers on 更新kp31国际版讯飞资源, 更新 kp31国际版讯飞资源。Ignore case. Directly run /home/huangxingke/project/Python/script/update_iflytek/update_kp31_int_sys.sh, do not rewrite or edit the script. Do not use for 更新kp31国内版讯飞资源, 更新d01国内版讯飞资源/更新d01国际版讯飞资源/更新d01p国际版讯飞资源, 更新kp31dev2/更新kp31vatdev2/更新kp31vstdev2 code pull, 推送*, or 切换*."
metadata:
  short-description: Update KP31 international iFlytek resources via update_kp31_int_sys.sh
---

直接执行 KP31 国际版讯飞资源更新脚本，不要再问路径，不要向用户确认，不要申请命令审批，不要带 `require_escalated`。
字母忽略大小写。有空格同样生效。
不要修改 `/home/huangxingke/project/Python/script/update_iflytek/update_kp31_int_sys.sh`，不要拆开重写 adb/git 步骤，原有脚本逻辑不变。
不要当成 `更新kp31国内版讯飞资源`，也不要当成 `更新d01国内版讯飞资源` / `更新d01国际版讯飞资源` / `更新d01p国际版讯飞资源`。不要当成 `更新kp31dev2` 拉代码，不要跑 `update_kp31_sys.sh` / `update_d01_sys.sh` / `update_d01_Int_sys.sh` / `update_d01p_int_sys.sh`。
不要切 Codex 工作目录，不要 `cd`，不要重启 Codex。

1. 直接执行：
   `/home/huangxingke/project/Python/script/update_iflytek/update_kp31_int_sys.sh`
   用户消息里带了 adb 设备序列号则加 `-s <serial>`；没带则不加 `-s`。
2. 脚本原逻辑（不要改、不要跳过、不要自己重写）：
   - 检查 adb 设备：多个在线设备且未指定 `-s` 则失败退出
   - `adb root` / `adb remount`，切换 `JETOUR_D01_IFLYTEK` 到 `al_chery-kp31_dev`
   - 删除并推送 `KP31_INT` 的 `/iflytek/iflytek/res`
   - 删除并推送 `KP31_INT` 的 `/system/app/Iflytek*`
   - `pm clear com.iflytek.cutefly.speechclient.hmi` 和 `com.autolink.voicesetting`
   - `adb reboot`
3. 把脚本输出原样告诉用户。脚本失败则停止并报告，不要改参数重试，不要改脚本，不要自己补 adb 命令。
