#!/usr/bin/env bash

#Functions intentionally have no side effects until called.
log() {
    printf '[INFO] %s\n' "$*";
}

fail() {
    printf '[ERROR] %s\n' "$*" >&2;

    return 1;
}

validate_positive_integer() {

    [[ "$1" =~ ^[1-9][0-9]*$ ]]

}

check_linux_kvm(){
    [[ "$(uname -s)" == "Linux" ]] || { fail "Headless CI need Linux"; return 1; }

    [[ "$(uname -m)" == "x86_64" ]] || { fail "This exercise supports Linux x86_64 only"; return 1; }

    [[ -e /dev/kvm ]] || { fail "/dev/kvm missing: enable VT-x/AMD-v and KVM / nested virtualization"; return 1; }

    # /dev/kvm 存在：Linux 有暴露 KVM 裝置。
    # -r、-w：目前使用者有讀寫權限。

    [[ -r /dev/kvm && -w /dev/kvm ]] || { fail "/dev/kvm inaccessible: check KVM group/permissions"; return 1; }

    # Emulator 自己也確認硬體加速可用。
    emulator -accel-check || { fail "Emulator reports acceleration unavailable"; return 1; }
}

# Fail closed on shared machines: this exercise owns a single isolated emulator.
check_isolated_adb(){

    local lines

    lines="$(adb devices)" || return 1

    if printf "%s\n" "$lines" | awk '$1 ~ /^emulator-[0-9]+$/ {found=1} END {exit ! found}'; then

        fail "An emulator already exists. Run this exercise on an isolated runner."

        return 1

    fi
}

boot_completed(){
    [[ "$(adb -s "$EMULATOR_SERIAL" get-state 2>/dev/null || :)" == "device" ]] || return 1

    local value

    value="$(adb -s "$EMULATOR_SERIAL" shell getprop sys.boot_completed 2>/dev/null || :)"

    [[ "${value//$'\r'/}" == "1" ]]
}

wait_for_boot(){
    local pid="$1" deadline=$((SECONDS + EMULATOR_BOOT_TIMEOUT_SECONDS))

    while ((SECONDS < deadline)); do

        if boot_completed; then
            local name

            name=$(adb -s "$EMULATOR_SERIAL" emu avd name 2>/dev/null | tr -d '\r' || :)

            if ! printf '%s\n' "$name" | grep -Fxq "$AVD_NAME"; then

                fail "Unexpected AVD identity on $EMULATOR_SERIAL: $name"

                return 1
            fi

            log "READY: $AVD_NAME ($EMULATOR_SERIAL)"

            return 0

        fi

        if ! kill -0 "$pid" 2>/dev/null; then

            fail "Emulator process exited before boot completion"

            return 1

        fi

        sleep "$EMULATOR_POLL_INTERVAL_SECONDS"

    done

    fail "Boot timed out after ${EMULATOR_BOOT_TIMEOUT_SECONDS}s"
}

stop_owned_emulator() {
    local pid="$1" deadline=$((SECONDS + EMULATOR_STOP_TIMEOUT_SECONDS))

    # Target percisely one serial; do not kill unrelated devices or adb server.

    adb -s "$EMULATOR_SERIAL" emu kill >/dev/null 2>&1 || :

    while kill -0 "$pid" 2>/dev/null && (( SECONDS < deadline )); do

        sleep 1

    done

    if kill -0 "$pid" 2>/dev/null; then

        log "Grace period expired; termination owned process $pid"

        kill -TERM "$pid" 2>/dev/null || :
        sleep 2
    fi

    if kill -0 "$pid" 2>/dev/null; then

        kill -KILL "$pid" 2>/dev/null || :

    fi

    wait "$pid" 2>/dev/null || :
}
