# QOI images at the edges, besides those of qoi: a 1x1 image of each of the
# six chunks alone; one row or one column of 256, 1,000 or 4,096 pixels; a
# large image of one colour (512x512, 1024x256 or 64x4096: almost nothing
# but QOI_OP_RUN); runs of every length from 1 to 62, across rows; DIFF and
# LUMA at the ends of their ranges and around the wrap from 255 to 0, and
# just past them; colours that fall into the same slot of the index; and
# alpha that changes, is 0 under changing colours, or is there in an image
# whose header says three channels (the header only informs).
#
# TODO:
# * Chunks that make more or fewer pixels than the header says, data after
#   the end marker, a missing end marker, and channels or colorspace values
#   other than those of the specification are left out: readers differ on
#   them by design.

include("qoi/qoi.fan")


def _plus(p, d):
    return ((p[0] + d[0]) % 256, (p[1] + d[1]) % 256, (p[2] + d[2]) % 256, p[3])


# Pixels that walk DIFF and LUMA to the ends of their ranges, wrap from 255
# to 0 and back, and step just past each range (which takes QOI_OP_RGB)
def qoi_wrap_pixels(base):
    seq = [(255, 0, base[2], 255)]
    for d in ((1, 1, 1), (-2, -2, -2), (1, -2, 0), (0, 1, -2), (-1, 0, 1)):
        seq.append(_plus(seq[-1], d))
    for vg in (-32, 31):
        for dr in (-8, 7):
            for db in (-8, 7):
                seq.append(_plus(seq[-1], (vg + dr, vg, vg + db)))
    for d in ((2, 0, 0), (-3, 0, 0), (32, 32, 32), (8, 0, 0), (0, 0, -9)):
        seq.append(_plus(seq[-1], d))
    return seq


# Pixels drawn from colours of which six fall into the same slot of the index
# (adding 64 to red, or to green, keeps r*3 + g*5 + b*7 + a*11 mod 64)
def qoi_collide_pixels(seed, n):
    rnd = _stream(seed or b'\x00', n + 8)
    a = (rnd[0], rnd[1], rnd[2], 255)
    colours = [a, _plus(a, (64, 0, 0)), _plus(a, (128, 0, 0)), _plus(a, (0, 64, 0)),
               _plus(a, (64, 64, 0)), _plus(a, (192, 128, 0)), (rnd[3], rnd[4], rnd[5], 255), (0, 0, 0, 0)]
    return [colours[rnd[8 + i] % len(colours)] for i in range(n)]


# Pixels whose alpha is 0, 1, 128 or 255, with colours that change under alpha 0
def qoi_alpha_pixels(seed, n):
    rnd = _stream(seed or b'\x00', 5 * n)
    return [(rnd[5 * i], rnd[5 * i + 1], rnd[5 * i + 2], (0, 1, 128, 255)[rnd[5 * i + 3] % 4]) for i in range(n)]


# The rows after the pixels, filled with the last colour
def _fill(px, w):
    h = -(-len(px) // w)
    return px + [px[-1]] * (w * h - len(px)), h


def qoi_edge_file(draft):
    channels = bytes(_find(draft, '<channels>'))[0]
    colorspace = bytes(_find(draft, '<colorspace>'))[0]
    edge = _kids(_find(draft, '<edge>'))[0]
    name = str(edge.symbol)
    if name == '<e_single>':
        w, h, chunks = 1, 1, bytes(_find(edge, '<chunk1>'))
    elif name == '<e_line>':
        n = int.from_bytes(bytes(_find(edge, '<line_len>')), 'big')
        w, h = (n, 1) if bytes(_find(edge, '<line_dir>')) == b'r' else (1, n)
        kind = bytes(_find(edge, '<kind>')).decode()
        chunks = qoi_encode(qoi_pixels(kind, bytes(_find(edge, '<seed>')), w, h, channels))
    elif name == '<e_flat>':
        w, h = {b's': (512, 512), b'm': (1024, 256), b'l': (64, 4096)}[bytes(_find(edge, '<flat_size>'))]
        c = bytes(_find(edge, '<colour>'))
        p = (c[0], c[1], c[2], c[3] if channels == 4 else 255)
        # The first pixel takes a chunk of its own, unless it is the colour
        # a decoder starts from; every other pixel is a run
        if p == (0, 0, 0, 255):
            chunks = qoi_runs(w * h)
        else:
            chunks = qoi_encode([p]) + qoi_runs(w * h - 1)
    else:
        w = bytes(_find(edge, '<width>'))[0]
        seed = bytes(_find(edge, '<seed>')) if _find(edge, '<seed>') is not None else b''
        if name == '<e_runs>':
            rnd = _stream(seed or b'\x00', 3 * 62)
            px = []
            for k in range(1, 63):
                px += [(rnd[3 * k - 3], rnd[3 * k - 2], rnd[3 * k - 1], 255)] * (k + 1)
        elif name == '<e_wrap>':
            px = qoi_wrap_pixels(bytes(_find(edge, '<colour>')))
        elif name == '<e_collide>':
            px = qoi_collide_pixels(seed, w * bytes(_find(edge, '<height>'))[0])
        else:
            px = qoi_alpha_pixels(seed, w * bytes(_find(edge, '<height>'))[0])
        px, h = _fill(px, w)
        chunks = qoi_encode(px)
    return qoi_header(w, h, channels, colorspace) + chunks + QOI_END


<start> ::= <qoi> | <qoi_edge>
<qoi_edge> ::= <qoi_edge_file> := qoi_edge_file(<edge_draft>)
<qoi_edge_file> ::= rb'(?s).+'

<edge_draft> ::= <channels> <colorspace> <edge>
<edge> ::= <e_single> | <e_line> | <e_flat> | <e_runs> | <e_wrap> | <e_collide> | <e_alpha>

# 1x1: one chunk, or a run of one pixel
<e_single> ::= b'1' <chunk1>
<chunk1> ::= <op_rgb> | <op_rgba> | <op_index> | <op_diff> | <op_luma> | b'\xc0'

# One row (r) or one column (c) of 256, 1,000 or 4,096 drawn pixels
<e_line> ::= b'L' <line_len> <line_dir> <kind> <seed>
<line_len> ::= b'\x01\x00' | b'\x03\xe8' | b'\x10\x00'
<line_dir> ::= b'r' | b'c'

# One colour: 512x512, 1024x256 or 64x4096
<e_flat> ::= b'F' <flat_size> <colour>
<flat_size> ::= b's' | b'm' | b'l'
<colour> ::= <byte>{4}

<e_runs> ::= b'R' <width> <seed>
<e_wrap> ::= b'W' <width> <colour>
<e_collide> ::= b'C' <width> <height> <seed>
<e_alpha> ::= b'A' <width> <height> <seed>
