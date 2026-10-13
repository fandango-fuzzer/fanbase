# Same as xpm, plus the deprecated XPM1 (#define + _colors[]/_pixels[]
# arrays) and XPM2 (plain-text "! XPM2") dialects, boundary hex colour
# widths (3/6/9/12 digits), %HSV values, and large hotspot coordinates.

<start> ::= <f1_palette> | <f2_ncolors> | <f3_ext> | <f4_xpm1> | <f5_xpm2>

# shared vocab
<name>  ::= r'[a-z][a-zA-Z0-9_]{0,10}'
# color value forms incl. boundary hex widths (3/6/9/12), rare %HSV, named
<cval>  ::= "None" | r'#[0-9A-Fa-f]{6}' | r'#[0-9A-Fa-f]{3}' \
          | r'#[0-9A-Fa-f]{9}' | r'#[0-9A-Fa-f]{12}' \
          | r'%[0-9A-Fa-f]{6}' | "black" | "white" | "red" | "gray50" | "None"
<cvalsym> ::= r'[A-Za-z][A-Za-z0-9_]{0,6}'
<key>   ::= "c" | "m" | "g4" | "g" | "s"
<hot>   ::= "0" | "1" | "7" | "255" | "65535"

# F1: XPM3, cpp=1, WITH hotspot, pixels drawn only from the two DEFINED keys
#     (semantically valid palette↔raster link); width is variable & constrained
<f1_palette> ::= "/* XPM */\n" "static char * " <name> "[] = {\n" \
    '"' <w1> " 3 2 1 " <hot> " " <hot> '"' \
    ',\n"a' <f1kd> '"' ',\n"b' <f1kd> '"' \
    ',\n"' <p1> '",\n"' <p2> '",\n"' <p3> '"\n};\n'
<w1>   ::= r'[1-9]'
<f1kd> ::= <f1k>+
<f1k>  ::= " " <key> " " <cval>
<p1>   ::= r'[ab]+'
<p2>   ::= r'[ab]+'
<p3>   ::= r'[ab]+'
where int(str(<w1>)) == len(str(<p1>))
where int(str(<w1>)) == len(str(<p2>))
where int(str(<w1>)) == len(str(<p3>))

# F2: XPM3, cpp=1, VARIABLE ncolors bound to color-line count via .count;
#     multi-key color entries + boundary hex; fixed 4x2 raster (structural)
<f2_ncolors> ::= "/* XPM */\n" "static char * " <name> "[] = {\n" \
    '"4 2 ' <nc2> ' 1"' <cols2> \
    ',\n"' <r2a> '",\n"' <r2b> '"\n};\n'
<nc2>   ::= r'[1-4]'
<cols2> ::= <cl2>+
<cl2>   ::= ',\n"' <pkey1> <kds2> '"'
<pkey1> ::= r'[a-zA-Z0-9.#*+@ -]'
<kds2>  ::= <kd2>{1,3}
<kd2>   ::= " " <key> " " <colany>
<colany>::= <cval> | <cvalsym>
<r2a>   ::= r'[a-zA-Z0-9.#*+@ -]{4}'
<r2b>   ::= r'[a-zA-Z0-9.#*+@ -]{4}'
where int(str(<nc2>)) == str(<cols2>).count('\n')

# F3: XPM3, cpp=2 (two chars per pixel), XPMEXT flag + extension block
#     (XPMEXT <name> <data> ... XPMENDEXT) — rarely-exercised path
<f3_ext> ::= "/* XPM */\n" "static char * " <name> "[] = {\n" \
    '"3 2 2 2 XPMEXT"' \
    ',\n"ab c ' <cval> '"' ',\n"cd c ' <cval> '"' \
    ',\n"' <q1> '",\n"' <q2> '"' \
    <extblk> "\n};\n"
<q1>     ::= r'[a-d]{6}'
<q2>     ::= r'[a-d]{6}'
<extblk> ::= <extone>+
<extone> ::= ',\n"XPMEXT ' <extname> '"' <extdata> ',\n"XPMENDEXT"'
<extname>::= r'[A-Za-z][A-Za-z0-9_]{0,8}'
<extdata>::= <extline>*
<extline>::= ',\n"' <exttext> '"'
<exttext>::= r'[A-Za-z0-9 =:._/-]{0,20}'

# F4: legacy XPM1 — #define directives + separate _colors[]/_pixels[] arrays.
#     Deprecated pre-XPM3 syntax; width bound to raster row lengths via where.
<f4_xpm1> ::= "#define img_format 1\n" \
    "#define img_width " <w4> "\n" \
    "#define img_height 2\n" \
    "#define img_ncolors 2\n" \
    "#define img_chars_per_pixel 1\n" \
    "#define img_hotspot_x " <hot> "\n" \
    "#define img_hotspot_y " <hot> "\n" \
    'static char * img_colors[] = {\n' \
    '". ", "' <cval> '",\n' \
    '"# ", "' <cval> '"\n};\n' \
    'static char * img_pixels[] = {\n' \
    '"' <x1> '",\n"' <x2> '"\n};\n'
<w4> ::= r'[1-9]'
<x1> ::= r'[.# ]+'
<x2> ::= r'[.# ]+'
where int(str(<w4>)) == len(str(<x1>))
where int(str(<w4>)) == len(str(<x2>))

# F5: deprecated XPM2 plain-text (`! XPM2`, no C wrapper). Values line & color
#     lines unquoted; width bound to each raster row length via where.
<f5_xpm2> ::= "! XPM2\n" <w5> " 3 2 1\n" \
    ". c " <cval> "\n" \
    "# c " <cval> "\n" \
    <y1> "\n" <y2> "\n" <y3> "\n"
<w5> ::= r'[1-9]'
<y1> ::= r'[.#]+'
<y2> ::= r'[.#]+'
<y3> ::= r'[.#]+'
where int(str(<w5>)) == len(str(<y1>))
where int(str(<w5>)) == len(str(<y2>))
where int(str(<w5>)) == len(str(<y3>))
