# Physical devices — v0.5.1

Use the physical-device commands to select an ADB transport, check authorization, and read device facts. They require SDK Platform Tools on `PATH`; they do not require an AVD or emulator acceleration. Run commands from the repository root.

## Host USB visibility

If ADB does not list the phone, inspect host USB visibility first: `lsusb` on Linux or `system_profiler SPUSBDataType` on macOS. The v0.5.1 `make usb-diagnostics` entry point is incomplete and currently unusable. See [USB diagnostics](./usb-diagnostics.md) for manual checks and known defects.

## Connect and check

1. Enable Developer Options and USB debugging on the phone.
2. Connect a data-capable USB cable and unlock the phone.
3. Accept the workstation's RSA debugging prompt.
4. Check the connection:

```bash
adb devices
make physical-device-check
make physical-device-facts
```

For an explicit serial:

```bash
make physical-device-check SERIAL=ABC123
make physical-device-facts SERIAL=ABC123
```

The scripts accept a first positional argument, then fall back to the `DEVICE_SERIAL` environment variable when that argument is absent or empty:

```bash
./scripts/physical_device_check.sh ABC123
DEVICE_SERIAL=ABC123 ./scripts/physical_device_facts.sh
```

Make forwards `SERIAL` as the positional argument. A nonempty value takes precedence over `DEVICE_SERIAL`. These scripts do not source `config/android.env`.

## Automatic selection

[scripts/lib/physical_device.sh](../scripts/lib/physical_device.sh) parses `adb devices`, excludes serials starting with `emulator-`, and counts only entries whose state is `device`.

| Authorized candidates | Result |
| --- | --- |
| 0 | Fail; check reports `No authorized physical Android device found` |
| 1 | Select that serial |
| 2 or more | Fail; provide an explicit serial |

Unauthorized and offline entries do not count toward selection. To obtain their specific diagnostic, pass their serial explicitly. Selection excludes emulators by serial prefix only: it does not verify USB hardware or exclude network ADB transports. An explicitly supplied serial is checked for ADB state without the emulator-prefix filter.

## Authorization results

| Selected serial state | Check result |
| --- | --- |
| `device` | Exit 0; `ADB authorization accepted` |
| `unauthorized` | Exit 1; unlock the phone and accept the RSA prompt |
| `offline` | Exit 1; ADB transport is visible but unavailable |
| Missing | Exit 1; serial not found |
| Other | Exit 1; unexpected state |

A successful check confirms the listed ADB state. It does not wait for Android boot completion, run a shell readiness check, or verify an expected model or API level.

If no transport appears, inspect the cable, USB debugging setting, host USB permissions, and ADB server. Linux USB/udev permissions are separate from `/dev/kvm` emulator permissions. See the [Linux](./linux.md) and [macOS](./macos.md) host guides.

## Device facts

`make physical-device-facts` requires the selected transport to be authorized, then reads these properties with `adb -s SERIAL shell getprop`:

| Output | Property |
| --- | --- |
| Serial | Selected ADB serial |
| Manufacturer | `ro.product.manufacturer` |
| Model | `ro.product.model` |
| Product | `ro.product.name` |
| Device codename | `ro.product.device` |
| Android version | `ro.build.version.release` |
| SDK level | `ro.build.version.sdk` |
| Build fingerprint | `ro.build.fingerprint` |

The helper removes carriage returns and newlines and suppresses property-command stderr. Facts are printed for inspection; empty values and compatibility with the SDK baseline are not validated. A physical device need not run API 36.

## Scope and verification

These commands do not install APKs, change device settings, reboot, unlock, or flash. Fastboot visibility is a [separate check](./fastboot.md) performed after manually changing device mode.

The 24 cases in [test_physical_device.py](../tests/test_physical_device.py) use fake ADB/Fastboot executables. They cover discovery, emulator exclusion, authorization, selection, property helpers, and script entry points. They do not prove real USB connectivity or bootloader support. See [testing](./testing.md) for current results and remaining coverage.
