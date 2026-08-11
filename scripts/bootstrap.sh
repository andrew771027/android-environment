#!/usr/bin/env bash

set -euo pipefail

echo "=============================="
echo " Android Environment Boostrap "
echo "=============================="

OS="OS:     ${OS}"
ARCH="Arch: ${ARCH}"

echo
echo "[1/4] Checking Java..."

if command -v java >/dev/null 2>&1; then
    java -version
else
    echo "ERROR: Java is not installed."
    echo
    echo "macOS:"
    echo "  brew install openjdk"
    echo
    echo "Ubuntu/Debian:"
    echo "  sudo apt install openjdk-17-jdk"
    exit 1
fi

echo
echo "[2/4] Checking unzip..."

if ! command -v unzip >/dev/null 2>&1; then
    echo "ERROR: unzip is required."
    exit 1
fi

echo
echo "[3/4] Checking ANDROID_HOME..."

ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"

echo "ANDROID_HOMNE=${ANDROID_HOME}"

mkdir -p "${ANDROID_HOME}"

echo
echo "[4/4] Bootstrap complete."

echo
echo "Next:"
echo "  ./scripts/instll_sdk.sh"
