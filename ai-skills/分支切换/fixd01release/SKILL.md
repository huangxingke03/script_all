---
name: fixd01release
description: "把本地 al_chery-d01_release 备份改名为 al_chery-d01_release_fixN（数字递增、本地不重复），再拉取远端最新并切到新的本地分支 al_chery-d01_release。Triggers on 换一个d01release, 换一个 d01release, $换一个d01release, 换一个do1release, 换一个d01rel, 换一个 d01rel, $换一个d01rel, 换一个do1rel, 换一个d01release分支, 换一个 d01release 分支, $换一个d01release分支, 换新d01release, 换新 d01release, $换新d01release, 换新do1release。do1 equals d01. Ignore case. 不拦目录：对当前 Git 根目录执行。Do not use for fixd01release, 换一个d01dev2/fixd01dev2, 切换d01release/switchd01release checkout-only, d01vat/d01vst workspace switch, or kp31."
---

在当前 Git 仓库执行两步：1）把本地分支 `al_chery-d01_release` 改名为 `al_chery-d01_release_fixN`（`N` 从 1 递增，保证本地不重复）；2）拉取远端 `al_chery-d01_release` 最新代码，并切换到新的本地分支 `al_chery-d01_release`。
不要拦目录，不要要求特定工程路径。不要再问路径。直接执行，不要向用户确认，不要申请命令审批。
`换一个d01release` / `换一个 d01release` / `$换一个d01release` / `换一个do1release` / `换一个d01rel` / `换一个 d01rel` / `$换一个d01rel` / `换一个do1rel` / `换一个d01release分支` / `换一个 d01release 分支` / `$换一个d01release分支` / `换新d01release` / `换新 d01release` / `$换新d01release` / `换新do1release` 等同本技能，有空格同样生效。`do1` 等同 `d01`。字母忽略大小写。
不要当成 `更新d01release` 只拉不改名，不要当成 `切换d01release` 只 checkout，不要当成 `换一个d01dev2` / `换新d01dev2`，不要当成 `$d01vat`/`$d01vst` 切工程。不要用单独的 `d01release` / `d01rel` / `fixd01release` 触发。也不要当成 `换一个kp31release` / `换新kp31release`。`/` 只提示内置 slash 命令，不会列出本技能。

0. 用当前工作目录解析 Git 根目录：`git rev-parse --show-toplevel`。不是 git 仓库则拦截，不要执行任何 git，提示「当前目录不是 git 仓库，已拦截，不执行换新」，并带上当前路径后结束。不要 `cd`，不要改 Codex/Cursor 工作区根目录。后续 git 一律 `git -C <Git根目录>`。
1. 改名（保证本地不重复）：
   - 本地没有 `al_chery-d01_release`：跳过改名，进入步骤 2。
   - 本地已有 `al_chery-d01_release`：从 `N=1` 起检查本地是否已有 `al_chery-d01_release_fixN`；已有则 `N+=1`，直到找到不存在的名字。然后执行 `git -C <Git根目录> branch -m al_chery-d01_release al_chery-d01_release_fixN`。
   - 只改名本地分支，不要删分支，不要 push，不要改远端。
2. 拉取远端并切到新本地分支 `al_chery-d01_release`：
   - `git -C <Git根目录> fetch origin al_chery-d01_release`
   - 基于 `origin/al_chery-d01_release` 创建并检出本地新分支：`git -C <Git根目录> checkout -b al_chery-d01_release origin/al_chery-d01_release`
   - 若因意外仍存在同名本地分支导致 `-b` 失败：停止并报告，不要 `reset --hard`、不要 stash、不要强删。
3. 输出固定四行，不要少、不要改名：
   - `原分支备份为：<改名后的名字；若未改名则写 未改名>`
   - `拉取远端分支：origin/al_chery-d01_release`
   - `本地根目录：<当前工作目录，保持不变>`
   - `本地当前分支：<git -C <Git根目录> rev-parse --abbrev-ref HEAD>`

改名 / fetch / checkout 因未提交改动或其他原因失败时，停止并报告，不要 `git reset --hard`、不要 stash、不要 push、不要删分支。
不要拉 `sdk_release`，不要重启 Codex/Cursor，不要切工作目录，不要切到其他工程。
