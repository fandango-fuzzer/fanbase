# Radiance RGBE images (.hdr, .pic): the magic line (#?RADIANCE or #?RGBE),
# header lines (EXPOSURE, GAMMA, COLORCORR, PIXASPECT, PRIMARIES, VIEW,
# SOFTWARE, comments) with FORMAT=32-bit_rle_rgbe among them, the empty line,
# the resolution line (-Y height +X width), and the pixels: RGBE (a shared
# exponent for red, green and blue) made from colours of a high dynamic
# range, written flat or in the run-length scanlines that Radiance writes
# (2 2 and the width, then each of the four components in runs and dumps).
# Images of 1 to 128 by 1 to 32 pixels; run-length scanlines from width 8.
#
# Fandango draws the image as a draft (<hdr_draft>), and hdr_file() makes the
# file from it: it encodes the colours and the scanlines, and writes the
# resolution line, so that the pixels are as many as it says. In flat data
# no pixel is 1 1 1 n, and no row starts with 2 2 and a small third byte:
# readers take those for old and new run-length marks.
#
# hdr_file() also makes what only hdr-boundary draws: the XYZE format, no
# FORMAT line, the other seven orientations, old-style runs (1 1 1 n), rows
# of which only some are run-length encoded, rows of 4,096 pixels, and
# extreme exponents.
#
# TODO:
# * Pixels short of what the resolution line says are left out: readers
#   differ on them by design.

import hashlib
import math


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


# A colour as RGBE, as Radiance's float2rgbe writes it
def rgbe(r, g, b):
    v = max(r, g, b)
    if v < 1e-32:
        return bytes(4)
    m, e = math.frexp(v)
    f = m * 256.0 / v
    return bytes([min(255, int(r * f)), min(255, int(g * f)), min(255, int(b * f)), e + 128])


# The colours of the pixels, row by row from the top: noise over a range of
# exposures (n), runs of one colour (r), a gradient from dark to bright (g),
# or a sky with a sun (s)
def hdr_colours(kind, seed, w, h):
    n = w * h
    rnd = _stream(seed or b'\x00', 4 * n + 64)
    if kind == 'n':
        return [tuple(rnd[4 * i + k] / 255.0 * 2.0 ** (rnd[4 * i + 3] % 24 - 12) for k in range(3)) for i in range(n)]
    if kind == 'r':
        out, k = [], 0
        while len(out) < n:
            c = tuple(rnd[3 * k + j] / 64.0 for j in range(3))
            out += [c] * (1 + rnd[32 + k % 32] % 300)
            k += 1
        return out[:n]
    if kind == 'g':
        return [(2.0 ** (x / max(1, w - 1) * 16 - 8), 2.0 ** (y / max(1, h - 1) * 8 - 4), 0.5) for y in range(h) for x in range(w)]
    sx, sy = rnd[0] % w, rnd[1] % h
    return [(5000.0, 4800.0, 4000.0) if (x - sx) ** 2 + (y - sy) ** 2 < 3 else (0.2 + 0.4 * y / h, 0.4 + 0.3 * y / h, 0.9)
            for y in range(h) for x in range(w)]


# Flat pixels, kept from looking like run-length marks
def hdr_flat_row(px):
    out = []
    for i, p in enumerate(px):
        if p[0] == 1 and p[1] == 1 and p[2] == 1:
            p = bytes([1, 1, 2, p[3]])
        if i == 0 and p[0] == 2 and p[1] == 2 and p[2] < 128:
            p = bytes([2, 3, p[2], p[3]])
        out.append(p)
    return b''.join(out)


# One component of a scanline in runs (128 + n, value: n of one value, n up
# to 127) and dumps (n, values: n as they are, n up to 128), as Radiance's
# writer does: a run for four or more equal values
def _rle_component(values):
    out, i, n = bytearray(), 0, len(values)
    while i < n:
        run = 1
        while i + run < n and run < 127 and values[i + run] == values[i]:
            run += 1
        if run >= 4:
            out += bytes([128 + run, values[i]])
            i += run
            continue
        j = i
        while j < n and j - i < 128:
            k = 1
            while j + k < n and k < 4 and values[j + k] == values[j]:
                k += 1
            if k >= 4:
                break
            j += 1
        out += bytes([j - i]) + bytes(values[i:j])
        i = j
    return bytes(out)


def hdr_rle_row(px):
    w = len(px)
    out = bytes([2, 2, w >> 8, w & 0xff])
    for c in range(4):
        out += _rle_component([p[c] for p in px])
    return out


# Old-style runs: a pixel 1 1 1 n repeats the one before n times. (A second
# such pixel right after one would count 256 times as much, so a run is
# always followed by a pixel as it is.)
def hdr_old_rle_row(px):
    out, i, after_run = [px[0]], 1, False
    while i < len(px):
        run = 0
        while i + run < len(px) and px[i + run] == px[i - 1] and run < 255:
            run += 1
        if run >= 2 and not after_run:
            out.append(bytes([1, 1, 1, run]))
            i += run
            after_run = True
        else:
            after_run = False
            p = px[i]
            out.append(bytes([1, 1, 2, p[3]]) if (p[0] == 1 and p[1] == 1 and p[2] == 1) else p)
            i += 1
    return b''.join(out)


# The resolution line for each orientation: the first axis is the one the
# rows run along
_ORIENT = {b'-Y+X': '-Y {h} +X {w}', b'-Y-X': '-Y {h} -X {w}', b'+Y+X': '+Y {h} +X {w}', b'+Y-X': '+Y {h} -X {w}',
           b'+X-Y': '+X {w} -Y {h}', b'+X+Y': '+X {w} +Y {h}', b'-X-Y': '-X {w} -Y {h}', b'-X+Y': '-X {w} +Y {h}'}


def hdr_file(draft):
    big = _find(draft, '<big_size>')
    if big is not None:
        w, h = {b'L': (4096, 1), b'E': (8, 8), b'T': (4096, 2)}[bytes(big)]
    else:
        w, h = bytes(_find(draft, '<width>'))[0], bytes(_find(draft, '<height>'))[0]
    kind = bytes(_find(draft, '<kind>')).decode()
    # A large image is drawn in runs of one colour, so that it is quick to
    # make and, run-length encoded, small
    if w * h > 8192:
        kind = 'r'
    colours = hdr_colours(kind, bytes(_find(draft, '<seed>')), w, h)
    px = [rgbe(*c) for c in colours]
    extreme = _find(draft, '<extreme>')
    if extreme is not None:
        rnd = _stream(bytes(extreme), len(px))
        px = [bytes([p[0], p[1], p[2], (0, 1, 255, 254)[rnd[i] % 4]]) if rnd[i] < 64 else p for i, p in enumerate(px)]
    orient = _find(draft, '<orientation>')
    orient = bytes(orient) if orient is not None else b'-Y+X'
    rows_along_x = orient.startswith(b'-Y') or orient.startswith(b'+Y')
    line_len, lines = (w, h) if rows_along_x else (h, w)
    if not rows_along_x:
        px = [px[y * w + x] for x in range(w) for y in range(h)]
    encoding = bytes(_find(draft, '<encoding>'))
    data = b''
    for y in range(lines):
        row = px[y * line_len:(y + 1) * line_len]
        rle_ok = 8 <= line_len <= 32767
        if encoding == b'r' and rle_ok:
            data += hdr_rle_row(row)
        elif encoding == b'm' and rle_ok and y % 2 == 1:
            data += hdr_rle_row(row)
        elif encoding == b'o':
            data += hdr_old_rle_row(row)
        else:
            data += hdr_flat_row(row)
    head = bytes(_find(draft, '<magic>')) + b'\n'
    lines_before = [bytes(l) for l in _all(_find(draft, '<before>'), '<hline>')]
    lines_after = [bytes(l) for l in _all(_find(draft, '<after>'), '<hline>')]
    fmt = _find(draft, '<format>')
    fmt_line = [b'FORMAT=32-bit_rle_' + bytes(fmt) + b'\n'] if bytes(fmt) != b'none' else []
    head += b''.join(lines_before + fmt_line + lines_after) + b'\n'
    head += _ORIENT[orient].format(w=w, h=h).encode() + b'\n'
    return head + data


<start> ::= <hdr>
<hdr> ::= <hdr_file> := hdr_file(<hdr_draft>)
<hdr_file> ::= rb'(?s).+'

# The draft: what hdr_file() makes the file from
<hdr_draft> ::= <magic> <before> <format> <after> <width> <height> <encoding> <kind> <seed>
<magic> ::= b'#?RADIANCE' | b'#?RGBE'
<before> ::= <hline>{0,3}
<after> ::= <hline>{0,3}
<format> ::= b'rgbe'
<hline> ::= b'EXPOSURE=' <float> b'\n' | b'GAMMA=' <float> b'\n' \
          | b'COLORCORR=' <float> b' ' <float> b' ' <float> b'\n' \
          | b'PIXASPECT=' <float> b'\n' \
          | b'PRIMARIES=' <float> b' ' <float> b' ' <float> b' ' <float> b' ' <float> b' ' <float> b' ' <float> b' ' <float> b'\n' \
          | b'VIEW= -vtv -vp ' <float> b' ' <float> b' ' <float> b' -vd 0 1 0 -vu 0 0 1 -vh 45 -vv 45\n' \
          | b'SOFTWARE=' <text> b'\n' | b'# ' <text> b'\n'
<float> ::= rb'[0-9]{1,3}(\.[0-9]{1,4})?'
# Starts with a visible character: a value that is empty (or only spaces)
# is in hdr-boundary
<text> ::= rb'[\x21-\x7e][\x20-\x7e]{0,39}'
<width> ::= rb'[\x01-\x80]'
<height> ::= rb'[\x01-\x20]'
# Flat (f) or run-length scanlines (r, from width 8)
<encoding> ::= b'f' | b'r'
<kind> ::= b'n' | b'r' | b'g' | b's'
<seed> ::= rb'[\x00-\xff]{1,8}'
