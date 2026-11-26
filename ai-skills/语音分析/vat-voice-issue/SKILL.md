---
name: vat-voice-issue
description: "分析语音助手多媒体问题：结合日志/视频/代码，梳理本次指令、收到语义、本地执行动作、返回状态、本次TTS。时间优先用视频拍摄水印，没有水印用句式指定时间，没有指定时间用车机屏幕时间。句式优先用指定句式，没有指定用视频画面显示句式。规则内命中几轮输出几轮。同一次业务若多媒体状态码回调多次，按时间顺序写多次第4段，有对应播报再写多次第5段，不要只留首次。本地没收到语义就是没收到语义：只认 `dispatchSemantic : request =` 和 ` handleVoiceJsonData : service =`（另加已有的国际版 onReceive、免唤醒 handWakeupAction）。云端 NLU、捷途或其他进程的 FC/NLG/TTS 不算。无这些入口日志时第1段后写提示，有播报再写提示语，不要写本地code，不要补2-5段。有语义仍走2-5段。写备注时按 meegle-remark：默认只写正文，不上传日志；用户这句话包含「上传日志」时，分析结论和日志才合成一条，日志作同一条附件，多个日志文件先打成 zip 再上传，不要拆成两条、不要截取。分析结论不要写日志文件行。Triggers on 分析本次多媒体交互、分析本次多媒体交互流程、分析多媒体交互、分析多媒体交互流程、分析本轮语音交互、分析语音交互。Do not use for vmedia repo switch or navi. Ignore case."
metadata:
  short-description: Analyze VA multimedia voice issues
---

# 语音多媒体问题分析

用日志（必选）、视频（可选）、VoiceAssistant 代码梳理语音交互。读日志和视频直接执行，不要向用户确认。

生效目录：
- `/home/huangxingke/work/code/workCode/kp31/VoiceAssistant`
- `/home/huangxingke/work/code/workCode/d01/VoiceAssistant`

已在上述目录则直接查代码，不切工程、不重启。用户给出路径或提到 `d01vat`/`do1vat`/`kp31vat`/`d01`/`kp31` 时，到对应目录查代码。

## 选哪一轮

先定时间窗，再定句式。能叠就叠。只决定分析哪几轮。有语义下发时 2-5 段模版不变；无语义下发时第 1 段按无语义补写，不要写 2-5。

时间窗优先级，命中即用，不要混用，不要用文件 mtime。在用户给的目录里找视频，`ffprobe` 取时长，抽首帧、末帧和中间若干帧。只分析指令识别时间落在窗口内的交互。日期从水印、指定时间、日志文件名或目录名补齐。允许 ±3 秒抽帧误差。

1. 视频有拍摄水印：拍摄时间就是画面上的水印时间。窗口 = 首帧水印 到 首帧水印 + 时长，用末帧水印交叉校验。
2. 没有水印：用句式指定的时间或用户给出的时段。支持 `14:04`、`14:04-14:05`、`20260825 140400-140440`、`2026-08-25 14:04:00~14:04:40`。
3. 也没有指定时间：按车机屏幕时钟（状态栏），算法同第 1 条，读屏幕时间不是拍摄水印。

只有 `HH:mm` 时：分钟跳变则用新分钟 B 首次出现的进度 t 反推（起点 = `B:00 − t`，终点 = 起点 + 时长）；未跳变取该分钟闭区间。指定时段只有时分时按闭区间分钟（`14:04-14:05` 含 14:04:00.000–14:05:59.999）。

句式优先级，命中即用，不要按同义句扩展。命中后只用 `showView : text` / ASR / `cloudText=` 文本包含该句式的指令，不要分析其他话术。有时间窗先套窗再过滤句式；无时间窗则在本次日志目录内找全部命中。

仅命中免唤醒时，再额外认 `handWakeupAction` 的 `cmdWord`、`requestSpeechWakeup voice cmdWord`。没有 `showView` / ASR 时，指令内容用 `cmdWord`。未命中免唤醒时不要用这两条改句式。

4. 用户指定了句式：用指定句式。
5. 没有指定句式：用视频画面上显示的指令句式（语音识别/助手界面上的那句），抽帧读取，不要猜。
6. 指定句式和视频画面句式都没有：有时间窗则输出窗口内全部轮次；只有单点时间或话术时才分析一轮。

输出：规则内命中一轮输出一轮，命中多轮按指令时间顺序全部输出，每轮一套 1-5 段、轮与轮空一行。只有一轮时不要加轮次标题。多轮时每轮第 1 段前单独加一行加粗 `第N轮`，N 从 1 按时间顺序递增，例如 `第1轮`、`第2轮`。不要用有序列表，段内 1-5 编号保持不变。不要自行只留一轮；用户说只看前几次时再截取。有句式但窗口内或日志目录内没有该指令 → 输出 `提示：未找到该指令的日志`，结束。

分析结论只出 1-5 段，多轮时再加 `第N轮`。不要输出 `日志文件` 行。内部记下命中的本地日志原文件。用户要写飞书备注时按 `meegle-remark`：默认只写正文，不上传日志；用户这句话包含「上传日志」时，分析结论和日志才合成一条（正文用本次 1-5 段，多轮含 `第N轮`，日志作同一条附件），多个日志文件先打成 zip 再上传，不要拆成两条、不要截取。无语义下发这一档备注照抄 `提示` / `提示语`，不要补写 `本地：`；有语义下发的 2-5 段备注原文照抄，不要删行。多轮备注保留 `第N轮`。

## 流程判断

按 1→5 顺序查。缺哪步就写 `提示：` 并停止，不要再写后面的段。

1. 用户指定了指令内容，但日志没有该指令 → 输出 `提示：未找到该指令的日志`，结束。
2. 指令和语义一对一。本地收到语义只认语音助手这几条入口日志，必须文本命中，不要用类名或方法名放宽：
   - `VALog_VRManager` 且含 `dispatchSemantic : request =`（`VRManager.dispatchSemantic` 打的 `dispatchSemantic : request =\n`）。下游 `dispatchSemantic : functionId`、`dispatchSemantic functionId`、`dispatchSemantic()` 不算。
   - `VALog_VoiceCommonService` 且含 ` handleVoiceJsonData : service =`（`VoiceCommonService.handleVoiceJsonData` 打的这一条）。`dataJson is null`、`InternationalVersion return`、音乐/电台/视频里的 `handleVoiceJsonData` 不算。
   - `VALog_IflytekMessageReceiver onReceive`、`VALog_VRManager handWakeupAction` 仍算本地收到，原有场景 C/D 不变。
   云端 NLU、`JETOUR_CloudApiManager`、`InstructionEngine`、`DriverTitleSettingAdapter`、其它进程的 FC/NLG/TTS，都不是本地收到语义。只有这些、没有上面的入口日志 → 写完第 1 段后输出 `提示：有指令但没有语义下发`。仅这一档：不要写 `本地：`；本次有播报再写 `提示语 ： <TTS>`。不要写 2/3/4/5，结束。没有播报则不要写 `提示语` 行。不要贴代码，不要写提示语 id，不要把云端或其它进程的执行补成第 2–5 段。有上述入口日志才算有语义下发，第 1 段只保留指令，后面按已有 2-5 段模版继续，其他场景不变。
3. 语义正常解析后：
   - 已有本地语义入口，并进入了本次 `functionId` / `service` 对应的业务分支，就继续分析，不要用兜底结束。当前状态已经是目标值、只读状态后直接 `TtsSkillManager.onVoiceResponse` / `onAlreadyResponse` / `onDoneResponse`，也算触发了业务。例如识别文字显示已打开：`NewVoiceSettingMgr.getTypewriterDisplay()` 后回 `open_pgs_2`，没有调用 `setTypewriterDisplay()`。这种写第 3 段和第 5 段，不写第 4 段。第 3 段方法写本次实际调用到的方法，不要写成没执行的设置方法。下游找不到 `ttsId` 资源、没有 `startSpeak` 时，第 5 段仍写；`播报提示语文案` 不编原文；日志有 `ttsId` 就空一行写 `VRResponseID.<ttsId>`；字节语义且是本地 TTS 再空一行写 `resultCode`。
   - 只有没进入该业务分支、只播了与本功能无关的兜底（`speakNotSupport` 等），没有走到该 function 的 case、也没有 `onVoiceResponse` 时，才写完第 2 段后写 `播报提示语文案 ： <TTS>`，再输出 `提示：播报兜底提示语，后续不再分析`，结束。不要写 3/4/5。有实际播出才写文案。
   - 第三方视频前置失败（`isIQIYIFront() == false` / `isCanExecCmd() == false`），无 TTS 无 API → 写完第 2 段后输出 `提示：未触发多媒体业务`，结束。
   - 爱奇艺 `videoIsPlaying() == false`，或 `UserGuideVideoManager` / `VRBytedanceManager` 走 `speakNotSupport` → 按兜底提示语结束。
   - 若触发了业务动作 → 继续第 3 段。
4. 已触发业务：
   - 最终提示语走国际版 `ReplyInfo` → 不写第 4/5 段原模版，只输出一行 `ReplyInfo`。不走 `ReplyInfo` 时下面原有逻辑不变。
   - 有返回状态码（`onSuccess` / `onFailure` / `onError` / `rspCode` / `onQysCallback` / 番薯 `onResponse` 且代码按返回播报）→ 写第 4 段。同一次业务若回调多次（同一 `sendMultimediaReq` / 同一 `VoiceCallback` 多次 `onSuccess`/`onFailure` 等），按回调时间顺序写多次第 4 段，不要只留首次、不要合并成一行。
   - 没有可用状态码：
     - 代码已直接播报/NLG（爱奇艺 `execCmd` 后 `SUCCESS_CLOUD_NLG`，番薯 `responseOk` 后 `onResponse` 只打日志，车控/应用直接 `TtsSkillManager.onVoiceResponse`）→ 不写第 4 段，写第 5 段，标题用 `播报提示语执行时间`。
     - 否则写完第 3 段后输出 `提示：未收到多媒体返回状态码`，结束。
5. 有返回状态码：
   - 有真正开播 → 写第 5 段，标题用 `根据状态码播报提示语时间`，文案和后面的 `VRResponseID` / `resultCode` / `VRResponsePacket` 按原有规则。多次回调时按时间顺序配对：每次回调若触发了播报就写一次第 5 段，某次无播报则该次不写第 5；不要只留首次播报。
   - 没有真正开播 → 写完已有的第 4 段结束。不要写第 5 段，不要写 `提示：有返回状态码但未执行播报`，也不要写别的没播报提示。`startSpeakTag` / `tipsTtsText` 之后如果 `isNeedTTS() = false`、`speakCommText` 直接 return，或没有 `startSpeak`，都算没有播报。

## 输出模版

只输出实际走到的段，不要扩写，不要补多媒体 App 侧收包日志。不要用表格。5 段标题里的时间都带年月日，格式 `yyyy-MM-dd HH:mm:ss.SSS`。不要输出 `日志文件` 行。有语义下发时 2-5 段模版不变。

飞书会把 markdown 有序列表 `1.` 后面的换行吞掉，并把后续编号重置成 `1.`。标题必须写成加粗正文，不要用有序列表。段与段空一行，标题和下一行之间也空一行。

多轮输出按下面这一套，不要只写轮次标题、也不要把两轮的 1-5 段连在一起。只有一轮时不要加 `第N轮`，仍从第 1 段开始。两轮及以上时：

- 每轮第 1 段前单独一行加粗 `第N轮`，N 从 1 按时间顺序递增
- `第N轮` 和该轮第 1 段标题之间空一行
- 该轮内部仍用原来的 1-5 段，编号每轮从 1 重新开始
- 轮与轮之间空一行
- 某一轮提前停在 `提示：` 时，提示行写在该轮最后，不要另起一轮

多轮示例（格式参考，值不要照抄）：

**第1轮**

**1. 指令识别时间 ：2026-11-26 10:03:00.196**

指令内容：继续播放

**2. 免唤醒通知收到时间 ：2026-11-26 10:03:00.196**

- 免唤醒 = true
- 免唤醒词 = 继续播放
- 唤醒方位 = 主驾左前

**3. 触发业务交互时间 : 2026-11-26 10:03:00.204**

VoiceMediaControllerManager.resumeMusic()

- TYPE_SEMANTIC_LEVEL_FIRST_CONTROL = 5
- TYPE_SEMANTIC_LEVEL_SECOND_CONTROL_PLAY_PAUSE = 1500
- TYPE_SEMANTIC_LEVEL_THIRD_RADIO_CONTROL_CONTINUE = 15002

**4. 收到多媒体返回执行状态码时间 ：2026-11-26 10:03:00.220**

- onSuccess ： SemanticRsp.RSP_SEMANTIC_CONTROL_OK = 6000

**5. 根据状态码播报提示语时间 ： 2026-11-26 10:03:00.222**

播报提示语文案 ： 好嘞

**第2轮**

**1. 指令识别时间 ：2026-11-26 10:03:03.184**

指令内容：暂停播放

**2. 免唤醒通知收到时间 ：2026-11-26 10:03:03.184**

- 免唤醒 = true
- 免唤醒词 = 暂停播放
- 唤醒方位 = 主驾左前

**3. 触发业务交互时间 : 2026-11-26 10:03:03.191**

VoiceMediaControllerManager.pauseMusic()

- TYPE_SEMANTIC_LEVEL_FIRST_CONTROL = 5
- TYPE_SEMANTIC_LEVEL_SECOND_CONTROL_PLAY_PAUSE = 1500
- TYPE_SEMANTIC_LEVEL_THIRD_RADIO_CONTROL_PAUSE = 15000

**4. 收到多媒体返回执行状态码时间 ：2026-11-26 10:03:03.198**

- onSuccess ： SemanticRsp.RSP_SEMANTIC_SUCCEED = 200

**1. 指令识别时间 ：yyyy-MM-dd HH:mm:ss.SSS**

指令内容：用户话术

仅没有语义下发时，第 1 段后面只跟下面几行，不要写 2/3/4/5，不要写 `本地：`。有播报才写 `提示语`，用实际播出原文，不要写 `VRResponseID`。有语义下发时其他场景不变：第 1 段只写指令时间和指令内容，后面仍按已有 2-5 段模版走，不要在第 1 段写 `本地` / `提示语`。示例只说明无语义这一档的格式，后边内容不要照抄。

**1. 指令识别时间 ：yyyy-MM-dd HH:mm:ss.SSS**

指令内容：打开显示设置页面

提示：有指令但没有语义下发

提示语 ： 只有中控屏存在显示设置界面

**2. 收到语义时间 ：yyyy-MM-dd HH:mm:ss.SSS**

每次交互先查日志，命中哪种就按哪种输出，不要混打。不管哪种场景，都只列本次有效值。

有效值：非空字符串、数字（含 `0`）、布尔（`true`/`false`）。不要列 `null`、`""`、`[]`、`{}`、缺字段。`operation` 例外：没有下发（日志为 `null`、空字符串、或缺字段）仍输出 `operation = null`，不要省略。`isMediaCenterService`、`clientType` 即使日志里有有效值也不要输出。`clientType` 仍只用来判断 `isByte`，不要写成第 2 段的一行。`extraData` / `requestId` 若是 JSON 字符串，展开后按同样规则列内层有效字段，不要整段 JSON 原样贴出。嵌套对象同样只列有效值。等号前后加空格。示例只说明格式，字段以本次为准。

是否字节端下发在端到端、非端到端都写，且只在 `SystemPropertyUtils.isLargeByteModel()` 为 true 时写。`isLargeByteModel()` 即 `SystemPropertiesUtils.isLargeModelVersion()`，为 `Build.isD01()` 或 `Build.isHuaweiBuildType()`。`isLargeByteModel` 不为 true 时不要写 `isByte`。场景 C、D 不写。

判断用非端到端 `VoiceCommonService.handleVoiceJsonData` 这一句，比较式不变：

`isByte = (clientType == VrClientTypeRegistry.CLIENT_BYTE_MODEL)`

非端到端的 `clientType` 是 `voiceCommonMsgBean.getClientType()`。端到端没有这颗 bean，`clientType` 用同一次语义的 bind 日志，比较式照上面写。`CLIENT_BYTE_MODEL` 值为 `1`。

- 非端到端（场景 B）：用 `handleVoiceJsonData` 日志里的 `isByte = `。`true` 写 `isByte = true`，`false` 写 `isByte = false`。
- 端到端（场景 A）：`dispatchSemantic : request =` 没有 `isByte`。用同一次 `VALog_VoiceAssistantServiceImpl: dispatchSemantic bind clientType, ... clientType = `，或 `VALog_VrClientTypeRegistry: bind ... clientType = byte(1)` / `iflytek(0)`。`clientType` 为 `1` 或 `byte(1)` → `isByte = true`；为 `0` 或 `iflytek(0)` → `isByte = false`。

场景 A：`VALog_VRManager dispatchSemantic : request =`。`isLargeByteModel` 为 true 时在有效字段后追加 `isByte`，示例里的这一行仅该范围要写。

**2. 收到语义时间 ：2026-09-18 20:16:23.341**

- destState = true
- alias = 网易云音乐
- name = 网易云音乐
- packageName = com.autolink.music/com.autolink.app.module.main.activity.MainActivity
- functionId = 5100
- moduleId = 4
- multi_intent = false
- sid = 3d92e76d-c958-430f-9c4f-49deed7b0443-82
- intentIndex = 1
- userPosition = 0
- isByte = true

场景 B：`VALog_VoiceCommonService handleVoiceJsonData`。`operation` 没有下发时仍写 `operation = null`。`isLargeByteModel` 为 true 时 `isByte` 必写，按日志 `isByte = `。示例里的 `isByte` 仅该范围要写。

**2. 收到语义时间 ：2025-09-09 18:13:22.423**

- service = musicX
- operation = CHANGE
- sid = 2a08672b-c8eb-49e9-b3ae-d40b4dfbcc43-1179
- isByte = true
- quality = PLUS

`operation` 未下发示例：

- service = news
- operation = null
- isByte = false

场景 C：`VALog_IflytekMessageReceiver onReceive =` / `IflytekMessageReceiver: onReceive:`。`json` 为空时改用 `onReceive: base64Decode =`。关键类 `IflytekMessageReceiver`。

`content` 是 JSON 字符串时不要整段贴、不要把信封字段和 content 全量展开。按本地 `AbsOperation.doOperation` / `MediaOperation.doActionForOperationCommand` 最终传给 `doAction(position, service, operation, slots)` 的语义输出：只写 `service`、`operation`、`slots` 里有数据的字段。`slots` 展开后按有效值规则列内层（如 `instype = close`），不要写 `slots = {...}`。不要列 `messageType` / `focus` / `position` / `requestCode` / `text` / `bislocalresult` / `readable` / `vad` 等未作为语义传给 `doAction` 的字段。`operation` 没有下发仍写 `operation = null`。

**2. 收到语义时间 ：2026-09-27 13:40:02.350**

- service = musicX
- operation = INSTRUCTION
- instype = close

仅适配免唤醒，原有 A/B/C 不变。场景 D：`VALog_VRManager handWakeupAction: cmdWord =` 或 `handWakeupAction : cmdWord =`。有这条就按有语义走 2-5 段，不要写成没有语义下发。第 2 段标题改用 `2. 免唤醒通知收到时间`，不要写 `收到语义时间`。正文第一行固定写 `免唤醒 = true`，用来标明这次是免唤醒，不要省略。不写 `isByte`。第 2 段必须同时写免唤醒词和唤醒方位，不要只写词。免唤醒词取 `cmdWord`。唤醒方位取同一次 `mvwDirection`：`handWakeupAction` 没打这个值时，用 `requestSpeechWakeup voice cmdWord = ... mvwDirection:`；KP31 后排返回主页也可能打 `handWakeupAction : mvwDirection =`。方位按数值写名称，不要只写数字：`1` 主驾左前，`2` 副驾右前，`3` 左后，`4` 右后。日志没有方位时仍写这一行，值为 `未知`，不要省略。`cmdWord` 为空直接返回，写完第 2 段后输出 `提示：cmdWord 为空，未执行`，结束。`cmdWord` 没有进下面任一分支，写完第 2 段后输出 `提示：未进入免唤醒分支`，结束。

没有 `showView` / ASR 时，第 1 段时间用 `requestSpeechWakeup voice cmdWord`，没有这条再用 `handWakeupAction`；指令内容写 `cmdWord`。

**2. 免唤醒通知收到时间 ：yyyy-MM-dd HH:mm:ss.SSS**

- 免唤醒 = true
- 免唤醒词 = 下一首
- 唤醒方位 = 右后

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

<执行类>.<本地方法名>()

- TYPE_SEMANTIC_LEVEL_FIRST_* = <日志数值>
- TYPE_SEMANTIC_LEVEL_SECOND_* = <日志数值>
- TYPE_SEMANTIC_LEVEL_THIRD_* = <日志数值>
- <参数名> = <参数值>

执行类不限 `*Controller`。以国际版 `adapter.controller` 这些场景执行为准：cmd / hvac / manual / media / phone / route / system / vehicle。按本次实际走到的最终执行类补到方法前（`InternalVideoManager.openUsbVideo()` / `HvacProcessImpl.enableHVAC_AUTO_AC_MODE()` / `MusicController.xxx()` 等），有就补，没有不补、不要编类名，仍只写 `<本地方法名>()`。不要写 `AbsController` / `BaseController` / `PersistController` / `doAction` / `*Slots`。

先按语义入口分流，方法名、code、参数全部按本次日志 + 代码动态取值，示例只说明格式，禁止沿用。

入口 A：`handleVoiceJsonData`（音乐/电台/USB 等）

- 第 3 段方法名不写死。按本次触发场景在本地代码里找最终执行方法，找到什么就显示什么，带 `()`
- 执行类不限 `*Controller`：最终执行类有则写成 `ClassName.method()`，没有则只写 `method()`，不要编
- 先用本次 `VALog_Media` 的 `XxxApi` / `XxxManager` 日志缩小范围，再回代码确认该方法就是本次实际走到的分支
- 不要写 `voiceMediaMode` / `sendMultimediaReq` / `MultimediaReqUtil` / `MediaProxyManager`：这些只是下发通道，不是本地方法名
- 不要停在 `handleVoiceJsonData` / `MusicManager` / `RadioManager` 这类分发入口，除非它本身就是最终执行方法
- 仅视频类，且当前目录在 `/home/huangxingke/work/code/workCode/d01` 下（本次语义由 `VoiceVideoManager.handleVoiceJsonData` 分发，`service = video`）第 3 段写两个方法，共用同一个第 3 段标题和时间，两段方法之间空一行。先写 `VoiceVideoManager` 本次语义分支实际调用的方法，再写最终业务侧执行方法。`VoiceVideoManager` 这一行写分支方法，例如 `searchArtistVideo()` / `searchVideoByName()` / `searchVideoByNameIndex()` / `openVideo()` / `playVideoBySource()`，带该方法本次有效参数；不要写 `handleVoiceJsonData`。最终业务侧方法仍按下面爱奇艺 / USB / 搜狐规则。当前目录不在该 d01 目录下时，视频也只写最终业务侧方法，不要加 `VoiceVideoManager`。音乐、电台、车控、应用、免唤醒不要加 `VoiceVideoManager` 这一行
- 日志 `semanticLevelFirst/Second/Third`、`message` 提供数值和传参
- `TYPE_*` 名按本次本地对象反查，不要写死音乐或视频：
  - `MediaSemantic` → `QGMaterialUI-release.aar` 的 `com.autolink.music.mediabean.SemanticType`
  - `GallerySemantic` → `QGMaterialUI-release.aar` 的 `com.autolink.app.gallery.mediabean.ttvoice.GallerySemanticType`（或同类 `GallerySemanticType`）
  - 上面没有再到本地 `RequestCode` / `SemanticType` / `GallerySemanticType`
- 一/二/三级 code 各一行，写 `TYPE_* = 数值`，不要写 `semanticLevelFirst/Second/Third`
- 先看 `message`：有传参才追加到三级 code 后面，没有传参不加
- 传参格式与 code 相同：`参数名 = 参数值`，不要中文备注；只列有效值

音乐示例（格式参考，值不要照抄）：

**3. 触发业务交互时间 : 2025-09-09 18:13:22.423**

handleChangeMusicQuality()

- TYPE_SEMANTIC_LEVEL_FIRST_MUSIC = 0
- TYPE_SEMANTIC_LEVEL_SECOND_PLAY = 1000
- TYPE_SEMANTIC_LEVEL_THIRD_PLAY_SOUND_QUALITY_MUSIC = 10024
- quality = PLUS

视频/USB 示例（格式参考，值不要照抄）：

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

handleSeekTo()

- TYPE_SEMANTIC_LEVEL_FIRST_CONTROL = <日志数值>
- TYPE_SEMANTIC_LEVEL_SECOND_CONTROL_PLAY_FAST = <日志数值>
- TYPE_SEMANTIC_LEVEL_THIRD_CONTROL_FAST_FORWARD_TO_TIME = <日志数值>
- minute = <日志值>
- second = <日志值>

第三方视频：`TrdControlManager` 只分发，第 3/4 段写实际落到的 Manager。无 `TYPE_*` 时写本地方法名 + 本次 API 名/枚举 + 有效参数。仅当前目录在 `/home/huangxingke/work/code/workCode/d01` 下的视频类，按上面的规则在最终方法前再加一行 `VoiceVideoManager` 语义分支方法；其他目录的视频只写最终业务侧方法。

爱奇艺 `VRIqiyiManager`：`execCmd` + `QYSExecType.* = 日志cmd` + map 有效参数。从 `ArcLinkSdk` 的 `QYSExecType` / `LinkParam` 反查。

视频类示例（仅当前目录在 `/home/huangxingke/work/code/workCode/d01` 下；格式参考，值不要照抄；先 `VoiceVideoManager` 分支方法，再最终业务方法）：

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

VoiceVideoManager.searchArtistVideo()

- artist = 周星驰
- videoName = 功夫

VRIqiyiManager.execCmd()

- QYSExecType.SEARCH = search
- displayId = 0
- param = 周星驰 功夫

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

speedByTime()

- QYSExecType.FAST_FORWARD = fast_forward
- param = <毫秒>

番薯 `VRFanshuManager`：`sendMediaControl` + `FMediaControl.MediaAction.*` + 毫秒参数。

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

speedByTime()

- MediaAction.SEEK_FORWARD = <枚举值>
- param = <毫秒>

入口 B：`VALog_VRManager dispatchSemantic`

按 `VRManager.doDispatchSemantic` 的 `moduleId` 落到实际 Manager，第 3 段写最终本地方法，不要写 `doDispatchSemantic` / `dispatchSemantic` / `voiceMediaMode`。按本次实现选下面一种，不要混打。

1. 页面回调（`SettingSemanticExecMgr.openPage` / `closePage` + `ISemanticExecResultListener`）：只写本地方法名；日志有 pageId 再追加一行。

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

openSETTING_ASSISTANT()

- openPage = SET

仅适配，原有 1–5 段规则不变：

- 仅当最终经 AIDL 落到 `com.autolink.voicesetting` 时，第 3 段在本端方法后再补对端一步
- 第一步：实际调用 AIDL 的类和方法，不限定 `com.autolink.voiceassistant`，其它模块以本次实现为准
- 第二步：`com.autolink.voicesetting` 最终执行方法；方法名不写死，不要固定 `changNewRole` / `SettingSemanticExecMgr`
- 当前是 `d01/VoiceAssistant` 就找 `d01/VoiceSetting`，当前是 `kp31/VoiceAssistant` 就找 `kp31/VoiceSetting`；绝对路径读，不要切目录
- D01 / KP31 流程一样，代码不一样，第二步以对应 VoiceSetting 实际实现为准，不要照抄另一边
- AIDL 以当前工程 `VoiceAssistantApiService/src/main/aidl/com/autolink/voiceassistantapiservice/setting/` 为准，按本次日志 + 实际方法取值
- 对端若最终是 `SettingUtils.setValueString`，只列 `key` / `value`，`value` 用日志原文
- 最终实现不在 `com.autolink.voicesetting`，不要查 VoiceSetting，不要补第二步，不要补 `key` / `value`

AIDL 两步示例（格式参考，值不要照抄）：

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

SettingSemanticExecMgr.changNewRole()

VoiceSettingManager.setNewSpeaker()

- key = com.iflytek.autofly.IFLY_TTS_SPEAKER
- value = {"name":"聆飞逸","speakerId":60006,"type":0}

`IVoiceSemanticChangeListener` 两步落地（第一步以本次实际调用 AIDL 的类/方法为准，第二步按对应 VoiceSetting 实际分支取；下面是 D01 常见路径，KP31 不要照抄）：

- `changNewRole`：常见 `SettingSemanticExecMgr.changNewRole()` → 非大模型 `VoiceSettingManager.setNewSpeaker()`，最终 `SettingUtils.setValueString` 只列 `key`/`value`；大模型 `VoiceSettingManager.setTtsTimbre()`
- `changNewGender`：常见 `SettingSemanticExecMgr.changNewGender()` → 非大模型 `VoiceSettingManager.setSpeaker()`；大模型 `setTtsTimbre()`
- `setVRWakeCode`：常见 `SettingSemanticExecMgr.setVRWakeCode()` → `VoiceSettingManager.setWakeWord()`
- `openPage`：常见 `SettingSemanticExecMgr.openPage()` → `SemanticResultNotifyManager.handlePageResult()`。`SET` 开 `VoiceSettingActivity`；`HELP` 开帮助页；`SKILL`/`VPA` 开 `MainActivity`。日志有 pageId 仍追加 `openPage = SET`
- `closePage`：常见 `SettingSemanticExecMgr.closePage()` → `handlePageResult(false)`。关闭语音设置应用 `closeSETTING_ASSISTANT` 走本端 `OpenPageManager.closePage()`，只写一步
- `setVoiceServiceStatus`：VS stub 空实现。`functionId=3701` 走本端 `NewVoiceSettingMgr.setVoiceService()`，只写一步

`IVoiceSettingOperator` 是 `com.autolink.voicesetting` 调回语音助手，不是第 3 段这两步。`3666`/`3667` 讯飞兜底无 AIDL。

2. 车控/空调信号（`HvacControlManager` 等 `setVehicleState` / `commonEnableAndDisable`）：写本地方法名 + 本次实际走到的分支有效值 + 实际下发的信号。只列日志和代码确认执行了的操作，不要中文备注。

信号值必须区分代码设置值和日志值，分别各写一行，不要合成一个、不要先把十六进制转成十进制再输出：

- 代码设置值：`信号名 = 代码字面量`。代码写 `0x10` 就输出 `0x10`
- 日志值：`信号名 日志字段 = 日志数值`。日志 `state:16` 就输出 `ICC_DriveModeSet state = 16`

分支参数（如 `on` / `position`）仍只列有效值一行。

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

enableHVAC_AUTO_AC_MODE()

- position = 前排
- ICC_AC_POWER_SWITCH = 1
- ICC_AC_POWER_SWITCH state = 1
- ICC_FRONT_AC_AUTO = 1
- ICC_FRONT_AC_AUTO state = 1

车控开关示例（格式参考，值不要照抄）：

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

setConquerorModeSwitch()

- on = true
- ICC_DriveModeSet = 0x10
- ICC_DriveModeSet state = 16

3. 应用开关（`VRAppManager` → `AppControlManager.dispatchHandle`）：写最终执行方法（`enableAPP_KEY` / `disableAPP_KEY` / `openOnLineMusic` 等），不要停在 `dispatchHandle`。若最终又进 `voiceMediaMode`，按入口 A 的 `TYPE_*` 规则输出。

座椅 / APA / 蓝牙等同理：写最终本地方法 + 本次实际执行的动作或信号。最终执行类有同样补到方法前，没有不补，不限 `*Controller`。

入口 C：`IflytekMessageReceiver`（国际版）

以 `com.autolink.lib.international.adapter.controller` 这些场景执行为准：cmd / hvac / manual / media / phone / route / system / vehicle。按 `AbsOperation.doOperation` → `doAction` 再落到的最终执行类和执行方法，不要写 `doAction` / `doOperation`。执行类不限 `*Controller`，含各场景 `Internal*Manager` / `*ProcessImpl` / `*Controller` 等真正干活的类；有就补到方法前，没有不补。最终又进 `voiceMediaMode` 时，方法名仍写最终执行类 + 最终本地方法，code/参数按入口 A 的 `TYPE_*` 规则。最终提示语走 `ReplyInfo` 时，第 4、第 5 只输出一行 `ReplyInfo`，不要展开。

国际版示例（格式参考，值不要照抄；没有执行类时不要写类名）：

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

InternalVideoManager.openUsbVideo()

- TYPE_SEMANTIC_LEVEL_FIRST_VIDEO = <日志数值>
- TYPE_SEMANTIC_LEVEL_SECOND_PLAY_VIDEO = <日志数值>
- TYPE_SEMANTIC_LEVEL_THIRD_PLAY_USB_VIDEO = <日志数值>

若本次最终提示语走国际版 `ReplyInfo`（最终执行类返回 → `actionForOperationReply` / `speakCallback` → `sendSpeakText`）：第 4、第 5 不要按原模版展开，只输出一行 `ReplyInfo`。以最终实际开播为准：`replyResId != NO_REPLY_TSS` 或 `replyResString` 非空。走 `InternalTTSHelper.speakText` / `TtsSkillManager.onVoiceResponse` 等则不算 `ReplyInfo`，第 4、第 5 原有逻辑不变。

ReplyInfo 示例（格式参考，值不要照抄）：

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

HvacProcessImpl.enableHVAC_AUTO_AC_MODE()

ReplyInfo

入口 D：`VALog_VRManager handWakeupAction`（免唤醒）

只在命中 `handWakeupAction` 时走本入口。未命中时按原有 A/B/C，不要套用下面的分支，也不要改第 2–5 段。命中后第 1 段和第 4、第 5 段仍按原有规则；只有本入口写明的音量、返回主页、接听、挂断按这里收尾。

按当前工程 `VRManager.handWakeupAction` 的 `cmdWord` 分支取第 3 段，不要把 `handWakeupAction` 写成方法名。D01 / KP31 词集不一样，以当前仓库 `WakeupWordConstant` 和这个 switch 为准，不要把另一边的词补进来。`MediaControlManager.previous()` / `next()` / `pause()` / `play()` 只是分发，第 3 段写日志里实际落到的 listener 方法。

`cmdWord` 与第一跳：

- `上一首` → `MediaControlManager.previous()`
- `下一首` → `MediaControlManager.next()`
- `暂停播放` → `MediaControlManager.pause()`
- `继续播放` → `MediaControlManager.play()`
- `增大音量` → `CarSoundManager.setSETTING_ADJUST_VOLUME_LITTLE()`，value 为 `3-0`
- `减小音量` → `CarSoundManager.setSETTING_ADJUST_VOLUME_LITTLE()`，value 为 `3-1`
- `返回主页` → 后排且吸顶屏条件成立走 `AppUtils.goRoofHome()`，否则 `VRManager.handleGoHome()`
- `接听` → `BtPhoneManager.answerCall()`
- `挂断` → `BtPhoneManager.rejectCall()`
- `打开导航`：仅 D01。`VRManager.handleOpenMapByWakeup()` 之后本机 `dispatchSemantic`
- `播放音乐`：仅 KP31。`MusicApi.voicePlayMusic()`

上一首 / 下一首 / 暂停播放 / 继续播放：`MediaControlManager` 会把无参 `previous` / `next` / `pause` / `play` 分给已注册的 listener（音乐 `VoiceMediaControllerManager`、爱奇艺、USB 视频、番薯、用户手册、抖音等）。第 3 段写本次日志真正执行的那个方法，例如 `VoiceMediaControllerManager.previewMusic()` / `nextMusic()` / `pauseMusic()` / `resumeMusic()`，或对应 Manager 的 `handlePlay()` / `handlePause()` / `handleNext()` / `handlePrev()`。方法名以日志和代码为准，不要写死，也不要写 `MediaControlManager`。落到 `sendMultimediaReq` / `voiceMediaMode` 时，code 和参数按入口 A 的 `TYPE_*` 规则，第 4、第 5 段也按原规则。所有 listener 都没通过前台/焦点判断、没有真正执行 → 写完第 2 段后输出 `提示：未触发多媒体业务`，结束。

增大音量 / 减小音量：第 3 段写 `CarSoundManager.setSETTING_ADJUST_VOLUME_LITTLE()`。D01 多一个空的 `VRRequestPacket`，KP31 直接传空 requestId，value 都是 `3-0`（媒体、大一点）或 `3-1`（媒体、小一点）。日志有 `setSETTING_ADJUST_VOLUME_LITTLE parsed source=` 时，追加解析后的 `source`、`adjustValue`。这条在方法里直接 `TtsSkillManager.onVoiceResponse`，不写第 4 段，第 5 段标题用 `播报提示语执行时间`。

返回主页：`mvwDirection` 为 `3` 或 `4`，且 `SystemPropertyUtils.isSupportCMSM()`、`CarDisplayManager.isRoofDispalyOn()` 都成立 → `AppUtils.goRoofHome()`。否则 `VRManager.handleGoHome()`，日志有 `handleGoHome`。没有状态码、也没有播报：写完第 3 段结束，不要写第 4、第 5 段，不要写 `提示：未收到多媒体返回状态码`。

接听 / 挂断：第 3 段写 `BtPhoneManager.answerCall()` 或 `BtPhoneManager.rejectCall()`，对上日志 `answerCall` / `rejectCall`。没有状态码、也没有播报时同样写完第 3 段结束，不要补第 4、第 5 段，不要写未收到状态码。

打开导航：第 2 段仍是免唤醒。紧跟着的 `dispatchSemantic : request =` 是 `handleOpenMapByWakeup` 本机拼的打开应用包，不是新的一轮，也不要改成场景 A 再写一遍第 2 段。不要停在 `handleOpenMapByWakeup` / `dispatchSemantic` / `VRAppManager.dispatchSemantic` / `AppControlManager.dispatchHandle`。第 3 段写 `dispatchHandle` 最终落到的打开方法；日志里的包有 `alias` / `name` / `packageName` / `userPosition` 再列。`userPosition` 由方向转换：`1→0`，`2→1`，`3→2`，`4→3`，其他 `0`。包名以这次 `dispatchSemantic` 日志为准。之后的状态码和播报按应用打开原规则。

播放音乐：第 3 段写 `MusicApi.voicePlayMusic()`。免唤醒传入 `type = 0`，日志有 `voicePlayMusic : type =` 再写这一行。`type = 0` 走 `TYPE_SEMANTIC_LEVEL_THIRD_PLAY`，不是 U 盘、也不是蓝牙。三级 code 和后面的状态码、播报按入口 A。

免唤醒多媒体示例（格式参考，值不要照抄；类名和方法以本次落到的 listener 为准）：

**3. 触发业务交互时间 : yyyy-MM-dd HH:mm:ss.SSS**

VoiceMediaControllerManager.nextMusic()

- TYPE_SEMANTIC_LEVEL_FIRST_CONTROL = <日志数值>
- TYPE_SEMANTIC_LEVEL_SECOND_CONTROL_PLAY_SWITCH = <日志数值>
- TYPE_SEMANTIC_LEVEL_THIRD_RADIO_CONTROL_NEXT = <日志数值>

**4. 收到多媒体返回执行状态码时间 ：yyyy-MM-dd HH:mm:ss.SSS**

- onFailure ： SemanticRsp.RSP_SEMANTIC_MUSIC_USER_NOT_LOGGED_IN_AND_MEMBERSHIP = 6016

按本次回调类型写第 4 段，不要混用：

- 音乐/USB：`onSuccess` / `onFailure` 以本次 `VoiceCallback.Stub` 实际回调为准；数值以日志 `rspCode` / `p0` 为准
- 页面回调：`ISemanticExecResultListener` 只输出 `onSuccess` 或 `onError`，不要补状态码名字，不要写 `SemanticRsp`
- 爱奇艺：以本次 `onQysCallback` `code` 为准；未注册回调则不写第 4 段
- 番薯：`onResponse` 若只打日志、TTS 已走 `responseOk`，不写第 4 段
- 用户手册 / 抖音：`speedByTime` 为 `speakNotSupport`，不写第 3/4 段
- 车控/空调/应用若无异步回调、业务里直接 `onVoiceResponse` / `onDoneResponse` / `onAlreadyResponse` → 不写第 4 段，写第 5 段，标题用 `播报提示语执行时间`。当前值已等于目标值、只调用了读状态方法后直接 `onVoiceResponse` 的，同样走这一条，不要回到兜底结束
- 应用打开若同时又走了 `voiceMediaMode` 回调，第 4 段写多媒体 `onSuccess` / `onFailure`
- 名字按本次路径反查，用 `javap -constants`：
  - 音乐/电台：`SemanticRsp`
  - 视频/USB：`GallerySemanticRsp`
  - 爱奇艺：按本次 `code` 分支；没名字只输出数值
  - 番薯：有可用返回再写 `onResponse` 内容；没名字只输出返回值
- 不要查 `ResponseCode`
- 查到：`类名.RSP_* = 数值`；查不到只输出数值
- 示例只说明格式，禁止沿用
- 异常多次返回：同一次业务（通常第 3 段只触发一次 `sendMultimediaReq` / `voiceMediaMode` / 等价下发）若日志出现多次 `onSuccess` / `onFailure` / `onError` / `onQysCallback` / 按返回播报的 `onResponse`，按时间顺序输出多次第 4 段；每段标题用该次回调时间，正文格式与单次相同。不要只写首次，不要把多次时间塞进同一标题，不要自行判断哪次有效。即使状态码相同也要各写一段。

页面回调示例（格式参考）：

**4. 收到多媒体返回执行状态码时间 ：yyyy-MM-dd HH:mm:ss.SSS**

- onSuccess

多次返回异常示例（格式参考，值不要照抄；段与段空一行）：

**4. 收到多媒体返回执行状态码时间 ：2026-11-09 12:59:11.578**

- onSuccess ： SemanticRsp.RSP_SEMANTIC_CONTROL_COLLECTED = 6007

**4. 收到多媒体返回执行状态码时间 ：2026-11-09 12:59:11.932**

- onSuccess ： SemanticRsp.RSP_SEMANTIC_CONTROL_COLLECTED = 6007

第 5 段标题按有没有第 4 段分流，不要混用：

- 有状态码、写了第 4 段：

**5. 根据状态码播报提示语时间 ： yyyy-MM-dd HH:mm:ss.SSS**

- 没有状态码、不写第 4 段：

**5. 播报提示语执行时间 ： yyyy-MM-dd HH:mm:ss.SSS**

- 多次第 4 段时：按回调时间顺序，每次有对应播报就写一次第 5 段；标题用该次真正开播时间；文案按该次实际播出内容。某次回调没有播报则跳过该次第 5 段。不要只留首次播报，不要把多次播报合并成一段。

有状态码示例（格式参考）：

**5. 根据状态码播报提示语时间 ： yyyy-MM-dd HH:mm:ss.SSS**

播报提示语文案 ： 实际播出的 TTS 原文

多次返回且多次播报示例（格式参考，值不要照抄；与多次第 4 段配对，段与段空一行）：

**5. 根据状态码播报提示语时间 ： 2026-11-09 12:59:11.578**

播报提示语文案 ： 已收藏

**5. 根据状态码播报提示语时间 ： 2026-11-09 12:59:11.932**

播报提示语文案 ： 已收藏

TTS 用真正开播的内容。技能回包 `tipsText=好嘞` 若被大模型 NLG 替换，报 NLG 句，不要报「好嘞」。没有真正开播就不写第 5 段，也不要补没播报的提示。有真正开播才写第 5 段和播报相关内容。已进入业务并调用了 `onVoiceResponse`，但下游找不到 `ttsId` 资源、没有 `startSpeak` 时，不要因此停在第 2 段；这种仍写第 5 段，`播报提示语文案` 这一行不写，不要编原文。

若本次走 `TtsSkillManager.onVoiceResponse` 且日志有 `ttsId`，在播报提示语文案后再空一行写 `VRResponseID.<ttsId>`。多媒体 `TrdTTSHelper` / `R.string` 不要编 `VRResponseID`。

仅限本次语义是字节大模型时追加 `resultCode`：`FeedbackHelper.isByteModelSemantic()` 为 true，即 `clientType == VrClientTypeRegistry.CLIENT_BYTE_MODEL`（日志 `isByte = true` / `clientType = 1`）。`本地id` / `本地文本` 仅限在线字节 TTS 播报场景（`SUCCESS_CLOUD_NLG = 0`，含大模型 NLG / `playTextStream` / `speakTextStream`）才写；本地 TTS（`ERROR_LOCAL_TEXT = 1` / `SUCCESS_LOCAL_TEXT = 2`）不要写 `本地id` / `本地文本`。

不满足字节大模型时仍走原来的第 5 段：只写播报提示语文案；若走 `TtsSkillManager.onVoiceResponse` 且日志有 `ttsId`，再空一行写 `VRResponseID.<ttsId>`。不要加 `本地id` / `本地文本` / `resultCode`。已有 `VRResponseID.<ttsId>` 时，`本地id` 用该 ttsId，不要再重复写 `VRResponseID` 行。

在线字节 TTS 播报场景：在播报提示语文案后按顺序追加 `本地id` → `本地文本` → `resultCode`。`本地id` 与 `本地文本` 必须换行单独显示，禁止写在同一行，中间空一行；`resultCode` 前再空一行，单独换行显示。

本地id ： <本次代码资源 id 名，多媒体 `R.string.xxx`，车控/应用 `VRResponseID.xxx`>

本地文本 ： <strings.xml 定义文案；有 `%s` 等占位则用本次填入后的文案>

resultCode = VoiceResponseResultCode.SUCCESS_CLOUD_NLG = 0

字节大模型 + 本地 TTS：只追加 `resultCode`，不要写 `本地id` / `本地文本`：

resultCode = VoiceResponseResultCode.<本次实际常量> = <1/2>

`resultCode` 按本次实际值写：`SUCCESS_CLOUD_NLG = 0`、`ERROR_LOCAL_TEXT = 1`、`SUCCESS_LOCAL_TEXT = 2`。

大模型版本（`SystemPropertyUtils.isLargeByteModel()` 为 true）时，第 5 段在原有内容之后额外输出本次提示语的 `VRResponsePacket`。日志优先用 `onVoiceResponse dispatch packet=VRResponsePacket{...}`，没有再用 `VALog_VoiceAssistantCallback callbackVRResponsePacket` 的 `packet=`，或 `VALog_TtsSkillManager onVoiceResponse`。没有这份回包就不要编。字段只列有效值，等号前后加空格。`requestId` 是 JSON 时按第 2 段规则展开内层，不要整段贴出。`extraData` 为空不写。`resultCode` 用包里的原值，字节侧与 `rawResultCode` 相同。下面只说明格式，字段以本次日志为准。

VRResponsePacket

- multi_intent = false
- sid = 1a6e4e5a-f812-437b-96a9-4365962a7669-85
- intentIndex = 1
- resultCode = 1
- ttsId = open_pgs_2

字节语义 + 在线字节 TTS 示例（格式参考，值不要照抄；注意 `本地id`/`本地文本` 仅此场景、换行空行、`resultCode` 前空一行）：

**5. 根据状态码播报提示语时间 ： yyyy-MM-dd HH:mm:ss.SSS**

播报提示语文案 ： 好的，已经为你在中控屏上播放纪录片啦~

本地id ： R.string.search_video_channel

本地文本 ： 已打开纪录片栏目，请选择播放哦

resultCode = VoiceResponseResultCode.SUCCESS_CLOUD_NLG = 0

车控/应用示例（无状态码，格式参考，值不要照抄）：

**5. 播报提示语执行时间 ： yyyy-MM-dd HH:mm:ss.SSS**

播报提示语文案 ： 好的，网易云音乐已经为你打开咯~

VRResponseID.open_app_2

## 怎么找

先按「选哪一轮」定时间窗和句式，再查日志。时间：拍摄水印 > 句式指定时间 > 车机屏幕时钟。句式：指定句式 > 视频画面显示句式。规则内命中一轮输出一轮，命中多轮全部输出，多轮按输出模版加 `第N轮`。查到指令/语义后内部记下所在日志文件（`android_log/aplog`、`aplog.001`、`logcat_*` 等），不要写进分析结论。写备注时按 `meegle-remark`：默认只写正文，不上传日志；用户这句话包含「上传日志」时才上传该文件的本地整份原件，多个日志文件先打成 zip 再上传，不要拆成两条、不要截取。仅无语义下发这一档：分析结论和备注都不要写 `本地：`；有播报再写 `提示语`，TTS 可用 `CCA-TtsHelper` `startSpeak`。有语义下发其他场景不变：不要在第 1 段写 `本地` / `提示语`，2-5 段模版和备注都不改。单点时间仍可用 `202609181427` / `14:26:56`。第 1 到第 5 段时间都写 `yyyy-MM-dd HH:mm:ss.SSS`，以日志为准。日志行只有月日时，年份从日志文件名（如 `logcat_20260918_*`）或目录名补齐。

日志关键字：
- 指令：`showView : text`、`Process ASR`、`cloudText=`、`filtered`
- 语义：只认本地入口 `dispatchSemantic : request =`、` handleVoiceJsonData : service =`、`VALog_IflytekMessageReceiver onReceive`、`VALog_VRManager handWakeupAction`。`dispatchSemantic : functionId`、其它模块的 `handleVoiceJsonData`、云端 NLU、`JETOUR_*` 不算收到语义
- 免唤醒补充，未命中不要用：`handWakeupAction: cmdWord` 与 `handWakeupAction : cmdWord` 都算场景 D。`requestSpeechWakeup voice cmdWord` 只补方向和指令时间。打开导航本机拼出的 `dispatchSemantic : request =` 不算新一轮
- 多媒体：`VALog_Media`、`voiceMediaMode`、`execCmd`、`sendMediaControl`、`speedByTime`。第 3 段方法名每次按本次场景在本地代码里找，不写死；最终执行类有就补到方法前，没有不补，不限 `*Controller`。`VALog_Media` 的 `XxxApi` / `XxxManager` 日志只作线索，`voiceMediaMode` 只用来确认已下发，不要写成方法名
- 车控/应用：`openPage`、`enableAPP_KEY`、`dispatchHandle`、`setVehicleState`、`commonEnableAndDisable`、`openOnLineMusic`
- 返回：`onSuccess`、`onFailure`、`onError`、`rspCode`、`onQysCallback`、`onResponse`。查全本次业务窗口内全部回调，不要只取第一条；多次回调按第 4/5 段多次返回规则输出
- TTS：`ttsContent=`、`playTextStream`、`BidirectionalTtsClient`、`流式首帧`、`CommonTTSHelper`、`startSpeakTag`、`VALog_TtsSkillManager onVoiceResponse`、`ttsId`、`CCA-TtsHelper`、`startSpeak`、`actionForOperationReply`、`ReplyInfo`、`PLAY TTS start`

代码 / SDK：
- `VRManager.doDispatchSemantic`
- `VRManager.handWakeupAction`：按 `cmdWord` 落到 `MediaControlManager` / `CarSoundManager.setSETTING_ADJUST_VOLUME_LITTLE` / `handleGoHome` / `AppUtils.goRoofHome` / `BtPhoneManager.answerCall` / `rejectCall`；D01 另有 `handleOpenMapByWakeup`，KP31 另有 `MusicApi.voicePlayMusic`。`MediaControlManager` 只分发，第 3 段写实际 listener
- `VoiceCommonService.handleVoiceJsonData`
- `IflytekMessageReceiver.onReceive`
- 场景 C 第 2 段按 `AbsOperation.doOperation` / `MediaOperation.doActionForOperationCommand`：`service = ContentDTO.getService()`、`operation = ContentDTO.getOperation()`、`slots = ContentDTO.getContentSemantic().getSlots()`，只输出这三项里的有效值
- 本地方法不写死，按本次场景找最终执行类和执行方法再显示；国际版以 `adapter.controller` 各场景执行为准，不限 `*Controller`，有执行类就写成 `ClassName.method()`，没有不补
- 仅无语义下发时不要反查、不要输出 `本地：`。有语义下发时第 3 段方法名规则不变
- `TrdControlManager` / `MultimediaReqUtil` / `voiceMediaMode` / `AbsController` / `doAction` 只分发，不要当成第 3 段方法名
- `QGMaterialUI-release.aar`：音乐 `SemanticType` / `SemanticRsp`；视频/USB `GallerySemanticType` / `GallerySemanticRsp`
- 爱奇艺：`ArcLinkSdk` 的 `QYSExecType` / `LinkParam`
- 番薯：`FMediaControl.MediaAction`
- 提示语 id：`adapter_iflytek` 的 `VRResponseID`

常用映射：
- `playBackSource`：`1` QQ，`2` `TYPE_CLOUD_MUSIC` 网易云，`4` 云听
- `wake_up_direction`：`1` 主驾

用户要展开视频、多媒体 App 侧收包日志或对话过程时再补，默认不写。
