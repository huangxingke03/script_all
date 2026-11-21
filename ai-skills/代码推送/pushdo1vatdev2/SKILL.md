---
name: pushdo1vatdev2
description: "Alias of pushd01vatdev2. Gerrit 推送 d01 VoiceAssistant 当前 HEAD 到 refs/for/al_chery-d01_dev2。Triggers on pushdo1vatdev2, pushdo1vatd, $pushdo1vatdev2, $pushdo1vatd, 推送do1vatdev2, 推送d01vatdev2, 推送 do1vatdev2, 推送 d01vatdev2。do1 equals d01. 推送do1dev2/推送d01dev2 无 vat/vst，根据当前根目录默认执行 pushd01vatdev2 / pushd01vstdev2：当前根目录是 /home/huangxingke/work/code/workCode/d01/VoiceSetting 则走 pushd01vstdev2；当前根目录是 /home/huangxingke/work/code/workCode/d01/VoiceAssistant 则走本技能；否则拦截不执行并提示。Codex input $ then Tab: $pushdo1vatd = $pushdo1vatdev2. Ignore case. Slash / is builtin commands only. Do not use for do1vat workspace switch, pulld01vatdev2, pushd01vatrelease, do1vst, or kp31."
---

`pushdo1vatdev2` 等同 `pushd01vatdev2`（`pushdo1vatd`=`pushd01vatdev2`）。对 `/home/huangxingke/work/code/workCode/d01/VoiceAssistant` 执行 git，不要切工作目录，不要 `cd`，不要再问路径。当前根目录不是 `/home/huangxingke/work/code/workCode/d01/VoiceAssistant` 也不是 `/home/huangxingke/work/code/workCode/d01/VoiceSetting`（或其子目录）时，打断后续执行，不切目录，不 checkout，不 push，提示「当前目录不是 d01/VoiceAssistant 也不是 d01/VoiceSetting，已拦截，不执行推送」，并带上当前路径。
`推送do1dev2` / `推送d01dev2` 无 `vat`/`vst`：根据当前根目录默认执行 `pushd01vatdev2` / `pushd01vstdev2`。当前根目录是 `/home/huangxingke/work/code/workCode/d01/VoiceSetting`（或其子目录）时走 `pushd01vstdev2`；当前根目录是 `/home/huangxingke/work/code/workCode/d01/VoiceAssistant`（或其子目录）时走本技能；否则拦截不执行并提示。直接执行，不要向用户确认，不要申请命令审批。
Codex 输入框用 `$` 再打字母，Tab 补全：`$pushdo1vatd` → `$pushdo1vatdev2`。`/` 只提示内置 slash 命令，不会列出本技能。

0. 当前根目录不是 `/home/huangxingke/work/code/workCode/d01/VoiceAssistant` 也不是 `/home/huangxingke/work/code/workCode/d01/VoiceSetting`（或其子目录）时：打断后续执行，不要切目录，不要 checkout，不要 push，不要执行任何 git，提示「当前目录不是 d01/VoiceAssistant 也不是 d01/VoiceSetting，已拦截，不执行推送」，并带上当前路径，然后结束。
0b. 已通过第 0 步后，若本次触发词含 `vat`（如 `推送do1vatdev2`/`pushdo1vatdev2`）：当前目录必须是 `/home/huangxingke/work/code/workCode/d01/VoiceAssistant` 或其子目录，不是则打断后续执行，不要切目录，不要 checkout，不要 push，提示「当前目录不是 d01/VoiceAssistant，已拦截，不执行推送」，并带上当前路径，然后结束。不要从 VoiceSetting 切到 VoiceAssistant。
0c. 已通过第 0 步后，仅当本次触发词无 `vat`/`vst`（如 `推送do1dev2`/`推送d01dev2`）时按当前根目录分流：当前根目录是 `/home/huangxingke/work/code/workCode/d01/VoiceSetting` 或其子目录则改走 `pushd01vstdev2` 并结束；当前根目录是 `/home/huangxingke/work/code/workCode/d01/VoiceAssistant` 或其子目录则跳过本步，继续本技能。
1. 不要切工作目录，不要 `cd`，不要切分支，不要改 Codex 工作区根目录。触发词含 `vat` 时不要从其他目录切过来。所有 git 命令用 `git -C /home/huangxingke/work/code/workCode/d01/VoiceAssistant`。
2. 不要 checkout，不要切分支。用 `git -C /home/huangxingke/work/code/workCode/d01/VoiceAssistant rev-parse --abbrev-ref HEAD` 检查当前分支：已经是 `al_chery-d01_dev2` 则继续；不是则打断后续执行，不要 checkout，不要 push，提示「当前分支不是 al_chery-d01_dev2，已拦截，不执行推送」，并带上当前分支和当前路径，然后结束。
3. 执行 `git -C /home/huangxingke/work/code/workCode/d01/VoiceAssistant push origin HEAD:refs/for/al_chery-d01_dev2 --no-thin`
4. 输出当前工作目录（保持不变）和当前分支（`git -C /home/huangxingke/work/code/workCode/d01/VoiceAssistant rev-parse --abbrev-ref HEAD`）

push 失败时停止并报告，不要改参数重试、不要 `--force`，不要 checkout 改到目标分支后再推。
不要拉代码，不要拉 `sdk_release`，不要重启 Codex，不要切工作目录，不要 `cd`，不要切分支，不要切到其他工程。
