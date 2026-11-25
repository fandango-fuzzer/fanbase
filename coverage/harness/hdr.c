/* Reads a Radiance HDR image with stb_image, which is compiled here for HDR only. Exit 0: it did. 1: stb_image said no. */
#include <stdio.h>
#define STBI_ONLY_HDR
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    int width, height, channels;
    if (!stbi_info(argv[1], &width, &height, &channels)) {
        fprintf(stderr, "invalid HDR: %s\n", stbi_failure_reason());
        return 1;
    }
    if ((unsigned long long)width * height > (1ULL << 26)) {
        fprintf(stderr, "image too large for this reader\n");
        return 1;
    }
    float *pixels = stbi_loadf(argv[1], &width, &height, &channels, 0);
    if (!pixels) {
        fprintf(stderr, "invalid HDR: %s\n", stbi_failure_reason());
        return 1;
    }
    stbi_image_free(pixels);
    return 0;
}
