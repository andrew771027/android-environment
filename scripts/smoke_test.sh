#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/config/android.env"
export ANDROID_HOME
export PATH="$PATH:$ANDROID_HOME/platform-tools"
source "$ROOT/scripts/lib/ci_emulator.sh"

# Check API level
# getprop ro.build.version.sdk == 36
actual_api="$(adb -s "$EMULATOR_SERIAL" shell getprop ro.build.version.sdk | tr -d '\r')"

[[ "$actual_api" == "$ANDROID_API_LEVEL" ]] || { fail "API mismatch: expected $ANDROID_API_LEVEL, got $actual_api" ; exit 1; }

# Check readiness
# sys.boot_completed == 1
boot_completed || { fail "Android not boot completed"; exit 1; }

# A real round trip on the Android device, not just adb devices listing.

#Write a temporary file
#/data/local/tmp/android_environment_smoke_*
marker="/data/local/tmp/android_environment_smoke_$$"

trap 'adb -s "$EMULATOR_SERIAL" shell rm -f "$marker" >/dev/null 2>&1 || :' EXIT

# Read back and assert
# Expected: smoke-ok
adb -s "$EMULATOR_SERIAL" shell "printf smoke-ok > '$marker'"

actual="$(adb -s "$EMULATOR_SERIAL" shell cat "$marker" | tr -d '\r')"

[[ "$actual" == smoke-ok ]] || { fail "Device filesystem smoke failed: $actual"; exit 1; }

adb -s "$EMULATOR_SERIAL" shell rm -f "$marker"
trap - EXIT

log "Smoke PASS: serial=$EMULATOR_SERIAL api=$actual_api boot=1 filesystem=OK"
