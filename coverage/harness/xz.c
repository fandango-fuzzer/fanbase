/* Decompresses an .xz file with liblzma: every stream of it, and the stream padding between them, as xz reads them
   (LZMA_CONCATENATED), checking every block. No memory limit. Exit 0: liblzma took it. 1: it said no. */
#include <lzma.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_BYTES (64L * 1024 * 1024)

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    uint8_t *data = malloc(MAX_BYTES), *out = malloc(1 << 16);
    if (!data || !out) return 2;
    size_t length = fread(data, 1, MAX_BYTES, file);
    fclose(file);

    lzma_stream z = LZMA_STREAM_INIT;
    if (lzma_stream_decoder(&z, UINT64_MAX, LZMA_CONCATENATED) != LZMA_OK) return 2;
    z.next_in = data;
    z.avail_in = length;
    lzma_ret status;
    do {
        z.next_out = out;
        z.avail_out = 1 << 16;
        status = lzma_code(&z, z.avail_in ? LZMA_RUN : LZMA_FINISH);
    } while (status == LZMA_OK);
    lzma_end(&z);
    free(data);
    free(out);
    if (status == LZMA_STREAM_END) return 0;
    static const char *why[] = {"ok", "stream end", "no check", "unsupported check", "get check", "out of memory",
                                "memory limit", "not xz", "options error", "data error", "buffer error", "program error"};
    fprintf(stderr, "invalid stream: %s\n", status <= LZMA_PROG_ERROR ? why[status] : "error");
    return 1;
}
