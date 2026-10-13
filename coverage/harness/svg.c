/* Reads an SVG with NanoSVG, as an application would: the whole document, taken as an image with a size. NanoSVG is
   lenient (a text that is no SVG gives an empty image), so a document that has no size is what it says no to.
   Exit 0: it did. 1: NanoSVG said no. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#define NANOSVG_IMPLEMENTATION
#include "nanosvg.h"

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    fseek(file, 0, SEEK_END);
    long size = ftell(file);
    fclose(file);
    if (size <= 0 || size > (64L << 20)) return 1;

    NSVGimage *image = nsvgParseFromFile(argv[1], "px", 96.0f);
    if (!image) {
        fprintf(stderr, "invalid SVG: could not be read\n");
        return 1;
    }
    int status = 0;
    if (!(image->width > 0.0f) || !(image->height > 0.0f)) {
        fprintf(stderr, "invalid SVG: no size\n");
        status = 1;
    } else if ((double)image->width * image->height > (double)(1 << 26)) {
        fprintf(stderr, "image too large for this reader\n");
        status = 1;
    }
    nsvgDelete(image);
    return status;
}
