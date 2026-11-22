"""Ask the Python package lz4 about a file: exit 0 if its frame API reads every frame of it to its end, else say why and
exit 1.

It reads LZ4 frames only: a legacy frame (magic 0x184C2102), or a file of skippable frames alone, is something it does
not do (unsupported). Whatever it raises is a rejection.
"""

import sys

import lz4.frame

BLOCK = 1 << 20  # read a piece at a time, so that data that is huge once decompressed costs little memory

try:
    with lz4.frame.open(sys.argv[1], "rb") as data:
        while data.read(BLOCK):
            pass
except Exception as exc:  # whatever lz4 raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
