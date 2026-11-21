---
name: replacelocal
description: "执行 replaceLocal：推送本地 build.prop 到 /system/build.prop。逻辑单独维护在原脚本 replace_local.sh。Triggers on replaceLocal, replacelocal, $replaceLocal, $replacelocal, 替换本地系统配置, 更新本地系统配置, 推送本地build.prop, 推送build.prop。Ignore case. Directly run /home/huangxingke/.local/bin/replaceLocal or the source script. Do not rewrite adb steps. Do not use for replaceLocalD01p/推送build_d01p.prop, replaceOut/replaceOutD01p, 更新系统讯飞资源/更新d01sys full iflytek package update, 更新d01国际版讯飞资源, or kp31."
metadata:
  short-description: replaceLocal — push local build.prop only
---

直接执行 `replaceLocal`，不要再问路径，不要向用户确认，不要申请命令审批，不要带 `require_escalated`。
字母忽略大小写。

**逻辑单独维护**，不要改快捷入口去重写 adb 步骤：
- 原脚本（唯一逻辑）：`/home/huangxingke/work/file/讯飞切换版本/build_replace/sh/replace_local.sh`
- 快捷入口（只转发）：`/home/huangxingke/.local/bin/replaceLocal` → `project/Python/script/update_iflytek/replace_local.sh`

不要当成 `replaceLocalD01p` / 推送 `build_d01p.prop`。不要当成 `replaceOut` / `replaceOutD01p`。不要当成 `更新系统讯飞资源` / `更新d01sys`（会清应用并 reboot、拉讯飞仓库）。不要跑 `update_d01_sys.sh` / `update_d01_sys_setting.sh` / 国际版/kp31 脚本。
不要切 Codex 工作目录，不要 `cd`，不要重启 Codex。

1. 直接执行：`replaceLocal`（或 `/home/huangxingke/.local/bin/replaceLocal`）。用户带了设备序列号则加 `-s <serial>`。
2. 原脚本逻辑（只读、不改写）：`adb root` → `remount` → 清 `/data/dalvik-cache/*` 与 `/data/system/package_cache/*` → `adb push build.prop /system/build.prop` → `sync` → `adb reboot`（不拉讯飞仓、不清应用）
3. 终端 Tab：`replace`/`REPLACE`/`replacelocal` 补成 `replaceLocal`；`replaceLocal -s` 后再 Tab 列出在线设备。
4. 把输出原样告诉用户。失败则停止并报告，不要自己补 adb 命令，不要改原脚本除非用户明确要求改逻辑。
