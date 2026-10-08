/* Reads a BMP with stb_image, which is compiled here for BMP only. Exit 0: it did. 1: stb_image said no. */
#include <stdio.h>
#define STBI_ONLY_BMP
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    int width, height, channels;
    if (!stbi_info(argv[1], &width, &height, &channels)) {
        fprintf(stderr, "invalid BMP: %s\n", stbi_failure_reason());
        return 1;
    }
    if ((unsigned long long)width * height > (1ULL << 26)) {
        fprintf(stderr, "image too large for this reader\n");
        return 1;
    }
    unsigned char *pixels = stbi_load(argv[1], &width, &height, &channels, 0);
    if (!pixels) {
        fprintf(stderr, "invalid BMP: %s\n", stbi_failure_reason());
        return 1;
    }
    stbi_image_free(pixels);
    return 0;
}
