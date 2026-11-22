/* Reads a stream of the Snappy framing format: the stream identifier first, then chunks; a compressed one (0x00) is
   decoded with the Snappy library (snappy_uncompress, through its C interface), and the masked CRC-32C of every data
   chunk is checked; padding (0xfe) and the reserved skippable chunks (0x80 to 0xfd) are skipped, and a reserved
   unskippable one (0x02 to 0x7f) refused. The framing is read here: only the library's decoding is counted. Exit 0: it
   took the stream. 1: it did not. */
#include <snappy-c.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BYTES (64L * 1024 * 1024)

static uint32_t crc32c(const uint8_t *p, size_t n) {
    uint32_t crc = 0xFFFFFFFF;
    while (n--) {
        crc ^= *p++;
        for (int k = 0; k < 8; k++) crc = (crc >> 1) ^ (0x82F63B78 & -(crc & 1));
    }
    return ~crc;
}

static uint32_t masked(const uint8_t *p, size_t n) {
    uint32_t c = crc32c(p, n);
    return ((c >> 15) | (c << 17)) + 0xa282ead8;
}

static int no(const char *why) { fprintf(stderr, "invalid stream: %s\n", why); return 1; }

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    uint8_t *data = malloc(MAX_BYTES), *out = malloc(65536);
    if (!data || !out) return 2;
    size_t length = fread(data, 1, MAX_BYTES, file);
    fclose(file);

    size_t at = 0;
    int first = 1;
    while (at < length) {
        if (length - at < 4) return no("a chunk header ends in the middle");
        uint8_t type = data[at];
        size_t size = data[at + 1] | data[at + 2] << 8 | (size_t)data[at + 3] << 16;
        const uint8_t *body = data + at + 4;
        if (at + 4 + size > length) return no("a chunk ends in the middle");
        if (first && type != 0xff) return no("no stream identifier");
        first = 0;
        if (type == 0xff) {
            if (size != 6 || memcmp(body, "sNaPpY", 6)) return no("bad stream identifier");
        } else if (type == 0x00 || type == 0x01) {
            if (size < 4) return no("a data chunk without a CRC");
            uint32_t crc = body[0] | body[1] << 8 | body[2] << 16 | (uint32_t)body[3] << 24;
            const uint8_t *plain = body + 4;
            size_t plain_length = size - 4;
            if (type == 0x00) {
                size_t n;
                if (snappy_uncompressed_length((const char *)body + 4, size - 4, &n) != SNAPPY_OK || n > 65536)
                    return no("bad compressed length");
                if (snappy_uncompress((const char *)body + 4, size - 4, (char *)out, &n) != SNAPPY_OK)
                    return no("bad compressed block");
                plain = out;
                plain_length = n;
            } else if (plain_length > 65536) {
                return no("uncompressed chunk too long");
            }
            if (masked(plain, plain_length) != crc) return no("bad CRC");
        } else if (type <= 0x7f) {
            return no("reserved unskippable chunk");
        }
        at += 4 + size;
    }
    if (first) return no("empty");
    free(data);
    free(out);
    return 0;
}
