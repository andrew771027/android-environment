# Android Environment v0.2

Reproducible, command-line-first Android workstation environment for Android Cookbook.

Version 0.2 adds host architecture detection, architecture-aware system-image selection, idempotent SDK/AVD setup, and full environment validation.

## Baseline

- Android 16 / API level 36
- Google APIs system image
- Pixel 7 profile; AVD `cookbook_pixel_api_36`
- JDK 17 recommended; Android Studio optional

## Supported Hosts

| Host | CPU | System-image ABI |
| --- | --- | --- |
| macOS | Apple Silicon (`arm64`) | `arm64-v8a` |
| macOS | Intel (`x86_64`) | `x86_64` |
| Linux | ARM64 (`arm64` / `aarch64`) | `arm64-v8a` |
| Linux | Intel/AMD (`x86_64` / `amd64`) | `x86_64` |

## Quick Start

Install JDK 17 and Android SDK Command-Line Tools first, then expose the SDK tools on `PATH`:

```bash
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

make bootstrap
make install-sdk
make create-avd
make validate
make emulator
```

In another terminal:

```bash
adb wait-for-device
adb devices
adb shell getprop ro.build.version.sdk
```

The expected SDK level is `36`.

## Commands

| Command | Purpose |
| --- | --- |
| `make bootstrap` | Check basic host dependencies and create the SDK directory |
| `make install-sdk` | Install pinned packages and the host-compatible system image |
| `make create-avd` | Create the configured AVD if it does not exist |
| `make emulator` | Start the AVD without loading an old snapshot |
| `make doctor` | Show tool, AVD, and connected-device availability |
| `make validate` | Strictly validate host, tools, packages, and AVD |
| `make devices` | List devices visible to ADB |
| `make shell` | Open an ADB shell |
| `make clean` | Delete only the configured project AVD |

`doctor` is informational. `validate` reports pass/fail counts and exits non-zero when provisioning is incomplete.

## Configuration

Defaults live in [`config/android.env`](./config/android.env); the static package list lives in [`config/packages.txt`](./config/packages.txt). Callers may override `ANDROID_HOME`.

## Documentation

- [Complete setup](./docs/setup.md)
- [Configuration](./docs/configuration.md)
- [Architecture detection](./docs/architecture_detection.md)
- [Validation and doctor](./docs/validation.md)
- [macOS setup](./docs/macos.md)
- [Linux setup](./docs/linux.md)
- [Emulator lifecycle](./docs/emulator.md)
- [Android ecosystem concepts](./docs/android_ecoystem.md)

## v0.2 Highlights

- Normalized Darwin/Linux and ARM64/x86_64 host detection.
- Automatic `arm64-v8a` or `x86_64` image selection.
- Shared helpers for logging, prerequisites, and package installation.
- Idempotent SDK package installation and AVD creation.
- System-image and hardware-profile preflight checks.
- Strict `make validate` workflow for local checks and automation.
