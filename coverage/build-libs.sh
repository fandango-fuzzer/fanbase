#!/bin/sh
# Builds the libraries the registry's formats are read by, from pinned sources, so that every line they run is
# counted (gcc --coverage, no optimisation), and one small program for each that reads a file with it.
# A source is pinned by the commit of its tag, or by the hash of its archive: what is built is what was read.
set -eu

SRC=/opt/cov/src BUILD=/opt/cov/build PREFIX=/opt/cov/prefix
CFLAGS_COV="--coverage -O0 -g"
mkdir -p "$SRC" "$BUILD" "$PREFIX"

pin_git() { # name url tag commit
    git clone --quiet --depth 1 --branch "$3" "$2" "$SRC/$1"
    [ "$(git -C "$SRC/$1" rev-parse HEAD)" = "$4" ] || { echo "$1 $3 is not the commit $4" >&2; exit 1; }
}

cmake_build() { # name [options...]
    name=$1; shift
    cmake -S "$SRC/$name" -B "$BUILD/$name" -G Ninja -DCMAKE_BUILD_TYPE=None \
        -DCMAKE_C_FLAGS="$CFLAGS_COV" -DCMAKE_EXE_LINKER_FLAGS=--coverage \
        -DCMAKE_INSTALL_PREFIX="$PREFIX/$name" -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=OFF "$@" > "$BUILD/$name.cmake.log" 2>&1 \
        || { tail -30 "$BUILD/$name.cmake.log" >&2; exit 1; }
    cmake --build "$BUILD/$name" > "$BUILD/$name.build.log" 2>&1 || { tail -30 "$BUILD/$name.build.log" >&2; exit 1; }
    cmake --install "$BUILD/$name" > /dev/null
}

# --- libpng 1.6.59
pin_git libpng https://github.com/pnggroup/libpng v1.6.59 cd952f49f95bb27154ae77dbb103032d95f6e580
cmake_build libpng -DPNG_SHARED=OFF -DPNG_STATIC=ON -DPNG_TESTS=OFF -DPNG_TOOLS=OFF -DPNG_HARDWARE_OPTIMIZATIONS=OFF

# --- libjpeg-turbo 3.2.0
pin_git libjpeg-turbo https://github.com/libjpeg-turbo/libjpeg-turbo 3.2.0 c85e6b905bf237038faa936dab160ebfc5da0344
cmake_build libjpeg-turbo -DENABLE_SHARED=0 -DENABLE_STATIC=1 -DWITH_SIMD=0 -DWITH_TURBOJPEG=0 -DWITH_JAVA=0

# --- giflib 5.2.2 (a tarball: its git has no release tags)
curl -fsSL "https://sourceforge.net/projects/giflib/files/giflib-5.2.2.tar.gz/download" -o /tmp/giflib.tar.gz
echo "be7ffbd057cadebe2aa144542fd90c6838c6a083b5e8a9048b8ee3b66b29d5fb  /tmp/giflib.tar.gz" | sha256sum -c -
mkdir -p "$SRC/giflib" && tar -xzf /tmp/giflib.tar.gz -C "$SRC/giflib" --strip-components=1 && rm /tmp/giflib.tar.gz
make -C "$SRC/giflib" CFLAGS="$CFLAGS_COV -fPIC -std=gnu99" libgif.a > "$BUILD/giflib.build.log" 2>&1 || { tail -30 "$BUILD/giflib.build.log" >&2; exit 1; }

# --- libtiff 4.7.2 (the codecs it calls into are the system's: only libtiff's own code is counted)
pin_git libtiff https://gitlab.com/libtiff/libtiff v4.7.2 d01a94be176f5f6a87f7ee1c0b32e65416aa2b4d
cmake_build libtiff -Dtiff-tools=OFF -Dtiff-tests=OFF -Dtiff-contrib=OFF -Dtiff-docs=OFF -Dtiff-opengl=OFF -Dtiff-cxx=OFF \
    -Dlibdeflate=OFF -Djbig=OFF -Dlerc=OFF -Dwebp=OFF -Dzstd=ON -Dlzma=ON -Djpeg=ON -Dzlib=ON

# --- libwebp 1.6.0
pin_git libwebp https://github.com/webmproject/libwebp v1.6.0 4fa21912338357f89e4fd51cf2368325b59e9bd9
cmake_build libwebp -DWEBP_ENABLE_SIMD=OFF -DWEBP_BUILD_ANIM_UTILS=OFF -DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_DWEBP=OFF \
    -DWEBP_BUILD_GIF2WEBP=OFF -DWEBP_BUILD_IMG2WEBP=OFF -DWEBP_BUILD_VWEBP=OFF -DWEBP_BUILD_WEBPINFO=OFF \
    -DWEBP_BUILD_WEBPMUX=OFF -DWEBP_BUILD_EXTRAS=OFF -DWEBP_BUILD_LIBWEBPMUX=OFF

# --- stb_image (one header, at a pinned commit; BMP only, so that what is counted is BMP's code)
mkdir -p "$SRC/stb" "$BUILD/stb-bmp"
curl -fsSL "https://raw.githubusercontent.com/nothings/stb/2c980bb59875b0d32144a71867fbdebb2f77cd20/stb_image.h" -o "$SRC/stb/stb_image.h"
echo "594c2fe35d49488b4382dbfaec8f98366defca819d916ac95becf3e75f4200b3  $SRC/stb/stb_image.h" | sha256sum -c -

echo "built:"; ls "$PREFIX"
