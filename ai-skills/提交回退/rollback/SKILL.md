---
name: rollback
description: "按当前 Git 根目录回退未提交改动。Triggers on rollback, roolback, r00lback, r0llback, back, $rollback, $roolback, $r00lback, $r0llback, $back。Prefer $rollback Tab complete. Ignore case. Do not use for pull、push、切工程、stash、clean 未跟踪文件、界面返回。"
---

在当前仓库根目录回退已跟踪文件的未提交改动。不要再问路径。旧名 `roolback` / `r00lback` / `r0llback` / `back` 也等同本技能。直接执行，不要向用户确认，不要申请命令审批。
Codex 输入框用 `$` 再打字母，Tab 补全：`$rollback` / `$roolback` / `$r00lback` / `$r0llback` / `$back`。`/` 只提示内置 slash 命令，不会列出本技能。不要当成 pull / push / 切工程 / 界面返回。

1. 用 `git rev-parse --show-toplevel` 定位当前 Git 根目录；失败则停止并报告不是 git 仓库
2. 已经在该根目录时不要切目录；否则切到该根目录。不要切到其他工程
3. 先输出根目录、当前分支、`git status --short`
4. 在该根目录执行 `git reset --hard HEAD`，丢弃已跟踪文件的暂存区和工作区改动
5. 不要 checkout 其他分支，不要 pull，不要 push，不要 stash，不要 `git clean`，不要删除未跟踪文件，不要重启 Codex
6. 再输出根目录、当前分支、`git status --short`

没有改动时也执行 reset 并报告干净状态，不要报错。
