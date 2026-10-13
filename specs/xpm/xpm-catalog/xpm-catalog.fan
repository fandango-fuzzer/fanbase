# X PixMap generator covering XPM 3 C source, natural XPM 2, and legacy XPM 1.
# Each body is a bounded, internally consistent header/palette/raster unit.

<start> ::= <xpm3> | <xpm2> | <xpm1>

# XPM 3: the current C-source representation.
<xpm3> ::= <xpm3_magic> <c_comment>? <xpm3_declaration> "{\n" <xpm3_body> "};\n"
<xpm3_magic> ::= "/* XPM */\n"
<c_comment> ::= "/* standards-focused generated image */\n" | "/* hotspot, symbolic colors, and extensions are legal XPM features */\n"
<xpm3_declaration> ::= "static char * xpm_image[] = \n" | "static char * icon_pixmap[] = \n" | "static const char * generated_xpm[] = \n"
<xpm3_body> ::= <xpm3_base> | <xpm3_hotspot> | <xpm3_rich_colors> | <xpm3_cpp_two> | <xpm3_cpp_four> | <xpm3_wide> | <xpm3_extensions>

# Small dependable base case; palette values still exercise several X color forms.
<xpm3_base> ::= "\"2 2 2 1\",\n" <base_palette> "\"ab\",\n\"ba\"\n"
<base_palette> ::= "\"a c " <warm_color> "\",\n\"b c " <cool_color> "\",\n"
<warm_color> ::= "red" | "#F00" | "#FF0000" | "#FFFF00000000" | "rgb:ff/00/00" | "rgbi:1.0/0.0/0.0"
<cool_color> ::= "blue" | "#00F" | "#0000FF" | "#00000000FFFF" | "navy blue"

# Optional hotspot coordinates at the inclusive low and high boundaries.
<xpm3_hotspot> ::= "\"64 4 4 1 " <hot_x> " " <hot_y> "\",\n" <four_palette> <hot_rows>
<hot_x> ::= "0" | "63"
<hot_y> ::= "0" | "3"
<four_palette> ::= "\". c None\",\n\"X c #000000\",\n\"o c #FFFFFF\",\n\"+ c #808080\",\n"
<hot_rows> ::= "\"X..............................................................o\",\n\".++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.\",\n\".o............................................................X.\",\n\"o..............................................................X\"\n"

# All standardized visual keys: symbolic, monochrome, 4-level gray, gray, and color.
<xpm3_rich_colors> ::= "\"4 4 5 1\",\n" <rich_palette> "\" ab+\",\n\"a+bc\",\n\"bc a\",\n\"+cba\"\n"
<rich_palette> ::= "\"  s transparent m white g4 white g white c None\",\n\"a s foreground m black g4 #444 g #555555 c #123456\",\n\"b s background m white g4 #AAA g #BBBBBB c LightGoldenrodYellow\",\n\"c m black g4 gray50 g gray50 c #ABCDEF\",\n\"+ m white g4 gray100 g white c white\",\n"

# Multi-character pixels, including punctuation, cover cpp beyond the common value 1.
<xpm3_cpp_two> ::= "\"4 3 4 2\",\n" <cpp_two_palette> "\"aa..++++\",\n\"..ZZaa++\",\n\"++++..ZZ\"\n"
<cpp_two_palette> ::= "\"aa c black\",\n\".. c white\",\n\"++ c #00FF00\",\n\"ZZ c None\",\n"
<xpm3_cpp_four> ::= "\"2 2 3 4\",\n" <cpp_four_palette> "\"ABCD....\",\n\"++++ABCD\"\n"
<cpp_four_palette> ::= "\"ABCD c #123456789ABC\",\n\".... c None\",\n\"++++ c gray75\",\n"

# A bounded wide raster tests long scan lines without making generation expensive.
<xpm3_wide> ::= "\"64 1 1 1\",\n\"x c #0F0\",\n\"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx\"\n"

# XPMEXT is announced in the values line and terminated by XPMENDEXT.
<xpm3_extensions> ::= "\"4 2 3 1 0 1 XPMEXT\",\n" <extension_palette> "\"abba\",\n\"baab\",\n" <extension_blocks> "\"XPMENDEXT\"\n"
<extension_palette> ::= "\"a s foreground c #112233\",\n\"b s background c #DDEEFF\",\n\". c None\",\n"
<extension_blocks> ::= "\"XPMEXT metadata\",\n\"author generated\",\n" <optional_extension>
<optional_extension> ::= "" | "\"XPMEXT comments\",\n\"bounded extension payload\",\n" | "\"XPMEXT hints\",\n\"key=value\",\n\"second=line\",\n"

# Natural XPM 2 has no C quoting or comma punctuation.
<xpm2> ::= "! XPM2\n" <xpm2_body>
<xpm2_body> ::= <xpm2_base> | <xpm2_hotspot> | <xpm2_rich> | <xpm2_extensions>
<xpm2_base> ::= "3 2 3 1\n" <xpm2_palette> "abc\ncba\n"
<xpm2_palette> ::= "a c #000\nb c #FFF\nc c None\n"
<xpm2_hotspot> ::= <xpm2_hot_header> "a c black\nb c white\n" "abababab\nbabababa\nabababab\nbabababa\n"
<xpm2_hot_header> ::= <x2_width> " " <x2_height> " 2 1 " <x2_hot_x> " " <x2_hot_y> "\n"
where int(<x2_hot_x>) >= 0 and int(<x2_hot_x>) < int(<x2_width>) and int(<x2_hot_y>) >= 0 and int(<x2_hot_y>) < int(<x2_height>)
<x2_width> ::= "8"
<x2_height> ::= "4"
<x2_hot_x> ::= "0" | "7"
<x2_hot_y> ::= "0" | "3"
<xpm2_rich> ::= "2 2 2 2\nAA s foreground m black g4 gray25 g gray25 c #102030\n.. s mask m white g4 white g white c None\nAA..\n..AA\n"
<xpm2_extensions> ::= "2 2 2 1 XPMEXT\na c red\nb c blue\nab\nba\nXPMEXT metadata\nformat=natural\nXPMEXT data\nrare extension\nXPMENDEXT\n"

# XPM 1: obsolete pre-XPM2 C arrays with macro metadata and color/value pairs.
<xpm1> ::= <xpm1_macros> <xpm1_colors> <xpm1_pixels>
<xpm1_macros> ::= "#define legacy_format 1\n#define legacy_width 4\n#define legacy_height 3\n#define legacy_ncolors 3\n#define legacy_chars_per_pixel 1\n"
<xpm1_colors> ::= "static char * legacy_colors[] = {\n\"a\", \"" <legacy_color_a> "\",\n\"b\", \"" <legacy_color_b> "\",\n\".\", \"None\"\n};\n"
<legacy_color_a> ::= "black" | "#000000" | "gray10"
<legacy_color_b> ::= "white" | "#FFFFFF" | "gray90"
<xpm1_pixels> ::= "static char * legacy_pixels[] = {\n\"ab.a\",\n\"b..b\",\n\"a.ba\"\n};\n"
