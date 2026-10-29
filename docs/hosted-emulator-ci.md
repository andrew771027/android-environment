# GitHub hosted emulator CI — v0.4.6

The [hosted workflow](../.github/workflows/hosted-emulator.yml) provisions an Android API 36 emulator on `ubuntu-24.04` and runs the repository's headless smoke and cleanup scripts. This validates Android runtime capabilities; it does not build or install an APK. Configuration is implemented; a successful remote run must be established from GitHub Actions logs.

## Triggers and runner

The workflow runs on pushes to every branch, manual dispatch, and pull requests changing `scripts/**`, `config/**`, `tests/**`, `Makefile`, or the hosted workflow itself. Documentation-only pull requests do not trigger it. The job has a 20-minute timeout, read-only contents permission, and concurrency grouped by Git ref; a new run cancels an earlier run in that group.

The separate [unit workflow](../.github/workflows/ci.yml) runs selected Shell syntax checks and unit tests on `ubuntu-latest`, without starting Android. Both workflows install Python 3.14 and the declared pytest range. The hosted job currently does not invoke pytest or the integration-test Make target.

## Provisioning sequence

1. Resolve the SDK root from nonempty `ANDROID_HOME`, falling back to `ANDROID_SDK_ROOT`. Fail if neither is set or `cmdline-tools/latest/bin/sdkmanager` is not executable.
2. Export both SDK-root variables and add Command-Line Tools, Platform Tools, and Emulator directories to the job PATH. Set `ANDROID_AVD_HOME=$RUNNER_TEMP/android-avd` to isolate AVD storage.
3. Print host, Java, SDK-command, and KVM diagnostics.
4. Install a KVM udev rule, reload and trigger it, and apply `chmod a+rw /dev/kvm`. Require readable and writable access.
5. Attempt SDK license acceptance, then run `make install-sdk` and `make kvm-check`. The license pipeline ignores its own failure; later provisioning commands must still succeed.
6. Create the AVD directory, run `make create-avd`, `make validate`, and list AVDs.
7. Run `make hosted-emulator-ci`.

The workflow relies on the runner's existing Command-Line Tools rather than downloading a ZIP. Repository configuration selects `system-images;android-36;google_apis;x86_64`, AVD `cookbook_pixel_api_36`, and profile `pixel_7`. `make install-sdk` skips installed package IDs; package revisions are not locked. See [configuration](./configuration.md).

AVD creation checks required commands and the system image, then skips an existing exact AVD name. For a new AVD it validates the exact hardware profile, calls `avdmanager create avd`, and verifies the result through `emulator -list-avds`. Listing failures abort. A missing post-creation name prints AVD-related environment variables and `avdmanager list avd` diagnostics.

## Runtime and cleanup

`make hosted-emulator-ci` invokes [ci_headless_smoke.sh](../scripts/ci_headless_smoke.sh); the former `ci-headless-smoke` Make target is no longer defined. The wrapper creates a private PID directory, registers EXIT/INT/TERM traps, launches headless Android at `emulator-5554`, waits for readiness and AVD identity, and runs six smoke checks: ADB state, boot completion, SDK property, model, Package Manager, and shell execution.

Cleanup validates the tracked process command, AVD, and port before TERM/KILL. Startup refusal preserves existing emulators. A workflow failure remains the exit result; cleanup failure makes an otherwise successful run fail. SIGKILL and forced runner termination cannot guarantee trap completion. See [CI and cleanup](./ci-cleanup.md) for ownership and exit-code details.

## Diagnostics and artifacts

Both diagnostic collection and artifact upload use `always()`. `artifacts/hosted-ci-diagnostics.txt` records the host, KVM device, acceleration output, AVD list, and ADB devices. `artifacts/headless-emulator.log` contains emulator output when launch reaches that stage. Diagnostics are collected after runtime cleanup, so an empty ADB list can be expected after success.

The upload is named `hosted-emulator-${{ github.run_id }}`, includes `artifacts`, retains files for seven days, and warns if files are absent. CI PID files are in a temporary directory outside this upload; failed cleanup retains their path in the log.

For failures, inspect the first failing step: SDK path resolution, KVM access, package installation, acceleration, AVD creation, boot, smoke, or cleanup. Artifact collection is an attempt, not proof that every diagnostic command succeeded.

## Preflight helper limits

[hosted_ci.sh](../scripts/lib/hosted_ci.sh) implements Linux x86_64 selection, SDK-root precedence, and KVM file-access checks. Eight [unit cases](../tests/test_hosted_ci.py) cover these helpers with fake paths; they do not exercise a real KVM device or the preflight entry point.

`make hosted-ci-check` invokes [check_hosted_ci.sh](../scripts/check_hosted_ci.sh), but the hosted workflow does not call it. The entry point currently reads `GItHUB_ACTIONS` instead of `GITHUB_ACTIONS` and expands `${detect_os}` / `${detect_arch}` instead of calling the functions. With `set -u`, those unset variables abort execution after the environment check. Do not treat passing helper tests as evidence that this entry point works.

See [testing](./testing.md) for local results and unverified runtime paths.
