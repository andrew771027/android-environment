# Configuration

Android Environment v0.2 separates project defaults from the static SDK package list.

## `config/android.env`

| Variable | v0.2 default | Purpose |
| --- | --- | --- |
| `ANDROID_API_LEVEL` | `36` | Pinned Android API level |
| `ANDROID_PLATFORM` | `platforms;android-36` | Platform derived from the API level |
| `AVD_NAME` | `cookbook_pixel_api_36` | Project AVD derived from the API level |
| `AVD_DEVICE` | `pixel_7` | `avdmanager` hardware profile ID |
| `SYSTEM_IMAGE_FLAVOR` | `google_apis` | Emulator image flavor |
| `ANDROID_HOME` | `$HOME/Android/Sdk` | SDK root unless set by the caller |

For a custom SDK location:

```bash
export ANDROID_HOME="/path/to/Android/Sdk"
make validate
```

Ensure its SDK tools are also on `PATH`.

## `config/packages.txt`

This file contains one `sdkmanager` package per line. Blank lines and `#` comments are ignored. The v0.2 list is:

```text
platform-tools
emulator
platforms;android-36
```

The installer also checks the derived platform and architecture-specific system image. Installed packages are skipped, so rerunning `make install-sdk` is safe.

## Changing the Baseline

When changing the API level, update `ANDROID_API_LEVEL` and keep the platform entry in `config/packages.txt` consistent. The API affects `ANDROID_PLATFORM`, `AVD_NAME`, and the system-image package.

Confirm that the desired image and hardware profile exist:

```bash
sdkmanager --list | grep 'system-images;android-<API>'
avdmanager list device -c
```

Then run:

```bash
make install-sdk
make create-avd
make validate
```

Changing `AVD_NAME` changes which AVD `make emulator` starts and `make clean` deletes. Cleanup does not delete the SDK or unrelated AVDs.

Keep portable defaults in `android.env`, static packages in `packages.txt`, and machine-specific SDK paths in the shell environment. Do not commit SDK contents or AVD data.
