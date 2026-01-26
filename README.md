# Static ImageMagick Builder for Linux

This repository provides scripts to build **standalone, statically linked binaries** of the latest ImageMagick (v7.1.2+) for Linux (`amd64` and `arm64`).

The resulting binaries are designed to run on minimal Linux distributions (e.g., distroless, Alpine, minimal Ubuntu) without requiring any external runtime dependencies (other than standard `glibc`).

## Features
*   **Multi-Architecture**: Builds for both `x86_64` (amd64) and `aarch64` (arm64).
*   **Statically Linked Delegates**: Includes static versions of common image libraries:
    *   `libjpeg-turbo` (JPEG)
    *   `libpng` (PNG)
    *   `libtiff` (TIFF)
    *   `libwebp` (WebP)
    *   `freetype` (Font rendering)
    *   `zlib`
*   **Minimal Runtime Footprint**: OpenMP is disabled to remove dependency on `libgomp`.
*   **Legacy Tool Support**: Includes symlinks for `convert`, `identify`, `compare`, etc.
*   **Bazel Ready**: Packages binaries into tarballs compatible with Bazel's `http_archive`.

## Prerequisites
*   Docker (Builds run inside a container to ensure reproducibility).

## Usage

1.  Clone this repository:
    ```bash
    git clone https://github.com/joynal/imagemagick-static-builder.git
    cd imagemagick-static-builder
    ```

2.  Run the build script:
    ```bash
    chmod +x build.sh
    ./build.sh
    ```

3.  Find the artifacts in `local-bin/`:
    *   `imagemagick-<version>-x86_64-static.tar.gz`
    *   `imagemagick-<version>-aarch64-static.tar.gz`

    Each tarball contains:
    ```text
    bin/
    ├── magick
    ├── convert -> magick
    ├── identify -> magick
    ├── compare -> magick
    └── ... (other tools)
    ```

## Bazel Integration

To use these pre-built static binaries in your Bazel project, add the following to your `MODULE.bazel` or `WORKSPACE` file (update `url` and `sha256` with your hosted values):

```starlark
http_archive(
    name = "imagemagick_linux_amd64",
    build_file_content = """filegroup(
    name = "bin",
    srcs = glob(["bin/*"]),
    visibility = ["//visibility:public"],
)""",
    url = "https://your-storage.com/imagemagick-7.1.2-14-x86_64-static.tar.gz",
    sha256 = "<SHA256_FROM_BUILD_OUTPUT>",
    strip_prefix = "bin",
)

http_archive(
    name = "imagemagick_linux_arm64",
    build_file_content = """filegroup(
    name = "bin",
    srcs = glob(["bin/*"]),
    visibility = ["//visibility:public"],
)""",
    url = "https://your-storage.com/imagemagick-7.1.2-14-aarch64-static.tar.gz",
    sha256 = "<SHA256_FROM_BUILD_OUTPUT>",
    strip_prefix = "bin",
)
```

## Verification

You can verify the produced binaries work in a minimal environment (simulating a production container) using the included script:

```bash
./verify.sh
```

This runs the binaries inside a clean `ubuntu:24.04` container with only basic system utilities installed to confirm no missing shared libraries.
