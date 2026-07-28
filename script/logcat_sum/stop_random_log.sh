#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${SCRIPT_DIR}/startRandomLog"
if [ ! -x "${MAIN_SCRIPT}" ]; then
    echo "错误: 未找到 ${MAIN_SCRIPT}" >&2
    exit 1
fi

exec "${MAIN_SCRIPT}" "$@" stop
