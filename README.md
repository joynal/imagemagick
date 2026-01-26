# ImageMagick Standalone Binaries

This directory contains standalone binaries of ImageMagick for Linux (`amd64` and `arm64`), built from the latest source on Ubuntu 24.04.

## Contents
*   `magick-linux-amd64`: Binary for 64-bit Intel/AMD systems (x86_64).
*   `magick-linux-arm64`: Binary for 64-bit ARM systems (aarch64).

## Requirements
*   **OS**: Linux (Ubuntu 24.04 recommended, or any distro with compatible glibc).
*   **Dependencies**: The binaries are dynamically linked to several system libraries. You must install the following packages on Ubuntu 24.04:
    ```bash
    sudo apt-get install -y \
        libjpeg-turbo8 libpng16-16 libtiff6 libwebp7 libwebpmux3 libwebpdemux2 \
        libopenjp2-7 libgif7 librsvg2-2 libfontconfig1 libfreetype6 \
        libx11-6 libxext6 libxml2 libzip4 liblcms2-2 libgomp1 libjbig0 \
        ghostscript
    ```

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
