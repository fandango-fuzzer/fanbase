"""Ask Python's zlib about a file: exit 0 if it is one whole zlib stream, else say why and exit 1.

The stream must end (its Adler-32 checked) where the file ends: data after it is a rejection, as is a stream that needs a
preset dictionary, which the file does not come with. Whatever zlib raises is a rejection.
"""

import sys

import zlib

BLOCK = 1 << 20  # read a piece at a time, so that data that is huge once decompressed costs little memory

try:
    inflate = zlib.decompressobj()
    with open(sys.argv[1], "rb") as data:
        while piece := data.read(BLOCK):
            inflate.decompress(piece, BLOCK)
            while inflate.unconsumed_tail:
                inflate.decompress(inflate.unconsumed_tail, BLOCK)
    inflate.flush()
    if not inflate.eof:
        raise EOFError("the stream does not end")
    if inflate.unused_data:
        raise ValueError(f"data after the stream ({len(inflate.unused_data)} bytes)")
except Exception as exc:  # whatever zlib raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
