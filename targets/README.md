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
| `ffmpeg` | the same as Pillow | `ffmpeg` (not for jxl: it exits 0 on a truncated JPEG XL file, so it accepts files that nothing decodes) |
| `djpeg` | jpeg | `djpeg` (libjpeg-turbo) |
| `djxl` | jxl | `djxl` (`libjxl-tools`); the picture is decoded in full. A small wrapper gives it a file to write to, since the flag that says not to is newer than Ubuntu 24.04's version |
| `tiffinfo` | tiff | `tiffinfo` (libtiff) |
| `webpinfo` | webp | `webpinfo` (libwebp) |
| `giftext` | gif | `giftext` (giflib) |
| `pngcheck` | png | `pngcheck` (a strict conformance checker: it says what in a file breaks the specification; a warning rejects it; a small wrapper leaves out its zlib-version warning, which is about the machine) |

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

On Debian or Ubuntu: `apt install imagemagick ffmpeg libjpeg-turbo-progs libtiff-tools webp giflib-tools pngcheck librsvg2-bin libjxl-tools`,
and `pip install Pillow pillow-heif`. `fanbase targets` says which of them can run on your machine.

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
