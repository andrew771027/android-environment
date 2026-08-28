# Android Environment on macOS

This guide prepares a macOS workstation for Android Environment v0.2 and Android Cookbook.

The preferred setup is command-line first. Android Studio is optional.

## 1. Check the Mac Architecture

```bash
uname -s
uname -m
```

Typical results:

Apple Silicon:

```text
Darwin
arm64
```

Intel Mac:

```text
Darwin
x86_64
```

The CPU architecture matters because emulator system images should match the host architecture when possible for hardware-accelerated virtualization.

## 2. Install Homebrew

If Homebrew is already installed:

```bash
brew --version
```

Otherwise install it from the official Homebrew project before continuing.

Homebrew is convenient but not a strict requirement of Android itself.

## 3. Install Java

For this repository, JDK 17 is the recommended baseline:

```bash
brew install openjdk@17
```

Check installation:

```bash
java -version
```

If `java` is not found, follow the Homebrew output to expose the JDK to macOS and update `PATH` if required.

Optional repository check:

```bash
/usr/libexec/java_home -V
```

## 4. Install Utility Dependencies

Check:

```bash
command -v curl
command -v unzip
```

macOS normally provides these already.

## 5. Create the Android SDK Directory

```bash
mkdir -p "$HOME/Android/Sdk/cmdline-tools"
```

This repository uses:

```text
~/Android/Sdk
```

as its default SDK location.

## 6. Install Android Command-Line Tools

Download the current **Android SDK Command-Line Tools for macOS** from the Android Developers download page.

Choose the package matching the host architecture when architecture-specific packages are offered.

After downloading, extract it into a temporary directory. For example:

```bash
mkdir -p /tmp/android-cmdline-tools
unzip ~/Downloads/commandlinetools-*-latest.zip \
  -d /tmp/android-cmdline-tools
```

Move the extracted `cmdline-tools` directory into the SDK using the `latest` layout:

```bash
mkdir -p "$HOME/Android/Sdk/cmdline-tools/latest"

cp -R /tmp/android-cmdline-tools/cmdline-tools/. \
  "$HOME/Android/Sdk/cmdline-tools/latest/"
```

Verify:

```bash
ls "$HOME/Android/Sdk/cmdline-tools/latest/bin"
```

You should see tools including:

```text
sdkmanager
avdmanager
```

## 7. Configure zsh

Modern macOS defaults to zsh.

Edit:

```bash
nano ~/.zshrc
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
source ~/.zshrc
```

Verify:

```bash
echo "$ANDROID_HOME"
sdkmanager --version
avdmanager --help | head
```

## 8. Install Android SDK Packages

From the Android Environment repository:

```bash
make install-sdk
```

Or run:

```bash
./scripts/install_sdk.sh
```

Verify core packages:

```bash
sdkmanager --list_installed
```

## 9. Architecture-aware Emulator Image

The environment script should detect:

```bash
uname -m
```

and choose the appropriate system image.

Conceptually:

```text
Apple Silicon (arm64)
    ↓
arm64-v8a Android system image

Intel Mac (x86_64)
    ↓
x86_64 Android system image
```

Do not hard-code an image package without checking that it exists for the selected Android API and channel:

```bash
sdkmanager --list
```

Search for Android 16 images:

```bash
sdkmanager --list | grep 'system-images;android-36'
```

Then install the architecture-compatible image selected by `config/android.env` / `install_sdk.sh`.

## 10. Verify Emulator Acceleration

Run:

```bash
emulator -accel-check
```

A healthy environment should report that virtualization support is usable.

If it does not, verify:

- macOS is supported by the installed Emulator version.
- The emulator package is current.
- The system image architecture matches the host architecture.
- No other virtualization configuration is interfering.

## 11. Create the Cookbook AVD

```bash
make create-avd
```

Then:

```bash
emulator -list-avds
```

Expected:

```text
cookbook_pixel_api_36
```

## 12. Start the Emulator

```bash
make emulator
```

Or:

```bash
emulator -avd cookbook_pixel_api_36
```

See [emulator.md](./emulator.md) for boot checks and lifecycle commands.

## 13. Test ADB

```bash
adb devices
```

Then:

```bash
adb shell getprop ro.product.model
adb shell getprop ro.build.version.sdk
```

## 14. Physical Pixel on macOS

macOS does not require the Google USB driver used by Windows.

For a physical Pixel:

1. Enable Developer options on the phone.
2. Enable USB debugging.
3. Connect the phone by USB.
4. Accept the RSA authorization dialog on the device.
5. Run:

```bash
adb devices
```

Expected:

```text
SERIAL_NUMBER    device
```

If it reports:

```text
unauthorized
```

unlock the phone and accept the USB debugging authorization dialog.

## 15. Useful Checks

```bash
java -version
sdkmanager --version
adb version
fastboot --version
emulator -version
emulator -accel-check
emulator -list-avds
adb devices
```

Or simply:

```bash
make doctor
```

Run the v0.2 strict provisioning check with:

```bash
make validate
```

## 16. Common Problems

### `sdkmanager: command not found`

Check:

```bash
ls "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
echo "$PATH"
```

Then reload:

```bash
source ~/.zshrc
```

### `adb: command not found`

Check:

```bash
ls "$ANDROID_HOME/platform-tools/adb"
```

If it is missing:

```bash
sdkmanager "platform-tools"
```

### Emulator is slow

Check:

```bash
emulator -accel-check
```

Also confirm that the AVD system image architecture matches the Mac CPU architecture.

### Emulator cannot find the AVD

```bash
emulator -list-avds
```

AVD configuration normally lives below the user's Android configuration directory, commonly under:

```text
~/.android/avd/
```

Do not commit this directory to Git.

## 17. Done

Return to [setup.md](./setup.md) and continue with the common setup flow.
