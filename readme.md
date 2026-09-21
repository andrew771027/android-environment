# Android Environment v0.4

Reproducible, command-line-first Android workstation environment for Android Cookbook.

Version 0.4 is an overlay on v0.3 for Linux x86_64 / KVM preflight, a headless emulator, readiness checks, isolated smoke testing, cleanup, CI, and offline pytest tests. Preserve your existing local configuration when applying the overlay.

The v0.3 local workflow remains available: start, wait for Android boot completion, inspect status, stop, and reset user data. It builds on v0.2's host architecture detection, architecture-aware system-image selection, idempotent SDK/AVD setup, and provisioning validation.

Start at [docs/setup.md](./docs/setup.md). Concepts: [Linux KVM](./docs/linux-kvm.md), [headless lifecycle](./docs/headless-lifecycle.md), and [testing](./docs/testing.md).

## v0.4 CI / Headless Quick Start

Use Ubuntu 24.04 x86_64 with KVM and the host dependencies described in the setup guide. Run from the repository root:

```bash
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

make linux-tools      # Linux-only CLI bootstrap; verifies the downloaded ZIP checksum
sdkmanager --licenses # Review and accept licenses yourself
make install-sdk
make create-avd
make kvm-check
make headless-smoke
make unit-test        # Offline tests; excludes integration cases
```

The [GitHub workflow](./.github/workflows/android-headless.yml) accepts Android SDK licenses in a noninteractive CI runner. This overlay assumes an isolated, disposable runner and reserves emulator port 5554; do not use it to control a shared lab workstation. macOS users should follow the local workflow below.

The offline `unit` job uses Python 3.14. Passing offline tests does not establish a successful real emulator / KVM run; inspect the GitHub Actions results. See [testing](./docs/testing.md) for coverage and prerequisites.

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

## Local Workstation Quick Start

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
| `make linux-tools` | Install pinned Linux x86_64 command-line tools and verify the downloaded archive checksum |
| `make install-sdk` | Install pinned packages and the host-compatible system image |
| `make create-avd` | Create the configured AVD if it does not exist |
| `make emulator-start` | Start the AVD or reuse an online emulator, then wait for boot completion |
| `make emulator-wait` | Wait for Android boot completion without launching an emulator |
| `make emulator-status` | Report STOPPED, BOOTING, or READY |
| `make emulator-stop` | Stop the first online emulator through ADB |
| `make emulator-reset` | Wipe the configured AVD user data, launch it, and wait for boot |
| `make kvm-check` | Check Linux x86_64, KVM access, and emulator acceleration |
| `make headless-smoke` | Invoke the headless emulator lifecycle and smoke script |
| `make unit-test` | Run offline pytest tests, excluding integration tests |
| `make test` | Alias for `make unit-test` |
| `make doctor` | Show tool, AVD, and connected-device availability |
| `make validate` | Strictly validate host, tools, packages, and AVD |
| `make devices` | List devices visible to ADB |
| `make shell` | Open an ADB shell |
| `make clean` | Delete only the configured project AVD |

`doctor` is informational. `validate` reports pass/fail counts and exits non-zero when provisioning is incomplete; it does not require a running emulator or verify Android boot completion. Use `make emulator-wait` for runtime readiness. The local launch command is `make emulator-start`.

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

For an existing `.venv`, activate it with `source script.sh`. Run mock tests independently, then prepare the emulator for integration tests:

```bash
source script.sh
python -m pytest -v -m "not integration"
make emulator-start
python -m pytest -v -m integration
```

| Suite | Cases | Coverage |
| --- | --- | --- |
| [Mock tests](./tests/test_emulator_lib.py) | 6 | Serial discovery, missing emulator, boot-complete / incomplete responses, and wait timeout using a fake `adb` with the real Bash helpers |
| [Integration tests](./tests/test_emulator_integration.py) | 2 | Baseline AVD appears in `emulator -list-avds`; first online emulator reports `sys.boot_completed=1` |
| [CI emulator tests](./tests/test_ci_emulator.py) | 12 | Boot readiness, AVD identity, timeout configuration, isolation, physical-device filtering, and simulated smoke success / API mismatch |

Mock tests require no real SDK or emulator. Integration tests require SDK tools on `PATH`, the baseline AVD, and an already booted emulator; they do not provision or launch it. The AVD existence test hardcodes `cookbook_pixel_api_36`, while the readiness test does not verify the selected emulator's AVD name.

`make test` and `make unit-test` run offline tests, including the v0.4 CI cases. Use `python -m pytest -v tests` to run all tests. The `integration` marker labels tests; it does not automatically skip them when an emulator is unavailable. Current coverage does not include end-to-end start/stop/reset behavior. See [testing](./docs/testing.md) for setup, coverage limits, and failure diagnosis.

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
- [Linux / KVM prerequisites](./docs/linux-kvm.md)
- [Headless emulator lifecycle](./docs/headless-lifecycle.md)
- [Emulator guide](./docs/emulator.md)
- [Emulator lifecycle implementation](./docs/emulator-lifecycle.md)
- [Testing and troubleshooting](./docs/testing.md)
- [Android ecosystem concepts](./docs/android_ecosystem.md)
- [Android Emulator, VM, Docker, and Linux kernel](./docs/android_emulator_vm_docker.md)
- [Roadmap](./roadmap.md)

Some background documents retain v0.2 labels. Use the commands above and the lifecycle implementation guide for v0.3 behavior.

## v0.3 Highlights

- Shared emulator discovery and boot-readiness helpers in `scripts/lib/emulator.sh`.
- Start or reuse an online emulator and wait for Android boot completion.
- Dedicated wait, status, stop, and user-data reset commands.
- Configurable boot polling and start flags, with emulator output in `emulator.log`.
- Six mock tests and two integration tests, plus lifecycle and testing documentation.

The v0.4 overlay adds the headless/CI workflow described above; the local `make emulator-start` launcher continues to start an interactive emulator. Physical-device workflows remain planned for v0.5 in the roadmap.
