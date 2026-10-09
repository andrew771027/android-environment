#!/usr/bin/env bash

# Android Environment v0.4.3
# Android Build Tools capability helpers.

build_tools_package_name() {

    local version="${1:?build tools version required}"

    echo "build-tools;${version}"
}

build_tools_directory() {

    local android_home="${1:?ANDROID_HOME required}"
    local version="${2:?build tools version required}"

    echo "${android_home}/build-tools/${version}"
}

build_tools_installed() {

    local android_home="${1:?ANDROID_HOME required}"
    local version="${2:?build tools version required}"

    local directory
    
    directory="$(build_tools_directory \
        "${android_home}" \
        "${version}"
        )"

    [[ -d "${directory}" ]]

}

build_tools_has_required_binaries() {


    local android_home="${1:?ANDROID_HOME required}"
    local version="${2:?build tools version required}"

    local directory

    directory="$(build_tools_directory \
        "${android_home}" \
        "${version}"
        )"

    [[ -x "${directory}/aapt2" ]] &&
    [[ -x "${directory}/apksigner" ]] &&
    [[ -x "${directory}/zipalign" ]]
    
}