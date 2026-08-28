#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/platform.sh"

HOST_OS="$(detect_os)"
HOST_ARCH="$(detect_arch)"

ANDROID_IMAGE_ARCH="$(
    resolve_system_image_arch \
        "${HOST_OS}" \
        "${HOST_ARCH}"
)"

SYSTEM_IMAGE="system-images;android-${ANDROID_API_LEVEL};${SYSTEM_IMAGE_FLAVOR};${ANDROID_IMAGE_ARCH}"


echo "======================================"
echo " Create Android AVD"
echo "======================================"

echo
echo "name:   ${AVD_NAME}"
echo "device: ${AVD_DEVICE}"
echo "image:  ${SYSTEM_IMAGE}"


# ------------------------------------------
# Validate required tools
# ------------------------------------------

if ! command_exists avdmanager; then
    die "avdmanager not found."
fi

if ! command_exists emulator; then
    die "emulator not found."
fi


# ------------------------------------------
# Validate system image
# ------------------------------------------

if ! package_is_installed "${SYSTEM_IMAGE}"; then

    die "System image not installed:

${SYSTEM_IMAGE}

Run:

make install-sdk"
fi


# ------------------------------------------
# Idempotent AVD creation
# ------------------------------------------

if emulator -list-avds | grep -Fxq "${AVD_NAME}"; then

    log_ok "AVD already exists: ${AVD_NAME}"

    exit 0
fi


# ------------------------------------------
# Validate hardware profile
# ------------------------------------------

if avdmanager list device -c 2>/dev/null | grep -Fxq "${AVD_DEVICE}"; then

    log_ok "Hardware profile found: ${AVD_DEVICE}"

else

    die "Hardware profile not found: ${AVD_DEVICE}"

fi


# ------------------------------------------
# Create AVD
# ------------------------------------------

echo
log_info "Creating AVD: ${AVD_NAME}"

echo "no" | avdmanager create avd \
    -n "${AVD_NAME}" \
    -k "${SYSTEM_IMAGE}" \
    -d "${AVD_DEVICE}"


# ------------------------------------------
# Validate result
# ------------------------------------------

if emulator -list-avds | grep -Fxq "${AVD_NAME}"; then

    log_ok "AVD created: ${AVD_NAME}"

else

    die "AVD creation failed: ${AVD_NAME}"

fi
