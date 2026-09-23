# Run a headless emulator

Android Environment v0.4.1 provides `headless-start`, `headless-status`, and `headless-stop` for a single emulator on Linux x86_64. The emulator runs without a window and remains accessible through ADB.

## Before you start

Complete [Linux setup](./linux.md), then check provisioning and KVM:

```bash
make validate
make kvm-check
adb devices
```

The configured AVD must exist, port 5554 must be available, and ADB must list no `emulator-*` entries. Start rejects existing entries even if they are offline. Physical devices do not trigger this check.

The scripts use **port 5554** and **serial `emulator-5554`**. Changing `EMULATOR_PORT` or `EMULATOR_SERIAL` in `config/android.env` does not change this behavior. See [configuration](./configuration.md).

## Start

```bash
make headless-start
```

The script checks `adb`, `emulator`, Linux/KVM, AVD existence, and the ADB device list before launching. It runs this emulator command in the background with `nohup`:

```bash
emulator \
  -avd cookbook_pixel_api_36 \
  -port 5554 \
  -no-window \
  -no-audio \
  -no-boot-anim \
  -no-snapshot \
  -gpu software
```

The AVD name comes from configuration. The remaining flags are fixed in the script. Software graphics does not remove the KVM requirement.

Output goes to `artifacts/headless-emulator.log`, which is overwritten on each launch. Standard input is redirected from `/dev/null`. The script prints the launcher PID but does not store a PID file or supervise the process.

Start waits for both of these conditions:

1. `adb -s emulator-5554 get-state` returns `device`.
2. `sys.boot_completed` is `1`.

It then checks that `adb -s emulator-5554 emu avd name` matches `AVD_NAME`. Success prints:

```text
READY: cookbook_pixel_api_36 (emulator-5554)
```

The default boot wait is 180 polling seconds, with a check every second and one final check at the deadline. ADB command duration is additional; this is not a strict wall-clock timeout.

If boot times out or the AVD name does not match, start exits non-zero. It leaves the emulator process running for inspection.

## Check status

```bash
make headless-status
```

| Output | Meaning | Exit status |
| --- | --- | --- |
| `STOPPED` | The target serial is absent from the ADB list | 0 |
| `BOOTING or OFFLINE: emulator-5554` | The serial is listed but does not pass both readiness checks | 0 |
| `READY: ...` | The device is ready and its AVD name matches | 0 |
| `UNKNOWN AVD: ...` | The device is ready but its AVD name differs | 1 |

A successful status command does not necessarily mean Android is ready. ADB visibility also does not prove whether an unlisted emulator process exists. These status meanings assume ADB is installed and working; the status script has no separate tool check.

## Stop

```bash
make headless-stop
```

If the serial is absent from the ADB list, the command reports `Already stopped.` Otherwise, it requires boot readiness and the configured AVD name before sending `adb -s emulator-5554 emu kill`.

The command prints `Stop requested` and exits without waiting for disconnection. Check again with:

```bash
make headless-status
adb devices
```

It refuses to stop an offline, booting, or differently named AVD. There is no forced-kill fallback. For a failed start, inspect the log and identify the process before handling it manually.

## Troubleshoot

| Symptom | Check |
| --- | --- |
| Missing SDK tool or AVD | Run `make doctor` and `make validate` |
| KVM error | Follow [Linux/KVM troubleshooting](./linux-kvm.md) |
| Existing emulator error | Run `adb devices`; stop the existing emulator using its own workflow |
| Boot timeout or offline state | Read the log and inspect the target serial with the commands below |
| Unexpected AVD name | Verify which AVD owns port 5554; the scripts will not stop a different AVD |

```bash
tail -n 100 artifacts/headless-emulator.log
adb -s emulator-5554 get-state
adb -s emulator-5554 shell getprop sys.boot_completed
adb -s emulator-5554 emu avd name
```

## Implementation and tests

The entry points are [headless_start.sh](../scripts/headless_start.sh), [headless_status.sh](../scripts/headless_status.sh), and [headless_stop.sh](../scripts/headless_stop.sh). They share [headless.sh](../scripts/lib/headless.sh).

Six [mock tests](../tests/test_headless.py) cover device listing, boot readiness, wait success/timeout, and AVD-name parsing. They do not run the entry-point scripts or exercise real Linux/KVM. There is no smoke-test runner, automatic timeout cleanup, or CI workflow in this release. See [testing](./testing.md) for the recorded checks.
