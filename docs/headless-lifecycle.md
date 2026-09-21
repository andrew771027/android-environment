# Headless emulator lifecycle (v0.4)

## Why process != readiness

`emulator` starts a process; `adb devices` may show `device` before Android boot finishes. Readiness is checked by `sys.boot_completed=1`, followed by verifying the AVD name using `adb -s emulator-5554 emu avd name`.

```text
Preflight -> start own process -> adb device -> boot complete -> identity -> smoke
   |                                                        |             |
   +---------------------- failure -------------------------+-------------+
                               |
                        EXIT cleanup (owned PID)
```

## Run

```bash
make install-sdk
make create-avd
make kvm-check
make headless-smoke
```

`run_headless_smoke.sh` uses `-no-window -no-audio -no-boot-anim -no-snapshot -gpu swiftshader_indirect` and reserved port 5554. Headless is not a performance benchmark. Adjust the graphics flag if unsupported by your installed emulator version.

## Isolation contract

One managed emulator per runner. If *any* emulator is already listed by adb, exit without stopping it. The script only cleans up the emulator PID it launched and uses serial `emulator-5554` for ADB. Do not run concurrently on a shared workstation or change `EMULATOR_PORT` alone.

## Cleanup

An EXIT trap calls `adb -s emulator-5554 emu kill`, waits a bounded period, then TERM/KILL only the process PID it started. The original exit status is preserved. Logs remain at `artifacts/emulator.log` after launch and are uploaded even if CI fails; preflight failures may occur before the log exists.

## Timeout

`EMULATOR_BOOT_TIMEOUT_SECONDS` and poll interval are positive integers. The boot loop checks a SECONDS-based deadline and returns non-zero when readiness fails. Individual adb calls have no independent timeout, so a stalled adb call can exceed this budget. The CI job has a 35-minute timeout.

## Known limits

- This is a *one-AVD isolated CI* implementation; multi-emulator reservation and process-tree cleanup are later work.
- On Linux hosts without KVM access, fail fast rather than asserting the emulator is ready.
- A persistent host should use an explicit reservation/lock before launching; this tutorial assumes an ephemeral runner.
