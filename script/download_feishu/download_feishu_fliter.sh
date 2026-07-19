#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="${SCRIPT_DIR}/download_feishu.sh"

if [ ! -x "${TARGET_SCRIPT}" ]; then
    TARGET_SCRIPT="/home/huangxingke/project/Python/script/download_feishu/download_feishu.sh"
fi

exec env FEISHU_FILTER_SKIP_SPECIAL=1 "${TARGET_SCRIPT}" "$@"
