#!/bin/bash

DEVICE_SERIAL=""
TARGET_BRANCH="al_chery-d01_dev2"
REPO_DIR="/home/huangxingke/work/code/workCode/JETOUR_D01_IFLYTEK"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

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
    adb_cmd root
    if [ $? -ne 0 ]; then
        echo "❌ adb root 失败！请确认设备已 Root"
        exit 1
    fi
}

run_adb_remount() {
    adb_cmd remount
    if [ $? -ne 0 ]; then
        echo "❌ adb remount 失败！"
        exit 1
    fi
}

ensure_target_branch() {
    local current_branch
    local remote_name="origin"

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
    echo "拉取远端 ${remote_name}/${TARGET_BRANCH} 最新代码..."
    git fetch "${remote_name}" "${TARGET_BRANCH}" || {
        echo "错误: 拉取远端分支 ${remote_name}/${TARGET_BRANCH} 失败"
        exit 1
    }

    if [ "${current_branch}" != "${TARGET_BRANCH}" ]; then
        echo "当前分支为 ${current_branch}，开始切换到 ${TARGET_BRANCH}"
        git checkout "${TARGET_BRANCH}" >/dev/null 2>&1 || \
        git checkout -B "${TARGET_BRANCH}" "${remote_name}/${TARGET_BRANCH}" || {
            echo "错误: 切换到分支 ${TARGET_BRANCH} 失败，已停止后续推包"
            exit 1
        }
        echo "已切换到目标分支 ${TARGET_BRANCH}"
    else
        echo "当前已在目标分支 ${TARGET_BRANCH}"
    fi

    echo "强制同步本地分支到 ${remote_name}/${TARGET_BRANCH}..."
    git reset --hard "${remote_name}/${TARGET_BRANCH}" || {
        echo "错误: 重置本地分支到 ${remote_name}/${TARGET_BRANCH} 失败"
        exit 1
    }
    git clean -fd || {
        echo "错误: 清理本地未跟踪文件失败"
        exit 1
    }

    echo "本地代码已与 ${remote_name}/${TARGET_BRANCH} 保持一致"
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

"${SCRIPT_DIR}/update_d01_Int_sys_setting.sh" ${DEVICE_SERIAL:+-s "${DEVICE_SERIAL}"} || exit 1

echo "=== 开始推送 讯飞资源 到系统 ==="

run_adb_root
run_adb_remount

echo "🗑️    删除旧 Iflytek 资源..."
adb_cmd shell rm -rf /iflytek/iflytek/res

echo "📤  推送新 Iflytek 资源..."
adb_cmd push /home/huangxingke/work/code/workCode/JETOUR_D01_IFLYTEK/D01_INT/iflytek/res /iflytek/iflytek/res
adb_cmd shell chmod -R 777 /iflytek/iflytek/*

echo "更新 ：/iflytek/iflytek/res ---》成功"

echo "=== 开始推送 讯飞APK 到系统 ==="

run_adb_root
run_adb_remount

echo "🗑️    删除旧 Iflytek 应用..."
adb_cmd shell rm -rf /system/app/Iflytek*

echo "📤  推送新 APK..."
adb_cmd push /home/huangxingke/work/code/workCode/JETOUR_D01_IFLYTEK/D01_INT/system/app /system/

echo "清除语音设置，讯飞侧应用缓存..."
adb_cmd shell pm clear com.iflytek.cutefly.speechclient.hmi
adb_cmd shell pm clear com.autolink.voicesetting
echo "清除语音设置，讯飞侧应用缓存后重启台架..."
adb_cmd reboot
