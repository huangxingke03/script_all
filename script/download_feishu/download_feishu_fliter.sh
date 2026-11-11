#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="${SCRIPT_DIR}/downloadFeishu"
if [ ! -x "${TARGET_SCRIPT}" ]; then
    TARGET_SCRIPT="${SCRIPT_DIR}/download_feishu.sh"
fi
if [ ! -x "${TARGET_SCRIPT}" ]; then
    echo "错误: 未找到 ${TARGET_SCRIPT}" >&2
    exit 1
fi

run_one() {
    env FEISHU_FILTER_SKIP_SPECIAL=1 "${TARGET_SCRIPT}" "$1"
}

ids=()
for arg in "$@"; do
    arg="${arg//，/ }"
    arg="${arg//、/ }"
    arg="${arg//,/ }"
    for id in $arg; do
        [ -n "$id" ] && ids+=("$id")
    done
done

if [ "${#ids[@]}" -le 1 ]; then
    exec env FEISHU_FILTER_SKIP_SPECIAL=1 "${TARGET_SCRIPT}" "$@"
fi

echo "多任务下载: ${ids[*]}"
status=0
total="${#ids[@]}"
index=0
for id in "${ids[@]}"; do
    index=$((index + 1))
    echo "==== [${index}/${total}] 开始下载 ${id} ===="
    if run_one "$id"; then
        echo "==== [${index}/${total}] ${id} 下载完成 ===="
    else
        echo "==== [${index}/${total}] ${id} 下载失败 ====" >&2
        status=1
    fi
done
exit "${status}"
