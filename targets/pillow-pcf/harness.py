"""Ask Pillow about a PCF font: exit 0 if PcfFontFile reads it and compiles it into a font Pillow can draw with, else
say why and exit 1.

Pillow's PCF reader is its own (not FreeType): it reads the properties, the metrics, the bitmaps and the encodings.
Whatever it raises is a rejection; its "decompression bomb" error is a limit it sets on itself.
"""

import sys

from PIL import PcfFontFile

try:
    with open(sys.argv[1], "rb") as data:
        PcfFontFile.PcfFontFile(data).compile()
except Exception as exc:  # whatever Pillow raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
