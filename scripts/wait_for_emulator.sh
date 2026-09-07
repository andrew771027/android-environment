#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/emulator.sh"

echo "================================"
echo " Wait For Android Emulator "
echo "================================"

if ! command_exists adb; then
    die "adb command not found."
fi

if wait_for_emulator_boot \
    "${EMULATOR_BOOT_TIMEOUT_SECONDS}"\
    "${EMULATOR_BOOT_POLL_INTERVAL_SECONDS}"
then

    serial="$(get_emulator_serial)"

    log_ok "Emulator ready: ${serial}"

else

    die "Emulator did not become ready within ${EMULATOR_BOOT_TIMEOUT_SECONDS} seconds."

fi
