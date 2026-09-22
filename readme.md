# Android Environment v0.4.0

Reproducible, command-line-first Android workstation environment for Android Cookbook.

Version 0.4.0 adds Linux/KVM host checks and mock tests while retaining architecture-aware SDK/AVD setup and emulator lifecycle management. The KVM command targets Linux x86_64; the headless smoke runner is absent. See [Linux/KVM status](./docs/linux-kvm.md) for the current limitations.

## Baseline

- Android 16 / API level 36
- Google APIs system image
- Pixel 7 profile; AVD `cookbook_pixel_api_36`
- JDK 17 recommended; Android Studio optional

## Host Architecture Mapping

The scripts map the following hosts to system-image ABIs. This mapping does not configure hardware acceleration or verify that emulator binaries are available for every host; check your local setup with `emulator -accel-check`.

| Host | CPU | System-image ABI |
| --- | --- | --- |
| macOS | Apple Silicon (`arm64`) | `arm64-v8a` |
| macOS | Intel (`x86_64`) | `x86_64` |
| Linux | ARM64 (`arm64` / `aarch64`) | `arm64-v8a` |
| Linux | Intel/AMD (`x86_64` / `amd64`) | `x86_64` |

## Quick Start

Install JDK 17, Bash, make, unzip, and Android SDK Command-Line Tools first (see [macOS](./docs/macos.md) or [Linux](./docs/linux.md)). Bootstrap checks prerequisites; it does not download Java or Command-Line Tools. From the repository root, expose the SDK tools on `PATH`:

```bash
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

make bootstrap
make install-sdk
make create-avd
make validate
make emulator-start
make emulator-status
```

In another terminal:

```bash
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
| `make emulator-start` | Start the AVD or reuse an online emulator, then wait for boot completion |
| `make emulator-wait` | Wait for Android boot completion without launching an emulator |
| `make emulator-status` | Report STOPPED, BOOTING, or READY |
| `make emulator-stop` | Stop the first online emulator through ADB |
| `make emulator-reset` | Wipe the configured AVD user data, launch it, and wait for boot |
| `make unit-test` | Run non-integration tests using `.venv/bin/python`, falling back to `python3` |
| `make kvm-check` | Check Linux x86_64, KVM device access, and emulator acceleration |
| `make doctor` | Show tool, AVD, and connected-device availability |
| `make validate` | Strictly validate host, tools, packages, and AVD |
| `make devices` | List devices visible to ADB |
| `make shell` | Open an ADB shell |
| `make clean` | Delete only the configured project AVD |

`doctor` is informational. `validate` reports pass/fail counts and exits non-zero when provisioning is incomplete; it does not require a running emulator or verify Android boot completion. Use `make emulator-wait` for runtime readiness. The current launch command is `make emulator-start`; `make emulator` is not a defined target.

## Emulator Lifecycle

`make emulator-start` checks the required tools and configured AVD, returns successfully if an online emulator is already ready, waits if it is still booting, or launches the configured AVD in the background. Readiness means `sys.boot_completed` is `1`, not merely that ADB reports `device`.

| Status | ADB observation |
| --- | --- |
| `STOPPED` | No `emulator-*` entry with state `device` |
| `BOOTING` | An online emulator exists, but `sys.boot_completed` is not `1` |
| `READY` | An online emulator exists and `sys.boot_completed` is `1` |

`STOPPED` can also mean an emulator is offline or not yet visible to ADB. A successful status query can report any of these states; use `make emulator-wait` when success must mean ready.

The default polling interval is 2 seconds with a 180-second wait budget. The budget counts sleep time, excluding ADB command duration. Start and reset overwrite `emulator.log` in the project root when launching a process. A boot timeout exits non-zero but leaves the background emulator running.

The lifecycle scripts select the first `emulator-*` entry with ADB state `device`; they do not verify its AVD name. Use one online emulator for this workflow. Stop sends `emu kill` and waits up to 30 polling seconds for disconnection; it succeeds immediately if no online emulator exists.

**`make emulator-reset` clears installed apps and user settings.** It stops the selected emulator, waits for disconnection, then launches the configured AVD with `-wipe-data -no-snapshot-load -no-boot-anim` and waits for boot. Its disconnection wait currently has no timeout. `make clean` deletes the configured AVD without stopping it first.

See [lifecycle implementation](./docs/emulator-lifecycle.md) for shared helpers and detailed behavior.

## Tests

The test environment requires Python >= 3.14 and pytest >= 9.1.1, < 10.0.0, as declared in [pyproject.toml](./pyproject.toml). To create a test environment from the repository root:

```bash
python3.14 -m venv .venv
source .venv/bin/activate
python -m pip install 'pytest>=9.1.1,<10.0.0'
```

`make unit-test` uses `.venv/bin/python` when present, otherwise `python3`. Override it with `make unit-test PYTHON=/path/to/python`; the selected interpreter must have pytest installed.

For an existing `.venv`, activate it with `source script.sh`. Run mock tests independently, then prepare the emulator for integration tests:

```bash
source script.sh
make unit-test
make emulator-start
python -m pytest -v -m integration
```

| Suite | Cases | Coverage |
| --- | --- | --- |
| [Mock tests](./tests/test_emulator_lib.py) | 6 | Serial discovery, missing emulator, boot-complete / incomplete responses, and wait timeout using a fake `adb` with the real Bash helpers |
| [KVM mock tests](./tests/test_kvm.py) | 4 | Device existence and acceleration success/failure using temporary files and a fake emulator |
| [Integration tests](./tests/test_emulator_integration.py) | 2 | Baseline AVD appears in `emulator -list-avds`; first online emulator reports `sys.boot_completed=1` |

Mock tests require no real SDK or emulator. Integration tests require SDK tools on `PATH`, the baseline AVD, and an already booted emulator; they do not provision or launch it. The AVD existence test hardcodes `cookbook_pixel_api_36`, while the readiness test does not verify the selected emulator's AVD name.

`make unit-test` selects 10 non-integration tests; `python -m pytest -v tests` selects all 12 tests. The 2026-09-22 macOS run with Python 3.14.0 and pytest 9.1.1 reports **10 passed, 2 deselected**. The two integration tests were excluded by the marker filter and were not run; real Linux/KVM acceleration was not verified. The `integration` marker labels tests; it does not automatically skip them when an emulator is unavailable. Current coverage does not include end-to-end start/stop/reset behavior. See [testing](./docs/testing.md) for setup, coverage limits, and failure diagnosis.

## Configuration

Defaults live in [`config/android.env`](./config/android.env); the static package list lives in [`config/packages.txt`](./config/packages.txt). Callers may override `ANDROID_HOME`.

| Variable | Default | Purpose |
| --- | --- | --- |
| `ANDROID_HOME` | `$HOME/Android/Sdk` | SDK root; preserves the caller's value |
| `ANDROID_API_LEVEL` | `36` | API used to derive platform, system image, and AVD name |
| `SYSTEM_IMAGE_FLAVOR` | `google_apis` | System-image flavor |
| `AVD_NAME` | `cookbook_pixel_api_36` | AVD to create, launch, reset, or delete |
| `AVD_DEVICE` | `pixel_7` | Hardware profile for AVD creation |
| `EMULATOR_BOOT_TIMEOUT_SECONDS` | `180` | Boot polling wait budget |
| `EMULATOR_BOOT_POLL_INTERVAL_SECONDS` | `2` | Delay between readiness checks |
| `EMULATOR_NO_SNAPSHOT_LOAD` | `true` | Start with `-no-snapshot-load` |
| `EMULATOR_NO_BOOT_ANIMATION` | `true` | Start with `-no-boot-anim` |

Edit `config/android.env` to change defaults other than `ANDROID_HOME`; these assignments overwrite caller-provided values when sourced. Reset always uses both launch flags regardless of these toggles. When changing the API level, also update `config/packages.txt`; custom AVD names require updating the hardcoded integration-test expectation.

## Documentation

- [Complete setup](./docs/setup.md)
- [Configuration](./docs/configuration.md)
- [Architecture detection](./docs/architecture_detection.md)
- [Validation and doctor](./docs/validation.md)
- [macOS setup](./docs/macos.md)
- [Linux setup](./docs/linux.md)
- [Linux/KVM checks and current limitations](./docs/linux-kvm.md)
- [Emulator guide](./docs/emulator.md)
- [Emulator lifecycle implementation](./docs/emulator-lifecycle.md)
- [Testing and troubleshooting](./docs/testing.md)
- [Android ecosystem concepts](./docs/android_ecosystem.md)
- [Android Emulator, VM, Docker, and Linux kernel](./docs/android_emulator_vm_docker.md)
- [Roadmap](./roadmap.md)

## v0.4.0 Status

- Existing local start, wait, status, stop, and reset commands remain available.
- Linux/KVM helpers, a check command, and four passing mock test cases have been added. Real Linux/KVM host validation remains to be exercised on a suitable host.
- `make unit-test` runs non-integration tests only.
- `EMULATOR_PORT`, `EMULATOR_SERIAL`, `EMULATOR_STOP_TIMEOUT_SECONDS`, and `EMULATOR_POLL_INTERVAL_SECONDS` are declared but unused by the current scripts. They do not isolate an emulator or change local stop behavior.
- There is no `make headless-smoke` target or `scripts/run_headless_smoke.sh` runner. There is no `tests/test_ci_emulator.py` in the current source tree, and no automated headless workflow is available.

The roadmap describes intended milestones; the commands and limitations above reflect the current source. The v0.4.0 label here identifies the documentation release; `pyproject.toml` still declares package version `0.1.0`.
