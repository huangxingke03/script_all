#!/bin/bash
set -u

STUDIO_HOME="${ANDROID_STUDIO_HOME:-/opt/android-studio}"
JAVA_PATTERN="${STUDIO_HOME}/jbr/bin/java"
FSNOTIFIER_PATTERN="${STUDIO_HOME}/bin/fsnotifier"
DESKTOP_ID="jetbrains-studio"
DESKTOP_FILE="${HOME}/.local/share/applications/${DESKTOP_ID}.desktop"
GNOME_PID="$(pgrep -n -u "$(id -u)" gnome-shell || true)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FONT_SYNC="${SCRIPT_DIR}/sync_android_studio_fonts.py"

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

stop_studio() {
    if studio_running; then
        echo "正在停止 Android Studio..."
        pkill -f "$JAVA_PATTERN" 2>/dev/null || true
        pkill -f "$FSNOTIFIER_PATTERN" 2>/dev/null || true
        for _ in $(seq 1 20); do
            studio_running || break
            sleep 0.5
        done
        if studio_running; then
            echo "进程未退出，强制结束"
            pkill -9 -f "$JAVA_PATTERN" 2>/dev/null || true
            pkill -9 -f "$FSNOTIFIER_PATTERN" 2>/dev/null || true
            sleep 0.5
        fi
        if studio_running; then
            echo "Android Studio 仍未退出"
            return 1
        fi
        echo "Android Studio 已停止"
    else
        echo "Android Studio 未在运行"
    fi
    return 0
}

sync_fonts() {
    python3 "$FONT_SYNC"
}

wait_studio_window() {
    local java_ok=0
    local window_ok=0
    for _ in $(seq 1 40); do
        if studio_running; then
            java_ok=1
        elif [ "$java_ok" -eq 1 ]; then
            echo "Android Studio 进程已退出，窗口未保持"
            return 1
        fi
        if [ "$java_ok" -eq 1 ] && studio_window; then
            window_ok=1
            echo "Android Studio 已重启，窗口已打开"
            return 0
        fi
        sleep 0.5
    done
    if [ "$java_ok" -eq 1 ]; then
        echo "Android Studio 进程已拉起，但未检测到窗口"
        return 1
    fi
    echo "快捷方式已发出，但 Android Studio 未保持运行"
    return 1
}

start_studio() {
    echo "正在用任务栏快捷方式启动 Android Studio..."
    local launched=0
    if command -v gtk-launch >/dev/null 2>&1; then
        setsid -f gtk-launch --display="$DISPLAY" "$DESKTOP_ID" </dev/null >/dev/null 2>&1
        launched=1
    elif command -v gio >/dev/null 2>&1 && [ -f "$DESKTOP_FILE" ]; then
        setsid -f gio launch "$DESKTOP_FILE" </dev/null >/dev/null 2>&1
        launched=1
    fi
    if [ "$launched" -eq 0 ]; then
        echo "未找到任务栏快捷方式: $DESKTOP_ID"
        return 1
    fi
    wait_studio_window
}

stop_studio || exit 1
sleep 1
sync_fonts || exit 1
start_studio || exit 1
sleep 2
if python3 "$FONT_SYNC" --check >/tmp/as-font-check.txt 2>&1; then
    cat /tmp/as-font-check.txt
    exit 0
fi
echo "启动后字体仍不一致，停止后再次同步并重启"
cat /tmp/as-font-check.txt
stop_studio || exit 1
sleep 1
sync_fonts || exit 1
start_studio || exit 1
sleep 2
python3 "$FONT_SYNC" --check
exit $?
