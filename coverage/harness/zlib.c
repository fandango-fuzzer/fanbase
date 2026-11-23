/* Inflates a file with zlib: one zlib stream (RFC 1950) that ends where the file ends, or (with "gz") the members of a
   gzip file (RFC 1952), one after the other, as gzip reads them; zero bytes after the last member are skipped, as gzip
   does, and anything else after it is refused. Exit 0: zlib took it. 1: it said no. usage: zlib-harness zlib|gz FILE */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

#define MAX_BYTES (64L * 1024 * 1024)

static int fail(const char *what, z_stream *z) {
    fprintf(stderr, "invalid stream: %s%s%s\n", what, z->msg ? ": " : "", z->msg ? z->msg : "");
    inflateEnd(z);
    return 1;
}

int main(int argc, char **argv) {
    if (argc != 3) return 2;
    int gz = !strcmp(argv[1], "gz");
    FILE *file = fopen(argv[2], "rb");
    if (!file) return 2;
    unsigned char *data = malloc(MAX_BYTES), *out = malloc(1 << 16);
    if (!data || !out) return 2;
    size_t length = fread(data, 1, MAX_BYTES, file);
    fclose(file);

    z_stream z;
    memset(&z, 0, sizeof z);
    if (inflateInit2(&z, gz ? 15 + 16 : 15) != Z_OK) return 2;
    z.next_in = data;
    z.avail_in = (uInt)length;
    for (;;) {
        z.next_out = out;
        z.avail_out = 1 << 16;
        int status = inflate(&z, Z_NO_FLUSH);
        if (status == Z_STREAM_END) {
            if (z.avail_in == 0) break;
            if (!gz) return fail("data after the stream", &z);
            if (z.avail_in >= 2 && z.next_in[0] == 0x1f && z.next_in[1] == 0x8b) {
                inflateReset(&z);
                continue;
            }
            for (uInt i = 0; i < z.avail_in; i++)
                if (z.next_in[i]) return fail("data after the last member", &z);
            break;
        }
        if (status == Z_NEED_DICT) return fail("needs a preset dictionary", &z);
        if (status != Z_OK) return fail(status == Z_DATA_ERROR ? "data error" : "error", &z);
        if (z.avail_in == 0 && z.avail_out != 0) return fail("ends in the middle", &z);
    }
    inflateEnd(&z);
    free(data);
    free(out);
    return 0;
}
