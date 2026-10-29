# Android Environment v0.4.6 — Emulator Smoke Test

## Overview

Introduced in v0.4.4, the smoke test checks a running Android Emulator. Version 0.4.5 introduced a CI runner that starts an emulator, runs these same checks, and attempts cleanup.

Previous versions established:

```text
Host virtualization
        ↓
Android Emulator
        ↓
Headless lifecycle
        ↓
READY
```

However, reaching `READY` only proves that ADB is connected and Android reports that boot has completed.

v0.4.4 adds one more question:

> Is this Emulator actually usable as an Android test environment?

The Smoke Test performs a small set of high-value checks without testing any application-specific behavior.

---

## Goal

The Smoke Test validates the minimum runtime capability expected by Android Cookbook and other Android test workloads.

It checks:

```text
ADB connectivity
Android boot state
Android SDK property
Device model property
Package Manager
Basic Android shell execution
```

A successful Smoke Test means:

> The Android Emulator is alive, booted, reachable, and capable of responding to basic Android system operations.

---

## Lifecycle

The Headless Emulator lifecycle remains:

```text
STOPPED
   |
   v
STARTING
   |
   v
ADB CONNECTED
   |
   v
BOOTING
   |
   v
READY
```

v0.4.4 adds a validation step after READY:

```text
READY
   |
   v
SMOKE TEST
   |
   v
USABLE
```

Therefore:

```text
READY
```

and:

```text
USABLE
```

are related but not identical concepts.

---

## Why READY Is Not Enough

The existing readiness check verifies:

```text
adb state == device
```

and:

```text
sys.boot_completed == 1
```

These checks are important, but they do not validate additional Android services.

For example, an environment may theoretically report boot completion while another system capability is unavailable or malfunctioning.

The Smoke Test therefore probes a few additional Android interfaces.

---

## Smoke Test Checks

### 1. ADB State

Command:

```bash
adb -s emulator-5554 get-state
```

Expected:

```text
device
```

This verifies that ADB can communicate with the Emulator.

---

### 2. Boot Completion

Command:

```bash
adb -s emulator-5554 shell getprop sys.boot_completed
```

Expected:

```text
1
```

This verifies that Android has completed its normal boot sequence.

---

### 3. Android SDK Version

Command:

```bash
adb -s emulator-5554 \
    shell getprop ro.build.version.sdk
```

Example:

```text
36
```

The Smoke Test verifies that the property is available and contains a numeric SDK level.

The exact value is not hard-coded into the Smoke Test.

Version policy belongs to environment configuration and validation rather than basic runtime reachability.

---

### 4. Device Model

Command:

```bash
adb -s emulator-5554 \
    shell getprop ro.product.model
```

The Smoke Test only requires a non-empty response.

The specific model name depends on the selected AVD and system image.

---

### 5. Package Manager

Command:

```bash
adb -s emulator-5554 \
    shell pm list packages
```

The purpose is not to validate every installed package.

The purpose is to confirm that Android Package Manager can respond successfully.

---

### 6. Android Shell

Command:

```bash
adb -s emulator-5554 \
    shell echo smoke-ok
```

Expected:

```text
smoke-ok
```

This confirms basic shell command execution through ADB.

---

## Running the Smoke Test

Start the Emulator:

```bash
make headless-start
```

Check status:

```bash
make headless-status
```

Expected:

```text
READY: cookbook_pixel_api_36 (emulator-5554)
```

Run:

```bash
make smoke
```

Example:

```text
[INFO] Running Android Emulator Smoke Test

Serial:
  emulator-5554

[ OK ] ADB device is ready
[ OK ] Android boot completed
[ OK ] Android SDK version: 36
[ OK ] Device model: sdk_gphone_x86_64
[ OK ] Package Manager is available
[ OK ] Android shell is usable

==========================================
 Android Emulator Smoke Test PASSED
==========================================
```

---

## CI smoke with cleanup

The CI runner introduced in v0.4.5 is available in v0.4.6 as:

```bash
make hosted-emulator-ci
```

This command starts an emulator, runs the existing six smoke checks, and attempts cleanup of its own process on exit. It refuses to start if ADB lists any emulator and preserves that existing instance. A startup or smoke failure remains a failure even when cleanup succeeds. A cleanup failure also fails an otherwise successful run. See [CI and cleanup](./ci-cleanup.md).

Use `make smoke` when an emulator is already running. `make headless-smoke` keeps its existing behavior and does not automatically stop the emulator.

## Combined Headless + Smoke Flow

v0.4.4 also provides:

```bash
make headless-smoke
```

Conceptually:

```text
make headless-smoke
        |
        v
check acceleration
        |
        v
start Emulator
        |
        v
wait for READY
        |
        v
Smoke Test
        |
        v
PASS
```

This provides a simple end-to-end environment validation flow.

---

## Smoke Test vs Environment Validation

These two concepts should remain separate.

### Environment Validation

Examples:

```text
adb binary installed
emulator binary installed
SDK packages installed
KVM available
Build Tools installed
```

These checks answer:

> Is the workstation provisioned correctly?

### Smoke Test

Examples:

```text
ADB communicates with Android
Android boot completed
Package Manager responds
Shell responds
```

These checks answer:

> Does the running environment actually work?

Conceptually:

```text
Provisioning
    |
    v
Static validation
    |
    v
Start runtime
    |
    v
Smoke test
```

---

## Smoke Test vs Functional Test

A Smoke Test should remain small.

For example:

```text
pm responds
```

belongs to the Environment Smoke Test.

But:

```text
install application
launch activity
click button
verify UI
```

belongs to Android Cookbook or another application test suite.

Therefore v0.4.4 intentionally does not validate application behavior.

---

## Smoke Test vs Build Capability

Android Environment v0.4.3 introduced optional Build Tools.

The Emulator Smoke Test does not require:

```text
build-tools;36.0.0
```

because an Emulator-only workstation may intentionally not have Android Build Tools installed.

The responsibilities remain:

```text
make validate-build-tools

    Build capability
```

and:

```text
make smoke

    Runtime capability
```

This maintains capability-based provisioning.

---

## Architecture

```text
                  Android Environment
                         |
          +--------------+--------------+
          |                             |
          v                             v
  Static Environment              Runtime Environment
     Validation                        Validation
          |                             |
          |                             v
          |                        Smoke Test
          |                             |
          |                       +-----+------+
          |                       |            |
          |                      ADB       Android OS
          |                       |            |
          |                       v            v
          |                   get-state     getprop
          |                                   |
          |                           Package Manager
          |
          +-- SDK
          +-- Emulator
          +-- KVM / Hypervisor
          +-- Optional Build Tools
```

---

## Failure Examples

### ADB Offline

```text
[ERROR] ADB device is not ready
```

Check:

```bash
adb devices
```

---

### Boot Incomplete

```text
[ERROR] Android boot is not complete
```

Check:

```bash
adb -s emulator-5554 \
    shell getprop sys.boot_completed
```

---

### Package Manager Failure

```text
[ERROR] Android Package Manager is unavailable
```

Try manually:

```bash
adb -s emulator-5554 \
    shell pm list packages
```

---

### Shell Failure

```text
[ERROR] Basic Android shell command failed
```

Try:

```bash
adb -s emulator-5554 \
    shell echo smoke-ok
```

---

## Testing Strategy

The unit tests do not launch a real Android Emulator.

Instead, they create a fake `adb` executable and inject it through `PATH`.

Conceptually:

```text
Production

smoke.sh
   |
   v
real adb
```

while tests use:

```text
Test

smoke.sh
   |
   v
fake adb
```

The fake executable returns controlled outputs such as:

```text
get-state
    → device

sys.boot_completed
    → 1

ro.build.version.sdk
    → 36
```

This allows the Shell logic to be tested without requiring:

```text
Android SDK
Emulator
KVM
macOS Hypervisor
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
Local CI runner / owned-process cleanup
    |
    v
v0.4.6
GitHub hosted emulator CI
```

---

## Key Learning

v0.4.4 introduces an important infrastructure concept:

> Process existence is not the same as readiness, and readiness is not the same as usability.

The progression is:

```text
Process exists
      |
      v
ADB connected
      |
      v
Android boot completed
      |
      v
Runtime services respond
      |
      v
Environment usable
```

A Smoke Test provides a lightweight confidence check before higher-level Android tests begin.