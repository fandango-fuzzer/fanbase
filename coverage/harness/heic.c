/* Reads a HEIC/HEIF with libheif, as an application would: the file, then every top-level image decoded to RGB.
   Exit 0: it did. 1: libheif said no. */
#include <libheif/heif.h>
#include <stdio.h>

#define MAX_IMAGES 16

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    struct heif_context *context = heif_context_alloc();
    if (!context) return 2;
    heif_context_set_maximum_image_size_limit(context, 16384);

    struct heif_error error = heif_context_read_from_file(context, argv[1], NULL);
    if (error.code != heif_error_Ok) {
        fprintf(stderr, "invalid HEIF: %s\n", error.message);
        heif_context_free(context);
        return 1;
    }
    int count = heif_context_get_number_of_top_level_images(context);
    if (count <= 0) {
        fprintf(stderr, "invalid HEIF: no image\n");
        heif_context_free(context);
        return 1;
    }
    if (count > MAX_IMAGES) count = MAX_IMAGES;
    heif_item_id ids[MAX_IMAGES];
    count = heif_context_get_list_of_top_level_image_IDs(context, ids, count);

    int status = 0;
    for (int i = 0; i < count && status == 0; i++) {
        struct heif_image_handle *handle = NULL;
        error = heif_context_get_image_handle(context, ids[i], &handle);
        if (error.code != heif_error_Ok) {
            fprintf(stderr, "invalid HEIF: %s\n", error.message);
            status = 1;
            break;
        }
        if ((long long)heif_image_handle_get_width(handle) * heif_image_handle_get_height(handle) > (1LL << 26)) {
            fprintf(stderr, "image too large for this reader\n");
            status = 1;
        } else {
            struct heif_image *image = NULL;
            error = heif_decode_image(handle, &image, heif_colorspace_RGB, heif_chroma_interleaved_RGB, NULL);
            if (error.code != heif_error_Ok) {
                fprintf(stderr, "invalid HEIF: %s\n", error.message);
                status = 1;
            }
            heif_image_release(image);
        }
        heif_image_handle_release(handle);
    }
    heif_context_free(context);
    return status;
}
