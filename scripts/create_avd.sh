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

SYSTEM_IMAGE="system-images;android-${ANDROID_API_LEVEL};${SYSTEM_IMAGE_FLAVOR};#${ANDROID_IMAGE_ARCH}"


echo "======================================"
echo " Create Android AVD "
echo "======================================"

echo
echo "name:   ${AVD_NAME}"
echo "device: ${AVD_DEVICE}"
echo "image:  ${SYSTEM_IMAGE}"

# ------------------------------------------
# Validate system image
# ------------------------------------------

if ! package_is_installed "${SYSTEM_IMAGE}"; then

    die "System image not installed:

${SYSTEM_IMAGE}

Run:

make install-sdk"
fi

# -------------------------------------------
# Idempotent AVD creation
# -------------------------------------------

if emulator -list-avds | grep -Fxq "${AVD_NAME}"; then

    log_ok "AVD already exists: ${AVD_NAME}"

    exit 0
fi

echo

log_info "Create AVD: ${AVD_NAME}"

echo "no" | avdmanager create avd \
    --name "${AVD_NAME}" \
    --package "${SYSTEM_IMAGE}" \
    --device "${AVD_DEVICE}"

# -------------------------------------------
# Validate
# -------------------------------------------


if emulator -list-avds | grep -Fxq "${AVD_NAME}"; then

    log_ok "AVD created: ${AVD_NAME}"

else

    die "AVD creation failed ${AVD_NAME}"

fi
