# Fastboot visibility — v0.5.1

ADB checks communicate with Android through `adbd`. Fastboot checks communicate with a device exposing a supported Fastboot interface, such as bootloader Fastboot or fastbootd. Run the checks separately for the device's current mode.

## Check a device

Install SDK Platform Tools and put `fastboot` on `PATH`. Manually place the device in its supported Fastboot mode, then run:

```bash
fastboot devices
make fastboot-device-check
make fastboot-device-check SERIAL=ABC123
```

The implemented Make target is `fastboot-device-check`. The Makefile also lists `fastboot-check` under `.PHONY`, but that name has no recipe and does not perform a check.

You can invoke the script directly:

```bash
./scripts/fastboot_check.sh ABC123
DEVICE_SERIAL=ABC123 ./scripts/fastboot_check.sh
```

A nonempty first argument takes precedence over `DEVICE_SERIAL`; an empty argument falls back to it. The script does not read `config/android.env`.

| Input | Behavior |
| --- | --- |
| No selected serial | Print all discovered serials; succeed if at least one is listed |
| Selected serial present | Succeed and report that serial |
| Selected serial missing | Exit 1 with `Expected Fastboot serial not found` |
| No devices | Exit 1 with `No Fastboot device found` |
| Missing command | Exit 1 with `fastboot not found` |

Unlike automatic ADB selection, multiple Fastboot devices are accepted when no serial is specified. The list helper prints the first field of each nonempty `fastboot devices` row; it does not validate the mode field or identify hardware properties.

## Scope and verification

The script only calls `fastboot devices`. It does not initiate mode transitions, wait for a device, reboot, unlock, flash, erase, or format. A successful result proves visibility to this command, not flashing readiness or ADB authorization.

Fake-tool tests cover presence and absence, explicit serial matching, argument precedence, environment fallback, and script exit messages. Real hardware and mode transitions remain unverified. See [physical devices](./physical-device.md) for Android-mode checks and [testing](./testing.md) for verification results.
