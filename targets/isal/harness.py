"""Ask ISA-L about a file: exit 0 if it reads it to its end as gzip (a .gz file) or as one zlib stream (a .zlib file), else
say why and exit 1.

ISA-L is Intel's implementation of DEFLATE, apart from zlib's, called through the Python package isal (python-isal).
Whatever it raises is a rejection; a zlib stream must end where the file ends.
"""

import sys

import os

from isal import igzip, isal_zlib

BLOCK = 1 << 20  # read a piece at a time, so that data that is huge once decompressed costs little memory

try:
    if os.path.splitext(sys.argv[1])[1].lower() == ".gz":
        with igzip.open(sys.argv[1], "rb") as data:
            while data.read(BLOCK):
                pass
    else:
        inflate = isal_zlib.decompressobj()
        with open(sys.argv[1], "rb") as data:
            inflate.decompress(data.read())
        inflate.flush()
        if not inflate.eof:
            raise EOFError("the stream does not end")
        if inflate.unused_data:
            raise ValueError(f"data after the stream ({len(inflate.unused_data)} bytes)")
except Exception as exc:  # whatever isal raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
