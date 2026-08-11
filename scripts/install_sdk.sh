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
    echo "Install Android COmmand Line Tools first."
    exit 1
fi
