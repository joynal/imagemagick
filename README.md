# ImageMagick Standalone Binaries

This directory contains standalone binaries of ImageMagick for Linux (`amd64` and `arm64`), built from the latest source on Ubuntu 24.04.

## Contents
*   `magick-linux-amd64`: Binary for 64-bit Intel/AMD systems (x86_64).
*   `magick-linux-arm64`: Binary for 64-bit ARM systems (aarch64).

## Requirements
*   **OS**: Linux (Ubuntu 24.04 recommended, or any distro with compatible glibc).
*   **Dependencies**: The binaries are **statically linked** for most libraries (JPEG, PNG, TIFF, WebP, Freetype). They only depend on standard system libraries (`glibc`, `libm`, `libgcc`).
    *   No external packages (`apt-get install ...`) are required for standard image formats.


## Usage
1.  Make the binary executable (if not already):
    ```bash
    chmod +x magick-linux-amd64
    ```

2.  Run commands:
    ```bash
    ./magick-linux-amd64 --version
    ./magick-linux-amd64 input.jpg output.png
    ./magick-linux-amd64 convert image.png -resize 50% resized.png
    ```

## Build Information
*   **Source**: [ImageMagick/ImageMagick](https://github.com/ImageMagick/ImageMagick) (Latest)
*   **Build Environment**: Ubuntu 24.04 Docker Container
*   **Configuration**: Static build (`--enable-static --disable-shared`), including support for JPEG, PNG, TIFF, WebP, etc.
