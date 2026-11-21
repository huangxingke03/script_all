---
name: scriptsum
description: "Manual sidebar switch only for Script_Sum. Triggers only when the user manually clicks Script_Sum in the Cursor sidebar, or clicks the + beside it to start a chat, and the session root is already /home/huangxingke/project/Python. Do not trigger on typed words such as scriptsum, script_sum, 切换, 打开, or 打开项目. Do not pull, restart, or open Android Studio."
---

仅限手动切换。只有用户在 Cursor 左侧栏点 `Script_Sum`，或点该行旁边的 + 新开对话，且当前会话根目录已经是 `/home/huangxingke/project/Python` 时才使用本技能。

把工作目录当作 `/home/huangxingke/project/Python`。不要再问路径。在该目录查代码和改代码，并告诉用户这个路径。

不要因为消息里出现 `scriptsum`、`script_sum`、`切换`、`打开`、`打开项目` 而切换。这些词不是本技能的触发。

手动切换时：
- 不要执行 `shortcut-switch-prep.sh`、`shortcut-sync.sh`、`shortcut-restart.sh`。
- 不要 `git pull`，不要打开 Android Studio，不要改用其他 IDE。
- 不要新开对话，不要调用 `move_agent_to_root` / `move_agent_to_cloned_root`，也不要用 `rootPaths`。
- 不要调用 `list_projects` / `list_threads` / `move_thread_to_project` / `create_thread`，不要运行 `expand-sidebar-fast.py` 或 `expand-codex-sidebar-project.py`。
- 侧栏项目只用 `Script_Sum`。不要再登记名为 Python 的项目。
- 当前对话根目录不是该目录时不要切换、不要新登记，提示去侧栏打开 Script_Sum。
