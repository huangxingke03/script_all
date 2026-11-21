#!/bin/bash
set -u

STUDIO_HOME="${ANDROID_STUDIO_HOME:-/opt/android-studio}"
JAVA_PATTERN="${STUDIO_HOME}/jbr/bin/java"
FSNOTIFIER_PATTERN="${STUDIO_HOME}/bin/fsnotifier"

studio_running() {
    pgrep -f "$JAVA_PATTERN" >/dev/null 2>&1
}

if ! studio_running; then
    echo "Android Studio 未在运行"
    exit 0
fi

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
    exit 1
fi
echo "Android Studio 已停止"
