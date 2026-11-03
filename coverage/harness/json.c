/* Reads a JSON text with json-c, strictly (RFC 8259, UTF-8 checked): one value, and only white space after it.
   Exit 0: json-c took it. 1: it said no. */
#include <json-c/json.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_BYTES (64L * 1024 * 1024)

int main(int argc, char **argv) {
    if (argc != 2) return 2;
    FILE *file = fopen(argv[1], "rb");
    if (!file) return 2;
    char *text = malloc(MAX_BYTES);
    if (!text) return 2;
    size_t length = fread(text, 1, MAX_BYTES, file);
    fclose(file);

    struct json_tokener *tokener = json_tokener_new_ex(JSON_TOKENER_DEFAULT_DEPTH);
    if (!tokener) return 2;
    json_tokener_set_flags(tokener, JSON_TOKENER_STRICT | JSON_TOKENER_VALIDATE_UTF8);
    struct json_object *value = json_tokener_parse_ex(tokener, text, (int)length);
    enum json_tokener_error error = json_tokener_get_error(tokener);
    int status = 0;
    size_t end = json_tokener_get_parse_end(tokener);
    if (error == json_tokener_continue) {  /* the text ended inside a value: a number at the very end needs a last byte */
        value = json_tokener_parse_ex(tokener, "", 1);
        error = json_tokener_get_error(tokener);
        end = length;  /* all of the text was read */
    }
    if (error != json_tokener_success) {  /* a value of null is no object, and a success */
        fprintf(stderr, "invalid JSON: %s\n", json_tokener_error_desc(error));
        status = 1;
    } else {
        for (size_t at = end; at < length; at++) {
            if (!strchr(" \t\r\n", text[at])) {
                fprintf(stderr, "invalid JSON: something after the value\n");
                status = 1;
                break;
            }
        }
    }
    json_object_put(value);
    json_tokener_free(tokener);
    free(text);
    return status;
}
