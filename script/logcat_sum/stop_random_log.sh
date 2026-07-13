#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="${SCRIPT_DIR}/start_random_log.sh"

exec "${MAIN_SCRIPT}" "$@" stop
