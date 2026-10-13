# Portable Pixel Map (PPM) grammar.
# Covers legacy/plain P3, raw P6, comments and all legal header whitespace,
# maxval boundaries, one- and two-byte raw samples, and bounded image streams.

<start> ::= <ppm_image> | <p3_image> <sep> <ppm_image> | <p6_image> <ppm_image>

<ppm_image> ::= <p3_image> | <p6_image>

# P3 is the older plain-text representation.  Fixed-size cases keep raster
# cardinality structural; the dynamic 1x1 case demonstrates cross-field bounds.
<p3_image> ::= <p3_minimal> | <p3_common> | <p3_wide> | <p3_tall> | <p3_deep> | <p3_dynamic_1x1>
<p3_minimal> ::= "P3" <sep> "1" <sep> "1" <sep> "1" <sep> <sample1> (<sep> <sample1>){2} <trailing>?
<p3_common> ::= "P3" <sep> "2" <sep> "2" <sep> "255" <sep> <sample255> (<sep> <sample255>){11} <trailing>?
<p3_wide> ::= "P3" <sep> "8" <sep> "1" <sep> "15" <sep> <sample15> (<sep> <sample15>){23} <trailing>?
<p3_tall> ::= "P3" <sep> "1" <sep> "8" <sep> "255" <sep> <sample255> (<sep> <sample255>){23} <trailing>?
<p3_deep> ::= "P3" <sep> "3" <sep> "2" <sep> "65535" <sep> <sample65535> (<sep> <sample65535>){17} <trailing>?
<p3_dynamic_1x1> ::= "P3" <sep> "1" <sep> "1" <sep> <dynamic_maxval> <sep> <dynamic_red> <sep> <dynamic_green> <sep> <dynamic_blue> <trailing>?
where int(<dynamic_red>) <= int(<dynamic_maxval>) and int(<dynamic_green>) <= int(<dynamic_maxval>) and int(<dynamic_blue>) <= int(<dynamic_maxval>)

<dynamic_maxval> ::= <decimal5>
where 1 <= int(<decimal5>) <= 65535
<dynamic_red> ::= <decimal5>
where 0 <= int(<decimal5>) <= 65535
<dynamic_green> ::= <decimal5>
where 0 <= int(<decimal5>) <= 65535
<dynamic_blue> ::= <decimal5>
where 0 <= int(<decimal5>) <= 65535
<decimal5> ::= r'(0|[1-9][0-9]{0,4})'

<sample1> ::= "0" | "1"
<sample15> ::= r'(0|[1-9]|1[0-5])'
<sample255> ::= r'(0|[1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
<sample65535> ::= r'(0|[1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])'

# P6 headers end in exactly one whitespace byte.  Raster cases are bounded and
# structurally contain width * height * 3 samples.  16-bit samples are big-endian.
<p6_image> ::= <p6_minimal> | <p6_common> | <p6_wide> | <p6_deep>
<p6_minimal> ::= "P6" <sep> "1" <sep> "1" <sep> "1" <raw_terminator> <raw_bit> <raw_bit> <raw_bit>
<p6_common> ::= "P6" <sep> "2" <sep> "2" <sep> "255" <raw_terminator> <raw_octet>{12}
<p6_wide> ::= "P6" <sep> "8" <sep> "1" <sep> "255" <raw_terminator> <raw_octet>{24}
<p6_deep> ::= "P6" <sep> "3" <sep> "2" <sep> "65535" <raw_terminator> <raw_word>{18}

<raw_bit> ::= "\x00" | "\x01"
<raw_octet> ::= "\x00" | "\x01" | "\x02" | "\x7f" | "\x80" | "\xfe" | "\xff"
<raw_word> ::= "\x00\x00" | "\x00\x01" | "\x00\xff" | "\x01\x00" | "\x7f\xff" | "\x80\x00" | "\xff\xfe" | "\xff\xff"

# A comment terminates at LF or CRLF and is whitespace.  Separators are
# deliberately bounded to avoid nullable repetition and excessive ambiguity.
<sep> ::= <ws_char>+ | <hws>* <comment> <ws_char>* | <hws>* <comment> <hws>* <comment> <ws_char>*
<comment> ::= "#" <comment_text> <line_end>
<comment_text> ::= r'[A-Za-z0-9 .,:;_+\-/]{0,60}'
<line_end> ::= "\n" | "\r\n"
<ws_char> ::= " " | "\t" | "\n" | "\r" | "\x0b" | "\x0c"
<hws> ::= " " | "\t"
<raw_terminator> ::= " " | "\t" | "\n" | "\r" | "\x0b" | "\x0c"
<trailing> ::= <sep>
