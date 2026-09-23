# Check Linux and KVM

Android Environment v0.4.1 provides a host check for **Linux x86_64**. Run it after installing the SDK Emulator package:

```bash
make kvm-check
```

[check_kvm.sh](../scripts/check_kvm.sh) checks the following in order and stops at the first failure:

1. The host OS is Linux.
2. The normalized architecture is `x86_64`.
3. `emulator` is on `PATH`.
4. `/dev/kvm` exists.
5. The current user can read and write `/dev/kvm`.
6. `emulator -accel-check` exits successfully.

The script returns 0 on success and non-zero on failure. It does not create an AVD or start an emulator.

`make headless-start` runs this check automatically. Desktop lifecycle commands and `make validate` do not. On macOS, use `emulator -accel-check` directly.

## Missing KVM device

Inspect CPU virtualization flags, loaded modules, and the device:

```bash
grep -Ec '(vmx|svm)' /proc/cpuinfo
lsmod | grep kvm
ls -l /dev/kvm
```

A non-zero flag count indicates visible CPU virtualization extensions, but does not establish that the current user can use KVM. Check firmware virtualization settings and host KVM configuration. In a VM or container, also check whether the outer host exposes the required virtualization and device access.

On Ubuntu/Debian, KVM tooling can be installed with:

```bash
sudo apt install -y qemu-kvm
```

Installing a package inside a container does not expose `/dev/kvm` from the host.

## Permission denied

```bash
ls -l /dev/kvm
id
test -r /dev/kvm && test -w /dev/kvm && echo "KVM ACCESS OK"
```

If access fails, follow the [device-group instructions](./linux.md#the-user-is-missing-from-the-device-group). That guide also covers Codespaces and numeric group IDs in containers.

## Acceleration check fails

Run the underlying command to see its diagnostic output:

```bash
emulator -accel-check
```

Resolve this failure before starting the headless workflow. Software graphics in headless mode does not replace CPU virtualization.

## Test coverage

[kvm.sh](../scripts/lib/kvm.sh) contains the device-existence, access, and acceleration helpers. Four [mock tests](../tests/test_kvm.py) cover device existence and acceleration command results. They do not test real KVM, device permissions, or the complete host-check script. See [testing](./testing.md) for results.
