#!/usr/bin/env bash

set -u

log_info(){
    echo "[INFO] $*"
}

log_ok(){
    echo "[ OK ] $*"
}

log_warn(){
    echo "[WARN] $*"
}

log_error(){
    echo "[ERROR] $*" >&2
}

command_exists(){
    command -v "$1" >/dev/null 2>&1
}

die(){
    log_error "$*"
    exit 1
}

package_is_installed(){

    local package="$1"

    sdkmanager --list_installed \
        | awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}' \
        | grep -Fxq "${package}"
}

install_package(){

    local package="$1"

    if package_is_installed "${package}"; then

        log_ok "${package} already installed"

        return 0
    fi

    log_info "Installed ${package}"

    sdkmanager "${package}"

    if package_is_installed "${package}"; then

        log_ok "${package} installed"

        return 0
    fi

    die "Failed to install ${package}"
}
