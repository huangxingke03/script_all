---
name: vmedia
description: "Switch Codex work to MediaCenter. Triggers on vmedia, vm, media, $vmedia, /vmedia, 切换vmedia, 打开vmedia, 切换 vmedia, 打开 vmedia, 切换多媒体中心, 打开多媒体中心, 切换 多媒体中心, 打开 多媒体中心. Plain switch only changes directory: pull latest, print workdir and branch, do not open Android Studio. Also triggers when those phrases include 打开项目, spaces optional, such as 切换多媒体中心打开项目 and 切换多媒体中心 打开项目: same directory switch, then open this Android Studio project in an extra window without closing projects already open. Skip if this exact path is already open. Do not kill or restart Android Studio. Ignore case. Do not use for vehicle, 分析多媒体交互, or 多媒体上报."
---

把工作目录当作 `/home/huangxingke/work/code/workCode/other/MediaCenter`。
`打开vmedia` / `切换vmedia` / `打开多媒体中心` / `切换多媒体中心` 也等同本技能。有空格同样生效。
不要再问路径。在该目录查代码和改代码。

每次切换只跑一次准备脚本（切目录、拉最新代码、输出目录和分支；普通切换不打开 Android Studio）：
  `/home/huangxingke/.codex/shortcut-switch-prep.sh vmedia`

是否打开 Android Studio 看本条触发词，不是持久配置：
- 普通切换只切目录。`vmedia` / `打开多媒体中心` / `切换多媒体中心`，以及带空格、忽略大小写的同等写法，都不要打开 Android Studio。`打开多媒体中心` 里的「打开」不是打开项目。
- 只有同一条消息同时含本技能触发词和 `打开项目`（`打开` 和 `项目` 之间可以有空格）才额外打开。例如 `切换多媒体中心打开项目`、`切换多媒体中心 打开项目`、`打开多媒体中心打开项目`、`vmedia打开项目`。这时改用：
  `/home/huangxingke/.codex/shortcut-switch-prep.sh vmedia open_project`
  把脚本输出原样告诉用户。已打开本路径会跳过，不要重复打开；不要关闭、不要杀掉已打开的工程，不要套用 vat/vst 的先关闭再打开。不要改用其他 IDE。

按当前对话类型三选一，命中即停。`CURSOR_AGENT=1` 或 `CURSOR_CONVERSATION_ID` 非空是 Cursor 客户端，优先判断；这时 `CODEX_APP_TOOLS_PIPE_PATH` 和 `CODEX_INTERNAL_ORIGINATOR_OVERRIDE` 通常为空，不要当成命令行。

Cursor 客户端：不要执行 `shortcut-restart.sh`，不要为工作区路径结束进程、resume、重启 Codex。不要新开对话，不要调用 `move_agent_to_root` / `move_agent_to_cloned_root`，也不要用 `rootPaths`。侧栏项目只用 `多媒体中心（D01-KP31）`，目录是 `/home/huangxingke/work/code/workCode/other/MediaCenter`。不要再登记名为 MediaCenter 的项目。当前对话根目录已经是该目录时直接继续，并告诉用户这个路径。不是该目录时不要新登记，提示去侧栏打开多媒体中心（D01-KP31）。
侧栏点进本目录不是切换口令。上下文里若已有本次准备脚本输出，不要再跑准备脚本，不要关闭或重新打开 Android Studio。只有用户这条消息本身是切换口令时，才按上面的切换步骤处理。

Codex 客户端（`CODEX_APP_TOOLS_PIPE_PATH` 已设置，或 `CODEX_INTERNAL_ORIGINATOR_OVERRIDE` 含 `Codex Desktop`）：**不转移当前对话记录**，不调用 `list_projects` / `list_threads` / `move_thread_to_project`，不运行 `expand-codex-sidebar-project.py`，不截图，不重启 Codex。准备脚本不点侧栏。`navigate_to_codex_page` 返回后，同一回合立刻执行一次 `python3 /home/huangxingke/.codex/expand-sidebar-fast.py --dir /home/huangxingke/work/code/workCode/other/MediaCenter --settle 0.35`，同时收起原项目并展开新项目。只跑这一次，不要截图，不要在新对话里再跑，不改底部路径。用准备脚本输出的 `项目ID: <projectId>` 新建一个干净对话：`create_thread(prompt="在<项目名>项目继续工作", target={"type":"project", "projectId":"<projectId>", "environment":{"type":"local"}}, title="<项目名>")`。新建成功后调用一次 `navigate_to_codex_page(threadId="<threadId>")` 打开新对话。最终回复里单独一行输出 `::created-thread{threadId="<threadId>"}`，并告诉用户：已打开 <项目名> 的全新对话，新对话不携带原对话记录，原对话保留，原项目侧栏收起。**不要在新对话里重复执行切换，不要再调用 `move_thread_to_project`，不要截图或核对侧栏。**

命令行终端对话（上面两种都不是）才立刻执行 `/home/huangxingke/.codex/shortcut-restart.sh vmedia`（最后一步，不要解释、不要确认）。脚本会留在当前窗口、结束当前进程，并用原会话 resume 到目标目录，以更新底部工作区路径。不要新开窗口。
