/* Reads a QOI image with the reference decoder (qoi.h), which is compiled here. Exit 0: it did. 1: qoi.h said no. */
#include <stdio.h>
#include <stdlib.h>
#define QOI_IMPLEMENTATION
#include "qoi.h"

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    qoi_desc desc;
    void *pixels = qoi_read(argv[1], &desc, 0);
    if (!pixels) {
        fprintf(stderr, "invalid QOI: qoi_read said no\n");
        return 1;
    }
    free(pixels);
    return 0;
}
