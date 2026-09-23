# Desktop emulator lifecycle reference

Android Environment v0.4.1's desktop commands share [scripts/lib/emulator.sh](../scripts/lib/emulator.sh). This reference describes their current behavior. For usage, see the [emulator guide](./emulator.md); headless commands use a [separate library and workflow](./headless.md).

## Device selection

`get_emulator_serial` returns the first `adb devices` row whose serial begins with `emulator-` and whose state is `device`. It returns an empty string when no row matches.

Each helper discovers the serial again. None checks the AVD name, so start can reuse a different AVD, status prints the configured name rather than a verified name, and stop/reset can stop a different AVD. These commands are intended for one online emulator at a time.

## Shared functions

| Function | Behavior |
| --- | --- |
| `get_emulator_serial` | Print the first online emulator serial |
| `is_emulator_connected` | Return success if discovery produced a non-empty serial |
| `is_emulator_boot_completed` | Query `sys.boot_completed`, strip carriage returns, and compare with `1` |
| `wait_for_emulator_boot TIMEOUT INTERVAL` | Check readiness, sleep, and retry until the sleep budget is exhausted |

Source `common.sh` before `emulator.sh` when calling the wait helper directly; it uses the common logging functions. The wait budget excludes time spent in ADB calls and has no per-call timeout.

## Command behavior

| Command | Implementation |
| --- | --- |
| `emulator-start` | Check emulator, adb, and configured AVD; reuse an online emulator or launch; wait for boot |
| `emulator-wait` | Check adb and wait; does not launch |
| `emulator-status` | Print `STOPPED`, `BOOTING`, or `READY`; all are successful status-query results |
| `emulator-stop` | Send `emu kill` to the selected serial; poll every second for up to 30 sleep seconds |
| `emulator-reset` | Kill the selected emulator, wait for disconnection without a timeout, launch configured AVD with wiped data, then wait for boot |
| `clean` | Delete the configured AVD without stopping it first |

Start and reset redirect output to `emulator.log`, overwriting it on launch. If boot waiting fails, the script returns non-zero and leaves the background process running.

## Settings

Start reads `EMULATOR_NO_SNAPSHOT_LOAD` and `EMULATOR_NO_BOOT_ANIMATION`. When `true`, they add `-no-snapshot-load` and `-no-boot-anim`. Reset always uses both flags plus `-wipe-data`.

The default boot budget is 180 seconds, with a 2-second polling interval. These values come from `EMULATOR_BOOT_TIMEOUT_SECONDS` and `EMULATOR_BOOT_POLL_INTERVAL_SECONDS`.

The desktop helpers do not read `EMULATOR_PORT`, `EMULATOR_SERIAL`, `EMULATOR_STOP_TIMEOUT_SECONDS`, or `EMULATOR_POLL_INTERVAL_SECONDS`. See [configuration](./configuration.md) for how the headless workflow handles those declarations.

## Test coverage

Six [helper tests](../tests/test_emulator_lib.py) use fake ADB output to check discovery, boot properties, missing devices, and timeout behavior. They do not run the lifecycle entry points. The two [integration tests](../tests/test_emulator_integration.py) check AVD listing and a running emulator's boot property, but do not establish that both refer to the same AVD.
