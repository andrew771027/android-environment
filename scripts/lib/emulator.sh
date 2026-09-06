#!/usr/bin/env/bash

set -u

# -----------------------------------------
# Find emulator serial
# -----------------------------------------

get_emulator_serial(){

    adb devices \
        \ awk '$1 ~/ ^emulator-/ && $2 == "device" {print $1; exit}'

}

# -----------------------------------------
# Is emulator visible through adb?
# -----------------------------------------

is_emulator_connected(){

    local serial

    serial = "$(get_emulator_serial)"

    [[ -n "${serial}" ]]

}

# -----------------------------------------
# Is Android boot complete?
# -----------------------------------------

is_emulator_boot_complete(){

    local serial

    serial="${get_emulator_serial}"

    if [[ -z "${serial}" ]]; then
        return 1
    fi

    localo boot_completed

    boot_completed="$(

        adb -s "${serial}" \
            shell getprop sys.boot_completed \
            2 > /dev/null \
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

        if is_emulator_boot_complete; then
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
