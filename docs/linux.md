# Set up Linux

Prepare a Linux host for Android Environment v0.4.1. These commands use Ubuntu/Debian package names. The headless workflow requires **Linux x86_64 with KVM** and uses Android 16 / API 36.

## 1. Check the host

```bash
uname -s
uname -m
cat /etc/os-release
```

For headless operation, the expected OS and architecture are `Linux` and `x86_64`. The provisioning code also maps ARM64 to an image ABI, but the KVM check rejects that host architecture. See [architecture detection](./architecture_detection.md).

## 2. Install prerequisites

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk make unzip wget
```

Verify:

```bash
java -version
command -v bash
command -v make
command -v unzip
command -v wget
```

## 3. Download Command-Line Tools

Download **Android SDK Command-Line Tools 22.0 / build 15859902** from [Google](https://developer.android.com/studio#command-line-tools-only):

```bash
wget https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip
```

Extract the archive and place its contents under `~/Android/Sdk/cmdline-tools/latest/`. Verify that `latest/bin/sdkmanager` exists; avoid an extra nested `cmdline-tools` directory.

## 4. Configure the shell

Add these lines to `~/.bashrc`:

```bash
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
```

Reload and verify:

```bash
source ~/.bashrc
sdkmanager --version
```

If you use zsh, use `~/.zshrc` instead.

## 5. Install packages and create the AVD

From the repository root:

```bash
make bootstrap
make install-sdk
make create-avd
make validate
```

On Linux x86_64, the image package is `system-images;android-36;google_apis;x86_64`. The AVD is `cookbook_pixel_api_36`, using the `pixel_7` profile.

## 6. Check KVM

```bash
make kvm-check
```

The check requires `/dev/kvm` to exist and be readable and writable by the current user. It also runs `emulator -accel-check`. It does not configure virtualization or install KVM.

If the check fails, inspect:

```bash
ls -l /dev/kvm
id
emulator -accel-check
```

See [Linux and KVM](./linux-kvm.md) for missing-device and acceleration failures. The following sections cover device permissions, including Codespaces and containers.

### The user is missing from the device group

A device can exist while remaining inaccessible to the current user. For example, `crw-rw---- root kvm` allows access to root and members of `kvm`.

Inspect the owner, numeric group, and current memberships:

```bash
stat -c 'uid=%u gid=%g user=%U group=%G mode=%A' /dev/kvm
id
getent group kvm
```

If the device is owned by `kvm` and the account is not a member:

```bash
sudo usermod -aG kvm "$USER"
```

Log out and reconnect so the session picks up the new membership. For a temporary shell with the new group, use `newgrp kvm`. Then verify:

```bash
id
test -r /dev/kvm && test -w /dev/kvm && echo "KVM ACCESS OK"
make kvm-check
```

This also applies to a Codespace where `/dev/kvm` is exposed but the `codespace` user lacks the device's group. Reconnecting the session may be necessary. Group membership cannot make an absent device or unavailable virtualization feature appear.

### The device group has no name in the container

An exposed device can have a numeric group ID that is missing from the container's group database. Check it before creating a group:

```bash
stat -c '%g' /dev/kvm
getent group "$(stat -c '%g' /dev/kvm)"
```

If the numeric group already exists, add the user to that group. If it is absent, and you administer the environment, create a matching group with an unused name. For example, when `kvm` is also unused:

```bash
KVM_GID="$(stat -c '%g' /dev/kvm)"
sudo groupadd -g "$KVM_GID" kvm
sudo usermod -aG kvm "$USER"
```

Reconnect or use `newgrp kvm`, then repeat the access check. Avoid `chmod 777 /dev/kvm`; use the device's group permissions.

## 7. Start Android

For a desktop session:

```bash
make emulator-start
make emulator-status
```

For a host without a display:

```bash
make headless-start
make headless-status
```

Headless start calls the KVM check, rejects existing emulators in the ADB list, and uses port 5554. Read [headless operation](./headless.md) for shutdown and failure handling.

Verify the API level:

```bash
adb devices
adb shell getprop ro.build.version.sdk
```

The expected value is `36`. Use `make emulator-stop` for the desktop workflow or `make headless-stop` for the headless workflow.

## Connect a physical device

Enable USB debugging, connect the device, and accept the debugging authorization prompt. Use `adb devices` to check the connection. If it is absent, inspect the USB connection with `lsusb` and check the distribution's USB permissions and udev rules. A physical device is optional.

## Troubleshoot

| Problem | Next step |
| --- | --- |
| `sdkmanager` is missing | Check the extracted directory layout and reload the shell configuration |
| SDK package or AVD is missing | Run `make install-sdk`, `make create-avd`, and `make validate` |
| KVM check fails | Check device access and [acceleration diagnostics](./linux-kvm.md) |
| Emulator does not finish booting | Inspect `emulator.log` or `artifacts/headless-emulator.log` |
| Multiple ADB devices are connected | Use `adb -s SERIAL` |

See [testing](./testing.md) for the checks performed during this documentation update. Mock tests do not verify this host's KVM or emulator behavior.
