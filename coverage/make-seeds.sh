#!/bin/sh
# A few real files of each format, made by real tools (ImageMagick, from its built-in picture; libheif's and libjxl's own
# encoders for HEIC and JPEG XL) and not by a grammar: what the generated files are compared with. Different encodings, so
# that they reach different parts of a library. The SVG files are written by hand, in seed-sources/, since no tool makes a
# vector drawing from a picture.
set -eu
OUT=/opt/cov/seeds
mkdir -p "$OUT/png" "$OUT/jpeg" "$OUT/gif" "$OUT/tiff" "$OUT/webp" "$OUT/bmp" "$OUT/heic" "$OUT/jxl" "$OUT/ppm" "$OUT/xbm" "$OUT/xpm" "$OUT/svg"
cd /tmp
convert rose: -resize 70x46 base.png

convert base.png "$OUT/png/plain.png"
convert base.png -interlace PNG "$OUT/png/interlaced.png"
convert base.png -colors 16 -depth 4 "$OUT/png/palette.png"
convert base.png -colorspace Gray "$OUT/png/gray.png"
convert base.png -alpha set -channel A -evaluate set 60% +channel "$OUT/png/alpha.png"
convert base.png -depth 16 "$OUT/png/sixteen-bit.png"

convert base.png -quality 85 "$OUT/jpeg/baseline.jpg"
convert base.png -quality 60 -interlace Plane "$OUT/jpeg/progressive.jpg"
convert base.png -colorspace Gray "$OUT/jpeg/gray.jpg"
convert base.png -sampling-factor 4:4:4 -quality 95 "$OUT/jpeg/full-colour.jpg"
convert base.png -define jpeg:restart-interval=4 "$OUT/jpeg/restarts.jpg"

convert base.png "$OUT/gif/plain.gif"
convert base.png -interlace GIF "$OUT/gif/interlaced.gif"
convert base.png \( +clone -rotate 90 \) \( +clone -rotate 90 \) -delay 10 -loop 0 "$OUT/gif/animated.gif"
convert base.png -colors 4 "$OUT/gif/four-colours.gif"

convert base.png "$OUT/tiff/plain.tif"
convert base.png -compress LZW "$OUT/tiff/lzw.tif"
convert base.png -compress Zip "$OUT/tiff/zip.tif"
convert base.png -compress JPEG "$OUT/tiff/jpeg.tif"
convert base.png -depth 16 "$OUT/tiff/sixteen-bit.tif"
convert base.png -define tiff:tile-geometry=32x32 "$OUT/tiff/tiled.tif"
convert base.png -colorspace Gray "$OUT/tiff/gray.tif"
convert base.png -colors 16 "$OUT/tiff/palette.tif"

convert base.png -quality 80 "$OUT/webp/lossy.webp"
convert base.png -define webp:lossless=true "$OUT/webp/lossless.webp"
convert base.png -alpha set -channel A -evaluate set 60% +channel -define webp:lossless=true "$OUT/webp/alpha.webp"
convert base.png \( +clone -rotate 90 \) \( +clone -rotate 90 \) -delay 10 -loop 0 "$OUT/webp/animated.webp"

convert base.png "$OUT/bmp/plain.bmp"
convert base.png BMP3:"$OUT/bmp/windows3.bmp"
convert base.png -colors 256 "$OUT/bmp/palette-8.bmp"
convert base.png -colors 16 "$OUT/bmp/palette-4.bmp"
convert base.png -colors 2 "$OUT/bmp/mono.bmp"
convert base.png -alpha set "$OUT/bmp/alpha.bmp"

convert base.png "$OUT/ppm/plain.ppm"
convert base.png -compress none "$OUT/ppm/ascii.ppm"
convert base.png -depth 16 "$OUT/ppm/sixteen-bit.ppm"
convert base.png -depth 16 -compress none "$OUT/ppm/sixteen-bit-ascii.ppm"
printf 'P6\n# a comment\n3 2\n255\n\000\001\002\003\004\005\006\007\010\011\012\013\014\015\016\017\020\021' > "$OUT/ppm/comment.ppm"

convert base.png "$OUT/xbm/plain.xbm"
convert base.png -resize 33x17! "$OUT/xbm/odd-size.xbm"
convert base.png -resize 8x8! "$OUT/xbm/tiny.xbm"

convert base.png "$OUT/xpm/plain.xpm"
convert base.png -colors 4 "$OUT/xpm/four-colours.xpm"
convert base.png -colors 256 "$OUT/xpm/many-colours.xpm"
convert base.png -colorspace Gray "$OUT/xpm/gray.xpm"
convert base.png -alpha set -channel A -evaluate set 60% +channel "$OUT/xpm/alpha.xpm"

# JPEG XL, with cjxl
convert base.png base.jpg
convert base.png -alpha set -channel A -evaluate set 60% +channel alpha.png
convert base.png -colorspace Gray gray.png
convert base.png -depth 16 sixteen.png
cjxl base.png "$OUT/jxl/lossy.jxl" -d 1 > /dev/null 2>&1
cjxl base.png "$OUT/jxl/lossless.jxl" -d 0 > /dev/null 2>&1
cjxl base.png "$OUT/jxl/progressive.jxl" -d 1 --progressive > /dev/null 2>&1
cjxl base.png "$OUT/jxl/progressive-dc.jxl" -d 1 --progressive_dc=1 > /dev/null 2>&1
cjxl base.png "$OUT/jxl/modular.jxl" -d 1 -m 1 > /dev/null 2>&1
cjxl base.png "$OUT/jxl/fast.jxl" -d 2 -e 3 > /dev/null 2>&1
cjxl base.png "$OUT/jxl/slow.jxl" -d 1 -e 9 > /dev/null 2>&1
cjxl base.png "$OUT/jxl/container.jxl" -d 1 --container=1 > /dev/null 2>&1
cjxl base.png "$OUT/jxl/noise.jxl" -d 2 --photon_noise_iso=3200 > /dev/null 2>&1
cjxl base.png "$OUT/jxl/resampled.jxl" -d 2 --resampling=2 > /dev/null 2>&1
cjxl alpha.png "$OUT/jxl/alpha.jxl" -d 1 > /dev/null 2>&1
cjxl gray.png "$OUT/jxl/gray.jxl" -d 1 > /dev/null 2>&1
cjxl sixteen.png "$OUT/jxl/sixteen-bit.jxl" -d 1 > /dev/null 2>&1
cjxl base.jpg "$OUT/jxl/transcoded.jxl" > /dev/null 2>&1   # a JPEG, repacked without loss

# HEIC and HEIF, with the libheif that is measured (HEVC by kvazaar)
HEIF_ENC=/opt/cov/prefix/libheif/bin/heif-enc
convert base.png -colorspace Gray gray.jpg
"$HEIF_ENC" base.jpg -o "$OUT/heic/plain.heic" > /dev/null
"$HEIF_ENC" base.jpg -q 20 -o "$OUT/heic/low-quality.heic" > /dev/null
"$HEIF_ENC" base.jpg -q 95 -o "$OUT/heic/high-quality.heic" > /dev/null
"$HEIF_ENC" base.jpg --thumb 24 -o "$OUT/heic/thumbnail.heic" > /dev/null
"$HEIF_ENC" gray.jpg -o "$OUT/heic/gray.heic" > /dev/null
"$HEIF_ENC" alpha.png -o "$OUT/heic/alpha.heic" > /dev/null
"$HEIF_ENC" base.jpg --uncompressed -o "$OUT/heic/uncompressed.heif" > /dev/null
"$HEIF_ENC" base.jpg --jpeg -o "$OUT/heic/jpeg.heif" > /dev/null

cp /opt/cov/seed-sources/svg/*.svg "$OUT/svg/"
rm -f base.png base.jpg gray.jpg gray.png alpha.png sixteen.png
find "$OUT" -type f | sort | sed 's#^#seed: #'
