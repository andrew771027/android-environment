#!/usr/bin/env bash

set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/platform.sh"
source "${PROJECT_ROOT}/scripts/lib/hosted_ci.sh"



echo "=========================================="
echo " GitHub Hosted Android CI Preflight "
echo "=========================================="
echo

# --------------------------------------------------
# 1. GitHub Actions
# --------------------------------------------------

if [[ "${GItHUB_ACTIONS:-}" != "true" ]]; then

    die "This preflight is intended for GitHUb Actions"

fi

log_ok "Github Actions environment detected"

# --------------------------------------------------
# 2. Host platform
# --------------------------------------------------

HOST_OS="${detect_os}"
HOST_ARCH="${detect_arch}"

if ! hosted_ci_supported_platform \
     "${HOST_OS}" \
     "${HOST_ARCH}"
then

    die "Unsupported hosted CI platform: ${HOST_OS}-${HOST_ARCH}"

fi


log_ok "Hosted platform: ${HOST_OS}-${HOST_ARCH}"


# --------------------------------------------------
# 3. Android SDK
# --------------------------------------------------

ANDROID_SDK="$(
    hosted_ci_android_home
)" || die "ANDROID_HOME / ANDROID_SDK_ROOT not avaiable"


log_ok "Android SDK root: ${ANDROID_SDK}"


command_exists sdkmanager ||
    die "sdkmanager not found"


log_ok "sdkmanager available"


# --------------------------------------------------
# 4. KVM
# --------------------------------------------------

if ! hosted_ci_kvm_accessible "/dev/kvm"; then

    die "/dev/kvm is not readable and writable"

fi

log_ok "/dev/kvm is readable and writable"

echo
echo "============================================="
echo " Hosted Android CI preflight PASSED "
echo "============================================="

