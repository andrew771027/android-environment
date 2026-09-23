# Host architecture and system images

Android Environment v0.4.1 uses [platform.sh](../scripts/lib/platform.sh) to select an Android system-image ABI during SDK installation, AVD creation, and validation.

## Host mapping

| OS from `uname -s` | CPU from `uname -m` | Normalized host | Image ABI |
| --- | --- | --- | --- |
| `Darwin` | `arm64` / `aarch64` | `darwin-arm64` | `arm64-v8a` |
| `Darwin` | `x86_64` / `amd64` | `darwin-x86_64` | `x86_64` |
| `Linux` | `arm64` / `aarch64` | `linux-arm64` | `arm64-v8a` |
| `Linux` | `x86_64` / `amd64` | `linux-x86_64` | `x86_64` |

Other values resolve to `unsupported`. This table describes code mappings, not verified host support. In particular, the Linux/KVM check and headless start accept only Linux x86_64.

## Package selection

The scripts combine API level, image flavor, and image ABI:

```text
system-images;android-<API>;<flavor>;<ABI>
```

With the repository defaults, Apple Silicon resolves to:

```text
system-images;android-36;google_apis;arm64-v8a
```

Intel Mac and Linux x86_64 resolve to:

```text
system-images;android-36;google_apis;x86_64
```

The mapping does not install virtualization support or prove that emulator binaries work on a host.

## Check the selection

```bash
uname -s
uname -m
make validate
```

The validator prints the normalized OS, CPU, and selected image ABI. `make install-sdk` prints its selection before installing packages.

Check acceleration separately with `emulator -accel-check`, or use `make kvm-check` on Linux x86_64. See [Linux and KVM](./linux-kvm.md) for details.
