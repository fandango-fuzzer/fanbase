#!/bin/sh
# One small program for each library, that reads a file with it and says whether the library took it: exit 0 if it
# did, 1 if the library said no. They are compiled without counting, and linked with the libraries that count.
set -eu

SRC=/opt/cov/src BUILD=/opt/cov/build PREFIX=/opt/cov/prefix BIN=/opt/cov/bin HARNESS=/opt/cov/harness
mkdir -p "$BIN"

harness() { # name source include-flags libs...
    name=$1; source=$2; includes=$3; shift 3
    mkdir -p "$BUILD/$name-harness"
    gcc -O0 -g -c "$HARNESS/$source" -o "$BUILD/$name-harness/$name.o" $includes
    gcc "$BUILD/$name-harness/$name.o" -o "$BIN/$name-harness" "$@" -lgcov
}

harness png png.c "-I$PREFIX/libpng/include" "$PREFIX/libpng/lib/libpng16.a" -lz -lm
harness jpeg jpeg.c "-I$PREFIX/libjpeg-turbo/include" "$PREFIX/libjpeg-turbo/lib/libjpeg.a" -lm
harness gif gif.c "-I$SRC/giflib" "$SRC/giflib/libgif.a"
harness tiff tiff.c "-I$PREFIX/libtiff/include" "$PREFIX/libtiff/lib/libtiff.a" -ljpeg -lz -llzma -lzstd -lm
harness webp webp.c "-I$PREFIX/libwebp/include" "$PREFIX/libwebp/lib/libwebpdemux.a" "$PREFIX/libwebp/lib/libwebp.a" \
    "$PREFIX/libwebp/lib/libsharpyuv.a" -lm -lpthread

# stb_image is one header: the program is the library, so it is the one that counts
mkdir -p "$BUILD/stb-bmp"
gcc --coverage -O0 -g -I"$SRC/stb" -c "$HARNESS/bmp.c" -o "$BUILD/stb-bmp/bmp.o"
gcc "$BUILD/stb-bmp/bmp.o" -o "$BIN/bmp-harness" -lm --coverage

echo "built:"; ls "$BIN"
