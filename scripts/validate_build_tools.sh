#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/build_tools.sh"

ANDROID_HOME="${ANDROID_HOME:-${HOME}/Android/Sdk}"

BUILD_TOOLS_VERSION="${ANDROID_BUILD_TOOLS_VERSION:?ANDROID_BUILD_TOOLS_VERSION is required}"

echo "[INFO] Checking Android Build Capability"
echo 

# -----------------------------------
# 1. Check JDK
# -----------------------------------

command_exists java || {

    die "Java not found"

}

log_ok "Java is available"

# -----------------------------------
# 2. Check Android Build Tools
# -----------------------------------

if ! build_tools_installed \
    "${ANDROID_HOME}" \
    "${BUILD_TOOLS_VERSION}"
then

    log_error "Android Build Tools ${BUILD_TOOLS_VERSION} not installed"

    echo
    echo "Install with:"
    echo
    echo "  make install-build-tools"

    exit 1

fi

log_ok "Android Build Tools ${BUILD_TOOLS_VERSION} installed"

# -----------------------------------
# 3. Check important binaries
# -----------------------------------

if ! build_tools_has_required_binaries \
    "${ANDROID_HOME}" \
    "${BUILD_TOOLS_VERSION}"
then

   die "Android Build Tools installation is incomplete."

fi

log_ok "Required Build Tools binaries are available"


# -----------------------------------
# Summary
# -----------------------------------

echo
echo "-----------------------------------"
echo " Android Build Capability PASSED "
echo "-----------------------------------"
echo
echo "ANDROID_HOME:" 
echo "  ${ANDROID_HOME}"
echo
echo "Build Tools:"
echo "  ${BUILD_TOOLS_VERSION}"
