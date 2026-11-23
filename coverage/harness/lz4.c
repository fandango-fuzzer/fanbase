/* Decodes an LZ4 file with liblz4: its frames, one after the other, with LZ4F (which skips the skippable frames and
   checks the checksums that a frame has); a legacy frame (magic 0x184C2102), which LZ4F does not read, is decoded block
   by block with LZ4_decompress_safe, as the lz4 tool does. Exit 0: liblz4 took it. 1: it said no. */
#include <lz4.h>
#include <lz4frame.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BYTES (64L * 1024 * 1024)
#define LEGACY_BLOCK (8 << 20) /* what a legacy block decodes to, at most */

static uint32_t le32(const uint8_t *p) { return p[0] | p[1] << 8 | p[2] << 16 | (uint32_t)p[3] << 24; }

/* The legacy frame at data: its blocks, until the end of the file or the magic number of another frame */
static long legacy(const uint8_t *data, long length, char *out) {
    long at = 4;
    while (at + 4 <= length) {
        uint32_t size = le32(data + at);
        if (size == 0x184D2204 || size == 0x184C2102 || (size & 0xFFFFFFF0) == 0x184D2A50) break;
        if (size > LZ4_compressBound(LEGACY_BLOCK) || at + 4 + (long)size > length) return -1;
        if (LZ4_decompress_safe((const char *)data + at + 4, out, (int)size, LEGACY_BLOCK) < 0) return -1;
        at += 4 + size;
    }
    return at;
}

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    uint8_t *data = malloc(MAX_BYTES);
    char *out = malloc(LEGACY_BLOCK);
    if (!data || !out) return 2;
    long length = (long)fread(data, 1, MAX_BYTES, file);
    fclose(file);
    if (length == 0) return fprintf(stderr, "invalid file: empty\n"), 1;

    LZ4F_dctx *z;
    if (LZ4F_isError(LZ4F_createDecompressionContext(&z, LZ4F_VERSION))) return 2;
    long at = 0;
    size_t status = 0; /* 0: between frames */
    while (at < length) {
        if (status == 0 && length - at >= 4 && le32(data + at) == 0x184C2102) {
            long used = legacy(data + at, length - at, out);
            if (used < 0) return fprintf(stderr, "invalid legacy frame\n"), 1;
            at += used;
            continue;
        }
        size_t in = (size_t)(length - at), room = LEGACY_BLOCK;
        status = LZ4F_decompress(z, out, &room, data + at, &in, NULL);
        if (LZ4F_isError(status)) return fprintf(stderr, "invalid frame: %s\n", LZ4F_getErrorName(status)), 1;
        if (in == 0 && room == 0) return fprintf(stderr, "invalid frame: no progress\n"), 1;
        at += (long)in;
    }
    if (status != 0) return fprintf(stderr, "invalid frame: ends in the middle\n"), 1;
    LZ4F_freeDecompressionContext(z);
    free(data);
    free(out);
    return 0;
}
