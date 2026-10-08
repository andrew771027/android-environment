# macOS headless support — v0.4.3

The shared headless lifecycle was extended to macOS in v0.4.2 and remains available in v0.4.3. The launcher calls [check_acceleration.sh](../scripts/check_acceleration.sh) instead of directly requiring Linux/KVM. The ADB readiness and AVD identity checks remain shared across platforms.

## Platform behavior

| Host | Acceleration check | System-image ABI |
| --- | --- | --- |
| macOS Intel | `emulator -accel-check`, using Hypervisor.Framework | `x86_64` |
| macOS Apple Silicon | `emulator -accel-check`, using Hypervisor.Framework | `arm64-v8a` |
| Linux x86_64 | Linux host check, `/dev/kvm` existence and read/write access, `emulator -accel-check` | `x86_64` |
| Linux ARM64 | Rejected by the current KVM host check | Provisioning maps to `arm64-v8a`, but headless launch is not supported by that check |
| Other OS | Rejected by the shared acceleration script | Unsupported provisioning mapping |

Image selection comes from [platform.sh](../scripts/lib/platform.sh). The macOS acceleration branch prints the architecture but does not independently validate it. These mappings describe implementation; they do not establish that every host has been tested.

macOS does not use `/dev/kvm`. `make kvm-check` remains Linux-only. Use the shared command:

```bash
make acceleration-check
```

For detailed macOS diagnostics, run `emulator -accel-check` directly. The helper suppresses the emulator's output and checks its exit status.

## Provision and launch

Complete [macOS setup](./macos.md), then run from the repository root in your terminal:

```bash
make install-sdk
make create-avd
make validate
make acceleration-check
make headless-start
```

Defaults are API 36, the `google_apis` image, AVD `cookbook_pixel_api_36`, and hardware profile `pixel_7`. A differently named Android Studio AVD does not satisfy the configured AVD name. If creation reports a missing image, run `make install-sdk` and retry `make create-avd`.

Startup rejects any `emulator-*` entry in the ADB list, including offline entries. It uses port 5554, serial `emulator-5554`, and these fixed flags:

```bash
emulator \
  -avd cookbook_pixel_api_36 \
  -port 5554 \
  -no-window \
  -no-audio \
  -no-boot-anim \
  -no-snapshot
```

The AVD name comes from configuration. The launcher does not specify `-gpu`. It starts with `nohup`, redirects input from `/dev/null`, and overwrites `artifacts/headless-emulator.log` on each launch.

Startup waits for ADB state `device` and `sys.boot_completed=1`, then verifies the AVD name. Success prints:

```text
READY: cookbook_pixel_api_36 (emulator-5554)
```

The default polling budget is 180 seconds; individual ADB call durations are additional. A timeout or identity mismatch exits non-zero and does not automatically stop the emulator.

## Status and shutdown

```bash
make headless-status
adb devices
```

A ready device should appear as `emulator-5554 device`. `STOPPED` means the target serial is absent from a successful ADB listing. `BOOTING or OFFLINE` means it is listed but not ready. A failed `adb devices` command causes status to report an error and exit 1.

To request shutdown:

```bash
make headless-stop
make headless-status
```

Stop checks readiness and AVD identity before sending `emu kill`. It does not wait for disconnection and refuses to stop an unready or differently named device. See [headless operation](./headless.md) for all status outputs and shutdown limitations.

## Troubleshooting

| Symptom | Action |
| --- | --- |
| `AVD missing: cookbook_pixel_api_36` | Run `make create-avd`; inspect `emulator -list-avds` |
| Acceleration unavailable | Run `emulator -accel-check` and check the image ABI against the host mapping |
| Empty ADB list after an earlier `READY` | Check status and the log; the process may have exited or been cleaned up by an external task runner |
| Boot timeout | Inspect the log and target boot property; startup does not clean up automatically |
| ADB-listing error | Check `adb` on `PATH`, server availability, and the original ADB error |
| Existing emulator | Stop it with its own workflow before launching this isolated instance |

Useful commands:

```bash
tail -n 100 artifacts/headless-emulator.log
adb -s emulator-5554 get-state
adb -s emulator-5554 shell getprop sys.boot_completed
adb -s emulator-5554 emu avd name
```

`nohup` does not provide supervision or prevent an external runner from terminating a process. Run startup in your own terminal when you need the local emulator to remain running. `READY` establishes readiness at the time of the check.

## Verification scope

On 2026-10-08, a macOS Intel launch created the baseline AVD and reached `READY`. A later check found no emulator process and an empty ADB list; persistence was not established. Apple Silicon, Linux/KVM, and a complete real start/status/stop sequence were not verified in that session.

On 2026-10-08, the user also reported both existing integration tests passing: baseline AVD listing and boot completion of the first online emulator. This result does not identify the launch mode, verify the running AVD identity, or cover shutdown. Integration output and duration were not supplied.

All five acceleration mock cases pass after correcting the macOS dispatch assertion spelling. The seven headless tests include status handling for failed ADB listing. See [testing](./testing.md) for full mock results and known helper issues.

v0.4.3 adds optional [Build Tools](./build-tools.md) without changing the headless launch flags. Smoke-test automation and CI remain future work; see the [roadmap](../roadmap.md).
