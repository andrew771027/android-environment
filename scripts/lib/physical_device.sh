#!/usr/bin/env bash

# Android Environment v0.5
# Physical Android Device Helpers.

# ---------------------------------------
# ADB device discovery
# ---------------------------------------

list_physical_adb_devices(){

    adb devicess | 
        awk '
            NR > 1 &&
            NF >= 2 &&
            $1 !~ /^emulator-/ {
                print $1, $2
            }
        '
}

physical_device_state(){

    local serial="${1:?serial required}"

    adb devices |
        awk -v target="${serial}" '
            NR > 1 &&
            $1 == target {
                print $2
                exit
            }
        '
}

physical_device_is_authorized(){
    
    local serial="${1:?serial required}"

    [[ "$(physical_device_state "${serial}")" == "device" ]]

}

# --------------------------------------------------
# Device selection
# --------------------------------------------------

select_single_physical_device(){

    local devices
    local count

    devices="$(
        list_physical_adb_devices | 
            awk '$2 == "device" {print $1}'
    )"

    count="$(
        print '%s\n' "${devices}" |
            awk 'NF {count++} END {print count+0}'
    )"

    if [[ "${count}" -eq 0 ]]; then

        return 1
    
    fi

    if [[ "${count}" -gt 1 ]]; then

        return 2
    
    fi

    printf '%s\n' "${devices}"

}

# --------------------------------------------------
# Device facts
# --------------------------------------------------

adb_getprop() {

    local serial="${1:?serial required}"
    local property="${2:?property required}"

    adb -s "${serial}" \
        shell getprop "${property}" \
        2>/dev/null |
        tr -d '\r\n'

}

device_manufacturer(){

    adb_getprop "$1" "ro.product.manufacturer"

}

device_model(){

    adb_getprop "$1" "ro.product.model"

}

device_product(){

    adb_getprop "$1" "ro.product.name"

}

device_codename(){

    adb_getprop "$1" "ro.product.device"

}

device_android_version(){

    adb_getprop "$1" "ro.build.version.release"

}

device_sdk_level(){

    adb_getprop "$1" "ro.build.version.sdk"

}

device_build_fingerprint(){

    adb_getprop "$1" "ro.build.fingerprint"

}

# --------------------------------------------------
# Fastboot
# --------------------------------------------------

list_fastboot_devices(){

    fastboot devices |
        awk 'NF >= 1 {print $1}'

}


fastboot_device_present(){

    local serial="${1:?serial required}"

    fastboot devices |
        awk -v target="${serial}" '
            $1 == target {
                found=1
            }

            END {
                exit !found
            }
        '

}