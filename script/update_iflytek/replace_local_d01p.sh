#!/bin/bash

# replaceLocalD01p 快捷入口：业务逻辑单独维护在原脚本，这里只做转发与 -s 设备参数。
# 原脚本：/home/huangxingke/work/file/讯飞切换版本/build_replace/sh/replace_local_d01p.sh

SOURCE_DIR="/home/huangxingke/work/file/讯飞切换版本/build_replace/sh"
SOURCE_SCRIPT="${SOURCE_DIR}/replace_local_d01p.sh"
DEVICE_SERIAL=""

usage() {
    echo "用法: replaceLocalD01p [-s device_serial]"
    echo "  -s device_serial  指定 adb 设备序列号"
    echo "逻辑维护在: ${SOURCE_SCRIPT}"
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
            echo "错误: -${OPTARG} 需要传入设备序列号" >&2
            usage
            exit 1
            ;;
        \?)
            echo "错误: 不支持的参数 -${OPTARG}" >&2
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if [ ! -f "${SOURCE_SCRIPT}" ]; then
    echo "错误: 未找到原脚本 ${SOURCE_SCRIPT}" >&2
    exit 1
fi

cd "${SOURCE_DIR}" || {
    echo "错误: 无法进入目录 ${SOURCE_DIR}" >&2
    exit 1
}

if [ -n "${DEVICE_SERIAL}" ]; then
    # export 序列号，否则子 bash 里 export -f 的 adb() 读到空串，变成 -s ''
    export DEVICE_SERIAL
    adb() {
        command adb -s "${DEVICE_SERIAL}" "$@"
    }
    export -f adb
fi

exec bash "${SOURCE_SCRIPT}" "$@"
