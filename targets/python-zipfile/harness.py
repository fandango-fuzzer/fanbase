"""Ask Python's zipfile about a file: exit 0 if it reads every member of it, else say why and exit 1.

Reading a member to its end is what checks its CRC-32. Whatever zipfile raises is a rejection: it says what it did not
like with an exception, and which one is part of the reason.
"""

import sys
import zipfile

BLOCK = 1 << 20  # read a member a piece at a time, so that a member that says it is huge costs nothing up front

try:
    with zipfile.ZipFile(sys.argv[1]) as archive:
        for member in archive.infolist():
            with archive.open(member) as content:
                while content.read(BLOCK):
                    pass
except Exception as exc:  # whatever zipfile raises is a rejection
    print(f"{type(exc).__name__}: {exc}", file=sys.stderr)
    sys.exit(1)
