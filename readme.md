# Android Environment v0.4.3

Set up an Android SDK and emulator for Android Cookbook from the command line. Android Studio is optional.

Version 0.4.3 adds optional Android SDK Build Tools 36.0.0 installation and validation for application builds. The macOS headless workflow introduced in v0.4.2 remains available through the shared acceleration check. Linux headless operation still requires x86_64 and KVM. The shared headless lifecycle checks boot readiness and AVD identity before reporting ready or requesting shutdown. The desktop workflow remains available on macOS and Linux.

## SDK target

| Component | Baseline |
| --- | --- |
| Android | Android 16 / API 36 |
| SDK Platform | `platforms;android-36` |
| System image | `google_apis`, with the ABI selected from the host architecture |
| AVD | `cookbook_pixel_api_36`, using the `pixel_7` profile |
| Command-Line Tools download | 22.0 / build 15859902 |
| Java | JDK 17 recommended; the application's Gradle/AGP requirements still apply |
| Optional Build Tools | `build-tools;36.0.0` |

Package IDs and API level are specified, but SDK package revisions are not locked. See [setup](./docs/setup.md) for the exact image packages and download instructions.

## Get started

Install the prerequisites and Command-Line Tools using the [macOS guide](./docs/macos.md) or [Linux guide](./docs/linux.md). Run the following from the repository root:

```bash
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

make bootstrap
make install-sdk
make create-avd
make validate
```

`bootstrap` checks Java and unzip and creates the SDK directory. It does not install the prerequisites.

If you will build APKs, also run:

```bash
make install-build-tools
make validate-build-tools
```

Build Tools are optional and are not installed by `make install-sdk`. Validation checks Java availability, the versioned directory, and executable `aapt2`, `apksigner`, and `zipalign`; it does not run a Gradle build. See [Build Tools](./docs/build-tools.md).

For a desktop session:

```bash
make emulator-start
make emulator-status
```

For macOS or a Linux x86_64 host with KVM, without an emulator window:

```bash
make headless-start
make headless-status
```

Headless start calls `scripts/check_acceleration.sh`: macOS checks `emulator -accel-check`, while Linux delegates to the KVM check. It refuses to launch while any emulator is listed by ADB. It uses port `5554` and serial `emulator-5554`. See [headless operation](./docs/headless.md) for logs, readiness checks, and shutdown behavior.

After either start command succeeds, check the device:

```bash
adb devices
adb shell getprop ro.build.version.sdk
```

The SDK property should report `36`. Use `adb -s SERIAL` when more than one device is connected.

## Commands

| Command | Action |
| --- | --- |
| `make bootstrap` | Check Java and unzip; create the SDK directory |
| `make install-sdk` | Install missing SDK packages and the host-specific system image |
| `make install-build-tools` | Install the configured Build Tools package if its directory is absent |
| `make validate-build-tools` | Check Java, the Build Tools directory, and three executable tools |
| `make create-avd` | Create the configured AVD if its name is not already listed |
| `make validate` | Check tools, package IDs, host mapping, and AVD existence |
| `make doctor` | Print tool, AVD, and device information |
| `make acceleration-check` | Check macOS emulator acceleration or delegate to Linux/KVM checks |
| `make kvm-check` | Check Linux x86_64, KVM access, and emulator acceleration |
| `make emulator-start` | Launch the configured AVD or reuse the first online emulator; wait for boot |
| `make emulator-wait` | Wait for the first online emulator to finish booting |
| `make emulator-status` | Report `STOPPED`, `BOOTING`, or `READY` |
| `make emulator-stop` | Stop the first online emulator and wait for disconnection |
| `make emulator-reset` | Wipe the configured AVD's user data and start it |
| `make headless-start` | Launch on port 5554; wait for boot and verify the AVD name |
| `make headless-status` | Report state and ready AVD identity at `emulator-5554`; fail if ADB listing fails |
| `make headless-stop` | Request shutdown after checking boot readiness and AVD identity |
| `make devices` | Run `adb devices` |
| `make shell` | Run `adb shell` |
| `make unit-test` | Run tests that do not require a real SDK or emulator |
| `make integration-test` | Check baseline AVD listing and boot completion of an online emulator |
| `make clean` | Delete the configured AVD; does not stop it first |

Desktop lifecycle commands select the first online emulator without checking its AVD name. Use them with one emulator at a time. `emulator-reset` removes installed apps and user settings; `clean` deletes the AVD.

## Tests

Create a test environment with the Python and pytest versions declared in [pyproject.toml](./pyproject.toml):

```bash
python3.14 -m venv .venv
source .venv/bin/activate
python -m pip install 'pytest>=9.1.1,<10.0.0'
make unit-test
```

The source defines 28 mock tests and 2 integration tests. On 2026-10-08, separate runs reported `28 passed, 2 deselected` for `make unit-test` and `2 passed, 28 deselected` for `make integration-test`. Unit tests do not start or require an emulator. Integration tests require the baseline AVD and an already booted emulator:

```bash
make integration-test
```

The integration tests check AVD listing and boot completion, not APK builds or the complete emulator start/stop lifecycle. See [testing](./docs/testing.md) for results and coverage limits.

| Variable | Default | Purpose |
| --- | --- | --- |
| `ANDROID_HOME` | `$HOME/Android/Sdk` | SDK root; preserves the caller's value |
| `ANDROID_API_LEVEL` | `36` | API used to derive platform, system image, and AVD name |
| `ANDROID_BUILD_TOOLS_VERSION` | `36.0.0` | Optional Build Tools package and directory |
| `SYSTEM_IMAGE_FLAVOR` | `google_apis` | System-image flavor |
| `AVD_NAME` | `cookbook_pixel_api_36` | AVD to create, launch, reset, or delete |
| `AVD_DEVICE` | `pixel_7` | Hardware profile for AVD creation |
| `EMULATOR_BOOT_TIMEOUT_SECONDS` | `180` | Boot polling wait budget |
| `EMULATOR_BOOT_POLL_INTERVAL_SECONDS` | `2` | Delay between readiness checks |
| `EMULATOR_NO_SNAPSHOT_LOAD` | `true` | Start with `-no-snapshot-load` |
| `EMULATOR_NO_BOOT_ANIMATION` | `true` | Start with `-no-boot-anim` |

Edit `config/android.env` to change defaults other than `ANDROID_HOME`; these assignments overwrite caller-provided values when sourced. Reset always uses both launch flags regardless of these toggles. When changing the API level, also update `config/packages.txt`; custom AVD names require updating the hardcoded integration-test expectation.

## Documentation

| Task | Guide |
| --- | --- |
| Install the environment | [Setup](./docs/setup.md), [macOS](./docs/macos.md), [Linux](./docs/linux.md) |
| Configure paths and defaults | [Configuration](./docs/configuration.md) |
| Understand host-to-image selection | [Architecture detection](./docs/architecture_detection.md) |
| Diagnose provisioning | [Validation](./docs/validation.md) |
| Run a desktop emulator | [Emulator guide](./docs/emulator.md) |
| Inspect desktop lifecycle behavior | [Lifecycle reference](./docs/emulator-lifecycle.md) |
| Check Linux acceleration | [Linux and KVM](./docs/linux-kvm.md) |
| Run without a window | [Headless emulator](./docs/headless.md), [macOS headless](./docs/macos-headless.md) |
| Prepare APK build tools | [Build Tools](./docs/build-tools.md) |
| Understand Gradle and APK builds | [Gradle APK lifecycle](./docs/gradle-apk-lifecycle.md) |
| Run tests | [Testing](./docs/testing.md) |
| Understand the tools | [Android ecosystem](./docs/android_ecosystem.md) |
| Understand virtualization | [Emulator, VM, and Docker](./docs/android_emulator_vm_docker.md) |

Defaults are in [config/android.env](./config/android.env); runtime package IDs are in [config/packages.txt](./config/packages.txt). `config/build-packages.txt` lists the baseline Build Tools package as a reference; current scripts derive it from `ANDROID_BUILD_TOOLS_VERSION` and do not read that file. SDK migration, a smoke-test runner, and CI orchestration are outside this release. The [roadmap](./roadmap.md) describes planned work.

The documentation targets v0.4.3. `pyproject.toml` also declares package version `0.4.3`.
