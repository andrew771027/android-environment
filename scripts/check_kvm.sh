#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT/config/android.env"

export ANDROID_HOME

export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

source "$ROOT/scripts/lib/ci_emulator.sh"

command -v emulator >/dev/null || { fail "emulator command missing; run make install-sdk"; exit 1;}

check_linux_kvm

log "KVM validation passed"
