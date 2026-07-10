# Command Aliases

## Voice Assistant D01
- Standard: `voiceAssistantD01`
- Variant: `voiceassistantD01`
- Variant: `voiceAssistantd01`
- Variant: `voiceassistantd01`

## Voice Assistant KP31
- Standard: `voiceAssistantKp31`
- Variant: `voiceassistantKp31`
- Variant: `voiceAssistantkp31`
- Variant: `voiceassistantkp31`

## Voice Setting D01
- Standard: `voiceSettingD01`
- Variant: `voicesettingD01`
- Variant: `voiceSettingd01`
- Variant: `voicesettingd01`

## Voice Setting KP31
- Standard: `voiceSettingKp31`
- Variant: `voicesettingKp31`
- Variant: `voiceSettingkp31`
- Variant: `voicesettingkp31`

## Xunfei KP31
- Standard: `xunfeikp31`
- Variant: `Xunfeikp31`
- Variant: `XunFeiKp31`
- Variant: `xunfeiKp31`
- Variant: `xunfeiKP31`

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

## Random Log
- Standard: `startRandomLog`
- Variant: `startrandomLog`
- Variant: `startRandomlog`
- Variant: `startrandomlog`
- Standard: `stopRandomLog`
- Variant: `stoprandomLog`
- Variant: `stopRandomlog`
- Variant: `stoprandomlog`

## Jira Commands
- Standard: `updateDownloadJira`
- Variant: `updatedownloadJira`
- Variant: `updateDownloadjira`
- Variant: `updatedownloadjira`
- Standard: `downloadJira`
- Variant: `downloadjira`

## Iflytek System Update Commands
- Standard: `updateD01IntSys`
- Variant: `updated01IntSys`
- Variant: `updateD01intSys`
- Variant: `updated01intSys`
- Standard: `updateD01Sys`
- Variant: `updated01Sys`
- Variant: `updateD01sys`
- Variant: `updated01sys`
- Standard: `updateD01pIntSys`
- Variant: `updated01pIntSys`
- Variant: `updateD01pintSys`
- Variant: `updated01pintSys`
- Standard: `updateKp31IntSys`
- Variant: `updatekp31IntSys`
- Variant: `updateKp31intSys`
- Variant: `updatekp31intSys`
- Standard: `updateKp31Sys`
- Variant: `updatekp31Sys`
- Variant: `updateKp31sys`
- Variant: `updatekp31sys`

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

## Virt Manager
- Standard: `virtManager`
- Variant: `virtmanager`
- Variant: `startVirtManager`
- Variant: `startvirtManager`
- Variant: `startVirtmanager`
- Variant: `startvirtmanager`
- Variant: `start_virt_manager`

## Notes
- Voice command variants all support `-s` device selection and tab completion.
- Random log and Iflytek update command variants also support `-s` device selection and tab completion.
- `pullLogcatByAdb` variants also support `-s` device selection and tab completion.
- Jira command variants are command-name aliases only; they do not need device completion.
- Rename USB Dir variants support case-insensitive Tab completion for command names and USB root directories.
- Virt Manager also installs an application launcher into ~/.local/share/applications.
- Legacy underscore-style shortcuts have been removed.

## Examples
```bash
voiceAssistantKp31 -s <device_serial>
voiceassistantkp31 -s <device_serial>
ksui -s <device_serial>
killsystemui -s <device_serial>
startRandomlog -s <device_serial>
updatekp31sys -s <device_serial>
pullLogcatByAdb -s <device_serial>
clearLogcatByAdb -s <device_serial>
clearLogcatByAdb /data/log
updateDownloadjira
updatedownloadjira
```
