#!/bin/bash
set -u

PROJECT="${1:-/home/huangxingke/work/code/workCode/kp31/VoiceAssistant}"
STUDIO_HOME="${ANDROID_STUDIO_HOME:-/opt/android-studio}"
STUDIO_BIN="${STUDIO_HOME}/bin/studio.sh"
JAVA_PATTERN="${STUDIO_HOME}/jbr/bin/java"
ENSURE_SCRIPT="/home/huangxingke/.agents/skills/kill-android-studio/scripts/ensure_android_studio_project.sh"
if [ -x "$ENSURE_SCRIPT" ] && "$ENSURE_SCRIPT" --check "$PROJECT" >/dev/null 2>&1; then
    echo "Android Studio 已打开目标项目，跳过关闭和重新打开: $PROJECT"
    exit 0
fi
DESKTOP_ID="jetbrains-studio"
GNOME_PID="$(pgrep -n -u "$(id -u)" gnome-shell || true)"

load_session_env() {
    local pid="$1" line
    [ -n "$pid" ] && [ -r "/proc/$pid/environ" ] || return 0
    while IFS= read -r -d '' line; do
        case "$line" in
            DISPLAY=*|XAUTHORITY=*|DBUS_SESSION_BUS_ADDRESS=*|XDG_RUNTIME_DIR=*|XDG_CURRENT_DESKTOP=*|GNOME_SETUP_DISPLAY=*|XDG_SESSION_TYPE=*)
                export "$line"
                ;;
        esac
    done < "/proc/$pid/environ"
}

load_session_env "$GNOME_PID"
if [ -z "${DISPLAY:-}" ]; then
    if [ -S /tmp/.X11-unix/X1 ]; then
        export DISPLAY=":1"
    elif [ -S /tmp/.X11-unix/X0 ]; then
        export DISPLAY=":0"
    else
        export DISPLAY=":1"
    fi
fi
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -S "/run/user/${UID}/bus" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${UID}/bus"
fi
if [ -z "${XDG_RUNTIME_DIR:-}" ] && [ -d "/run/user/${UID}" ]; then
    export XDG_RUNTIME_DIR="/run/user/${UID}"
fi
if [ -z "${XAUTHORITY:-}" ] && [ -f "/run/user/${UID}/gdm/Xauthority" ]; then
    export XAUTHORITY="/run/user/${UID}/gdm/Xauthority"
fi
export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-ubuntu:GNOME}"

studio_running() {
    pgrep -f "$JAVA_PATTERN" >/dev/null 2>&1
}

studio_window() {
    DISPLAY="${DISPLAY}" XAUTHORITY="${XAUTHORITY:-}" xwininfo -root -tree 2>/dev/null \
        | grep -F 'jetbrains-studio' >/dev/null 2>&1
}

if [ ! -d "$PROJECT" ]; then
    echo "项目目录不存在: $PROJECT"
    exit 1
fi
if [ ! -x "$STUDIO_BIN" ]; then
    echo "未找到 Android Studio: $STUDIO_BIN"
    exit 1
fi

echo "正在用 Android Studio 打开 $PROJECT ..."
setsid -f "$STUDIO_BIN" "$PROJECT" </dev/null >/dev/null 2>&1

java_ok=0
for _ in $(seq 1 40); do
    if studio_running; then
        java_ok=1
    elif [ "$java_ok" -eq 1 ]; then
        echo "Android Studio 进程已退出，窗口未保持"
        exit 1
    fi
    if [ "$java_ok" -eq 1 ] && studio_window; then
        echo "Android Studio 已打开项目: $PROJECT"
        exit 0
    fi
    sleep 0.5
done

if [ "$java_ok" -eq 1 ]; then
    echo "Android Studio 进程已拉起，但未检测到窗口: $PROJECT"
    exit 1
fi
echo "已发出打开命令，但 Android Studio 未保持运行: $PROJECT"
exit 1
