# Linux and KVM

Android Environment v0.4.0 introduces Linux host validation and KVM acceleration checks.

## Goal

Before running an Android Emulator on Linux, verify that the workstation can provide hardware-assisted virtualization.

The validation flow is:

```text
Linux
  |
  v
CPU Architecture
  |
  v
/dev/kvm
  |
  v
KVM Permission
  |
  v
Android Emulator
  |
  v
emulator -accel-check
  |
  v
READY
```

## Requirements

Android Environment v0.4.0 currently targets:

* Linux
* x86_64
* Android Emulator
* KVM
* x86_64 Android system images

## Manual Validation

Check the host:

```bash
uname -s
uname -m
```

Expected:

```text
Linux
x86_64
```

Check the KVM device:

```bash
ls -l /dev/kvm
```

Check Android Emulator acceleration:

```bash
emulator -accel-check
```

A successful check should indicate that KVM is installed and usable.

## Project Validation

Run:

```bash
make kvm-check
```

The script validates:

1. The host is Linux.
2. The host architecture is x86_64.
3. Android Emulator is installed.
4. `/dev/kvm` exists.
5. The current user can read and write `/dev/kvm`.
6. Android Emulator reports that acceleration is available.

## KVM Device

Linux exposes KVM through:

```text
/dev/kvm
```

The existence of this device indicates that the KVM interface is available to userspace.

Existence alone is not sufficient. The current user also needs permission to access the device.

## Emulator Acceleration

Android Emulator provides:

```bash
emulator -accel-check
```

Android Environment uses this command as the final validation that the Emulator can use VM acceleration.

## Troubleshooting

### `/dev/kvm` does not exist

Check whether CPU virtualization support is visible:

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

A value greater than zero indicates that virtualization extensions are visible to Linux.

### Permission denied

Inspect:

```bash
ls -l /dev/kvm
groups
```

The Linux account must have appropriate permission to access the KVM device.

### Emulator acceleration fails

Run:

```bash
emulator -accel-check
```

directly and inspect its diagnostic output.

## Scope

v0.4.0 does not start an Android Emulator.

It only answers:

> Is this Linux workstation ready to use KVM-backed Android Emulator acceleration?

Headless execution and automated smoke testing are intentionally deferred to later versions.
