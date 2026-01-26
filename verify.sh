#!/bin/bash
set -e

BIN_DIR="./local-bin"
echo "=== Verifying Static Binaries in Minimal Ubuntu 24.04 Environment ==="

# Create a minimal Dockerfile for verification
cat <<EOF > Dockerfile.verify
# Mimic the user's minimal environment
FROM ubuntu:24.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get --no-install-recommends \
  --no-install-suggests -y install \
  bzip2 \
  python3 \
  python-is-python3 \
  ca-certificates \
  libpq-dev \
  binutils \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
EOF

verify_arch() {
    PLATFORM=$1
    ARCH_NAME=$2
    BINARY="magick-linux-${ARCH_NAME}"

    if [ ! -f "$BIN_DIR/$BINARY" ]; then
        echo "Error: Binary $BINARY not found!"
        return 1
    fi

    echo "--- Verifying $ARCH_NAME on $PLATFORM ---"
    
    # Build minimal verification image
    docker build --platform "$PLATFORM" -t "im-verify-$ARCH_NAME" -f Dockerfile.verify .

    # Run verification
    docker run --rm --platform "$PLATFORM" -v "$(pwd)/$BIN_DIR:/data" "im-verify-$ARCH_NAME" bash -c "
        echo '-> LDD Output (Should have minimal dependencies):'
        ldd /data/$BINARY
        
        echo '-> Version Check:'
        /data/$BINARY --version
        
        echo '-> Functional Test (Logo Gen):'
        /data/$BINARY logo: /data/logo-static-$ARCH_NAME.png
        if [ -f /data/logo-static-$ARCH_NAME.png ]; then
            echo '✓ Success: Image generated in minimal env.'
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
rm Dockerfile.verify
