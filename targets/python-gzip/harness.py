"""Ask Python's gzip about a file: exit 0 if it reads every member of it to its end, else say why and exit 1.

Reading to the end is what checks the CRC-32 and the size of every member. Whatever gzip raises is a rejection.
"""

import sys

import gzip

BLOCK = 1 << 20  # read a piece at a time, so that data that is huge once decompressed costs little memory

try:
    with gzip.open(sys.argv[1], "rb") as data:
        while data.read(BLOCK):
            pass
except Exception as exc:  # whatever gzip raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
