#!/usr/bin/env bash

# Android Environment v0.4.4
# Emulator smoke-test helpers.

smoke_adb_ready(){

    local serial="${1:?serial required}"

    [[ 
        "$(
        adb -s "${serial}" \
            get-state \
            2>/dev/null |
            tr -d '\r\n'
        )" == "device" 
    ]]

}

smoke_boot_completed(){

    local serial="${1:?serial required}"

    [[  
        "$(
        adb -s "${serial}" \
            shell getprop sys.boot_completed \
            2>/dev/null |
            tr -d '\r\n'
        )" == "1"
    ]]

}

smoke_android_sdk(){

    local serial="${1:?serial required}"

    local sdk

    sdk="$(
        adb -s "${serial}" \
            shell getprop ro.build.version.sdk \
            2>/dev/null |
            tr -d '\r\n'
    )"

    [[ "${sdk}" =~ ^[0-9]+$ ]]

}

smoke_device_model(){

    local serial="${1:?serial required}"

    local model

    model="$(
        adb -s "${serial}" \
            shell getprop ro.product.model \
            2>/dev/null |
            tr -d '\r\n'
        )"

    [[ -n "${model}" ]]

}

smoke_package_manager(){

    local serial="${1:?serial required}"

    adb -s "${serial}" \
        shell pm list packages \
        >/dev/null 2>&1

}

smoke_shell_command(){

    local serial="${1:?serial required}"

    local result

    result="$(
        adb -s "${serial}" \
            shell echo smoke-ok \
            2>/dev/null |
            tr -d '\r\n'
    )"

    [[ "${result}" == "smoke-ok" ]]

}