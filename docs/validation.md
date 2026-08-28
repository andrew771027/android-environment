# Environment Validation

Android Environment v0.2 provides a quick diagnostic and a strict validator.

## Quick Diagnostic

```bash
make doctor
```

The doctor checks whether `java`, `sdkmanager`, `avdmanager`, `adb`, `fastboot`, and `emulator` are on `PATH`. It also prints `ANDROID_HOME`, available AVDs, and ADB devices. It is informational and does not fail merely because a tool is missing.

## Strict Validation

```bash
make validate
```

The validator checks:

1. Host OS, CPU, and compatible image ABI.
2. The resolved `ANDROID_HOME` value and SDK directory.
3. Java and Android command-line tools.
4. Required SDK packages.
5. The configured AVD.
6. Connected devices as additional information.

It ends with `PASS=<count>` and `FAIL=<count>`. Any failure produces exit status `1`, making it suitable for automation. A running emulator is not required, but the configured AVD must exist.

## Recommended Workflow

```bash
make bootstrap
make install-sdk
make create-avd
make validate
make emulator
```

After launch, check runtime health separately:

```bash
adb wait-for-device
adb devices
adb shell getprop sys.boot_completed
adb shell getprop ro.build.version.sdk
```

After boot, expected values are `1` for `sys.boot_completed` and `36` for the SDK level.

## Interpreting Failures

| Failure | Action |
| --- | --- |
| Unsupported host | See [architecture_detection.md](./architecture_detection.md) |
| SDK directory missing | Install Command-Line Tools or correct/override `ANDROID_HOME` |
| Tool missing | Add the appropriate SDK directory to `PATH` |
| Package missing | Run `make install-sdk` |
| AVD missing | Run `make create-avd` |

If `sdkmanager` is missing, strict validation stops because it cannot inspect packages. Use `make doctor` first for a partially configured workstation.

Provisioning validation does not guarantee acceleration, Android boot, or physical-device authorization. Check those with `emulator -accel-check`, `adb devices`, and the boot-completed property. See [emulator.md](./emulator.md).
