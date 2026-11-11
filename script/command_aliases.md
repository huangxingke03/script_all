# Command Aliases

## Voice Assistant D01
- Standard: `voiceAssistantD01`
- Variant: `voiceassistantD01`
- Variant: `voiceAssistantDO1`
- Variant: `voiceassistantDO1`
- Variant: `voiceAssistantd01`
- Variant: `voiceassistantd01`
- Variant: `voiceAssistantdo1`
- Variant: `voiceassistantdo1`

## Voice Assistant KP31
- Standard: `voiceAssistantKp31`
- Variant: `voiceassistantKp31`
- Variant: `voiceAssistantkp31`
- Variant: `voiceassistantkp31`

## Voice Assistant T12A
- Standard: `voiceAssistantT12a`
- Variant: `voiceassistantT12a`
- Variant: `voiceAssistantt12a`
- Variant: `voiceassistantt12a`

## Voice Setting D01
- Standard: `voiceSettingD01`
- Variant: `voicesettingD01`
- Variant: `voiceSettingDO1`
- Variant: `voicesettingDO1`
- Variant: `voiceSettingd01`
- Variant: `voicesettingd01`
- Variant: `voiceSettingdo1`
- Variant: `voicesettingdo1`

## Voice Setting KP31
- Standard: `voiceSettingKp31`
- Variant: `voicesettingKp31`
- Variant: `voiceSettingkp31`
- Variant: `voicesettingkp31`

## Voice Assistant API KP31
- Standard: `makeVoiceAssistantApiKp31`
- Variant: `makevoiceAssistantApiKp31`
- Variant: `makeVoiceAssistantApikp31`
- Variant: `makevoiceAssistantApikp31`
- Variant: `makevoiceassistantapikp31`
- Variant: `make_voice_assistant_api_kp31`
- Variant: `make_voice_assistant_api_kp31.sh`

## Voice Assistant API D01
- Standard: `makeVoiceAssistantApiD01`
- Variant: `makevoiceAssistantApiD01`
- Variant: `makeVoiceAssistantApiDO1`
- Variant: `makevoiceAssistantApiDO1`
- Variant: `makeVoiceAssistantApid01`
- Variant: `makevoiceAssistantApid01`
- Variant: `makevoiceassistantapid01`
- Variant: `makeVoiceAssistantApido1`
- Variant: `makevoiceAssistantApido1`
- Variant: `makevoiceassistantapido1`
- Variant: `make_voice_assistant_api_d01`
- Variant: `make_voice_assistant_api_d01.sh`

## Xunfei KP31
- Standard: `startIflytekPage`
- Variant: `startiflytekPage`
- Variant: `startIflytekpage`
- Variant: `startiflytekpage`
- Variant: `start_iflytek_page`
- 中文说明：用于启动讯飞设置页，支持 `-s` 指定台架设备序列号。

## Start QNX D01
- Standard: `startQnxD01`
- Variant: `startqnxD01`
- Variant: `startQnxDO1`
- Variant: `startqnxDO1`
- Variant: `startQnxd01`
- Variant: `startqnxd01`
- Variant: `startQnxdo1`
- Variant: `startqnxdo1`
- Variant: `start_qnx_d01`

## Boot Guide KP31
- Standard: `startBootGuideKP31`
- Variant: `startBootGuideKp31`
- Variant: `startbootGuideKP31`
- Variant: `startbootguidekp31`
- Variant: `start_boot_guide_kp31`
- 中文说明：拉起 KP31 开机引导。依次执行 `adb root`、等待设备恢复、把 `first_begin_boot` 和 `user_setup_complete` 置 0、启用引导三个 Activity，再启动 `DefaultActivity`。支持 `-s` 指定设备。
- Tab Completion: 输入 `startb` / `startboot` / `STARTBOOTGUIDEKP31` / `start_boot` 会补成正式命令 `startBootGuideKP31`。命令后的 Tab 提示 `-s`、`-h`，`-s` 后再 Tab 列出当前在线设备。

## Set Sales Area
- Standard: `setSalesArea`
- Variant: `setsalesarea`
- Variant: `SetSalesArea`
- Variant: `SETSALESAREA`
- Variant: `set_sales_area`
- 中文说明：`adb root` 后设置 `persist.vendor.oem.cfg.vci.b.sales.area.icc`。信号值由参数传入，例如 `setSalesArea 7`。多台设备在线时用 `-s` 指定。
- Tab Completion: 输入 `setsa` / `setsales` / `SETSALESAREA` / `set_sales` 会补成正式命令 `setSalesArea`。命令后的 Tab 提示 `-s`、`-h`，`-s` 后再 Tab 只列出当前在线设备。

## Reset Voice Assistant
- Standard: `resetVat`
- Variant: `resetvat`
- Variant: `ResetVat`
- Variant: `RESETVAT`
- Variant: `reset_vat`
- 中文说明：杀掉 `com.autolink.voiceassistant` 进程，让持久应用自己重启。支持 `-s` 指定设备，默认 `f6e277ff`。
- Tab Completion: 输入 `resetva` / `RESETVAT` / `reset_vat` 会补成正式命令 `resetVat`。命令后的 Tab 提示 `-s`、`-h`，`-s` 后再 Tab 列出当前在线设备。

## Reset Voice Setting
- Standard: `resetVst`
- Variant: `resetvst`
- Variant: `ResetVst`
- Variant: `RESETVST`
- Variant: `reset_vst`
- 中文说明：杀掉 `com.autolink.voicesetting` 进程后，主动打开首页 `com.autolink.voicesetting.ui.MainActivity`。支持 `-s` 指定设备，默认 `f6e277ff`。
- Tab Completion: 输入 `resetvs` / `RESETVST` / `reset_vst` 会补成正式命令 `resetVst`。`reset` / `resetv` 先补到 `resetV`，再列出 `resetVat` 和 `resetVst`。命令后的 Tab 提示 `-s`、`-h`，`-s` 后再 Tab 列出当前在线设备。

## Kill SystemUI
- Standard: `killSystemui`
- Variant: `killsystemUi`
- Variant: `killsystemui`
- Shortcut: `ksui`
- Shortcut Variant: `Ksui`
- Shortcut Variant: `KSui`
- Shortcut Variant: `KSUI`
- Shortcut Variant: `KsUi`
- Shortcut Variant: `KsUI`
- Shortcut Variant: `KsuI`
- Shortcut Variant: `KSuI`
- Shortcut Variant: `kSui`
- Shortcut Variant: `kSUi`
- Shortcut Variant: `kSUI`
- Shortcut Variant: `ksUi`
- Shortcut Variant: `ksUI`
- Shortcut Variant: `ksuI`
- Shortcut Variant: `kSuI`
- 中文说明：用于结束 SystemUI 进程，通常需要设备支持 root/su。

## Reboot Device
- Standard: `rebootDevice`
- Variant: `rebootdevice`
- Variant: `reboot_device`

## Random Log
- Standard: `startRandomLog`
- Variant: `startrandomLog`
- Variant: `startRandomlog`
- Variant: `startrandomlog`
- Standard: `stopRandomLog`
- Variant: `stoprandomLog`
- Variant: `stopRandomlog`
- Variant: `stoprandomlog`
- 中文说明：用于启动或停止随机日志采集，`stopRandomLog` 会复用同一套采集逻辑。

## Jira Commands
- Standard: `downloadJira`
- Variant: `downloadjira`
- Variant: `download_jira`
- Standard: `downloadJiraFiltered`
- Variant: `downloadjirafiltered`
- Variant: `download_jira_filtered`
- Request Template: `download_jira/download_jira_request.curl`
- Cookie Source: extracted directly from the JIRA cURL file at runtime; `download_jira_cookie.sh` has been removed

## Feishu Download Commands
- Standard: `downloadFeishu`
- Variant: `downloadfeishu`
- Variant: `download_feishu`
- Variant: `download_bug_feishu`
- Shortcut: `downloadb`
- Standard: `downloadFeishuFliter`
- Variant: `downloadfeishufliter`
- Variant: `download_feishu_fliter`
- Shortcut: `dfres` (same as `downloadfeishufliter`)
- Tab Completion: typing `down` / `download` only lists canonical names `downloadb`, `downloadFeishu`, `downloadFeishuFliter`, `downloadJira`, `downloadJiraFiltered`
- Config: `download_feishu/download_feishu_config.sh`
- Request Template: `download_feishu/download_feishu_request_kp31.curl`
- Request Routing: `downloadFeishu` / `downloadFeishuFliter` will prefer `download_feishu_request_<issue_id>.curl` first, then the default `download_feishu_request_kp31.curl`, then built-in project aliases such as `download_feishu_request_d01.curl` and `download_feishu_request_d01_int.curl`, then any other matching Feishu cURL exports in the script directory or source script directory
- Attachment Rule: download every attachment URL returned by Feishu; JIRA-history attachments can use `FEISHU_ATTACHMENT_JIRA_COOKIE`
- Filter Rule: `downloadFeishuFliter` keeps all `downloadFeishu` logic but skips `can_*.asc`, `mcu_*.zip`, and `qnx_*.zip` attachments before download and extraction. Multiple IDs are supported: `downloadFeishuFliter id1 id2 ...` runs the original single-ID download sequentially per ID. Extra save rule for filter mode only: for `*.hprof`, keep the first file's original name; if the same name already exists locally, accumulate a numeric suffix (`name1.hprof`, `name2.hprof`, ...) and never overwrite
- Save Dir Rule: keep the original naming order; normalize project text like `CHERY_KP31_Bug` to `KP31`, then prefer detected project prefix such as `KP31_7043211990` or `D01_7043211990`, otherwise fall back to the plain issue ID directory like `7043211990`

## Unified Update
- Standard: `updateSciptAll`
- Variant: `updatesciptAll`
- Variant: `updateSciptall`
- Variant: `updatesciptall`
- Variant: `update_scipt_all`
- Variant: `updateAll`
- Variant: `update_all`
- Variant: `updateDownloadJira`
- Variant: `updatedownloadJira`
- Variant: `updateDownloadjira`
- Variant: `updatedownloadjira`
- Variant: `update_download_jira`
- Variant: `updateDownloadFeishu`
- Variant: `updatedownloadFeishu`
- Variant: `updateDownloadfeishu`
- Variant: `updatedownloadfeishu`
- Variant: `update_download_feishu`

## Iflytek System Update Commands
- Standard: `updateD01IntSys`
- Variant: `updated01IntSys`
- Variant: `updateDO1IntSys`
- Variant: `updatedo1IntSys`
- Variant: `updateD01intSys`
- Variant: `updateDO1intSys`
- Variant: `updatedo1intSys`
- Standard: `updateD01Sys`
- Variant: `updated01Sys`
- Variant: `updateDO1Sys`
- Variant: `updatedo1Sys`
- Variant: `updateD01sys`
- Variant: `updateDO1sys`
- Variant: `updatedo1sys`
- Standard: `replaceLocal`
- Rule: `replaceLocal` is a thin entry only. Logic is maintained separately in `/home/huangxingke/work/file/讯飞切换版本/build_replace/sh/replace_local.sh` (`adb root` / `remount` / clear dalvik+package cache / push `build.prop` / `sync` / `adb reboot`). Wrapper: `update_iflytek/replace_local.sh` only forwards (supports `-s <serial>`). Does not pull iFlytek git or clear apps.
- Standard: `replaceLocalD01p`
- Variant: `replaceLocalDO1p` (`do1` equals `d01`)
- Rule: `replaceLocalD01p` is a thin entry only. Logic is maintained separately in `/home/huangxingke/work/file/讯飞切换版本/build_replace/sh/replace_local_d01p.sh` (`adb root` / `remount` / clear dalvik+package cache / push `build_d01p.prop` / `sync` / `adb reboot`). Wrapper: `update_iflytek/replace_local_d01p.sh` only forwards (supports `-s <serial>`).
- Standard: `replaceOut`
- Rule: `replaceOut` is a thin entry only. Logic is maintained separately in `/home/huangxingke/work/file/讯飞切换版本/build_replace/sh/replace_out.sh` (`adb root` / `remount` / clear dalvik+package cache / push `build_out.prop` / `sync` / `adb reboot`). Wrapper: `update_iflytek/replace_out.sh` only forwards (supports `-s <serial>`).
- Standard: `replaceOutD01p`
- Variant: `replaceOutDO1p` (`do1` equals `d01`)
- Rule: `replaceOutD01p` is a thin entry only. Logic is maintained separately in `/home/huangxingke/work/file/讯飞切换版本/build_replace/sh/replace_out_d01p.sh` (`adb root` / `remount` / clear dalvik+package cache / push `build_out_d01p.prop` / `sync` / `adb reboot`). Wrapper: `update_iflytek/replace_out_d01p.sh` only forwards (supports `-s <serial>`).
- Tab Completion: PATH 保留正式名 + 全小写（及 do1）别名：`replaceLocal`/`replacelocal`、`replaceOut`/`replaceout`、`replaceLocalD01p`/`replacelocald01p`/`replaceLocalDO1p`、`replaceOutD01p`/`replaceoutd01p`/`replaceOutDO1p`。输入 `replaceout` 可直接 Tab/执行。已去掉 `replace_out.sh` 等杂别名。命令后 `-s` 再 Tab 只列在线设备；误写如 `replaceOutD01P` 也会绑设备补全，不再列出当前目录文件。
- Standard: `updateD01pIntSys`
- Variant: `updated01pIntSys`
- Variant: `updateDO1pIntSys`
- Variant: `updatedo1pIntSys`
- Variant: `updateD01pintSys`
- Variant: `updateDO1pintSys`
- Variant: `updatedo1pintSys`
- Standard: `updateKp31IntSys`
- Variant: `updatekp31IntSys`
- Variant: `updateKp31intSys`
- Variant: `updatekp31intSys`
- Standard: `updateKp31Sys`
- Variant: `updatekp31Sys`
- Variant: `updateKp31sys`
- Variant: `updatekp31sys`

## Iflytek Resource Update Commands
- Standard: `updateIflytekResD01`
- Variant: `updateiflytekResD01`
- Variant: `updateIflytekResd01`
- Variant: `updateiflytekresd01`
- Variant: `updateIflytekResDO1`
- Variant: `updateiflytekResDO1`
- Variant: `updateIflytekResdo1`
- Variant: `updateiflytekresdo1`
- Variant: `update_iflytek_res_d01`
- Variant: `update_iflytek_res_d01.sh`
- 中文说明：只更新 D01 国内讯飞资源和 APK，不推送 `build.prop`。对齐 `origin/al_chery-d01_dev2`，推送 `D01/iflytek/res` 和 `D01/system/app`。支持 `-s` 指定设备。
- Standard: `updateIflytekResD01Int`
- Variant: `updateiflytekResD01Int`
- Variant: `updateIflytekResd01Int`
- Variant: `updateiflytekresd01Int`
- Variant: `updateIflytekResDO1Int`
- Variant: `updateiflytekResDO1Int`
- Variant: `updateIflytekResdo1Int`
- Variant: `updateiflytekresdo1Int`
- Variant: `updateIflytekResD01int`
- Variant: `updateiflytekResD01int`
- Variant: `updateIflytekResd01int`
- Variant: `updateiflytekresd01int`
- Variant: `updateIflytekResDO1int`
- Variant: `updateiflytekResDO1int`
- Variant: `updateIflytekResdo1int`
- Variant: `updateiflytekresdo1int`
- Variant: `update_iflytek_res_d01_int`
- Variant: `update_iflytek_res_d01_int.sh`
- 中文说明：只更新 D01 国际讯飞资源和 APK，不推送 `build.prop`。对齐 `origin/al_chery-d01_dev2`，推送 `D01_INT/iflytek/res` 和 `D01_INT/system/app`。`do1` 等同 `d01`，`Int`/`int` 都可用。支持 `-s` 指定设备。
- Standard: `updateIflytekResKp31`
- Variant: `updateiflytekResKp31`
- Variant: `updateIflytekReskp31`
- Variant: `updateiflytekreskp31`
- Variant: `update_iflytek_res_kp31`
- Variant: `update_iflytek_res_kp31.sh`
- 中文说明：更新 KP31 国内讯飞资源和 APK。对齐 `origin/al_chery-kp31_dev2`，推送 `KP31/iflytek/res` 和 `KP31/system/app`。支持 `-s` 指定设备。
- Tab Completion: 上述命令后 Tab 提示 `-s`、`-h`；`-s` 后再 Tab 列出当前在线设备。别名区分大小写安装，Tab 补全忽略大小写。

## Rename USB Dir
- Standard: `renameUsbDir`
- Variant: `renameusbDir`
- Variant: `renameUsbdir`
- Variant: `renameusbdir`
- Variant: `rename_usb_dir`

## Pull Logcat By Adb
- Standard: `pullLogcatByAdb`
- Variant: `pulllogcatByAdb`
- Variant: `pullLogcatbyAdb`
- Variant: `pulllogcatbyAdb`
- Variant: `pull_logcat_by_adb`

## Clear Logcat By Adb
- Standard: `clearLogcatByAdb`
- Variant: `clearlogcatByAdb`
- Variant: `clearLogcatbyAdb`
- Variant: `clearlogcatbyAdb`
- Variant: `clear_logcat_by_adb`

## Voice Bt Click
- Standard: `voiceBtClick`
- Variant: `voicebtClick`
- Variant: `voiceBtclick`
- Variant: `voicebtclick`
- Variant: `voice_bt_click`
- Compatibility Alias: `soundBtClick`
- Compatibility Alias: `soundbtClick`
- Compatibility Alias: `soundBtclick`
- Compatibility Alias: `soundbtclick`
- 中文说明：这是“语音按键”服务的快捷指令，旧的 `soundBtClick` 族命令仍保留为兼容别名。
- 中文说明：输入命令名后可直接按 Tab 补全，`-s` 后也会继续提示可用设备。

## Virt Manager
- Standard: `virtManager`
- Variant: `virtmanager`
- Variant: `startVirtManager`
- Variant: `startvirtManager`
- Variant: `startVirtmanager`
- Variant: `startvirtmanager`
- Variant: `start_virt_manager`

## Start win10-pct VM
- Standard: `startWin10`
- Variant: `STARTWIN10`
- Variant: `StartWin10`
- Variant: `startwin10`
- Variant: `Startwin10`
- Variant: `startWIN10`
- Variant: `start_win10`
- Variant: `start-win10`
- Compatibility: `startWin10Pct` / `startwin10pct` / `start_win10_pct` / `win10pct`
- 中文说明：通用脚本，启动 libvirt 虚拟机 `win10-pct`（可用 `WIN10_PCT_VM` 覆盖名称）。默认打开**窗口化** `virt-viewer`（`setsid` 脱钩），可最小化/关闭控制台，虚拟机继续后台跑；鼠标被抓取时用 `Ctrl+Alt` 释放。`-b`/`--background`/`-n`/`--no-viewer` 纯后台开机；`-v`/`--viewer-only` 已开机时只开控制台。关机请用 `closeWin10`。桌面快捷方式名：`startWin10`。
- Tab Completion: 输入 `start` / `START` / `startwin` / `STARTWIN` / `startWin` 可补到正式命令 `startWin10`（忽略大小写）。命令后的 Tab 提示 `-b`/`--background`、`-n`/`--no-viewer`、`-v`/`--viewer-only`、`-h`/`--help`。
- Source: `common_script/start_win10.sh`，桌面文件 `common_script/start_win10.desktop`，补全 `common_script/startWin10_completion.sh`。

## Close win10-pct VM
- Standard: `closeWin10`
- Variant: `CLOSEWIN10`
- Variant: `CloseWin10`
- Variant: `closewin10`
- Variant: `Closewin10`
- Variant: `closeWIN10`
- Variant: `close_win10`
- Variant: `close-win10`
- Compatibility: `stopWin10` / `stopwin10` / `stop_win10`
- 中文说明：通用脚本，关闭 libvirt 虚拟机 `win10-pct`（可用 `WIN10_PCT_VM` 覆盖）。默认 ACPI 优雅关机，超时（默认 60s，可用 `WIN10_SHUTDOWN_WAIT`）后 `destroy` 强制断电，确保 qemu 退出、不再占内存；同时关掉该机的 `virt-viewer`。`-f`/`--force` 直接强制断电。桌面快捷方式名：`closeWin10`。
- Tab Completion: 输入 `close` / `CLOSE` / `closewin` / `CLOSEWIN` / `closeWin` 可补到正式命令 `closeWin10`（忽略大小写）。命令后的 Tab 提示 `-f`/`--force`、`-h`/`--help`。
- Source: `common_script/close_win10.sh`，桌面文件 `common_script/close_win10.desktop`，补全 `common_script/closeWin10_completion.sh`。

## Sync FileToUbuntu
- Standard: `syncftu`
- Variant: `SYNCFTU`
- Variant: `Syncftu`
- Variant: `SyncFtu`
- Variant: `syncFtu`
- Variant: `syncFileToUbuntu`
- Variant: `syncfiletoubuntu`
- Variant: `SyncFileToUbuntu`
- Variant: `SYNCFILETOUBUNTU`
- Variant: `sync-filetoubuntu`
- Compatibility: `sync-filetoubuntu-from-vm.sh`
- 中文说明：把 Windows 虚拟机 `win10-pct` 上的共享目录 `FileToUbuntu` 同步到 Ubuntu 侧栏目录 `~/FileToUbuntu`。与 `pcatusb`（9008 透传）无关。默认只同步、不删本地已有文件。公司网卡 `cnem_vnic` 常抢 `192.168.122.0/24` 路由（表现 `NT_STATUS_HOST_UNREACHABLE`）；`fix_virbr_route.sh` 用独立 table/ip rule 强制走 `virbr0`，并由系统服务 `fix-virbr-route.service` 每 15s 重刷。`syncftu` 若发现默认路由不经 `virbr0` 会自动 `--fix-route`（可能弹 pkexec）。定时静默同步用 `syncftu --quiet`。可选 `-s` 指定台架设备序列号（仅校验设备在线）。
- Tab Completion: 输入 `sync` / `SYNC` / `syncftu` / `SYNCFTU` / `syncFile` 可补到正式命令 `syncftu`（忽略大小写）。命令后的 Tab 提示 `-s`、`-q`/`--quiet`、`-f`/`--fix-route`、`-h`/`--help`；`-s` 后再 Tab 只列出当前在线设备。
- Source: `common_script/sync_filetoubuntu.sh`，依赖同目录 `fix_virbr_route.sh`；补全逻辑在 `common_script/syncftu_completion.sh`。

## Notes
- JIRA implementation files live in `download_jira/`; published commands are installed into `~/.local/bin` by `update_scipt_all.sh`.
- JIRA downloader configuration is now centered on `download_jira_request.curl`; `download_jira.sh` and `download_jira_filtered.sh` extract Cookie directly from that file at runtime, and `download_jira_cookie.sh` has been removed.
- Recommended JIRA setup: copy any authenticated JIRA request as `cURL (bash)` from the browser and paste it into `download_jira/download_jira_request.curl`; the downloader only needs the `-b` / `Cookie` portion and does not require a specific endpoint.
- Feishu implementation files live in `download_feishu/`; published commands are installed into `~/.local/bin` by `update_scipt_all.sh`.
- Feishu downloader configuration is split into `download_feishu.sh`, `download_feishu_config.sh`, `download_feishu_request_kp31.curl`, `download_feishu_request_d01.curl`, and `download_feishu_request_d01_int.curl`, all under `download_feishu/`.
- Recommended Feishu setup: copy the issue-detail request as `cURL (bash)` from the browser and paste it into the matching request file such as `download_feishu/download_feishu_request_kp31.curl` or `download_feishu/download_feishu_request_d01.curl`; `download_feishu.sh` extracts cookie, referer, and user-agent from that file.
- Fallback Feishu setup: if the copied cURL omits `-b` / `Cookie`, set `FEISHU_COOKIE` in `download_feishu/download_feishu_config.sh` or run `FEISHU_COOKIE='...' downloadfeishu <issue_id>`.
- If Feishu returns JIRA-history attachment URLs, set `FEISHU_ATTACHMENT_JIRA_COOKIE` in `download_feishu/download_feishu_config.sh`; `download_feishu.sh` remains independent from `download_jira.sh` and only uses that extra cookie string for the returned attachment URL itself.
- `downloadFeishu` now attempts every attachment URL returned by Feishu. If a returned JIRA-history attachment responds with the JIRA login page, the script treats it as a download failure and removes the fake file.
- `downloadFeishu` now recursively scans the whole download tree for archives, so nested `zip`/`7z`/`rar` files extracted into child directories are processed in later passes too.
- `downloadFeishu` keeps the original save-dir naming logic: it first uses the existing project-name/version/title detection flow, normalizes project text such as `CHERY_KP31_Bug` to `KP31`, adds `KP31` / `D01` fallback recognition from Feishu text when needed, and if nothing matches still falls back to `/home/huangxingke/下载/<issue_id>`.
- Log-related implementation and completion files live in `logcat_sum/`; `update_scipt_all.sh` now publishes `startRandomLog`, `stopRandomLog`, `pullLogcatByAdb`, and `clearLogcatByAdb` from there.
- 中文说明：随机日志命令支持 `-s` 选设备，`stopRandomLog` 直接复用已发布的 `startRandomLog`。
- Common utility scripts live in `common_script/`; `update_scipt_all.sh` now publishes `startIflytekPage`, `startQnxD01`, `startBootGuideKP31`, `rebootDevice`, `killSystemui`, `resetVat`, `resetVst`, `setSalesArea`, `renameUsbDir`, `virtManager`, `startWin10`, `closeWin10`, and `syncftu` from there, and loads their shared completion logic from the same directory.
- 中文说明：这些通用命令都以发布到 `~/.local/bin` 的版本为准，不再依赖源码目录下的旧位置。
- `syncftu` / `syncFileToUbuntu` 用于 Windows 虚拟机 `FileToUbuntu` → Ubuntu `~/FileToUbuntu` 文件同步；源码在 `common_script/sync_filetoubuntu.sh`，路由修复在 `common_script/fix_virbr_route.sh`。与 `pcatusb` 刷机透传相互独立。
- `updateSciptAll` is the only local update implementation in this repo; old `updateAll` and JIRA/Feishu legacy update names are compatibility aliases to the same unified updater.
- `update_scipt_all.sh` publishes these downloader entry points: `downloadJira`, `downloadJiraFiltered`, `downloadFeishu`, `downloadFeishuFliter`, plus helper files `download_jira_request.curl`, `download_feishu_config.sh`, `download_feishu_request_kp31.curl`, `download_feishu_request_d01.curl`, and `download_feishu_request_d01_int.curl`.
- Jira and Feishu downloader aliases are command-name aliases only; they do not need device completion.
- Random log, `pullLogcatByAdb`, and `clearLogcatByAdb` variants support `-s` device selection and tab completion.
- Voice command variants and Iflytek update command variants also support `-s` device selection and tab completion. `updateIflytekResD01`, `updateIflytekResD01Int`, and `updateIflytekResKp31` are resource-only shortcuts published from `update_iflytek/update_iflytek_res_d01.sh`, `update_iflytek/update_iflytek_res_d01_int.sh`, and `update_iflytek/update_iflytek_res_kp31.sh`. Voice build implementations, shared helpers, completion logic, and VoiceAssistant API jar helper scripts now live in `voice_build/`. `update_scipt_all.sh` now publishes `voiceAssistant*`, `voiceSetting*`, `makeVoiceAssistantApiKp31`, and `makeVoiceAssistantApiD01` from there; Iflytek implementation scripts still live in `update_iflytek/`.
- `voiceBtClick` supports `-s` device selection and tab completion. `soundBtClick` variants remain compatibility aliases.
- `voiceBtClick` is the canonical implementation for the VoiceCommonService voice-button action.
- Rename USB Dir variants now live in `common_script/`, are published by `update_scipt_all.sh`, and support case-insensitive Tab completion for command names plus current first-level directories under the configured USB mount point.
- Virt Manager now lives in `common_script/`, is published by `update_scipt_all.sh`, and also installs an application launcher into `~/.local/share/applications` and the desktop.
- `startWin10` starts libvirt VM `win10-pct` and opens virt-viewer; desktop/app shortcut name is `startWin10`. Case-insensitive Tab completion is provided by `startWin10_completion.sh`.
- `closeWin10` shuts down `win10-pct` (graceful then force destroy) so qemu frees memory, closes virt-viewer, and installs desktop shortcut `closeWin10`. Case-insensitive Tab completion is provided by `closeWin10_completion.sh`.
- Sync FileToUbuntu (`syncftu`) now lives in `common_script/`, is published by `update_scipt_all.sh`, supports case-insensitive Tab completion for command names, `-s` online-device completion, and accepts `--quiet` / `--fix-route`.
- Legacy underscore-style shortcuts have been removed except where they are still intentionally published as compatibility aliases.
- `shell_refresh_hooks.sh` is loaded from `~/.bashrc` when a new Bash shell starts; it does not publish scripts, but it does define helper update functions and immediately reload current completion definitions into the shell session.
- `update_scipt_all.sh` is the actual publisher for local commands in `~/.local/bin`; it now only ensures the single `shell_refresh_hooks.sh` entry exists in `~/.bashrc`, and no longer writes per-completion source lines there.
- If command names or symlink targets were just updated, run `hash -r`; if completion behavior was updated, run `source ~/.bashrc` or `reload_local_completions`.
- `makeVoiceAssistantApiKp31` and `makeVoiceAssistantApiD01` accept either a full version like `1.8.7` or a 3-digit shorthand like `187` -> `1.8.7`, `211` -> `2.1.1`.
- `makeVoiceAssistantApiKp31` and `makeVoiceAssistantApiD01` are local jar build helpers, so they do not support `-s`; connected-device Tab completion still applies to the voice deploy commands such as `voiceAssistant*` and `voiceSetting*`.

## Examples
```bash
voiceAssistantKp31 -s <device_serial>
voiceAssistantT12a -s <device_serial>
makeVoiceAssistantApiKp31 187
makeVoiceAssistantApiD01 211
voiceassistantkp31 -s <device_serial>
ksui -s <device_serial>
killsystemui -s <device_serial>
resetVat -s <device_serial>
resetVst -s <device_serial>
setSalesArea -s <device_serial> 7
startRandomlog -s <device_serial>
pullLogcatByAdb -s <device_serial>
clearLogcatByAdb -s <device_serial>
voiceBtClick -s <device_serial>
soundBtClick -s <device_serial>
startQnxD01
startBootGuideKP31 -s <device_serial>
syncftu
syncftu -s <device_serial>
syncftu --fix-route
syncFileToUbuntu --quiet
clearLogcatByAdb /data/log
updateIflytekResD01 -s <device_serial>
updateIflytekResD01Int -s <device_serial>
updateIflytekResKp31 -s <device_serial>
replaceLocal -s <device_serial>
replaceLocalD01p -s <device_serial>
replaceOut -s <device_serial>
replaceOutD01p -s <device_serial>
updateSciptAll
updateAll
downloadJira CHYKP31-1028
# Edit download_jira/download_jira_request.curl with the latest authenticated JIRA cURL, then run:
downloadJiraFiltered CHYKP31-1028
downloadFeishu 7043211990
FEISHU_COOKIE='session=...; meego_csrf_token=...; meego_local=28800' downloadfeishu 7043211990
# If Feishu issue attachments are actually JIRA-history attachments, set FEISHU_ATTACHMENT_JIRA_COOKIE in download_feishu/download_feishu_config.sh.
# Edit download_feishu/download_feishu_request.curl with the latest browser-exported issue-detail cURL, then run:
downloadfeishu 7043211990
downloadb 7043211990
```
