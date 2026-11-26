---
name: kp31vat
description: "Switch Codex work to kp31 VoiceAssistant. Triggers on kp31vat, kp31va, $kp31vat, /kp31vat, 切换kp31vat, 打开kp31vat, 切换 kp31vat, 打开 kp31vat. Only switch this main repo; always pull kp31 sdk_release. After sync, ensure Android Studio is on this exact project path; skip close/reopen only if already open on this path. Same-named VoiceSetting/VoiceAssistant under d01 vs kp31 are different projects. Ignore case. Do not use for 填写日报、写日报、填日报、填飞书日报, or 日报kp31/日报KP31/填写日报kp31/填写日报KP31 (those are fill-daily-report section KP31, not workspace switch; do not ensure/restart Android Studio for them). Do not use for kp31vst, d01vat, 切换kp31dev2, or 切换kp31release."
---

## 日报拦截（最高优先级）

用户消息含 `日报` / `填写日报` / `写日报` / `填日报` / `填飞书日报`（含 `日报d01`/`日报kp31`/`填写日报d01`/`填写日报kp31` 等）时，**立即停止本技能**，改走 `fill-daily-report`。不要跑准备脚本，不要拉 sdk，不要 `ensure`/`open`/`kill`/`restart` Android Studio。


把工作目录当作 `/home/huangxingke/work/code/workCode/kp31/VoiceAssistant`。
`打开kp31vat` / `切换kp31vat` 也等同本技能。有空格同样生效。
不要再问路径。在该目录查代码和改代码，并输出当前 git 分支和目录。
主工程只切目录，不要 `git pull`。每次切换都拉 `/home/huangxingke/work/code/workCode/kp31/sdk_release`，不切换过去；拉完后输出该库目录和当前分支。
终端执行 `kp31vat` 进入 Codex 后，后续操作与此相同。

## 切换步骤

不要向用户确认，不要申请审批。**默认用最快路径**：整条切换最多 2 个回合——一次准备脚本、一次新建并打开干净对话。禁止截图、禁止 `view_image`、禁止反复探测或重复核对。

1. **只跑一次准备脚本**（目录、分支、sdk 拉取、Android Studio、项目 ID 一次完成，不点侧栏）：
   `/home/huangxingke/.codex/shortcut-switch-prep.sh kp31vat`
   把输出的“工作目录 / 当前分支 / sdk 目录 / sdk 分支”和 Android Studio 结果原样告诉用户。侧栏在打开新对话之后再点。脚本里已包含 Android Studio 打开逻辑；不要再单独调用 `shortcut-info.sh`、`shortcut-sync.sh` 或 `ensure_android_studio_project.sh`。不要改用其他 IDE。
2. 按当前对话类型三选一，命中即停。`CURSOR_AGENT=1` 或 `CURSOR_CONVERSATION_ID` 非空是 Cursor 客户端，优先判断；这时 `CODEX_APP_TOOLS_PIPE_PATH` 和 `CODEX_INTERNAL_ORIGINATOR_OVERRIDE` 通常为空，不要当成命令行。

   Cursor 客户端：不要执行 `shortcut-restart.sh`，不要为工作区路径结束进程、resume、重启 Codex。不要新开对话，不要调用 `move_agent_to_root` / `move_agent_to_cloned_root`，也不要用 `rootPaths`。侧栏项目只用 `KP31-VAT`，目录是 `/home/huangxingke/work/code/workCode/kp31/VoiceAssistant`。不要再登记名为 VoiceAssistant 的项目。当前对话根目录已经是该目录时直接继续，并告诉用户这个路径。不是该目录时不要新登记，提示去侧栏打开 KP31-VAT。
侧栏点进本目录不是切换口令。上下文里若已有本次准备脚本输出，不要再跑准备脚本，不要关闭或重新打开 Android Studio。只有用户这条消息本身是切换口令时，才按上面的切换步骤处理。

   Codex 客户端（`CODEX_APP_TOOLS_PIPE_PATH` 已设置，或 `CODEX_INTERNAL_ORIGINATOR_OVERRIDE` 含 `Codex Desktop`）：**不转移当前对话记录**，不调用 `list_projects` / `list_threads` / `move_thread_to_project`，不运行 `expand-codex-sidebar-project.py`，不截图，不重启 Codex。准备脚本不点侧栏。`navigate_to_codex_page` 返回后，同一回合立刻执行一次 `python3 /home/huangxingke/.codex/expand-sidebar-fast.py --dir /home/huangxingke/work/code/workCode/kp31/VoiceAssistant --settle 0.35`，同时收起原项目并展开新项目。只跑这一次，不要截图，不要在新对话里再跑，不改底部路径。用准备脚本输出的 `项目ID: <projectId>` 新建一个干净对话：`create_thread(prompt="在<项目名>项目继续工作", target={"type":"project", "projectId":"<projectId>", "environment":{"type":"local"}}, title="<项目名>")`。新建成功后调用一次 `navigate_to_codex_page(threadId="<threadId>")` 打开新对话。最终回复里单独一行输出 `::created-thread{threadId="<threadId>"}`，并告诉用户：已打开 <项目名> 的全新对话，新对话不携带原对话记录，原对话保留，原项目侧栏收起。**不要在新对话里重复执行切换，不要再调用 `move_thread_to_project`，不要截图或核对侧栏。**

   命令行终端对话（上面两种都不是）才立刻执行 `/home/huangxingke/.codex/shortcut-restart.sh kp31vat`（最后一步，不要解释、不要确认）。脚本会留在当前窗口、结束当前进程，并用原会话 resume 到目标目录，以更新底部工作区路径。不要新开窗口。
