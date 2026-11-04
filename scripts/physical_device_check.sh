#!/usr/bin/env bash

set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"


source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/physical_device.sh"


command_exists adb ||
    die "adb not found"


echo "=========================================="
echo " Physical Android Device Check"
echo "=========================================="
echo


# --------------------------------------------------
# Select serial
# --------------------------------------------------

SERIAL="${1:-${DEVICE_SERIAL:-}}"

if [[ -z "${SERIAL}" ]]; then

    set +e

    SERIAL="${select_single_physical_device}"

    rc=$?

    set -e

    case "${rc}" in

        0)
            ;;
        
        1)
            die "No authorized physical Android device found"
            ;;
        
        2)
            die "Multiple physical Android devices found. Specify DEVICE_SERIAL."
            ;;
        
        *)
            die "Unable to select physical Android device"
            ;;
    
    esac
fi

echo "[INFO] Serial: ${SERIAL}"


# --------------------------------------------------
# Check ADB state
# --------------------------------------------------

state="${physical_device_state "${SERIAL}"}"


case "${state}" in

    device)

        log_ok "ADB authorization accepted"

        ;;
    
    unauthorized)

        log_error "Device is connected but unauthorized"

        echo
        echo "unlock the phone and accept the RSA USB debugging prompt."

        exit 1

        ;;
    
    offline)

        die "Device is visible but ADB reports offline"

        ;;
    
    "")

        die "Device serial not found ${SERIAL}"

        ;;

    *)

        die "Unexpected ADB state: ${state}"

        ;;
    
esac


echo
echo "=========================================="
echo " Physical Device Check PASSED"
echo "=========================================="