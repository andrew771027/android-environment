# Optional Build Tools — v0.4.3

Android Environment v0.4.3 adds a separate installation and validation path for Android SDK Build Tools. Emulator operation can continue without this package. An application repository uses its own Gradle Wrapper and Android Gradle Plugin (AGP) to build APKs.

## Install and validate

Complete [SDK setup](./setup.md), then run from this repository:

```bash
make install-build-tools
make validate-build-tools
```

The default in [android.env](../config/android.env) is:

```bash
ANDROID_BUILD_TOOLS_VERSION="36.0.0"
```

The package is `build-tools;36.0.0`, installed under `$ANDROID_HOME/build-tools/36.0.0`. Other Build Tools versions can coexist in the SDK. This setting does not force an application's AGP to use that version.

`make install-sdk` does not install Build Tools. The Build Tools installer constructs the package ID from `ANDROID_BUILD_TOOLS_VERSION`; it does not read [build-packages.txt](../config/build-packages.txt). That file currently records the baseline package as a reference.

## Installer behavior

[install_build_tools.sh](../scripts/install_build_tools.sh) checks configuration and `sdkmanager`, then tests whether the versioned directory exists. If it exists, installation is skipped. Otherwise, it runs `sdkmanager "build-tools;36.0.0"` and checks the directory again.

This directory check does not confirm package metadata or completeness. A partially installed directory is also skipped; use the validator to detect missing required binaries. The installer does not repair an incomplete installation. It does not install Java, Gradle, or an application's dependencies.

## Validator behavior

[validate_build_tools.sh](../scripts/validate_build_tools.sh) checks:

| Check | Implementation |
| --- | --- |
| Java | `java` command exists on `PATH` |
| Installed version | `$ANDROID_HOME/build-tools/36.0.0` is a directory |
| Required tools | `aapt2`, `apksigner`, and `zipalign` have executable permission |

Missing requirements cause a non-zero exit. A missing versioned directory includes the recovery command `make install-build-tools`.

The validator does not run these binaries or inspect Java/tool versions. It does not check `d8`, AGP/Gradle compatibility, dependency downloads, signing credentials, or an actual APK build. `make validate` remains a separate runtime provisioning check.

## Check tools manually

```bash
"$ANDROID_HOME/build-tools/36.0.0/aapt2" version
"$ANDROID_HOME/build-tools/36.0.0/apksigner" version
```

`zipalign` does not support `-h` in the tested 36.0.0 installation; an invalid help flag is not evidence of a failed installation. To align an unsigned APK and check it:

```bash
"$ANDROID_HOME/build-tools/36.0.0/zipalign" 4 unsigned.apk aligned.apk
"$ANDROID_HOME/build-tools/36.0.0/zipalign" -c -v 4 aligned.apk
```

These commands demonstrate ordinary four-byte alignment. Native libraries can require additional page alignment; see Google's [zipalign reference](https://developer.android.com/tools/zipalign). With `apksigner`, align before signing because changing the APK afterward invalidates its signature. See the [apksigner reference](https://developer.android.com/tools/apksigner).

## Build an application

From the application repository that contains `gradlew`:

```bash
./gradlew assembleDebug
```

This environment repository does not contain an Android app or Gradle Wrapper. The application controls AGP, Gradle, SDK levels, dependencies, variants, and signing. Its Java requirements may differ from this repository's JDK recommendation. See [Gradle and APK lifecycle](./gradle-apk-lifecycle.md).

## Tests and verification

Six [mock tests](../tests/test_build_tools.py) cover package-name construction, directory resolution, directory presence/absence, all three required executables, and a missing `zipalign`. They use temporary directories and executable stubs, not real SDK binaries. They do not run the installer or validator entry points or build an APK.

On 2026-10-08, `make validate-build-tools` passed on the current macOS Intel host with Build Tools 36.0.0. The unit suite reported `28 passed, 2 deselected`; integration tests separately reported `2 passed, 28 deselected`. The integration cases concern emulator readiness, not Build Tools. See [testing](./testing.md).
