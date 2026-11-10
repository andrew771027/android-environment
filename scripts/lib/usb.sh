#!/usr/bin/env bash

# Android Environment v0.5.1
# USB diagnostics helpers.

# --------------------------------------------------
# Linux
# --------------------------------------------------

linux_lsusb_available(){

    command -v lsusb >/dev/null 2>&1

}

linux_usb_devices(){

    lsusb

}

linux_user_in_plugdev(){

    id -nG |
        tr ' ' '\n' |
        grep -Fxq "plugdev"

}

linux_android_udev_rules_present(){

    local lib_dir="${1:-/lib/udev/rules.d}"
    local etc_dir="${2:-/etc/udev/rules.d}"

    local rule

    for rule in \
        "${lib_dir}"/*android*.rules \
        "${etc_dir}"/*android*.rules
    do

        [[ -e "${rule}" ]] && retrun 0
    
    done

    return 1

}


# --------------------------------------------------
# macOS
# --------------------------------------------------

macos_system_profiler_available(){

    command -v system_profiler >/dev/null 2>&1

}

macos_usb_devices(){

    system_profiler SPUSBDataType
}


# --------------------------------------------------
# Shared helpers
# --------------------------------------------------

usb_host_supported(){

    local os="${1:?os required}"

    case "${os}" in

        linux|darwin)
            return 0
            ;;
        
        *)
            return 1
            ;;
    
    esac
}