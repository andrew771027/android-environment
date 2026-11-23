# USB diagnostics — v0.5.1

Host USB visibility is a separate check from ADB transport and RSA authorization. If `adb devices` does not list a connected phone, first inspect whether the host lists its USB connection. These checks do not require an emulator or KVM.

## Current implementation status

Run `make usb-diagnostics` to invoke the diagnostic script. On Linux, it lists USB devices and reports `plugdev` membership and Android-related udev rule filenames. It exits with status 1 if `lsusb` is missing.

On macOS, the script prints the host OS and checks for `system_profiler`. When the command is available, the script exits successfully without listing USB devices. Use the manual macOS command below to inspect the USB hardware tree. The script has no explicit branch for unsupported hosts.

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

The Linux script also checks exact membership in `plugdev` and Android-related rule filenames in `/lib/udev/rules.d` and `/etc/udev/rules.d`. Its suggested Ubuntu/Debian recovery commands are:

```bash
sudo usermod -aG plugdev "$LOGNAME"
sudo apt install android-sdk-platform-tools-common
```

Apply host administration changes according to your workstation policy; these are suggestions printed by the source, not repairs performed by the repository. Log out and back in after changing groups. Group names and package choices depend on the distribution.

The rule helper only looks for existing paths matching `*android*.rules`. This does not verify rule contents, vendor coverage, loaded rules, or effective device permissions. USB permissions and `/dev/kvm` permissions are separate concerns.

### macOS

```bash
system_profiler SPUSBDataType
```

Inspect the USB hardware tree for the connected device. The macOS listing helper invokes this command directly. The entry script currently only checks command availability. Linux `plugdev` and udev checks do not apply here.

## Continue with ADB

If the host does not list the phone, inspect the cable, port, adapter, and device connection. Once it appears, continue with:

```bash
adb devices
make physical-device-check SERIAL=ABC123
make physical-device-facts SERIAL=ABC123
```

Replace `ABC123` with the ADB serial. An `unauthorized` entry requires accepting the phone's RSA prompt; `offline` is a separate transport state. Host USB visibility alone does not prove either authorization or a usable ADB connection. See [physical devices](./physical-device.md) and [Fastboot](./fastboot.md).

## Helper tests and limits

[tests/test_usb.py](../tests/test_usb.py) collects 13 cases using fake commands and temporary rule directories. It covers the USB helper’s support checks for Linux, macOS, and Windows, as well as the Linux entry point invoked through Bash with simulated USB output.

- The rule-present case creates a matching file but does not assert the helper's return code.
- Fake commands still lack the leading `#` in their shebang and rely on Bash fallback.
- The suite does not invoke the Make target or cover the macOS entry point, missing `system_profiler`, or USB listing command failures.

All 13 cases passed in the local check. On macOS, `make usb-diagnostics` exited successfully after printing the host OS. Real USB visibility, Linux device permissions, and ADB authorization were not verified.
