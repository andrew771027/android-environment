# Validate the environment

Use these checks at different stages of Android Environment v0.4.1 setup:

| Command | Checks | Requires a running emulator? |
| --- | --- | --- |
| `make doctor` | Tool availability, SDK environment variable, AVD and device lists | No |
| `make validate` | Host mapping, SDK directory, tool commands, package IDs, and AVD existence | No |
| `make kvm-check` | Linux x86_64, KVM device access, emulator acceleration | No |
| `make emulator-wait` | Boot completion of the first online emulator | Yes |
| `make headless-status` | ADB visibility, readiness, and AVD identity at `emulator-5554` | No; reports absence |

## Inspect an incomplete setup

```bash
make doctor
```

The doctor prints whether `java`, `sdkmanager`, `avdmanager`, `adb`, `fastboot`, and `emulator` are on `PATH`. It also prints `ANDROID_HOME`, available AVDs, and connected devices. Missing tools do not cause the doctor to fail; use it for diagnosis rather than as an automation gate.

## Validate provisioning

```bash
make validate
```

The validator checks the SDK directory, supported host mapping, six tool commands, four SDK package IDs, and the configured AVD name. The packages are Platform Tools, Emulator, `ANDROID_PLATFORM`, and the selected system image.

On normal completion, it prints `PASS=<count>` and `FAIL=<count>`. A failed check causes exit status 1. If `sdkmanager` is missing, validation exits early without the final counts.

The validator prints connected devices for information. An empty device list is not a provisioning failure. It does not compare package revisions, inspect an existing AVD's image configuration, test acceleration, or confirm Android boot completion.

## Fix a provisioning failure

| Failure | Action |
| --- | --- |
| Unsupported host | Check [architecture detection](./architecture_detection.md) |
| SDK directory missing | Correct `ANDROID_HOME` and install Command-Line Tools |
| Tool missing | Check the tool's installation and `PATH` |
| Package missing | Run `make install-sdk` |
| AVD missing | Run `make create-avd` |

All commands found on `PATH` should belong to the SDK selected by `ANDROID_HOME`; validation does not enforce that relationship.

## Check runtime readiness

Start using the [desktop](./emulator.md) or [headless](./headless.md) workflow. After successful boot, inspect the target device:

```bash
adb devices
adb -s emulator-5554 shell getprop sys.boot_completed
adb -s emulator-5554 shell getprop ro.build.version.sdk
```

Replace the serial if the desktop workflow selected a different emulator. Expected values are `1` for boot completion and `36` for API level.

A status query may exit successfully while reporting stopped or booting. Use the start command's readiness result, or `make emulator-wait` for the desktop workflow, when a step must wait for Android.

The current tests do not exercise the provisioning validator end to end. See [test coverage](./testing.md).
