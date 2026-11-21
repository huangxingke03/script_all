#!/bin/bash
# Open an Android Studio project in addition to projects already open.
# Never kills or restarts Android Studio. Already-open exact paths are skipped.
set -u

CHECK_ONLY=0
if [ "${1:-}" = "--check" ]; then
    CHECK_ONLY=1
    shift
fi

PROJECT="${1:-}"
STUDIO_HOME="${ANDROID_STUDIO_HOME:-/opt/android-studio}"
STUDIO_BIN="${STUDIO_HOME}/bin/studio.sh"
JAVA_BIN="${STUDIO_HOME}/jbr/bin/java"
JAVA_PATTERN="${STUDIO_HOME}/jbr/bin/java"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_JAR="${SCRIPT_DIR}/extra-open/open-new-window-agent.jar"
AGENT_CP="${SCRIPT_DIR}/extra-open"
LOCK_FILE="/tmp/android-studio-extra-open.lock"
GNOME_PID="$(pgrep -n -u "$(id -u)" gnome-shell || true)"

if [ -z "$PROJECT" ]; then
    echo "用法: $0 [--check] <项目目录>"
    exit 1
fi
if [ ! -d "$PROJECT" ]; then
    echo "项目目录不存在: $PROJECT"
    exit 1
fi
PROJECT="$(realpath -m "$PROJECT")"

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

studio_pid() {
    pgrep -f "$JAVA_PATTERN" | head -n 1 || true
}

studio_running() {
    [ -n "$(studio_pid)" ]
}

studio_window() {
    DISPLAY="${DISPLAY}" XAUTHORITY="${XAUTHORITY:-}" xwininfo -root -tree 2>/dev/null \
        | grep -F 'jetbrains-studio' >/dev/null 2>&1
}

idea_log() {
    local pid selector log
    pid="$(studio_pid)"
    if [ -n "$pid" ] && [ -r "/proc/$pid/cmdline" ]; then
        selector="$(tr '\0' '\n' < "/proc/$pid/cmdline" | sed -n 's/^-Didea.paths.selector=//p' | head -n 1)"
        if [ -n "$selector" ]; then
            log="$HOME/.cache/Google/${selector}/log/idea.log"
            if [ -f "$log" ]; then
                printf '%s\n' "$log"
                return 0
            fi
        fi
    fi
    ls -1dt "$HOME/.cache/Google/AndroidStudio"*/log/idea.log 2>/dev/null | head -n 1
}

general_xml() {
    local pid selector xml
    pid="$(studio_pid)"
    if [ -n "$pid" ] && [ -r "/proc/$pid/cmdline" ]; then
        selector="$(tr '\0' '\n' < "/proc/$pid/cmdline" | sed -n 's/^-Didea.paths.selector=//p' | head -n 1)"
        if [ -n "$selector" ]; then
            xml="$HOME/.config/Google/${selector}/options/ide.general.xml"
            if [ -f "$xml" ]; then
                printf '%s\n' "$xml"
                return 0
            fi
        fi
    fi
    ls -1d "$HOME/.config/Google/AndroidStudio"*/options/ide.general.xml 2>/dev/null | sort -V | tail -n 1
}

list_open_projects() {
    local log
    log="$(idea_log || true)"
    python3 - "${log:-}" <<'PY'
import os
import sys

log_path = sys.argv[1]

def normalize(path):
    path = (path or "").strip().strip("\"'")
    if not path:
        return None
    path = os.path.expanduser(path.replace("$USER_HOME$", os.path.expanduser("~")))
    try:
        return os.path.realpath(path)
    except OSError:
        return os.path.abspath(path)

def extract(line):
    marker = "componentStore="
    idx = line.rfind(marker)
    if idx < 0:
        return None
    rest = line[idx + len(marker):].strip()
    end = len(rest)
    for stop in (")", ",", " "):
        pos = rest.find(stop)
        if pos >= 0:
            end = min(end, pos)
    return normalize(rest[:end])

current = {}
order = []
if log_path and os.path.isfile(log_path):
    try:
        with open(log_path, "rb") as handle:
            lines = handle.read().decode("utf-8", "ignore").splitlines()
    except OSError:
        lines = []
    for line in lines:
        if "Project frame set to Project" in line or "Setting project frame to Project" in line:
            path = extract(line)
            if not path:
                continue
            if path not in current:
                order.append(path)
            current[path] = True
        elif "DISPOSE_IN_PROGRESS" in line and "componentStore=" in line:
            path = extract(line)
            if path and path in current:
                del current[path]
                order = [item for item in order if item != path]
for path in order:
    if path in current:
        print(path)
PY
}

project_is_open() {
    list_open_projects | grep -Fxq "$PROJECT"
}

set_open_mode() {
    local pid="$1" value="$2" status="$3"
    "$JAVA_BIN" --add-modules jdk.attach -cp "$AGENT_CP" AttachAgent \
        "$pid" "$AGENT_JAR" "set:${value}:${status}"
}

MODE_PID=""
MODE_STATUS=""
MODE_XML=""
MODE_XML_BEFORE=""

restore_open_mode() {
    if [ -n "$MODE_PID" ]; then
        set_open_mode "$MODE_PID" -1 "$MODE_STATUS" >/dev/null 2>&1 || true
        MODE_PID=""
    fi
    if [ -n "$MODE_XML" ] && [ -n "$MODE_XML_BEFORE" ] && [ -f "$MODE_XML" ]; then
        python3 - "$MODE_XML" "$MODE_XML_BEFORE" <<'PY'
import pathlib
import re
import sys
path, before = sys.argv[1], sys.argv[2]
file = pathlib.Path(path)
text = file.read_text(encoding="utf-8")
current = re.search(r'name="confirmOpenNewProject2" value="([^"]*)"', text)
if current and current.group(1) != before:
    text = re.sub(
        r'(name="confirmOpenNewProject2" value=")[^"]*(")',
        lambda match: match.group(1) + before + match.group(2),
        text,
        count=1,
    )
    file.write_text(text, encoding="utf-8")
PY
    fi
}

trap restore_open_mode EXIT

if project_is_open; then
    echo "Android Studio 已打开目标项目，跳过额外打开: $PROJECT"
    exit 0
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
    echo "Android Studio 未打开目标项目: $PROJECT"
    exit 1
fi

if [ ! -x "$STUDIO_BIN" ]; then
    echo "未找到 Android Studio: $STUDIO_BIN"
    exit 1
fi
if [ ! -x "$JAVA_BIN" ] || [ ! -f "$AGENT_JAR" ]; then
    echo "未找到额外打开组件: $AGENT_JAR"
    exit 1
fi

exec 9>"$LOCK_FILE"
flock 9

BEFORE="$(list_open_projects || true)"
RUNNING_PID="$(studio_pid)"
if [ -n "$RUNNING_PID" ]; then
    MODE_XML="$(general_xml || true)"
    if [ -n "$MODE_XML" ]; then
        MODE_XML_BEFORE="$(python3 - "$MODE_XML" <<'PY'
import re
import sys
text = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r'name="confirmOpenNewProject2" value="([^"]*)"', text)
print(match.group(1) if match else "-1")
PY
)"
    fi
    MODE_STATUS="/tmp/android-studio-extra-open-status.$$"
    MODE_PID="$RUNNING_PID"
    if ! set_open_mode "$RUNNING_PID" 0 "$MODE_STATUS"; then
        echo "无法改为新窗口打开，已停止，未关闭已有工程: $PROJECT"
        exit 1
    fi
    if ! grep -q '^OK 0$' "$MODE_STATUS"; then
        echo "无法改为新窗口打开，已停止，未关闭已有工程: $PROJECT"
        echo "状态: $(cat "$MODE_STATUS" 2>/dev/null || true)"
        exit 1
    fi
fi

echo "正在用 Android Studio 额外打开 $PROJECT ..."
setsid -f "$STUDIO_BIN" "$PROJECT" </dev/null >/dev/null 2>&1

opened=0
kept_ok=1
for _ in $(seq 1 90); do
    if project_is_open; then
        opened=1
        break
    fi
    sleep 0.5
done

restore_open_mode

if [ "$opened" -ne 1 ]; then
    if studio_running && studio_window; then
        echo "已发出额外打开命令，但未检测到目标项目窗口: $PROJECT"
    else
        echo "已发出额外打开命令，但 Android Studio 未保持运行: $PROJECT"
    fi
    exit 1
fi

AFTER="$(list_open_projects || true)"
if [ -n "$BEFORE" ]; then
    while IFS= read -r old; do
        [ -n "$old" ] || continue
        if ! printf '%s\n' "$AFTER" | grep -Fxq "$old"; then
            echo "错误: 已打开的项目被关闭: $old"
            kept_ok=0
        fi
    done <<< "$BEFORE"
fi

if [ "$kept_ok" -ne 1 ]; then
    echo "额外打开未保持已有工程: $PROJECT"
    exit 1
fi

echo "Android Studio 已额外打开项目，未关闭已有工程: $PROJECT"
if [ -n "$BEFORE" ]; then
    echo "已保持打开:"
    printf '%s\n' "$BEFORE"
fi
exit 0
