---
name: empty-amend
description: "对当前 Git 仓库执行 git commit --amend --no-edit。Triggers on 空追加, $空追加, $empty-amend。Prefer $empty-amend Tab complete. Ignore case. Do not use for push、pull、rollback、切工程、修改提交说明。"
---

在当前仓库对最近一次提交做空追加：`git commit --amend --no-edit`。不要再问路径。直接执行，不要向用户确认，不要申请命令审批。
Codex 输入框用 `$` 再打字母，Tab 补全：`$empty-amend`。`/` 只提示内置 slash 命令，不会列出本技能。不要当成 push / pull / rollback / 切工程 / 改 commit message。

1. 用 `git rev-parse --show-toplevel` 定位当前 Git 根目录；失败则停止并报告不是 git 仓库
2. 已经在该根目录时不要切目录；否则切到该根目录。不要切到其他工程
3. 执行 `git commit --amend --no-edit`
4. 输出当前工作目录和当前分支
5. 不要 push，不要 pull，不要 checkout 其他分支，不要 reset，不要 stash，不要重启 Codex

amend 失败时停止并报告，不要改参数重试、不要 `--force`。
