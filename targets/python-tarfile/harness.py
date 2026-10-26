"""Ask Python's tarfile about a file: exit 0 if it reads every member of it, else say why and exit 1.

The file is read as a tar archive with nothing around it (mode "r:"), as an application that is given a .tar file would.
Whatever tarfile raises is a rejection. tarfile stops quietly at a header it cannot read after the first one: that is
how it reads archives, and it is left so.
"""

import sys
import tarfile

BLOCK = 1 << 20  # read a member a piece at a time, so that a member that says it is huge costs nothing up front

try:
    with tarfile.open(sys.argv[1], "r:") as archive:
        for member in archive:
            if member.isfile():
                content = archive.extractfile(member)
                while content.read(BLOCK):
                    pass
except Exception as exc:  # whatever tarfile raises is a rejection
    print(f"{type(exc).__name__}: {exc}", file=sys.stderr)
    sys.exit(1)
