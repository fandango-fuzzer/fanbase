#!/bin/sh
# A few real files of each format, made by real tools (ImageMagick, from its built-in picture; libheif's and libjxl's own
# encoders for HEIC and JPEG XL; FFmpeg, from two tones, for the sound formats) and not by a grammar: what the generated
# files are compared with. Different encodings, so that they reach different parts of a library. The SVG files are written
# by hand, in seed-sources/, since no tool makes a vector drawing from a picture. The archives are made by the tools that
# write them, from a small tree of files; RAR, which no free tool writes, comes from the archives that libarchive's own tests
# read (made by WinRAR). The XML files are written by hand (seed-sources/xml/), and the SVG ones count as XML too; JSON
# is written by Python's json, and CBOR by cbor2, with the examples of RFC 8949's appendix A.
set -eu
OUT=/opt/cov/seeds
mkdir -p "$OUT/png" "$OUT/jpeg" "$OUT/gif" "$OUT/tiff" "$OUT/webp" "$OUT/bmp" "$OUT/heic" "$OUT/jxl" "$OUT/ppm" "$OUT/xbm" "$OUT/xpm" "$OUT/svg" \
    "$OUT/wav" "$OUT/flac" "$OUT/ogg" "$OUT/mp3" "$OUT/aac" \
    "$OUT/zip" "$OUT/tar" "$OUT/7z" "$OUT/rar" "$OUT/cab" "$OUT/cpio" "$OUT/arj" "$OUT/ar" \
    "$OUT/xml" "$OUT/json" "$OUT/cbor" "$OUT/ttf" "$OUT/otf" "$OUT/woff" "$OUT/woff2" "$OUT/pcf"
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

# XML: written by hand, and the SVG drawings
cp /opt/cov/seed-sources/xml/*.xml "$OUT/xml/"
for drawing in /opt/cov/seed-sources/svg/*.svg; do cp "$drawing" "$OUT/xml/svg-$(basename "$drawing" .svg).xml"; done

# JSON, by Python's json, from a few kinds of data
python3 - "$OUT/json" <<'PYTHON'
import json, sys
out = sys.argv[1]
record = {"id": 7, "name": "Ada", "tags": ["a", "b"], "active": True, "score": 9.5, "parent": None, "nested": {"x": [1, 2, {"y": []}]}}
def write(name, text):
    open(f"{out}/{name}.json", "w", encoding="utf-8").write(text)
write("pretty", json.dumps(record, indent=2))
write("compact", json.dumps([record, record], separators=(",", ":")))
write("escaped", json.dumps({"text": "café ☺ \U0001F600 \"q\" \\ / \b\f\n\r\t \u0001", "kéy": "v"}))
write("utf8", json.dumps({"de": "Grüße", "el": "καλημέρα", "ja": "こんにちは"}, ensure_ascii=False))
write("numbers", '[0, -0, 1, -1, 9223372036854775807, -9223372036854775808, 1.5, -0.25, 1e10, 1E-10, 2.5e+300, 0.1e1]')
write("deep", "[" * 30 + "{\"leaf\": true}" + "]" * 30)
write("empty", '{"a": {}, "b": [], "c": "", "d": [{}, []]}')
write("scalar", '"just a string"')
write("records", json.dumps([{"n": i, "sq": i * i, "even": i % 2 == 0} for i in range(30)]))
PYTHON

# CBOR, by cbor2 from Python values (its tags too), and the examples of RFC 8949, appendix A
python3 - "$OUT/cbor" <<'PYTHON'
import cbor2, datetime, decimal, fractions, ipaddress, re, sys, uuid
out = sys.argv[1]
values = {
    "record": {"id": 7, "name": "Ada", "tags": ["a", "b"], "active": True, "score": 9.5, "parent": None, "raw": b"\x00\x01"},
    "integers": [0, 23, 24, 255, 256, 65535, 65536, 2**32, 2**64 - 1, -1, -24, -25, -2**64, 2**70, -2**70],
    "floats": [0.0, -0.0, 1.5, 65504.0, 1e300, float("inf"), float("-inf"), float("nan"), 5e-324],
    "strings": ["", "a", "café", "\U0001F600", "x" * 300, b"", b"\xff" * 300],
    "tags": [datetime.datetime(2013, 3, 21, 20, 4, tzinfo=datetime.timezone.utc), decimal.Decimal("273.15"),
             fractions.Fraction(1, 3), uuid.UUID(int=2**127), ipaddress.ip_address("192.168.0.1"),
             ipaddress.ip_network("10.0.0.0/8"), re.compile("a+b*"), {1, 2, 3}, datetime.date(2020, 1, 1)],
    "nested": [[[[{"k": [1, {"j": [2, 3]}]}]]]],
}
for name, value in values.items():
    open(f"{out}/{name}.cbor", "wb").write(cbor2.dumps(value, datetime_as_timestamp=False, value_sharing=False))
open(f"{out}/canonical.cbor", "wb").write(cbor2.dumps(values["record"], canonical=True))
appendix_a = ["1b000000e8d4a51000", "1bffffffffffffffff", "c249010000000000000000", "3bffffffffffffffff", "3903e7",
              "f93c00", "fb3ff199999999999a", "f97bff", "fa7f7fffff", "f90001", "f9c400", "f97e00", "f0", "f8ff",
              "c074323031332d30332d32315432303a30343a30305a", "c1fb41d452d9ec200000", "d74401020304", "d818456449455446",
              "d82076687474703a2f2f7777772e6578616d706c652e636f6d", "64f0908591", "8301820203820405",
              "98190102030405060708090a0b0c0d0e0f101112131415161718181819",
              "a56161614161626142616361436164614461656145", "5f42010243030405ff", "7f657374726561646d696e67ff", "9fff",
              "9f018202039f0405ffff", "83019f0203ff820405", "bf61610161629f0203ffff", "bf6346756ef563416d7421ff"]
for number, item in enumerate(appendix_a):
    open(f"{out}/rfc8949-{number:02d}.cbor", "wb").write(bytes.fromhex(item))
PYTHON

# Fonts: parts of DejaVu (TrueType, hinted) and GNU FreeFont (CFF), cut by fontTools' subsetter, and Cantarell, a variable
# font with CFF2 outlines; WOFF made from them by sfnt2woff (the WOFF reference code) and by fontTools, WOFF2 by
# woff2_compress (Google's) and by fontTools (with hmtx transformed too); PCF fonts of X11's misc set, and the same fonts
# written again by bdftopcf with other paddings, scan units and byte and bit orders
latin=U+0020-007E,U+00A0-00FF
dejavu=/usr/share/fonts/truetype/dejavu freefont=/usr/share/fonts/opentype/freefont
pyftsubset "$dejavu/DejaVuSans.ttf" --unicodes=$latin --output-file="$OUT/ttf/dejavu-sans-latin.ttf"
pyftsubset "$dejavu/DejaVuSerif-Bold.ttf" --unicodes=$latin,U+0391-03C9 --output-file="$OUT/ttf/dejavu-serif-bold-greek.ttf"
pyftsubset "$dejavu/DejaVuSans-Bold.ttf" --unicodes=U+0020-007E --no-hinting --output-file="$OUT/ttf/dejavu-sans-bold-unhinted.ttf"
pyftsubset "$dejavu/DejaVuSerif.ttf" --unicodes=U+0020-024F,U+0400-04FF --layout-features='*' --output-file="$OUT/ttf/dejavu-serif-cyrillic.ttf"
pyftsubset "$freefont/FreeSans.otf" --unicodes=$latin --output-file="$OUT/otf/freesans-latin.otf"
pyftsubset "$freefont/FreeSerifBold.otf" --unicodes=$latin,U+0391-03C9 --output-file="$OUT/otf/freeserif-bold-greek.otf"
pyftsubset "$freefont/FreeMono.otf" --unicodes=U+0020-007E --desubroutinize --output-file="$OUT/otf/freemono-desubroutinized.otf"
pyftsubset /usr/share/fonts/opentype/cantarell/Cantarell-VF.otf --unicodes=$latin --output-file="$OUT/otf/cantarell-variable.otf"
for font in "$OUT/ttf/dejavu-sans-latin.ttf" "$OUT/otf/freesans-latin.otf"; do
    cp "$font" . && sfnt2woff "$(basename "$font")" && mv "$(basename "${font%.*}").woff" "$OUT/woff/sfnt2woff-$(basename "${font%.*}").woff"
    cp "$font" . && woff2_compress "$(basename "$font")" > /dev/null && mv "$(basename "${font%.*}").woff2" "$OUT/woff2/google-$(basename "${font%.*}").woff2"
    rm -f "$(basename "$font")"
done
pyftsubset "$dejavu/DejaVuSerif-Bold.ttf" --unicodes=$latin --flavor=woff --output-file="$OUT/woff/fonttools-dejavu-serif-bold.woff"
python3 -m fontTools.ttLib.woff2 compress --hmtx-transform -o "$OUT/woff2/fonttools-hmtx-dejavu-serif-bold.woff2" "$OUT/ttf/dejavu-serif-bold-greek.ttf"
python3 -m fontTools.ttLib.woff2 compress --no-glyf-transform -o "$OUT/woff2/fonttools-null-dejavu-sans-bold.woff2" "$OUT/ttf/dejavu-sans-bold-unhinted.ttf"
for font in 6x13 9x15B 10x20 7x14 cursor 12x13ja; do gunzip -c "/usr/share/fonts/X11/misc/$font.pcf.gz" > "$OUT/pcf/$font.pcf"; done
pcf2bdf -o 6x13.bdf "$OUT/pcf/6x13.pcf"
bdftopcf -p1 -u1 -l -L -o "$OUT/pcf/6x13-lsb-pad1.pcf" 6x13.bdf
bdftopcf -p8 -u4 -m -M -o "$OUT/pcf/6x13-msb-pad8.pcf" 6x13.bdf
bdftopcf -p2 -u2 -m -L -o "$OUT/pcf/6x13-mixed-pad2.pcf" 6x13.bdf
bdftopcf -t -o "$OUT/pcf/6x13-terminal.pcf" 6x13.bdf
rm -f 6x13.bdf

# The compression formats: the same data (this image's harnesses, as text; 300 kB of zeros; 70 kB that does not
# compress, from Python's random with a fixed seed) compressed by the tools of each format, at their fastest and their
# best, and with the options that change what is in a file (names, checks, filters, blocks, more than one member)
mkdir -p "$OUT/gz" "$OUT/bz2" "$OUT/xz" "$OUT/lz" "$OUT/lz4" "$OUT/zst" "$OUT/z" "$OUT/zlib" "$OUT/sz"
cat /opt/cov/harness/*.c > text.txt
head -c 300000 /dev/zero > zeros.bin
python3 -c "import random, sys; random.seed(1); sys.stdout.buffer.write(random.randbytes(70000))" > noise.bin
for data in text zeros noise; do
    file=$data.$( [ $data = text ] && echo txt || echo bin )
    gzip -n -9 -c "$file" > "$OUT/gz/$data.gz"
    bzip2 -9 -c "$file" > "$OUT/bz2/$data.bz2"
    xz -6 -c "$file" > "$OUT/xz/$data.xz"
    lzip -9 -c "$file" > "$OUT/lz/$data.lz"
    lz4 -q -9 -c "$file" > "$OUT/lz4/$data.lz4"
    zstd -q -19 -c "$file" > "$OUT/zst/$data.zst"
    compress -c "$file" > "$OUT/z/$data.Z"
done
gzip -n -1 -c text.txt > "$OUT/gz/fastest.gz"
cp text.txt named.txt && gzip -9 named.txt && mv named.txt.gz "$OUT/gz/with-name.gz"
(gzip -n -c text.txt; gzip -n -c noise.bin) > "$OUT/gz/two-members.gz"
bzip2 -1 -c text.txt > "$OUT/bz2/fastest.bz2"
(bzip2 -c text.txt; bzip2 -c zeros.bin) > "$OUT/bz2/two-streams.bz2"
xz -0 -c text.txt > "$OUT/xz/fastest.xz"
xz -9e -c text.txt > "$OUT/xz/extreme.xz"
xz --check=crc32 -c text.txt > "$OUT/xz/crc32.xz"
xz --check=sha256 -c text.txt > "$OUT/xz/sha256.xz"
xz --check=none -c text.txt > "$OUT/xz/no-check.xz"
xz --delta=dist=4 --lzma2=preset=6 -c text.txt > "$OUT/xz/delta.xz"
xz --x86 --lzma2=preset=6 -c text.txt > "$OUT/xz/x86.xz"
xz --block-size=20000 -c text.txt > "$OUT/xz/blocks.xz"
(xz -c text.txt; xz -c noise.bin) > "$OUT/xz/two-streams.xz"
lzip -0 -c text.txt > "$OUT/lz/fastest.lz"
lzip -b 20KiB -c text.txt > "$OUT/lz/members.lz"
lz4 -q -1 -c text.txt > "$OUT/lz4/fastest.lz4"
lz4 -q -l -c text.txt > "$OUT/lz4/legacy.lz4"
lz4 -q -BD -B4 -c text.txt > "$OUT/lz4/linked-blocks.lz4"
lz4 -q -BX --content-size -c text.txt > "$OUT/lz4/block-checksums.lz4"
lz4 -q --no-frame-crc -c text.txt > "$OUT/lz4/no-checksum.lz4"
zstd -q -1 -c text.txt > "$OUT/zst/fastest.zst"
zstd -q --fast=5 -c text.txt > "$OUT/zst/negative-level.zst"
zstd -q --no-check -c text.txt > "$OUT/zst/no-check.zst"
zstd -q --ultra -22 -c text.txt > "$OUT/zst/ultra.zst"
(zstd -q -c text.txt; zstd -q -c noise.bin) > "$OUT/zst/two-frames.zst"
compress -b 10 -c text.txt > "$OUT/z/ten-bits.Z"
compress -b 12 -c text.txt > "$OUT/z/twelve-bits.Z"
python3 - "$OUT" <<'PYTHON'
import io, snappy, sys, zlib
out = sys.argv[1]
data = {name: open(f, "rb").read() for name, f in (("text", "text.txt"), ("zeros", "zeros.bin"), ("noise", "noise.bin"))}
for name, value in data.items():
    open(f"{out}/zlib/{name}.zlib", "wb").write(zlib.compress(value, 9))
    stream = io.BytesIO()
    snappy.stream_compress(io.BytesIO(value), stream)
    open(f"{out}/sz/{name}.sz", "wb").write(stream.getvalue())
for level in (0, 1):
    open(f"{out}/zlib/level-{level}.zlib", "wb").write(zlib.compress(data["text"], level))
for wbits, strategy, name in ((9, zlib.Z_DEFAULT_STRATEGY, "window-512"), (15, zlib.Z_FIXED, "fixed-codes"),
                              (15, zlib.Z_HUFFMAN_ONLY, "huffman-only"), (15, zlib.Z_RLE, "rle")):
    c = zlib.compressobj(6, zlib.DEFLATED, wbits, 8, strategy)
    open(f"{out}/zlib/{name}.zlib", "wb").write(c.compress(data["text"]) + c.flush())
PYTHON
rm -f text.txt zeros.bin noise.bin

cp /opt/cov/seed-sources/svg/*.svg "$OUT/svg/"
rm -f base.png base.jpg gray.jpg gray.png alpha.png sixteen.png tones.wav sparse.bin lib.c && rm -r tree
find "$OUT" -type f | sort | sed 's#^#seed: #'
