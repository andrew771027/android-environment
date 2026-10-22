#!/usr/bin/env bash

set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CI_RUNTIME_DIR="$(mktemp -d "${TMPDIR:-/tmp}/android-ci.XXXXXX")"
export HEADLESS_PID_FILE="${CI_RUNTIME_DIR}/emulator.pid"

cleanup() {

    local exit_code=$?
    local cleanup_rc

    trap - EXIT INT TERM

    echo
    echo "[INFO] CI cleanup started"
    echo "[INFO] Workflow exit code: ${exit_code}"

    set +e

    cleanup_rc=0
    if [[ -f "${HEADLESS_PID_FILE}" ]]; then
        "${PROJECT_ROOT}/scripts/headless_stop.sh" --owned
        cleanup_rc=$?
    else
        echo "[INFO] No emulator launched by this run; skipping stop"
    fi

    if [[ "${cleanup_rc}" -eq 0 ]]; then
        rm -rf "${CI_RUNTIME_DIR}"
    fi

    set -e

    echo "[INFO] Cleanup exit code: ${cleanup_rc}"

    if [[ "${cleanup_rc}" -ne 0 ]]; then

        echo "[WARN] Cleanup reported an error (exit code: ${cleanup_rc})" >&2
        echo "[WARN] Retained PID file: ${HEADLESS_PID_FILE}" >&2
    
    fi

    echo "[INFO] CI cleanup finished"

    if [[ "${exit_code}" -eq 0 ]]; then
        exit_code=${cleanup_rc}
    fi

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
