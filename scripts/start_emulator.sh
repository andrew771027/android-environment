#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/emulator.sh"

echo "================================"
echo " Start Android Emulator "
echo "================================"

# -----------------------------------------
# Validate tools
# -----------------------------------------

if ! command_exists emulator; then
    die "Android Emulator not installed."
fi

if ! command_exists adb; then
    die "adn command not found."
fi

# -----------------------------------------
# Valdate AVD
# -----------------------------------------

if ! emulator -list-avds | grep -Fxq "${AVD_NAME}"; then

    die "AVD does not exists:

${AVD_NAME}

Run:

make create-avd"
fi

# -----------------------------------------
# Idempotent start
# -----------------------------------------

if is_emulator_boot_completed; then

    serial="$(get_emulator_serial)"

    log_ok "Emulator already ready: ${serial}"

    exit 0
fi

if is_emulator_connected; then

    log_info "Emulator is already running, but still booting."

else

    log_info "Starting emulator ${AVD_NAME}"

    EMULATOR_ARGS=(
        -avd "${AVD_NAME}"
    )

    if [[ "${EMULATOR_NO_SNAPSHOT_LOAD}" == "true" ]]; then
        EMULATOR_ARGS+=(
            -no-snapshot-load
        )
    fi

    if [[ "${EMULATOR_NO_BOOT_ANIMATION}" == "true" ]]; then
        EMULATOR_ARGS+=(
            -no-boot-anim
        )
    fi

    # & 代表 Emulator 在背景執行，並將輸出導向 emulator.log
    emulator "${EMULATOR_ARGS[@]}" \
        >"${PROJECT_ROOT}/emulator.log" \
        2>&1 &

fi

# -----------------------------------------
# Wait
# -----------------------------------------

if wait_for_emulator_boot\
    "${EMULATOR_BOOT_TIMEOUT_SECONDS}" \
    "${EMULATOR_BOOT_POLL_INTERVAL_SECONDS}"
then

    serial="$(get_emulator_serial)"

    echo
    log_ok "Android Emulator ready"

    echo
    echo "AVD:      ${AVD_NAME}"
    echo "Serial:   ${serial}"

else

    die "Emulator boot timeout after ${EMULATOR_BOOT_TIMEOUT_SECONDS} seconds."

fi
