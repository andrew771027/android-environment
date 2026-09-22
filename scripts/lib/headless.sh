#!/usr/bin/env bash
# Source this library after loading config/android.env
# Single emulator only.

EMULATOR_SERIAL="emulator-5554"

# --------------------------------------------------
# 1. Check emulator exists in ADB
# --------------------------------------------------

emulator_listed() {

    adb devices | awk -v target="$EMULATOR_SERIAL" \
    '$1 == target {found=1} END {exit !found}'

}

# --------------------------------------------------
# 2. Check boot completed
# --------------------------------------------------

boot_ready() {

    # ADB state must be "device".
    [[ "$(adb -s "$EMULATOR_SERIAL" get-state \
       2>/dev/null)" == "device" ]] || return 1

    # Android boot property must be 1.
    [[ "$(adb -s "$EMULATOR_SERIAL" \
        shell getprop sys.boot_completed \
        2>/dev/null | tr -d '\r')" == "1" ]]

}

# --------------------------------------------------
# 3. Wait for Android boot
# --------------------------------------------------

wait_for_boot(){
    local timeout="${1:?timeout required}"
    local elapsed

    for ((elapsed=0; elapsed<timeout; elapsed++)); do

        if boot_ready; then

            return 0

        fi

        sleep 1

    done

    # Check once more at the deadline.
    boot_ready

}

# --------------------------------------------------
# 4. Get AVD name
# --------------------------------------------------

# Only use after ADB reports this serial as a device.
avd_name_for_serial() {

    adb -s "$EMULATOR_SERIAL" \
        emu avd name \
        2>/dev/null |
        head -n 1 |
        tr -d '\r'

}
