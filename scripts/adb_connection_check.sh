#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/physical_device.sh"
source "${PROJECT_ROOT}/scripts/lib/adb_connection.sh"

command_exists abd ||
    die "adb not found"

SERIAL="${1:-${DEVICE_SERIAL:-}}"

if [[ -z "${SERIAL}" ]]; then

    SERIAL="$(select_single_pyhsical_device 2>/dev/null || true)"

fi

if [[ -z "${SERIAL}" ]]; then

    die "No physical Android device serial available"

fi

echo "=========================================="
echo " ADB Connection State"
echo "=========================================="
echo

echo "[INFO] Serial: ${SERIAL}"

state="$(adb_device_state "${SERIAL}")"

case "${state}" in 

    device)

        log_ok "ADB state: device"
        echo
        echo "Device is authorized and ready."

        ;;
    
    unauthorized)

        log_warn "ADB state: unauthorized"
        echo
        echo "The device is connected but this workstation"
        echo "has not been authorized."
        echo
        echo "Unlock the Android device and accept the"
        echo "USB debbing RSA prompt"
        echo

        exit 2
    
        ;;
    
    offline)

        log_warn "ADB state: offline"
        echo
        echo "The device transport exists, but ADB"
        echo "cannot currently communicate with it."
        echo
        echo "Try:"
        echo
        echo " make adb-recover SERIAL=${SERIAL}"
        echo

        exit 3

        ;;
    
    "")

        log_error "ADB device not found: ${SERIAL}"
        echo
        echo "Run USB diagnostics first:"
        echo
        echo " make usb-diagnostics"
        echo

        exit 4

        ;;
    
    *)

        die "Unexpected ADB state: ${state}"

        ;;
    
esac