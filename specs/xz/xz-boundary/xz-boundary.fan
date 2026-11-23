# Same as xz, at the edges of the .xz format: streams of no blocks (an Index
# of no records), one to three streams with stream padding (zero bytes, a
# multiple of four) between them and after the last, the BCJ filters (x86,
# PowerPC, IA-64, ARM, ARM-Thumb, SPARC) before Delta or LZMA2, block headers
# padded beyond what they need (up to 1,024 bytes), data that does not
# compress (LZMA2 stores it in an uncompressed chunk), LZMA2 data in two to
# four chunks, and dictionaries of up to 48 MiB. xz_file() of xz makes the
# file from the draft.
#
# TODO:
# * No check IDs other than the four that xz defines, and no filter chains
#   of more than three filters.

include("xz/xz.fan")

<streams> ::= <stream> (<stream_padding> <stream>){0,2} <stream_padding>?
<stream_padding> ::= rb'(\x00\x00\x00\x00){1,8}'

<stream> ::= <check_id> <block>{0,3}

<block> ::= <filters> <sizes>? <header_padding>? <dict_prop> <payload> <chunks>?
<payload> ::= <repeat> <data> | <noise>
<noise> ::= b'N' <byte>{4}

# LZMA2 data in this many uncompressed chunks (only in blocks of LZMA2 alone)
<chunks> ::= rb'[\x02-\x04]'
# More words of zero padding in the block header (at most 255 in all)
<header_padding> ::= b'P' <header_words>
<header_words> ::= rb'[\x01-\xf0]'

<filters> ::= <lzma2> | <delta> <lzma2> | <bcj> <lzma2> | <bcj> <delta> <lzma2>
<bcj> ::= b'B' <bcj_id>
<bcj_id> ::= b'\x04' | b'\x05' | b'\x06' | b'\x07' | b'\x08' | b'\x09'

# 4 KiB (0) to 48 MiB (27)
<dict_prop> ::= rb'[\x00-\x1b]'
