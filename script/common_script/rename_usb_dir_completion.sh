#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RENAME_USB_SCRIPT="${SCRIPT_DIR}/rename_usb_dir.sh"

_rename_usb_dir_collect_dirs() {
    local script_path="$1"
    local mount_point

    mount_point=$(sed -n 's/^MOUNT_POINT="\(.*\)"$/\1/p' "${script_path}" | head -n 1)
    if [ -z "${mount_point}" ] || [ ! -d "${mount_point}" ]; then
        return 0
    fi

    find "${mount_point}" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -f
}

_rename_usb_dir_completion() {
    local cur
    cur="${COMP_WORDS[COMP_CWORD]}"

    compopt +o default +o bashdefault 2>/dev/null

    case "${COMP_CWORD}" in
        1|2)
            mapfile -t COMPREPLY < <(compgen -W "$(_rename_usb_dir_collect_dirs "${RENAME_USB_SCRIPT}")" -- "${cur}")
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

rename_usb_dir_completion_repair() {
    local command_name
    local -a commands=(
        ./rename_usb_dir.sh
        rename_usb_dir.sh
        /usr/local/bin/renameUsbDir
        /usr/local/bin/renameusbDir
        /usr/local/bin/renameUsbdir
        /usr/local/bin/renameusbdir
        /usr/local/bin/rename_usb_dir
        renameUsbDir
        renameusbDir
        renameUsbdir
        renameusbdir
        rename_usb_dir
    )

    for command_name in "${commands[@]}"; do
        complete -r "${command_name}" 2>/dev/null || true
    done

    for command_name in "${commands[@]}"; do
        complete -o nospace -F _rename_usb_dir_completion "${command_name}"
    done
}

rename_usb_dir_completion_repair
