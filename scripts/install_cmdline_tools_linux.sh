#!/usr/bin/env bash
set -euo pipefail

[[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] || { echo 'Linux x86_64 only' >&2; exit 1; }

ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"

export ANDROID_HOME

DEST="$ANDROID_HOME/cmdline-tools/latest"

if [[ -x "$DEST/bin/sdkmanager" ]]; then

  echo '[OK] Command-line tools already installed'

  exit 0

fi

# Android official download listing verified on 2026-09-18; update checksum with URL if release changes.

VERSION=15859902

SHA256=4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583

URL="https://dl.google.com/android/repository/commandlinetools-linux-${VERSION}_latest.zip"

TMP="$(mktemp -d)"

trap 'rm -rf "$TMP"' EXIT

curl --fail --location --retry 3 "$URL" -o "$TMP/tools.zip"

printf '%s  %s\n' "$SHA256" "$TMP/tools.zip" | sha256sum --check --status

unzip -q "$TMP/tools.zip" -d "$TMP/unpacked"

[[ -x "$TMP/unpacked/cmdline-tools/bin/sdkmanager" ]] || { echo 'Unexpected archive layout' >&2; exit 1; }

mkdir -p "$ANDROID_HOME/cmdline-tools"

[[ ! -e "$DEST" ]] || { echo "Incomplete install already present: $DEST; inspect it before retry" >&2; exit 1; }

mv "$TMP/unpacked/cmdline-tools" "$DEST"

echo "[OK] Installed command-line tools at $DEST"
