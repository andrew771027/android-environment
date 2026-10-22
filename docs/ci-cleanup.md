# CI and cleanup — v0.4.5

Version 0.4.5 provides a local CI runner that starts a headless emulator, checks Android runtime capabilities, and attempts to stop the process created by that run. It does not reuse an existing emulator.

## Run a complete cycle

Complete [setup](./setup.md), put `adb` and `emulator` on `PATH`, and ensure no emulator is listed by ADB:

```bash
adb devices
make ci-headless-smoke
```

The Make target invokes [ci_headless_smoke.sh](../scripts/ci_headless_smoke.sh):

```text
Create private PID directory and register traps
    → headless_start.sh: preflight, launch, record PID, wait for READY
    → smoke_test.sh: check six runtime capabilities
    → EXIT trap: clean up this run’s tracked process
    → return workflow or cleanup failure
```

The runner requires macOS emulator acceleration or Linux x86_64 with KVM. It uses port `5554` and serial `emulator-5554`. See [headless operation](./headless.md) for launch flags and preflight requirements.

| Command | Starts an emulator | Stops it automatically |
| --- | --- | --- |
| `make smoke` | No; checks an existing emulator | No |
| `make headless-smoke` | Yes; refuses existing emulators | No |
| `make ci-headless-smoke` | Yes; refuses existing emulators | Best effort, limited to this run’s tracked process |

## PID ownership

[headless_start.sh](../scripts/headless_start.sh) records `$!`, the background launcher PID, immediately after launch and before waiting for Android to boot.

Both headless start and stop use:

```bash
PID_FILE="${HEADLESS_PID_FILE:-${PROJECT_ROOT}/artifacts/headless-emulator.pid}"
```

A manual session uses `artifacts/headless-emulator.pid`. The CI wrapper creates a private directory under `${TMPDIR:-/tmp}` with `mktemp -d` and exports `HEADLESS_PID_FILE` pointing to `emulator.pid` inside it. CI does not read or overwrite a previous manual session’s PID file.

If preflight rejects an existing emulator, no private PID file is written. Cleanup prints:

```text
[INFO] No emulator launched by this run; skipping stop
```

The existing emulator remains running. If launch occurs but boot times out, the PID file already exists, so cleanup still attempts to stop the tracked process. Standalone `make headless-start` does not provide this automatic cleanup.

## Shutdown paths

| Path | Identification | Shutdown |
| --- | --- | --- |
| Manual `make headless-stop` | Requires target ADB serial, boot readiness, and matching AVD name | Requests `adb emu kill`, waits two seconds, then uses recorded PID as fallback |
| CI `headless_stop.sh --owned` | Reads the private PID file; if alive, checks process command for `emulator` or `qemu`, configured `-avd`, and `-port 5554` | Sends TERM directly, followed by KILL if needed; does not require ADB readiness |

The process helper allows a five-second TERM grace period in these stop paths. After KILL, it polls for up to five more seconds. It treats zombie processes as terminated when `ps` can report their state. These polling budgets do not impose a timeout on every external command.

Owned cleanup refuses a live PID whose command cannot be inspected or does not match. A PID file is a runtime ownership record, not permanent proof of identity: processes can exit and PIDs can be reused. The checks reduce accidental termination; they do not provide process-group supervision or track arbitrary descendants.

Manual stop returns early when the serial is absent from a successful ADB listing. It refuses unready or differently named devices before reaching PID fallback. It therefore cannot replace owned cleanup for a process that never becomes ADB-ready. The manual fallback relies on its recorded PID; the extra command-line validation belongs to the `--owned` path.

## Exit codes

Cleanup logs the two results separately:

```text
[INFO] Workflow exit code: 1
[INFO] Cleanup exit code: 0
```

This means startup or smoke failed, while cleanup completed successfully. Make still reports `Error 1`.

| Workflow result | Cleanup result | Wrapper exit code |
| --- | --- | --- |
| Success (`0`) | Success or no process to stop (`0`) | `0` |
| Failure (nonzero) | Any result | Original workflow failure |
| Success (`0`) | Failure (nonzero) | Cleanup failure |

`trap cleanup EXIT` covers normal completion and shell exits, including a command failure under `set -e`. INT is converted to exit `130`; TERM to exit `143`. The cleanup function disables its traps to avoid re-entry. Signal handling can be delayed while Bash waits for a foreground command. SIGKILL cannot be trapped, so this is best-effort cleanup rather than an unconditional guarantee.

## Logs and retained files

| File | Behavior |
| --- | --- |
| `artifacts/headless-emulator.log` | Emulator stdout/stderr; overwritten on each actual launch |
| `artifacts/headless-emulator.pid` | Default manual-session launcher PID |
| Temporary `android-ci.XXXXXX/emulator.pid` | CI-owned PID; directory removed after successful cleanup, retained after failure |

Failed cleanup logs `Retained PID file` with its path for inspection. That temporary directory is outside `artifacts/`; an artifact upload limited to `artifacts/` will not include it automatically. A rejected startup does not generate a new emulator log, so an existing log may belong to an earlier run.

## GitHub Actions status

The unit workflow is [.github/workflows/ci.yml](../.github/workflows/ci.yml). It triggers on pushes to all branches, pull requests, and manual dispatch after the workflow is available to GitHub.

It uses Python 3.14, installs the project's pytest version range, checks every Shell script under `scripts/`, and runs only tests marked `not integration`. The JUnit report is written to `artifacts/pytest.xml`. An `always()` artifact step attempts upload even after a failed test, with seven-day retention. The job does not install an SDK or start an emulator.

The configuration has been checked locally; a successful hosted run must be verified after pushing it. This branch defines only the `test` job. A separate `headless` job seen in another branch or an older run belongs to that run's workflow and commit. Real emulator CI requires separate SDK provisioning and an acceleration-capable runner. See the [roadmap](../roadmap.md).

## Test coverage

- [test_process.py](../tests/test_process.py): 13 cases for live/exited processes, PID parsing and unsafe values, TERM, KILL fallback, and EXIT trap behavior.
- [test_ci_cleanup.py](../tests/test_ci_cleanup.py): 7 cases for skipping stop before launch, cleaning up after launch failure, success, cleanup-failure propagation, preserving the original failure, rejecting an unrelated live process, and stopping a simulated emulator without ADB readiness.

Wrapper tests substitute start, stop, and smoke scripts. Process tests create ordinary temporary host processes, not Android emulators. They do not establish that every real emulator command line will match the ownership checks or verify a complete real start/smoke/stop cycle. See [testing](./testing.md) for recorded results.
