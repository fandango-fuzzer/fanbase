/* Reads a TIFF with libtiff: every directory, as an RGBA image. Exit 0: it did. 1: libtiff said no. */
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <tiffio.h>

static int failed = 0;

static void complain(const char *module, const char *format, va_list args) {
    failed = 1;
    fprintf(stderr, "invalid TIFF: %s: ", module ? module : "libtiff");
    vfprintf(stderr, format, args);
    fprintf(stderr, "\n");
}

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    TIFFSetErrorHandler(complain);
    TIFFSetWarningHandler(NULL);
    TIFF *tiff = TIFFOpen(argv[1], "r");
    if (!tiff) return 1;
    int directories = 0;
    do {
        uint32_t width = 0, height = 0;
        TIFFGetField(tiff, TIFFTAG_IMAGEWIDTH, &width);
        TIFFGetField(tiff, TIFFTAG_IMAGELENGTH, &height);
        if ((unsigned long long)width * height > (1ULL << 24)) {
            fprintf(stderr, "image too large for this reader\n");
            failed = 1;
            break;
        }
        char reason[1024];
        TIFFRGBAImage image;
        if (TIFFRGBAImageBegin(&image, tiff, 0, reason)) {
            uint32_t *pixels = malloc((size_t)width * height * sizeof(uint32_t));
            if (pixels) {
                if (!TIFFRGBAImageGet(&image, pixels, width, height)) failed = 1;
                free(pixels);
            }
            TIFFRGBAImageEnd(&image);
        } else {
            fprintf(stderr, "invalid TIFF: %s\n", reason);
            failed = 1;
        }
    } while (++directories < 64 && TIFFReadDirectory(tiff));
    TIFFClose(tiff);
    return failed;
}
