# USB diagnostics — v0.5.1

Host USB visibility is a separate check from ADB transport and RSA authorization. If `adb devices` does not list a connected phone, first inspect whether the host lists its USB connection. These checks do not require an emulator or KVM.

## Current implementation status

The Makefile registers `make usb-diagnostics`, but the command is currently unusable:

- `scripts/usb_diagnostics.sh` is tracked as mode `100644`, so Make fails with permission denied.
- The script ends inside the macOS branch without closing the `case`; `bash -n` reports unexpected end of file. Running it with Bash does not fix this.
- The script calls `log_error`, `log_ok`, `log_warn`, and `die`, but neither sourced file defines these functions.
- `linux_android_udev_rules_present` calls `return 0` instead of `return 0`. A matching rule therefore triggers a command error and the helper eventually returns 1.

The script contains a Linux diagnostic sequence and the beginning of a macOS branch. It does not implement the successful macOS report shown in the earlier draft. There is no completed unsupported-host branch. These defects must be fixed and the entry point tested before describing this command as available.

## Manual host checks

Run commands on the host where the phone is connected. Use a data-capable cable, unlock the device, and enable USB debugging.

### Linux

```bash
lsusb
id -nG
```

Compare the USB listing before and after connecting the phone. If `lsusb` is missing, the script suggests the following Ubuntu/Debian command:

```bash
sudo apt install usbutils
```

The Linux script also intends to check exact membership in `plugdev` and Android-related rule filenames in `/lib/udev/rules.d` and `/etc/udev/rules.d`. Its suggested Ubuntu/Debian recovery commands are:

```bash
sudo usermod -aG plugdev "$LOGNAME"
sudo apt install android-sdk-platform-tools-common
```

Apply host administration changes according to your workstation policy; these are suggestions printed by the source, not repairs performed by the repository. Log out and back in after changing groups. Group names and package choices depend on the distribution.

The rule helper only looks for existing paths matching `*android*.rules`. Even after correcting its typo, this would not verify rule contents, vendor coverage, loaded rules, or effective device permissions. USB permissions and `/dev/kvm` permissions are separate concerns.

### macOS

```bash
system_profiler SPUSBDataType
```

Inspect the USB hardware tree for the connected device. The helper invokes this command directly; the entry script does not yet reach a completed macOS diagnostic flow. Linux `plugdev` and udev checks do not apply here.

## Continue with ADB

If the host does not list the phone, inspect the cable, port, adapter, and device connection. Once it appears, continue with:

```bash
adb devices
make physical-device-check SERIAL=ABC123
make physical-device-facts SERIAL=ABC123
```

Replace `ABC123` with the ADB serial. An `unauthorized` entry requires accepting the phone's RSA prompt; `offline` is a separate transport state. Host USB visibility alone does not prove either authorization or a usable ADB connection. See [physical devices](./physical-device.md) and [Fastboot](./fastboot.md).

## Helper tests and limits

[tests/test_usb.py](../tests/test_usb.py) collects 11 cases using fake `lsusb`, `id`, and `system_profiler` commands and temporary rule directories. It does not invoke the diagnostic script or the Make target and does not use real USB hardware.

The coverage has material gaps:

- The rule-present case has no assertions, so it passes despite the `return` defect.
- The negative group case sets `PATH` instead of `PATH`, so its fake `id` is not selected and the result depends on the host's groups.
- Two functions are named `test_linux_host_supported`; Python replaces the Linux case with the later Darwin case. Only Darwin and Windows host checks are collected.
- Fake command files begin with `!/usr/bin/env bash`, missing the shebang's `#`. Their execution relies on Bash fallback and is not evidence of valid standalone scripts.
- Missing `system_profiler`, command failures, and the completed entry-point flow are not covered.

See [testing](./testing.md) for current execution results. The two existing integration tests check an emulator, not USB. Real Linux and macOS USB visibility, permissions, RSA authorization, and Fastboot checks remain unverified for v0.5.1.
