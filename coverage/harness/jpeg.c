/* Reads a JPEG with libjpeg(-turbo): the header, then every scanline. Exit 0: it did. 1: the library said no. */
#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <jpeglib.h>

struct failure { struct jpeg_error_mgr pub; jmp_buf back; };

static void give_up(j_common_ptr cinfo) {
    struct failure *err = (struct failure *)cinfo->err;
    char message[JMSG_LENGTH_MAX];
    (*cinfo->err->format_message)(cinfo, message);
    fprintf(stderr, "invalid JPEG: %s\n", message);
    longjmp(err->back, 1);
}

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    struct jpeg_decompress_struct cinfo;
    struct failure err;
    cinfo.err = jpeg_std_error(&err.pub);
    err.pub.error_exit = give_up;
    unsigned char *row = NULL;
    if (setjmp(err.back)) {
        jpeg_destroy_decompress(&cinfo);
        free(row);
        fclose(file);
        return 1;
    }
    jpeg_create_decompress(&cinfo);
    jpeg_stdio_src(&cinfo, file);
    jpeg_read_header(&cinfo, TRUE);
    if ((unsigned long long)cinfo.image_width * cinfo.image_height > (1ULL << 26)) {
        fprintf(stderr, "image too large for this reader\n");
        jpeg_destroy_decompress(&cinfo);
        fclose(file);
        return 1;
    }
    jpeg_start_decompress(&cinfo);
    row = malloc((size_t)cinfo.output_width * cinfo.output_components);
    while (cinfo.output_scanline < cinfo.output_height) {
        JSAMPROW rows[1] = { row };
        jpeg_read_scanlines(&cinfo, rows, 1);
    }
    jpeg_finish_decompress(&cinfo);
    jpeg_destroy_decompress(&cinfo);
    free(row);
    fclose(file);
    return 0;
}
