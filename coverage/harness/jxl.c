/* Reads a JPEG XL with libjxl, as an application would: the whole file, every frame decoded to 8-bit RGBA.
   Exit 0: it did. 1: libjxl said no. */
#include <jxl/decode.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define MAX_FRAMES 1000

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    fseek(file, 0, SEEK_END);
    long size = ftell(file);
    fseek(file, 0, SEEK_SET);
    if (size <= 0 || size > (64L << 20)) { fclose(file); return 1; }
    uint8_t *data = malloc((size_t)size);
    if (!data || fread(data, 1, (size_t)size, file) != (size_t)size) { fclose(file); free(data); return 2; }
    fclose(file);

    JxlDecoder *decoder = JxlDecoderCreate(NULL);
    if (!decoder) { free(data); return 2; }
    if (JxlDecoderSubscribeEvents(decoder, JXL_DEC_BASIC_INFO | JXL_DEC_COLOR_ENCODING | JXL_DEC_PREVIEW_IMAGE |
                                           JXL_DEC_FRAME | JXL_DEC_FULL_IMAGE | JXL_DEC_BOX) != JXL_DEC_SUCCESS) {
        JxlDecoderDestroy(decoder);
        free(data);
        return 2;
    }
    JxlDecoderSetInput(decoder, data, (size_t)size);
    JxlDecoderCloseInput(decoder);

    JxlPixelFormat format = {4, JXL_TYPE_UINT8, JXL_NATIVE_ENDIAN, 0};
    void *pixels = NULL;
    int frames = 0, status = 0;
    for (;;) {
        JxlDecoderStatus event = JxlDecoderProcessInput(decoder);
        if (event == JXL_DEC_SUCCESS) break;
        if (event == JXL_DEC_ERROR || event == JXL_DEC_NEED_MORE_INPUT) {
            fprintf(stderr, "invalid JPEG XL: %s\n", event == JXL_DEC_ERROR ? "libjxl gave up" : "truncated");
            status = 1;
            break;
        }
        if (event == JXL_DEC_BASIC_INFO) {
            JxlBasicInfo info;
            if (JxlDecoderGetBasicInfo(decoder, &info) != JXL_DEC_SUCCESS) { status = 1; break; }
            if ((unsigned long long)info.xsize * info.ysize > (1ULL << 26)) {
                fprintf(stderr, "image too large for this reader\n");
                status = 1;
                break;
            }
        } else if (event == JXL_DEC_NEED_PREVIEW_OUT_BUFFER || event == JXL_DEC_NEED_IMAGE_OUT_BUFFER) {
            size_t bytes = 0;
            JxlDecoderStatus got = event == JXL_DEC_NEED_PREVIEW_OUT_BUFFER
                                       ? JxlDecoderPreviewOutBufferSize(decoder, &format, &bytes)
                                       : JxlDecoderImageOutBufferSize(decoder, &format, &bytes);
            if (got != JXL_DEC_SUCCESS || bytes > (1UL << 29)) {
                fprintf(stderr, "image too large for this reader\n");
                status = 1;
                break;
            }
            free(pixels);
            pixels = malloc(bytes ? bytes : 1);
            if (!pixels) { status = 2; break; }
            got = event == JXL_DEC_NEED_PREVIEW_OUT_BUFFER
                      ? JxlDecoderSetPreviewOutBuffer(decoder, &format, pixels, bytes)
                      : JxlDecoderSetImageOutBuffer(decoder, &format, pixels, bytes);
            if (got != JXL_DEC_SUCCESS) { status = 1; break; }
        } else if (event == JXL_DEC_FULL_IMAGE) {
            if (++frames >= MAX_FRAMES) break;
        }
    }
    free(pixels);
    JxlDecoderDestroy(decoder);
    free(data);
    return status;
}
