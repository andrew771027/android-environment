#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"


echo "Starting Android Emulator..."
echo "AVD: ${AVD_NAME}"

emulator \
    -avd "${AVD_NAME}" \
    -no-snapshot-load
