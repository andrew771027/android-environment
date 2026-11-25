# Android Environment v0.5.2 — ADB Connection State and Recovery

## Overview

Android Environment v0.5.2 introduces explicit ADB connection-state diagnostics and recovery.

v0.5.1 established host-level USB diagnostics.

The next layer is:

```text
Physical Device
      |
      v
USB visible
      |
      v
ADB transport
      |
      v
Connection state
```

The goal of v0.5.2 is:

> Determine the current ADB state and perform limited, safe recovery when appropriate.

---

## Connection States

ADB can report several useful states.

### `device`

Example:

```text
ABC123    device
```

This means the ADB transport is available and the workstation is authorized to communicate with the Android device.

This is the normal READY state.

---

### `unauthorized`

Example:

```text
ABC123    unauthorized
```

The workstation can see the Android device, but the device has not authorized this workstation for USB debugging.

The normal recovery is a user action:

```text
unlock device
      |
      v
inspect RSA prompt
      |
      v
accept USB debugging authorization
```

Automation should not treat this state as an ordinary transport failure.

---

### `offline`

Example:

```text
ABC123    offline
```

ADB knows about the transport, but communication is not currently usable.

This is an appropriate candidate for automated recovery.

The recovery order is:

```text
reconnect device
       |
       v
wait for device
       |
       v
still offline?
       |
       v
restart ADB server
```

---

### Missing

If the requested serial is absent from:

```bash
adb devices
```

ADB currently does not know about that device.

Before aggressive recovery, verify the lower layer:

```bash
make usb-diagnostics
```

If USB is visible, restarting the ADB server can trigger another device scan.

---

# Layered Model

The Physical Device connection stack is:

```text
Physical Device
        |
        v
USB hardware
        |
        v
Host USB visibility
        |
        v
ADB server
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

Different failures belong to different layers.

For example:

```text
USB missing
```

should not be debugged as an RSA authorization problem.

Likewise:

```text
unauthorized
```

should not initially be treated as a USB cable problem.

---

# ADB Client and Server

The `adb` command used in the terminal is a client.

ADB also runs a workstation-side server process.

Conceptually:

```text
adb command
    |
    v
ADB client
    |
    v
ADB server
    |
    v
USB / TCP transport
    |
    v
adbd on Android
```

Therefore connection recovery can occur at different scopes.

---

# Device Reconnect

A localized recovery can use:

```bash
adb -s ABC123 reconnect
```

This requests reconnection of the selected transport.

This should generally be attempted before restarting the entire workstation-side ADB server.

The reason is scope.

A workstation may have:

```text
Pixel A
Pixel B
OnePlus
Emulator
```

Restarting the ADB server affects all ADB transports.

Reconnecting one device is therefore the smaller recovery action.

---

# Server Restart

ADB server restart uses:

```bash
adb kill-server
adb start-server
```

Restarting the server causes ADB to rebuild its workstation-side state and rediscover connected devices.

This is useful when:

```text
device is missing from adb
transport remains offline
ADB server state appears unhealthy
```

It should be considered a broader recovery action than a single-device reconnect.

---

# Recovery Escalation

v0.5.2 uses the following policy:

```text
device
   |
   └── no recovery


unauthorized
   |
   └── user authorization required


offline
   |
   v
device reconnect
   |
   v
wait
   |
   v
server restart
   |
   v
wait


missing
   |
   v
verify USB
   |
   v
server restart / rescan
```

The principle is:

> Use the smallest recovery action that can reasonably solve the problem.

---

# Checking State

Run:

```bash
make adb-connection SERIAL=ABC123
```

Possible results include:

```text
[ OK ] ADB state: device
```

```text
[WARN] ADB state: unauthorized
```

```text
[WARN] ADB state: offline
```

or:

```text
[ERROR] ADB device not found: ABC123
```

---

# Recovery

For an offline or missing device:

```bash
make adb-recover SERIAL=ABC123
```

Example:

```text
==========================================
 ADB Connection Recovery
==========================================

[INFO] Serial: ABC123
[INFO] Initial state: offline

[INFO] Attempt 1: reconnect device

[ OK ] Device recovered after reconnect
```

If reconnect does not recover the device:

```text
[INFO] Attempt 2: restart ADB server
```

The script then waits again for:

```text
device
```

---

# Unauthorized Devices

An unauthorized device is intentionally not automatically repaired.

Example:

```text
ABC123    unauthorized
```

The user should:

```text
1. Unlock the Android device.
2. Confirm USB debugging is enabled.
3. Inspect the RSA authorization prompt.
4. Approve the workstation.
5. Run the connection check again.
```

The trust decision remains on the physical Android device.

---

# Why Recovery Has a Timeout

Recovery should never wait forever.

For example:

```text
adb reconnect
      |
      v
wait_for_adb_ready
      |
      +-- device → success
      |
      +-- timeout → next recovery step
```

A finite timeout makes recovery deterministic and usable in future automation.

---

# ADB State vs USB State

These should remain distinct.

```text
USB visible
    ≠
ADB ready
```

For example:

```text
USB visible
        |
        v
ADB unauthorized
```

is possible.

Likewise:

```text
USB visible
        |
        v
ADB offline
```

is possible.

v0.5.1 diagnoses USB.

v0.5.2 diagnoses ADB.

---

# Testing Strategy

Unit tests do not require a real Android phone.

The tests replace the `adb` executable through PATH injection.

Example:

```text
Production

adb_connection.sh
      |
      v
real adb
```

Test:

```text
adb_connection.sh
      |
      v
fake adb
```

The fake implementation can return:

```text
device
unauthorized
offline
missing
```

This allows connection logic to be tested independently from USB hardware.

Stateful fake ADB tests can also simulate:

```text
offline
   |
reconnect
   |
device
```

which provides lightweight testing of recovery transitions.

---

# Responsibility Boundary

v0.5.2 remains an environment-layer feature.

Android Environment answers:

```text
Can this workstation establish and recover
a usable ADB connection?
```

Android Cookbook answers:

```text
What Android operations should be executed
after the connection is ready?
```

For example:

```text
Android Environment
      |
      v
ADB state = device
      |
      v
Android Cookbook
      |
      +-- package manager
      +-- activity manager
      +-- APK installation
      +-- lifecycle tests
```

---

# Version Progression

```text
v0.5
Physical Device Foundation
    |
    v
v0.5.1
USB Diagnostics
    |
    v
v0.5.2
ADB Connection State
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

v0.5.2 introduces two important infrastructure concepts:

```text
State observation
```

and:

```text
Recovery escalation
```

Instead of treating every failure as:

```text
ADB broken
```

the environment classifies:

```text
missing
unauthorized
offline
device
```

and chooses a response based on state.

This turns ADB handling from a collection of shell commands into a small connection-state model.