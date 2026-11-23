/* Decodes a Zstandard file with libzstd: every frame of it, one after the other (skippable frames skipped), checking
   the checksums they have. The window may be up to 128 MiB, libzstd's default; no dictionary. Exit 0: libzstd took
   it. 1: it said no. */
#include <stdio.h>
#include <stdlib.h>
#include <zstd.h>

#define MAX_BYTES (64L * 1024 * 1024)

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    char *data = malloc(MAX_BYTES);
    size_t room = ZSTD_DStreamOutSize();
    char *out = malloc(room);
    if (!data || !out) return 2;
    size_t length = fread(data, 1, MAX_BYTES, file);
    fclose(file);
    if (length == 0) return fprintf(stderr, "invalid file: empty\n"), 1;

    ZSTD_DCtx *z = ZSTD_createDCtx();
    if (!z) return 2;
    ZSTD_inBuffer in = {data, length, 0};
    size_t status = 0;
    while (in.pos < in.size) {
        ZSTD_outBuffer o = {out, room, 0};
        status = ZSTD_decompressStream(z, &o, &in);
        if (ZSTD_isError(status)) {
            fprintf(stderr, "invalid frame: %s\n", ZSTD_getErrorName(status));
            return 1;
        }
    }
    for (int more = 1; status != 0 && more; ) { /* what is still in the context, after the last input */
        ZSTD_outBuffer o = {out, room, 0};
        status = ZSTD_decompressStream(z, &o, &in);
        if (ZSTD_isError(status)) return fprintf(stderr, "invalid frame: %s\n", ZSTD_getErrorName(status)), 1;
        more = o.pos == o.size;
    }
    if (status != 0) return fprintf(stderr, "invalid frame: ends in the middle\n"), 1;
    ZSTD_freeDCtx(z);
    free(data);
    free(out);
    return 0;
}
