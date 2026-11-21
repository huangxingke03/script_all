---
name: pushd01vstrelease
description: "Gerrit 推送 d01 VoiceSetting 当前 HEAD 到 refs/for/al_chery-d01_release。Triggers on pushd01vstrelease, pushdo1vstrelease, pushd01vstr, pushdo1vstr, $pushd01vstrelease, $pushd01vstr, 推送d01vstrelease, 推送do1vstrelease, 推送 d01vstrelease, 推送 do1vstrelease, 推送d01vstrel, 推送do1vstrel, 推送 d01vstrel, 推送 do1vstrel, 推送d01release, 推送do1release, 推送 d01release, 推送 do1release when current workspace/directory is VoiceSetting。do1 equals d01. 推送d01release/推送do1release 无 vat/vst，根据当前根目录默认执行 pushd01vatrelease / pushd01vstrelease：当前根目录是 /home/huangxingke/work/code/workCode/d01/VoiceSetting 则走本技能；当前根目录是 /home/huangxingke/work/code/workCode/d01/VoiceAssistant 则走 pushd01vatrelease；否则拦截不执行并提示。Codex input $ then Tab: $pushd01vstr = $pushd01vstrelease. Ignore case. Slash / is builtin commands only. Do not use for d01vst workspace switch, pulld01vstrelease, pushd01vstdev2, d01vat, or kp31."
---

对 `/home/huangxingke/work/code/workCode/d01/VoiceSetting` 执行 git，不要切工作目录，不要 `cd`，不要再问路径。当前根目录不是 `/home/huangxingke/work/code/workCode/d01/VoiceAssistant` 也不是 `/home/huangxingke/work/code/workCode/d01/VoiceSetting`（或其子目录）时，打断后续执行，不切目录，不 checkout，不 push，提示「当前目录不是 d01/VoiceAssistant 也不是 d01/VoiceSetting，已拦截，不执行推送」，并带上当前路径。
`do1` 等同 `d01`（`pushdo1vstrelease`=`pushd01vstrelease`，`pushd01vstr`=`pushd01vstrelease`）。
`推送d01vstrelease` / `推送do1vstrelease` / `推送d01vstrel` / `推送do1vstrel` / `pushd01vstrelease` 含 `vst`：当前目录必须是 `/home/huangxingke/work/code/workCode/d01/VoiceSetting`（或其子目录），不是则拦截，不要切目录，不要 checkout，不要 push，提示「当前目录不是 d01/VoiceSetting，已拦截，不执行推送」，并带上当前路径。不要切目录。`推送d01vstrel`=`推送d01vstrelease`。有空格同样生效。
`推送d01release` / `推送do1release` 无 `vat`/`vst`：根据当前根目录默认执行 `pushd01vatrelease` / `pushd01vstrelease`。当前根目录是 `/home/huangxingke/work/code/workCode/d01/VoiceSetting`（或其子目录）时走本技能；当前根目录是 `/home/huangxingke/work/code/workCode/d01/VoiceAssistant`（或其子目录）时走 `pushd01vatrelease`，不要用本技能切到 VoiceSetting；否则拦截，不要执行任何 git，提示「当前目录不是 d01/VoiceAssistant 也不是 d01/VoiceSetting，已拦截，不执行推送」，并带上当前路径。有空格同样生效。
直接执行，不要向用户确认，不要申请命令审批。
Codex 输入框用 `$` 再打字母，Tab 补全：`$pushd01vstr` → `$pushd01vstrelease`。`/` 只提示内置 slash 命令，不会列出本技能。不要把它当成 `$d01vst` 切工程，也不要当成 `$pulld01vstrelease` 拉代码。

0. 当前根目录不是 `/home/huangxingke/work/code/workCode/d01/VoiceAssistant` 也不是 `/home/huangxingke/work/code/workCode/d01/VoiceSetting`（或其子目录）时：打断后续执行，不要切目录，不要 checkout，不要 push，不要执行任何 git，提示「当前目录不是 d01/VoiceAssistant 也不是 d01/VoiceSetting，已拦截，不执行推送」，并带上当前路径，然后结束。
0b. 已通过第 0 步后，若本次触发词含 `vst`（如 `推送d01vstrelease`/`推送d01vstrel`/`pushd01vstrelease`）：当前目录必须是 `/home/huangxingke/work/code/workCode/d01/VoiceSetting` 或其子目录，不是则打断后续执行，不要切目录，不要 checkout，不要 push，提示「当前目录不是 d01/VoiceSetting，已拦截，不执行推送」，并带上当前路径，然后结束。不要从 VoiceAssistant 切到 VoiceSetting。
0c. 已通过第 0 步后，仅当本次触发词无 `vat`/`vst`（如 `推送d01release`/`推送do1release`）时按当前根目录分流：当前根目录是 `/home/huangxingke/work/code/workCode/d01/VoiceSetting` 或其子目录则跳过本步，继续本技能；当前根目录是 `/home/huangxingke/work/code/workCode/d01/VoiceAssistant` 或其子目录则改走 `pushd01vatrelease` 并结束。
1. 不要切工作目录，不要 `cd`，不要切分支，不要改 Codex 工作区根目录。触发词含 `vst` 时不要从其他目录切过来。所有 git 命令用 `git -C /home/huangxingke/work/code/workCode/d01/VoiceSetting`。
2. 不要 checkout，不要切分支。用 `git -C /home/huangxingke/work/code/workCode/d01/VoiceSetting rev-parse --abbrev-ref HEAD` 检查当前分支：已经是 `al_chery-d01_release` 则继续；不是则打断后续执行，不要 checkout，不要 push，提示「当前分支不是 al_chery-d01_release，已拦截，不执行推送」，并带上当前分支和当前路径，然后结束。
3. 执行 `git -C /home/huangxingke/work/code/workCode/d01/VoiceSetting push origin HEAD:refs/for/al_chery-d01_release --no-thin`
4. 输出当前工作目录（保持不变）和当前分支（`git -C /home/huangxingke/work/code/workCode/d01/VoiceSetting rev-parse --abbrev-ref HEAD`）

push 失败时停止并报告，不要改参数重试、不要 `--force`，不要 checkout 改到目标分支后再推。
不要拉代码，不要拉 `sdk_release`，不要重启 Codex，不要切工作目录，不要 `cd`，不要切分支，不要切到其他工程。
