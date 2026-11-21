---
name: fill-daily-report
description: "PRIORITY over workspace switch / Android Studio. 填写飞书日报。用户说填写日报、写日报、填日报、填飞书日报、日报d01、日报D01、日报do1、日报kp31、日报KP31，或给出 project.feishu.cn 缺陷链接要记到 D01 / KP31 时使用。日报/填写日报后的 d01/D01/do1/kp31/KP31 只是日报栏目，不是工程切换，也不要因此重启或开关 Android Studio。写入固定知识库日报，日期按 Asia/Shanghai 当天写成「2026年10月30日」并加粗、黑色，同一天同一栏目多条编号自动累加。Triggers on 填写日报、写日报、填日报、填飞书日报、日报d01、日报D01、日报do1、日报kp31、日报KP31、填写日报d01、填写日报D01、填写日报do1、填写日报kp31、填写日报KP31。Do not use for 切换d01vat/切换do1vat/打开d01vat/d01vat/do1vat/kp31vat/kp31vst/d01vst workspace switch, 重启as, or Android Studio ensure/open/kill."
metadata:
  short-description: Fill the Feishu daily report
  requires:
    bins: ["lark-cli", "meegle", "python3"]
---

# 填写日报

## 禁止动 Android Studio

本技能优先于一切工程切换。命中后只跑下方脚本；禁止读/执行 `d01vat`/`kp31vat`/`d01vst`/`kp31vst`/`restart-android-studio`/`kill-android-studio`，禁止 `shortcut-switch-prep.sh` / `ensure_android_studio_project.sh`。

Cursor 会话开始只同步目录，不关闭、不打开 Android Studio。用户消息含 `日报` 时，提交钩子清掉待打开记录，命令钩子会拒绝准备脚本和 Android Studio 开关命令。不要改跑这些命令，也不要重试被拒绝的命令。

把飞书项目缺陷链接写进固定日报。已经给出链接和栏目后直接写，不要再确认。缺链接先问，不要猜标题，不要写没有链接的纯文本。
`日报d01` / `日报D01` / `日报do1` / `日报kp31` / `日报KP31` / `填写日报d01` / `填写日报D01` / `填写日报do1` / `填写日报kp31` / `填写日报KP31` 只表示栏目。
禁止因此调用 `d01vat` / `do1vat` / `kp31vat` / `d01vst` / `kp31vst`、`restart-android-studio` / `kill-android-studio`，禁止跑 `shortcut-switch-prep.sh` / `ensure_android_studio_project.sh` / `open_android_studio_project.sh`，禁止重启、关闭或打开 Android Studio。

文档固定为：

`https://t83dfrspj4.feishu.cn/wiki/HMLbwl1I6i2istkvgH9cYAOknjh`

用户另给了 wiki / docx 链接才换文档。不要改文档标题，不要 `overwrite` 全文。

## 格式

跟文档里已有行一致，不要按截图 OCR 改格式。

- 日期标题写成 `2026年10月30日`，不要补零，不要再用四位 `MMDD`。时区用 `Asia/Shanghai`。加粗，不设字体色，飞书默认就是黑色。不同天写入对应日期；没有这一天就按顺序补上，新的一天在文末。读到旧的 `1030` 时按同一天识别，并改成新格式。
- 栏目只有 `D01` 和 `KP31`，分栏写。`do1` 等于 `D01`。
- 编号用中文冒号：`1：`、`2：`。同一天同一栏目从已有最大编号往后加，不重排旧编号。
- 条目是带标题的普通链接，不是纯文本，也不要做成项目预览。不要在 `【】` 之间加空格。

```xml
<p><b>2026年10月30日</b></p>
<p>D01</p>
<p>1：<a href="https://project.feishu.cn/pojw7j/issue/detail/7147253441">[故障]【D01P国际右舵】【中控】【实车】【车辆设置】【高法规】【版三】【必现】AI助手语音设置，可收音区，主驾车模显示错误 1.车机上电</a></p>
<p></p>
<p>KP31</p>
<p>1：</p>
```

标题用工作项类型加名称，故障就是 `[故障]` + 工作项名称。名称里已经有这个前缀就不要再加。

## 怎么跑

只跑本技能脚本，不要手改文档。本技能与工程切换无关：即使消息里有 `kp31` / `d01` / 当前已在对应工程目录，也不要切仓库、不要拉 sdk、不要动 Android Studio。

```bash
python3 /home/huangxingke/.agents/skills/fill-daily-report/scripts/fill_daily_report.py \
  --section D01 \
  'https://project.feishu.cn/pojw7j/issue/detail/7147253441'
```

同一条消息里两个栏目都有时，一次传完：

```bash
python3 /home/huangxingke/.agents/skills/fill-daily-report/scripts/fill_daily_report.py \
  --entry D01 'https://project.feishu.cn/.../issue/detail/111' \
  --entry D01 'https://project.feishu.cn/.../issue/detail/222' \
  --entry KP31 'https://project.feishu.cn/.../issue/detail/333'
```

- 用户指定了 D01 或 KP31，就用用户指定的栏目，不要用标题改判。
- 没指定栏目时不要传 `--section`，脚本按标题推断。推断不了会退出，把标题问用户，不要猜。
- 日期默认今天。用户说了昨天、`1031`、`10月31日`、`2026年10月31日` 或 `2026-10-31` 时加 `--date`。写进文档的仍是加粗黑色的 `2026年10月31日`。
- 同一天同一栏目已有同一缺陷则跳过，不要再写一条。已有的项目预览不要改回普通链接，改写也会把项目打开。
- 不要打开项目。禁止 `meegle project search`，也禁止把链接升级成 `url_type=Project` 预览。标题用 `workitem get`，`--project-key` 直接传链接里的 simple_name。条目保持普通标题链接。
- 退出码 3 是 Meegle 未登录。先读并执行 `../meegle/references/auth-guard.md`，登录后再跑脚本。不要在脚本里发起会卡住的浏览器登录。
- 飞书文档鉴权或 scope 失败时，再读 `../lark-shared/SKILL.md` 修好后重跑。平时不要预读。

## 回复

成功后只报日期、栏目、编号、标题，以及文档链接。跳过的说明已经在哪一天哪一条。不要展开整篇日报。
