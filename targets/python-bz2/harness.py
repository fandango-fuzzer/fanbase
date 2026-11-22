"""Ask Python's bz2 about a file: exit 0 if it reads every stream of it to its end, else say why and exit 1.

bz2 is libbzip2 underneath; reading to the end is what checks the CRCs. Whatever it raises is a rejection.
"""

import sys

import bz2

BLOCK = 1 << 20  # read a piece at a time, so that data that is huge once decompressed costs little memory

try:
    with bz2.open(sys.argv[1], "rb") as data:
        while data.read(BLOCK):
            pass
except Exception as exc:  # whatever bz2 raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
