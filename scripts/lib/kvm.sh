#!/usr/bin/env bash

set -u

kvm_device_exists(){

    local device_path="$1"

    [[ -e "${device_path}" ]]

}

kvm_device_accessible(){

    local device_path="$1"

    [[ -r "${device_path}" && -w "${device_path}" ]]
}

emulator_acceleration_available(){

    emulator -accel-check >/dev/null 2>&1

}
