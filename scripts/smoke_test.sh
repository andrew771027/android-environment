#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/headless.sh"
source "${PROJECT_ROOT}/scripts/lib/smoke.sh"

SERIAL="${EMULATOR_SERIAL}"

echo "[INFO] Running Android Emulator Smoke Test"
echo
echo "Serial:"
echo "  ${SERIAL}"
echo


# -----------------------------------------------
# 1. ADB
# -----------------------------------------------

if ! smoke_adb_ready "${SERIAL}"; then

    echo "[ERROR] ADB device is not ready" >&2

    exit 1

fi

echo "[ OK ] ADB device is ready"

# -----------------------------------------------
# 2. Android boot
# -----------------------------------------------

if ! smoke_boot_completed "${SERIAL}"; then

    echo "[ERROR] Android boot is not complete" >&2

    exit 1

fi

echo "[ OK ] Android boot completed"

# -----------------------------------------------
# 3. Android SDK
# -----------------------------------------------


if ! smoke_android_sdk "${SERIAL}"; then

    echo "[ERROR] Unable to read Android SDK version" >&2

    exit 1

fi

sdk="$(
    adb -s "${SERIAL}" \
        shell getprop ro.build.version.sdk |
        tr -d '\r\n'
)"

echo "[ OK ] Android SDK version: ${sdk}"


# -----------------------------------------------
# 4. Device model
# -----------------------------------------------

if ! smoke_device_model "${SERIAL}"; then

    echo "[ERROR] Unable to read device model" >&2

    exit 1

fi

model="$(
    adb -s "${SERIAL}" \
        shell getprop ro.product.model |
        tr -d '\r\n'
)"

echo "[ OK ] Device model: ${model}"

# --------------------------------------------------
# 5. Package Manager
# --------------------------------------------------

if ! smoke_package_manager "${SERIAL}"; then

    echo "[ERROR] Android Package Manager is unavaiable" >&2

    exit 1

fi

echo "[ OK ] Package Manager is avaiable"


# --------------------------------------------------
# 6. Shell
# --------------------------------------------------


if ! smoke_shell_command "${SERIAL}"; then

    echo "[ERROR] Basic Android shell command failed" >&2

    exit 1

fi

echo "[ OK ] Android shell is usable"

# --------------------------------------------------
# Summary
# --------------------------------------------------

echo
echo "=========================================="
echo " Android Emulator Smoke Test PASSED"
echo "=========================================="