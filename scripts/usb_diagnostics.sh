#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/platform.sh"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/usb.sh"

HOST_OS="$(detect_os)"

echo "=========================================="
echo " Android Physical USB Diagnostics"
echo "=========================================="
echo

echo "[INFO] HOST OS: ${HOST_OS}"
echo

case "${HOST_OS}" in

    linux)

        # --------------------------------------------------
        # lsusb
        # --------------------------------------------------

        if ! linux_lsusb_available; then

            log_error "lsusb not found"

            echo
            echo "Install on Ubuntu/Debian with:"
            echo
            echo " sudo apt install usbutils"

            exit 1
        
        fi

        log_ok "lsusb is avaiable"

        echo
        echo "USB devices:"
        echo "------------------------------------------"

        linux_usb_devices

        echo "------------------------------------------"
        echo

        # --------------------------------------------------
        # plugdev
        # --------------------------------------------------

        if linux_user_in_plugdev; then

            log_ok "Current user belongs to plugdev"
        
        else
        
            log_warn "Current user is not"
        
            echo
            echo "Suggested Ubuntu command:"
            echo
            echo " sudo usermod -aG plugdev \"\$LOGNAME\""
            echo
            echo "Log out and log back in aftger changing groups."
        
        fi

        # --------------------------------------------------
        # udev
        # --------------------------------------------------

        if linux_android_udev_rules_present; then

            log_ok "Android-related udev rules found"

        else

            log_warn "Android-related udev rules not found"

            echo
            echo "Suggesed Ubuntu/Debian package:"
            echo
            echo " sudo apt install android-sdk-platform-tools-common"
        
        fi

        ;;

    darwin)

        # --------------------------------------------------
        # system_profiler
        # --------------------------------------------------
    
        if ! macos_system_profiler_available; then

            die "system_profiler not found"
        
        fi
esac