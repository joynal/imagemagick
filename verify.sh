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
    BAZEL_ARCH=$3 
    
    # Find the tarball for this arch using wildcard as version changes
    TARBALL=$(find "$BIN_DIR" -name "imagemagick-*-${BAZEL_ARCH}-static.tar.gz" | head -n 1)

    if [ -z "$TARBALL" ]; then
        echo "Error: Tarball for $ARCH_NAME not found in $BIN_DIR!"
        return 1
    fi
    
    TAR_FILENAME=$(basename "$TARBALL")
    echo "--- Verifying $TAR_FILENAME on $PLATFORM ---"
    
    # Build minimal verification image
    docker build --platform "$PLATFORM" -t "im-verify-$ARCH_NAME" -f Dockerfile.verify .

    # Run verification
    # 1. Mount the tarball directory
    # 2. Extract it inside the container
    # 3. run the extracted binary
    docker run --rm --platform "$PLATFORM" -v "$(pwd)/$BIN_DIR:/data" "im-verify-$ARCH_NAME" bash -c "
        cd /data
        # Create a temp dir to extract
        mkdir -p /tmp/verify
        tar -xzf /data/$TAR_FILENAME -C /tmp/verify
        
        BINARY=/tmp/verify/bin/magick
        
        if [ ! -f \"\$BINARY\" ]; then
            echo '✗ Failure: Binary not found after extraction.'
            exit 1
        fi
        
        echo '-> LDD Output (Should have minimal dependencies):'
        ldd \$BINARY
        
        echo '-> Version Check:'
        \$BINARY --version
        
        echo '-> Functional Test (Logo Gen):'
        \$BINARY logo: /data/logo-static-$ARCH_NAME.png
        if [ -f /data/logo-static-$ARCH_NAME.png ]; then
            echo '✓ Success: Image generated in minimal env.'
        else
            echo '✗ Failure: Image not generated.'
            exit 1
        fi
    "
}

# Verify amd64
verify_arch "linux/amd64" "amd64" "x86_64"

# Verify arm64
verify_arch "linux/arm64" "arm64" "aarch64"

echo "=== Verification Complete ==="
rm Dockerfile.verify
