# Android Environment v0.5 — Physical Device

## Overview

Android Environment v0.5 introduces support for real Android hardware.

Previous versions focused mainly on Android Emulator lifecycle and hosted virtual environments.

v0.5 adds a second runtime target:

```text
Android Environment
        |
        +-------------------+
        |                   |
        v                   v
     Emulator          Physical Device
        |                   |
        v                   v
       ADB              USB / ADB
```

The goal of v0.5 is not flashing or modifying a device.

The goal is:

> Establish a safe and deterministic connection between a workstation and a physical Android device.

---

## Scope

v0.5 covers:

```text
USB connection
USB debugging
ADB authorization
device serial
device selection
device facts
Fastboot visibility
```

It intentionally does not perform:

```text
bootloader unlock
partition flashing
factory image installation
root
recovery modification
```

---

## Physical Device Lifecycle

A basic development connection looks like:

```text
Physical Android Device
        |
        v
USB cable
        |
        v
Developer Options
        |
        v
USB Debugging
        |
        v
RSA Authorization
        |
        v
ADB
        |
        v
AUTHORIZED DEVICE
```

ADB authorization is an explicit trust relationship between the Android device and the workstation.

---

## USB Debugging

Enable Developer Options on the Android device.

Then enable:

```text
USB debugging
```

After connecting the USB cable:

```bash
adb devices
```

may initially report:

```text
List of devices attached
ABC123    unauthorized
```

The device should display an RSA authorization dialog.

Unlock the device and approve the workstation.

Run again:

```bash
adb devices
```

Expected:

```text
ABC123    device
```

---

## ADB States

Important ADB states include:

### `device`

```text
ABC123    device
```

The device is authorized and available.

### `unauthorized`

```text
ABC123    unauthorized
```

The workstation has not yet been trusted.

Check the Android device for the USB debugging authorization dialog.

### `offline`

```text
ABC123    offline
```

ADB knows about the transport, but communication is not currently usable.

### Missing

If the device does not appear at all, investigate:

```text
USB cable
USB mode
Developer Options
USB debugging
host USB permissions
ADB server
```

---

## Device Serial

Each ADB transport is identified by a serial.

Example:

```text
ABC123
```

Use:

```bash
adb -s ABC123 shell
```

to explicitly select one device.

This becomes essential when a workstation has multiple connected devices.

Example:

```text
Workstation
├── Pixel A
├── Pixel B
├── OnePlus
└── Emulator
```

Automation should never silently choose an arbitrary physical device when multiple valid devices are connected.

The v0.5 policy is:

```text
0 devices
    → fail

1 authorized physical device
    → auto-select

2+ authorized physical devices
    → require explicit serial
```

---

## Checking a Physical Device

Run:

```bash
make physical-check
```

If exactly one authorized physical device exists, it is selected automatically.

For multiple devices:

```bash
make physical-check SERIAL=ABC123
```

Successful result:

```text
==========================================
 Physical Android Device Check
==========================================

[INFO] Serial: ABC123
[ OK ] ADB authorization accepted

==========================================
 Physical Device Check PASSED
==========================================
```

---

## Device Facts

Run:

```bash
make physical-facts
```

or:

```bash
make physical-facts SERIAL=ABC123
```

The command collects:

```text
serial
manufacturer
model
product
device codename
Android version
SDK level
build fingerprint
```

These values are retrieved through Android system properties.

Examples:

```bash
adb -s ABC123 shell getprop ro.product.manufacturer
adb -s ABC123 shell getprop ro.product.model
adb -s ABC123 shell getprop ro.product.device
adb -s ABC123 shell getprop ro.build.version.release
adb -s ABC123 shell getprop ro.build.version.sdk
adb -s ABC123 shell getprop ro.build.fingerprint
```

---

## Emulator vs Physical Device

ADB sees both Emulator and physical devices.

Example:

```text
emulator-5554    device
ABC123           device
```

v0.5 physical-device discovery intentionally excludes serials beginning with:

```text
emulator-
```

This keeps the two environment targets separate.

---

## Linux USB

On Linux, physical USB device access may require host-level permission configuration.

The stack is:

```text
Android Device
      |
      v
USB
      |
      v
Linux USB subsystem
      |
      v
udev permissions
      |
      v
ADB
```

This differs from Emulator KVM access.

KVM permissions concern:

```text
/dev/kvm
```

Physical-device permissions concern:

```text
USB / udev
```

They are separate host capabilities.

---

## macOS USB

macOS normally does not require an additional Android USB driver.

The basic flow is:

```text
USB cable
   |
USB debugging
   |
RSA authorization
   |
ADB
```

---

## Troubleshooting Authorization

If:

```bash
adb devices
```

continues to show:

```text
unauthorized
```

try:

```text
1. Unlock the device.
2. Check for the RSA debugging prompt.
3. Disconnect USB.
4. Revoke USB debugging authorizations.
5. Reconnect USB.
6. Accept the new authorization.
```

ADB can also be restarted:

```bash
adb kill-server
adb start-server
adb devices
```

---

## Responsibility Boundary

Android Environment v0.5 is responsible for:

```text
Can this workstation reliably identify and communicate with this device?
```

Android Cookbook remains responsible for:

```text
What Android commands and behaviors do we exercise after the device is available?
```

For example:

```text
Android Environment
    |
    └── select ABC123
            |
            v
Android Cookbook
    |
    ├── package manager
    ├── activity manager
    ├── getprop
    ├── install APK
    └── lifecycle tests
```

---

## Key Learning

v0.5 introduces physical identity and trust into Android Environment.

An Emulator can usually be created and owned entirely by the workstation.

A physical Android device has additional concerns:

```text
physical connection
USB permission
user authorization
device identity
runtime state
```

Therefore:

```text
device plugged in
```

is not equivalent to:

```text
device usable
```

The full state is closer to:

```text
USB connected
     |
     v
ADB sees transport
     |
     v
RSA authorized
     |
     v
serial selected
     |
     v
device facts validated
     |
     v
READY FOR WORKLOAD
```