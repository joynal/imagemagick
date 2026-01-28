#!/bin/bash
set -e

# Configuration
BUILD_DIR="$(pwd)/build-work-macos"
INSTALL_DIR="$BUILD_DIR/install"
SRC_DIR="$BUILD_DIR/src"
OUTPUT_DIR="./local-bin"
NUM_CORES=$(sysctl -n hw.ncpu)

# Versions (Matching Dockerfile)
ZLIB_VERSION="1.3.1"
LIBJPEG_VERSION="3.0.1"
LIBPNG_VERSION="1.6.40"
LIBTIFF_VERSION="4.6.0"
LIBWEBP_VERSION="1.3.2"
FREETYPE_VERSION="2.13.2"

# Paths
export PATH="$INSTALL_DIR/bin:$PATH"
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig"
export CPPFLAGS="-I$INSTALL_DIR/include"
export LDFLAGS="-L$INSTALL_DIR/lib"
export CFLAGS="-I$INSTALL_DIR/include"

mkdir -p "$SRC_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$OUTPUT_DIR"

echo "=== Building ImageMagick for macOS (Static) ==="
echo "Work Dir: $BUILD_DIR"
echo "Install Dir: $INSTALL_DIR"

check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Tool '$1' is missing. Attempting to install via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install "$1"
        else
            echo "Error: Homebrew not found. Please install '$1' manually."
            exit 1
        fi
    fi
}

# Check for required tools
# Note: libtool on macOS is provided by the system, but GNU libtool is needed for some builds.
# Homebrew 'libtool' installs as 'glibtool'. We primarily need cmake, nasm, autoconf, automake, pkg-config.
for tool in cmake nasm autoconf automake pkg-config; do
    check_command $tool
done

download() {
    URL=$1
    FILE=$2
    if [ ! -f "$SRC_DIR/$FILE" ]; then
        echo "Downloading $FILE..."
        curl -L -o "$SRC_DIR/$FILE" "$URL"
    else
        echo "Using cached $FILE"
    fi
}

echo "--- 1. ZLIB ---"
download "https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz" "zlib-${ZLIB_VERSION}.tar.gz"
if [ ! -f "$INSTALL_DIR/lib/libz.a" ]; then
    cd "$SRC_DIR"
    tar xzf "zlib-${ZLIB_VERSION}.tar.gz"
    cd "zlib-${ZLIB_VERSION}"
    ./configure --prefix="$INSTALL_DIR" --static
    make -j$NUM_CORES
    make install
    echo "Zlib build complete."
else
    echo "Zlib already installed."
fi

echo "--- 2. LIBJPEG-TURBO ---"
download "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/${LIBJPEG_VERSION}.tar.gz" "libjpeg-turbo-${LIBJPEG_VERSION}.tar.gz"
if [ ! -f "$INSTALL_DIR/lib/libjpeg.a" ]; then
    cd "$SRC_DIR"
    tar xzf "libjpeg-turbo-${LIBJPEG_VERSION}.tar.gz"
    cd "libjpeg-turbo-${LIBJPEG_VERSION}"
    cmake -G"Unix Makefiles" \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
        -DENABLE_SHARED=OFF \
        -DENABLE_STATIC=ON \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        .
    make -j$NUM_CORES
    make install
    echo "Libjpeg-turbo build complete."
else
    echo "Libjpeg-turbo already installed."
fi

echo "--- 3. LIBPNG ---"
download "https://download.sourceforge.net/libpng/libpng-${LIBPNG_VERSION}.tar.gz" "libpng-${LIBPNG_VERSION}.tar.gz"
if [ ! -f "$INSTALL_DIR/lib/libpng.a" ]; then
    cd "$SRC_DIR"
    # Ensure clean build dir
    rm -rf "libpng-${LIBPNG_VERSION}"
    tar xzf "libpng-${LIBPNG_VERSION}.tar.gz"
    cd "libpng-${LIBPNG_VERSION}"
    
    # Patch for macOS: fp.h is deprecated/missing, replace with math.h
    # This fixes the "fatal error: 'fp.h' file not found"
    echo "Patching pngpriv.h for macOS..."
    sed -i '' 's|<fp.h>|<math.h>|g' pngpriv.h

    ./configure --prefix="$INSTALL_DIR" --disable-shared --enable-static
    make -j$NUM_CORES
    make install
    echo "Libpng build complete."
else
    echo "Libpng already installed."
fi

echo "--- 4. LIBTIFF ---"
download "https://download.osgeo.org/libtiff/tiff-${LIBTIFF_VERSION}.tar.gz" "tiff-${LIBTIFF_VERSION}.tar.gz"
if [ ! -f "$INSTALL_DIR/lib/libtiff.a" ]; then
    cd "$SRC_DIR"
    tar xzf "tiff-${LIBTIFF_VERSION}.tar.gz"
    cd "tiff-${LIBTIFF_VERSION}"
    ./configure --prefix="$INSTALL_DIR" \
        --disable-shared --enable-static \
        --disable-zstd --disable-lzma --disable-webp --without-x \
        --disable-cxx
    make -j$NUM_CORES
    make install
    echo "Libtiff build complete."
else
    echo "Libtiff already installed."
fi

echo "--- 5. LIBWEBP ---"
download "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${LIBWEBP_VERSION}.tar.gz" "libwebp-${LIBWEBP_VERSION}.tar.gz"
if [ ! -f "$INSTALL_DIR/lib/libwebp.a" ]; then
    cd "$SRC_DIR"
    tar xzf "libwebp-${LIBWEBP_VERSION}.tar.gz"
    cd "libwebp-${LIBWEBP_VERSION}"
    ./configure --prefix="$INSTALL_DIR" \
        --disable-shared --enable-static \
        --disable-gl --disable-sdl --disable-png --disable-jpeg --disable-tiff --disable-gif
    make -j$NUM_CORES
    make install
    echo "Libwebp build complete."
else
    echo "Libwebp already installed."
fi

echo "--- 6. FREETYPE ---"
download "https://download.savannah.gnu.org/releases/freetype/freetype-${FREETYPE_VERSION}.tar.gz" "freetype-${FREETYPE_VERSION}.tar.gz"
if [ ! -f "$INSTALL_DIR/lib/libfreetype.a" ]; then
    cd "$SRC_DIR"
    tar xzf "freetype-${FREETYPE_VERSION}.tar.gz"
    cd "freetype-${FREETYPE_VERSION}"
    ./configure --prefix="$INSTALL_DIR" \
        --disable-shared --enable-static \
        --without-harfbuzz --without-brotli --without-png --without-zlib
    make -j$NUM_CORES
    make install
    echo "Freetype build complete."
else
    echo "Freetype already installed."
fi

echo "--- 7. ImageMagick ---"
cd "$SRC_DIR"
if [ ! -d "ImageMagick" ]; then
    git clone https://github.com/ImageMagick/ImageMagick.git
else
    echo "Updating ImageMagick..."
    cd ImageMagick
    git pull
    cd ..
fi

cd ImageMagick
# Configure to link against our static libs
./configure \
    --prefix="$INSTALL_DIR" \
    --enable-static \
    --disable-shared \
    --with-modules=no \
    --with-jpeg=yes \
    --with-png=yes \
    --with-tiff=yes \
    --with-webp=yes \
    --with-freetype=yes \
    --enable-hdri=yes \
    --disable-openmp \
    --with-quantum-depth=16 \
    --without-x \
    --without-magick-plus-plus \
    --without-perl \
    --without-zstd \
    --without-lzma

make -j$NUM_CORES
make install

echo "--- Packaging ---"
# Get version
IM_VERSION=$("$INSTALL_DIR/bin/magick" --version | head -n 1 | awk '{print $3}')
ARCH_NAME=$(uname -m)
if [ "$ARCH_NAME" == "arm64" ]; then
    # standardizing on typical macos naming if needed, but 'arm64' is fine
    ARCH_NAME="arm64"
else
    ARCH_NAME="x86_64"
fi

TAR_NAME="imagemagick-${IM_VERSION}-macos-${ARCH_NAME}-static.tar.gz"

echo "Creating $TAR_NAME..."

# Create a staging directory to organize the files cleanly
STAGE_DIR="$BUILD_DIR/stage"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR/bin"

# Copy the binary
cp "$INSTALL_DIR/bin/magick" "$STAGE_DIR/bin/"

# Create symlinks
cd "$STAGE_DIR/bin"
for tool in compare composite conjure convert identify mogrify montage stream magick-script; do
    ln -sf magick "$tool"
done
cd - > /dev/null

# Package it
# Current dir is build-work-macos/src/ImageMagick usually. Go back up.
cd "$BUILD_DIR" 
# We want to tar the 'bin' directory inside stage
tar -czf "$TAR_NAME" -C "$STAGE_DIR" bin

# Move to local-bin
mv "$TAR_NAME" "../local-bin/"

echo "✓ Created local-bin/$TAR_NAME"
ls -l "../local-bin/$TAR_NAME"
