#!/usr/bin/env bash

set -euo pipefail

maker="${1:?maker required}"

cleanup() {

    echo "cleanup" > "${maker}"

}

trap cleanup EXIT

echo "running"

exit 1