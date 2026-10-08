/* Reads a WebP with libwebp: a still image decoded, an animation frame by frame. Exit 0: it did. 1: libwebp said no. */
#include <stdio.h>
#include <stdlib.h>
#include <webp/decode.h>
#include <webp/demux.h>

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

    WebPBitstreamFeatures features;
    if (WebPGetFeatures(data, (size_t)size, &features) != VP8_STATUS_OK) {
        fprintf(stderr, "invalid WebP: no features\n");
        free(data);
        return 1;
    }
    if ((unsigned long long)features.width * features.height > (1ULL << 26)) {
        fprintf(stderr, "image too large for this reader\n");
        free(data);
        return 1;
    }
    int status = 0;
    if (features.has_animation) {
        WebPData webp = { data, (size_t)size };
        WebPAnimDecoderOptions options;
        WebPAnimDecoderOptionsInit(&options);
        WebPAnimDecoder *decoder = WebPAnimDecoderNew(&webp, &options);
        if (!decoder) {
            fprintf(stderr, "invalid WebP: animation\n");
            status = 1;
        } else {
            uint8_t *frame;
            int timestamp;
            while (WebPAnimDecoderHasMoreFrames(decoder)) {
                if (!WebPAnimDecoderGetNext(decoder, &frame, &timestamp)) { status = 1; break; }
            }
            WebPAnimDecoderDelete(decoder);
        }
    } else {
        int width, height;
        uint8_t *pixels = WebPDecodeRGBA(data, (size_t)size, &width, &height);
        if (!pixels) {
            fprintf(stderr, "invalid WebP: decoding failed\n");
            status = 1;
        }
        WebPFree(pixels);
    }
    free(data);
    return status;
}
