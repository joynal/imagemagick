#!/bin/bash
set -e

BIN_DIR="./local-bin"
echo "=== Verifying Binaries in Clean Ubuntu 24.04 Environment ==="

verify_arch() {
    PLATFORM=$1
    ARCH_NAME=$2
    BINARY="magick-linux-${ARCH_NAME}"

    if [ ! -f "$BIN_DIR/$BINARY" ]; then
        echo "Error: Binary $BINARY not found!"
        return 1
    fi

    echo "--- Verifying $ARCH_NAME on $PLATFORM ---"
    
    # We mount the binary into a clean ubuntu:24.04 container and run verification commands
    # We install minimal runtime deps if needed, but the goal is to see if it works with what's available 
    # or identify strictly necessary shared libs.
    # Note: Ubuntu 24.04 base is very minimal. It might miss libgomp or others if not statically linked.
    
    # We will try to run strictly.
    docker run --rm --platform "$PLATFORM" -v "$(pwd)/$BIN_DIR:/data" ubuntu:24.04 bash -c "
        echo '-> Checking dependencies (ldd):'
        apt-get update -qq
        # Install runtime dependencies required by dynamic linking
        apt-get install -y -qq \
            binutils \
            libjpeg-turbo8 \
            libpng16-16 \
            libtiff6 \
            libwebp7 \
            libwebpmux3 \
            libwebpdemux2 \
            libopenjp2-7 \
            libgif7 \
            librsvg2-2 \
            libfontconfig1 \
            libfreetype6 \
            libx11-6 \
            libxext6 \
            libxml2 \
            libzip4 \
            liblcms2-2 \
            libgomp1 \
            libjbig0 \
            ghostscript \
            > /dev/null
        
        chmod +x /data/$BINARY
        
        echo '-> LDD Output:'
        ldd /data/$BINARY
        
        echo '-> Version Check:'
        /data/$BINARY --version
        
        echo '-> Functional Test (Logo Gen):'
        /data/$BINARY logo: /data/logo-$ARCH_NAME.png
        if [ -f /data/logo-$ARCH_NAME.png ]; then
            echo '✓ Success: Image generated.'
        else
            echo '✗ Failure: Image not generated.'
            exit 1
        fi
    "
}

# Verify amd64
verify_arch "linux/amd64" "amd64"

# Verify arm64
verify_arch "linux/arm64" "arm64"

echo "=== Verification Complete ==="
