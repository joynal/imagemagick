# Dockerfile for building ImageMagick on Ubuntu 24.04 with STATIC delegates
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

# Install build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    git \
    curl \
    autoconf \
    automake \
    libtool \
    nasm \  
    cmake \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

# --- 1. ZLIB ---
RUN curl -fsSL https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz | tar xz && \
    cd zlib-1.3.1 && \
    ./configure --prefix=/usr/local --static && \
    make -j$(nproc) && \
    make install

# --- 2. LIBJPEG-TURBO ---
RUN curl -L -O https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/3.0.1.tar.gz && \
    tar xzf 3.0.1.tar.gz && \
    cd libjpeg-turbo-3.0.1 && \
    cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr/local -DENABLE_SHARED=OFF -DENABLE_STATIC=ON . && \
    make -j$(nproc) && \
    make install

# --- 3. LIBPNG ---
RUN curl -L -O https://download.sourceforge.net/libpng/libpng-1.6.40.tar.gz && \
    tar xzf libpng-1.6.40.tar.gz && \
    cd libpng-1.6.40 && \
    ./configure --prefix=/usr/local --disable-shared --enable-static && \
    make -j$(nproc) && \
    make install

# --- 4. LIBTIFF ---
RUN curl -L -O https://download.osgeo.org/libtiff/tiff-4.6.0.tar.gz && \
    tar xzf tiff-4.6.0.tar.gz && \
    cd tiff-4.6.0 && \
    ./configure --prefix=/usr/local --disable-shared --enable-static --disable-zstd --disable-lzma --disable-webp --without-x && \
    make -j$(nproc) && \
    make install

# --- 5. LIBWEBP ---
RUN curl -L -O https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.3.2.tar.gz && \
    tar xzf libwebp-1.3.2.tar.gz && \
    cd libwebp-1.3.2 && \
    ./configure --prefix=/usr/local --disable-shared --enable-static --disable-gl --disable-sdl --disable-png --disable-jpeg --disable-tiff --disable-gif && \
    make -j$(nproc) && \
    make install

# --- 6. FREETYPE ---
RUN curl -L -O https://download.savannah.gnu.org/releases/freetype/freetype-2.13.2.tar.gz && \
    tar xzf freetype-2.13.2.tar.gz && \
    cd freetype-2.13.2 && \
    ./configure --prefix=/usr/local --disable-shared --enable-static --without-harfbuzz --without-brotli --without-png --without-zlib && \
    make -j$(nproc) && \
    make install

# --- 7. ImageMagick ---
RUN git clone https://github.com/ImageMagick/ImageMagick.git ImageMagick
WORKDIR /usr/src/ImageMagick

# Configure to link against our static libs
RUN ./configure \
    --prefix=/usr/local \
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
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

RUN make -j$(nproc)
RUN make install

# Quick verify in builder
RUN /usr/local/bin/magick --version
RUN ldd /usr/local/bin/magick || true

CMD ["/bin/bash"]
