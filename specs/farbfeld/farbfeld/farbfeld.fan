# farbfeld images: the magic "farbfeld", width and height (32-bit big-endian)
# and then every pixel, row by row, as red, green, blue and alpha of 16 bits
# each, big-endian. Images of 1 to 64 by 1 to 64 pixels of noise, a
# gradient, one colour or the extreme values (0, 1, 0x7fff, 0x8000, 0xfffe,
# 0xffff), and at the edges: 1x1, one row or one column of 1,024 pixels,
# and 100x100.
#
# Fandango draws the image as a draft (<ff_draft>), and farbfeld_file()
# writes the pixels it asks for, so that there are always width times height
# of them.
#
# TODO:
# * Images of no pixels (a width or height of 0), and data short of or past
#   the pixels, are left out: readers differ on them.

import hashlib


def _kids(node):
    return [c for c in node.children if c.is_non_terminal]


def _find(node, name):
    """The first symbol called `name` under `node` (or `node` itself), or None."""
    if str(node.symbol) == name:
        return node
    for c in _kids(node):
        found = _find(c, name)
        if found is not None:
            return found
    return None


def _stream(seed, n):
    """n bytes made from seed (SHA-256 in counter mode)."""
    out = b''
    while len(out) < n:
        out += hashlib.sha256(seed + len(out).to_bytes(4, 'little')).digest()
    return out[:n]


_EXTREMES = (0, 1, 0x7fff, 0x8000, 0xfffe, 0xffff)


# The pixels: noise (n), a gradient (g), one colour (f), or extreme values (x)
def ff_pixels(kind, seed, w, h):
    n = w * h
    if kind == 'n':
        return _stream(seed or b'\x00', 8 * n)
    if kind == 'f':
        return _stream(seed or b'\x00', 8) * n
    if kind == 'x':
        rnd = _stream(seed or b'\x00', 4 * n)
        return b''.join(_EXTREMES[b % 6].to_bytes(2, 'big') for b in rnd)
    out = bytearray()
    for y in range(h):
        for x in range(w):
            r = (x * 65535 // max(1, w - 1)) & 0xffff
            g = (y * 65535 // max(1, h - 1)) & 0xffff
            out += r.to_bytes(2, 'big') + g.to_bytes(2, 'big') + ((r + g) // 2).to_bytes(2, 'big') + b'\xff\xff'
    return bytes(out)


def farbfeld_file(draft):
    size = _kids(_find(draft, '<size>'))[0]
    if str(size.symbol) == '<small>':
        w, h = bytes(_find(size, '<side>'))[0], bytes(_find(size, '<side2>'))[0]
    else:
        w, h = {b'1': (1, 1), b'r': (1024, 1), b'c': (1, 1024), b's': (100, 100)}[bytes(size)]
    kind = bytes(_find(draft, '<kind>')).decode()
    pixels = ff_pixels(kind, bytes(_find(draft, '<seed>')), w, h)
    return b'farbfeld' + w.to_bytes(4, 'big') + h.to_bytes(4, 'big') + pixels


<start> ::= <farbfeld>
<farbfeld> ::= <farbfeld_file> := farbfeld_file(<ff_draft>)
<farbfeld_file> ::= rb'(?s).+'

# The draft: what farbfeld_file() makes the file from
<ff_draft> ::= <size> <kind> <seed>
<size> ::= <small> | <edge_size>
<small> ::= <side> <side2>
<side> ::= rb'[\x01-\x40]'
<side2> ::= rb'[\x01-\x40]'
# 1x1, one row (r) or one column (c) of 1,024, or 100x100 (a file of 80 KB:
# Fandango keeps many drafts and their files at once)
<edge_size> ::= b'1' | b'r' | b'c' | b's'
<kind> ::= b'n' | b'g' | b'f' | b'x'
<seed> ::= <byte>{1,8}
<byte> ::= rb'[\x00-\xff]'
