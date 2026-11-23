"""Ask the Python package python-snappy about a file: exit 0 if it decodes it as a stream of the Snappy framing format,
else say why and exit 1.

The framing is python-snappy's, the blocks are Google's Snappy library. Every chunk's CRC-32C is checked. Whatever it
raises is a rejection.
"""

import sys

import snappy

BLOCK = 1 << 20  # read a piece at a time, so that data that is huge once decompressed costs little memory

try:
    stream = snappy.StreamDecompressor()
    with open(sys.argv[1], "rb") as data:
        while piece := data.read(BLOCK):
            stream.decompress(piece)
    stream.flush()
except Exception as exc:  # whatever snappy raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
