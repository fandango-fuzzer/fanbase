# PPM (Netpbm): P3 (plain ASCII) and P6 (raw binary) rasters, 8-bit and
# 16-bit big-endian samples, header comments, and the whitespace rule that
# a comment counts as whitespace anywhere one is legal.

<start> ::= <p6_8> | <p6_16> | <p3>

# P6, raw 8-bit: 3 bytes per pixel
<p6_8> ::= "P6" <ws> <comments> <width> <ws> <height> <ws> "255" <onews> <raster8>
where len(<raster8>) == int(str(<width>)) * int(str(<height>)) * 3

# P6, raw 16-bit: 6 bytes per pixel (2 BE bytes per sample)
<p6_16> ::= "P6" <ws> <comments> <width> <ws> <height> <ws> "65535" <onews> <raster16>
where len(<raster16>) == int(str(<width>)) * int(str(<height>)) * 6

# P3, plain ASCII: 3 decimal samples per pixel
<p3> ::= "P3" <ws> <comments> <width> <ws> <height> <ws> "255" <ws> <p3data>
where len(<p3data>) == int(str(<width>)) * int(str(<height>)) * 3

# shared header tokens
<width>  ::= r'[1-8]'
<height> ::= r'[1-8]'
<ws>     ::= r'[ \t\r\n]+'
<onews>  ::= "\n"
<comments> ::= <comment>*
<comment>  ::= r'#[^\n\r]*' "\n"

# raster bodies
<raster8>  ::= <byte>*
<raster16> ::= <byte>*
<byte> ::= rb'[\x00-\xff]'

<p3data>   ::= <p3sample>*
<p3sample> ::= <p3num> " "
<p3num>    ::= r'0|[1-9][0-9]?|1[0-9][0-9]|2[0-4][0-9]|25[0-5]'
