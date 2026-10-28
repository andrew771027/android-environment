# Android Environment v0.4.6 — GitHub Hosted Emulator CI

## Overview

Android Environment v0.4.6 runs a real Android Emulator on a GitHub-hosted Linux runner.

Previous CI versions validated Shell and Python code without requiring an Android runtime.

v0.4.6 adds an end-to-end hosted environment:

```text
GitHub-hosted Ubuntu
        |
        v
Android SDK provisioning
        |
        v
KVM acceleration
        |
        v
AVD creation
        |
        v
Headless Emulator
        |
        v
Android boot
        |
        v
Smoke Test
        |
        v
Cleanup
```

The purpose of this version is not Android application testing.

The purpose is to validate that Android Environment can provision and operate a usable Android runtime on a fresh CI machine.

---

## Runner

v0.4.6 initially uses:

```yaml
runs-on: ubuntu-24.04
```

The runner image is intentionally pinned rather than using:

```yaml
ubuntu-latest
```

so operating-system image changes do not occur at the same time as Emulator CI development.

---

## Existing GitHub Runner Android SDK

GitHub-hosted Ubuntu runners already contain an Android SDK installation.

The repository therefore does not reinstall Android Command-Line Tools from a ZIP during every workflow.

Instead:

```text
GitHub runner Android SDK
          |
          v
make install-sdk
          |
          v
reconcile required repository packages
```

The repository configuration remains the source of truth for:

```text
API level
system-image flavor
architecture mapping
AVD name
AVD profile
```

---

## KVM

Android Emulator hardware acceleration on Linux uses KVM.

The hosted runner exposes:

```text
/dev/kvm
```

The workflow configures device permissions before launching the Emulator.

After configuration:

```bash
test -r /dev/kvm
test -w /dev/kvm
```

must both succeed.

The existing repository command then performs the Android-side validation:

```bash
make kvm-check
```

---

## Provisioning

Required SDK packages are installed through:

```bash
make install-sdk
```

For the current Linux x86_64 environment this resolves to an Android system image similar to:

```text
system-images;android-36;google_apis;x86_64
```

The workflow does not duplicate this package-selection logic.

---

## AVD Creation

The workflow runs:

```bash
make create-avd
```

The existing Android Environment code validates:

```text
system image
hardware profile
AVD existence
```

and creates:

```text
cookbook_pixel_api_36
```

when necessary.

---

## Real Hosted Runtime

After provisioning:

```bash
make hosted-emulator-ci
```

starts the runtime workflow.

Conceptually:

```text
register cleanup trap
        |
        v
start Headless Emulator
        |
        v
record owned PID
        |
        v
wait for Android READY
        |
        v
run Smoke Test
        |
        v
exit
        |
        v
cleanup trap
```

The CI workflow therefore reuses the same lifecycle scripts used on local Linux and macOS environments.

---

## Why CI Does Not Reimplement Emulator Lifecycle

The GitHub Actions workflow is responsible for:

```text
machine provisioning
KVM permission
SDK package installation
AVD creation
artifact preservation
```

Android Environment scripts remain responsible for:

```text
Emulator start
readiness polling
runtime validation
PID ownership
shutdown
TERM/KILL fallback
```

This prevents two independent implementations from developing.

---

## Smoke Test

The hosted workflow executes the existing Emulator Smoke Test.

Checks include:

```text
ADB state
sys.boot_completed
Android SDK property
device model
Package Manager
basic Android shell
```

Therefore the job validates more than process startup.

A passing job means the newly provisioned Android environment is usable.

---

## Cleanup

v0.4.6 reuses the cleanup foundation introduced in v0.4.5.

The runtime stores the Emulator PID and installs an EXIT trap.

Cleanup follows:

```text
owned process
     |
     v
shutdown
     |
     v
TERM
     |
     v
grace period
     |
     v
KILL if necessary
```

The original test exit status remains the primary workflow result.

Cleanup failures are reported separately.

---

## Artifacts

Hosted Emulator CI preserves runtime diagnostics under:

```text
artifacts/
```

Examples:

```text
headless-emulator.log
hosted-ci-diagnostics.txt
```

Artifacts are uploaded even when a previous workflow step fails.

This makes boot and KVM failures diagnosable after the ephemeral runner has been destroyed.

---

## Failure Layers

A hosted Emulator failure should be classified by layer.

```text
Runner
  |
  +-- KVM missing / permission
  |
Android SDK
  |
  +-- package installation failure
  |
AVD
  |
  +-- creation / profile failure
  |
Emulator
  |
  +-- process startup failure
  |
ADB
  |
  +-- offline / unavailable
  |
Android
  |
  +-- boot timeout
  |
Smoke
  |
  +-- runtime service failure
```

Debugging should begin at the first failed layer rather than treating all failures as an Emulator failure.

---

## CI Layers

Android Environment now has two CI levels.

### Fast CI

```text
Shell syntax
unit tests
helper tests
```

This should remain the normal fast-feedback path.

### Hosted Emulator CI

```text
fresh Ubuntu runner
KVM
Android SDK
AVD
real Emulator
real Android OS
Smoke Test
```

This provides higher confidence but costs more time.

The two layers are complementary rather than replacements for each other.

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
GitHub Hosted Emulator CI
```

---

## Key Learning

v0.4.6 changes the confidence level of the project.

Before:

```text
The code should be able to operate an Android environment.
```

After:

```text
A completely new machine can provision an Android environment,
boot Android,
validate it,
and clean itself up automatically.
```

This is the difference between having setup scripts and having reproducible infrastructure.