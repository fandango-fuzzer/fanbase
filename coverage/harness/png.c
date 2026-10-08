/* Reads a PNG with libpng, as an application would: all of it, with the usual conversions. Exit 0: it did. 1: libpng said no. */
#include <png.h>
#include <setjmp.h>
#include <stdio.h>

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    png_structp png = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    png_infop info = png ? png_create_info_struct(png) : NULL;
    if (!png || !info) return 2;
    if (setjmp(png_jmpbuf(png))) {
        png_destroy_read_struct(&png, &info, NULL);
        fclose(file);
        fprintf(stderr, "invalid PNG: libpng gave up\n");
        return 1;
    }
    png_init_io(png, file);
    png_set_user_limits(png, 16384, 16384); /* a file that asks for more is refused, as an application may */
    png_set_chunk_malloc_max(png, 16 * 1024 * 1024);
    png_read_png(png, info, PNG_TRANSFORM_EXPAND | PNG_TRANSFORM_STRIP_16 | PNG_TRANSFORM_PACKING, NULL);
    png_destroy_read_struct(&png, &info, NULL);
    fclose(file);
    return 0;
}
