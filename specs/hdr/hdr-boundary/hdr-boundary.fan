# Radiance images at the edges, besides those of hdr: the XYZE format and no
# FORMAT line at all; the seven other orientations of the resolution line
# (rows from the bottom, from the right, or along Y); old-style runs (a pixel
# 1 1 1 n repeating the one before); images whose odd rows only are
# run-length encoded; the narrowest rows that run-length encoding allows
# (8x8), and rows of 4,096 pixels; exponents of 0, 1, 254 and 255 under any
# mantissa;
# header values that are empty or 200 to 1,000 characters long, and 12 to
# 20 header lines.
#
# TODO:
# * The widest row that run-length encoding allows (32,767) and the rows
#   past it: Fandango 1.3.1 runs out of memory making an image of that many
#   pixels.
# * Pixels short of what the resolution line says, header lines without an
#   ending newline, and a resolution line that does not parse are left out:
#   readers differ on them by design.

include("hdr/hdr.fan")

<hdr_draft> ::= <magic> <before> <format> <after> <size> <encoding> <kind> <seed> <orientation>? <extreme>?
<size> ::= <width> <height> | <big_size>
# 4096x1, 8x8, 4096x2
<big_size> ::= b'L' | b'E' | b'T'
# Red-green-blue or CIE XYZ, or no FORMAT line
<format> ::= b'rgbe' | b'xyze' | b'none'
# Flat, run-length, old-style runs (o), or run-length on odd rows only (m)
<encoding> ::= b'f' | b'r' | b'o' | b'm'
<orientation> ::= b'-Y+X' | b'-Y-X' | b'+Y+X' | b'+Y-X' | b'+X-Y' | b'+X+Y' | b'-X-Y' | b'-X+Y'
<extreme> ::= rb'[\x00-\xff]{1,4}'
<before> ::= <hline>{0,3} | <hline>{12,20}
<text> ::= rb'[\x20-\x7e]{0,40}' | rb'[\x20-\x7e]{200,1000}'
