#!/usr/bin/env bash

set -u

detect_os(){

    case "$(uname -s)" in

        Darwin)
            echo "darwin"
            ;;
        Linux)
            echo "linux"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in

    x86_64|amd64)
        echo "x86_64"
        ;;
    arm64|aarch64)
        echo "arm64"
        ;;
    *)
        echo "unsupported"
        ;;
    esac
}

resolve_system_image_arch(){
    local os="$1"
    local arch="$2"

    case "${os}-${arch}" in

        darwin-x86_64)
            echo "x86_64"
            ;;
        darwin-arm64)
            echo "arm64-v8a"
            ;;
        linux-x86_64)
            echo "x86_64"
            ;;
        linux-arm64)
            echo "arm64-v8a"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}
