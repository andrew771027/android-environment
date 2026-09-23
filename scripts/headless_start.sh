#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/headless.sh"

# --------------------------------------------------
# 1. Check required tools
# --------------------------------------------------

command -v adb >/dev/null || {
    echo "ERROR: adb not found" >&2
    exit 1
}

command -v emulator >/dev/null || {
    echo "ERROR: emulator not found. Run make install-sdk" >&2
    exit 1
}

# --------------------------------------------------
# 2. Check Linux / KVM
# --------------------------------------------------

"$PROJECT_ROOT/scripts/check_kvm.sh" || exit 1

# --------------------------------------------------
# 3. Check AVD exists
# --------------------------------------------------

emulator -list-avds | grep -Fxq "$AVD_NAME" || {
    echo "ERROR: AVD missing: $AVD_NAME" >&2
    exit 1
}

# --------------------------------------------------
# 4. Prevent duplicate emulator
# --------------------------------------------------

if adb devices |

    awk '$1 ~ /^emulator-/ {found=1} END {exit !found}'

then

    echo "ERROR: An emulator already exists." >&2
    echo "Stop it before starting this isolated instance." >&2

    exit 1

fi

# --------------------------------------------------
# 5. Prepare log directory
# --------------------------------------------------

mkdir -p "$PROJECT_ROOT/artifacts"

log="$PROJECT_ROOT/artifacts/headless-emulator.log"

echo "Starting $AVD_NAME (headless)"
echo "Log: $log"

# --------------------------------------------------
# 6. Start emulator in background
# --------------------------------------------------

#代表背景啟動 Emulator
# 代表將 stdout、stderr 寫進 log，並讓 stdin 來自 /dev/null
nohup emulator \
    -avd "$AVD_NAME" \
    -port 5554 \
    -no-window \
    -no-audio \
    -no-boot-anim \
    -no-snapshot \
    -gpu software \
    >"$log" 2>&1 </dev/null & 
    
#取得剛剛啟動的背景程序 PID
pid=$!

echo "Launcher PID: $pid"

# --------------------------------------------------
# 7. Wait for boot
# --------------------------------------------------

if wait_for_boot "${EMULATOR_BOOT_TIMEOUT_SECONDS:-180}"; then

    actual="$(avd_name_for_serial)"

    if [[ "$actual" == "$AVD_NAME" ]]; then

        echo "READY: $AVD_NAME ($EMULATOR_SERIAL)"

        exit 0

    fi

    echo "ERROR: unexpected AVD name: $actual" >&2

else

    echo "ERROR: boot timeout." >&2

    echo "Inspect $log" >&2

fi

exit 1
