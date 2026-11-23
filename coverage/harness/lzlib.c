/* Decompresses an lzip file with lzlib: every member of it, checking its CRC-32 and sizes. Exit 0: lzlib took it. 1: it
   said no. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <lzlib.h>

#define MAX_BYTES (64L * 1024 * 1024)

static int fail(struct LZ_Decoder *z, const char *what) {
    fprintf(stderr, "invalid file: %s\n", what ? what : LZ_strerror(LZ_decompress_errno(z)));
    LZ_decompress_close(z);
    return 1;
}

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    uint8_t *data = malloc(MAX_BYTES), out[65536];
    if (!data) return 2;
    long length = (long)fread(data, 1, MAX_BYTES, file);
    fclose(file);

    struct LZ_Decoder *z = LZ_decompress_open();
    if (!z || LZ_decompress_errno(z) != LZ_ok) return 2;
    long written = 0;
    if (length == 0) LZ_decompress_finish(z);
    for (;;) {
        int took = 0;
        if (written < length) {
            long room = length - written;
            took = LZ_decompress_write(z, data + written, (int)(room < 65536 ? room : 65536));
            if (took < 0) return fail(z, NULL);
            written += took;
            if (written == length) LZ_decompress_finish(z);
        }
        int got = LZ_decompress_read(z, out, sizeof out);
        if (got < 0) return fail(z, NULL);
        if (LZ_decompress_finished(z) == 1) break;
        if (got == 0 && took == 0 && written == length) return fail(z, "ends in the middle of a member");
    }
    LZ_decompress_close(z);
    free(data);
    return 0;
}
