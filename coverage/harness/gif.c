/* Reads a GIF with giflib: the whole file, every frame. Exit 0: it did. 1: giflib said no. */
#include <gif_lib.h>
#include <stdio.h>

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    int error = 0;
    GifFileType *gif = DGifOpenFileName(argv[1], &error);
    if (!gif) {
        fprintf(stderr, "invalid GIF: %s\n", GifErrorString(error));
        return 1;
    }
    if ((unsigned long long)gif->SWidth * gif->SHeight > (1ULL << 26)) {
        fprintf(stderr, "image too large for this reader\n");
        DGifCloseFile(gif, &error);
        return 1;
    }
    if (DGifSlurp(gif) != GIF_OK) {
        fprintf(stderr, "invalid GIF: %s\n", GifErrorString(gif->Error));
        DGifCloseFile(gif, &error);
        return 1;
    }
    DGifCloseFile(gif, &error);
    return 0;
}
