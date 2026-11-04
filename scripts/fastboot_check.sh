#!/usr/bin/env bash

set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"


source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/physical_device.sh"

command_exists fastboot ||
    die "fastboot not found"


SERIAL=$"{1:-${DEVICE_SERIAL:-}}"

echo "=========================================="
echo " Fastboot Device Check"
echo "=========================================="
echo

device="$(
    list_fastboot_devices
)"

if [[ -z "${devices}" ]]; then

    die "No Fastboot device found"

fi

if [[ -n "${SERIAL}" ]]; then

    if ! fastboot_device_present "${SERIAL}"; then

        die "Expected Fastboot serial not found: ${SERIAL}"
    
    fi

    echo "[ OK ] Fastboot device found: ${SERIAL}"

else

    echo "[INFO] Fastboot devices:"
    echo

    printf '%s\n' "${devices}"

fi


echo
echo "=========================================="
echo " Fastboot Device Check PASSED"
echo "=========================================="