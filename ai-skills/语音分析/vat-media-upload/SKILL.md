---
name: vat-media-upload
description: "查询语音助手多媒体状态上报：结合日志和 MediaStatusUploadUtil，梳理指定时间点之前最近一次 service status 上报。Triggers on 分析多媒体上报、查多媒体上报、最近一次上报、多媒体状态上报、MediaStatusUploadUtil。Do not use for 分析本轮语音交互, 分析多媒体交互, or vmedia repo switch. Ignore case."
metadata:
  short-description: Analyze VA media status upload
---

# 多媒体状态上报

用日志（必选）和 VoiceAssistant 代码，只查多媒体场景信息上报。读日志直接执行，不要向用户确认。不要套用 `vat-voice-issue` 的 1→5 交互分析模版。

生效目录：
- `/home/huangxingke/work/code/workCode/kp31/VoiceAssistant`
- `/home/huangxingke/work/code/workCode/d01/VoiceAssistant`

已在上述目录则直接查代码，不切工程、不重启。用户给出路径或提到 `d01vat`/`do1vat`/`kp31vat`/`d01`/`kp31` 时，到对应目录查代码。

## 怎么查

关键类：`MediaStatusUploadUtil.uploadData`。

日志：
- `MediaStatusUploadUtil` `service status ==> 1 updateMusicChange`
- `MediaStatusUploadUtil` `service status== > 2 updateMusicChange`

时间格式写 `yyyy-MM-dd HH:mm:ss.SSS`。日志行只有月日时，年份从日志文件名（如 `logcat_20260918_*`）或目录名补齐。

取数规则：
- 用户给了时间 / 指令 / 语义时间：取该时间之前最近一条，不要用之后的上报
- 同一时刻既有 `==> 1` 又有 `== > 2`：取更晚的那条
- 只有 `updateMusicStatus pkgName fail`、没有 JSON：输出 `提示：未找到有效上报`
- 完全没有上报日志：输出 `提示：未找到多媒体上报日志`

## 输出模版

只输出查到的这一条，不要扩写，不要补交互分析。不要用表格。

飞书会把 markdown 有序列表 `1.` 后面的换行吞掉。标题必须写成加粗正文，不要用有序列表。标题和下一行之间空一行。

有效值：非空字符串、数字（含 `0`）、布尔（`true`/`false`）。不要列 `null`、`""`、`[]`、`{}`、缺字段。`state` / `data` / `dataInfo` 展开内层有效字段，不要整段 JSON 原样贴出。等号前后加空格。示例只说明格式，字段以本次日志为准。

**最近一次上报时间 ：yyyy-MM-dd HH:mm:ss.SSS**

- service = musicX
- scene = default
- sceneStatus = playing
- artist = 周杰伦
- song = 晴天
- sourceType = 叶惠美
- displayId = 0
- activeStatus = fg
