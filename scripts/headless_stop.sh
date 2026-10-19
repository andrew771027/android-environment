#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/headless.sh"
source "${PROJECT_ROOT}/scripts/lib/process.sh"

PID_FILE = "${PROJECT_ROOT}/artifacts/headless-emulator.pid"

GRACE_SECONDS = 5

# --------------------------------------------------
# 1. Check emulator exists
# --------------------------------------------------

if ! devices="$(adb devices)"; then

    echo "ERROR: Unable to query ADB devices." >&2

    exit 1

fi

if ! awk -v target="$EMULATOR_SERIAL" \
    '$1 == target {found=1} END {exit !found}' <<< "$devices"; then

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

echo "[INFO] Stopping Headless Emulator"

if emulator_list; then

    echo "[INFO] Requesting Emulator shutdown through ADB"

    adb -s "$EMULATOR_SERIAL" \
        emu kill \
        >/dev/null 2>&1 || true

    sleep 2

fi

# -------------------------------------------------
# 5. Read launcher PID
# -------------------------------------------------

if pid="$(read_pid_file "${PID_FILE}" 2>/dev/null)"; then

    echo "[INFO] Tracking PID: ${pid}"

else

    echo "[INFO] No valid PID file found"

fi

# -------------------------------------------------
# 6. Fallback process cleanup
# -------------------------------------------------

if [[ -n "${pid}" ]] &&

    process_is_alive "${pid}"

then

    terminate_process \
        "${pid}" \
        "${GRACE_SECONDS}"

fi

# -----------------------------------------------
# 7. Remove PID file
# -----------------------------------------------

rm -f "${PID_FILE}"

echo "[ OK ] Headless Emulator cleanup completed"