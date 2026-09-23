# Android Environment v0.4.1

Set up an Android SDK and emulator for Android Cookbook from the command line. Android Studio is optional.

Version 0.4.1 includes a Linux x86_64 headless workflow: start an emulator, check its boot state and AVD name, and request shutdown. The desktop workflow remains available on macOS and Linux.

## SDK target

| Component | Baseline |
| --- | --- |
| Android | Android 16 / API 36 |
| SDK Platform | `platforms;android-36` |
| System image | `google_apis`, with the ABI selected from the host architecture |
| AVD | `cookbook_pixel_api_36`, using the `pixel_7` profile |
| Command-Line Tools download | 22.0 / build 15859902 |
| Java | JDK 17 recommended |

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

For a desktop session:

```bash
make emulator-start
make emulator-status
```

For a Linux x86_64 host with KVM and no display:

```bash
make headless-start
make headless-status
```

Headless start runs the KVM check and refuses to launch while any emulator is listed by ADB. It uses port `5554` and serial `emulator-5554`. See [headless operation](./docs/headless.md) for logs, readiness checks, and shutdown behavior.

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
| `make create-avd` | Create the configured AVD if its name is not already listed |
| `make validate` | Check tools, package IDs, host mapping, and AVD existence |
| `make doctor` | Print tool, AVD, and device information |
| `make kvm-check` | Check Linux x86_64, KVM access, and emulator acceleration |
| `make emulator-start` | Launch the configured AVD or reuse the first online emulator; wait for boot |
| `make emulator-wait` | Wait for the first online emulator to finish booting |
| `make emulator-status` | Report `STOPPED`, `BOOTING`, or `READY` |
| `make emulator-stop` | Stop the first online emulator and wait for disconnection |
| `make emulator-reset` | Wipe the configured AVD's user data and start it |
| `make headless-start` | Launch on port 5554; wait for boot and verify the AVD name |
| `make headless-status` | Report the state and, when ready, identity of `emulator-5554` |
| `make headless-stop` | Request shutdown after checking boot readiness and AVD identity |
| `make devices` | Run `adb devices` |
| `make shell` | Run `adb shell` |
| `make unit-test` | Run tests that do not require a real SDK or emulator |
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

There are 16 mock tests and 2 integration tests. Integration tests require the baseline AVD and an already booted emulator:

```bash
python -m pytest -v -m integration tests
```

The mock suite passed during this documentation update. It does not establish that Linux/KVM or the complete headless lifecycle works on a real host. See [testing](./docs/testing.md) for the recorded result and coverage gaps.

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
| Run without a display | [Headless emulator](./docs/headless.md) |
| Run tests | [Testing](./docs/testing.md) |
| Understand the tools | [Android ecosystem](./docs/android_ecosystem.md) |
| Understand virtualization | [Emulator, VM, and Docker](./docs/android_emulator_vm_docker.md) |

Defaults are in [config/android.env](./config/android.env); package IDs are in [config/packages.txt](./config/packages.txt). SDK migration, a smoke-test runner, and CI orchestration are outside this release. The [roadmap](./roadmap.md) describes planned work.

The documentation targets v0.4.1. Python package metadata still declares `0.1.0`.
