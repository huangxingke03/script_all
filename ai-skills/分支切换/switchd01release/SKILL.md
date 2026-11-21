---
name: switchd01release
description: "切换当前 Git 仓库本地分支到 al_chery-d01_release，只 checkout 不 pull。Triggers on 切换d01release, 切换do1release, 切换d01rel, 切换 d01release, 切换 d01rel, 切换 do1release, $切换d01release, $切换d01rel。do1 equals d01. Ignore case. 不拦目录：本地有分支就切，没有则 fetch 远端后创建并检出。Do not use for switchd01release, $switchd01release, standalone d01rel/do1rel, d01vat workspace switch, 切换d01dev2, or 切换d01ota3."
---

在当前 Git 仓库把本地分支切到 `al_chery-d01_release`。不要拦目录，不要要求当前目录是 VoiceAssistant。不要再问路径。直接执行，不要向用户确认，不要申请命令审批。
`切换d01release` / `切换d01rel` / `切换do1release` 等同本技能，有空格同样生效。`do1` 等同 `d01`。字母忽略大小写。不要用单独的 `d01rel`/`do1rel` 触发本技能。
不要当成 `$d01vat` 切工程，不要当成 `切换d01dev2`/`切换d01ota3`。不要用全是字母的触发词（如 `switch*` / `$switch*`）。`/` 只提示内置 slash 命令，不会列出本技能。
不要当成 `更新*` 拉代码，不要当成切工程。

0. 用当前工作目录解析 Git 根目录：`git rev-parse --show-toplevel`。不是 git 仓库则拦截，不要执行任何 git，提示「当前目录不是 git 仓库，已拦截，不执行切换」，并带上当前路径后结束。不要 `cd`，不要改 Codex 工作区根目录。后续 git 一律 `git -C <Git根目录>`。
1. 本地已有 `al_chery-d01_release`：当前分支已经是该分支则不要 checkout；否则 `git -C <Git根目录> checkout al_chery-d01_release`。
2. 本地没有 `al_chery-d01_release`：`git -C <Git根目录> fetch origin al_chery-d01_release`，再基于 `origin/al_chery-d01_release` 创建并检出本地 `al_chery-d01_release`。
3. 不要 `git pull`，不要 rebase。
4. 输出当前工作目录和当前分支。

checkout 因未提交改动失败时，停止并报告脏工作区，不要 `git reset --hard`、不要 stash、不要 push。
不要拉 `sdk_release`，不要重启 Codex，不要切 Codex 工作目录，不要切到其他工程。
