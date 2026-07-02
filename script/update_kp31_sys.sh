#!/bin/bash

set -euo pipefail

DEVICE_SERIAL=""
TARGET_BRANCH="al_chery-kp31_dev"
REPO_DIR="/home/huangxingke/work/code/workCode/JETOUR_D01_IFLYTEK"

usage() {
    echo "用法: $0 [-s device_serial]"
    echo "  -s device_serial  指定 adb 设备序列号"
}

adb_cmd() {
    if [ -n "${DEVICE_SERIAL}" ]; then
        adb -s "${DEVICE_SERIAL}" "$@"
    else
        adb "$@"
    fi
}

ensure_device_ready() {
    local device_status
    local device_count

    adb start-server >/dev/null
    if [ -n "${DEVICE_SERIAL}" ]; then
        device_status=$(adb devices | sed '1d' | awk -v serial="${DEVICE_SERIAL}" '$1 == serial {print $2}')
        if [ -z "${device_status}" ]; then
            echo "错误: adb devices 中未找到设备序列号 ${DEVICE_SERIAL}"
            exit 1
        fi
        if [ "${device_status}" != "device" ]; then
            echo "错误: 设备 ${DEVICE_SERIAL} 当前状态为 ${device_status}，必须为 device 才能继续"
            exit 1
        fi
        return 0
    fi

    device_count=$(adb devices | sed '1d' | awk '$2 == "device" {count++} END {print count + 0}')
    if [ "${device_count}" -gt 1 ]; then
        echo "错误: 检测到多个在线设备，请使用 -s 指定设备序列号"
        exit 1
    fi
}

run_adb_root() {
    adb_cmd root || {
        echo "❌ adb root 失败！请确认设备已 Root"
        exit 1
    }
}

run_adb_remount() {
    local remount_output

    remount_output=$(adb_cmd remount 2>&1) || {
        printf '%s\n' "${remount_output}"
        echo "❌ adb remount 失败！"
        exit 1
    }

    printf '%s\n' "${remount_output}"
}

ensure_system_writable() {
    adb_cmd shell 'touch /system/.update_kp31_sys_write_test && rm -f /system/.update_kp31_sys_write_test' >/dev/null 2>&1 || {
        echo "❌ /system 仍为只读，无法推送系统 APK。"
        echo "请先确认设备支持 adb remount，或先执行 adb disable-verity && adb reboot。"
        exit 1
    }
}

push_path() {
    local source_path="$1"
    local target_path="$2"

    adb_cmd push "${source_path}" "${target_path}" || {
        echo "❌ 推送失败: ${source_path} -> ${target_path}"
        exit 1
    }
}

ensure_target_branch_latest() {
    local current_branch
    local untracked_count

    cd "${REPO_DIR}" || {
        echo "错误: 无法进入仓库目录 ${REPO_DIR}"
        exit 1
    }

    current_branch=$(git branch --show-current 2>/dev/null)
    if [ -z "${current_branch}" ]; then
        echo "错误: 当前目录不是有效的 Git 仓库，或无法识别当前分支"
        exit 1
    fi

    echo "切换到 ：JETOUR_D01_IFLYTEK根目录"
    echo "开始获取 ${TARGET_BRANCH} 远端最新代码..."

    git fetch origin "${TARGET_BRANCH}" || {
        echo "错误: 获取远端分支 ${TARGET_BRANCH} 失败"
        exit 1
    }

    if [ "${current_branch}" != "${TARGET_BRANCH}" ]; then
        echo "当前分支为 ${current_branch}，强制切换到 ${TARGET_BRANCH}"
        git checkout -f "${TARGET_BRANCH}" || {
            echo "错误: 切换到分支 ${TARGET_BRANCH} 失败，请检查是否有未跟踪文件冲突"
            exit 1
        }
    else
        echo "当前已在目标分支 ${TARGET_BRANCH}"
    fi

    echo "本地已跟踪修改将被远端覆盖..."
    git reset --hard "origin/${TARGET_BRANCH}" || {
        echo "错误: 重置到 origin/${TARGET_BRANCH} 失败"
        exit 1
    }

    untracked_count=$(git ls-files --others --exclude-standard | wc -l)
    if [ "${untracked_count}" -gt 0 ]; then
        echo "提示: 仓库仍有 ${untracked_count} 个未跟踪文件，未做删除。"
    fi

    echo "已同步到 origin/${TARGET_BRANCH} 最新代码"
}

while getopts ":s:h" opt; do
    case "${opt}" in
        s)
            DEVICE_SERIAL="${OPTARG}"
            ;;
        h)
            usage
            exit 0
            ;;
        :)
            echo "错误: -${OPTARG} 需要传入设备序列号"
            usage
            exit 1
            ;;
        \?)
            echo "错误: 不支持的参数 -${OPTARG}"
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

ensure_device_ready

echo "=== 开始同步 ${TARGET_BRANCH} 最新代码 ==="
ensure_target_branch_latest

echo "=== 开始推送 讯飞资源 到系统 ==="

run_adb_root
run_adb_remount
ensure_system_writable

echo "🗑️   删除旧 Iflytek 资源..."
adb_cmd shell rm -rf /iflytek/iflytek/res

echo "📤  推送新 Iflytek 资源..."
push_path /home/huangxingke/work/code/workCode/JETOUR_D01_IFLYTEK/KP31/iflytek/res /iflytek/iflytek/res
adb_cmd shell chmod -R 777 /iflytek/iflytek/*

echo "更新 ：/iflytek/iflytek/res ---》成功"

echo "=== 开始推送 讯飞APK 到系统 ==="

run_adb_root
run_adb_remount
ensure_system_writable

echo "🗑️   删除旧 Iflytek 应用..."
adb_cmd shell rm -rf /system/app/Iflytek*

echo "📤  推送新 APK..."
push_path /home/huangxingke/work/code/workCode/JETOUR_D01_IFLYTEK/KP31/system/app /system/
adb_cmd shell sync

echo "清除语音设置，讯飞侧应用缓存..."
adb_cmd shell pm clear com.iflytek.cutefly.speechclient.hmi
adb_cmd shell pm clear com.autolink.voicesetting

echo "清除语音设置，讯飞侧应用缓存后重启..."
adb_cmd reboot
