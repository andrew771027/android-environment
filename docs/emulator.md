# Use the Android Emulator

This guide covers desktop emulator operation in Android Environment v0.4.1. Complete [setup](./setup.md) first. For Linux without a display, use the [headless workflow](./headless.md).

An AVD stores a virtual device's configuration and user data. The Emulator is the host program that runs it. The default AVD is `cookbook_pixel_api_36`, with a `pixel_7` hardware profile and an Android 16 / API 36 Google APIs image.

## Create and inspect the AVD

```bash
make create-avd
emulator -list-avds
```

The command checks the system image and reuses an existing AVD with the configured name. It does not repair an existing AVD's configuration. To inspect available profiles and packages:

```bash
avdmanager list device -c
sdkmanager --list | grep 'system-images;android-36'
```

## Start and wait

```bash
make emulator-start
```

Start checks the required tools and configured AVD. It then reuses the first online emulator or launches the configured AVD, and waits until `sys.boot_completed` is `1`.

Keep only one emulator online with this workflow. The desktop helpers do not verify that an existing emulator is the configured AVD. An offline or not-yet-listed process may not be detected, so inspect the process and log before repeating a failed start.

For a manual launch:

```bash
emulator -avd cookbook_pixel_api_36
```

This command runs in the foreground and does not perform the repository's readiness check. In another terminal, run:

```bash
make emulator-wait
```

An ADB state of `device` means the ADB connection is available; Android may still be booting.

## Inspect the running device

```bash
make emulator-status
adb devices
```

| State | Meaning |
| --- | --- |
| `STOPPED` | No online `emulator-*` entry was found |
| `BOOTING` | An online emulator exists, but boot completion is not `1` |
| `READY` | An online emulator reports boot completion as `1` |

`STOPPED` does not rule out an offline or unlisted process. The status command can return success for all three states.

Use a serial from `adb devices` when issuing device commands:

```bash
adb -s emulator-5554 shell getprop ro.product.model
adb -s emulator-5554 shell getprop ro.build.version.release
adb -s emulator-5554 shell getprop ro.build.version.sdk
```

For the default system image, the SDK property should be `36`. The desktop workflow may select a serial other than `emulator-5554`.

## Stop

```bash
make emulator-stop
```

Stop sends `emu kill` to the first online emulator and waits up to 30 polling seconds for no online emulator to remain. If none is online at the start, it returns successfully without sending a shutdown request.

To target a specific emulator manually:

```bash
adb -s emulator-5554 emu kill
```

## Reset or delete

**Reset removes installed apps and user settings from the configured AVD.**

```bash
make emulator-reset
```

Reset stops the first online emulator, waits for disconnection, then starts the configured AVD with `-wipe-data -no-snapshot-load -no-boot-anim`. The disconnection wait has no timeout.

To delete the configured AVD, stop it first, then run:

```bash
make clean
```

Cleanup deletes only the configured AVD. It does not stop a running process or remove SDK packages.

## Logs and troubleshooting

Desktop start and reset write emulator output to `emulator.log` in the repository root. Each launch overwrites it. A boot timeout leaves the background process running.

| Problem | Check |
| --- | --- |
| AVD missing | Run `emulator -list-avds`, then `make create-avd` |
| Package missing | Run `make install-sdk` and `make validate` |
| Slow startup or acceleration error | Run `emulator -accel-check`; verify the host/image ABI |
| Boot timeout | Inspect `emulator.log` and `adb devices` before retrying |
| Wrong device receives an ADB command | Pass `-s SERIAL`; keep one emulator online for repository lifecycle commands |

For implementation details, see [lifecycle reference](./emulator-lifecycle.md). For commands to run the two existing SDK/emulator tests, see [testing](./testing.md).
