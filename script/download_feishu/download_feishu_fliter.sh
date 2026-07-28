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

exec env FEISHU_FILTER_SKIP_SPECIAL=1 "${TARGET_SCRIPT}" "$@"
