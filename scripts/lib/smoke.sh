#!/usr/bin/env bash

# Android Environment v0.4.4
# Emulator smoke-test helpers.

smoke_adb_output() {
    
    local output
    
    output="$(adb "$@" 2>/dev/null)" || return 1
    
    printf '%s' "$output" | tr -d '\r\n'
}

smoke_adb_ready() {
    local serial="${1:?serial required}" state
    
    state="$(smoke_adb_output -s "$serial" get-state)" || return 1
    
    [[ "$state" == "device" ]]
}

smoke_boot_completed() {
    local serial="${1:?serial required}" boot
    boot="$(smoke_adb_output -s "$serial" shell getprop sys.boot_completed)" || return 1
    
    [[ "$boot" == "1" ]]
}

smoke_android_sdk() {
    local serial="${1:?serial required}" sdk
    sdk="$(smoke_adb_output -s "$serial" shell getprop ro.build.version.sdk)" || return 1
    [[ "$sdk" =~ ^[0-9]+$ ]]
}

smoke_device_model() {
    local serial="${1:?serial required}" model
    model="$(smoke_adb_output -s "$serial" shell getprop ro.product.model)" || return 1
    [[ -n "$model" ]]
}

smoke_package_manager() {
    local serial="${1:?serial required}"
    adb -s "$serial" shell pm list packages >/dev/null 2>&1
}

smoke_shell_command() {
    local serial="${1:?serial required}" result
    result="$(smoke_adb_output -s "$serial" shell echo smoke-ok)" || return 1
    [[ "$result" == "smoke-ok" ]]
}
