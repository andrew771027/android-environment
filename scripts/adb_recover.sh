#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/adb_connection.sh"

command_exists_adb ||
    die "adb not found"

SERIAL="${1:-${DEVICE_SERIAL:-}}"

[[ -n "${SERIAL}" ]] ||
    die "SERIAL or DEVICE_SERIAL is required"

ADB_RECOVERY_TIMEOUT="${ADB_RECOVERY_TIMEOUT:-10}"

echo "=========================================="
echo " ADB Connection Recovery"
echo "=========================================="
echo

echo "[INFO] Serial: ${SERIAL}"

state="$(adb_device_state "${SERIAL}")"

echo "[INFO] Initial state: ${state:-missing}"


case "${state}" in 

    device)

        log_ok "Device is already ready"

        exit 0

        ;;
    
    unauthorized)

        log_error "Device is unauthorized"
        echo
        echo "Recovery cannot approve RSA authorization."
        echo "Unlock the Android device and accept"
        echo "the USB debigging prompt."
        echo

        exit 2
    
        ;;
    
    offline)

        echo
        echo "[INFO] Attempt 1: reconnect device"
        echo

        adb_reconnect_device "${SERIAL}" || true

        if wait_for_adb_ready \
            "${SERIAL}" \
            "${ADB_RECOVERY_TIMEOUT}"
        then

            log_ok "Device recovered after reconnect"
            
            exit 0
        
        fi

        echo
        echo "[INFO] Attempt 2: restart ADB server"
        echo

        adb_restart_server

        if wait_for_adb_ready \
            "${SERIAL}" \
            "${ADB_RECOVERY_TIMEOUT}"
        then

            log_ok "Device recovered after server restart"

            exit 0
        
        fi

        die "ADB recovery failed for ${SERIAL}"

        ;;
    
    "")

        echo
        echo "[INFO] Device is not currently listed by ADB"
        echo "[INFO] Restarting ADB server to rescan devices"
        echo

        adb_restart_server

        if wait_for_adb_ready \
            "${SERIAL}" \
            "${ADB_RECOVERY_TIMEOUT}"
        then

            log_ok "Device discovered after server restart"

            exit 0
        
        fi

        die "Device still not available after ADB server restart"

        ;;
    
    *)

        die "Unsupported ADB state: ${state}"

        ;;

esac