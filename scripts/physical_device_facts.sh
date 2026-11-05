#!/usr/bin/env bash

set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"


source "${PROJECT_ROOT}/scripts/lib/common.sh"
source "${PROJECT_ROOT}/scripts/lib/physical_device.sh"

SERIAL="${1:-${DEVICE_SERIAL:-}}"

if [[ -z "${SERIAL}" ]]; then

    SERIAL="$(select_single_physical_device)" || {

        die "Unable to select exactly one authorized physical device"

    }

fi

physical_device_is_authorized "${SERIAL}" || 
    die "Device is not authorized: ${SERIAL}"


manufacturer="$(device_manufacturer "${SERIAL}")"
model="$(device_model "${SERIAL}")"
product="$(device_product "${SERIAL}")"
codename="$(device_codename "${SERIAL}")"
android_version="$(device_android_version "${SERIAL}")"
sdk="$(device_sdk_level "${SERIAL}")"
fingerprint="$(device_build_fingerprint "${SERIAL}")"


echo "=========================================="
echo " Android Physical Device Facts"
echo "=========================================="
echo
echo "Serial:"
echo " ${SERIAL}"
echo 
echo "Hardware:"
echo "  Manufacturer: ${manufacturer}"
echo "  Model:        ${model}"
echo "  Product:      ${product}"
echo "  Device:       ${codename}"
echo
echo "Android:"
echo "  Version:      ${android_version}"
echo "  SDK:          ${sdk}"
echo
echo "Build:"
echo "  Fingerprint:  ${fingerprint}"
