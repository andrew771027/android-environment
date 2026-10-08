#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${PROJECT_ROOT}/config/android.env"
source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/build_tools.sh"

# -----------------------------------
# 1. Check configuration
# -----------------------------------

ANDROID_HOME="${ANDROID_HOME:-${HOME}/Android/Sdk}"

BUILD_TOOLS_VERSION="${ANDROID_BUILD_TOOLS_VERSION:?ANDROID_BUILD_TOOLS_VERISON is required}"

# -----------------------------------
# 2. Check sdkmanager
# -----------------------------------

command_exists sdkmanager || {

    die "sdkmanager not found"

}

# -----------------------------------
# 3. Check current state
# -----------------------------------

if build_tools_installed \
    "${ANDROID_HOME}" \
    "${BUILD_TOOLS_VERSION}"
then

    log_ok "Android Build Tools ${BUILD_TOOLS_VERSION} already installed"

    exit 0

fi

# -----------------------------------
# 4. Install
# -----------------------------------

package="$(
    build_tools_package_name \
        "${BUILD_TOOLS_VERSION}"
    )"

log_info "Installing ${package}"

sdkmanager "${package}"

# -----------------------------------
# 5. Verify
# -----------------------------------

if ! build_tools_installed \
    "${ANDROID_HOME}" \
    "${BUILD_TOOLS_VERSION}"
then

    die "Android Build Tools installation failed"

fi

log_ok "Android Build Tools ${BUILD_TOOLS_VERSION} installed successfully"