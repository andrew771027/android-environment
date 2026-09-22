#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/platform.sh"
source "${PROJECT_ROOT}/scripts/lib/kvm.sh"

KVM_DEVICE="/dev/kvm"

echo " ============================================== "
echo " Android Environment - Linux / KVM "
echo " ============================================== "

# --------------------------------------------------
# Host
# --------------------------------------------------
HOST_OS="$(detect_os)"
HOST_ARCH="$(detect_arch)"

echo
log_info "OS: ${HOST_OS}"
log_info "Architecture: ${HOST_ARCH}"

if [[ "${HOST_OS}" != "linux" ]]; then

    die "KVM check requires Linux;

Current OS:
${HOST_OS}"

fi

if [[ "${HOST_ARCH}" != "x86_64" ]]; then

    die "Android Environment v0.4.0 currently support Linux x86_64 only.

Current architecture:
${HOST_ARCH}"

fi

# -------------------------------------------------
# Android Enulator
# -------------------------------------------------

echo
log_info "Checking Android Emulator"

if ! command_exists emulator; then

    die "Android Emulator command not found.

Run:

make install-sdk"

fi

log_ok "Android Emulator found"

# -------------------------------------------------
# KVM device
# -------------------------------------------------

echo
log_info "Checking KVM device"

if ! kvm_device_exists "${KVM_DEVICE}"; then

    die "KVM device not found:

${KVM_DEVICE}

Check whether virtualization and KVM are enabled."

fi

log_ok "KVM device exists: ${KVM_DEVICE}"

# ------------------------------------------------
# KVM Permission
# ------------------------------------------------

if ! kvm_device_accessible "${KVM_DEVICE}"; then

    die "Current user cannot access:

${KVM_DEVICE}

Check KVM group membership and device permissions."

fi

log_ok "KVM device is readable and writable"

# ------------------------------------------------
# Emulator acceleration
# ------------------------------------------------

echo
log_info "Checking Emulator acceleration"

if ! emulator_acceleration_available; then

    echo

    emulator -accel-check || true

    die "Android EMulator acceleration is unavailable."

fi

log_ok "Android EMulator acceleration is available"

# ------------------------------------------------
# Summary
# ------------------------------------------------

echo
echo " ========================================== "
echo " Linux / KVM Check PASSED"
echo " ========================================== "
echo

echo
echo "Host:"
echo "  OS:           ${HOST_OS}"
echo "  Architecture: ${HOST_ARCH}"
echo
echo "KVM:"
echo "  Device:       ${KVM_DEVICE}"
echo "  Acceleration: available"
