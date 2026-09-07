# Android Emulator Guide

This document explains the Android Virtual Device (AVD) lifecycle used by Android Environment v0.2.

The goal is not only to launch an emulator, but to understand the relationship between:

```text
sdkmanager
    ↓
system image
    ↓
avdmanager
    ↓
AVD configuration
    ↓
emulator process
    ↓
Android boot
    ↓
adbd
    ↓
adb
    ↓
Android Cookbook
```

## 1. Emulator vs AVD

These are different concepts.

### Android Emulator

The emulator is the executable program that runs a virtual Android device.

```bash
emulator
```

### Android Virtual Device

An AVD is a configuration describing a virtual device, such as:

- device profile
- Android system image
- storage
- screen/device characteristics
- snapshots

AVDs are created and managed from the command line with `avdmanager`.

Think of it as:

```text
emulator = execution engine
AVD      = virtual device configuration
```

## 2. v0.2 Baseline

```text
AVD name:    cookbook_pixel_api_36
Android:     Android 16
API:         36
Device:      pixel_7
```

The exact system-image ABI depends on the host architecture and package availability.

## 3. Inspect Available Device Profiles

```bash
avdmanager list device
```

You can search for Pixel profiles:

```bash
avdmanager list device | grep -i pixel
```

Do not assume a specific profile ID exists on every SDK installation without checking first.

## 4. Inspect Available System Images

```bash
sdkmanager --list
```

Filter Android 16 images:

```bash
sdkmanager --list | grep 'system-images;android-36'
```

A package name follows a structure similar to:

```text
system-images;android-36;google_apis;<abi>
```

The repository should select an ABI compatible with the host CPU whenever possible.

## 5. Create an AVD

Preferred repository command:

```bash
make create-avd
```

Conceptually, the script performs something like:

```bash
echo "no" | avdmanager create avd \
  --name cookbook_pixel_api_36 \
  --package "$SYSTEM_IMAGE" \
  --device "$AVD_DEVICE"
```

The script checks the required tools and system image, then skips creation when the configured AVD already exists:

```text
AVD does not exist
    ↓
create it

AVD already exists
    ↓
do not create a duplicate
```

## 6. List AVDs

```bash
emulator -list-avds
```

or:

```bash
avdmanager list avd
```

Expected:

```text
cookbook_pixel_api_36
```

## 7. Start an AVD

Basic command:

```bash
emulator -avd cookbook_pixel_api_36
```

Equivalent form:

```bash
emulator @cookbook_pixel_api_36
```

Repository command:

```bash
make emulator-start
```

## 8. Start Without Loading an Old Snapshot

By default, `start_emulator.sh` passes both `-no-snapshot-load` and `-no-boot-anim`. The snapshot option can also be used directly:

```bash
emulator \
  -avd cookbook_pixel_api_36 \
  -no-snapshot-load
```

This avoids loading an earlier emulator snapshot at startup while still keeping the setup simple.

`make emulator-reset` implements user-data reset with `-wipe-data`; it also passes `-no-snapshot-load` and `-no-boot-anim`. This removes installed apps and user settings from the configured AVD.

## 9. Headless Emulator

Useful on remote Linux workstations or CI:

```bash
emulator \
  -avd cookbook_pixel_api_36 \
  -no-window \
  -no-audio
```

Headless mode is optional in v0.2. First make the normal interactive emulator reliable.

## 10. Check Hardware Acceleration

```bash
emulator -accel-check
```

Hardware acceleration is important for emulator performance.

General architecture rule:

```text
x86_64 host
    ↓
x86/x86_64 compatible system image

ARM64 host
    ↓
arm64-v8a compatible system image
```

Using an incompatible guest/host architecture can prevent the expected VM acceleration.

## 11. Understand the Emulator Process

After launch:

```bash
ps aux | grep emulator
```

The emulator is a host process running a virtual Android device.

Conceptually:

```text
macOS/Linux host
│
├── emulator process
│    │
│    └── virtual Android OS
│          │
│          └── adbd
│
└── adb client/server
       │
       └──────── connects to adbd
```

This is useful preparation for later Device Test Runner lifecycle work because the emulator itself has a start/ready/stop lifecycle.

## 12. Wait for ADB

Immediately after starting the emulator, Android may not yet be ready.

First wait for a device transport:

```bash
adb wait-for-device
```

Then inspect:

```bash
adb devices
```

Example:

```text
List of devices attached
emulator-5554    device
```

But `adb devices` reporting `device` does not always mean Android has completed its full boot sequence.

## 13. Wait for Android Boot Completion

Query:

```bash
adb shell getprop sys.boot_completed
```

Typical completed state:

```text
1
```

The repository provides a bounded polling command that does not launch an emulator:

```bash
make emulator-wait
```

It uses a 180-second configured wait budget and a 2-second polling interval. `make emulator-start` already performs this wait. See [lifecycle implementation](./emulator-lifecycle.md) for timing and device-selection limitations.

For comparison, this manual shell loop has no timeout and assumes one attached device:

```bash
adb wait-for-device

until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
  sleep 2
done

echo "Android boot completed"
```

This runtime boot check complements the v0.2 provisioning validator, which does not require a running emulator.

## 14. Verify Device Information

```bash
adb shell getprop ro.product.model
adb shell getprop ro.product.device
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.sdk
```

This verifies that Android Cookbook is talking to the expected target.

## 15. Multiple Devices

If both an emulator and physical Pixel are connected:

```bash
adb devices
```

Example:

```text
emulator-5554    device
1234567890ABC    device
```

A plain command such as:

```bash
adb shell
```

becomes ambiguous.

Specify the target:

```bash
adb -s emulator-5554 shell
```

or:

```bash
adb -s 1234567890ABC shell
```

This becomes important later when Android Cookbook and Device Test Runner support multiple targets.

## 16. Stop the Emulator

Repository command (selects the first online emulator):

```bash
make emulator-stop
```

To explicitly select a serial, use:

```bash
adb -s emulator-5554 emu kill
```

If only one emulator exists, you can determine its serial first:

```bash
adb devices
```

Then stop that specific emulator.

Avoid treating `kill -9` as the normal lifecycle mechanism. Force-killing a process should be a fallback for a stuck emulator, not the standard shutdown path.

## 17. Delete an AVD

```bash
avdmanager delete avd \
  --name cookbook_pixel_api_36
```

Repository command:

```bash
make clean
```

The cleanup script runs `avdmanager delete avd` for `AVD_NAME`; it does not remove the SDK or stop a running emulator first. Stop the emulator before deleting its AVD.

## 18. Cold Boot / State Reset

As the environment evolves, there are several reproducibility levels:

```text
Level 1
Normal startup

Level 2
Do not load previous snapshot

Level 3
Cold boot

Level 4
Wipe AVD user data

Level 5
Delete and recreate AVD
```

Choose the lowest-cost level that provides the reproducibility your test needs.

For early Cookbook work, normal startup or `-no-snapshot-load` is usually sufficient.

For automated validation later, explicit reset policy becomes important.

## 19. Troubleshooting

### No AVDs listed

```bash
emulator -list-avds
avdmanager list avd
```

If empty, recreate the AVD:

```bash
make create-avd
```

### System image missing

```bash
sdkmanager --list | grep 'system-images;android-36'
```

Then install the system image configured for the host.

### Emulator starts but ADB does not see it

```bash
adb kill-server
adb start-server
adb devices
```

Then inspect the emulator output for startup errors.

### Emulator is very slow

```bash
emulator -accel-check
```

Confirm hardware virtualization and host/image architecture compatibility.

### Boot never completes

Check:

```bash
adb devices
adb shell getprop sys.boot_completed
adb logcat
```

If the AVD state is corrupted, try a clean boot or recreate the project AVD.

### Graphics problems

Try updating the emulator package first:

```bash
sdkmanager --update
```

If debugging a graphics-specific problem, Android Emulator also exposes command-line GPU options. Keep machine-specific overrides out of the default v0.2 configuration unless required.

## 20. Implemented Lifecycle Commands

| Command | Script | Behavior |
| --- | --- | --- |
| `make emulator-start` | `start_emulator.sh` | Validate tools/AVD, launch if needed, wait for boot |
| `make emulator-wait` | `wait_for_emulator.sh` | Poll boot readiness without starting a process |
| `make emulator-status` | `emulator_status.sh` | Print STOPPED, BOOTING, or READY |
| `make emulator-stop` | `stop_emulator.sh` | Send `emu kill`, then wait for disconnection |
| `make emulator-reset` | `reset_emulator.sh` | Stop an online emulator, wipe configured AVD data, restart and wait |

The shared implementation is [`scripts/lib/emulator.sh`](../scripts/lib/emulator.sh). Device discovery selects the first online emulator, without checking its AVD name. A process that is offline or not yet visible to ADB is not detected as connected. Use one emulator for the repository workflow; use explicit `adb -s SERIAL` commands when working with multiple devices.

See [lifecycle details](./emulator-lifecycle.md) and [test coverage and troubleshooting](./testing.md).

## 21. Cookbook Handoff

When all three commands succeed:

```bash
emulator -list-avds
adb devices
adb shell getprop sys.boot_completed
```

and the result is effectively:

```text
cookbook_pixel_api_36 exists
        ↓
emulator is connected
        ↓
Android boot_completed = 1
```

then Android Environment's job is complete and Android Cookbook can begin.

Recommended first Cookbook recipe:

```text
Recipe 001 — Device Discovery

adb devices
adb get-state
adb shell getprop ro.product.model
adb shell getprop ro.build.version.sdk
```
