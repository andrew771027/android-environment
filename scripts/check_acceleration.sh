#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/scripts/lib/platform.sh"
source "${PROJECT_ROOT}/scripts/lib/acceleration.sh"

HOST_OS="$(detect_os)"
HOST_ARCH="$(detect_arch)"

echo "[INFO] Checking Android Emulator acceleration"
echo

case "${HOST_OS}" in

    linux)

        echo "[INFO] Host OS: Linux"
        echo "[INFO] Using KVM acceleration check"
        echo

        "${PROJECT_ROOT}/scripts/check_kvm.sh"

        ;;
    
    darwin)

        echo "[INFO] Host OS: macOS"
        echo "[INFO] Architecture: ${HOST_ARCH}"
        echo "[INFO] Checking Hypervisor.Framework through Android Emulator"
        echo

        if ! check_emulator_exists; then

            echo "[ERROR] Android Emulator not fount" >&2
            exit 1
        
        fi

        if ! check_macos_acceleration; then

            echo "[ERROR] Android Emulator acceleration is unavailable" >&2
            exit 1

        fi

        echo "[ OK ] Android Emulator accleration is available"
        echo 
        echo "================================================"
        echo " macOS Emulator Acceleration Check PASSED "
        echo "================================================" 

        ;;
    
    *)

        echo "[ERROR] Unsupported host OS: ${HOST_OS}" >&2
        exit 1

        ;;

esac