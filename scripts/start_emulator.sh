#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

if ! command_exists emulator; then
    die "Android Emulator not installed."
fi

if ! emulator -list-avds | grep -Fxq "${AVD_NAME}"; then

    die "AVD does not exists:

${AVD_NAME}

Run:

make create-avd"
fi

log_info "Stanting Android Emulator"

echo
echo "AVD: ${AVD_NAME}"

echo

exec emulator \
     -avd "${AVD_NAME}" \
     -no-snapshot-load
