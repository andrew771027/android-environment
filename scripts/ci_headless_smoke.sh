#!/usr/bin/env bash

set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cleanup() {

    local exit_code=$?

    trap - EXIT INT TERM

    echo
    echo "[INFO] CI cleanup started"

    set +e

    "${PROJECT_ROOT}/scripts/headless_stop.sh"

    cleanup_rc=$?

    set -e

    if [[ "${cleanup_rc}" -ne 0 ]]; then

        echo "[WARN] Cleanup reported an error"
    
    fi

    echo "[INFO] CI cleanup finished"

    exit "${exit_code}"

}

# 這支 script 不管成功或失敗離開，都跑 cleanup()。
trap cleanup EXIT

# Ctrl+C → INT
trap 'exit 130' INT

# CI stop → TERM
trap 'exit 143' TERM

echo "=============================================="
echo " Android Environment CI Headless Smoke "
echo "=============================================="

"${PROJECT_ROOT}/scripts/headless_start.sh"

"${PROJECT_ROOT}/scripts/smoke_test.sh"

echo
echo "[ OK ] CI Headless Smoke completed"