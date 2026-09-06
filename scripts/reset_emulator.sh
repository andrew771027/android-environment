#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/emulator.sh"

echo "================================"
echo " Stop existing emulator "
echo "================================"

serial="$(get_emulator_serial)"

if [[ -n "${serial}" ]]; then

    log_info "Stopping existing emulator"

    adb -s "${serial}" emu kill

    while is_emulator_connected; do

        log_info "Waiting for emulator to stop..."

        sleep 1

    done

fi

# -----------------------------------------
# Start with wipe-data
# -----------------------------------------

log_info "Starting emulator with clean user data"

emulator \
    -avd "${AVD_NAME}" \
    -wipe-data \
    -no-snapshot-load \
    -no-boot-anim \
    >"${PROJECT_ROOT}/emulator.log" \
    2>&1 &


# -----------------------------------------
# Wait
# -----------------------------------------

if wait_for_emulator_boot \
    "${EMULATOR_BOOT_TIMEOUT_SECONDS}" \
    "${EMULATOR_BOOT_POLL_INTERVAL_SECONDS}"
then

    serial="$(get_emulator_serial)"

    log_ok "Emulator reset completed: ${serial}"

else

    die "Emulator reset timed out after ${EMULATOR_BOOT_TIMEOUT_SECONDS} seconds."

fi
