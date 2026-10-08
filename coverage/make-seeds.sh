#!/bin/sh
# A few real files of each format, made by real tools (ImageMagick, from its built-in picture) and not by a grammar:
# what the generated files are compared with. Different encodings, so that they reach different parts of a library.
set -eu
OUT=/opt/cov/seeds
mkdir -p "$OUT/png" "$OUT/jpeg" "$OUT/gif" "$OUT/tiff" "$OUT/webp" "$OUT/bmp"
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
rm base.png
find "$OUT" -type f | sort | sed 's#^#seed: #'
