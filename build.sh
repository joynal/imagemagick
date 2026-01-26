#!/bin/bash
set -e

# Directory to store binaries
OUTPUT_DIR="./local-bin"
mkdir -p "$OUTPUT_DIR"

echo "=== Building ImageMagick for Linux amd64 and arm64 ==="

# Function to build and package for a specific platform
build_and_package() {
    PLATFORM=$1
    ARCH_NAME=$2
    BAZEL_ARCH=$3 # x86_64 or aarch64
    
    TAG="im-build-${ARCH_NAME}"
    CONTAINER="extract-${ARCH_NAME}"

    echo "--- Building for $PLATFORM ($ARCH_NAME) ---"
    
    # 1. Build the image
    docker build --platform "$PLATFORM" -t "$TAG" .

    # 2. Create a container instance
    docker rm -f "$CONTAINER" 2>/dev/null || true
    docker create --name "$CONTAINER" --platform "$PLATFORM" "$TAG"

    # 3. Extract and Package
    echo "Extracting binary..."
    
    # Staging area for tarball
    STAGE_DIR="$OUTPUT_DIR/stage_${ARCH_NAME}"
    rm -rf "$STAGE_DIR"
    mkdir -p "$STAGE_DIR/bin"
    
    # Copy binary to stage/bin/magick
    docker cp "$CONTAINER":/usr/local/bin/magick "$STAGE_DIR/bin/magick"
    
    # Create symlinks for legacy tools
    echo "Creating symlinks..."
    cd "$STAGE_DIR/bin"
    for tool in compare composite conjure convert identify mogrify montage stream magick-script; do
        ln -sf magick "$tool"
    done
    cd - > /dev/null
    
    # Get version for filename
    IM_VERSION=$(docker run --rm --platform "$PLATFORM" "$TAG" magick --version | head -n 1 | awk '{print $3}')
    TAR_NAME="imagemagick-${IM_VERSION}-${BAZEL_ARCH}-static.tar.gz"
    
    echo "Packaging $TAR_NAME..."
    # Create tarball preserving 'bin' directory structure, compatible with strip_prefix="bin"
    # usage: tar -czf <file> -C <dir> .
    # Use -C to change to STAGE_DIR so 'bin' is at the root of the archive
    tar -czf "$OUTPUT_DIR/$TAR_NAME" -C "$STAGE_DIR" bin
    
    # Calculate SHA256
    if command -v sha256sum >/dev/null 2>&1; then
        SHA=$(sha256sum "$OUTPUT_DIR/$TAR_NAME" | awk '{print $1}')
    else
        SHA=$(shasum -a 256 "$OUTPUT_DIR/$TAR_NAME" | awk '{print $1}')
    fi
    
    echo "✓ Created $OUTPUT_DIR/$TAR_NAME"
    echo "  SHA256: $SHA"
    
    # Save info for user convenience
    echo "$TAR_NAME" >> "$OUTPUT_DIR/artifacts.txt"
    echo "SHA256: $SHA" >> "$OUTPUT_DIR/artifacts.txt"
    echo "" >> "$OUTPUT_DIR/artifacts.txt"

    # 4. Cleanup
    docker rm -f "$CONTAINER"
    rm -rf "$STAGE_DIR"
}

# Clear artifact log
rm -f "$OUTPUT_DIR/artifacts.txt"

# Build for amd64
build_and_package "linux/amd64" "amd64" "x86_64"

# Build for arm64
build_and_package "linux/arm64" "arm64" "aarch64"

echo "=== Build & Package Complete ==="
cat "$OUTPUT_DIR/artifacts.txt"

