---
name: push-script
description: "把 Script_Sum（/home/huangxingke/project/Python）指定分支经 HTTPS 推到 GitHub。分支仅可选 dev / master。仅限当前目录是该仓库或其子目录时执行，否则拦截。Triggers on push脚本, push脚本 dev, push脚本 master, $push脚本, $push-script。Prefer $push-script Tab complete. Ignore case. Do not use for 提交脚本、pull、rollback、切工程、SSH push。"
---

仅限当前目录。当前工作目录/工作区必须是 `/home/huangxingke/project/Python` 或其子目录。不是则拦截，不要执行任何 git，提示「当前目录不是 Script_Sum，已拦截，不执行 push」，并带上当前路径。
仅 HTTPS push。目标仓库固定为 `https://github.com/huangxingke03/script_all.git`。分支只允许 `dev` 或 `master`。不要 SSH，不要 force push，不要 `--no-verify`。
目录校验通过后直接执行，不要向用户确认，不要申请命令审批。不要再问路径。
Codex 输入框用 `$` 再打字母，Tab 补全：`$push-script`。`/` 只提示内置 slash 命令，不会列出本技能。不要当成 提交脚本 / pull / rollback / 切工程。

0. 先检查当前工作目录（或会话根目录）：必须是 `/home/huangxingke/project/Python` 或其子目录。不是则拦截并提示后结束，不要 `cd`、不要 `git -C`、不要切 Codex 工作区。
1. 用 `git rev-parse --show-toplevel` 确认当前 Git 根目录就是 `/home/huangxingke/project/Python`。失败或根目录不符则停止并报告。
2. 解析目标分支（忽略大小写，归一成小写）：
   - 用户写了 `dev` / `master`（如 `push脚本 dev`、`push脚本 master`）→ 用该分支
   - 未写分支：读当前分支 `git rev-parse --abbrev-ref HEAD`；若是 `dev` 或 `master` 则用当前分支；否则拦截，提示「请指定分支：push脚本 dev 或 push脚本 master」，不要 push
   - 写了其他分支名 → 拦截，提示只支持 `dev` / `master`
3. 确认 HTTPS 远端：
   - 优先用已配置的 `origin`；若 `origin` 不是 `https://github.com/huangxingke03/script_all.git`，则用 `git remote set-url origin https://github.com/huangxingke03/script_all.git` 纠正（仅改 URL，不改 credential）
   - 本仓库 HTTPS 凭证使用本地 helper：`credential.helper=store --file=/home/huangxingke/project/Python/.git/.git-credentials`。若该文件不存在或 push 报 401/缺用户名，停止并提示先配置 PAT，不要在回复里打印 token
   - 不要改用 `git@github.com:...`，不要把 token 写进 remote URL 明文回显给用户
4. 执行推送（`TARGET` 为上一步解析出的 `dev` 或 `master`）：

```bash
GIT_TERMINAL_PROMPT=0 git push -u origin "HEAD:refs/heads/${TARGET}"
```

若当前已在目标分支上，也可：

```bash
GIT_TERMINAL_PROMPT=0 git push -u origin "${TARGET}"
```

但必须保证推上去的是本地当前 `HEAD` 到远端 `${TARGET}`。不要 `push --all`，不要顺带推别的分支。
5. 推送后输出三行：
   - `推送远端：https://github.com/huangxingke03/script_all.git`
   - `推送分支：origin/<TARGET>`
   - `本地当前分支：<git rev-parse --abbrev-ref HEAD>`
   再附 `git status -sb` 与 `git log -1 --oneline`。
6. 不要 commit，不要 pull，不要 checkout 切分支（除非用户另说），不要 reset，不要 stash，不要改 git config（除步骤 3 纠正 origin HTTPS URL），不要 amend。

失败时：
- 目录不符 / 分支非法：只提示拦截，不做 push
- 401 / 用户名无法读取：提示更新 `.git/.git-credentials` 中的 HTTPS PAT（classic 需 `repo`），不要在聊天里复述旧 token
- GH013 Push Protection / secret scanning：把拦截摘要和 unblock 链接（若有）原样报告，停止；等用户放行后再说 `push脚本 <分支>`
- non-fast-forward：停止并报告，不要 `--force`，除非用户本句明确要求强推（本技能默认仍拒绝强推，需用户另说「强制 push脚本 …」才允许 `+refs/heads/...` 或 `--force-with-lease`，且仅限 `dev`/`master`）
