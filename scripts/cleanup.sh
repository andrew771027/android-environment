#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"

echo "Deleting AVD: $(AVD_NAME)"

avdmanager delete avd \
    --nmae "${AVD_NAME}"

echo "Done."