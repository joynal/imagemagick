#!/bin/bash
set -e

# Directory to store binaries
OUTPUT_DIR="./local-bin"
mkdir -p "$OUTPUT_DIR"

echo "=== Building ImageMagick for Linux amd64 and arm64 ==="

# Function to build for a specific platform
build_platform() {
    PLATFORM=$1
    ARCH_NAME=$2
    TAG="im-build-${ARCH_NAME}"
    CONTAINER="extract-${ARCH_NAME}"

    echo "--- Building for $PLATFORM ($ARCH_NAME) ---"
    
    # 1. Build the image
    docker build --platform "$PLATFORM" -t "$TAG" .

    # 2. Create a container instance
    docker rm -f "$CONTAINER" 2>/dev/null || true
    docker create --name "$CONTAINER" --platform "$PLATFORM" "$TAG"

    # 3. Copy the binary out
    # The installed binary is usually in /usr/local/bin/magick
    echo "Extracting binary..."
    docker cp "$CONTAINER":/usr/local/bin/magick "$OUTPUT_DIR/magick-linux-${ARCH_NAME}"

    # 4. Cleanup
    docker rm -f "$CONTAINER"
    
    echo "✓ Built $OUTPUT_DIR/magick-linux-${ARCH_NAME}"
}

# Build for amd64
build_platform "linux/amd64" "amd64"

# Build for arm64
build_platform "linux/arm64" "arm64"

echo "=== Build Complete ==="
ls -lh "$OUTPUT_DIR"
