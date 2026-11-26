---
name: sync-skill
description: "把当前正在触发的技能最新源文件同步到 /home/huangxingke/project/Python/ai-skills，按脚本提交格式提交，提交成功后再推送。Triggers on 同步技能。Ignore case. Do not use for 更新技能, 发布最新技能, 提交脚本, push脚本, 安装最新脚本, 创建技能, or 切工程."
---

用户说「同步技能」时，把当前正在触发的技能最新源文件同步到 `/home/huangxingke/project/Python/ai-skills`，然后提交并推送。不要再问路径，不要向用户确认，不要申请命令审批。不要 `pull`，不要 `checkout`，不要 `reset`，不要 `stash`，不要 `--amend`，不要 `--no-verify`，不要 force push。不要当成「更新技能」「提交脚本」「push脚本」「安装最新脚本」「创建技能」或切工程。

当前对话在别的工程时也执行。用 `git -C /home/huangxingke/project/Python`，不要切换 Codex / Cursor 工作区。

源文件是触发时实际读取的目录：

- `/home/huangxingke/.agents/skills`
- `/home/huangxingke/.claude/skills`
- `/home/huangxingke/.cursor/skills-cursor`

目标只限 `/home/huangxingke/project/Python/ai-skills`。`~/.claude/skills` 对应 `Claude/`，`~/.cursor/skills-cursor` 对应 `Cursor内置/`，其余按仓库里已有的同名技能目录覆盖。

1. 按技能名找到仓库里的 `SKILL.md`。加载路径已经是指向该仓库目录的符号链接时，两边是同一个文件，跳过复制。同名目录多于一个时不要猜，列出来并跳过该技能。仓库里没有同名目录时不要新建分类，在结果里列出名字。
2. 内容不同时，用加载目录里的文件覆盖仓库同名技能里的对应文件。不复制 `__pycache__`、`.pyc`、`.env`、凭证、私钥。不删除只存在于仓库里的文件。
3. 同步后在 `/home/huangxingke/project/Python` 收集 `git status --short --branch`、`git diff`、`git diff --cached`、`git log -12 --oneline`。没有技能文件改动就停止，报告「没有可提交的改动」，不要空提交，不要推送。
4. 最终提交只包含技能文件：本次同步覆盖到的技能目录里的 `SKILL.md`、`agents/`、技能自带的 `scripts/` 和其他技能正文。不要提交 `ai-skills/README.md`、`ai-skills/install.sh`，不要提交 `ai-skills` 以外的任何文件，也不要提交 `__pycache__`、`.pyc`、`.env`、凭证、私钥、`.git/.git-credentials`、`script/download_feishu/*.curl`、`script/download_jira/*.curl`。不要 `git add ai-skills`，不要 `git add -A`，不要 `git commit -a`。暂存后看 `git diff --cached --name-only`，里面有非技能文件就撤出暂存再提交。
5. 提交说明沿用本仓库记录，不用 feat/chore/docs。一条中文，全角冒号加空格：新技能用 `add ：`，同步或完善用 `ref ：`，修错误行为用 `fix ：`。说明写为什么，不堆文件清单。用 HEREDOC：

```bash
git -C /home/huangxingke/project/Python commit -m "$(cat <<'EOF'
ref ： 这里写说明

EOF
)"
```

hook 拒绝就按报错修，再打新 commit，不要 `--amend`。
6. 提交成功后立刻推送。仅 HTTPS，远端必须是 `https://github.com/huangxingke03/script_all.git`；`origin` 不是这个地址时只改 URL，不改 credential，不把 token 写进地址。分支只用当前 `HEAD`：是 `dev` 或 `master` 就推它，否则停止并说明提交已在本地，不要推。凭证文件 `/home/huangxingke/project/Python/.git/.git-credentials` 缺失或 401 时停止，不要在回复里打印 token。

```bash
GIT_TERMINAL_PROMPT=0 git -C /home/huangxingke/project/Python push -u origin "HEAD:refs/heads/${TARGET}"
```

不要 `push --all`，不要强推。non-fast-forward 或 GH013 时停下并原样报告。
7. 回复依次给出：同步了哪些技能、跳过或未纳入的技能、`git log -1 --oneline`、推送远端、推送分支、本地当前分支、`git status -sb`。
