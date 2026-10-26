#!/bin/sh
# A few real files of each format, made by real tools (ImageMagick, from its built-in picture; libheif's and libjxl's own
# encoders for HEIC and JPEG XL; FFmpeg, from two tones, for the sound formats) and not by a grammar: what the generated
# files are compared with. Different encodings, so that they reach different parts of a library. The SVG files are written
# by hand, in seed-sources/, since no tool makes a vector drawing from a picture. The archives are made by the tools that
# write them, from a small tree of files; RAR, which no free tool writes, comes from the archives that libarchive's own tests
# read (made by WinRAR).
set -eu
OUT=/opt/cov/seeds
mkdir -p "$OUT/png" "$OUT/jpeg" "$OUT/gif" "$OUT/tiff" "$OUT/webp" "$OUT/bmp" "$OUT/heic" "$OUT/jxl" "$OUT/ppm" "$OUT/xbm" "$OUT/xpm" "$OUT/svg" \
    "$OUT/wav" "$OUT/flac" "$OUT/ogg" "$OUT/mp3" "$OUT/aac" \
    "$OUT/zip" "$OUT/tar" "$OUT/7z" "$OUT/rar" "$OUT/cab" "$OUT/cpio" "$OUT/arj" "$OUT/ar"
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

# Sound, with the FFmpeg of the system (its own encoders, and LAME, libvorbis and libopus through it), from two tones
sound() { ffmpeg -nostdin -v error -y "$@"; }
sound -f lavfi -i "sine=frequency=440:duration=0.5" -f lavfi -i "sine=frequency=660:duration=0.5" -filter_complex amerge=inputs=2 \
    -ar 44100 tones.wav
sound -i tones.wav "$OUT/wav/plain.wav"
sound -i tones.wav -ac 1 -ar 8000 -c:a pcm_u8 "$OUT/wav/eight-bit.wav"
sound -i tones.wav -c:a pcm_s24le -ar 48000 "$OUT/wav/twenty-four-bit.wav"
sound -i tones.wav -c:a pcm_f32le "$OUT/wav/float.wav"
sound -i tones.wav -ac 1 -ar 8000 -c:a pcm_alaw "$OUT/wav/a-law.wav"
sound -i tones.wav -ac 1 -ar 8000 -c:a pcm_mulaw "$OUT/wav/mu-law.wav"
sound -i tones.wav -metadata title=Seed -metadata artist=Fanbase "$OUT/wav/tagged.wav"
sound -i tones.wav -rf64 always "$OUT/wav/rf64.wav"

sound -i tones.wav "$OUT/flac/plain.flac"
sound -i tones.wav -compression_level 0 "$OUT/flac/fast.flac"
sound -i tones.wav -compression_level 12 "$OUT/flac/best.flac"
sound -i tones.wav -ac 1 -ar 8000 "$OUT/flac/mono.flac"
sound -i tones.wav -sample_fmt s32 -bits_per_raw_sample 24 -ar 96000 "$OUT/flac/twenty-four-bit.flac"
sound -i tones.wav -metadata title=Seed -metadata artist=Fanbase "$OUT/flac/tagged.flac"

sound -i tones.wav -c:a libvorbis -q:a 2 "$OUT/ogg/vorbis-low.ogg"
sound -i tones.wav -c:a libvorbis -q:a 8 "$OUT/ogg/vorbis-high.ogg"
sound -i tones.wav -ac 1 -ar 22050 -c:a libvorbis "$OUT/ogg/vorbis-mono.ogg"
sound -i tones.wav -c:a libvorbis -metadata title=Seed -metadata artist=Fanbase "$OUT/ogg/tagged.ogg"
sound -i tones.wav -c:a libopus -b:a 64k "$OUT/ogg/opus.ogg"
sound -i tones.wav -c:a flac -f ogg "$OUT/ogg/flac.ogg"

sound -i tones.wav -c:a libmp3lame -b:a 128k "$OUT/mp3/cbr.mp3"
sound -i tones.wav -c:a libmp3lame -q:a 2 "$OUT/mp3/vbr.mp3"
sound -i tones.wav -c:a libmp3lame -ac 1 -ar 22050 -b:a 32k "$OUT/mp3/mpeg-2.mp3"
sound -i tones.wav -c:a libmp3lame -ac 1 -ar 8000 -b:a 16k "$OUT/mp3/mpeg-2-5.mp3"
sound -i tones.wav -c:a libmp3lame -id3v2_version 4 -write_id3v1 1 -metadata title=Seed -metadata artist=Fanbase "$OUT/mp3/tagged.mp3"
sound -i tones.wav -c:a mp2 -f mp2 "$OUT/mp3/layer-2.mp3"

sound -i tones.wav -c:a aac -f adts "$OUT/aac/plain.aac"
sound -i tones.wav -c:a aac -ac 1 -ar 8000 -f adts "$OUT/aac/mono.aac"
sound -i tones.wav -c:a aac -ac 6 -f adts "$OUT/aac/surround.aac"
sound -i tones.wav -c:a aac -b:a 32k -f adts "$OUT/aac/low-rate.aac"
sound -i tones.wav -c:a aac -profile:a aac_main -f adts "$OUT/aac/main-profile.aac"
sound -i tones.wav -c:a aac -profile:a aac_ltp -strict -2 -f adts "$OUT/aac/ltp.aac"   # LTP is "experimental" in FFmpeg's encoder

# Archives, of a small tree: text, numbers, bytes that do not compress, a folder in a folder, a link, a long name
mkdir -p tree/dir/sub/a-folder-whose-name-is-long-enough-that-a-path-in-it-is-more-than-a-hundred-characters
(cd tree && printf 'hello hello hello hello\n' > hello.txt && seq 1 3000 > dir/numbers.txt \
    && python3 -c "import random; random.seed(1); open('dir/sub/bytes.bin', 'wb').write(random.randbytes(2000))" \
    && cp hello.txt dir/sub/a-folder-whose-name-is-long-enough-that-a-path-in-it-is-more-than-a-hundred-characters/hello.txt \
    && ln -s hello.txt link)
cd tree
zip -q -r -0 "$OUT/zip/stored.zip" .
zip -q -r "$OUT/zip/deflate.zip" .
zip -q -r -Z bzip2 "$OUT/zip/bzip2.zip" .
zip -q -r -y "$OUT/zip/symlink.zip" .
zip -q -r -fz "$OUT/zip/zip64.zip" .
zip -q - hello.txt dir/numbers.txt > "$OUT/zip/streamed.zip"          # to a pipe: sizes in data descriptors after the data
echo "an archive comment" | zip -q -r -z "$OUT/zip/comment.zip" .
7z a -bso0 -bsp0 -tzip -mm=LZMA "$OUT/zip/lzma.zip" .
7z a -bso0 -bsp0 -tzip -mm=PPMd "$OUT/zip/ppmd.zip" .
7z a -bso0 -bsp0 "$OUT/7z/lzma2.7z" .
7z a -bso0 -bsp0 -m0=LZMA "$OUT/7z/lzma.7z" .
7z a -bso0 -bsp0 -m0=PPMd "$OUT/7z/ppmd.7z" .
7z a -bso0 -bsp0 -m0=BZip2 "$OUT/7z/bzip2.7z" .
7z a -bso0 -bsp0 -m0=Deflate "$OUT/7z/deflate.7z" .
7z a -bso0 -bsp0 -mx0 "$OUT/7z/stored.7z" .
7z a -bso0 -bsp0 -ms=off "$OUT/7z/not-solid.7z" .
7z a -bso0 -bsp0 -mf=Delta:4 "$OUT/7z/delta.7z" .
tar --format=ustar -cf "$OUT/tar/ustar.tar" hello.txt dir/numbers.txt link
tar --format=gnu -cf "$OUT/tar/gnu.tar" .
tar --format=pax -cf "$OUT/tar/pax.tar" .
tar --format=v7 -cf "$OUT/tar/v7.tar" hello.txt dir/numbers.txt
tar --format=oldgnu -cf "$OUT/tar/oldgnu.tar" .
truncate -s 1M ../sparse.bin && printf 'data' | dd of=../sparse.bin bs=1 seek=500000 conv=notrunc 2>/dev/null
tar --format=gnu --sparse -cf "$OUT/tar/sparse.tar" -C .. sparse.bin
tar --format=pax --sparse -cf "$OUT/tar/sparse-pax.tar" -C .. sparse.bin
find . | cpio -o -H newc --quiet > "$OUT/cpio/newc.cpio"
find . | cpio -o -H crc --quiet > "$OUT/cpio/crc.cpio"
find . | cpio -o -H odc --quiet > "$OUT/cpio/odc.cpio"
find . | cpio -o -H bin --quiet > "$OUT/cpio/bin.cpio"
printf 'int fanbase(void) { return 1; }\n' > ../lib.c && gcc -c ../lib.c -o lib.o
ar rc "$OUT/ar/plain.a" hello.txt dir/numbers.txt
ar rcs "$OUT/ar/library.a" lib.o                                     # a static library: a symbol table first
ar rc "$OUT/ar/long-names.a" dir/sub/a-folder-whose-name-is-long-enough-that-a-path-in-it-is-more-than-a-hundred-characters/hello.txt
bsdtar --format arbsd -cf "$OUT/ar/bsd.a" hello.txt dir/numbers.txt
rm lib.o
gcab -c "$OUT/cab/stored.cab" hello.txt dir/numbers.txt dir/sub/bytes.bin
gcab -c -z "$OUT/cab/mszip.cab" hello.txt dir/numbers.txt dir/sub/bytes.bin
arj a -y -r -m1 "$OUT/arj/method1.arj" hello.txt dir > /dev/null
arj a -y -r -m2 "$OUT/arj/method2.arj" hello.txt dir > /dev/null
arj a -y -r -m3 "$OUT/arj/method3.arj" hello.txt dir > /dev/null
arj a -y -r -m4 "$OUT/arj/method4.arj" hello.txt dir > /dev/null
arj a -y -m0 "$OUT/arj/stored.arj" hello.txt dir/numbers.txt > /dev/null
cd /tmp
for name in rar rar_compress_best rar_filter rar_unicode rar5_stored rar5_compressed rar5_solid rar5_blake2 rar5_arm; do
    python3 -c "
import binascii, sys
out = open(sys.argv[2], 'wb')
for line in open(sys.argv[1]):
    if line.startswith('begin ') or line.strip() in ('', 'end', '\`'):
        continue
    out.write(binascii.a2b_uu(line))" "/opt/cov/src/libarchive/libarchive/test/test_read_format_$name.rar.uu" "$OUT/rar/$name.rar"
done

cp /opt/cov/seed-sources/svg/*.svg "$OUT/svg/"
rm -f base.png base.jpg gray.jpg gray.png alpha.png sixteen.png tones.wav sparse.bin lib.c && rm -r tree
find "$OUT" -type f | sort | sed 's#^#seed: #'
