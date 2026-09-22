#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/config/android.env"
source "$ROOT/scripts/lib/headless.sh"

# --------------------------------------------------
# 1. Check emulator exists
# --------------------------------------------------

if ! emulator_listed; then

    echo "Already stopped."

    exit 0

fi

# --------------------------------------------------
# 2. Check emulator ready
# --------------------------------------------------

if ! boot_ready; then

    echo "ERROR: Emulator not ADB-ready." >&2
    echo "Inspect logs; do not kill an unidentified process." >&2

    exit 1

fi

# --------------------------------------------------
# 3. Validate AVD identity
# --------------------------------------------------

actual="$(avd_name_for_serial)"

if [[ "$actual" != "$AVD_NAME" ]]; then

    echo "ERROR: Refusing to stop other AVD: $actual" >&2

    exit 1

fi

# --------------------------------------------------
# 4. Stop emulator
# --------------------------------------------------

adb -s "$EMULATOR_SERIAL" emu kill

echo "Stop requested for $AVD_NAME."
