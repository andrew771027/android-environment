#!/usr/bin/env bash

set -u


echo "================================"
echo " Android Environment Doctor"
echo "================================"

TOOLS=(
    java
    sdkmanager
    avdmanager
    adb
    fastboot
    emulator
)


for tool in "${TOOLS[@]}"; do

    printf "%-15s" "${tool}"

    if command -v "${tool}" >/dev/null 2>&1; then
        echo "OK"
    else
        echo "MISSING"
    fi
done

echo
echo "ANDROID_HOME=${ANDROID_HOME:-NOT_SET}"

echo
echo "AVDs:"

emulator -list-avds 2>/dev/null || true

echo "Devices:"
adb devices 2>/dev/null || true
