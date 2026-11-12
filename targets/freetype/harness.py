"""Ask FreeType about a font: exit 0 if it opens every face in the file and loads and renders every glyph of each,
else say why and exit 1.

It calls the system's FreeType (libfreetype6 on Debian and Ubuntu, built with zlib and brotli, so that it reads WOFF and
WOFF2 too) through ctypes, since the copy that the Python package freetype-py brings reads neither. A scalable font is
set to 16 pixels, so that its hinting program runs; a font of bitmaps is read at its first size.
"""

import ctypes
import ctypes.util
import sys

SCALABLE, LOAD_RENDER = 1, 4
# the reasons FreeType gives most often (fterrdef.h); any other is shown as its number
REASONS = {0x01: "cannot open resource", 0x02: "unknown file format", 0x03: "broken file", 0x04: "invalid FreeType version",
           0x06: "invalid argument", 0x07: "unimplemented feature", 0x08: "broken table", 0x09: "broken offset within table",
           0x0A: "array allocation size too large", 0x0B: "missing module", 0x0C: "missing property",
           0x10: "invalid glyph index", 0x11: "invalid character code", 0x12: "unsupported glyph image format",
           0x13: "cannot render this glyph format", 0x14: "invalid outline", 0x15: "invalid composite glyph",
           0x16: "too many hints", 0x17: "invalid pixel size", 0x18: "invalid SVG document", 0x40: "out of memory",
           0x51: "invalid stream offset", 0x52: "invalid stream seek", 0x53: "invalid stream skip", 0x54: "invalid stream read",
           0x55: "invalid stream operation", 0x56: "invalid frame operation", 0x57: "nested frame access",
           0x58: "invalid frame read", 0x60: "raster uninitialized", 0x61: "raster corrupted", 0x62: "raster overflow",
           0x63: "negative height while rastering", 0x70: "too many registered caches", 0x80: "invalid opcode",
           0x81: "too few arguments", 0x82: "stack overflow", 0x83: "code overflow", 0x84: "bad argument",
           0x85: "division by zero", 0x86: "invalid reference", 0x87: "found debug opcode", 0x88: "found ENDF opcode in execution stream",
           0x89: "nested DEFS", 0x8A: "invalid code range", 0x8B: "execution context too long", 0x8C: "too many function definitions",
           0x8D: "too many instruction definitions", 0x8E: "SFNT font table missing", 0x8F: "horizontal header (hhea) table missing",
           0x90: "locations (loca) table missing", 0x91: "name table missing", 0x92: "character map (cmap) table missing",
           0x93: "horizontal metrics (hmtx) table missing", 0x94: "PostScript (post) table missing", 0x95: "invalid horizontal metrics",
           0x96: "invalid character map (cmap) format", 0x97: "invalid ppem value", 0x98: "invalid vertical metrics",
           0x99: "could not find context", 0x9A: "invalid PostScript (post) table format", 0x9B: "invalid PostScript (post) table",
           0x9C: "found FDEF or IDEF opcode in glyf bytecode", 0x9D: "missing bitmap in strike", 0x9E: "SVG hooks have not been set",
           0xA0: "opcode syntax error", 0xA1: "argument stack underflow", 0xA2: "ignore", 0xA3: "no Unicode glyph name found",
           0xA4: "glyph too big for hinting", 0xB0: "`STARTFONT' field missing", 0xB1: "`FONT' field missing",
           0xB2: "`SIZE' field missing", 0xB3: "`FONTBOUNDINGBOX' field missing", 0xB4: "`CHARS' field missing",
           0xB5: "`STARTCHAR' field missing", 0xB6: "`ENCODING' field missing", 0xB7: "`BBX' field missing",
           0xB8: "`BBX' too big", 0xB9: "Font header corrupted or missing fields", 0xBA: "Font glyphs corrupted or missing fields"}


class Face(ctypes.Structure):  # the first fields of FT_FaceRec, which are all that is read
    _fields_ = [("num_faces", ctypes.c_long), ("face_index", ctypes.c_long), ("face_flags", ctypes.c_long),
                ("style_flags", ctypes.c_long), ("num_glyphs", ctypes.c_long), ("family_name", ctypes.c_char_p),
                ("style_name", ctypes.c_char_p), ("num_fixed_sizes", ctypes.c_int)]


ft = ctypes.CDLL(ctypes.util.find_library("freetype") or "libfreetype.so.6")
ft.FT_New_Face.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_long, ctypes.POINTER(ctypes.POINTER(Face))]
ft.FT_Set_Char_Size.argtypes = [ctypes.POINTER(Face), ctypes.c_long, ctypes.c_long, ctypes.c_uint, ctypes.c_uint]
ft.FT_Select_Size.argtypes = [ctypes.POINTER(Face), ctypes.c_int]
ft.FT_Load_Glyph.argtypes = [ctypes.POINTER(Face), ctypes.c_uint, ctypes.c_int32]
ft.FT_Done_Face.argtypes = [ctypes.POINTER(Face)]
library = ctypes.c_void_p()
ft.FT_Init_FreeType(ctypes.byref(library))

if sys.argv[1] == "--version":
    major, minor, patch = ctypes.c_int(), ctypes.c_int(), ctypes.c_int()
    ft.FT_Library_Version(library, ctypes.byref(major), ctypes.byref(minor), ctypes.byref(patch))
    print(f"{major.value}.{minor.value}.{patch.value}")
    sys.exit(0)


def check(error, doing):
    if error:
        print(f"{doing}: {REASONS.get(error, f'error {error:#04x}')}", file=sys.stderr)
        sys.exit(1)


path = sys.argv[1].encode()
index, faces = 0, 1
while index < faces:
    face = ctypes.POINTER(Face)()
    check(ft.FT_New_Face(library, path, index, ctypes.byref(face)), "opening")
    faces = face.contents.num_faces
    if face.contents.face_flags & SCALABLE:
        check(ft.FT_Set_Char_Size(face, 0, 16 * 64, 72, 72), "sizing")
    elif face.contents.num_fixed_sizes > 0:
        check(ft.FT_Select_Size(face, 0), "sizing")
    for glyph in range(face.contents.num_glyphs):
        check(ft.FT_Load_Glyph(face, glyph, LOAD_RENDER), "loading a glyph")
    ft.FT_Done_Face(face)
    index += 1
