# Targets

The parsers and tools that the files of a format are judged by, for `fanbase evaluate`. A format
names its targets in `specs/<format>/format.yml`. Each target is a folder with a `target.yml` that says
what to run for a file (its exit status is the verdict), what has to be installed, and how to read its
messages; see [the fanbase-cli README](https://github.com/fandango-fuzzer/fanbase-cli#evaluating-a-spec).

A target is code that the evaluation runs, so a change to one is reviewed like a change to a spec.

| target | judges | needs |
|---|---|---|
| `pillow` | bmp, gif, heic, jpeg, png, ppm, tiff, webp, xbm, xpm | Python package Pillow (and `pillow-heif`, which gives it a HEIC reader) |
| `imagemagick` | the same, and svg | `identify` (ImageMagick); a file that it decodes is accepted, warnings or not. It reads SVG with `rsvg-convert` (`librsvg2-bin`) |
| `imagemagick-strict` | the same | the same, but a warning rejects the file: "is it clean?" rather than "does it decode?" (not in any format's `targets` by default) |
| `ffmpeg` | the same as Pillow, and aac, flac, mp3, ogg, wav | `ffmpeg` (not for jxl: it exits 0 on a truncated JPEG XL file, so it accepts files that nothing decodes) |
| `djpeg` | jpeg | `djpeg` (libjpeg-turbo) |
| `djxl` | jxl | `djxl` (`libjxl-tools`); the picture is decoded in full. A small wrapper gives it a file to write to, since the flag that says not to is newer than Ubuntu 24.04's version |
| `tiffinfo` | tiff | `tiffinfo` (libtiff) |
| `webpinfo` | webp | `webpinfo` (libwebp) |
| `giftext` | gif | `giftext` (giflib) |
| `pngcheck` | png | `pngcheck` (a strict conformance checker: it says what in a file breaks the specification; a warning rejects it; a small wrapper leaves out its zlib-version warning, which is about the machine) |
| `libsndfile` | flac, mp3, ogg, wav | Python package soundfile, which brings libsndfile; every frame is read, and a file that says it has frames and gives none is rejected (libsndfile opens some Ogg files it cannot decode) |
| `flac` | flac | `flac` (libFLAC's own tool: `flac --test` decodes every frame and checks the MD5 sum of the audio) |
| `ogginfo` | ogg | `ogginfo` (`vorbis-tools`): checks the pages, and the headers of the Vorbis, Theora, Opus, Speex or FLAC streams in them; it does not decode the audio |
| `mpg123` | mp3 | `mpg123`; it exits 0 whatever it reads, so a small wrapper accepts a file only if mpg123 got audio out of it |
| `faad` | aac | `faad` (FAAD2); it exits 0 even when it cannot decode a file, so a small wrapper reads its `Error:` line |
| `libarchive` | 7z, ar, cab, cpio, rar, tar, zip | `bsdtar` (`libarchive-tools`); every entry is read to its end, which is when the checksums are checked. A small wrapper sends the contents to nothing and leaves the names of the entries out of what it said |
| `7zip` | the same, and arj | `7z` (`7zip`, and `7zip-rar` for RAR); `7z t` decodes every entry and checks it. Left to itself it opens a file as whatever archive it finds in it, and checks fields its readers do not need, so a small wrapper tells it the format the file's extension names (`-t`) |
| `unzip` | zip | `unzip` (Info-ZIP); `unzip -t` decodes every entry and checks its CRC-32 |
| `python-zipfile` | zip | Python's `zipfile`; every member is read to its end |
| `gnu-tar` | tar | `tar` (GNU); every header and its checksum is read (tar has no checksum of the contents) |
| `python-tarfile` | tar | Python's `tarfile`; every member is read |
| `cpio` | cpio | `cpio` (GNU); every entry is read, nothing is written, and the sums of the `crc` format are checked |
| `cabextract` | cab | `cabextract` (libmspack); `cabextract -t` decodes every file and checks it |
| `unrar` | rar | `unrar` (RARLAB, non-free); `unrar t` decodes every file and checks it. A small wrapper drops the lines that say which file it is testing |
| `arj` | arj | `arj` (the open-source ARJ); `arj t` decodes every file and checks its CRC-32. It starts with a banner and puts the reason last, so a small wrapper prints the reason first |
| `unar` | 7z, arj, rar, zip | `lsar` (The Unarchiver, `unar`); `lsar -t` decodes every entry and checks it. It judges only the formats that have checksums, and a small wrapper accepts a file only if it was read as the format of its extension |
| `gnu-ar` | ar | `ar` (GNU binutils); a small wrapper reads out every member (`ar p`), to nothing, which is what finds an archive that ends inside a member |
| `libxml2` | xml | `xmllint` (`libxml2-utils`): is the document well-formed? It is not let at the network, and does not substitute entities. A small wrapper leaves the file's name, the line and the names of elements out of what it said |
| `expat` | xml | `xmlwf` (`expat`): is the document well-formed? A small wrapper takes its reason from "FILE:LINE:COLUMN: reason" |
| `xerces` | xml | `SAX2Count` (`libxerces-c-samples`), one of Xerces-C++'s sample programs, which parses a document without validating it. Xerces loads an external DTD that a document names, over the network too, so a small wrapper points every proxy it could use at a port where nothing listens: a document whose DTD is a URL is refused, as one is whose DTD is not there |
| `python-json` | json | Python's `json`, with its defaults (it takes NaN, Infinity and repeated keys); the file must be UTF-8 |
| `jq` | json | `jq`; it reads a stream of values, so a small wrapper accepts a file only if it holds exactly one |
| `yajl` | json | `json_verify` (`yajl-tools`, YAJL), which reads standard input: a small wrapper gives it the file |
| `json-pp` | json | `json_pp` (Perl's JSON::PP), which reads standard input: a small wrapper gives it the file and keeps its reason without the offset |
| `node-json` | json | Node.js, `JSON.parse` (V8); the file is decoded as strict UTF-8 first |
| `cbor2` | cbor | Python package cbor2; the file must be one data item and nothing after it. It turns the tags it knows into values and rejects content that does not fit its tag (a date that is not one), so it judges validity |
| `cbor-diag` | cbor | Python package cbor-diag, which calls the Rust crate of that name to write the file in diagnostic notation; well-formedness only. What the crate has not implemented is counted as unsupported |

The `*-cov` targets are the libraries built to be measured, from [`coverage/`](../coverage/README.md), and run only in
its image, with `fanbase evaluate --coverage`: they are not named by any format, and `fanbase targets` shows them as
not ready anywhere else.

| target | judges | built from |
|---|---|---|
| `libpng-cov` | png | libpng 1.6.59 |
| `libjpeg-turbo-cov` | jpeg | libjpeg-turbo 3.2.0 |
| `giflib-cov` | gif | giflib 5.2.2 |
| `libtiff-cov` | tiff | libtiff 4.7.2 |
| `libwebp-cov` | webp | libwebp 1.6.0 |
| `stb-bmp-cov` | bmp | stb_image, BMP only |
| `libheif-cov` | heic | libheif 1.23.6 |
| `libjxl-cov` | jxl | libjxl 0.12.0 |
| `ffmpeg-pnm-cov` | ppm | FFmpeg n9.0.2, its PNM decoders |
| `ffmpeg-xbm-cov` | xbm | FFmpeg n9.0.2, its XBM decoder |
| `ffmpeg-xpm-cov` | xpm | FFmpeg n9.0.2, its XPM decoder |
| `nanosvg-cov` | svg | NanoSVG |
| `ffmpeg-wav-cov` | wav | FFmpeg n9.0.2, its WAV demuxer and PCM decoders |
| `ffmpeg-flac-cov` | flac | FFmpeg n9.0.2, its FLAC demuxer and decoder |
| `ffmpeg-ogg-cov` | ogg | FFmpeg n9.0.2, its Ogg demuxer and Vorbis decoder |
| `ffmpeg-mp3-cov` | mp3 | FFmpeg n9.0.2, its MP3 demuxer, tag readers and MPEG audio decoders |
| `ffmpeg-aac-cov` | aac | FFmpeg n9.0.2, its ADTS demuxer and AAC decoder |
| `libarchive-7z-cov` | 7z | libarchive 3.8.10, its 7z reader |
| `libarchive-ar-cov` | ar | libarchive 3.8.10, its ar reader |
| `libarchive-cab-cov` | cab | libarchive 3.8.10, its Cabinet reader |
| `libarchive-cpio-cov` | cpio | libarchive 3.8.10, its cpio reader |
| `libarchive-rar-cov` | rar | libarchive 3.8.10, its RAR readers (RAR 1.5 to 4, and RAR 5) |
| `libarchive-tar-cov` | tar | libarchive 3.8.10, its tar reader |
| `libarchive-zip-cov` | zip | libarchive 3.8.10, its ZIP reader |
| `7zip-arj-cov` | arj | 7-Zip 26.05, its ARJ reader |
| `libxml2-cov` | xml | libxml2 2.15.4, its parser |
| `expat-cov` | xml | Expat 2.10.0 |
| `json-c-cov` | json | json-c 0.19, its parser |
| `libcbor-cov` | cbor | libcbor 0.14.0, its decoder |

On Debian or Ubuntu: `apt install imagemagick ffmpeg libjpeg-turbo-progs libtiff-tools webp giflib-tools pngcheck librsvg2-bin libjxl-tools
flac mpg123 faad vorbis-tools libarchive-tools 7zip 7zip-rar unzip cpio cabextract unrar arj unar libxml2-utils expat libxerces-c-samples jq
yajl-tools nodejs` (`unrar` and `7zip-rar` are in Debian's non-free and Ubuntu's multiverse), and `pip install Pillow pillow-heif soundfile cbor2 cbor-diag`. `fanbase targets` says which of them can run on your machine.

**Where a target runs.** On a pull request (`evaluate.yml`), with a read-only token and no secrets, because a pull
request from a fork brings its own targets. On `main`, once a week and by hand (`evaluate-main.yml`), in a job that
also has no secrets: the only job that has them (the one that mails the private record) runs none of the registry's
code.

**When a target crashes or hangs on a file.** That may be a bug in the parser that is not fixed yet, so it is never
public. A public report counts it as an error and says no more (`--hide-crashes`); on `main` the details go into an
encrypted file for the one who reports it (see [CONTRIBUTING.md](../CONTRIBUTING.md)). Do not describe such a file, or
paste it, in a pull request or an issue. Run the parser itself as the target (`run: [djpeg, ..., "{file}"]`), not
through a shell wrapper that turns a signal into an exit status: a crash is only seen as one if the process is killed
by the signal. A limit that the library sets on itself (Pillow's "decompression bomb" error) is a `resource-limit`,
and is not a crash.
