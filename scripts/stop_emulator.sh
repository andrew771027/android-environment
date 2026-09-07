#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/emulator.sh"

echo "================================"
echo " Stop Android Emulator "
echo "================================"

serial=$(get_emulator_serial)

if [[ -z "${serial}" ]]; then

    log_ok "Emulator already stopped."

    exit 0
fi

log_info "Stopping emulator: ${serial}"

adb -s "${serial}" emu kill

# ------------------------------------------
# Wait until disconnected
# ------------------------------------------

timeout_seconds=30
elapsed=0

while (( elapsed < timeout_seconds )); do

    if ! is_emulator_connected; then

        log_ok "Emulator stopped."

        exit 0

    fi

    sleep 1

    elapsed=$((elapsed + 1))

done

die "Emulator did not stop within ${timeout_seconds} seconds."
