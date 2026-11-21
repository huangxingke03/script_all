---
name: sync-filetoubuntu
description: "独立同步：Windows C:\\FileToUbuntu → Ubuntu ~/FileFromWindow。Triggers on syncftu, SYNCFTU, SyncFtu, syncFileToUbuntu, sync-filetoubuntu, $syncftu, $SYNCFTU, $syncFileToUbuntu, 同步FileToUbuntu, 拉FileToUbuntu, FileFromWindow。Prefer $syncftu Tab complete. Ignore case. Do not use for pcatusb/9008透传、HxkShare、刷机。"
metadata:
  short-description: Standalone sync VM FileToUbuntu to Ubuntu FileFromWindow
---

独立通用命令，与 `pcatusb` 无关。Ubuntu 侧目录仅为 `~/FileFromWindow`（不再使用 FileToUbuntu）。

**逻辑唯一源码**（勿在技能目录改业务逻辑）：
- `/home/huangxingke/project/Python/script/common_script/sync_filetoubuntu.sh`
- `/home/huangxingke/project/Python/script/common_script/fix_virbr_route.sh`
- 说明文档：`/home/huangxingke/project/Python/script/command_aliases.md` 中 `## Sync FileToUbuntu`

发布入口：`updateSciptAll` → `~/.local/bin/syncftu`

不要再问路径，不要向用户确认，不要申请命令审批。修路由用 `--fix-route`（可能弹出 pkexec）。

1. 直接执行：`syncftu`（或 `/home/huangxingke/.local/bin/syncftu`）
2. 不可达时：`syncftu --fix-route`；定时器：`syncftu --quiet`
3. 把输出原样告诉用户。失败则停止，不要改去挂 CIFS，不要清空本地目录，不要调用 pcatusb。
4. 不要改技能目录里的 forwarder 去重写同步逻辑；要改就改 `common_script/`。
