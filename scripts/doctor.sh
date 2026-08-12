#!/usr/bin/env bash

set -u

PASS=0
FAIL=0


check_command() {

    local command_name="$1"

    printf "%-15s" "${command_name}"

    if command -v "${command_name}" >/dev/null 2>&1; then
        echo "OK"
        PASS=$((PASS + 1))
    else
        echo "MISSING"
        FAIL=$((FAIL + 1))
    fi
}


echo "================================"
echo " Android Environment Doctor"
echo "================================"

echo

check_command java
check_command sdkmanager
check_command avdmanager
check_command adb
check_command fastboot
check_command emulator

echo
echo "ANDROID_HOME=${ANDROID_HOME:-NOT_SET}"

echo
echo "Connected devices:"
adb devices 2>/dev/null || true

echo
echo "Available AVDs:"
emulator -list-avds 2>/dev/null || true

echo
echo "--------------------------------"
echo "PASS=${PASS}"
echo "FAIL=${FAIL}"

if [[ "${FAIL}" -gt 0 ]]; then
    exit 1
fi
