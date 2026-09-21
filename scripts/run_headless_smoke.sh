#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/config/android.env"

export ANDROID_HOME

export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

source "$ROOT/scripts/lib/ci_emulator.sh"

for name in emulator adb; do

    command -v "$name" >/dev/null || { fail "Missing $name; run make install-sdk"; exit 1; }

done

for number in "$EMULATOR_BOOT_TIMEOUT_SECONDS" "$EMULATOR_STOP_TIMEOUT_SECONDS" "$EMULATOR_POLL_INTERVAL_SECONDS"; do

    validate_positive_integer "$number" || { fail "Invalid positive timeout/interval: $number"; exit 1; }

done

[[ "$EMULATOR_PORT" == 5554 && "$EMULATOR_SERIAL" == emulator-5554 ]] || { fail "v0.4 CI requires reserved port 5554 and emulator-5554"; exit 1; }

check_linux_kvm

emulator -list-avds | grep -Fxq "$AVD_NAME" || { fail "AVD missing: $AVD_NAME"; exit 1; }

check_isolated_adb

mkdir -p "$ROOT/artifacts"

log "Starting headless emulator on port 5554"

# -avd 指定 AVD
# -port 5554 固定 Emulator console port
# -no-window 不顯示 GUI
# -no-audio 不初始化音效
# -no-boot-anim 跳過 Android 開機動畫
# -no-snapshot 不載入或儲存 snapshot
# -gpu swiftshader_indirect 使用軟體 GPU rendering

emulator -avd "$AVD_NAME" -port "$EMULATOR_PORT" \
    -no-window -no-audio -no-boot-anim -no-snapshot -gpu swiftshader_indirect \
    >"$ROOT/artifacts/emulator.log" \
    2>&1 &

# $! 是最近啟動的背景 job 的 PID。
emulator_pid=$!

cleanup() {
    local original_status=$?

    trap - EXIT INT TERM

    log "Cleaning up owned emulator pid=$emulator_pid"

    stop_owned_emulator "$emulator_pid"

    exit "$original_status"
}

# Delete temporary file
# Cleanup

trap cleanup EXIT

trap "exit 130" INT

trap "exit 143" TERM

wait_for_boot "$emulator_pid"

"$ROOT/scripts/smoke_test.sh"
