"""Ask Python's lzma about a file: exit 0 if it reads every .xz stream of it to its end, else say why and exit 1.

lzma is liblzma underneath, and is told that the file is .xz (not .lzma, or raw). Reading to the end is what checks every
block. Whatever it raises is a rejection.
"""

import sys

import lzma

BLOCK = 1 << 20  # read a piece at a time, so that data that is huge once decompressed costs little memory

try:
    with lzma.open(sys.argv[1], "rb", format=lzma.FORMAT_XZ) as data:
        while data.read(BLOCK):
            pass
except Exception as exc:  # whatever lzma raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
