#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"

OS="$(uname -s)"
ARCH="$(uname -m)"

echo "=============================="
echo " Android SDK Installation"
echo "=============================="

echo "OS:   ${OS}"
echo "Arch: ${ARCH}"

if ! command -v sdkmanager >/dev/null 2>&1; then
    echo "ERROR: sdkmanager not founds."
    echo "Install Android Command Line Tools first."
    exit 1
fi

echo
echo "[1/4] Accepting licens..."

yes | sdkmanager --licenses >/dev/null || true

echo
echo "[2/4] Installing core SDK tools..."

sdkmanager \
    "platform-tools" \
    "emulator" \
    "${ANDROID_PLATFORM}"

case "${OS}-${ARCH}" in

    Darwin-arm64)
        SYSTEM_IMAGE="${MAC_ARM_SYSTEM_IMAGE}"
        ;;

    Darwin-x86_64)
        SYSTEM_IMAGE="${MAC_X86_SYSTEM_IMAGE}"
        ;;

    Linux-x86_64)
        SYSTEM_IMAGE="${LINUX_SYSTEM_IMAGE}"
        ;;
    *)

        echo "Unsupported platform: ${OS}-${ARCH}"
        exit 1
        ;;
esac

echo "System image:"
echo "  ${SYSTEM_IMAGE}"

echo
echo "[4/4] Installing Android system image..."

sdkmanager "${SYSTEM_IMAGE}"

echo
echo "SDK installation complete."
