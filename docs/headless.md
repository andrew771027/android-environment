# Run a headless emulator

Android Environment v0.4.5 provides `headless-start`, `headless-status`, and `headless-stop` for a single emulator on macOS or Linux x86_64 with KVM. The emulator runs without a window and remains accessible through ADB.

## Before you start

Complete [macOS setup](./macos.md) or [Linux setup](./linux.md), create the configured AVD, then check provisioning and acceleration:

```bash
make create-avd
make validate
make acceleration-check
adb devices
```

The configured AVD must exist, port 5554 must be available, and ADB must list no `emulator-*` entries. Start rejects existing entries even if they are offline. Physical devices do not trigger this check. A failed ADB listing aborts startup before launch.

The scripts use **port 5554** and **serial `emulator-5554`**. Changing `EMULATOR_PORT` or `EMULATOR_SERIAL` in `config/android.env` does not change this behavior. See [configuration](./configuration.md).

## Start

```bash
make headless-start
```

The script checks `adb`, `emulator`, platform acceleration, AVD existence, and the ADB device list before launching. On macOS, `check_acceleration.sh` uses the emulator acceleration check; on Linux, it delegates to the x86_64/KVM check. It runs this emulator command in the background with `nohup`:

```bash
emulator \
  -avd cookbook_pixel_api_36 \
  -port 5554 \
  -no-window \
  -no-audio \
  -no-boot-anim \
  -no-snapshot
```

The AVD name comes from configuration. The remaining flags are fixed in the script. The launcher does not specify `-gpu`; graphics selection is left to the emulator. Linux still requires KVM.

Output goes to `artifacts/headless-emulator.log`, which is overwritten on each launch. Standard input is redirected from `/dev/null`. The script prints the launcher PID and stores it in `artifacts/headless-emulator.pid`, or the path supplied through `HEADLESS_PID_FILE`. It does not supervise or restart the process. Run it from your terminal for a persistent local session; task runners may clean up background processes even when `nohup` is used.

Start waits for both of these conditions:

1. `adb -s emulator-5554 get-state` returns `device`.
2. `sys.boot_completed` is `1`.

It then checks that `adb -s emulator-5554 emu avd name` matches `AVD_NAME`. Success prints:

```text
READY: cookbook_pixel_api_36 (emulator-5554)
```

The default boot wait is 180 polling seconds, with a check every second and one final check at the deadline. ADB command duration is additional; this is not a strict wall-clock timeout.

If boot times out or the AVD name does not match, start exits non-zero. When invoked directly, it leaves the emulator process running for inspection. `make ci-headless-smoke` instead attempts to clean up the process started by that run.

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
| `ERROR: Unable to query ADB devices.` | `adb devices` failed; status cannot be determined | 1 |

A successful status command does not necessarily mean Android is ready. ADB visibility also does not prove whether an unlisted emulator process exists. The status script checks whether `adb devices` succeeds before interpreting the list. Later readiness failures are reported as `BOOTING or OFFLINE`; they are not separately classified as ADB errors.

## Stop

```bash
make headless-stop
```

If ADB listing fails, stop exits non-zero without reporting that the emulator is stopped. If the serial is absent from a successful ADB list, the command reports `Already stopped.` Otherwise, it requires boot readiness and the configured AVD name before sending `adb -s emulator-5554 emu kill`.

After requesting ADB shutdown, the command waits two seconds and checks the recorded launcher PID. If that process remains alive, it sends TERM, waits up to five polling seconds, then uses KILL and waits up to five more polling seconds. It removes the PID file on successful cleanup. This checks the tracked process; it does not poll ADB until disconnection. Check again with:

```bash
make headless-status
adb devices
```

It refuses to stop an offline, booting, or differently named AVD. The manual command reaches its PID fallback only after readiness and AVD validation. If the target is absent from ADB, it returns early; it does not clean up an unlisted process or remove the PID file. For a failed manual start, inspect the log and identify the process before handling it manually.

## Troubleshoot

| Symptom | Check |
| --- | --- |
| Missing SDK tool or AVD | Run `make doctor` and `make validate`; for a missing AVD, run `make create-avd` |
| macOS acceleration error | Run `emulator -accel-check`; see [macOS headless](./macos-headless.md) |
| `STOPPED` or an empty `adb devices` list | No target serial is visible; start from your terminal and inspect the log if it exits |
| Unable to query ADB devices | Check `adb` on `PATH` and the error printed by `adb devices` |
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

Nine [mock tests](../tests/test_headless.py) cover device listing, boot readiness, wait success/timeout, AVD-name parsing, and ADB-listing failure in the start, status, and stop entry points. They do not exercise real acceleration or the complete start/stop entry points. Use `make smoke` after startup or `make headless-smoke` to start and check runtime capabilities. Neither command stops the emulator. See [smoke test](./smoke-test.md). Version 0.4.5 adds `make ci-headless-smoke` with a private PID file and `headless_stop.sh --owned` cleanup. This path validates the process command and can stop its tracked process even before Android becomes ready. It uses TERM/KILL directly rather than ADB shutdown. See [CI and cleanup](./ci-cleanup.md). See [testing](./testing.md) for the recorded checks.
