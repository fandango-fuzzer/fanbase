# Windows icons and cursors (.ico, .cur): the directory (type 1 for an icon,
# 2 for a cursor, and how many images), one entry for each of 1 to 4 images
# (width, height, colour count, planes and bit count, or the hotspot of a
# cursor, size and offset), and the images: device-independent bitmaps of 1,
# 4, 8, 24 or 32 bits (header with twice the height, palette, colour bitmap
# and AND mask, rows bottom up and padded to four bytes) or PNG images (gray,
# RGB, palette with or without tRNS, gray with alpha, RGBA; every row filter).
# Images are 1 to 64 pixels wide and high, square or not.
#
# Fandango draws the icon as a draft (<ico_draft>), and ico_file() makes the
# file from it: it encodes each image, and writes the sizes and offsets of
# the directory, so that they agree with the images.
#
# ico_file() also makes what only ico-boundary draws: 16-bit bitmaps,
# palettes of fewer colours than the depth allows, 256x256 images (written as
# 0 in the directory), 16-bit and interlaced PNG, and directory entries with
# a plane and bit count of 0. An image of more than 4,096 pixels is drawn in
# runs of one colour, its bitmap has at most 4 bits and its PNG is an 8-bit
# palette image, not interlaced, so that the file stays small and quick to
# make (Fandango keeps many drafts and their files at once).
#
# TODO:
# * Entries whose width, height or bit count disagree with their image, and
#   images that overlap or lie past the end of the file, are left out:
#   readers differ on them by design.

import hashlib
import zlib


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


def _parts(node, names):
    """The symbols under `node` called one of `names`, in file order."""
    if str(node.symbol) in names:
        return [node]
    found = []
    for c in _kids(node):
        found += _parts(c, names)
    return found


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


def _u16(n):
    return (n & 0xffff).to_bytes(2, 'little')


def _u32(n):
    return (n & 0xffffffff).to_bytes(4, 'little')


# The colours of the pixels, as (r, g, b, a), row by row from the top: noise
# (n), runs of one colour (r), a gradient with a transparent corner (g), or
# four colours (p)
def ico_colours(kind, seed, w, h):
    n = w * h
    rnd = _stream(seed or b'\x00', 4 * n + 256)
    if kind == 'n':
        return [tuple(rnd[4 * i:4 * i + 4]) for i in range(n)]
    if kind == 'r':
        out, k = [], 0
        while len(out) < n:
            out += [tuple(rnd[4 * k:4 * k + 4])] * (1 + rnd[128 + k % 128] % 20)
            k += 1
        return out[:n]
    if kind == 'g':
        return [((255 * x) // max(1, w - 1), (255 * y) // max(1, h - 1), 128, 0 if x + y < 3 else 255)
                for y in range(h) for x in range(w)]
    four = [tuple(rnd[4 * k:4 * k + 4]) for k in range(4)]
    return [four[rnd[64 + i % 192] % 4] for i in range(n)]


# --- bitmaps

# The pixels packed in a row of `bpp` bits each, padded to four bytes
def _row_bits(values, bpp):
    out, acc, nbits = bytearray(), 0, 0
    for v in values:
        acc = (acc << bpp) | v
        nbits += bpp
        while nbits >= 8:
            nbits -= 8
            out.append((acc >> nbits) & 0xff)
    if nbits:
        out.append((acc << (8 - nbits)) & 0xff)
    return bytes(out) + b'\x00' * ((-len(out)) % 4)


# A bitmap as an icon holds it: BITMAPINFOHEADER with twice the height, the
# palette (of `colours` entries, or none), the colour bitmap and the AND mask
# (1 where the pixel is transparent), both bottom up
def ico_bitmap(px, w, h, bpp, colours):
    rows = [px[y * w:(y + 1) * w] for y in range(h)][::-1]
    palette = b''
    if bpp <= 8:
        pal = []
        for c in px:
            if c[:3] not in pal and len(pal) < colours:
                pal.append(c[:3])
        pal += [(0, 0, 0)] * (colours - len(pal))
        palette = b''.join(bytes([b, g, r, 0]) for r, g, b in pal)
        nearest = {}
        for c in px:
            if c[:3] not in nearest:
                nearest[c[:3]] = min(range(colours), key=lambda k: sum(abs(pal[k][i] - c[i]) for i in range(3)))
        xor = b''.join(_row_bits([nearest[c[:3]] for c in row], bpp) for row in rows)
    elif bpp == 16:
        xor = b''.join(b''.join(_u16((c[0] >> 3) << 10 | (c[1] >> 3) << 5 | (c[2] >> 3)) for c in row)
                       + b'\x00' * ((-2 * w) % 4) for row in rows)
    elif bpp == 24:
        xor = b''.join(b''.join(bytes([c[2], c[1], c[0]]) for c in row) + b'\x00' * ((-3 * w) % 4) for row in rows)
    else:
        xor = b''.join(b''.join(bytes([c[2], c[1], c[0], c[3]]) for c in row) for row in rows)
    mask = b''.join(_row_bits([1 if c[3] < 128 else 0 for c in row], 1) for row in rows)
    clr_used = colours if (bpp <= 8 and colours < (1 << bpp)) else 0
    header = _u32(40) + _u32(w) + _u32(2 * h) + _u16(1) + _u16(bpp) + _u32(0) + _u32(len(xor) + len(mask))
    header += _u32(0) + _u32(0) + _u32(clr_used) + _u32(0)
    return header + palette + xor + mask


# --- PNG

def _chunk(kind, data):
    return len(data).to_bytes(4, 'big') + kind + data + (zlib.crc32(kind + data) & 0xffffffff).to_bytes(4, 'big')


def _paeth(a, b, c):
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    return b if pb <= pc else c


# One row with filter `f` (0 none, 1 Sub, 2 Up, 3 Average, 4 Paeth)
def _filter(row, prev, f, bpp):
    out = bytearray([f])
    for i, x in enumerate(row):
        a = row[i - bpp] if i >= bpp else 0
        b = prev[i] if prev else 0
        c = prev[i - bpp] if (prev and i >= bpp) else 0
        pred = (0, a, b, (a + b) // 2, _paeth(a, b, c))[f]
        out.append((x - pred) % 256)
    return bytes(out)


# The rows of one pass, filtered: filter `filters[y % len(filters)]` for row y
def _scanlines(rows, bpp, filters):
    out, prev = b'', None
    for y, row in enumerate(rows):
        out += _filter(row, prev, filters[y % len(filters)], bpp)
        prev = row
    return out


_ADAM7 = ((0, 0, 8, 8), (4, 0, 8, 8), (0, 4, 4, 8), (2, 0, 4, 4), (0, 2, 2, 4), (1, 0, 2, 2), (0, 1, 1, 2))


# A PNG of colour type `ctype`: 0 gray, 2 RGB, 3 palette (with tRNS if
# `trns`), 4 gray and alpha, 6 RGBA; 8 or 16 bits; interlaced or not
def ico_png(px, w, h, ctype, filters, depth=8, interlace=False, trns=False):
    extra = b''
    if ctype == 3:
        pal = []
        for c in px:
            if c not in pal and len(pal) < 256:
                pal.append(c)
        index = {c: k for k, c in enumerate(pal)}
        samples = [[index.get(c, 0)] for c in px]
        extra = _chunk(b'PLTE', b''.join(bytes(c[:3]) for c in pal))
        if trns:
            extra += _chunk(b'tRNS', bytes(c[3] for c in pal))
        depth = 8
    else:
        def gray(c):
            return (c[0] * 3 + c[1] * 6 + c[2]) // 10
        pick = {0: lambda c: [gray(c)], 2: lambda c: list(c[:3]), 4: lambda c: [gray(c), c[3]], 6: lambda c: list(c)}[ctype]
        samples = [pick(c) for c in px]
    width = 2 if depth == 16 else 1
    bpp = len(samples[0]) * width

    def enc(s):
        return b''.join((v * 257).to_bytes(2, 'big') if width == 2 else bytes([v]) for v in s)
    if interlace:
        raw = b''
        for x0, y0, dx, dy in _ADAM7:
            rows = [b''.join(enc(samples[y * w + x]) for x in range(x0, w, dx)) for y in range(y0, h, dy)]
            rows = [r for r in rows if r]
            raw += _scanlines(rows, bpp, filters)
    else:
        rows = [b''.join(enc(samples[y * w + x]) for x in range(w)) for y in range(h)]
        raw = _scanlines(rows, bpp, filters)
    ihdr = w.to_bytes(4, 'big') + h.to_bytes(4, 'big') + bytes([depth, ctype, 0, 0, 1 if interlace else 0])
    return b'\x89PNG\r\n\x1a\n' + _chunk(b'IHDR', ihdr) + extra + _chunk(b'IDAT', zlib.compress(raw)) + _chunk(b'IEND', b'')


# --- the file

def ico_file(draft):
    cursor = bytes(_find(draft, '<dir_type>')) == b'c'
    entries, images = [], []
    for e in _parts(draft, ('<entry>', '<tiny_entry>')):
        size = bytes(_find(e, '<icon_size>') or _find(e, '<tiny_size>'))
        w, h = (256, 256) if size == b'big' else (size[0], size[-1])
        kind = bytes(_find(e, '<kind>')).decode()
        large = w * h > 4096
        if large:
            kind = 'r'
        px = ico_colours(kind, bytes(_find(e, '<seed>')), w, h)
        bitmap = _find(e, '<bitmap>')
        if bitmap is not None:
            bpp = int(bytes(_find(bitmap, '<bpp>')))
            if large:
                bpp = min(bpp, 4)
            few = _find(bitmap, '<few_colours>')
            colours = (1 << bpp) if bpp <= 8 else 0
            if few is not None and bpp <= 8:
                colours = 1 + bytes(few)[0] % colours
            data = ico_bitmap(px, w, h, bpp, colours)
            count = colours if (bpp <= 8 and colours < 256) else 0
        else:
            p = _find(e, '<png>')
            ctype = 3 if large else int(bytes(_find(p, '<ctype>')))
            filters = list(bytes(_find(p, '<filters>')))
            filters = [f % 5 for f in filters]
            data = ico_png(px, w, h, ctype, filters,
                           depth=16 if (_find(p, '<deep>') is not None and not large) else 8,
                           interlace=_find(p, '<interlaced>') is not None and not large,
                           trns=_find(p, '<trns>') is not None)
            bpp, count = 32, 0
        if cursor:
            hot = bytes(_find(e, '<hotspot>'))
            a, b = hot[0] % w, hot[1] % h
        elif _find(e, '<dir_zero>') is not None:
            a, b, count = 0, 0, 0
        else:
            a, b = 1, bpp
        entries.append((w, h, count, a, b, data))
    offset = 6 + 16 * len(entries)
    out = _u16(0) + _u16(2 if cursor else 1) + _u16(len(entries))
    for w, h, count, a, b, data in entries:
        out += bytes([w % 256, h % 256, count, 0]) + _u16(a) + _u16(b) + _u32(len(data)) + _u32(offset)
        offset += len(data)
    return out + b''.join(e[5] for e in entries)


<start> ::= <ico>
<ico> ::= <ico_file> := ico_file(<ico_draft>)
<ico_file> ::= rb'(?s).+'

# The draft: what ico_file() makes the file from
<ico_draft> ::= <dir_type> <entry>{1,4}
# An icon (i) or a cursor (c)
<dir_type> ::= b'i' | b'c'
<entry> ::= <icon_size> <image> <kind> <seed> <hotspot>
# Square of a usual size, or any width and height from 1 to 64
<icon_size> ::= b'\x10' | b'\x18' | b'\x20' | b'\x30' | <side> <side>
<side> ::= rb'[\x01-\x40]'
<image> ::= <bitmap> | <png>
<bitmap> ::= b'B' <bpp>
<bpp> ::= b'1' | b'4' | b'8' | b'24' | b'32'
# Gray, RGB, palette, gray and alpha, RGBA; the filter of each row in turn
<png> ::= b'P' <ctype> <trns>? <filters>
<ctype> ::= b'0' | b'2' | b'3' | b'4' | b'6'
<trns> ::= b't'
<filters> ::= rb'[\x00-\xff]{1,5}'
<kind> ::= b'n' | b'r' | b'g' | b'p'
<seed> ::= rb'[\x00-\xff]{1,8}'
# Where a cursor points (taken within the image)
<hotspot> ::= rb'[\x00-\xff]{2}'

<byte> ::= rb'[\x00-\xff]'
