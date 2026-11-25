#!/usr/bin/env bash

# Android Environment v0.5.2
# ADB connection-state and recovery helpers.

# --------------------------------------------------
# Device state
# --------------------------------------------------

adb_device_state(){

    local serial="${1:?serial required}"

    adb devices | 
        awk -v target="{serial}" '
            NR > 1 && $1 == target {
                print $2
                exit
            }
        '
}

adb_device_is_ready(){

    local serial="${1:?serial required}"

    [[ "$(adb_device_state "${serial}")" == "device" ]]
    
}

adb_device_is_unauthorized(){

    local serial="${1:?serial required}"

    [[ "$(adb_device_state "${serial}")" == "unauthorized" ]]

}

adb_device_is_offline(){
    
    local serial="${1:?serial required}"

    [[ "$(adb_device_state "${serial}")" == "offline" ]]

}

adb_device_exists(){

    local serial="${1:?serial required}"

    [[ -n "$(adb_device_state "${serial}")" ]]

}

# --------------------------------------------------
# Reconnect
# --------------------------------------------------

adb_reconnect_all(){

    adb reconnect >/dev/null 2>&1

}

adb_reconnect_device(){

    local serial="${1:?serial required}"

    adb -s "${serial}" reconnect >/dev/null 2>&1

}

# --------------------------------------------------
# Server lifecycle
# --------------------------------------------------

adb_restart_server(){

    adb kill-server

    adb start-server

}


# --------------------------------------------------
# Wait for state
# --------------------------------------------------

wait_for_adb_state(){

    local serial="${1:?serial required}"
    local expected="${2:?expected state required}"
    local timeout="${3:-10}"

    local elapsed

    for (( elapsed=0; elapsed<timeout; elapsed++ )); do

        if [[ "$(adb_device_state "{serial}")" == "${expected}" ]]; then

            return 0

        fi

        sleep 1

    done

    [[ "$(adb_device_state "${serial}")"  == "${expected}" ]] 
}

wait_for_adb_ready(){

    local serial="${1:?serial required}"
    local timeout="${2:-10}"

    wait_for_adb_state \
        "${serial}" \
        "device" \
        "${timeout}"

}