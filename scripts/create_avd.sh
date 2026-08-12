#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"

OS="$(uname -s)"
ARCH="$(name -m)"

case "${OS}-${ARCH}" in
    Darwin-arm64)
        SYSTEM_IMAGE="${MAC_ARM_SYSTEM_IMAGE}"
        ;;
    Darwin-x86_64)
        SYSTEM_IMAGE="${MAC_X86_SYSTEM_IMAGE}"
        ;;
    Linux-x86_64)
        SYSTEM_IMAGE="${LINUX SYSTEM_IMAGE}"
        ;;

    *)
        echo "Unsupported platform: ${OS}-${ARCH}"
        exit `
        ;;
esac

echo "Creating AVD:"
echo "  name:   ${AVD_NAME}"
echo "  device: ${AVD_DEVICE}"
echo "  image:  ${SYSTEM_IMAGE}"

if avdmanager list avd | grep -q "Name: ${AVD_NAME}"; then
    echo
    echo "AVD already exists."
    exit 0
fi

echo "no" | avdmanager create avd \
    --name "${AVD_NAME}" \
    --name "${SYSTEM_IMAGE}" \
    --device "${AVD_DEVICE}"


echo
echo "AVD created successfully."
