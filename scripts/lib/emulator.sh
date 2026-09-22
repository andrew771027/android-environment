#!/usr/bin/env/bash

set -u

# -----------------------------------------
# Find emulator serial
# -----------------------------------------

get_emulator_serial(){

    #awk regex: ^emulator- : emulator serial starts with "emulator-" and $2 == "device" : device is connected and ready
    adb devices | awk '$1 ~ /^emulator-/ && $2 == "device" {print $1; exit}'

}

# -----------------------------------------
# Is emulator visible through adb?
# -----------------------------------------

is_emulator_connected(){

    local serial

    serial="$(get_emulator_serial)"

    # serial is non-empty if emulator is connected
    [[ -n "${serial}" ]]

}

# -----------------------------------------
# Is Android boot complete?
# -----------------------------------------

is_emulator_boot_completed(){

    local serial

    serial="$(get_emulator_serial)"

    # serial is empty if emulator is not connected
    if [[ -z "${serial}" ]]; then

        return 1

    fi

    local boot_completed

    boot_completed="$(

        adb -s "${serial}" \
            shell getprop sys.boot_completed \
            2>/dev/null \
            | tr -d '\r'
    )"

        [[ "${boot_completed}" == "1" ]]
}

# -----------------------------------------
# Wait until boot completed
# -----------------------------------------

wait_for_emulator_boot(){

    local timeout_seconds="$1"
    local poll_interval_seconds="$2"

    local elapsed=0

    log_info "Waiting for emulator to become available..."

    while ((elapsed < timeout_seconds)); do

        if is_emulator_boot_completed; then

            local serial

            serial="$(get_emulator_serial)"

            log_ok "Emulator boot completed. Serial: ${serial}"

            return 0
        fi

        sleep "${poll_interval_seconds}"

        elapsed=$((elapsed + poll_interval_seconds))

        log_info "Waiting... ${elapsed}/${timeout_seconds}s"

    done

    return 1
}
