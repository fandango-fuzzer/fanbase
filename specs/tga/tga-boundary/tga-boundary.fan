# TGA images at the edges, besides those of tga: 15-bit colour and colour
# maps of 15-bit entries, 16-bit grayscale with alpha, 32 bits whose alpha
# byte is said to be unused, images that start from the bottom right or the
# top right, origins other than 0, run-length packets that cross rows, an
# image ID of 255 bytes of any value, large images (one row of 65,535, one
# column of 4,096, 256x256, and 128x2 for packets of exactly 128), 10 to 16
# developer tags, every attributes type (premultiplied alpha included), and
# a TGA 2.0 footer with no extension or developer area.
#
# TODO:
# * Image type 0 (no image data), the Huffman and delta-compressed types
#   (32 and 33), colour maps of more than 256 entries, and image data short
#   of what the header says are left out: readers differ on them by design.

include("tga/tga.fan")

<tga_draft> ::= <ident> <image> <packing> <size> <origin> <xy>? <kind> <seed> <ending>
<size> ::= <width> <height> | <big_size>
<big_size> ::= b'R' | b'C' | b'S' | b'M'
# X and Y origin of the image on a screen
<xy> ::= <byte>{4}

<ident> ::= rb'[\x20-\x7e]{0,32}' | rb'[\x00-\xff]{255}'
<tc_depth> ::= b'15' | b'16' | b'16a' | b'24' | b'32' | b'32x'
<grayscale> ::= b'G' | b'GA'
<cm_entry> ::= b'15' | b'16' | b'24' | b'32'
# Raw (r), run-length within rows (l), or run-length across rows (x)
<packing> ::= b'r' | b'l' | b'x'
<origin> ::= b'b' | b't' | b'r' | b'R'

<ending> ::= <tga1> | <tga2> | <footer_only>
<footer_only> ::= b'z'
<tga2> ::= b'2' <ext> <dev>? <scan_table>? <stamp>? <cc_table>? <attributes>?
<dev> ::= <tag>{1,3} | <tag>{10,16}
# No alpha, undefined (ignore), undefined (keep), alpha, premultiplied alpha
<attributes> ::= b'\x00' | b'\x01' | b'\x02' | b'\x03' | b'\x04'
