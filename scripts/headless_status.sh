#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/headless.sh"

# --------------------------------------------------
# Check status
# --------------------------------------------------

if ! devices="$(adb devices)"; then

    echo "ERROR: Unable to query ADB devices." >&2
    exit 1

fi

if ! awk -v target="$EMULATOR_SERIAL" \
    '$1 == target {found=1} END {exit !found}' <<< "$devices"; then

    echo "STOPPED"

elif ! boot_ready; then

    echo "BOOTING or OFFLINE: $EMULATOR_SERIAL"

else

    actual="$(avd_name_for_serial)"

    if [[ "$actual" == "$AVD_NAME" ]]; then

        echo "READY: $AVD_NAME ($EMULATOR_SERIAL)"

    else

        echo "UNKNOWN AVD: $actual ($EMULATOR_SERIAL)"

        exit 1

    fi

fi
