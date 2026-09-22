# Android Environment v0.4.1 — Headless Emulator

## Overview

Android Environment v0.4.1 focuses on running an Android Emulator in **headless mode** on a Linux workstation.

The goal of this version is not CI yet.

The goal is simpler:

> Start, observe, verify, and stop an Android Emulator without a graphical window.

This version builds on v0.4.0, where Linux and KVM acceleration were validated first.

---

# 1. Learning Goal

In earlier versions, the Android Emulator was mainly treated as an application that could be launched manually.

In v0.4.1, the Emulator becomes a managed process.

The lifecycle becomes:

```text
STOPPED
   |
   v
STARTING
   |
   v
ADB CONNECTED
   |
   v
BOOTING
   |
   v
READY
   |
   v
STOPPED
```

The important idea is:

```text
Emulator process exists
        !=
ADB device is available
        !=
Android boot is complete
```

A process can be running while Android is still booting.

---

# 2. Prerequisites

v0.4.1 assumes v0.4.0 has already passed.

Run:

```bash
make kvm-check
```

Expected result:

```text
[INFO] Checking KVM device
[ OK ] KVM device exists: /dev/kvm
[ OK ] KVM device is readable and writable

[INFO] Checking Emulator acceleration
[ OK ] Android Emulator acceleration is available

Linux / KVM Check PASSED
```

The workstation also needs:

```bash
adb
emulator
```

Check:

```bash
command -v adb
command -v emulator
```

Example:

```text
/home/codespace/Android/Sdk/platform-tools/adb
/home/codespace/Android/Sdk/emulator/emulator
```

---

# 3. Scope

v0.4.1 intentionally keeps the scope small.

Supported:

```text
Linux
x86_64
KVM acceleration
one Android Emulator
one fixed emulator serial
headless execution
start
status
stop
boot readiness check
AVD identity check
```

Not included yet:

```text
multiple emulators
dynamic port allocation
CI workflow
smoke test
advanced crash recovery
PID registry
process supervision
automatic restart
parallel execution
```

Those belong to later versions.

---

# 4. Project Structure

Relevant files:

```text
android-environment/
├── config/
│   └── android.env
│
├── scripts/
│   ├── headless_start.sh
│   ├── headless_status.sh
│   ├── headless_stop.sh
│   ├── check_kvm.sh
│   │
│   └── lib/
│       └── headless.sh
│
├── artifacts/
│   └── headless-emulator.log
│
├── tests/
│   └── test_headless.py
│
└── docs/
    └── headless.md
```

The responsibilities are separated as follows:

```text
headless.sh
    |
    +-- reusable lifecycle helper functions

headless_start.sh
    |
    +-- validate environment
    +-- start emulator
    +-- wait until ready

headless_status.sh
    |
    +-- inspect current emulator state

headless_stop.sh
    |
    +-- verify emulator identity
    +-- request graceful shutdown
```

---

# 5. Configuration

Example `config/android.env`:

```bash
ANDROID_API_LEVEL=36

AVD_NAME="cookbook_pixel_api_36"

SYSTEM_IMAGE_FLAVOR="google_apis"

ANDROID_HOME="${ANDROID_HOME:-${HOME}/Android/Sdk}"

EMULATOR_BOOT_TIMEOUT_SECONDS=180
```

The current implementation assumes the emulator runs on:

```text
emulator-5554
```

The port is explicitly configured as:

```bash
-port 5554
```

This keeps v0.4.1 simple and deterministic.

---

# 6. Headless Mode

A normal Android Emulator opens a graphical window.

For example:

```bash
emulator -avd cookbook_pixel_api_36
```

Headless mode removes that GUI dependency.

The core option is:

```bash
-no-window
```

Example:

```bash
emulator \
    -avd cookbook_pixel_api_36 \
    -port 5554 \
    -no-window \
    -no-audio \
    -no-boot-anim \
    -no-snapshot
```

This is useful for environments such as:

```text
remote Linux workstation
SSH session
GitHub Codespace
CI runner
server
automation worker
```

---

# 7. Starting the Emulator

Run:

```bash
make headless-start
```

The start flow is:

```text
Check adb
    |
Check emulator
    |
Check Linux / KVM
    |
Check AVD exists
    |
Check another emulator is not already running
    |
Start emulator in background
    |
Wait for Android boot
    |
Verify AVD identity
    |
READY
```

Example output:

```text
[INFO] Checking KVM device
[ OK ] KVM device exists: /dev/kvm
[ OK ] KVM device is readable and writable

[INFO] Checking Emulator acceleration
[ OK ] Android Emulator acceleration is available

Linux / KVM Check PASSED

Starting cookbook_pixel_api_36 (headless)
Log: /workspaces/android-environment/artifacts/headless-emulator.log
Launcher PID: 37978

READY: cookbook_pixel_api_36 (emulator-5554)
```

---

# 8. Background Process

The Emulator is started with:

```bash
nohup emulator \
    -avd "${AVD_NAME}" \
    -port 5554 \
    -no-window \
    -no-audio \
    -no-boot-anim \
    -no-snapshot \
    >"${log}" 2>&1 </dev/null &
```

Important shell concepts:

## `nohup`

```bash
nohup
```

allows the process to continue running even if the launching shell exits.

---

## `&`

```bash
&
```

runs the command as a background process.

---

## `$!`

After starting a background process:

```bash
pid=$!
```

`$!` contains the PID of the most recently started background process.

Example:

```text
Launcher PID: 37978
```

---

## Output redirection

```bash
>"${log}" 2>&1
```

means:

```text
stdout -> log file
stderr -> same log file
```

---

## `/dev/null`

```bash
</dev/null
```

prevents the background Emulator from depending on terminal input.

---

# 9. Emulator Readiness

Starting the Emulator process does not mean Android is ready.

v0.4.1 uses two checks.

## Step 1 — ADB state

```bash
adb -s emulator-5554 get-state
```

Expected:

```text
device
```

Possible states include:

```text
offline
device
```

`device` means the ADB connection is usable.

---

## Step 2 — Android Boot Property

Run:

```bash
adb -s emulator-5554 shell getprop sys.boot_completed
```

Expected:

```text
1
```

The Emulator is considered ready only when:

```text
ADB state == device
AND
sys.boot_completed == 1
```

Conceptually:

```text
Process running
      |
      v
ADB connected
      |
      v
Android boot complete
      |
      v
READY
```

---

# 10. `boot_ready()`

The lifecycle helper is implemented in:

```text
scripts/lib/headless.sh
```

Example:

```bash
boot_ready() {

    [[ "$(adb -s "$EMULATOR_SERIAL" get-state \
        2>/dev/null)" == "device" ]] || return 1

    [[ "$(adb -s "$EMULATOR_SERIAL" \
        shell getprop sys.boot_completed \
        2>/dev/null | tr -d '\r')" == "1" ]]

}
```

This function follows the Unix convention:

```text
return code 0     success / ready
non-zero          not ready
```

Therefore other functions can simply use:

```bash
if boot_ready; then
    ...
fi
```

---

# 11. Waiting for Boot

Android boot takes time.

The runner therefore polls periodically:

```bash
wait_for_boot() {
    local timeout="${1:?timeout required}"
    local elapsed

    for ((elapsed=0; elapsed<timeout; elapsed++)); do

        if boot_ready; then
            return 0
        fi

        sleep 1

    done

    boot_ready
}
```

With:

```bash
EMULATOR_BOOT_TIMEOUT_SECONDS=180
```

the script waits for up to three minutes.

Conceptually:

```text
boot_ready?
    |
    +-- yes -> READY
    |
    +-- no
         |
         sleep 1 second
         |
         retry
```

This is polling.

---

# 12. Checking Status

Run:

```bash
make headless-status
```

Possible output:

```text
STOPPED
```

or:

```text
BOOTING or OFFLINE: emulator-5554
```

or:

```text
READY: cookbook_pixel_api_36 (emulator-5554)
```

The status logic checks:

```text
Is the emulator listed by ADB?
        |
        no
        |
     STOPPED

        yes
        |
Is Android boot-ready?
        |
        no
        |
BOOTING / OFFLINE

        yes
        |
Is this the expected AVD?
        |
        yes
        |
      READY
```

---

# 13. Checking AVD Identity

ADB serial alone does not tell us which AVD is running.

For example:

```text
emulator-5554
```

is only a runtime serial.

The AVD name can be retrieved using:

```bash
adb -s emulator-5554 emu avd name
```

Example:

```text
cookbook_pixel_api_36
OK
```

The helper function reads the first line:

```bash
avd_name_for_serial() {

    adb -s "$EMULATOR_SERIAL" \
        emu avd name \
        2>/dev/null |
        head -n 1 |
        tr -d '\r'

}
```

This allows the scripts to verify:

```text
runtime emulator
        ==
expected AVD
```

before performing operations such as stopping it.

---

# 14. Stopping the Emulator

Run:

```bash
make headless-stop
```

The stop script first checks:

```text
Does the emulator exist?
        |
Is ADB ready?
        |
Is this the expected AVD?
        |
Request shutdown
```

The actual shutdown command is:

```bash
adb -s emulator-5554 emu kill
```

Example:

```text
Stop requested for cookbook_pixel_api_36.
```

After shutdown:

```bash
make headless-status
```

should eventually show:

```text
STOPPED
```

---

# 15. Logs

The Emulator stdout and stderr are stored at:

```text
artifacts/headless-emulator.log
```

Inspect recent logs:

```bash
tail -100 artifacts/headless-emulator.log
```

Follow logs continuously:

```bash
tail -f artifacts/headless-emulator.log
```

Logs are especially useful when:

```text
Emulator exits immediately
ADB remains offline
boot timeout occurs
KVM fails
system image fails to load
graphics initialization fails
```

---

# 16. Useful Debug Commands

## Check ADB devices

```bash
adb devices
```

Expected:

```text
List of devices attached
emulator-5554    device
```

---

## Check ADB state

```bash
adb -s emulator-5554 get-state
```

Expected:

```text
device
```

---

## Check Android boot

```bash
adb -s emulator-5554 shell getprop sys.boot_completed
```

Expected:

```text
1
```

---

## Check AVD name

```bash
adb -s emulator-5554 emu avd name
```

---

## Check Emulator process

```bash
pgrep -af emulator
```

---

## Check KVM

```bash
make kvm-check
```

---

## Check shell script syntax

```bash
bash -n scripts/headless_start.sh
bash -n scripts/headless_status.sh
bash -n scripts/headless_stop.sh
```

---

## Trace shell execution

```bash
bash -x scripts/headless_start.sh
```

This is useful when debugging variable values, command execution, and control flow.

---

# 17. Troubleshooting

## `ERROR: adb not found`

Check:

```bash
command -v adb
```

The Android Platform Tools directory should be in `PATH`.

Example:

```bash
export ANDROID_HOME="$HOME/Android/Sdk"

export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

---

## `ERROR: emulator not found`

Check:

```bash
command -v emulator
```

Add:

```bash
export PATH="$ANDROID_HOME/emulator:$PATH"
```

---

## `/dev/kvm` permission denied

Check:

```bash
ls -l /dev/kvm
id
```

Typical device permissions:

```text
crw-rw---- root kvm /dev/kvm
```

The current user must have permission to access the KVM device.

Validate:

```bash
test -r /dev/kvm &&
test -w /dev/kvm &&
echo "KVM ACCESS OK"
```

---

## `BOOTING or OFFLINE`

Check:

```bash
adb devices
```

If:

```text
emulator-5554    offline
```

ADB is not ready yet.

If:

```text
emulator-5554    device
```

then check:

```bash
adb -s emulator-5554 shell getprop sys.boot_completed
```

If it returns:

```text
1
```

Android boot is complete.

---

## Boot timeout

Inspect:

```bash
tail -100 artifacts/headless-emulator.log
```

Also verify:

```bash
adb devices
pgrep -af emulator
```

A timeout does not necessarily mean the process failed.

Possible states include:

```text
process alive but Android still booting
ADB offline
system image startup failure
emulator process exited
```

---

# 18. Shell Lessons Learned

v0.4.1 also introduces several useful Shell concepts.

## Shebang

Scripts use:

```bash
#!/usr/bin/env bash
```

Therefore execute them using:

```bash
./scripts/headless_start.sh
```

or:

```bash
bash scripts/headless_start.sh
```

Do not force Bash-specific scripts through:

```bash
sh scripts/headless_start.sh
```

because `/bin/sh` may not support options such as:

```bash
set -o pipefail
```

---

## `set -euo pipefail`

```bash
set -euo pipefail
```

provides basic defensive Shell behavior.

```text
-e            stop on command failure
-u            fail on undefined variables
-o pipefail   pipeline fails if a command inside it fails
```

---

## Exit Codes

Shell functions often communicate boolean state using exit codes.

For example:

```bash
boot_ready
```

does not need to print:

```text
true
```

Instead:

```text
0       ready
1       not ready
```

This allows:

```bash
if boot_ready; then
    ...
fi
```

---

# 19. Architecture

v0.4.1 adds another layer to the Android Environment architecture.

```text
+------------------------------------------------+
| Android Environment                            |
+------------------------------------------------+
                    |
                    v
+------------------------------------------------+
| Headless Lifecycle Scripts                     |
|                                                |
| start | status | stop | wait                   |
+------------------------------------------------+
                    |
                    v
+------------------------------------------------+
| Android SDK Tools                              |
|                                                |
| adb                  emulator                  |
+------------------------------------------------+
             |                    |
             |                    v
             |          +----------------------+
             |          | Emulator Process     |
             |          | -no-window           |
             |          +----------------------+
             |                    |
             |                    v
             |          +----------------------+
             |          | KVM Acceleration     |
             |          +----------------------+
             |                    |
             |                    v
             |               /dev/kvm
             |
             v
+------------------------------------------------+
| Android OS inside AVD                          |
|                                                |
| sys.boot_completed                             |
+------------------------------------------------+
```

The important separation is:

```text
Host Infrastructure
    Linux + KVM

Android Tooling
    adb + emulator

Virtual Device
    AVD

Guest OS
    Android

Lifecycle Automation
    start / status / stop
```

---

# 20. Relationship to Previous Versions

## v0.1 — Build

```text
Install Android SDK
Install adb
Install Emulator
Create AVD
```

Question:

> Can I build an Android development environment?

---

## v0.2 — Provision

```text
Pinned API level
Architecture detection
Idempotent installation
Environment validation
```

Question:

> Can I reproduce this environment reliably?

---

## v0.3 — Operate

```text
start
wait
status
stop
reset
```

Question:

> Can I control the Emulator lifecycle?

---

## v0.4.0 — Linux / KVM

```text
/dev/kvm
permissions
hardware acceleration
```

Question:

> Can this Linux workstation efficiently run Android Emulator?

---

## v0.4.1 — Headless Emulator

```text
-no-window
background process
ADB readiness
boot polling
headless lifecycle
```

Question:

> Can this workstation operate Android Emulator without a GUI?

---

# 21. What v0.4.1 Teaches

The main lesson is not simply:

```text
how to add -no-window
```

The deeper lesson is:

> A remote Android test environment is a stack of host infrastructure, process lifecycle, Android tooling, virtual hardware, and guest OS state.

A successful Emulator launch requires several independent conditions:

```text
Linux host               ✓
KVM                      ✓
device permission        ✓
Android Emulator         ✓
AVD                      ✓
process running          ✓
ADB available            ✓
Android boot complete    ✓
```

This is why:

```text
process started
```

is not equivalent to:

```text
test environment ready
```

---

# 22. Next Version

The next version is:

```text
v0.4.2 — Smoke Test
```

Its purpose is to answer:

> Once the headless Android Emulator reaches READY, can we automatically verify that it is actually usable?

Possible smoke checks include:

```text
adb connection
Android version
device model
package manager availability
simple shell command
basic filesystem access
```

CI integration remains outside this version and will be handled later.

```text
v0.4.0  Linux / KVM
   |
   v
v0.4.1  Headless Emulator
   |
   v
v0.4.2  Smoke Test
   |
   v
v0.4.3  CI / GitHub Actions
```
