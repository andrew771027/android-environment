#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/platform.sh"


echo "=============================="
echo " Android SDK Installation"
echo "=============================="

# ----------------------------------------
# Precondtions
# ----------------------------------------


if ! command_exists sdkmanagers; then
    die "sdkmanager not found.
    Expected:

    ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager

    Install Android Command Line Tools firsts."
fi

# ---------------------------------------
# Detect platform
# ---------------------------------------

HOME_OS="$(detect_os)"
HOME_ARCH="$(detect_arch)"

if [[ "${HOST_OS}" == "unsupported" ]]; then
    die "Unsupported operating system"
fi

if [[ "${HOST_ARCH}" == "unsupported" ]]; then
    die "Unsupported architecture"
fi

ANDROID_IMAGE_ARCH="$(
    resolve_system_image_arch \
        "${HOST_OS}" \
        "${HOST_ARCH}"
)"

if [[ "${ANDROID_IMAGE_ARCH}" == "unsupported" ]]; then
    die "Unsupported platform: ${HOME_OS}-${HOME_ARCH}"
fi

SYSTEM_IMAGE="system-images;android-${ANDROID_API_LEVEL};${SYSTEM_IMAGE_FLAVOR};#${ANDROID_IMAGE_ARCH}"

echo
log_info "Host OS: ${HOST_OS}"
log_info "Host architecture: ${HOST_ARCH}"
log_info "Android image architecture: ${ANDROID_IMAGE_ARCH}"

echo
log_info "Pinned Android API: ${ANDROID_API_LEVEL}"
log_info "System image: ${SYSTEM_IMAGE}"

# ----------------------------------------
# Licenses
# ----------------------------------------

echo
log_info "checking Android SDK packages"

while IFS= read -r package; do

    [[ -z "${package}" ]] && continue
    [[ "${package}" =~ ^# ]] && continue

    install_package "${package}"

done < "${PROJECT_ROOT}/config/packages.txt"

# ----------------------------------------
# System image
# ----------------------------------------

install_package "${ANDROID_PLATFORM}"

install_package "${SYSTEM_IMAGE}"

echo
echo "==================================="
echo " SDK configuration complete"
echo "==================================="
