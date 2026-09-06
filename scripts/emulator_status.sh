#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/emulator.sh"

echo "================================"
echo " Android Emulator Status "
echo "================================"

serial="$(get_emulator_serial)"

if [[ -z "${serial}" ]]; then

    echo
    echo "State: STOPPED"
    echo "AVD: ${AVD_NAME}"

    exit 0
fi

if is_emulator_boot_complete; then

    echo
    echo "State: READY"
    echo "Serial: ${serial}"

else

    echo
    echo "State: BOOTING"
    echo "Serial: ${serial}"

fi
