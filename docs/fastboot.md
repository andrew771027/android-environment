# Android Environment v0.5 — Fastboot Foundation

## Overview

Android SDK Platform-Tools contains two important device interfaces:

```text
adb
fastboot
```

They operate at different stages of the Android device lifecycle.

---

## ADB

ADB normally communicates with a running Android operating system.

```text
Android OS
   |
   v
adbd
   |
   v
USB / TCP transport
   |
   v
adb client
```

Typical commands include:

```bash
adb devices
adb shell
adb install
adb logcat
```

---

## Fastboot

Fastboot communicates with a device in its Bootloader/Fastboot state.

Conceptually:

```text
Power On
   |
   v
Bootloader
   |
   +------ Fastboot interface
   |
   v
Kernel
   |
   v
Android OS
   |
   +------ ADB interface
```

ADB and Fastboot therefore represent different device states.

---

## State Model

### Android Running

```text
Bootloader
    |
Kernel
    |
Android
    |
   ADB
```

Check:

```bash
adb devices
```

### Bootloader / Fastboot

```text
Bootloader
    |
 Fastboot
```

Check:

```bash
fastboot devices
```

A device normally transitions between these modes rather than exposing both as the same active runtime state.

---

## v0.5 Safety Boundary

v0.5 only verifies Fastboot visibility.

It does not execute:

```text
fastboot flashing unlock
fastboot flash
fastboot erase
fastboot format
```

This version treats Fastboot as a device-state observation mechanism.

---

## Checking Fastboot

After manually placing the device in Bootloader/Fastboot mode:

```bash
fastboot devices
```

Example:

```text
ABC123    fastboot
```

Android Environment provides:

```bash
make fastboot-check
```

or:

```bash
make fastboot-check SERIAL=ABC123
```

---

## Why Fastboot Check Is Separate

The normal Physical Device check expects:

```text
Android running
    |
    v
ADB
```

Fastboot check expects:

```text
Bootloader
    |
    v
Fastboot
```

Therefore this would be incorrect:

```text
physical-check
    |
ADB must work
    |
Fastboot must work
```

Instead:

```text
Android Mode
    |
    └── physical-check

Bootloader Mode
    |
    └── fastboot-check
```

The tests represent device state rather than requiring mutually exclusive interfaces simultaneously.

---

## Future Roadmap

Possible later versions:

```text
v0.5.1
Physical Device USB Diagnostics
    |
    ├── Linux lsusb
    ├── udev
    └── permission diagnostics

v0.5.2
ADB Authorization Diagnostics
    |
    ├── unauthorized
    ├── offline
    ├── reconnect
    └── adb server lifecycle

v0.5.3
Multi-Device Selection
    |
    ├── inventory
    ├── explicit serial
    └── deterministic selection

v0.5.4
Bootloader Transition
    |
    ├── adb mode
    ├── manual/reboot transition
    ├── wait for fastboot
    └── return to Android

v0.6+
Device Provisioning
    |
    └── only after the safety model is clearly defined
```

Flashing, unlocking, and partition mutation should remain outside the basic Physical Device foundation.

---

## Key Learning

The important concept is not simply learning another command.

It is learning that an Android device changes control interfaces during its boot lifecycle:

```text
Bootloader
    |
    | fastboot
    |
    v
Kernel
    |
    v
Android
    |
    | adb
    |
    v
Application / Test workload
```

ADB is primarily an Android-runtime interface.

Fastboot is primarily a Bootloader-level interface.

Understanding the difference is foundational for physical Android device infrastructure.