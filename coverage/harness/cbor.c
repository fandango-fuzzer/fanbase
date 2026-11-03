/* Reads a CBOR data item with libcbor (cbor_load): the whole file must be one well-formed item. Exit 0: libcbor took
   it. 1: it said no. */
#include <cbor.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_BYTES (64L * 1024 * 1024)

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    unsigned char *data = malloc(MAX_BYTES);
    if (!data) return 2;
    size_t length = fread(data, 1, MAX_BYTES, file);
    fclose(file);

    struct cbor_load_result result;
    cbor_item_t *item = cbor_load(data, length, &result);
    int status = 0;
    if (!item || result.error.code != CBOR_ERR_NONE) {
        static const char *why[] = {"none", "not enough data", "no data", "malformed", "out of memory", "syntax error"};
        int code = result.error.code;
        fprintf(stderr, "invalid CBOR: %s\n", code >= 0 && code < 6 ? why[code] : "error");
        status = 1;
    } else if (result.read != length) {
        fprintf(stderr, "invalid CBOR: data after the item\n");
        status = 1;
    }
    if (item) cbor_decref(&item);
    free(data);
    return status;
}
