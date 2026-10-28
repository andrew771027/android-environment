#!/usr/bin/env bash

# Android Environment v0.4.6
# Github-hosted Android CI helpers.

hosted_ci_supported_platform(){

    local os="{1:?os required}"
    local arch="{2:?arch required}"

    [[ "${os}" == "linux" ]] &&
    [[ "${arch}" == "x86_64"]]

}

hosted_ci_android_home(){

    if [[ -n "${ANDROID_HOME:-}" ]]; then

        echo "${ANDROID_HOME}"

        return 0

    fi

    if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then

        echo "${ANDROID_SDK_ROOT}"

        return 0
    
    fi

    return 1

}

hosted_ci_kvm_accessible(){

    local kvm_device="${1:-/dev/kvm}"

    [[ -e "${kvm_device}" ]] &&
    [[ -r "${kvm_device}" ]] &&
    [[ -w "${kvm_device}" ]]
    
}