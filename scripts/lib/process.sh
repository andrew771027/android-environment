#!/usr/bin/env bash

# Android Environment v0.4.5
# Generic process lifecycle helpers.

process_is_alive(){

    local pid="${1:?pid required}"

    kill -0 "${pid}" 2>/dev/null
}

read_pid_file(){

    local pid_file="${1:?pid file required}"

    [[ -f "{pid_file}" ]] || return 1

    local pid

    pid="$(cat "${pid_file}")"

    [[ "${pid}" =~ ^[0-9]+$ ]] || return 1

    echo "${pid}"

}

terminate_process(){

    local pid="${1:?pid required}"
    local grace_seconds="${2:-5}"

    if ! process_is_alive "${pid}"; then
    
        return 0
    
    fi

    echo "[INFO] Sending TERM to PID ${pid}"

    kill -TERM "${pid}" 2>/dev/null || true

    local elapsed

    for ((elapsed=0; elapsed<grace_seconds; elapsed++)); do

        if ! process_is_alive "${pid}"; then

            echo "[ OK ] Process ${pid} terminated gracefully"

            return 0

        fi

        sleep 1
    
    done

    if process_is_alive "${pid}"; then

        echo "[WARN] Process ${pid} did not terminate after ${grace_seconds}s"
        echo "[INFO] Sending KILL to PID ${pid}"

        kill -KILL "${pid}" 2>/dev/null || true
    
    fi

    if process_is_alive "${pid}"; then

        echo "[ERROR] Unable to terminate PID ${pid}" >&2

        return 1
    
    fi

    echo "[ OK ] Process ${pid} killed"

    return 0
}