/* Decompresses a bzip2 file with libbzip2: every stream of it, one after the other, as bzip2 reads them; anything after
   the last one is refused. Exit 0: libbzip2 took it. 1: it said no. */
#include <bzlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BYTES (64L * 1024 * 1024)

static int fail(const char *what, int status, bz_stream *z) {
    fprintf(stderr, "invalid stream: %s (%d)\n", what, status);
    BZ2_bzDecompressEnd(z);
    return 1;
}

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    char *data = malloc(MAX_BYTES), *out = malloc(1 << 16);
    if (!data || !out) return 2;
    size_t length = fread(data, 1, MAX_BYTES, file);
    fclose(file);
    if (length == 0) return fprintf(stderr, "invalid stream: empty file\n"), 1;

    bz_stream z;
    memset(&z, 0, sizeof z);
    if (BZ2_bzDecompressInit(&z, 0, 0) != BZ_OK) return 2;
    z.next_in = data;
    z.avail_in = (unsigned)length;
    for (;;) {
        z.next_out = out;
        z.avail_out = 1 << 16;
        int status = BZ2_bzDecompress(&z);
        if (status == BZ_STREAM_END) {
            if (z.avail_in == 0) break;
            char *next = z.next_in;
            unsigned left = z.avail_in;
            BZ2_bzDecompressEnd(&z);
            memset(&z, 0, sizeof z);
            if (BZ2_bzDecompressInit(&z, 0, 0) != BZ_OK) return 2;
            z.next_in = next;
            z.avail_in = left;
            continue;
        }
        if (status == BZ_DATA_ERROR_MAGIC) return fail("not bzip2 data", status, &z);
        if (status == BZ_DATA_ERROR) return fail("data error", status, &z);
        if (status != BZ_OK) return fail("error", status, &z);
        if (z.avail_in == 0 && z.avail_out != 0) return fail("ends in the middle", status, &z);
    }
    BZ2_bzDecompressEnd(&z);
    free(data);
    free(out);
    return 0;
}
