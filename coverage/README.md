# Measuring how much of a parser the files reach

`fanbase evaluate --coverage` asks how much of a library's own code the files of a spec run, compared with a few real
files, and how that grows with the number of files (see the
[fanbase-cli README](https://github.com/fandango-fuzzer/fanbase-cli#how-much-of-a-parser-the-files-reach---coverage)).
For that the libraries have to be built so that what runs is counted. This folder is the recipe, and CI uses the image
it makes so that nothing is compiled on every run.

| library | version | pinned as | what is counted (library's own reading code) |
|---|---|---|---|
| libpng | 1.6.59 | commit `cd952f4` of `v1.6.59` | `png*.c` without the writing code and `pngpread.c` |
| libjpeg-turbo | 3.2.0 | commit `c85e6b9` of `3.2.0` | the decompressor (`jd*.c`, `jerror`, `jmemmgr`, `jutils`, ...), no SIMD |
| giflib | 5.2.2 | SHA-256 of the tarball | `dgif_lib`, `gifalloc`, `gif_err`, `gif_hash` |
| libtiff | 4.7.2 | commit `d01a94b` of `v4.7.2` | `libtiff/tif_*.c` without the writing code and the rarely used codecs |
| libwebp | 1.6.0 | commit `4fa2191` of `v1.6.0` | `src/dec`, `src/dsp` (C only, no SIMD), `src/utils`, `src/demux` |
| stb_image | `2c980bb` | SHA-256 of the file | the header, compiled for BMP only |

Everything is compiled with `gcc --coverage -O0`. Each library has a small program (`harness/`) that reads a file the
way an application does and exits 0 if the library took it, 1 if it said no, and a name in `libs.json` that says which
files count (`include` and `exclude`, patterns on the path from the library's source folder). `cov-reset LIB` clears
the counters, and `cov-snapshot LIB` asks gcov about every object that was built, so that code that never ran is in the
total, and prints what ran as JSON. The real files are made at build time, with ImageMagick, from its built-in picture
(`make-seeds.sh`): several encodings of each format, so that they reach different parts of a library.

What this does not tell: it is *line* and *branch* coverage of the reading path, with the library compiled without
optimisation and without SIMD; codecs a library calls into (zlib, the JPEG codec libtiff uses) are the system's and not
counted; and a high number says the files run much of the code, not that they run it with the values that break it.

```bash
docker build -t fanbase-coverage coverage/                      # about ten minutes
docker run --rm -v "$PWD":/registry -w /registry fanbase-coverage \
    fanbase evaluate png --coverage-only -n 1000 --curve 1,10,100,1000 --hide-crashes
```

`.github/workflows/coverage-image.yml` builds the image and publishes it as `ghcr.io/fandango-fuzzer/fanbase-coverage`
(on a change to this folder on `main`, or by hand); `.github/workflows/coverage.yml` uses it, once a week. The package
has to be made public, and linked to this repository, once, in its settings on GitHub, for the pull to need no login.

## Adding a library

1. Pin its source in `build-libs.sh` (a tag's commit, or an archive's hash) and build it with `$CFLAGS_COV`.
2. Add a program to `harness/` that reads one file and exits 0 or 1, and to `build-harness.sh`.
3. Add it to `libs.json`, and check what it counts: `cov-reset`, run the seeds, `cov-snapshot` — the total should be
   the library's reading code, and nothing else.
4. Add a `targets/<name>-cov/target.yml` like the others, and the seeds to `make-seeds.sh`.
