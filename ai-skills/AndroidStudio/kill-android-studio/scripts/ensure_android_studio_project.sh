#!/bin/bash
# Closes Android Studio when the target project is not already open.
# vehicle/vmedia must not use this script; use open_android_studio_project_extra.sh.
set -u

CHECK_ONLY=0
if [ "${1:-}" = "--check" ]; then
    CHECK_ONLY=1
    shift
fi

PROJECT="${1:-}"
OPEN_SCRIPT="${2:-}"
KILL_SCRIPT="/home/huangxingke/.agents/skills/kill-android-studio/scripts/kill_android_studio.sh"
STUDIO_HOME="${ANDROID_STUDIO_HOME:-/opt/android-studio}"
JAVA_PATTERN="${STUDIO_HOME}/jbr/bin/java"
GNOME_PID="$(pgrep -n -u "$(id -u)" gnome-shell || true)"

if [ -z "$PROJECT" ] || { [ "$CHECK_ONLY" -eq 0 ] && [ -z "$OPEN_SCRIPT" ]; }; then
    echo "用法: $0 [--check] <项目目录> <打开脚本>"
    exit 1
fi
if [ ! -d "$PROJECT" ]; then
    echo "项目目录不存在: $PROJECT"
    exit 1
fi
if [ "$CHECK_ONLY" -eq 0 ]; then
    if [ ! -x "$OPEN_SCRIPT" ]; then
        echo "未找到打开脚本: $OPEN_SCRIPT"
        exit 1
    fi
    if [ ! -x "$KILL_SCRIPT" ]; then
        echo "未找到关闭脚本: $KILL_SCRIPT"
        exit 1
    fi
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

studio_running() {
    pgrep -f "$JAVA_PATTERN" >/dev/null 2>&1
}

studio_pids() {
    pgrep -f "$JAVA_PATTERN" || true
}

recent_projects_xml() {
    local pid selector xml
    pid="$(pgrep -n -f "$JAVA_PATTERN" || true)"
    if [ -n "$pid" ] && [ -r "/proc/$pid/cmdline" ]; then
        selector="$(tr '\0' '\n' < "/proc/$pid/cmdline" | sed -n 's/^-Didea.paths.selector=//p' | head -n 1)"
        if [ -n "$selector" ]; then
            xml="$HOME/.config/Google/${selector}/options/recentProjects.xml"
            if [ -f "$xml" ]; then
                printf '%s\n' "$xml"
                return 0
            fi
        fi
    fi
    ls -1d "$HOME/.config/Google/AndroidStudio"*/options/recentProjects.xml 2>/dev/null | sort -V | tail -n 1
}

studio_window_titles() {
    DISPLAY="${DISPLAY}" XAUTHORITY="${XAUTHORITY:-}" xwininfo -root -tree 2>/dev/null \
        | python3 -c 'import sys
for line in sys.stdin:
    if "jetbrains-studio" not in line:
        continue
    if "Content window" in line:
        continue
    start = line.find("\"")
    end = line.find("\":", start + 1) if start >= 0 else -1
    if start < 0 or end < 0:
        continue
    title = line[start + 1:end]
    if title in ("jetbrains-studio",):
        continue
    print(title)
'
}

idea_log() {
    local pid selector log
    pid="$(pgrep -n -f "$JAVA_PATTERN" || true)"
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

project_already_open() {
    local titles pids log
    titles="$(studio_window_titles || true)"
    pids="$(studio_pids | tr '\n' ' ')"
    log="$(idea_log || true)"
    python3 - "$PROJECT" "$titles" "$pids" "${log:-}" <<'PY'
import os
import sys

project, titles_text, pids_text, log_path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
project = os.path.realpath(os.path.abspath(project))
basename = os.path.basename(project)
parent = os.path.basename(os.path.dirname(project))

def normalize_path(path):
    path = (path or "").strip().strip("\"'")
    if not path:
        return None
    path = os.path.expanduser(path.replace("$USER_HOME$", os.path.expanduser("~")))
    try:
        return os.path.realpath(path)
    except OSError:
        return os.path.abspath(path)

def extract_after(line, marker, stops):
    idx = line.rfind(marker)
    if idx < 0:
        return None
    rest = line[idx + len(marker):].strip()
    end = len(rest)
    for stop in stops:
        pos = rest.find(stop)
        if pos >= 0:
            end = min(end, pos)
    return rest[:end].strip() or None

def current_project_from_log():
    if not log_path or not os.path.isfile(log_path):
        return None
    try:
        with open(log_path, "rb") as handle:
            lines = handle.read().decode("utf-8", "ignore").splitlines()
    except OSError:
        return None
    frame_at = None
    current = None
    for index, line in enumerate(lines):
        if "Project frame set to Project" not in line and "Setting project frame to Project" not in line:
            continue
        path = normalize_path(extract_after(line, "componentStore=", (")", ",", " ")))
        if path:
            current = path
            frame_at = index
    if not current or frame_at is None:
        return None
    for line in lines[frame_at + 1:]:
        if "DISPOSE_IN_PROGRESS" not in line or "componentStore=" not in line:
            continue
        disposed = normalize_path(extract_after(line, "componentStore=", (")", ",", " ")))
        if disposed == current:
            return None
    return current

def cmdline_projects():
    found = set()
    for pid in pids_text.split():
        try:
            with open("/proc/%s/cmdline" % pid, "rb") as handle:
                args = [part.decode("utf-8", "ignore") for part in handle.read().split(b"\0") if part]
        except OSError:
            continue
        if "com.android.tools.idea.MainWrapper" not in args and not any("studio" in part for part in args):
            continue
        for raw in reversed(args):
            if not raw.startswith("/"):
                continue
            candidate = normalize_path(raw)
            if candidate and os.path.isdir(candidate) and candidate != project and "/android-studio" in candidate:
                continue
            if candidate and os.path.isdir(candidate):
                found.add(candidate)
                break
    return found

def title_has_exact_path():
    markers = (project, os.path.join(parent, basename))
    for title in titles_text.splitlines():
        if any(marker and marker in title for marker in markers):
            return True
    return False

if title_has_exact_path():
    sys.exit(0)
current = current_project_from_log()
if current:
    sys.exit(0 if current == project else 1)
if project in cmdline_projects():
    sys.exit(0)
sys.exit(1)
PY
}

if studio_running && project_already_open; then
    echo "Android Studio 已打开目标项目，跳过关闭和重新打开: $PROJECT"
    exit 0
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
    echo "Android Studio 未打开目标项目: $PROJECT"
    exit 1
fi

"$KILL_SCRIPT"
"$OPEN_SCRIPT" "$PROJECT"
