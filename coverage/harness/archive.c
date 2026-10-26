/* Reads an archive with libarchive, as a program that unpacks it would: every entry's header, then its contents to the
   end, which is when the checksums of the formats that have them are checked. Only the reader of the format named on
   the command line is enabled, so that a file is read as that format or not at all. Exit 0: it did. 1: libarchive said
   no. usage: archive-harness FORMAT FILE */
#include <archive.h>
#include <archive_entry.h>
#include <stdio.h>
#include <string.h>

#define MAX_ENTRIES 10000
#define MAX_BYTES (256L * 1024 * 1024) /* what an entry may unpack to before the rest is skipped, as a program with a limit would */

static int enable(struct archive *archive, const char *format) {
    if (!strcmp(format, "7z")) return archive_read_support_format_7zip(archive);
    if (!strcmp(format, "ar")) return archive_read_support_format_ar(archive);
    if (!strcmp(format, "cab")) return archive_read_support_format_cab(archive);
    if (!strcmp(format, "cpio")) return archive_read_support_format_cpio(archive);
    if (!strcmp(format, "rar")) {
        int status = archive_read_support_format_rar(archive);
        return status == ARCHIVE_OK ? archive_read_support_format_rar5(archive) : status;
    }
    if (!strcmp(format, "tar")) return archive_read_support_format_tar(archive);
    if (!strcmp(format, "zip")) return archive_read_support_format_zip(archive);
    return ARCHIVE_FATAL;
}

static int fail(struct archive *archive, const char *what) {
    const char *message = archive_error_string(archive);
    fprintf(stderr, "invalid archive: %s: %s\n", what, message ? message : "no reason given");
    archive_read_free(archive);
    return 1;
}

int main(int argc, char **argv) {
    if (argc != 3) return 2;
    struct archive *archive = archive_read_new();
    if (!archive || enable(archive, argv[1]) != ARCHIVE_OK) return 2;
    if (archive_read_open_filename(archive, argv[2], 65536) != ARCHIVE_OK) return fail(archive, "open");

    static char buffer[65536];
    struct archive_entry *entry;
    int status;
    long entries = 0;
    while ((status = archive_read_next_header(archive, &entry)) == ARCHIVE_OK || status == ARCHIVE_WARN) {
        if (++entries > MAX_ENTRIES) break;
        long unpacked = 0;
        la_ssize_t got;
        while ((got = archive_read_data(archive, buffer, sizeof buffer)) > 0) {
            if ((unpacked += got) > MAX_BYTES) break;
        }
        if (got < 0 && got != ARCHIVE_WARN) return fail(archive, "contents");
    }
    if (status != ARCHIVE_EOF && entries <= MAX_ENTRIES) return fail(archive, "header");
    archive_read_free(archive);
    return 0;
}
