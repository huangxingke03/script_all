# 本地 AI 技能分类

这里是按功能整理的技能副本，文件从本机技能目录完整复制而来。原目录没有移动，这台电脑的技能加载不变。

技能运行时仍从下面三个目录加载：

- `~/.agents/skills`：本机工作技能、飞书技能
- `~/.cursor/skills-cursor`：Cursor 内置技能
- `~/.claude/skills`：Claude 技能

另一台电脑拉下本仓库后，在仓库根目录执行 `bash ai-skills/install.sh`。脚本把工作技能和 Claude 技能链接到上述加载目录；目标已存在则跳过，不会覆盖。Cursor 内置技能随 Cursor 自带，仓库里保留副本，安装脚本不写入 `~/.cursor/skills-cursor`。

`~/.agents/skills` 里与 Cursor 同名的内置副本没有重复收入。技能正文里的本机绝对路径保持原样。

## 工程切换

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `d01vat` | Switch Codex work to d01 VoiceAssistant. | `~/.agents/skills` |
| `do1vat` | 别名，指向 d01vat。 | `~/.agents/skills` |
| `d01vst` | Switch Codex work to d01 VoiceSetting. | `~/.agents/skills` |
| `do1vst` | 别名，指向 d01vst。 | `~/.agents/skills` |
| `kp31vat` | Switch Codex work to kp31 VoiceAssistant. | `~/.agents/skills` |
| `kp31vst` | Switch Codex work to kp31 VoiceSetting. | `~/.agents/skills` |
| `vehicle` | Switch Codex work to Live3DLauncher. | `~/.agents/skills` |
| `vmedia` | Switch Codex work to MediaCenter. | `~/.agents/skills` |
| `scriptsum` | Manual sidebar switch only for Script_Sum. | `~/.agents/skills` |

## 分支切换

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `switchd01dev2` | 切换当前 Git 仓库本地分支到 al_chery-d01_dev2，只 checkout 不 pull。 | `~/.agents/skills` |
| `switchd01release` | 切换当前 Git 仓库本地分支到 al_chery-d01_release，只 checkout 不 pull。 | `~/.agents/skills` |
| `switchd01ota3` | 切换当前 Git 仓库本地分支到 al_chery-d01_OTA3，只 checkout 不 pull。 | `~/.agents/skills` |
| `switchkp31dev2` | 切换当前 Git 仓库本地分支到 al_chery-kp31_dev2，只 checkout 不 pull。 | `~/.agents/skills` |
| `switchkp31release` | 切换当前 Git 仓库本地分支到 al_chery-kp31_release，只 checkout 不 pull。 | `~/.agents/skills` |
| `fixd01dev2` | 把本地 al_chery-d01_dev2 备份改名为 al_chery-d01_dev2_fixN（数字递增、本地不重复），再拉取远端最新并… | `~/.agents/skills` |
| `fixd01release` | 把本地 al_chery-d01_release 备份改名为 al_chery-d01_release_fixN（数字递增、本地不重复），再拉… | `~/.agents/skills` |
| `fixkp31dev2` | 把本地 al_chery-kp31_dev2 备份改名为 al_chery-kp31_dev2_fixN（数字递增、本地不重复），再拉取远端最… | `~/.agents/skills` |
| `fixkp31release` | 把本地 al_chery-kp31_release 备份改名为 al_chery-kp31_release_fixN（数字递增、本地不重复），… | `~/.agents/skills` |

## 代码推送

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `pushd01vatdev2` | Gerrit 推送 d01 VoiceAssistant 当前 HEAD 到 refs/for/al_chery-d01_dev2。 | `~/.agents/skills` |
| `pushdo1vatdev2` | 别名，指向 pushd01vatdev2。 | `~/.agents/skills` |
| `pushd01vatrelease` | Gerrit 推送 d01 VoiceAssistant 当前 HEAD 到 refs/for/al_chery-d01_release。 | `~/.agents/skills` |
| `pushdo1vatrelease` | 别名，指向 pushd01vatrelease。 | `~/.agents/skills` |
| `pushd01vstdev2` | Gerrit 推送 d01 VoiceSetting 当前 HEAD 到 refs/for/al_chery-d01_dev2。 | `~/.agents/skills` |
| `pushdo1vstdev2` | 别名，指向 pushd01vstdev2。 | `~/.agents/skills` |
| `pushd01vstrelease` | Gerrit 推送 d01 VoiceSetting 当前 HEAD 到 refs/for/al_chery-d01_release。 | `~/.agents/skills` |
| `pushdo1vstrelease` | 别名，指向 pushd01vstrelease。 | `~/.agents/skills` |
| `pushkp31vatdev2` | Gerrit 推送 kp31 VoiceAssistant 当前 HEAD 到 refs/for/al_chery-kp31_dev2。 | `~/.agents/skills` |
| `pushkp31vatrelease` | Gerrit 推送 kp31 VoiceAssistant 当前 HEAD 到 refs/for/al_chery-kp31_release。 | `~/.agents/skills` |
| `pushkp31vstdev2` | Gerrit 推送 kp31 VoiceSetting 当前 HEAD 到 refs/for/al_chery-kp31_dev2。 | `~/.agents/skills` |
| `pushkp31vstrelease` | Gerrit 推送 kp31 VoiceSetting 当前 HEAD 到 refs/for/al_chery-kp31_release。 | `~/.agents/skills` |
| `push-script` | 把 Script_Sum（/home/huangxingke/project/Python）指定分支经 HTTPS 推到 GitHub。 | `~/.agents/skills` |

## 提交回退

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `commit-script` | 把 Script_Sum（/home/huangxingke/project/Python）当前本地改动按已有提交记录格式打成一条 git c… | `~/.agents/skills` |
| `empty-amend` | 对当前 Git 仓库执行 git commit --amend --no-edit。 | `~/.agents/skills` |
| `rollback` | 按当前 Git 根目录回退未提交改动。 | `~/.agents/skills` |
| `back` | 别名，指向 rollback。 | `~/.agents/skills` |
| `roolback` | 别名，指向 rollback。 | `~/.agents/skills` |
| `r00lback` | 别名，指向 rollback。 | `~/.agents/skills` |
| `r0llback` | 别名，指向 rollback。 | `~/.agents/skills` |

## AndroidStudio

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `restart-android-studio` | 重启本机 Android Studio：先结束现有进程，再按任务栏快捷方式拉起；重启后对比并同步已记录的字体大小。 | `~/.agents/skills` |
| `kill-android-studio` | 杀掉本机 Android Studio，不重新拉起。 | `~/.agents/skills` |
| `killas` | 别名，指向 kill-android-studio。 | `~/.agents/skills` |

## 系统配置

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `replacelocal` | 执行 replaceLocal：推送本地 build.prop 到 /system/build.prop。 | `~/.agents/skills` |
| `replaceLocal` | 别名，指向 replacelocal。 | `~/.agents/skills` |
| `replacelocald01p` | 执行 replaceLocalD01p：推送 build_d01p.prop 到 /system/build.prop。 | `~/.agents/skills` |
| `replaceLocalD01p` | 别名，指向 replacelocald01p。 | `~/.agents/skills` |
| `replaceout` | 执行 replaceOut：推送 build_out.prop 到 /system/build.prop。 | `~/.agents/skills` |
| `replaceOut` | 别名，指向 replaceout。 | `~/.agents/skills` |
| `replaceoutd01p` | 执行 replaceOutD01p：推送 build_out_d01p.prop 到 /system/build.prop。 | `~/.agents/skills` |
| `replaceOutD01p` | 别名，指向 replaceoutd01p。 | `~/.agents/skills` |

## 讯飞资源

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `updated01sys` | 按 update_d01_sys.sh 原逻辑更新 D01 系统讯飞资源。 | `~/.agents/skills` |
| `updated01intsys` | 按 update_d01_Int_sys.sh 原逻辑更新 D01 国际版讯飞资源。 | `~/.agents/skills` |
| `updated01pintsys` | 按 update_d01p_int_sys.sh 原逻辑更新 D01P 国际版讯飞资源。 | `~/.agents/skills` |
| `updatekp31sys` | 按 update_kp31_sys.sh 原逻辑更新 KP31 国内版讯飞资源。 | `~/.agents/skills` |
| `updatekp31intsys` | 按 update_kp31_int_sys.sh 原逻辑更新 KP31 国际版讯飞资源。 | `~/.agents/skills` |

## 设备同步

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `pcat-usb-attach` | 把宿主机 Qualcomm EDL/9008 USB 透传到 win10-pct，供 Windows PCAT 刷机。 | `~/.agents/skills` |
| `pcatusb` | 别名，指向 pcat-usb-attach。 | `~/.agents/skills` |
| `sync-filetoubuntu` | 独立同步：Windows C:\\FileToUbuntu → Ubuntu ~/FileFromWindow。 | `~/.agents/skills` |
| `syncftu` | 别名，指向 sync-filetoubuntu。 | `~/.agents/skills` |

## 需求文言

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `d01-i18n-query` | 查询 D01 国际项目平台翻译库，结果去掉划线废弃文言。 | `~/.agents/skills` |
| `kp31-i18n-query` | 查询 KP31 飞书词条总数据的中英文资源。 | `~/.agents/skills` |
| `prd-query` | 查询 D01/kp31 语音助手产品需求（飞书 PRD 表格）。 | `~/.agents/skills` |
| `ssrd-query` | 查询 D01P国际/D01/KP31 Polarion SSRD 软件需求。 | `~/.agents/skills` |

## 语音分析

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `vat-voice-issue` | 分析语音助手多媒体问题：结合日志/视频/代码，梳理本次指令、收到语义、本地执行动作、返回状态、本次TTS。 | `~/.agents/skills` |
| `vat-media-upload` | 查询语音助手多媒体状态上报：结合日志和 MediaStatusUploadUtil，梳理指定时间点之前最近一次 service status … | `~/.agents/skills` |

## 飞书办公

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `fill-daily-report` | PRIORITY over workspace switch / Android Studio. 填写飞书日报。 | `~/.agents/skills` |
| `fill-submit-record` | 填写代码提交记录中的【原因分析】【解决方案】【自测用例】【自测方法】四段；按标题各占一行，混写输入先拆开再交付。 | `~/.agents/skills` |
| `meegle-remark` | 填写飞书项目工作项备注（评论）。 | `~/.agents/skills` |

## 飞书套件

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `lark-shared` | Use for lark-cli setup/auth tasks: auth login/status/logout, user vs bo… | `~/.agents/skills` |
| `lark-im` | 飞书即时通讯：收发消息和管理群聊。 | `~/.agents/skills` |
| `lark-mail` | 飞书邮箱： | `~/.agents/skills` |
| `lark-contact` | 飞书 / Lark 通讯录:按姓名 / 邮箱解析成 open_id,或按 open_id 反查姓名 / 部门 / 邮箱 / 联系方式 / 个人… | `~/.agents/skills` |
| `lark-calendar` | 飞书日历：管理日历日程和会议室。 | `~/.agents/skills` |
| `lark-meeting` | 飞书视频会议：查询会议记录与会议产物(纪要/逐字稿/妙记)、妙记搜索/上传/下载/编辑、机器人参与会议；查询进行中的会议、实时会议内容(发言/… | `~/.agents/skills` |
| `lark-minutes` | 仅当用户或上游配置显式指定 lark-minutes 时使用，相关请求统一交由 lark-meeting 技能处理。 | `~/.agents/skills` |
| `lark-note` | 仅当用户或上游配置显式指定 lark-note 时使用，相关请求统一交由 lark-meeting 技能处理。 | `~/.agents/skills` |
| `lark-vc` | 仅当用户或上游配置显式指定 lark-vc 时使用，相关请求统一交由 lark-meeting 技能处理。 | `~/.agents/skills` |
| `lark-vc-agent` | 仅当用户或上游配置显式指定 lark-vc-agent 时使用，相关请求统一交由 lark-meeting 技能处理。 | `~/.agents/skills` |
| `lark-task` | 飞书任务：管理任务、清单和任务智能体。 | `~/.agents/skills` |
| `lark-approval` | 飞书审批：查询和处理审批待办/已办/实例，搜索可发起审批定义、查看定义详情并发起原生审批实例。 | `~/.agents/skills` |
| `lark-okr` | 飞书 OKR：管理目标与关键结果。 | `~/.agents/skills` |
| `lark-attendance` | 飞书考勤打卡：查询自己的考勤打卡记录 | `~/.agents/skills` |
| `lark-doc` | 飞书云文档（Docx / Wiki）内容操作：读取、创建、编辑文档，插入或下载图片附件，以及操作思维笔记。 | `~/.agents/skills` |
| `lark-wiki` | 飞书知识库：管理知识空间、空间成员和文档节点。 | `~/.agents/skills` |
| `lark-drive` | 飞书云空间（云盘/云存储）：管理 Drive 文件和文件夹，包含上传/下载、创建文件夹、复制/移动/删除、查看元数据、查询权限设置、评论/权限… | `~/.agents/skills` |
| `lark-markdown` | 飞书 Markdown：查看、创建、上传、编辑和比较飞书中的原生 Markdown 文件。 | `~/.agents/skills` |
| `lark-sheets` | 飞书电子表格：创建和操作电子表格。 | `~/.agents/skills` |
| `lark-base` | 飞书多维表格（Base）操作：建表、字段、记录、视图、统计、公式/lookup、表单、仪表盘、应用模式（BaseApp/AppMode 页面与… | `~/.agents/skills` |
| `lark-slides` | 飞书幻灯片：创建和编辑幻灯片。 | `~/.agents/skills` |
| `lark-whiteboard` | > 飞书画板：查询和编辑飞书云文档中的画板。 | `~/.agents/skills` |
| `lark-apps` | 妙搭（Spark/Miaoda）应用开发与托管：应用创建、本地全栈开发、云端生成迭代、创意设计（UI mockup / 可交互原型 / 线框图… | `~/.agents/skills` |
| `lark-event` | Lark/Feishu real-time event listening / subscribing / consuming: stream… | `~/.agents/skills` |
| `lark-openapi-explorer` | 飞书/Lark 原生 OpenAPI 探索：从官方文档库中挖掘未经 CLI 封装的原生 OpenAPI 接口。 | `~/.agents/skills` |
| `lark-skill-maker` | 创建 lark-cli 的自定义 Skill。 | `~/.agents/skills` |
| `lark-workflow-meeting-summary` | 会议纪要整理工作流：汇总指定时间范围内的会议纪要并生成结构化报告。 | `~/.agents/skills` |
| `lark-workflow-standup-report` | 日程待办摘要：编排 calendar +agenda 和 task +get-my-tasks，生成指定日期的日程与未完成任务摘要。 | `~/.agents/skills` |
| `meegle` | 飞书项目（Meego/Meegle）操作工具。 | `~/.agents/skills` |

## 脚本安装

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `install-latest-scripts` | 把仓库当前脚本安装到 ~/.local/bin。触发词：安装最新脚本。 | `~/.agents/skills` |

## 会话控制

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `new-chat` | Start a fresh Codex conversation in the current project. | `~/.agents/skills` |
| `no-approval-run` | 每次触发交互后，读取和修改类指令全部不拦截、直接执行，结束后输出本次操作结果。 | `~/.agents/skills` |

## Claude

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `carher-image` | 画图 / 生成图片 / 出图 / 做配图、插画、海报、头像、示意图时用。 | `~/.claude/skills` |
| `carher-refresh-models` | 用户说「刷模型」「更新模型」「刷新模型列表」,或说 /model 里的模型不对、少了、多了、点了没权限时用。 | `~/.claude/skills` |

## Cursor内置

| 技能 | 说明 | 来源 |
| --- | --- | --- |
| `agent-sdk-create-agent` | Scaffold a new Agent SDK agent: short AskQuestion interview, then verif… | `~/.cursor/skills-cursor` |
| `automate` | Use this skill to create Cursor Automations. | `~/.cursor/skills-cursor` |
| `autopilot` | Keep a PR merge-ready by triaging comments, resolving clear conflicts, … | `~/.cursor/skills-cursor` |
| `canvas` | A Cursor Canvas is a live React app that the user can open beside the c… | `~/.cursor/skills-cursor` |
| `create-hook` | Create Cursor hooks. | `~/.cursor/skills-cursor` |
| `create-rule` | Create Cursor rules for persistent AI guidance. | `~/.cursor/skills-cursor` |
| `create-skill` | Create Cursor Agent Skills. | `~/.cursor/skills-cursor` |
| `create-subagent` | Create custom subagents for specialized AI tasks. | `~/.cursor/skills-cursor` |
| `deploy-with-vercel` | Link this repository to a Vercel project and deploy it using the Vercel… | `~/.cursor/skills-cursor` |
| `goal` | Set a goal that Cursor will pursue to completion. | `~/.cursor/skills-cursor` |
| `loop` | Run a prompt or skill in this session on a recurring or variable interv… | `~/.cursor/skills-cursor` |
| `migrate-to-skills` | Convert 'Applied intelligently' Cursor rules (.cursor/rules/*.mdc) and … | `~/.cursor/skills-cursor` |
| `new-repo` | Create a Cursor-hosted repo for the current project and push it. | `~/.cursor/skills-cursor` |
| `onboard` | Use /onboard for a focused Cursor onboarding flow that learns basic pre… | `~/.cursor/skills-cursor` |
| `origin` | Install, sign in, update, or repair the origin CLI for repos hosted on … | `~/.cursor/skills-cursor` |
| `rename-chat` | Rename the current chat to match its focus. Use only when the user invo… | `~/.cursor/skills-cursor` |
| `review` | Review code changes with the Bugbot or Security Review subagent. | `~/.cursor/skills-cursor` |
| `review-bugbot` | Review code changes with Bugbot subagent. | `~/.cursor/skills-cursor` |
| `review-security` | Review code changes with Security Review subagent. | `~/.cursor/skills-cursor` |
| `sdk` | Guide users building apps, scripts, CI pipelines, or automations on top… | `~/.cursor/skills-cursor` |
| `share` | Save, back up, or share the current project on Cursor — creates a repo … | `~/.cursor/skills-cursor` |
| `shell` | Runs the rest of a /shell request as a literal shell command. Use only … | `~/.cursor/skills-cursor` |
| `split-to-prs` | Split current work into small reviewable PRs. | `~/.cursor/skills-cursor` |
| `statusline` | Configure a custom status line in the CLI. | `~/.cursor/skills-cursor` |
| `update-cli-config` | View and modify Cursor CLI configuration settings in ~/.cursor/cli-conf… | `~/.cursor/skills-cursor` |
| `update-cursor-settings` | Modify Cursor/VSCode user settings in settings.json. | `~/.cursor/skills-cursor` |
| `visualize` | Use /visualize for creating compact charts, diagrams, or other visuals … | `~/.cursor/skills-cursor` |
