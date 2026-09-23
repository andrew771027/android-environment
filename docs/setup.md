# Set up Android Environment

This guide covers Android Environment v0.4.1. Complete the host prerequisites, install the SDK packages, then create and start an Android Virtual Device (AVD). Run repository commands from the repository root.

## SDK target

The defaults come from [android.env](../config/android.env), [packages.txt](../config/packages.txt), and [platform.sh](../scripts/lib/platform.sh).

| Component | Target |
| --- | --- |
| Android release | Android 16 / API 36 |
| SDK Platform | `platforms;android-36` |
| macOS Apple Silicon image | `system-images;android-36;google_apis;arm64-v8a` |
| macOS Intel / Linux x86_64 image | `system-images;android-36;google_apis;x86_64` |
| Linux ARM64 image mapping | `system-images;android-36;google_apis;arm64-v8a` |
| Other SDK packages | `platform-tools`, `emulator` |
| AVD name / hardware profile | `cookbook_pixel_api_36` / `pixel_7` |
| Command-Line Tools download | 22.0 / build 15859902 |

Linux ARM64 has a package mapping in the scripts; this is not a verified emulator host. The KVM check and headless start require Linux x86_64.

The SDK target describes the installed platform and emulator image. This repository does not configure an application's `targetSdk` or `compileSdk`, and does not install Build Tools or NDK by default.

### Version limits

The download instructions use a fixed Command-Line Tools archive. The scripts do not enforce its version. Platform Tools, Emulator, SDK Platform, and system-image revisions are not locked, so new installations can resolve to different revisions under the same package IDs.

Use `sdkmanager --list_installed` to record installed revisions. Use `cat "$ANDROID_HOME/cmdline-tools/latest/source.properties"` to inspect the Command-Line Tools version.

### SDK management tools

As checked on 2026-09-23, Google marks [`sdkmanager` as deprecated](https://developer.android.com/tools/sdkmanager) and recommends Android CLI's `android sdk` command. This refers to the management tool, not the Android SDK as a whole.

This repository still calls `sdkmanager` and `avdmanager`. Migration to Android CLI is outside v0.4.1's scope.

## 1. Install host prerequisites

Follow [macOS setup](./macos.md) or [Linux setup](./linux.md). These guides include the Google download URL and a one-line download command. Android Studio is optional.

Set the SDK location and tools path in your shell:

```bash
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

For persistent settings, add these lines to `~/.zshrc` on macOS or `~/.bashrc` when using Bash on Linux. All tools on `PATH` should belong to the same SDK installation.

The extracted Command-Line Tools must have this layout:

```text
$ANDROID_HOME/cmdline-tools/latest/
├── bin/
│   ├── sdkmanager
│   └── avdmanager
├── lib/
├── NOTICE.txt
└── source.properties
```

Check the prerequisites:

```bash
java -version
sdkmanager --version
make bootstrap
```

Bootstrap checks Java and unzip and creates the SDK directory. It does not download or install tools.

## 2. Install SDK packages

```bash
make install-sdk
```

The installer reads `config/packages.txt`, adds the configured platform and host-specific system image, and skips package IDs already installed. It does not update installed packages. Review and accept SDK licenses when prompted. To review outstanding licenses separately:

```bash
sdkmanager --licenses
```

Check the result:

```bash
sdkmanager --list_installed
adb version
emulator -version
```

## 3. Create the AVD

```bash
make create-avd
emulator -list-avds
make validate
```

The list should include `cookbook_pixel_api_36`. Validation should finish with `FAIL=0`. Creation reuses an existing AVD with that name; it does not compare or repair its configuration. See [validation](./validation.md) for the exact checks.

## 4. Start Android

For a desktop session on macOS or Linux:

```bash
make emulator-start
make emulator-status
```

For Linux x86_64 without a display:

```bash
make headless-start
make headless-status
```

Headless start requires KVM access and no existing emulator in the ADB list. It uses port 5554. See [headless operation](./headless.md) before using it on a shared host.

Both start commands wait for Android boot completion. If boot times out, inspect `emulator.log` for desktop mode or `artifacts/headless-emulator.log` for headless mode. A timeout does not automatically stop the background process.

## 5. Verify and stop the device

```bash
adb devices
adb shell getprop sys.boot_completed
adb shell getprop ro.build.version.sdk
```

Expected property values are `1` and `36`. When multiple devices are connected, pass `-s SERIAL` to ADB.

Use the stop command for the workflow you started:

```bash
make emulator-stop
```

or:

```bash
make headless-stop
```

Headless stop sends a shutdown request after checking readiness and identity; it does not wait for disconnection. Desktop stop waits up to 30 polling seconds.

For test setup and coverage, see [testing](./testing.md). For physical-device access and day-to-day commands, see the host guides and [emulator guide](./emulator.md).
