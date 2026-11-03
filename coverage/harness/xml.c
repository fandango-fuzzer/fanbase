/* Reads an XML document with libxml2, as xmllint does by default: well-formedness, namespaces included, without the
   network and without substituting entities. Exit 0: the document is well-formed. 1: libxml2 said no. */
#include <libxml/parser.h>
#include <stdio.h>

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    xmlParserCtxtPtr context = xmlNewParserCtxt();
    if (!context) return 2;
    xmlDocPtr doc = xmlCtxtReadFile(context, argv[1], NULL, XML_PARSE_NONET | XML_PARSE_NOERROR | XML_PARSE_NOWARNING);
    int ok = doc != NULL && !(xmlCtxtGetStatus(context) & (XML_STATUS_NOT_WELL_FORMED | XML_STATUS_NOT_NS_WELL_FORMED));
    if (!ok) {
        const xmlError *error = xmlCtxtGetLastError(context);
        fprintf(stderr, "invalid XML: %s", error && error->message ? error->message : "not well-formed\n");
    }
    xmlFreeDoc(doc);
    xmlFreeParserCtxt(context);
    return ok ? 0 : 1;
}
