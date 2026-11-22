"""Ask the Python package zstandard about a file: exit 0 if it reads every frame of it to its end, else say why and exit
1.

zstandard is libzstd underneath. A frame that needs a dictionary, or a window over 128 MiB, is refused. Whatever it
raises is a rejection.
"""

import sys

import zstandard

BLOCK = 1 << 20  # read a piece at a time, so that data that is huge once decompressed costs little memory

try:
    with open(sys.argv[1], "rb") as raw, zstandard.ZstdDecompressor().stream_reader(raw, read_across_frames=True) as data:
        while data.read(BLOCK):
            pass
except Exception as exc:  # whatever zstandard raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
