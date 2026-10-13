# Same as xbm, with values taken from the edges of what the format allows:
# boundary dimensions (0, 1, 7, 8, 9, 15, 16, 17, 31, 32) that stress the
# ceil() row padding, uppercase hex, every hotspot combination, the legacy
# "static char" (no "unsigned") and X10 "static short" forms, an empty 0x0
# bitmap, and hotspot values most parsers never range-check.

<start> ::= <x11_unsigned> | <x11_char_legacy> | <x11_hotspot> | <x11_odd_width> \
          | <x10_short> | <x10_hotspot> | <empty_bitmap>

# X11: static unsigned char — the canonical modern form
<x11_unsigned> ::= (
        "#define img_width " <wa> "\n#define img_height " <ha>
        "\nstatic unsigned char img_bits[] = {\n  " <bytes_a> "\n};\n"
    )

# X11 legacy: "static char" with no "unsigned" (pre-R4, still accepted by many readers)
<x11_char_legacy> ::= (
        "#define img_width " <wb> "\n#define img_height " <hb>
        "\nstatic char img_bits[] = {\n  " <bytes_b> "\n};\n"
    )

# X11 with hotspot defines (legacy cursor bitmaps); huge hot values are the edge case
<x11_hotspot> ::= (
        "#define img_width " <wc> "\n#define img_height " <hc>
        "\n#define img_x_hot " <hot> "\n#define img_y_hot " <hot>
        "\nstatic unsigned char img_bits[] = {\n  " <bytes_c> "\n};\n"
    )

# X11 with a single hotspot define (y_hot only) — asymmetric, rarely handled
<x11_odd_width> ::= (
        "#define img_width " <wd> "\n#define img_height " <hd>
        "\n#define img_y_hot " <hot>
        "\nstatic unsigned char img_bits[] = {\n  " <bytes_d> "\n};\n"
    )

# X10: deprecated "static short" 16-bit word dialect
<x10_short> ::= (
        "#define img_width " <we> "\n#define img_height " <he>
        "\nstatic short img_bits[] = {\n  " <words_e> "\n};\n"
    )

<x10_hotspot> ::= (
        "#define img_width " <wf> "\n#define img_height " <hf>
        "\n#define img_x_hot " <hot> "\n#define img_y_hot " <hot>
        "\nstatic short img_bits[] = {\n  " <words_f> "\n};\n"
    )

# Degenerate 0x0 bitmap: empty initializer list — the ultimate parser edge case
<empty_bitmap> ::= (
        "#define img_width 0\n#define img_height 0\n"
        "static unsigned char img_bits[] = {};\n"
    )

# Boundary-biased dimension enums (1/7/8/9/15/16/17/31/32 stress ceil() padding)
<wa> ::= "1" | "7" | "8" | "9"
<ha> ::= "1" | "2" | "8"
<wb> ::= "15" | "16" | "17"
<hb> ::= "1" | "3"
<wc> ::= "8" | "31" | "32"
<hc> ::= "1" | "2"
<wd> ::= "1" | "9" | "17"
<hd> ::= "1" | "4"
<we> ::= "1" | "16" | "17" | "32"
<he> ::= "1" | "2"
<wf> ::= "15" | "16" | "31"
<hf> ::= "1" | "2"

# Hotspot values: boundary + absurdly large (parsers rarely range-check these)
<hot> ::= "0" | "1" | "255" | "65535"

# Hex terminals: mixed case, spicy value spread
<byte> ::= r'0x[0-9a-fA-F][0-9a-fA-F]'
<word> ::= r'0x[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]'

<bytes_a> ::= <byte> (", " <byte>)*
<bytes_b> ::= <byte> (", " <byte>)*
<bytes_c> ::= <byte> (", " <byte>)*
<bytes_d> ::= <byte> (", " <byte>)*
<words_e> ::= <word> (", " <word>)*
<words_f> ::= <word> (", " <word>)*

# Element-count constraints (top-level): count == ceil(W/8)*H (X11) / ceil(W/16)*H (X10)
where len(str(<bytes_a>).split(", ")) == ((int(<wa>) + 7) // 8) * int(<ha>)
where len(str(<bytes_b>).split(", ")) == ((int(<wb>) + 7) // 8) * int(<hb>)
where len(str(<bytes_c>).split(", ")) == ((int(<wc>) + 7) // 8) * int(<hc>)
where len(str(<bytes_d>).split(", ")) == ((int(<wd>) + 7) // 8) * int(<hd>)
where len(str(<words_e>).split(", ")) == ((int(<we>) + 15) // 16) * int(<he>)
where len(str(<words_f>).split(", ")) == ((int(<wf>) + 15) // 16) * int(<hf>)
