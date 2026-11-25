---
name: install-latest-scripts
description: "把 Script_Sum 仓库里当前的脚本安装到 ~/.local/bin。Triggers on 安装最新脚本。Ignore case. Directly run /home/huangxingke/project/Python/script/update_scipt_all.sh. Do not use for 创建技能, 提交脚本, push脚本, pull, rollback, 更新讯飞资源, or 切工程."
---

用户说「安装最新脚本」时，把本机仓库当前脚本安装到 `~/.local/bin`。不要再问路径，不要向用户确认，不要申请命令审批。

安装的是 `/home/huangxingke/project/Python/script` 里现在的文件，包含未提交改动。不要先 `git pull`，不要 `commit`，不要 `push`。

不要修改 `update_scipt_all.sh`，不要拆开重写复制步骤。不要当成「创建技能」「提交脚本」「push脚本」、讯飞资源更新或切工程。

1. 直接执行：

```bash
bash /home/huangxingke/project/Python/script/update_scipt_all.sh
```

2. 脚本失败则停止并报告，不要改参数重试，不要改脚本。
3. 成功后告诉用户：脚本已从仓库当前文件装到 `~/.local/bin`。当前 shell 若还命中旧命令，执行 `hash -r` 或新开终端。
4. 用户点名了某个命令时，再对照仓库源文件和 `~/.local/bin` 里的副本是否一致，并说明结果。没点名则不要逐个比对。
