# XBM: X11 ("static unsigned char NAME_bits[] = {0xNN, ...}", one byte per
# 8 pixels) and the deprecated X10 dialect ("static short", one 16-bit word
# per 16 pixels), both row-padded to a byte/word boundary, with an optional
# x_hot/y_hot cursor hotspot pair.

<start> ::= <xbm>
<xbm> ::= <x11_plain> | <x11_char> | <x11_hotspot> | <x10_short> | <x10_hotspot>

# 1. X11, "unsigned char", no hotspot
<x11_plain> ::= (
    "#define image_width " <w1> "\n"
    "#define image_height " <h1> "\n"
    "static unsigned char image_bits[] = {\n "
    <bytes1>
    " };\n"
  )
  where len(str(<bytes1>).split(", ")) == ((int(<w1>) + 7) // 8) * int(<h1>)

# 2. X11, plain "char" element type
<x11_char> ::= (
    "#define picture_width " <w2> "\n"
    "#define picture_height " <h2> "\n"
    "static char picture_bits[] = {\n "
    <bytes2>
    " };\n"
  )
  where len(str(<bytes2>).split(", ")) == ((int(<w2>) + 7) // 8) * int(<h2>)

# 3. X11 with an x_hot / y_hot cursor hotspot
<x11_hotspot> ::= (
    "#define cursor_width " <w3> "\n"
    "#define cursor_height " <h3> "\n"
    "#define cursor_x_hot " <xh3> "\n"
    "#define cursor_y_hot " <yh3> "\n"
    "static unsigned char cursor_bits[] = {\n "
    <bytes3>
    " };\n"
  )
  where len(str(<bytes3>).split(", ")) == ((int(<w3>) + 7) // 8) * int(<h3>)

# 4. X10, 16-bit "short" words, no hotspot
<x10_short> ::= (
    "#define bitmap_width " <w4> "\n"
    "#define bitmap_height " <h4> "\n"
    "static short bitmap_bits[] = {\n "
    <words4>
    " };\n"
  )
  where len(str(<words4>).split(", ")) == ((int(<w4>) + 15) // 16) * int(<h4>)

# 5. X10, 16-bit "short" words, with hotspot
<x10_hotspot> ::= (
    "#define glyph_width " <w5> "\n"
    "#define glyph_height " <h5> "\n"
    "#define glyph_x_hot " <xh5> "\n"
    "#define glyph_y_hot " <yh5> "\n"
    "static short glyph_bits[] = {\n "
    <words5>
    " };\n"
  )
  where len(str(<words5>).split(", ")) == ((int(<w5>) + 15) // 16) * int(<h5>)

# dimensions (mandatory, positive, bounded to keep files small)
<w1> ::= <dim>
<h1> ::= <dim>
<w2> ::= <dim>
<h2> ::= <dim>
<w3> ::= <dim>
<h3> ::= <dim>
<w4> ::= <dim>
<h4> ::= <dim>
<w5> ::= <dim>
<h5> ::= <dim>
<dim> ::= "8" | "16" | "24" | "32"

# hotspot coordinates: any non-negative integer within the image
<xh3> ::= <coord>
<yh3> ::= <coord>
<xh5> ::= <coord>
<yh5> ::= <coord>
<coord> ::= "0" | "1" | "3" | "7" | "8" | "15"

# array bodies
<bytes1> ::= <byte> (", " <byte>)*
<bytes2> ::= <byte> (", " <byte>)*
<bytes3> ::= <byte> (", " <byte>)*
<words4> ::= <word> (", " <word>)*
<words5> ::= <word> (", " <word>)*

<byte> ::= r'0x[0-9a-f][0-9a-f]'
<word> ::= r'0x[0-9a-f][0-9a-f][0-9a-f][0-9a-f]'
