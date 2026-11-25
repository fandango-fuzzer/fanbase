# Icons and cursors at the edges, besides those of ico: 256x256 images
# (written as 0 in the directory; drawn in runs of one colour, as palette PNG
# or bitmaps of up to 4 bits), images of 1 to 255 pixels on a side, 16-bit
# bitmaps, palettes of fewer colours than the depth allows, 16-bit and
# interlaced PNG, up to 16 images in one file, directory
# entries with a plane and bit count of 0 (readers take them from the
# image), and cursors whose hotspot is anywhere in the image.
#
# TODO:
# * Entries whose width, height or bit count disagree with their image, an
#   empty directory, compressed bitmaps (BI_RLE, BI_BITFIELDS), and images
#   that overlap or lie past the end of the file are left out: readers
#   differ on them by design.

include("ico/ico.fan")

# 1 to 4 images, and then 0, 4, 8 or 12 of up to 16x16 (Fandango draws the
# count of a repetition near its least, so they come in fours)
<ico_draft> ::= <dir_type> <entry>{1,4} <tiny_four>{0,3}
<tiny_four> ::= <tiny_entry> <tiny_entry> <tiny_entry> <tiny_entry>
<tiny_entry> ::= <tiny_size> <image> <kind> <seed> <hotspot>
<tiny_size> ::= <tiny_side> <tiny_side>
<tiny_side> ::= rb'[\x01-\x10]'
<entry> ::= <icon_size> <image> <kind> <seed> <hotspot> <dir_zero>?
<icon_size> ::= b'\x10' | b'\x18' | b'\x20' | b'\x30' | <side> <side> | b'big'
<side> ::= rb'[\x01-\x40]' | b'\x01' | b'\xff' | b'\x80'
<bitmap> ::= b'B' <bpp> <few_colours>?
<bpp> ::= b'1' | b'4' | b'8' | b'16' | b'24' | b'32'
<few_colours> ::= <byte>
<png> ::= b'P' <ctype> <trns>? <deep>? <interlaced>? <filters>
<deep> ::= b'16'
<interlaced> ::= b'i'
<dir_zero> ::= b'0'
