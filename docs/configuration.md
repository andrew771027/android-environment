# Configuration

Android Environment v0.4.1 reads defaults from [config/android.env](../config/android.env) and package IDs from [config/packages.txt](../config/packages.txt).

## SDK and AVD defaults

| Variable | Default | Used for |
| --- | --- | --- |
| `ANDROID_HOME` | `$HOME/Android/Sdk` | SDK root; preserves a value supplied by the caller |
| `ANDROID_API_LEVEL` | `36` | Platform, system-image, and AVD-name construction |
| `ANDROID_PLATFORM` | `platforms;android-36` | SDK Platform package |
| `SYSTEM_IMAGE_FLAVOR` | `google_apis` | System-image package |
| `AVD_NAME` | `cookbook_pixel_api_36` | AVD creation, launch, headless identity check, and deletion |
| `AVD_DEVICE` | `pixel_7` | Hardware profile for AVD creation |

For a custom SDK directory:

```bash
export ANDROID_HOME="/path/to/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
make validate
```

Except for `ANDROID_HOME`, the file assigns values unconditionally. Edit the file to change those defaults; exporting a same-named variable before running Make will not override them.

## Boot and shutdown settings

| Variable | Default | Desktop workflow | Headless workflow |
| --- | --- | --- | --- |
| `EMULATOR_BOOT_TIMEOUT_SECONDS` | `180` | Boot polling budget | Boot polling budget |
| `EMULATOR_BOOT_POLL_INTERVAL_SECONDS` | `2` | Delay between boot checks | Not used; fixed at 1 second |
| `EMULATOR_NO_SNAPSHOT_LOAD` | `true` | Adds `-no-snapshot-load` on start | Not used; start always uses `-no-snapshot` |
| `EMULATOR_NO_BOOT_ANIMATION` | `true` | Adds `-no-boot-anim` on start | Not used; flag is always enabled |
| `EMULATOR_PORT` | `5554` | Not used | Not read; launcher hardcodes port 5554 |
| `EMULATOR_SERIAL` | `emulator-5554` | Not used | Library overwrites it with `emulator-5554` |
| `EMULATOR_STOP_TIMEOUT_SECONDS` | `30` | Not used; stop hardcodes 30 seconds | Not used; stop does not wait |
| `EMULATOR_POLL_INTERVAL_SECONDS` | `2` | Not used | Not used |

Desktop reset always adds `-wipe-data -no-snapshot-load -no-boot-anim`. Its wait for the previous emulator to disconnect has no timeout.

Polling budgets count sleep time. They do not bound individual ADB calls or total elapsed time.

## SDK packages

`config/packages.txt` contains:

```text
platform-tools
emulator
platforms;android-36
```

The installer ignores blank lines and comments, then also checks `ANDROID_PLATFORM` and the host-specific system image. It skips installed package IDs rather than updating them. Package revisions are not locked.

The validator checks the four expected IDs: Platform Tools, Emulator, the configured platform, and the system image. It does not validate arbitrary extra entries added to `packages.txt`.

## Keep related settings consistent

If a future change adjusts the API level, update both `ANDROID_API_LEVEL` and the platform entry in `packages.txt`. The default AVD name and system-image path derive from that API level.

AVD creation checks for an existing name; it does not repair an existing AVD after a configuration change. The integration test also hardcodes `cookbook_pixel_api_36`, so changes to the AVD name require a matching test change.

This release retains API 36 and the existing SDK management tools. See [setup](./setup.md) for the target and migration scope.
