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

# --- libheif 1.23.6 (HEVC is decoded by the system's libde265, and the real files are made with kvazaar: codecs the
# library calls into are not counted; the tools are built to make those files)
pin_git libheif https://github.com/strukturag/libheif v1.23.6 f81f28ac014b1c28dee483ac45b72c6b05bc421a
cmake_build libheif -DCMAKE_CXX_FLAGS="$CFLAGS_COV" -DENABLE_PLUGIN_LOADING=OFF -DBUILD_TESTING=OFF -DWITH_EXAMPLES=ON -DWITH_FUZZERS=OFF \
    -DWITH_GDK_PIXBUF=OFF -DWITH_LIBDE265=ON -DWITH_LIBDE265_PLUGIN=OFF -DWITH_KVAZAAR=ON -DWITH_KVAZAAR_PLUGIN=OFF -DWITH_X265=OFF \
    -DWITH_AOM_DECODER=OFF -DWITH_AOM_ENCODER=OFF -DWITH_DAV1D=OFF -DWITH_RAV1E=OFF -DWITH_SvtEnc=OFF \
    -DWITH_OpenJPEG_DECODER=OFF -DWITH_OpenJPEG_ENCODER=OFF -DWITH_JPEG_DECODER=ON -DWITH_JPEG_ENCODER=ON -DWITH_UNCOMPRESSED_CODEC=ON

# --- libjxl 0.12.0 (with the highway, brotli and skcms that its own commit pins, and one instruction set: no SIMD)
pin_git libjxl https://github.com/libjxl/libjxl v0.12.0 a7a9c787341cf703dede03c2009fa460cae5e5df
git -C "$SRC/libjxl" submodule update --init --quiet --depth 1 third_party/skcms third_party/highway third_party/brotli
cmake_build libjxl -DCMAKE_CXX_FLAGS="$CFLAGS_COV -DHWY_COMPILE_ONLY_EMU128" -DBUILD_TESTING=OFF \
    -DJPEGXL_ENABLE_TOOLS=OFF -DJPEGXL_ENABLE_DOXYGEN=OFF -DJPEGXL_ENABLE_MANPAGES=OFF -DJPEGXL_ENABLE_BENCHMARK=OFF \
    -DJPEGXL_ENABLE_EXAMPLES=OFF -DJPEGXL_ENABLE_JNI=OFF -DJPEGXL_ENABLE_SJPEG=OFF -DJPEGXL_ENABLE_OPENEXR=OFF \
    -DJPEGXL_ENABLE_PLUGINS=OFF -DJPEGXL_ENABLE_VIEWERS=OFF -DJPEGXL_ENABLE_JPEGLI=OFF -DJPEGXL_ENABLE_JPEGLI_LIBJPEG=OFF \
    -DJPEGXL_ENABLE_AVX512=OFF -DJPEGXL_ENABLE_AVX512_ZEN4=OFF -DJPEGXL_ENABLE_AVX512_SPR=OFF \
    -DJPEGXL_ENABLE_SKCMS=ON -DJPEGXL_BUNDLE_SKCMS=ON

# --- FFmpeg n9.0.2, with the decoders of PPM, XBM and XPM and nothing else (its tag is an annotated one: this is its commit)
pin_git ffmpeg https://github.com/FFmpeg/FFmpeg n9.0.2 946fcce07b6dcd0331c8cc609192aeff5e1924f8
mkdir -p "$BUILD/ffmpeg"
(cd "$BUILD/ffmpeg" && "$SRC/ffmpeg/configure" --prefix="$PREFIX/ffmpeg" --cc=gcc \
    --disable-everything --disable-autodetect --disable-programs --disable-doc --disable-network \
    --disable-avdevice --disable-avfilter --disable-swscale --disable-swresample \
    --disable-asm --disable-stripping --disable-debug --optflags=-O0 --extra-cflags="$CFLAGS_COV" --extra-ldflags=--coverage \
    --disable-shared --enable-static --enable-pic --enable-protocol=file \
    --enable-demuxer=image2,image_ppm_pipe,image_pbm_pipe,image_pgm_pipe,image_pam_pipe,image_xbm_pipe,image_xpm_pipe \
    --enable-parser=pnm --enable-decoder=ppm,pbm,pgm,pam,pgmyuv,xbm,xpm > "$BUILD/ffmpeg.configure.log" 2>&1) \
    || { tail -30 "$BUILD/ffmpeg.configure.log" >&2; exit 1; }
make -C "$BUILD/ffmpeg" -j"$(nproc)" > "$BUILD/ffmpeg.build.log" 2>&1 || { tail -30 "$BUILD/ffmpeg.build.log" >&2; exit 1; }
make -C "$BUILD/ffmpeg" install > /dev/null

# --- the same FFmpeg again, with the demuxers and decoders of WAV, FLAC, Ogg (Vorbis, Opus, FLAC), MP3 (layers I to III)
# and AAC (ADTS), in a build of its own, so that the one above stays as it is
mkdir -p "$BUILD/ffmpeg-audio"
(cd "$BUILD/ffmpeg-audio" && "$SRC/ffmpeg/configure" --prefix="$PREFIX/ffmpeg-audio" --cc=gcc \
    --disable-everything --disable-autodetect --disable-programs --disable-doc --disable-network \
    --disable-avdevice --disable-avfilter --disable-swscale \
    --disable-asm --disable-stripping --disable-debug --optflags=-O0 --extra-cflags="$CFLAGS_COV" --extra-ldflags=--coverage \
    --disable-shared --enable-static --enable-pic --enable-protocol=file \
    --enable-demuxer=wav,flac,ogg,mp3,aac --enable-parser=flac,vorbis,opus,mpegaudio,aac \
    --enable-decoder=pcm_u8,pcm_s16le,pcm_s24le,pcm_s32le,pcm_f32le,pcm_f64le,pcm_alaw,pcm_mulaw,flac,vorbis,opus,mp1float,mp2float,mp3float,aac \
    > "$BUILD/ffmpeg-audio.configure.log" 2>&1) || { tail -30 "$BUILD/ffmpeg-audio.configure.log" >&2; exit 1; }
make -C "$BUILD/ffmpeg-audio" -j"$(nproc)" > "$BUILD/ffmpeg-audio.build.log" 2>&1 || { tail -30 "$BUILD/ffmpeg-audio.build.log" >&2; exit 1; }
make -C "$BUILD/ffmpeg-audio" install > /dev/null

# --- NanoSVG (one header, at a pinned commit; the program is the library, as with stb_image)
mkdir -p "$SRC/nanosvg" "$BUILD/nanosvg"
curl -fsSL "https://raw.githubusercontent.com/memononen/nanosvg/239e102ec2c691f2902e20ace2ed36ee4a35cfe6/src/nanosvg.h" -o "$SRC/nanosvg/nanosvg.h"
echo "e34fd5d084be106cea972d19ce5d27fd96d17ba89f8d06bdceee058420c8b2b0  $SRC/nanosvg/nanosvg.h" | sha256sum -c -

# --- libarchive 3.8.10, for the archive formats (its tag is an annotated one: this is its commit); the decompressors it
# calls into (zlib, bzip2, liblzma, zstd) are the system's, and only its readers are counted
pin_git libarchive https://github.com/libarchive/libarchive v3.8.10 0c48412be2d94afe1859a807ea7896a18d8900bd
cmake_build libarchive -DENABLE_TEST=OFF -DENABLE_TAR=OFF -DENABLE_CPIO=OFF -DENABLE_CAT=OFF -DENABLE_UNZIP=OFF \
    -DENABLE_OPENSSL=OFF -DENABLE_MBEDTLS=OFF -DENABLE_NETTLE=OFF -DENABLE_CNG=OFF -DENABLE_LIBB2=OFF -DENABLE_LIBXML2=OFF \
    -DENABLE_EXPAT=OFF -DENABLE_PCREPOSIX=OFF -DENABLE_PCRE2POSIX=OFF -DENABLE_ACL=OFF -DENABLE_XATTR=OFF -DENABLE_ICONV=OFF \
    -DENABLE_LZ4=OFF -DENABLE_LZO=OFF -DENABLE_ZLIB=ON -DENABLE_BZip2=ON -DENABLE_LZMA=ON -DENABLE_ZSTD=ON

# --- 7-Zip 26.05, for ARJ, which libarchive does not read: its console program with every format (7zz), of which only the
# ARJ reader is counted. Its own makefile, with counting and without optimisation (the last -O wins)
pin_git 7zip https://github.com/ip7z/7zip 26.05 b88c6bc09339de32f7d18bbab900686b244f42ba
mkdir -p "$BUILD/7zip" "$PREFIX/7zip/bin"
make -C "$SRC/7zip/CPP/7zip/Bundles/Alone2" -f ../../cmpl_gcc.mak -j"$(nproc)" O="$BUILD/7zip" \
    CFLAGS_BASE_LIST="-c $CFLAGS_COV" LDFLAGS_STATIC_3=--coverage CFLAGS_WARN_WALL= LFLAGS_STRIP= > "$BUILD/7zip.build.log" 2>&1 \
    || { tail -30 "$BUILD/7zip.build.log" >&2; exit 1; }
cp "$BUILD/7zip/7zz" "$PREFIX/7zip/bin/7zz"

echo "built:"; ls "$PREFIX"
