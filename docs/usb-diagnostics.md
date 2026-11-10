# Android Environment v0.5.1 — USB Diagnostics

## Overview

Android Environment v0.5.1 introduces host-level USB diagnostics for physical Android devices.

v0.5 established physical-device support through ADB, device serials, device facts, and Fastboot visibility.

v0.5.1 moves one layer lower:

> Before debugging ADB, verify that the host operating system can see the physical USB device.

The diagnostic stack becomes:

```text id="zpgb88"
Physical Android Device
        |
        v
USB connection
        |
        v
Host USB visibility
        |
        v
Host permissions
        |
        v
ADB transport
        |
        v
ADB authorization
```

---

## Why USB Diagnostics Matter

Running:

```bash id="47ngv1"
adb devices
```

and seeing no device does not necessarily mean ADB itself is broken.

The failure may exist lower in the stack:

```text id="9wrqpb"
USB cable
USB port
host USB subsystem
Linux udev permissions
Linux group membership
```

Therefore troubleshooting should begin from the lowest observable layer.

---

# Linux USB Stack

On Linux, the physical-device path is approximately:

```text id="vtpkvu"
Android device
      |
      v
USB
      |
      v
Linux kernel
      |
      v
lsusb
      |
      v
udev
      |
      v
device permissions
      |
      v
ADB
```

Three host-level checks are important:

```text id="32ncl5"
lsusb
plugdev
udev
```

---

## `lsusb`

Run:

```bash id="6knjqd"
lsusb
```

Example:

```text id="31l8m5"
Bus 001 Device 004: ID 18d1:4ee7 Google Inc.
```

This confirms that the Linux USB subsystem can see the device.

It does not prove that ADB can access it.

Therefore:

```text id="80oxyr"
lsusb visible
```

does not imply:

```text id="b12odr"
adb ready
```

---

## `plugdev`

On Ubuntu Linux, Android development users may need membership in the:

```text id="nj3010"
plugdev
```

group.

Check:

```bash id="3d2rx5"
id -nG
```

If missing:

```bash id="tacxny"
sudo usermod -aG plugdev "$LOGNAME"
```

Group membership changes normally require a new login session before they become effective.

---

## udev Rules

Linux uses udev rules to apply permissions and policies when USB devices appear.

The Android development package:

```text id="c5i82y"
android-sdk-platform-tools-common
```

provides Android-related udev rules on Ubuntu/Debian systems.

Install with:

```bash id="b8j8lg"
sudo apt install android-sdk-platform-tools-common
```

Conceptually:

```text id="11dyar"
USB device detected
        |
        v
udev matches device
        |
        v
permissions assigned
        |
        v
ADB can access transport
```

---

# macOS USB Stack

macOS does not use Linux `udev` or `plugdev`.

Android development on macOS normally requires no additional Android USB driver.

The physical-device path is:

```text id="l2za3j"
Android device
      |
      v
USB
      |
      v
macOS USB subsystem
      |
      v
system_profiler
      |
      v
ADB
```

---

## `system_profiler`

Run:

```bash id="zu6wkv"
system_profiler SPUSBDataType
```

This displays the macOS USB hardware tree.

If the Android device appears here, the Mac is seeing the physical USB connection.

If it does not appear, investigate:

```text id="isn77j"
USB cable
USB port
USB adapter
device connection mode
physical device
```

before investigating ADB.

---

# Running Android Environment Diagnostics

Run:

```bash id="i9mi5x"
make usb-diagnostics
```

The script detects the host platform.

---

## Linux

Checks include:

```text id="bp7lfb"
lsusb available
USB device list
plugdev membership
Android udev rule presence
```

Example:

```text id="avppvx"
[ OK ] lsusb is available

USB devices:
Bus 001 Device 004: ID 18d1:4ee7 Google Inc.

[ OK ] Current user belongs to plugdev
[ OK ] Android-related udev rules found
```

---

## macOS

Checks include:

```text id="er0aj1"
system_profiler available
USB hardware tree
```

Example:

```text id="9ma9g9"
[ OK ] system_profiler is available

USB devices:
...
Android USB Device
...
```

---

# Layered Troubleshooting

The recommended troubleshooting sequence is:

```text id="3qn50n"
Physical Android connected
          |
          v
make usb-diagnostics
          |
          +-- Host cannot see device
          |        |
          |        v
          |   cable / port / USB
          |
          v
Host sees device
          |
          v
adb devices
          |
          +-- missing
          |      |
          |      v
          |   ADB transport
          |
          +-- unauthorized
          |      |
          |      v
          |   RSA authorization
          |
          +-- offline
          |      |
          |      v
          |   ADB connection state
          |
          +-- device
                 |
                 v
              READY
```

This avoids debugging ADB before verifying that the underlying USB connection exists.

---

# Linux vs KVM Permissions

USB diagnostics should not be confused with Emulator KVM diagnostics.

Emulator acceleration uses:

```text id="es0mvt"
/dev/kvm
kvm group
```

Physical-device USB access uses:

```text id="fb9edw"
USB device
udev
plugdev
```

They are separate host capabilities.

Conceptually:

```text id="1rp735"
Android Environment
        |
        +--------------------------+
        |                          |
        v                          v
Virtual Device               Physical Device
        |                          |
        v                          v
/dev/kvm                     USB subsystem
kvm group                    udev
                             plugdev
```

---

# Diagnostics vs Repair

v0.5.1 intentionally diagnoses but does not automatically modify the workstation.

The script may recommend:

```bash id="e990lp"
sudo usermod -aG plugdev "$LOGNAME"
```

or:

```bash id="e7v5fb"
sudo apt install android-sdk-platform-tools-common
```

but it does not automatically execute privileged changes.

The responsibility is:

```text id="cu4gq5"
observe
   |
   v
report
   |
   v
recommend
```

rather than:

```text id="9v86l9"
detect
   |
   v
silently modify host
```

This is especially important on managed or shared workstations.

---

# Testing Strategy

Unit tests do not require a physical Android device.

Instead:

```text id="lgkypc"
Linux production
    |
    +-- lsusb
    +-- id
    +-- filesystem

Unit tests
    |
    +-- fake lsusb
    +-- fake id
    +-- temporary udev directory
```

For macOS:

```text id="n8l5u8"
Production
    |
    +-- system_profiler

Unit test
    |
    +-- fake system_profiler
```

The same Shell logic can therefore be tested on ordinary CI infrastructure.

---

# Manual Integration Test

A real physical Android device is required for manual validation.

## Linux

Run:

```bash id="ygzrhe"
make usb-diagnostics
```

then:

```bash id="w8eqh7"
adb devices
```

## macOS

Run:

```bash id="30ibpb"
make usb-diagnostics
```

then:

```bash id="sbja3s"
adb devices
```

The expected flow is:

```text id="3irncc"
USB visible
    |
    v
ADB visible
    |
    v
ADB authorized
```

---

# Version Progression

```text id="xz5bhp"
v0.5
Physical Device Foundation
    |
    v
v0.5.1
USB Diagnostics
    |
    v
v0.5.2
ADB Connection / Authorization Diagnostics
    |
    v
v0.5.3
Multi-Device Selection
    |
    v
v0.5.4
ADB ↔ Fastboot Lifecycle
```

---

# Key Learning

v0.5.1 introduces a layered debugging principle:

> Debug the lowest failing layer first.

For physical Android devices:

```text id="fncj9s"
Physical connection
        |
        v
USB visibility
        |
        v
Host permissions
        |
        v
ADB transport
        |
        v
Authorization
        |
        v
Android workload
```

If the host cannot see the USB device, debugging ADB authorization is premature.

If the host sees USB but ADB does not see the device, the problem has moved one layer higher.

This layered model makes physical-device failures easier to classify and diagnose.