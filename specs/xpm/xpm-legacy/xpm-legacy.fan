# Same as xpm, plus the deprecated XPM1 (#define + _colors[]/_pixels[]
# arrays) and XPM2 (plain-text "! XPM2") dialects, boundary hex colour
# widths (3/6/9/12 digits), %HSV values, and large hotspot coordinates.
#
# Every row of a raster has to be as wide as the header says, and Fandango
# seldom found rows and a width that agree by search: in 1,000 files F1 never
# came out, and XPM1 and XPM2 together in 2 to 18% of them, depending on the
# seed. So each of the three has one alternative for each width (1 to 9),
# with the width written in the header and the rows of that many pixels, and
# F2 one for each number of colors (1 to 4).

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
#     (semantically valid palette↔raster link); width 1 to 9
<xpm3_head> ::= "/* XPM */\n" "static char * " <name> "[] = {\n"
<f1_colors> ::= ',\n"a' <f1kd> '"' ',\n"b' <f1kd> '"'
<f1kd> ::= <f1k>+
<f1k>  ::= " " <key> " " <cval>
<f1_palette> ::= <f1_w1> | <f1_w2> | <f1_w3> | <f1_w4> | <f1_w5> | <f1_w6> | <f1_w7> | <f1_w8> | <f1_w9>
<f1_w1> ::= <xpm3_head> '"1 3 2 1 ' <hot> " " <hot> '"' <f1_colors> \
    ',\n"' r'[ab]{1}' '",\n"' r'[ab]{1}' '",\n"' r'[ab]{1}' '"\n};\n'
<f1_w2> ::= <xpm3_head> '"2 3 2 1 ' <hot> " " <hot> '"' <f1_colors> \
    ',\n"' r'[ab]{2}' '",\n"' r'[ab]{2}' '",\n"' r'[ab]{2}' '"\n};\n'
<f1_w3> ::= <xpm3_head> '"3 3 2 1 ' <hot> " " <hot> '"' <f1_colors> \
    ',\n"' r'[ab]{3}' '",\n"' r'[ab]{3}' '",\n"' r'[ab]{3}' '"\n};\n'
<f1_w4> ::= <xpm3_head> '"4 3 2 1 ' <hot> " " <hot> '"' <f1_colors> \
    ',\n"' r'[ab]{4}' '",\n"' r'[ab]{4}' '",\n"' r'[ab]{4}' '"\n};\n'
<f1_w5> ::= <xpm3_head> '"5 3 2 1 ' <hot> " " <hot> '"' <f1_colors> \
    ',\n"' r'[ab]{5}' '",\n"' r'[ab]{5}' '",\n"' r'[ab]{5}' '"\n};\n'
<f1_w6> ::= <xpm3_head> '"6 3 2 1 ' <hot> " " <hot> '"' <f1_colors> \
    ',\n"' r'[ab]{6}' '",\n"' r'[ab]{6}' '",\n"' r'[ab]{6}' '"\n};\n'
<f1_w7> ::= <xpm3_head> '"7 3 2 1 ' <hot> " " <hot> '"' <f1_colors> \
    ',\n"' r'[ab]{7}' '",\n"' r'[ab]{7}' '",\n"' r'[ab]{7}' '"\n};\n'
<f1_w8> ::= <xpm3_head> '"8 3 2 1 ' <hot> " " <hot> '"' <f1_colors> \
    ',\n"' r'[ab]{8}' '",\n"' r'[ab]{8}' '",\n"' r'[ab]{8}' '"\n};\n'
<f1_w9> ::= <xpm3_head> '"9 3 2 1 ' <hot> " " <hot> '"' <f1_colors> \
    ',\n"' r'[ab]{9}' '",\n"' r'[ab]{9}' '",\n"' r'[ab]{9}' '"\n};\n'

# F2: XPM3, cpp=1, 1 to 4 colors (one alternative for each count);
#     multi-key color entries + boundary hex; fixed 4x2 raster (structural)
<f2_ncolors> ::= <f2_n1> | <f2_n2> | <f2_n3> | <f2_n4>
<f2_n1> ::= <xpm3_head> '"4 2 1 1"' <cl2> <f2_raster>
<f2_n2> ::= <xpm3_head> '"4 2 2 1"' <cl2>{2} <f2_raster>
<f2_n3> ::= <xpm3_head> '"4 2 3 1"' <cl2>{3} <f2_raster>
<f2_n4> ::= <xpm3_head> '"4 2 4 1"' <cl2>{4} <f2_raster>
<f2_raster> ::= ',\n"' <r2a> '",\n"' <r2b> '"\n};\n'
<cl2>   ::= ',\n"' <pkey1> <kds2> '"'
<pkey1> ::= r'[a-zA-Z0-9.#*+@ -]'
<kds2>  ::= <kd2>{1,3}
<kd2>   ::= " " <key> " " <colany>
<colany>::= <cval> | <cvalsym>
<r2a>   ::= r'[a-zA-Z0-9.#*+@ -]{4}'
<r2b>   ::= r'[a-zA-Z0-9.#*+@ -]{4}'

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
#     Deprecated pre-XPM3 syntax; width 1 to 9.
<f4_xpm1> ::= <f4_w1> | <f4_w2> | <f4_w3> | <f4_w4> | <f4_w5> | <f4_w6> | <f4_w7> | <f4_w8> | <f4_w9>
<f4_w1> ::= "#define img_format 1\n" "#define img_width 1\n" <f4_rest> \
    '"' r'[.# ]{1}' '",\n"' r'[.# ]{1}' '"\n};\n'
<f4_w2> ::= "#define img_format 1\n" "#define img_width 2\n" <f4_rest> \
    '"' r'[.# ]{2}' '",\n"' r'[.# ]{2}' '"\n};\n'
<f4_w3> ::= "#define img_format 1\n" "#define img_width 3\n" <f4_rest> \
    '"' r'[.# ]{3}' '",\n"' r'[.# ]{3}' '"\n};\n'
<f4_w4> ::= "#define img_format 1\n" "#define img_width 4\n" <f4_rest> \
    '"' r'[.# ]{4}' '",\n"' r'[.# ]{4}' '"\n};\n'
<f4_w5> ::= "#define img_format 1\n" "#define img_width 5\n" <f4_rest> \
    '"' r'[.# ]{5}' '",\n"' r'[.# ]{5}' '"\n};\n'
<f4_w6> ::= "#define img_format 1\n" "#define img_width 6\n" <f4_rest> \
    '"' r'[.# ]{6}' '",\n"' r'[.# ]{6}' '"\n};\n'
<f4_w7> ::= "#define img_format 1\n" "#define img_width 7\n" <f4_rest> \
    '"' r'[.# ]{7}' '",\n"' r'[.# ]{7}' '"\n};\n'
<f4_w8> ::= "#define img_format 1\n" "#define img_width 8\n" <f4_rest> \
    '"' r'[.# ]{8}' '",\n"' r'[.# ]{8}' '"\n};\n'
<f4_w9> ::= "#define img_format 1\n" "#define img_width 9\n" <f4_rest> \
    '"' r'[.# ]{9}' '",\n"' r'[.# ]{9}' '"\n};\n'
<f4_rest> ::= "#define img_height 2\n" \
    "#define img_ncolors 2\n" \
    "#define img_chars_per_pixel 1\n" \
    "#define img_hotspot_x " <hot> "\n" \
    "#define img_hotspot_y " <hot> "\n" \
    'static char * img_colors[] = {\n' \
    '". ", "' <cval> '",\n' \
    '"# ", "' <cval> '"\n};\n' \
    'static char * img_pixels[] = {\n'

# F5: deprecated XPM2 plain-text (`! XPM2`, no C wrapper). Values line & color
#     lines unquoted; width 1 to 9.
<f5_xpm2> ::= <f5_w1> | <f5_w2> | <f5_w3> | <f5_w4> | <f5_w5> | <f5_w6> | <f5_w7> | <f5_w8> | <f5_w9>
<f5_w1> ::= "! XPM2\n1 3 2 1\n" <f5_colors> \
    r'[.#]{1}' "\n" r'[.#]{1}' "\n" r'[.#]{1}' "\n"
<f5_w2> ::= "! XPM2\n2 3 2 1\n" <f5_colors> \
    r'[.#]{2}' "\n" r'[.#]{2}' "\n" r'[.#]{2}' "\n"
<f5_w3> ::= "! XPM2\n3 3 2 1\n" <f5_colors> \
    r'[.#]{3}' "\n" r'[.#]{3}' "\n" r'[.#]{3}' "\n"
<f5_w4> ::= "! XPM2\n4 3 2 1\n" <f5_colors> \
    r'[.#]{4}' "\n" r'[.#]{4}' "\n" r'[.#]{4}' "\n"
<f5_w5> ::= "! XPM2\n5 3 2 1\n" <f5_colors> \
    r'[.#]{5}' "\n" r'[.#]{5}' "\n" r'[.#]{5}' "\n"
<f5_w6> ::= "! XPM2\n6 3 2 1\n" <f5_colors> \
    r'[.#]{6}' "\n" r'[.#]{6}' "\n" r'[.#]{6}' "\n"
<f5_w7> ::= "! XPM2\n7 3 2 1\n" <f5_colors> \
    r'[.#]{7}' "\n" r'[.#]{7}' "\n" r'[.#]{7}' "\n"
<f5_w8> ::= "! XPM2\n8 3 2 1\n" <f5_colors> \
    r'[.#]{8}' "\n" r'[.#]{8}' "\n" r'[.#]{8}' "\n"
<f5_w9> ::= "! XPM2\n9 3 2 1\n" <f5_colors> \
    r'[.#]{9}' "\n" r'[.#]{9}' "\n" r'[.#]{9}' "\n"
<f5_colors> ::= ". c " <cval> "\n" "# c " <cval> "\n"
