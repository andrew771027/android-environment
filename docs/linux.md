# Android Environment on Linux

This guide prepares a Linux workstation for Android Environment v0.1 and Android Cookbook v0.1.

The examples use Ubuntu/Debian-style package commands. Adjust package installation commands for other distributions.

## 1. Check the Host

```bash
uname -s
uname -m
```

Expected baseline:

```text
Linux
x86_64
```

Check distribution information:

```bash
cat /etc/os-release
```

## 2. Update Packages

Ubuntu / Debian:

```bash
sudo apt update
```

## 3. Install Java and Utilities

For this repository, JDK 17 is the recommended baseline:

```bash
sudo apt install -y \
  openjdk-17-jdk \
  curl \
  unzip
```

Verify:

```bash
java -version
curl --version
unzip -v | head
```

## 4. Create the Android SDK Directory

```bash
mkdir -p "$HOME/Android/Sdk/cmdline-tools"
```

## 5. Install Android Command-Line Tools

Download the current **Android SDK Command-Line Tools for Linux** from Android Developers.

Assuming the archive is in `~/Downloads`:

```bash
mkdir -p /tmp/android-cmdline-tools

unzip ~/Downloads/commandlinetools-linux-*_latest.zip \
  -d /tmp/android-cmdline-tools
```

Create the expected SDK layout:

```bash
mkdir -p "$HOME/Android/Sdk/cmdline-tools/latest"

cp -R /tmp/android-cmdline-tools/cmdline-tools/. \
  "$HOME/Android/Sdk/cmdline-tools/latest/"
```

Verify:

```bash
ls "$HOME/Android/Sdk/cmdline-tools/latest/bin"
```

## 6. Configure bash

Edit:

```bash
nano ~/.bashrc
```

Add:

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
export PATH="$ANDROID_HOME/emulator:$PATH"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

Reload:

```bash
source ~/.bashrc
```

Verify:

```bash
echo "$ANDROID_HOME"
sdkmanager --version
```

If your Linux workstation uses zsh instead, place the exports in `~/.zshrc`.

## 7. Install Android Packages

From the repository:

```bash
make install-sdk
```

Or:

```bash
./scripts/install_sdk.sh
```

Typical packages include:

```bash
sdkmanager \
  "platform-tools" \
  "emulator" \
  "platforms;android-36"
```

Install the Android 16 x86_64 system image selected by the repository configuration.

List available Android 16 images:

```bash
sdkmanager --list | grep 'system-images;android-36'
```

## 8. Check Linux Virtualization

The Android Emulator performs best with hardware virtualization.

First check whether the CPU advertises virtualization support:

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

A value greater than zero usually indicates that the CPU exposes virtualization extensions.

Then check the Android Emulator view:

```bash
emulator -accel-check
```

On Linux, accelerated Android Emulator execution normally uses KVM.

## 9. Check KVM

Check for the device:

```bash
ls -l /dev/kvm
```

Check kernel modules:

```bash
lsmod | grep kvm
```

Possible output:

```text
kvm_intel
kvm
```

or:

```text
kvm_amd
kvm
```

If `/dev/kvm` is missing, verify that virtualization is enabled in BIOS/UEFI and that KVM is installed/configured for the distribution.

On Ubuntu/Debian, packages commonly used for KVM tooling include:

```bash
sudo apt install -y qemu-kvm
```

Your Linux distribution and environment may require additional configuration.

## 10. Check KVM Permissions

If `/dev/kvm` exists but the emulator reports permission problems:

```bash
ls -l /dev/kvm
id
```

On systems configured with a `kvm` group, the account may need group access.

For example:

```bash
sudo usermod -aG kvm "$USER"
```

Log out and log back in before testing again.

Do not use broad permissions such as `chmod 777 /dev/kvm` as a normal solution.

## 11. Create the Cookbook AVD

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

## 12. Start the Emulator

Desktop Linux:

```bash
make emulator
```

Or:

```bash
emulator -avd cookbook_pixel_api_36
```

For a workstation without a graphical desktop, see the headless section in [emulator.md](./emulator.md).

## 13. Verify ADB

```bash
adb devices
```

Then:

```bash
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
adb shell getprop ro.build.version.sdk
```

## 14. Physical Android Devices on Linux

Unlike Windows, Linux does not use the Google USB driver package described for Windows hosts. However, Linux USB permissions and udev rules can affect device access.

Start with:

```bash
adb devices
```

If the phone does not appear:

```bash
lsusb
```

Then verify:

- Developer options are enabled.
- USB debugging is enabled.
- The phone is unlocked.
- The RSA debugging prompt was accepted.
- Linux USB permissions permit access to the device.

For Android Cookbook v0.1, a physical device remains optional.

## 15. Headless / Remote Linux Workstations

Do not start with this mode for v0.1 unless necessary.

A remote workstation often introduces extra concerns:

```text
SSH session
    ↓
No desktop display
    ↓
Headless Android Emulator
    ↓
KVM permissions
    ↓
ADB lifecycle
```

Once the normal local emulator works, a later environment version can add a dedicated headless launcher such as:

```bash
emulator \
  -avd cookbook_pixel_api_36 \
  -no-window \
  -no-audio
```

This is a useful future step for CI and Device Test Platform experiments, but it is not required for Android Environment v0.1.

## 16. Useful Checks

```bash
java -version
sdkmanager --version
adb version
fastboot --version
emulator -version
emulator -accel-check
emulator -list-avds
adb devices
ls -l /dev/kvm
```

Or:

```bash
make doctor
```

## 17. Common Problems

### `sdkmanager: command not found`

```bash
ls "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
echo "$PATH"
source ~/.bashrc
```

### Emulator reports KVM unavailable

Check:

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
ls -l /dev/kvm
lsmod | grep kvm
emulator -accel-check
```

Possible causes include:

- BIOS/UEFI virtualization disabled.
- Running inside another VM without nested virtualization.
- KVM unavailable on the host.
- Permission denied on `/dev/kvm`.

### ADB sees no devices

Restart the ADB server:

```bash
adb kill-server
adb start-server
adb devices
```

### Emulator is running remotely but no UI appears

You are probably on a headless host. Use a headless emulator configuration instead of assuming a desktop display exists.

## 18. Done

Return to [setup.md](./setup.md) and continue with the common setup flow.
