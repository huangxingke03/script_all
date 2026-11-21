---
name: commit-script
description: "把 Script_Sum（/home/huangxingke/project/Python）当前本地改动按已有提交记录格式打成一条 git commit。仅限当前目录是该仓库或其子目录时执行，否则拦截。Triggers on 提交脚本, $提交脚本, $commit-script。Prefer $commit-script Tab complete. Ignore case. Do not use for push、pull、rollback、切工程、空追加、填写提交记录。"
---

仅限当前目录。当前工作目录/工作区必须是 `/home/huangxingke/project/Python` 或其子目录。不是则拦截，不要执行任何 git，提示「当前目录不是 Script_Sum，已拦截，不执行提交」，并带上当前路径。字母忽略大小写（`提交脚本`=`$commit-script`）。
对 `/home/huangxingke/project/Python` 执行提交。不要再问路径。目录校验通过后直接执行，不要向用户确认，不要申请命令审批。
Codex 输入框用 `$` 再打字母，Tab 补全：`$commit-script`。`/` 只提示内置 slash 命令，不会列出本技能。不要当成 push / pull / rollback / 切工程 / empty-amend / 填写提交记录。

0. 先检查当前工作目录（或会话根目录）：必须是 `/home/huangxingke/project/Python` 或其子目录。不是则拦截并提示后结束，不要 `cd`、不要 `git -C`、不要切 Codex 工作区。
1. 用 `git rev-parse --show-toplevel` 确认当前 Git 根目录就是 `/home/huangxingke/project/Python`。失败或根目录不符则停止并报告。已经在该根或其子目录时不要切到其他工程。
2. 并行收集（在当前仓库内执行，可用 `git -C "$(git rev-parse --show-toplevel)"`）：
   - `git status --short --branch`
   - `git diff` 与 `git diff --cached`
   - `git log -12 --oneline`
3. 若无已暂存、无未暂存、无未跟踪改动：停止并报告「没有可提交的改动」，不要空提交。
4. 选择提交前缀（沿用本仓库历史，不要用 feat/chore/docs 等约定式英文前缀）：
   - `add ：` 全新脚本/能力/文件
   - `ref ：` 完善、扩展、梳理、同步文档、补全增强
   - `fix ：` 修 bug、修失败路径、修错误行为
   - 历史里偶见半角 `ref :` / `add :`；新提交统一用全角冒号加空格：`add ：` / `ref ：` / `fix ：`
5. 提交说明：1 行中文，前缀后接简短「为什么/结果」，不要堆文件清单。对照 `git log` 风格，例如：
   - `add ： 添加gitignore`
   - `ref ： 飞书下载脚本完善`
   - `fix ： 飞书下载附件脚本解压失败，名字乱码优化`
6. 暂存范围：
   - 默认把本次相关改动全部 `git add`（含未跟踪的新脚本）
   - **不要**暂存含登录态的请求模板：`script/download_feishu/*.curl`、`script/download_jira/*.curl`（Cookie/Token）。若用户明确要求提交这些文件，先警告再按用户要求处理
   - 不要提交 `.env`、凭证、私钥、`.git/.git-credentials`
7. 用 HEREDOC 提交（不要 `-i`，不要 `--no-verify`，不要 amend，除非用户另触发 empty-amend）：

```bash
git commit -m "$(cat <<'EOF'
ref ： 这里写说明

EOF
)"
```

8. 提交后输出：`git status -sb`、最新 `git log -1 --oneline`。
9. 不要 push，不要 pull，不要 checkout，不要 reset，不要 stash，不要改 git config。

失败时：
- 目录不符：只提示拦截，不做任何 git
- pre-commit / hook 拒绝：按报错修，再打 **新** commit，不要 `--amend`
- 无改动 / 仅被排除的 curl 改动：说明原因后结束
