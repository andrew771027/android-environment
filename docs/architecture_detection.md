# Architecture Detection

Android Environment v0.2 chooses an emulator system-image ABI from the workstation OS and CPU. `scripts/lib/platform.sh` is shared by SDK installation, AVD creation, and validation.

## Supported Matrix

| `uname -s` | `uname -m` | Normalized host | Image ABI |
| --- | --- | --- | --- |
| `Darwin` | `arm64` / `aarch64` | `darwin-arm64` | `arm64-v8a` |
| `Darwin` | `x86_64` / `amd64` | `darwin-x86_64` | `x86_64` |
| `Linux` | `arm64` / `aarch64` | `linux-arm64` | `arm64-v8a` |
| `Linux` | `x86_64` / `amd64` | `linux-x86_64` | `x86_64` |

Other combinations return `unsupported` and make installation or validation fail clearly.

## Detection Flow

```text
uname -s -> detect_os ----\
                           +-> resolve_system_image_arch -> image ABI
uname -m -> detect_arch --/
```

The package is assembled from configuration:

```bash
SYSTEM_IMAGE="system-images;android-${ANDROID_API_LEVEL};${SYSTEM_IMAGE_FLAVOR};${ANDROID_IMAGE_ARCH}"
```

With v0.2 defaults, Apple Silicon resolves to:

```text
system-images;android-36;google_apis;arm64-v8a
```

x86_64 Linux and Intel Mac resolve to:

```text
system-images;android-36;google_apis;x86_64
```

## Verify the Result

```bash
uname -s
uname -m
make validate
```

The validator's `Host` section shows the normalized OS, CPU, and image architecture. `make install-sdk` prints the same selection before checking packages.

A matching ABI gives the expected virtualization path and usually the best performance. Verify acceleration separately:

```bash
emulator -accel-check
```

Architecture detection does not enable macOS virtualization, Linux KVM, or nested virtualization.
