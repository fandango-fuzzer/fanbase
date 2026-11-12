/* Reads a font with FreeType: every face in the file is opened, set to 16 pixels (or, if it has only bitmaps, to its
   first size), and every glyph of it is loaded, hinted and rendered. Exit 0: FreeType took all of it. 1: it said no. */
#include <ft2build.h>
#include FT_FREETYPE_H
#include <stdio.h>

static int refuse(const char *doing, FT_Error error) {
    const char *why = FT_Error_String(error);
    if (why)
        fprintf(stderr, "%s: %s\n", doing, why);
    else
        fprintf(stderr, "%s: error 0x%02x\n", doing, error);
    return 1;
}

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FT_Library library;
    if (FT_Init_FreeType(&library)) return 2;
    int status = 0;
    FT_Long faces = 1;
    for (FT_Long index = 0; index < faces && !status; index++) {
        FT_Face face;
        FT_Error error = FT_New_Face(library, argv[1], index, &face);
        if (error) {
            status = refuse("opening", error);
            break;
        }
        faces = face->num_faces;
        if (FT_IS_SCALABLE(face))
            error = FT_Set_Char_Size(face, 0, 16 * 64, 72, 72);
        else if (face->num_fixed_sizes > 0)
            error = FT_Select_Size(face, 0);
        if (error)
            status = refuse("sizing", error);
        for (FT_Long glyph = 0; glyph < face->num_glyphs && !status; glyph++) {
            error = FT_Load_Glyph(face, (FT_UInt)glyph, FT_LOAD_RENDER);
            if (error) status = refuse("loading a glyph", error);
        }
        FT_Done_Face(face);
    }
    FT_Done_FreeType(library);
    return status;
}
