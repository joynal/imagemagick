# Dockerfile for building ImageMagick on Ubuntu 24.04
FROM ubuntu:24.04

# Update and install build dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    git \
    curl \
    autoconf \
    automake \
    libtool \
    # Image Format Libraries
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libwebp-dev \
    libgif-dev \
    libopenjp2-7-dev \
    librsvg2-dev \
    libfreetype6-dev \
    libfontconfig1-dev \
    libx11-dev \
    libxext-dev \
    libxml2-dev \
    liblzma-dev \
    liblcms2-dev \
    zlib1g-dev \
    libzip-dev \
    # Helper to clean up
    && rm -rf /var/lib/apt/lists/*

# Clone ImageMagick
WORKDIR /usr/src
# Using master or a specific stable tag. 
# We'll fetch the latest tags to find the latest stable version if needed, 
# or just clone the repo which defaults to main (usually dev), 
# but let's clone the latest generic release tag to be safe, or just use main with care.
# The user asked for "latest version", so cloning the repo is standard.
RUN git clone https://github.com/ImageMagick/ImageMagick.git

WORKDIR /usr/src/ImageMagick

# Configure for static build
# We want to disable shared libraries to keep the binary standalone (except for system libs like glibc)
# We enable delegate libraries.
RUN ./configure \
    --enable-static \
    --disable-shared \
    --with-modules=no \
    --with-jpeg=yes \
    --with-png=yes \
    --with-tiff=yes \
    --with-webp=yes \
    --with-freetype=yes \
    --enable-hdri=yes \
    --with-quantum-depth=16

# Build
RUN make -j$(nproc)

# Install to a local dir just to verify, but we will mostly just grab the binary from 'utilities'
RUN make install

# Verify inside the build image
RUN /usr/local/bin/magick --version

# Entrypoint to keep it alive or just exit, we will cp the file out.
CMD ["/bin/bash"]
