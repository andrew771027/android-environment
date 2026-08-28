#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/platform.sh"

PASS=0
FAIL=0

pass(){

    echo "[PASS] $*"

    PASS=$((PASS +1 ))
}

fail(){

    echo "[FAIL] $*"

    FAIL=$((FAIL + 1))

}

echo "=================================="
echo " Android Environment Validation "
echo "=================================="

# ------------------------------------------------
# Host
# ------------------------------------------------

HOST_OS="$(detect_os)"
HOST_ARCH="$(detect_arch)"

echo
echo "Host"
echo "----"

if [[ "${HOST_OS}" != "unsupported" ]]; then

    pass "Operating system: ${HOST_OS}"

else

    fail "Unsupported operating system"

fi

if [[ "${HOST_ARCH}" != "unsupported" ]]; then

    pass "Architecture: ${HOST_ARCH}"

else

    fail "Unsupported arthitecture"

fi


ANDROID_IMAGE_ARCH="$(
    resolve_system_image_arch \
        "${HOST_OS}" \
        "${HOST_ARCH}"
)"

if [[ "${ANDROID_IMAGE_ARCH}" != "unsupported" ]]; then

    pass "System image architecture: ${ANDROID_IMAGE_ARCH}"

else

    fail "Could not resolve Android system image architecture"

fi


SYSTEM_IMAGE="system-images;android-${ANDROID_API_LEVEL};${SYSTEM_IMAGE_FLAVOR};${ANDROID_IMAGE_ARCH}"


# ----------------------------------------------
# Environment variables
# ----------------------------------------------

echo
echo "Environment"
echo "-----------"

if [[ -n "${ANDROID_HOME:-}" ]]; then

    pass "ANDROID_HOME=${ANDROID_HOME}"

else

    fail "ANDROID_HOME not set"

fi

if [[ -d "${ANDROID_HOME}" ]]; then

    pass "Android SDK directory exists"

else

    fail "Android SDK directory missing: ${ANDROID_HOME}"

fi


# ----------------------------------------------
# Tools
# ----------------------------------------------

echo
echo "Tools"
echo "-----"

TOOLS=(
    java
    sdkmanager
    avdmanager
    adb
    fastboot
    emulator
)

for tool in "${TOOLS[@]}"; do

    if command_exists "${tool}"; then
        pass "${tool}"
    else
        fail "${tool} missing"
    fi

done

# Stop here if sdkmanager doesn't exist.

if ! command_exists sdkmanager; then

    echo
    echo "Cannot validate SDK packages without sdkmanager."

    exit 1
fi

# --------------------------------------
# Packages
# --------------------------------------

echo
echo "SDK Packages"
echo "------------"

PACKAGES=(
    "platform-tools"
    "emulator"
    "${ANDROID_PLATFORM}"
    "${SYSTEM_IMAGE}"
)

for package in "${PACKAGES[@]}"; do

    if package_is_installed "${package}"; then

        pass "${package}"

    else

        fail "${package} missing"

    fi

done

# ---------------------------------------
# AVD
# ---------------------------------------

if command_exists emulator; then

    if emulator -list-avds | grep -Fxq "${AVD_NAME}"; then

        pass "AVD exists: ${AVD_NAME}"

    else

        fail "AVD missing: ${AVD_NAME}"

    fi

else

    fail "Cannot validate AVD because emulator is missing"

fi

# ---------------------------------------
# Connected devices (information)
# ---------------------------------------

echo
echo "Connected Devices"
echo "-----------------"

if command_exists adb; then

    adb devices

fi

# ----------------------------------------
# Summary
# ----------------------------------------

echo
echo "===================================="
echo " Validation Summary "
echo "===================================="

echo "PASS=${PASS}"
echo "FAIL=${FAIL}"

if [[ "${FAIL}" -gt 0 ]]; then

    echo
    echo "Environment validaiton FAILED."

    exit 1

fi

echo
echo "Environment vaildation PASSED."
