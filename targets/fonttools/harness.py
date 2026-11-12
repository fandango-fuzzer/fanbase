"""Ask fontTools about a font: exit 0 if it decompiles every table of it and reads every glyph's outline, else say why
and exit 1.

TTFont reads TrueType and OpenType fonts, and WOFF and WOFF2 (with the brotli package) too; a collection (ttcf) is read
font by font. TrueType outlines are read with getCoordinates, which places the components of a composite glyph by
their offsets or by matching points; CFF outlines are drawn. Whatever it raises is a rejection.
"""

import sys

from fontTools.pens.basePen import NullPen
from fontTools.ttLib import TTCollection, TTFont

try:
    with open(sys.argv[1], "rb") as data:
        head = data.read(4)
    fonts = TTCollection(sys.argv[1], lazy=False).fonts if head == b"ttcf" else [TTFont(sys.argv[1], lazy=False)]
    for font in fonts:
        font.ensureDecompiled()
        if "glyf" in font:
            glyf = font["glyf"]
            for name in font.getGlyphOrder():
                glyf[name].getCoordinates(glyf)
        elif "CFF " in font or "CFF2" in font:
            glyphs = font.getGlyphSet()
            for name in font.getGlyphOrder():
                glyphs[name].draw(NullPen())
except Exception as exc:  # whatever fontTools raises is a rejection
    print(f"{type(exc).__name__}: {str(exc).splitlines()[0] if str(exc) else ''}", file=sys.stderr)
    sys.exit(1)
