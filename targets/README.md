# Targets

The parsers and tools that the files of a format are judged by, for `fanbase evaluate`. A format
names its targets in `specs/<format>/format.yml`. Each target is a folder with a `target.yml` that says
what to run for a file (its exit status is the verdict), what has to be installed, and how to read its
messages; see [the fanbase-cli README](https://github.com/fandango-fuzzer/fanbase-cli#evaluating-a-spec).

A target is code that the evaluation runs, so a change to one is reviewed like a change to a spec.

| target | judges | needs |
|---|---|---|
| `pillow` | bmp, gif, jpeg, png, tiff, webp | Python package Pillow |
| `imagemagick` | the same | `identify` (ImageMagick); a file that it decodes is accepted, warnings or not |
| `imagemagick-strict` | the same | the same, but a warning rejects the file: "is it clean?" rather than "does it decode?" (not in any format's `targets` by default) |
| `ffmpeg` | the same | `ffmpeg` |
| `djpeg` | jpeg | `djpeg` (libjpeg-turbo) |
| `tiffinfo` | tiff | `tiffinfo` (libtiff) |
| `webpinfo` | webp | `webpinfo` (libwebp) |
| `giftext` | gif | `giftext` (giflib) |

On Debian or Ubuntu: `apt install imagemagick ffmpeg libjpeg-turbo-progs libtiff-tools webp giflib-tools`,
and `pip install Pillow`. `fanbase targets` says which of them can run on your machine.
