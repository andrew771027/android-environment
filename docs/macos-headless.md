# Android Environment v0.4.2 — macOS Headless Support

## Overview

Android Environment v0.4.2 extends the existing Headless Emulator lifecycle to macOS.

v0.4.1 originally assumed a Linux workstation and directly executed:

```bash
check_kvm.sh
```

This was appropriate for Linux, but KVM is Linux-specific.

macOS does not provide `/dev/kvm`.

Instead, Android Emulator uses the macOS Hypervisor.Framework for VM acceleration.

The goal of v0.4.2 is therefore:

> Keep one shared Headless Emulator lifecycle while moving host-specific acceleration checks behind a platform abstraction.

---

## Architecture

Before v0.4.2:

```text
Headless Emulator
       |
       v
check_kvm.sh
       |
       v
Linux / KVM
```

After v0.4.2:

```text
                 Headless Emulator
                        |
                        v
              check_acceleration.sh
                   /           \
                  /             \
               Linux           macOS
                 |               |
                 v               v
                KVM      Hypervisor.Framework
```

The lifecycle itself remains platform-independent:

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
   |
   v
STOPPED
```

---

## Linux vs macOS

### Linux

Android Emulator hardware acceleration uses KVM.

Relevant concepts include:

```text
/dev/kvm
kvm group
device permissions
KVM kernel modules
```

The existing command remains:

```bash
make kvm-check
```

---

### macOS

macOS does not use `/dev/kvm`.

Android Emulator uses the built-in macOS Hypervisor.Framework.

Check acceleration with:

```bash
emulator -accel-check
```

A successful result should indicate that the hypervisor is available and usable.

---

## Cross-platform Acceleration Check

v0.4.2 introduces:

```text
scripts/check_acceleration.sh
```

Run:

```bash
make acceleration-check
```

The script detects the host platform.

Conceptually:

```text
detect_os
   |
   +-- linux
   |     |
   |     +-- check_kvm.sh
   |
   +-- darwin
         |
         +-- emulator -accel-check
```

This allows the Headless Emulator launcher to avoid Linux-specific knowledge.

---

## Starting a Headless Emulator

Create the configured AVD before the first launch:

```bash
make create-avd
```

If creation reports a missing system image, run `make install-sdk` and retry
`make create-avd`. An existing AVD with a different name does not satisfy the
configured `AVD_NAME` in `config/android.env`.

Run:

```bash
make headless-start
```

The startup flow is now:

```text
Check adb
    |
Check emulator
    |
Detect host OS
    |
Check platform acceleration
    |
Check AVD
    |
Start emulator with -no-window
    |
Wait for ADB
    |
Wait for sys.boot_completed
    |
Verify AVD identity
    |
READY
```

---

## Headless Emulator Options

The launcher uses:

```bash
emulator \
    -avd "${AVD_NAME}" \
    -port 5554 \
    -no-window \
    -no-audio \
    -no-boot-anim \
    -no-snapshot
```

### `-no-window`

Disables the Emulator graphical window.

This is the key option for headless execution.

### `-no-audio`

Disables audio support.

Audio is unnecessary for the current Android Environment workflow.

### `-no-boot-anim`

Disables the Android boot animation.

### `-no-snapshot`

Forces a full boot rather than loading or saving Quick Boot state.

This makes the current learning environment more deterministic.

---

## Checking Status

Run:

```bash
make headless-status
```

Possible states include:

```text
STOPPED
```

```text
BOOTING or OFFLINE: emulator-5554
```

or:

```text
READY: cookbook_pixel_api_36 (emulator-5554)
```

The definition of READY remains identical across Linux and macOS:

```text
adb state == device

AND

sys.boot_completed == 1
```

---

## Stopping

Run:

```bash
make headless-stop
```

The script verifies the AVD identity and requests shutdown through:

```bash
adb -s emulator-5554 emu kill
```

The stop implementation does not need to know whether the host uses KVM or Hypervisor.Framework.

---

## Intel Mac

An Intel Mac reports:

```bash
uname -m
```

as:

```text
x86_64
```

The matching Android system image can therefore remain:

```text
system-images;android-36;google_apis;x86_64
```

The architecture and hypervisor are different concepts:

```text
Architecture
    x86_64

Host OS
    macOS

Virtualization
    Hypervisor.Framework
```

---

## Apple Silicon

Apple Silicon normally reports:

```text
arm64
```

The Android Environment architecture-resolution logic should select the corresponding ARM64 system image.

For example:

```text
system-images;android-36;google_apis;arm64-v8a
```

The Headless lifecycle itself remains unchanged.

---

## Validation

Check platform information:

```bash
uname -s
uname -m
```

Check Android tooling:

```bash
command -v adb
command -v emulator
```

Check Emulator acceleration:

```bash
emulator -accel-check
```

Check AVD:

```bash
emulator -list-avds
```

Start:

```bash
make headless-start
```

Check:

```bash
make headless-status
```

Manual Android readiness check:

```bash
adb devices
```

and:

```bash
adb -s emulator-5554 shell getprop sys.boot_completed
```

Expected:

```text
1
```

Stop:

```bash
make headless-stop
```

---

## Key Learning

v0.4.2 introduces a small but important architecture improvement.

The Headless Emulator lifecycle should depend on:

```text
"Acceleration is available"
```

rather than:

```text
"KVM is available"
```

KVM is only one implementation.

Conceptually:

```text
          Acceleration
              |
      +-------+-------+
      |               |
     KVM       Hypervisor.Framework
      |               |
    Linux            macOS
```

This separates:

```text
WHAT

The Emulator requires VM acceleration.
```

from:

```text
HOW

Linux provides KVM.

macOS provides Hypervisor.Framework.
```

The result is one reusable Headless Emulator lifecycle across multiple host platforms.

---

## Version Progression

```text
v0.4.0
Linux / KVM
    |
    v
v0.4.1
Headless Emulator on Linux
    |
    v
v0.4.2
Cross-platform Headless
Linux + macOS
    |
    v
v0.4.3
Smoke Test
    |
    v
v0.4.4
CI
```
