# Set up macOS

Prepare a macOS host for Android Environment v0.4.1. The SDK target is Android 16 / API 36. Android Studio is optional.

## 1. Check the architecture

```bash
uname -m
```

Use the Apple Silicon download for `arm64`, or the Intel download for `x86_64`. The installer selects the corresponding emulator image automatically.

## 2. Install prerequisites

With Homebrew installed, install the project's recommended JDK:

```bash
brew install openjdk@17
```

Follow Homebrew's installation output to make the JDK available in your shell. Check the tools used by the setup instructions:

```bash
java -version
command -v bash
command -v make
command -v curl
command -v unzip
```

macOS provides `curl` and `unzip`; no `wget` installation is needed.

## 3. Download Command-Line Tools

Download **Android SDK Command-Line Tools 22.0 / build 15859902** from [Google](https://developer.android.com/studio#command-line-tools-only).

Apple Silicon:

```bash
curl -LO https://dl.google.com/android/repository/commandlinetools-mac_arm64-15859902_latest.zip
```

Intel Mac:

```bash
curl -LO https://dl.google.com/android/repository/commandlinetools-mac_x86_64-15859902_latest.zip
```

Extract the archive and place its contents under `~/Android/Sdk/cmdline-tools/latest/`. The resulting executable must be `latest/bin/sdkmanager`, not `latest/cmdline-tools/bin/sdkmanager`.

## 4. Configure the shell

Add these lines to `~/.zshrc`:

```bash
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

Reload and verify:

```bash
source ~/.zshrc
sdkmanager --version
```

If you use another shell, put the exports in that shell's startup file.

## 5. Provision and start the emulator

From the repository root:

```bash
make bootstrap
make install-sdk
make create-avd
make validate
emulator -accel-check
make emulator-start
```

The baseline AVD is `cookbook_pixel_api_36`, using the `pixel_7` profile. Apple Silicon uses `system-images;android-36;google_apis;arm64-v8a`; Intel uses `system-images;android-36;google_apis;x86_64`.

After start succeeds:

```bash
adb devices
adb shell getprop ro.build.version.sdk
```

The API level should be `36`. Stop the emulator with `make emulator-stop`.

Use `emulator -accel-check` for macOS acceleration diagnostics. `make kvm-check` and `make headless-start` require Linux x86_64.

## Connect a physical device

Enable Developer options and USB debugging on the device, connect it by USB, then run `adb devices`. Unlock the device and accept the debugging authorization prompt if the state is `unauthorized`.

When a phone and emulator are both connected, use `adb -s SERIAL` for device commands. A physical device is optional for this setup.

## Troubleshoot

| Problem | Check |
| --- | --- |
| `sdkmanager` is missing | Check `cmdline-tools/latest/bin/sdkmanager`, then reload `~/.zshrc` |
| `adb` is missing | Run `make install-sdk`; check `platform-tools` on `PATH` |
| No AVD is listed | Run `make create-avd`, then `emulator -list-avds` |
| Acceleration is unavailable | Inspect `emulator -accel-check` and confirm the image ABI matches the host |
| Boot times out | Inspect `emulator.log`; the process may still be running |

See [setup](./setup.md) for the SDK version scope, [emulator operation](./emulator.md) for daily commands, and [testing](./testing.md) for test results.
