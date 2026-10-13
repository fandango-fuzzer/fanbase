# Same as ppm, with values taken from the edges of what the format allows:
# maxval 1, 255, 256 and 65535; leading-zero dimensions; comment lines woven
# through the header; every whitespace flavour including VT and FF.

<start> ::= <p6_1> | <p6_255> | <p6_256> | <p6_65535> | <p3_255> | <p3_65535>

<p6_1>     ::= "P6" <sp> <width> <sp> <height> <sp> "1" <sws> <ras8>
<p6_255>   ::= "P6" <sp> <width> <sp> <height> <sp> "255" <sws> <ras8>
<p6_256>   ::= "P6" <sp> <width> <sp> <height> <sp> "256" <sws> <ras16>
<p6_65535> ::= "P6" <sp> <width> <sp> <height> <sp> "65535" <sws> <ras16>
<p3_255>   ::= "P3" <sp> <width> <sp> <height> <sp> "255" <sp> <p3r255>
<p3_65535> ::= "P3" <sp> <width> <sp> <height> <sp> "65535" <sp> <p3r65535>

# Dimensions: minimums and a leading-zero form (Netpbm parses "01" as 1).
<width>  ::= "1" | "2" | "3" | "01"
<height> ::= "1" | "2" | "3" | "01"

# Header whitespace: at least one item; items include comments and VT/FF.
<sp>  ::= <spi> <spi>*
<spi> ::= " " | "\t" | "\n" | "\r" | "\x0b" | "\x0c" | <comment>
<comment> ::= "#" <ctext> "\n"
<ctext>   ::= r'[^\n]*'

# Exactly ONE whitespace char ends MAXVAL before a P6 raster.
<sws> ::= " " | "\t" | "\n" | "\r"

# P6 raster bytes (comment/whitespace-free binary blob).
<ras8>  ::= <b>+
<ras16> ::= <b>+
<b> ::= rb'[\x00-\xff]'

# P3 raster: numeric samples with whitespace separators (no comments here so
# the token count stays exact). s255 regex is bounded to 0..255.
<p3r255>   ::= <s255r>
<s255r>    ::= <s255> <nws> <s255r> | <s255> <nws>
<s255>     ::= r'([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
<p3r65535> ::= <s16r>
<s16r>     ::= <s16> <nws> <s16r> | <s16> <nws>
<s16>      ::= r'[0-9]{1,5}'
<nws> ::= " " | "\t" | "\n" | "\r\n"

# cross-field constraints
# P6: emitted byte length == WIDTH*HEIGHT*3*bytes_per_sample.
where len(bytes(<ras8>))  == int(str(<width>)) * int(str(<height>)) * 3
where len(bytes(<ras16>)) == int(str(<width>)) * int(str(<height>)) * 3 * 2
# P3: numeric-token count == WIDTH*HEIGHT*3, and every sample <= MAXVAL.
where len(str(<p3r255>).split())   == int(str(<width>)) * int(str(<height>)) * 3
where len(str(<p3r65535>).split()) == int(str(<width>)) * int(str(<height>)) * 3
where all(int(t) <= 65535 for t in str(<p3r65535>).split())
