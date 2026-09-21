# Linux / KVM prerequisites (v0.4)

## Learning objective

KVM is Linux kernel virtualization acceleration; headless mode only hides the emulator GUI. Both are needed for this exercise's accelerated, displayless CI.

## Host

Supported exercise baseline: Ubuntu 24.04, x86_64. Linux ARM and Docker-in-Docker are out of scope. A Linux VM needs nested virtualization and `/dev/kvm` exposed by its hypervisor.

```bash
uname -s
uname -m
ls -l /dev/kvm
```

On Ubuntu, if needed:

```bash
sudo apt-get update
sudo apt-get install -y qemu-kvm cpu-checker unzip curl libgl1 libpulse0
kvm-ok
```

An available `/dev/kvm` does not imply current-user permission. On a workstation, ask the administrator to configure the kvm group, then re-login. On an authorized CI runner only, the workflow configures a udev rule for the ephemeral runner. Do not blindly chmod shared workstation devices world-writable.

```bash
make kvm-check
```

`check_kvm.sh` verifies host OS, architecture, device existence/access, and `emulator -accel-check`. It fails rather than silently switching to a slow software emulator.

Official reference: https://developer.android.com/studio/run/emulator-acceleration
