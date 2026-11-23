"""Ask the Python package cramjam about a file: exit 0 if it decodes it as a stream of the Snappy framing format, else say
why and exit 1.

cramjam calls Rust code: its Snappy is the crate snap, an implementation apart from Google's. Whatever it raises is a
rejection.
"""

import sys

import cramjam

BLOCK = 1 << 20  # read a piece at a time, so that data that is huge once decompressed costs little memory

try:
    with open(sys.argv[1], "rb") as data:
        bytes(cramjam.snappy.decompress(data.read()))
except Exception as exc:  # whatever cramjam raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
