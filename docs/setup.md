# Android Environment Setup

This document is the main setup guide for **Android Environment v0.2**, used by **Android Cookbook**.

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

Android Environment v0.2 uses the following project baseline:

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
make install-sdk
```

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

Accept Android SDK licenses when required:

```bash
yes | sdkmanager --licenses
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
make emulator
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

A physical Pixel is optional for v0.2.

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

Android Environment v0.2 is complete when all of the following work:

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
