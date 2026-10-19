# Android Environment v0.4.5 — CI and Cleanup

## Overview

Android Environment v0.4.5 introduces two related capabilities:

```text
Continuous Integration

and

Reliable Runtime Cleanup
```

Previous versions established the following lifecycle:

```text
Provision
   |
   v
Start Emulator
   |
   v
Wait for READY
   |
   v
Smoke Test
```

v0.4.5 extends the lifecycle:

```text
Provision
   |
   v
Start Emulator
   |
   v
Track PID
   |
   v
Smoke Test
   |
   v
Success / Failure / Signal
   |
   v
Cleanup
   |
   v
Artifacts
```

The key goal is:

> A test environment should clean up resources even when execution does not finish normally.

---

## PID Tracking

When the Android Emulator is started as a background process:

```bash
nohup emulator ... &
```

Bash exposes the PID of the most recently started background process through:

```bash
$!
```

The launcher stores this PID in:

```text
artifacts/headless-emulator.pid
```

Example:

```text
37978
```

This creates an ownership relationship:

```text
launcher
   |
   v
PID 37978
   |
   v
Emulator process
```

Cleanup no longer needs to search broadly for an arbitrary Emulator process.

---

## Graceful Shutdown

The preferred shutdown mechanism remains:

```bash
adb -s emulator-5554 emu kill
```

This allows the Android Emulator to perform its normal shutdown.

If the Android-aware shutdown fails or the process remains alive, v0.4.5 falls back to operating-system process management.

---

## TERM and KILL

The fallback sequence is:

```text
Process alive
     |
     v
SIGTERM
     |
     v
Wait for grace period
     |
     v
Still alive?
   /       \
 no         yes
 |           |
DONE       SIGKILL
```

`SIGTERM` requests termination.

It gives the process an opportunity to shut down normally.

`SIGKILL` forcibly terminates the process and cannot be handled or ignored by the target process.

Therefore `SIGKILL` is used only as a final fallback.

---

## Trap

The CI wrapper registers an EXIT trap:

```bash
trap cleanup EXIT
```

This means that when the script exits, the cleanup function is executed.

Examples include:

```text
normal success
test failure
set -e failure
explicit exit
SIGINT converted to exit
SIGTERM converted to exit
```

The wrapper also handles:

```bash
trap 'exit 130' INT
trap 'exit 143' TERM
```

Both paths eventually trigger the EXIT trap.

---

## Important Limitation

SIGKILL cannot be trapped.

Therefore:

```bash
trap cleanup KILL
```

cannot provide reliable cleanup.

The cleanup strategy should instead combine:

```text
application-level cleanup

+

CI-level cleanup

+

process fallback
```

No single cleanup mechanism should be assumed to handle every possible termination scenario.

---

## CI Wrapper

The runtime wrapper is:

```text
scripts/ci_headless_smoke.sh
```

Its lifecycle is:

```text
register trap
      |
      v
start Emulator
      |
      v
run Smoke Test
      |
      v
script exits
      |
      v
EXIT trap
      |
      v
stop Emulator
```

The same cleanup runs for successful and failed smoke tests.

---

## GitHub Actions

The default CI workflow runs lightweight checks:

```text
checkout
   |
setup Python
   |
Shell syntax validation
   |
pytest
   |
artifact upload
```

The default workflow intentionally does not provision a real Android Emulator.

This keeps pull-request CI:

```text
fast
deterministic
cheap
easy to debug
```

Real Emulator CI can run separately on a KVM-capable runner.

---

## Artifacts

CI artifacts are stored under:

```text
artifacts/
```

Examples include:

```text
pytest.xml
headless-emulator.log
headless-emulator.pid
```

Runtime PID files are useful during execution but should not be interpreted as valid process state after a CI machine has disappeared.

The PID file is therefore primarily a runtime ownership mechanism.

---

## Artifact Upload

GitHub Actions uploads the artifact directory after tests.

The upload step runs even when previous test steps fail.

This is important because failure logs are often more valuable than logs from successful executions.

Conceptually:

```text
TEST
 |
 +-- PASS ----+
 |            |
 +-- FAIL ----+
              |
              v
        Upload Artifacts
```

---

## Cleanup Is Not Test Logic

Cleanup should remain independent from Smoke Test assertions.

The Smoke Test answers:

> Does Android work?

Cleanup answers:

> Can we return the workstation to a safe state?

These are separate responsibilities.

---

## Responsibility Boundaries

The main components now have distinct responsibilities:

```text
headless_start.sh

Start runtime and record ownership.


smoke_test.sh

Validate Android runtime capability.


headless_stop.sh

Gracefully terminate the runtime with process fallback.


ci_headless_smoke.sh

Orchestrate runtime execution and guarantee best-effort cleanup.


GitHub Actions

Execute tests and preserve diagnostics.
```

---

## Failure Example

Consider:

```text
Headless Emulator READY
        |
        v
Package Manager Smoke Test
        |
        v
FAIL
```

Without cleanup:

```text
Smoke FAIL
    |
workflow stops
    |
Emulator remains alive
```

With v0.4.5:

```text
Smoke FAIL
    |
set -e
    |
script exits
    |
EXIT trap
    |
cleanup
    |
ADB shutdown
    |
TERM if necessary
    |
KILL if necessary
```

The original Smoke Test remains failed.

Cleanup does not hide the test failure.

---

## CI vs Runtime Cleanup

GitHub Actions and Bash traps solve related but different problems.

The Bash trap manages resources created by the runtime script.

GitHub Actions manages workflow-level diagnostics and artifacts.

Conceptually:

```text
GitHub Actions
       |
       v
ci_headless_smoke.sh
       |
       +-- trap
       |
       +-- Emulator PID
       |
       +-- cleanup
       |
       v
workflow result
       |
       v
artifact upload
```

---

## Testing Strategy

The process lifecycle tests do not require a real Android Emulator.

Tests create ordinary operating-system processes such as:

```text
sleep
```

or a process that intentionally ignores SIGTERM.

This allows tests to verify:

```text
PID detection
TERM shutdown
grace period
KILL fallback
PID file parsing
EXIT trap behavior
```

without requiring:

```text
Android SDK
KVM
Hypervisor.Framework
AVD
Android boot
```

---

## Version Progression

```text
v0.4.0
Linux / KVM
    |
    v
v0.4.1
Linux Headless Emulator
    |
    v
v0.4.2
macOS Headless Support
    |
    v
v0.4.3
Optional Build Capability
    |
    v
v0.4.4
Emulator Smoke Test
    |
    v
v0.4.5
CI + Cleanup Foundation
    |
    v
v0.4.6
Hosted Emulator CI
```

---

## Key Learning

v0.4.5 introduces an important infrastructure principle:

> Starting a resource also creates responsibility for cleaning it up.

The lifecycle is therefore no longer:

```text
start
   |
run
```

but:

```text
acquire
   |
use
   |
release
```

For Android Environment:

```text
start Emulator
      |
run workload
      |
stop Emulator
```

The same pattern appears in:

```text
temporary files
network sockets
containers
VMs
test devices
database connections
cloud resources
```

Reliable cleanup is therefore part of the runtime design, not an optional afterthought.