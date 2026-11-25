# QOI (the Quite OK Image format): the 14-byte header (magic "qoif", width
# and height, 3 or 4 channels, sRGB or linear), the chunks, and the end
# marker of seven zero bytes and a one. An image is either drawn as pixels
# and encoded as qoi.h encodes it (so QOI_OP_RUN, INDEX, DIFF and LUMA come
# where an encoder puts them), or written out chunk by chunk (any of the six
# chunks, in any order). Images are 1 to 64 pixels wide.
#
# Fandango draws the image as a draft (<qoi_draft>), and qoi_file() makes
# the file from it: it encodes the drawn pixels, or counts the pixels of the
# written chunks and fills the last row with QOI_OP_RUN, and writes the
# height that the pixels need, so that the chunks always make exactly width
# times height pixels.
#
# TODO:
# * Chunks that make more or fewer pixels than the header says, and data
#   after the end marker, are left out: readers differ on them by design.

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


def _all(node, name):
    """Every symbol called `name` under `node`, in file order."""
    if str(node.symbol) == name:
        return [node]
    found = []
    for c in _kids(node):
        found += _all(c, name)
    return found


def _stream(seed, n):
    """n bytes made from seed (SHA-256 in counter mode)."""
    out = b''
    while len(out) < n:
        out += hashlib.sha256(seed + len(out).to_bytes(4, 'little')).digest()
    return out[:n]


# The pixels of a drawn image: noise, one colour with a few others, a
# gradient, or a handful of colours (so that QOI_OP_INDEX finds them again).
# With three channels every pixel is opaque, as qoi.h encodes it.
def qoi_pixels(kind, seed, w, h, channels):
    n = w * h
    rnd = _stream(seed or b'\x00', 8 * n + 64)
    px = []
    if kind == 'n':
        for i in range(n):
            px.append(tuple(rnd[4 * i:4 * i + 4]))
    elif kind == 'f':
        base = tuple(rnd[0:4])
        for i in range(n):
            px.append(tuple(rnd[64 + 4 * i:68 + 4 * i]) if rnd[4 * n + 64 + i] < 16 else base)
    elif kind == 'g':
        r0, g0, b0, sx, sy = rnd[0], rnd[1], rnd[2], rnd[3] % 5, rnd[4] % 40
        for y in range(h):
            for x in range(w):
                px.append(((r0 + sx * x) % 256, (g0 + sx * x + sy * y) % 256, (b0 + sy * y) % 256, 255 - (x % 3)))
    else:
        palette = [tuple(rnd[4 * k:4 * k + 4]) for k in range(2 + rnd[40] % 7)]
        for i in range(n):
            px.append(palette[rnd[64 + i] % len(palette)])
    if channels == 3:
        px = [(r, g, b, 255) for r, g, b, _ in px]
    return px


def _signed(v):
    return ((v + 128) % 256) - 128


# The chunks of the pixels, as qoi.h's encoder writes them
def qoi_encode(px):
    index = [(0, 0, 0, 0)] * 64
    prev = (0, 0, 0, 255)
    run = 0
    out = bytearray()
    for i, p in enumerate(px):
        if p == prev:
            run += 1
            if run == 62 or i == len(px) - 1:
                out.append(0xc0 | (run - 1))
                run = 0
            continue
        if run > 0:
            out.append(0xc0 | (run - 1))
            run = 0
        slot = (p[0] * 3 + p[1] * 5 + p[2] * 7 + p[3] * 11) % 64
        if index[slot] == p:
            out.append(slot)
        else:
            index[slot] = p
            if p[3] == prev[3]:
                vr, vg, vb = _signed(p[0] - prev[0]), _signed(p[1] - prev[1]), _signed(p[2] - prev[2])
                vg_r, vg_b = vr - vg, vb - vg
                if -3 < vr < 2 and -3 < vg < 2 and -3 < vb < 2:
                    out.append(0x40 | (vr + 2) << 4 | (vg + 2) << 2 | (vb + 2))
                elif -33 < vg < 32 and -9 < vg_r < 8 and -9 < vg_b < 8:
                    out += bytes([0x80 | (vg + 32), (vg_r + 8) << 4 | (vg_b + 8)])
                else:
                    out += bytes([0xfe, p[0], p[1], p[2]])
            else:
                out += bytes([0xff, p[0], p[1], p[2], p[3]])
        prev = p
    return bytes(out)


# How many pixels written chunks make: one each, a run as many as it says
def qoi_count(chunks):
    n, i = 0, 0
    while i < len(chunks):
        b = chunks[i]
        if b == 0xfe:
            i += 4
            n += 1
        elif b == 0xff:
            i += 5
            n += 1
        elif b >> 6 == 2:
            i += 2
            n += 1
        elif b >> 6 == 3:
            i += 1
            n += (b & 0x3f) + 1
        else:
            i += 1
            n += 1
    return n


# QOI_OP_RUN chunks for n more pixels of the last colour
def qoi_runs(n):
    out = b''
    while n > 0:
        k = min(n, 62)
        out += bytes([0xc0 | (k - 1)])
        n -= k
    return out


def qoi_header(w, h, channels, colorspace):
    return b'qoif' + w.to_bytes(4, 'big') + h.to_bytes(4, 'big') + bytes([channels, colorspace])


QOI_END = b'\x00' * 7 + b'\x01'


def qoi_file(draft):
    channels = bytes(_find(draft, '<channels>'))[0]
    colorspace = bytes(_find(draft, '<colorspace>'))[0]
    w = bytes(_find(draft, '<width>'))[0]
    drawn = _find(draft, '<drawn>')
    if drawn is not None:
        h = bytes(_find(drawn, '<height>'))[0]
        kind = bytes(_find(drawn, '<kind>')).decode()
        px = qoi_pixels(kind, bytes(_find(drawn, '<seed>')), w, h, channels)
        chunks = qoi_encode(px)
    else:
        chunks = b''.join(bytes(c) for c in _all(draft, '<chunk>'))
        n = qoi_count(chunks)
        h = -(-n // w)
        chunks += qoi_runs(w * h - n)
    return qoi_header(w, h, channels, colorspace) + chunks + QOI_END


<start> ::= <qoi>
<qoi> ::= <qoi_file> := qoi_file(<qoi_draft>)
<qoi_file> ::= rb'(?s).+'

# The draft: what qoi_file() makes the file from
<qoi_draft> ::= <channels> <colorspace> <width> <image>
<channels> ::= b'\x03' | b'\x04'
<colorspace> ::= b'\x00' | b'\x01'
<width> ::= rb'[\x01-\x40]'
<image> ::= <drawn> | <written>

# Pixels: noise (n), one colour and a few others (f), a gradient (g), or a
# handful of colours (p), 1 to 32 rows
<drawn> ::= <kind> <height> <seed>
<kind> ::= b'n' | b'f' | b'g' | b'p'
<height> ::= rb'[\x01-\x20]'
<seed> ::= <byte>{1,8}

# Chunks written out
<written> ::= <chunk>{1,48}
<chunk> ::= <op_rgb> | <op_rgba> | <op_index> | <op_diff> | <op_luma> | <op_run>
<op_rgb> ::= b'\xfe' <byte> <byte> <byte>
<op_rgba> ::= b'\xff' <byte> <byte> <byte> <byte>
<op_index> ::= rb'[\x00-\x3f]'
<op_diff> ::= rb'[\x40-\x7f]'
<op_luma> ::= rb'[\x80-\xbf]' <byte>
# 0xfe and 0xff are QOI_OP_RGB and QOI_OP_RGBA: a run is 1 to 62 pixels
<op_run> ::= rb'[\xc0-\xfd]'

<byte> ::= rb'[\x00-\xff]'
