# bzip2 files: one to three streams, each the four-byte header ("BZh" and a
# block size from 1 to 9) and the compressed blocks and end-of-stream marker
# that Python's bz2 module (libbzip2) makes from data of up to 900 bytes:
# empty, random, one byte repeated, or text. Past the header everything is
# packed bit by bit, so it comes from the compressor, and a where constraint
# decompresses each stream to check that header and body agree.
#
# TODO:
# * The data is drawn with `random`, not by Fandango.
# * Every stream is a single block: the data never fills even the smallest
#   block size (100 kB).

import bz2
import random


# The data a stream holds: empty, random bytes, one byte repeated (long runs
# go through bzip2's run-length stages), or text.
def random_plaintext():
    kind = random.randint(0, 3)
    if kind == 0:
        return b''
    if kind == 1:
        n = random.randint(1, 900)
        return bytes(random.randint(0, 255) for _ in range(n))
    if kind == 2:
        return bytes([random.randint(0, 255)]) * random.randint(1, 900)
    return (b'The quick brown fox 0123456789 ' * random.randint(1, 28))[:900]


# The compressed blocks and the end-of-stream marker, without the "BZh9"
# header the compressor puts in front. Data this small makes the same body at
# every block size, so any header in the grammar fits it.
def compressed_body():
    return bz2.compress(random_plaintext(), 9)[4:]


<start> ::= <bz2_file>

<bz2_file> ::= <stream>{1,3}

<stream> ::= <header> <body>
    where bz2.decompress(bytes(<header>) + bytes(<body>)) is not None

<header> ::= <magic> <version> <level>

<magic> ::= b'BZ'

# 'h' (Huffman coding); the old 'BZ0' streams are not made
<version> ::= b'h'

# The block size, in units of 100 kB
<level> ::= b'1' | b'2' | b'3' | b'4' | b'5' | b'6' | b'7' | b'8' | b'9'

<body> ::= <byte>* := compressed_body()
