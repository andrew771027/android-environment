# Android Emulator, virtual machines, and containers

Android Environment v0.4.1 runs Android Emulator as a host process. It includes desktop lifecycle commands and a Linux x86_64 headless workflow. It does not include a Docker image, container launcher, or CI workflow.

## What each layer provides

| Component | Role |
| --- | --- |
| SDK tools | Host programs for installing packages and communicating with devices |
| AVD | Virtual-device configuration and persistent user data |
| System image | Android system files used by the virtual device |
| Emulator | Host process that runs the virtual Android device |
| Virtual machine | A guest operating system with its own kernel and virtual hardware |
| Linux container | Isolated processes that use the host Linux kernel |

An Android Emulator runs a guest Android system. A container isolates host processes. Placing an emulator in a container adds process isolation around the emulator; it does not remove the need to run the guest system.

## The repository's Linux workflow

```mermaid
flowchart TD
    Host[Linux x86_64 host] --> Emulator[Android Emulator process]
    KVM[/dev/kvm access] --> Emulator
    AVD[Configured AVD and system image] --> Emulator
    Emulator --> Android[Android guest]
    ADB[Host adb] --> Android
```

`make headless-start` checks Linux/KVM, launches the emulator without a window, and waits for ADB and Android boot readiness. It uses software graphics and still requires KVM access. See [headless operation](./headless.md).

`adb shell` runs inside the Android guest. It does not open a shell in the host or a surrounding container.

## Running inside a Linux container or VM

Installing Java and the SDK in a container provides the tools. Emulator acceleration also depends on the outer environment exposing the required virtualization capability and allowing access to `/dev/kvm`.

Check inside the environment where the emulator will run:

```bash
ls -l /dev/kvm
id
emulator -accel-check
```

A device node can be present but inaccessible because its numeric group ID does not match a group available to the container user. See [Linux permissions](./linux.md#the-device-group-has-no-name-in-the-container).

When Linux itself runs in a VM, the outer virtualization setup determines whether the guest can use hardware acceleration. The repository checks access; it does not configure the outer VM or container.

## macOS

The documented macOS workflow runs the SDK and emulator directly on macOS. Its acceleration check is `emulator -accel-check`; the Linux KVM script does not apply.

Linux containers on macOS run through a Linux VM. Running an emulator inside that environment adds a separate virtualization dependency and is not covered by this repository's host tests. Use the [macOS setup guide](./macos.md) for the documented desktop workflow.

## Physical devices

ADB can communicate with either an emulator or an authorized physical Android device. This makes many shell and diagnostic commands reusable, but it does not make virtual and physical hardware behavior identical.

The `pixel_7` AVD profile provides a virtual-device configuration. Tests that depend on physical USB, sensors, power behavior, or bootloader support need separate device validation.

## Verification scope

The repository's mock tests exercise Bash helpers with fake commands. They do not verify a VM, container, or KVM host. The two integration tests check AVD listing and Android boot completion on an already running emulator. See [testing](./testing.md) before treating those results as evidence for a deployment environment.
