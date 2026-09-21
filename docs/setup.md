# Android Environment v0.4 Setup

This document is the main setup guide for **Android Environment**, used by **Android Cookbook**. It combines the existing local workstation setup with the **v0.4 Linux / KVM / headless CI** workflow.

The v0.4 package is an **overlay** for the v0.3 repository, not a replacement for older Cookbook scripts. Back up or commit v0.3, copy the v0.4 files into the repository, and review changes before merging. The overlay's `config/android.env` adds CI settings; retain your own non-CI v0.3 settings if used elsewhere.

For Linux headless CI, follow [v0.4 Linux / CI Setup](#v04-linux--ci-setup) below. For a local workstation, follow sections 1–16; v0.3 remains the local Mac workflow.

The goal is to prepare a reproducible command-line Android workstation with:

- Java
- Android SDK Command-Line Tools
- `sdkmanager`
- `avdmanager`
- Android SDK Platform Tools
- `adb`
- `fastboot`
- Android Emulator
- One Android Virtual Device (AVD)

Android Studio is optional. Android's command-line tools can be installed independently and `sdkmanager` can then install the SDK packages required by this repository.

## 1. Architecture

```text
Host workstation
macOS / Linux
│
├── Java
│
└── Android SDK
    │
    ├── cmdline-tools
    │   ├── sdkmanager
    │   └── avdmanager
    │
    ├── platform-tools
    │   ├── adb
    │   └── fastboot
    │
    ├── emulator
    │
    ├── platforms
    │   └── android-36
    │
    └── system-images
        └── Android 16 / API 36
             │
             ▼
      cookbook_pixel_api_36
             │
             ▼
            adb
             │
             ▼
      Android Cookbook
```

## 2. Repository Layout

```text
android-environment/
├── config/
│   ├── android.env
│   └── packages.txt
├── docs/
│   ├── setup.md
│   ├── configuration.md
│   ├── architecture_detection.md
│   ├── validation.md
│   ├── macos.md
│   ├── linux.md
│   └── emulator.md
├── scripts/
│   ├── bootstrap.sh
│   ├── install_sdk.sh
│   ├── create_avd.sh
│   ├── start_emulator.sh
│   ├── doctor.sh
│   ├── validate_environment.sh
│   ├── lib/
│   │   ├── common.sh
│   │   └── platform.sh
│   └── cleanup.sh
├── .gitignore
├── Makefile
└── readme.md
```

## 3. Baseline

The local workstation workflow uses the following project baseline:

```text
Android:       Android 16
API level:     36
AVD name:      cookbook_pixel_api_36
Device type:   Pixel-family AVD
Android Studio: optional
Physical Pixel: optional
Host detection: macOS/Linux, ARM64/x86_64
```

These values are project defaults rather than requirements of Android itself.

## 4. Host-specific Setup

Follow the host guide first:

- macOS: [macos.md](./macos.md)
- Linux: [linux.md](./linux.md)

After completing the host-specific setup, return here.

## 5. Configure ANDROID_HOME

The recommended repository default is:

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
```

Add the Android tools to `PATH`:

```bash
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PATH="$ANDROID_HOME/emulator:$PATH"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

Verify:

```bash
echo "$ANDROID_HOME"
command -v sdkmanager
command -v avdmanager
command -v adb
command -v fastboot
command -v emulator
```

Expected SDK layout:

```text
$ANDROID_HOME/
├── cmdline-tools/
│   └── latest/
├── emulator/
├── platform-tools/
├── platforms/
└── system-images/
```

## 6. Bootstrap the Host

From the repository root:

```bash
chmod +x scripts/*.sh
./scripts/bootstrap.sh
```

Or, if the Makefile is available:

```bash
make bootstrap
```

The bootstrap step checks Java and `unzip`, resolves `ANDROID_HOME`, and creates the SDK directory when needed.

## 7. Install Android SDK Packages

After Android Command-Line Tools are installed:

```bash
sdkmanager --licenses
make install-sdk
```

Review and accept the Android SDK licenses before installing packages.

Equivalent SDK packages typically include:

```bash
sdkmanager \
  "platform-tools" \
  "emulator" \
  "platforms;android-36"
```

The repository's `install_sdk.sh` selects the Android 16 system image for the detected host OS and CPU architecture.

View installed packages:

```bash
sdkmanager --list_installed
```

## 8. Verify Command-Line Tools

```bash
sdkmanager --version
adb version
fastboot --version
emulator -version
```

At this point the workstation has Android tooling, but it does not yet necessarily have a running Android device.

## 9. Create an Android Virtual Device

```bash
make create-avd
```

Verify:

```bash
emulator -list-avds
```

Expected:

```text
cookbook_pixel_api_36
```

See [emulator.md](./emulator.md) for the complete emulator lifecycle.

## 10. Start the Emulator

```bash
make emulator-start
```

Or directly:

```bash
emulator -avd cookbook_pixel_api_36
```

Wait until Android finishes booting.

## 11. Verify ADB

Open another terminal:

```bash
adb devices
```

Expected:

```text
List of devices attached
emulator-5554    device
```

The serial may differ.

Test the connection:

```bash
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.sdk
```

For the repository baseline, the SDK property should report API 36.

## 12. Run Environment Doctor

```bash
make doctor
```

Example result:

```text
java           OK
sdkmanager     OK
avdmanager     OK
adb            OK
fastboot       OK
emulator       OK

ANDROID_HOME=/Users/example/Android/Sdk

AVDs:
cookbook_pixel_api_36

Devices:
List of devices attached
emulator-5554 device
```

For strict provisioning checks:

```bash
make validate
```

Unlike `doctor`, validation checks the host mapping, SDK directory, installed packages, and configured AVD, and exits non-zero on failure. See [validation.md](./validation.md).

## 13. Start Android Cookbook v0.1

Once this succeeds:

```bash
adb devices
```

Android Cookbook can assume that an Android target exists.

Recommended first commands:

```bash
adb devices
adb shell
adb shell getprop
adb shell pm list packages
adb shell ps -A
adb logcat
adb shell dumpsys
```

The responsibility boundary is:

```text
Android Environment
    └── How do I obtain a usable Android workstation/device?

Android Cookbook
    └── What can I inspect, control, test, and learn on Android?
```

## 14. Physical Pixel Devices

A physical Pixel is optional for the local workstation workflow.

The emulator is sufficient for early Cookbook topics such as:

- `adb`
- shell navigation
- `getprop`
- package manager (`pm`)
- activity manager (`am`)
- `logcat`
- `dumpsys`
- filesystem inspection
- processes
- settings

Use a physical device later for areas where hardware behavior matters, for example:

- bootloader
- real `fastboot` workflows
- flashing
- USB behavior
- battery and power
- sensors
- vendor-specific behavior
- hardware validation

## 15. Definition of Done

The local workstation setup is complete when all of the following work. For Linux headless CI, also complete the [v0.4 definition of done](#v04-definition-of-done).

- [ ] Java is available.
- [ ] `sdkmanager` is available.
- [ ] `avdmanager` is available.
- [ ] `adb` is available.
- [ ] `fastboot` is available.
- [ ] `emulator` is available.
- [ ] Android 16 / API 36 packages are installed.
- [ ] `cookbook_pixel_api_36` can be created.
- [ ] The emulator can boot.
- [ ] `adb devices` reports the emulator as `device`.
- [ ] `adb shell` works.
- [ ] `make doctor` reports the expected tools and devices.
- [ ] `make validate` reports `FAIL=0`.

## 16. Next

Continue with:

1. [macOS Setup](./macos.md)
2. [Linux Setup](./linux.md)
3. [Emulator Guide](./emulator.md)
4. Android Cookbook v0.1 Recipe 001 — Device Discovery

## v0.4 Linux / CI Setup

Run the following commands from the repository root on the Linux host. The Linux command-line-tools installer must not be run on macOS.

The Makefile provides all v0.4 entry points, including `linux-tools`. CI port, serial, stop timeout, and polling defaults are defined in `config/android.env`. A real Linux / KVM run is still required to validate the headless workflow.

### Step 1: Host / KVM

Use Ubuntu 24.04 x86_64 with `/dev/kvm` available and accessible to the runner user. Follow [linux-kvm.md](./linux-kvm.md) for host prerequisites and permissions. Prepare Java and the host dependencies before installing SDK tools.

### Step 2: SDK command-line tools

`make linux-tools` downloads a specific official Google command-line-tools Linux ZIP and validates its SHA-256. If the installer finds an existing executable `sdkmanager`, it skips the download; that path does not revalidate the existing installation's checksum.

Review Android SDK licenses and accept them via `sdkmanager --licenses` before installing SDK packages:

```bash
make linux-tools
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
sdkmanager --licenses
make install-sdk
```

### Step 3: Provision AVD

```bash
make create-avd
emulator -list-avds
```

The Linux CI baseline uses API 36 / `google_apis` / `x86_64` / Pixel 7 (`pixel_7`), with AVD name `cookbook_pixel_api_36`. If `avdmanager` reports the known `devices.xml` lookup message, verify the AVD profile and creation state; do not invent an XML file or silently select a different profile.

### Step 4: Validate and smoke

```bash
make kvm-check
make headless-smoke
```

Expected successful log: `[INFO] Smoke PASS: ...` followed by owned-emulator cleanup. Emulator logs after launch: `artifacts/emulator.log`; preflight failures may occur before this file exists.

Read [headless-lifecycle.md](./headless-lifecycle.md) for readiness checks, AVD identity verification, timeouts, and cleanup. Use an isolated runner with no other running emulator; the v0.4 workflow reserves port 5554 and serial `emulator-5554`.

### Step 5: Unit tests

```bash
python -m pip install pytest
make unit-test
```

The offline unit tests do not require an Android SDK, KVM, or a running emulator.

### GitHub Actions

After completing and reviewing the overlay integration, commit `.github/workflows/android-headless.yml` along with the required scripts, configuration, Makefile targets, and tests, then push. The `unit` job does not require KVM, while `headless` does. If the hosted runner lacks `/dev/kvm`, choose an appropriately configured runner instead of deleting the KVM check.

The workflow uploads diagnostics from `artifacts/`, including on failure.

### v0.4 Definition of Done

- [ ] Command-line tools checksum verified.
- [ ] API 36 image provisioned and AVD exists.
- [ ] KVM validation passes on Linux.
- [ ] Headless emulator reaches `sys.boot_completed=1` with expected AVD identity.
- [ ] Smoke test passes and the owned emulator process is cleaned up.
- [ ] Offline unit tests pass; CI logs are uploaded on failure.
