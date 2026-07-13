#!/usr/bin/env bash

set -euo pipefail

# Default values. You can edit these directly or override names on the command line.
MOUNT_POINT="/media/huangxingke/E689-0352"
OLD_DIR_NAME="all_images_cut"
NEW_DIR_NAME="all_images"
DEVICE="/dev/sda1"

usage() {
  cat <<'HELP'
Usage:
  bash rename_usb_dir.sh
  bash rename_usb_dir.sh <old_dir_name> <new_dir_name>
  renameUsbDir <old_dir_name> <new_dir_name>

Examples:
  bash rename_usb_dir.sh all_images_cut all_images
  renameUsbDir all_images_cut all_images

Notes:
  - Without arguments, the script uses the default names configured in the file.
  - If the USB mount point or device changes, update MOUNT_POINT and DEVICE at the top.
HELP
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -eq 2 ]]; then
  OLD_DIR_NAME="$1"
  NEW_DIR_NAME="$2"
elif [[ $# -ne 0 ]]; then
  usage >&2
  exit 1
fi

SOURCE_DIR="${MOUNT_POINT}/${OLD_DIR_NAME}"
TARGET_DIR="${MOUNT_POINT}/${NEW_DIR_NAME}"

if [[ ! -d "${MOUNT_POINT}" ]]; then
  echo "Mount point not found: ${MOUNT_POINT}" >&2
  exit 1
fi

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "Source directory not found: ${SOURCE_DIR}" >&2
  exit 1
fi

if [[ -e "${TARGET_DIR}" ]]; then
  echo "Target already exists: ${TARGET_DIR}" >&2
  exit 1
fi

mv "${SOURCE_DIR}" "${TARGET_DIR}"
sync

echo "Renamed:"
echo "  ${SOURCE_DIR}"
echo "  -> ${TARGET_DIR}"

if udisksctl unmount -b "${DEVICE}"; then
  echo "Unmounted ${DEVICE}"
else
  echo "Rename succeeded, but ${DEVICE} is still busy. Close any open files or folders and rerun:" >&2
  echo "  sync" >&2
  echo "  udisksctl unmount -b ${DEVICE}" >&2
fi
