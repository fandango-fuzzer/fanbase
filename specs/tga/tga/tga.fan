# Truevision TGA images: true-colour of 16, 24 or 32 bits (with or without
# alpha), grayscale of 8 bits, and colour-mapped with 8-bit indices into a
# colour map of 16-, 24- or 32-bit entries that may start past entry 0;
# stored as they are or run-length encoded (types 1, 2, 3, 9, 10 and 11);
# 1 to 64 by 1 to 64 pixels, from the bottom left or the top left; an image
# ID of up to 32 characters; and TGA 1.0 (no footer) or TGA 2.0: the
# extension area (author, comments, date and time, job, software, key colour,
# aspect ratio, gamma, attributes), sometimes with a scan-line table, a
# postage stamp and a colour-correction table, and a developer area of 1 to 3
# tags, all found from the footer.
#
# Fandango draws the image as a draft (<tga_draft>), and tga_file() makes the
# file from it: it encodes the pixels in the depth the header says, encodes
# them in run-length packets that end with each row, and writes every count,
# size and offset, so that they agree with what they describe.
#
# tga_file() also makes what only tga-boundary draws: 15-bit colour and
# colour maps, 16-bit grayscale with alpha, 32 bits without alpha, images
# that start from the right, origins other than 0, packets that cross rows,
# large images, a footer with no extension area, and premultiplied alpha.
#
# TODO:
# * Image type 0 (no image data) and the Huffman and delta-compressed types
#   (32 and 33) are left out: few readers read them.

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


def _u16(n):
    return (n & 0xffff).to_bytes(2, 'little')


def _u32(n):
    return (n & 0xffffffff).to_bytes(4, 'little')


# The colours of n pixels, as (r, g, b, a): noise (n), runs of one colour
# (r), a gradient (g), or four colours (p)
def tga_colours(kind, seed, w, h):
    n = w * h
    rnd = _stream(seed or b'\x00', 4 * n + 256)
    if kind == 'n':
        return [tuple(rnd[4 * i:4 * i + 4]) for i in range(n)]
    if kind == 'r':
        out, k = [], 0
        while len(out) < n:
            out += [tuple(rnd[4 * k:4 * k + 4])] * (1 + rnd[128 + k % 128] % 40)
            k += 1
        return out[:n]
    if kind == 'g':
        return [((255 * x) // max(1, w - 1), (255 * y) // max(1, h - 1), (x * y) % 256, 255 - x % 2)
                for y in range(h) for x in range(w)]
    four = [tuple(rnd[4 * k:4 * k + 4]) for k in range(4)]
    return [four[rnd[64 + i % 192] % 4] for i in range(n)]


# One pixel in the bytes of its depth: 15 or 16 bits (A RRRRR GGGGG BBBBB,
# little-endian), 24 (B G R), 32 (B G R A)
def tga_pixel(c, depth, alpha):
    if depth in (15, 16):
        a = 1 if (alpha and c[3] >= 128) else 0
        return _u16((a << 15) | (c[0] >> 3) << 10 | (c[1] >> 3) << 5 | (c[2] >> 3))
    if depth == 24:
        return bytes([c[2], c[1], c[0]])
    return bytes([c[2], c[1], c[0], c[3]])


# Run-length packets: a run of 2 to 128 equal pixels, or 1 to 128 pixels as
# they are; with `rows`, no packet goes past the end of a row. Returns the
# packets and where each row starts in them.
def tga_rle(units, w, rows=True):
    out, starts = bytearray(), []
    lines = [units[y:y + w] for y in range(0, len(units), w)] if rows else [units]
    for line in lines:
        starts.append(len(out))
        i = 0
        while i < len(line):
            run = 1
            while i + run < len(line) and run < 128 and line[i + run] == line[i]:
                run += 1
            if run >= 2:
                out.append(0x80 | (run - 1))
                out += line[i]
                i += run
                continue
            raw = 1
            while i + raw < len(line) and raw < 128 and not (i + raw + 1 < len(line) and line[i + raw] == line[i + raw + 1]):
                raw += 1
            out.append(raw - 1)
            out += b''.join(line[i:i + raw])
            i += raw
    return bytes(out), starts


def _text(node, size):
    """A NUL-terminated field of `size` bytes."""
    t = bytes(node)[:size - 1] if node is not None else b''
    return t + b'\x00' * (size - len(t))


# The extension area (495 bytes), with the offsets of what it points to
def tga_ext(x, alpha, cc_off, stamp_off, scan_off, attributes=None):
    d = bytes(_find(x, '<when>'))
    date = [1 + d[0] % 12, 1 + d[1] % 28, 1980 + d[2] % 60, d[3] % 24, d[4] % 60, d[5] % 60]
    j = bytes(_find(x, '<job_time>'))
    ver = bytes(_find(x, '<version>'))
    ratio = bytes(_find(x, '<ratio>'))
    out = _u16(495) + _text(_find(x, '<author>'), 41)
    lines = [bytes(c) for c in _all(x, '<comment_line>')]
    out += b''.join(_text(None, 81) if k >= len(lines) else (lines[k][:80] + b'\x00' * (81 - len(lines[k][:80]))) for k in range(4))
    out += b''.join(_u16(v) for v in date)
    out += _text(_find(x, '<job>'), 41)
    out += _u16(j[0] * 256 + j[1]) + _u16(j[2] % 60) + _u16(j[3] % 60)
    out += _text(_find(x, '<software>'), 41)
    out += _u16(ver[0] * 256 + ver[1]) + bytes([ver[2]])
    out += bytes(_find(x, '<key_colour>'))
    out += _u16(1 + ratio[0]) + _u16(1 + ratio[1]) + _u16(1 + ratio[2]) + _u16(1 + ratio[3] % 10)
    out += _u32(cc_off) + _u32(stamp_off) + _u32(scan_off)
    out += bytes([(3 if alpha else 0) if attributes is None else attributes])
    return out


# Large images: one row of 65,535, one column of 4,096, 256x256, and 128x2
# (run-length packets of exactly 128)
_BIG = {b'R': (65535, 1), b'C': (1, 4096), b'S': (256, 256), b'M': (128, 2)}

# Origin: bottom left (b), top left (t), bottom right (r), top right (R)
_ORIGIN = {b'b': 0x00, b't': 0x20, b'r': 0x10, b'R': 0x30}


def tga_file(draft):
    ident = bytes(_find(draft, '<ident>'))
    big = _find(draft, '<big_size>')
    if big is not None:
        w, h = _BIG[bytes(big)]
    else:
        w, h = bytes(_find(draft, '<width>'))[0], bytes(_find(draft, '<height>'))[0]
    origin = _ORIGIN[bytes(_find(draft, '<origin>'))]
    packing = bytes(_find(draft, '<packing>'))
    kind = bytes(_find(draft, '<kind>')).decode()
    # A large image is drawn in runs and run-length encoded, so that its
    # file stays small
    if w * h > 4096:
        kind, packing = 'r', (packing if packing != b'r' else b'l')
    rle = packing != b'r'
    colours = tga_colours(kind, bytes(_find(draft, '<seed>')), w, h)
    image = _kids(_find(draft, '<image>'))[0]
    name = str(image.symbol)
    cmap, cm_first, cm_len, cm_entry, alpha_bits = b'', 0, 0, 0, 0
    if name == '<truecolour>':
        d = bytes(_find(image, '<tc_depth>'))
        # 32x: 32 bits of which the alpha byte is said to be unused
        depth, alpha = {b'15': (15, False), b'16': (16, False), b'16a': (16, True), b'24': (24, False),
                        b'32': (32, True), b'32x': (32, False)}[d]
        alpha_bits = (1 if depth == 16 else 8) if alpha else 0
        units = [tga_pixel(c, depth, alpha) for c in colours]
        imgtype = 10 if rle else 2
    elif name == '<grayscale>':
        gray = [(c[0] * 3 + c[1] * 6 + c[2]) // 10 for c in colours]
        if bytes(image) == b'GA':
            depth, alpha, alpha_bits = 16, True, 8
            units = [bytes([g, c[3]]) for g, c in zip(gray, colours)]
        else:
            depth, alpha = 8, False
            units = [bytes([g]) for g in gray]
        imgtype = 11 if rle else 3
    else:
        depth, alpha = 8, False
        cm_entry = int(bytes(_find(image, '<cm_entry>')))
        cm_first = bytes(_find(image, '<cm_first>'))[0] % 16
        cm_len = 1 + bytes(_find(image, '<cm_size>'))[0] % (256 - cm_first)
        entries = _stream(bytes(_find(draft, '<seed>')) + b'map', 4 * cm_len)
        cmap = b''.join(tga_pixel(tuple(entries[4 * k:4 * k + 4]), cm_entry, cm_entry == 32) for k in range(cm_len))
        units = [bytes([cm_first + (c[0] + 7 * c[1]) % cm_len]) for c in colours]
        imgtype = 9 if rle else 1
    if rle:
        data, starts = tga_rle(units, w, rows=packing == b'l')
    else:
        data, starts = b''.join(units), [w * len(units[0]) * y for y in range(h)]
    xy = _find(draft, '<xy>')
    x0, y0 = (int.from_bytes(bytes(xy)[0:2], 'little'), int.from_bytes(bytes(xy)[2:4], 'little')) if xy is not None else (0, 0)
    header = bytes([len(ident), 1 if cmap else 0, imgtype]) + _u16(cm_first) + _u16(cm_len) + bytes([cm_entry])
    header += _u16(x0) + _u16(y0) + _u16(w) + _u16(h) + bytes([depth, alpha_bits | origin])
    body = header + ident + cmap
    data_at = len(body)
    body += data
    if _find(draft, '<footer_only>') is not None:
        return body + _u32(0) + _u32(0) + b'TRUEVISION-XFILE.\x00'
    tail = _find(draft, '<tga2>')
    if tail is None:
        return body
    # TGA 2.0: developer area, extension area, what it points to, footer
    dev_off = 0
    tags = _all(tail, '<tag>')
    if tags:
        entries = []
        for t in tags:
            payload = bytes(_find(t, '<tag_data>'))
            entries.append((32768 + bytes(_find(t, '<tag_id>'))[0], len(body), len(payload)))
            body += payload
        dev_off = len(body)
        body += _u16(len(entries)) + b''.join(_u16(i) + _u32(o) + _u32(s) for i, o, s in entries)
    ext_off = len(body)
    after = ext_off + 495
    scan_off = stamp_off = cc_off = 0
    extra = b''
    # A scan-line table only where every row starts a packet
    if _find(tail, '<scan_table>') is not None and len(starts) == h:
        scan_off = after + len(extra)
        extra += b''.join(_u32(data_at + s) for s in starts)
    stamp = _find(tail, '<stamp>')
    if stamp is not None:
        sw, sh = 1 + bytes(stamp)[0] % 8, 1 + bytes(stamp)[1] % 8
        stamp_off = after + len(extra)
        extra += bytes([sw, sh]) + b''.join(units[(y % h) * w + (x % w)] for y in range(sh) for x in range(sw))
    if _find(tail, '<cc_table>') is not None:
        cc_off = after + len(extra)
        extra += b''.join(_u16(65535) + _u16(k * 257) + _u16(k * 257) + _u16(k * 257) for k in range(256))
    attr = _find(tail, '<attributes>')
    body += tga_ext(_find(tail, '<ext>'), alpha_bits > 0, cc_off, stamp_off, scan_off,
                    bytes(attr)[0] if attr is not None else None) + extra
    return body + _u32(ext_off) + _u32(dev_off) + b'TRUEVISION-XFILE.\x00'


<start> ::= <tga>
<tga> ::= <tga_file> := tga_file(<tga_draft>)
<tga_file> ::= rb'(?s).+'

# The draft: what tga_file() makes the file from
<tga_draft> ::= <ident> <image> <packing> <width> <height> <origin> <kind> <seed> <ending>
<ident> ::= rb'[\x20-\x7e]{0,32}'
<image> ::= <truecolour> | <grayscale> | <colour_mapped>
# 16 bits without or with an alpha bit, 24 bits, 32 bits with alpha
<truecolour> ::= b'T' <tc_depth>
<tc_depth> ::= b'16' | b'16a' | b'24' | b'32'
<grayscale> ::= b'G'
# Entries of 16, 24 or 32 bits; the map starts at entry 0 to 15 and has 1 to
# 256 entries (no more than 256 in all)
<colour_mapped> ::= b'M' <cm_entry> <cm_first> <cm_size>
<cm_entry> ::= b'16' | b'24' | b'32'
<cm_first> ::= b'\x00' | <byte>
<cm_size> ::= <byte>
# Raw (r) or run-length (l)
<packing> ::= b'r' | b'l'
<width> ::= rb'[\x01-\x40]'
<height> ::= rb'[\x01-\x40]'
# From the bottom left (b) or the top left (t)
<origin> ::= b'b' | b't'
<kind> ::= b'n' | b'r' | b'g' | b'p'
<seed> ::= <byte>{1,8}

<ending> ::= <tga1> | <tga2>
<tga1> ::= b'1'
<tga2> ::= b'2' <ext> <dev>? <scan_table>? <stamp>? <cc_table>?
<ext> ::= <author> b'|' <comment_line>{0,4} b'|' <when> <job> b'|' <job_time> <software> b'|' <version> <key_colour> <ratio>
<author> ::= rb'[\x20-\x7e]{0,40}'
<comment_line> ::= rb'[\x20-\x7e]{0,80}' b'\n'
<when> ::= <byte>{6}
<job> ::= rb'[\x20-\x7e]{0,40}'
<job_time> ::= <byte>{4}
<software> ::= rb'[\x20-\x7e]{0,40}'
# Version number times 100, and a letter (or a space)
<version> ::= <byte> <byte> rb'[ a-z]'
<key_colour> ::= <byte>{4}
# Pixel aspect ratio and gamma, as numerator and denominator
<ratio> ::= <byte>{4}
<dev> ::= <tag>{1,3}
<tag> ::= <tag_id> <tag_data>
<tag_id> ::= <byte>
<tag_data> ::= <byte>{0,24}
<scan_table> ::= b'S'
<stamp> ::= <byte> <byte>
<cc_table> ::= b'C'

<byte> ::= rb'[\x00-\xff]'
