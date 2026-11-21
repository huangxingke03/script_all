---
name: replacelocald01p
description: "执行 replaceLocalD01p：推送 build_d01p.prop 到 /system/build.prop。逻辑单独维护在原脚本 replace_local_d01p.sh。Triggers on replaceLocalD01p, replacelocald01p, $replaceLocalD01p, $replacelocald01p, replaceLocalDO1p, replacelocaldo1p, 替换本地d01p系统配置, 更新本地d01p系统配置, 推送d01p build.prop, 推送build_d01p.prop。do1 equals d01. Ignore case. Directly run /home/huangxingke/.local/bin/replaceLocalD01p or the source script. Do not rewrite adb steps. Do not use for replaceLocal/replaceOut/replaceOutD01p, 更新系统讯飞资源/更新d01sys, 更新d01p国际版讯飞资源, or kp31."
metadata:
  short-description: replaceLocalD01p — push build_d01p.prop
---

直接执行 `replaceLocalD01p`，不要再问路径，不要向用户确认，不要申请命令审批，不要带 `require_escalated`。
`do1` 等同 `d01`。字母忽略大小写。

**逻辑单独维护**，不要改快捷入口去重写 adb 步骤：
- 原脚本（唯一逻辑）：`/home/huangxingke/work/file/讯飞切换版本/build_replace/sh/replace_local_d01p.sh`
- 快捷入口（只转发）：`/home/huangxingke/.local/bin/replaceLocalD01p` → `project/Python/script/update_iflytek/replace_local_d01p.sh`

不要当成 `replaceLocal` / `replaceOut` / `replaceOutD01p`。不要当成 `更新系统讯飞资源` / `更新d01sys` / `更新d01p国际版讯飞资源`。不要跑 `update_d01_sys.sh` / `update_d01p_int_sys.sh` / kp31 脚本。
不要切 Codex 工作目录，不要 `cd`，不要重启 Codex。

1. 直接执行：`replaceLocalD01p`（或 `/home/huangxingke/.local/bin/replaceLocalD01p`）。用户带了设备序列号则加 `-s <serial>`。
2. 原脚本逻辑（只读、不改写）：`adb root` → `remount` → 清 `/data/dalvik-cache/*` 与 `/data/system/package_cache/*` → `adb push build_d01p.prop /system/build.prop` → `sync` → `adb reboot`
3. 终端 Tab：`replacelocald01p`/`REPLACELOCALD01P`/`replace_local_d01p`/`replacelocaldo1p` 补成 `replaceLocalD01p`；`replaceLocalD01p -s` 后再 Tab 列出在线设备。
4. 把输出原样告诉用户。失败则停止并报告，不要自己补 adb 命令，不要改原脚本除非用户明确要求改逻辑。
