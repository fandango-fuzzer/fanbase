/* Reads an XML document with Expat, as xmlwf does by default: well-formedness, no namespace processing, no external
   entities. Exit 0: the document is well-formed. 1: Expat said no. */
#include <expat.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    XML_Parser parser = XML_ParserCreate(NULL);
    if (!parser) return 2;
    char buffer[65536];
    int status = 0;
    for (;;) {
        size_t got = fread(buffer, 1, sizeof buffer, file);
        int last = got < sizeof buffer;
        if (XML_Parse(parser, buffer, (int)got, last) == XML_STATUS_ERROR) {
            fprintf(stderr, "invalid XML: %s\n", XML_ErrorString(XML_GetErrorCode(parser)));
            status = 1;
            break;
        }
        if (last) break;
    }
    XML_ParserFree(parser);
    fclose(file);
    return status;
}
