# Adobe Photoshop documents (.psd): the header (8BPS, version 1, channels,
# height, width, depth, colour mode), the colour mode data (the palette of
# an indexed image, the duotone specification), image resources (resolution,
# version info, global angle, plug-in resources of any ID from 4000 to 4999),
# the layer and mask information, and the merged image. Every colour mode:
# bitmap (1 bit), grayscale, indexed, RGB, CMYK, multichannel, duotone and
# Lab, of 8 or 16 bits, with up to two alpha or spot channels where the mode
# has them; 1 to 64 by 1 to 64 pixels. Documents of 8 bits in grayscale,
# RGB, CMYK, Lab or duotone have 1 to 3 layers or none: each with its
# rectangle, a transparency channel or not, blend mode, opacity, flags, name
# (padded Pascal and Unicode, 'luni') and pixel data. Pixel data, of the
# layers and of the merged image, is raw or PackBits with the byte count of
# each row.
#
# Fandango draws the document as a draft (<psd_draft>), and psd_file() makes
# the file from it: it encodes the pixels of each channel and writes every
# length, count, rectangle and padding, so that they agree with the data.
#
# psd_file() also makes what only psd-boundary draws: 32-bit documents
# (grayscale and RGB),
# layers of 16 and 32-bit documents (in 'Lr16' and 'Lr32'), layer masks,
# group layers, empty layers, layers past the edges of the canvas, ZIP
# compression with and without prediction, the large document format (PSB),
# up to 56 channels (in at most 16x16 pixels when more than 8), a merged
# image said not to be the real one, an XMP packet, and resources of no
# data.
#
# TODO:
# * Image resources whose contents readers interpret (thumbnails, ICC
#   profiles, paths, XMP) are written only in psd-boundary, or not at all.

import hashlib
import struct
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


def _be(n, size):
    return (n % (1 << (8 * size))).to_bytes(size, 'big')


def _pad(data, align):
    return data + b'\x00' * ((-len(data)) % align)


def _pascal(text, align):
    """A Pascal string (length byte, then the text), padded to `align` bytes."""
    text = text[:255]
    return _pad(bytes([len(text)]) + text, align)


# --- pixels

# One channel of w x h samples of `depth` bits, row by row: noise (n), runs
# of one value (r), a gradient (g), or one value (f). Samples of 16 and 32
# bits are big-endian; 32-bit samples are floats from 0 to 1.
def psd_plane(kind, seed, w, h, depth):
    n = w * h
    rnd = _stream(seed or b'\x00', 2 * n + 64)
    if kind == 'n':
        vals = [rnd[2 * i] / 255.0 for i in range(n)]
    elif kind == 'r':
        vals, k = [], 0
        while len(vals) < n:
            vals += [rnd[k] / 255.0] * (1 + rnd[32 + k % 32] % 24)
            k += 1
        vals = vals[:n]
    elif kind == 'g':
        vals = [((x + y) % max(1, w + h - 1)) / max(1, w + h - 2) for y in range(h) for x in range(w)]
    else:
        vals = [rnd[0] / 255.0] * n
    rows = []
    for y in range(h):
        v = vals[y * w:(y + 1) * w]
        if depth == 1:
            bits = [1 if x >= 0.5 else 0 for x in v]
            row = bytearray((w + 7) // 8)
            for x, b in enumerate(bits):
                if b:
                    row[x // 8] |= 0x80 >> (x % 8)
            rows.append(bytes(row))
        elif depth == 8:
            rows.append(bytes(int(x * 255) for x in v))
        elif depth == 16:
            rows.append(b''.join(int(x * 65535).to_bytes(2, 'big') for x in v))
        else:
            rows.append(b''.join(struct.pack('>f', x) for x in v))
    return rows


# PackBits: n + 1 bytes as they are (n from 0 to 127), or 257 - n: one byte
# n times (n from 2 to 128)
def packbits(row):
    out, i, n = bytearray(), 0, len(row)
    while i < n:
        run = 1
        while i + run < n and run < 128 and row[i + run] == row[i]:
            run += 1
        if run >= 2:
            out += bytes([257 - run, row[i]])
            i += run
            continue
        j = i + 1
        while j < n and j - i < 128 and not (j + 1 < n and row[j] == row[j + 1]):
            j += 1
        out += bytes([j - i - 1]) + row[i:j]
        i = j
    return bytes(out)


# ZIP with prediction: each sample less the one before it in the row (for
# 32-bit samples, the bytes of each row grouped by significance first)
def _predict(rows, depth):
    out = b''
    for row in rows:
        if depth == 8:
            out += bytes([row[0]] + [(row[i] - row[i - 1]) % 256 for i in range(1, len(row))])
        elif depth == 16:
            s = [int.from_bytes(row[i:i + 2], 'big') for i in range(0, len(row), 2)]
            out += b''.join(((s[i] - (s[i - 1] if i else 0)) % 65536).to_bytes(2, 'big') for i in range(len(s)))
        else:
            k = len(row) // 4
            planar = bytes(row[4 * i + b] for b in range(4) for i in range(k))
            out += bytes([planar[0]] + [(planar[i] - planar[i - 1]) % 256 for i in range(1, len(planar))])
    return out


# The rows of one channel, compressed: raw (0), PackBits (1), ZIP (2), ZIP
# with prediction (3). Returns the compression and, apart, the byte counts of
# the rows (PackBits only) and the data.
def psd_compress(rows, method, depth, psb):
    if method == 1:
        packed = [packbits(r) for r in rows]
        return b''.join(_be(len(p), 4 if psb else 2) for p in packed), b''.join(packed)
    if method == 2:
        return b'', zlib.compress(b''.join(rows))
    if method == 3:
        return b'', zlib.compress(_predict(rows, depth))
    return b'', b''.join(rows)


# --- the document

# Colour mode: its number, and the channels its colours take
_MODES = {b'0': (0, 1), b'1': (1, 1), b'2': (2, 1), b'3': (3, 3), b'4': (4, 4), b'7': (7, 0), b'8': (8, 1), b'9': (9, 3)}
_METHODS = {b'r': 0, b'l': 1, b'z': 2, b'p': 3}


def _utf16(text):
    return _be(len(text), 4) + text.encode('utf-16-be')


def psd_resource(r):
    """One image resource block: 8BIM, ID, name, size, data (padded to even)."""
    kind = bytes(r)[:1]
    name = b''
    if kind == b'R':
        v = bytes(_find(r, '<res_values>'))
        dpi = 1 + v[0] % 255
        data = _be(dpi << 16, 4) + _be(1 + v[1] % 2, 2) + _be(1 + v[2] % 5, 2) + _be((1 + v[3] % 255) << 16, 4) + _be(1 + v[4] % 2, 2) + _be(1 + v[5] % 5, 2)
        rid = 1005
    elif kind in (b'V', b'v'):
        # v: the merged image is said not to be the real one
        data = _be(1, 4) + (b'\x01' if kind == b'V' else b'\x00') + _utf16('Adobe Photoshop') + _utf16('Adobe Photoshop 2026') + _be(1, 4)
        rid = 1057
    elif kind == b'X':
        data = b'<?xpacket begin="\xef\xbb\xbf" id="W5M0MpCehiHzreSzNTczkc9d"?><x:xmpmeta xmlns:x="adobe:ns:meta/">'
        data += b'<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"/></x:xmpmeta><?xpacket end="w"?>'
        rid = 1060
    elif kind == b'A':
        data, rid = bytes(_find(r, '<angle>')), 1037
    else:
        rid = 4000 + int.from_bytes(bytes(_find(r, '<res_id>')), 'big') % 1000
        name = bytes(_find(r, '<res_name>'))
        data = bytes(_find(r, '<res_data>'))
    return b'8BIM' + _be(rid, 2) + _pascal(name, 2) + _be(len(data), 4) + _pad(data, 2)


def _layer_rect(rect, w, h, beyond):
    r = bytes(rect)
    if beyond:
        # anywhere from 8 pixels before the canvas to 8 past it
        x0, y0 = r[0] % (w + 16) - 8, r[1] % (h + 16) - 8
        return x0, y0, 1 + r[2] % 24, 1 + r[3] % 24
    x0, y0 = r[0] % w, r[1] % h
    return x0, y0, 1 + r[2] % (w - x0), 1 + r[3] % (h - y0)


# What a layer of the draft asks for
def psd_layer_spec(lay, base, w, h):
    x0, y0, lw, lh = _layer_rect(_find(lay, '<rect>'), w, h, _find(lay, '<beyond>') is not None)
    if _find(lay, '<empty_layer>') is not None:
        lw = lh = 0
    alpha = _find(lay, '<layer_alpha>')
    ids = ([-1] if alpha is not None and bytes(alpha) == b'a' else []) + list(range(base))
    mask = _find(lay, '<layer_mask>')
    if mask is not None:
        ids.append(-2)
    clip = _find(lay, '<clipping>')
    return {'rect': (x0, y0, lw, lh), 'ids': ids, 'kind': bytes(_find(lay, '<kind>')).decode(),
            'seed': bytes(_find(lay, '<seed>')), 'method': _METHODS[bytes(_find(lay, '<layer_packing>'))],
            'name': bytes(_find(lay, '<layer_name>')), 'blend': bytes(_find(lay, '<blend>')),
            'flags': bytes(_find(lay, '<flags>'))[0], 'opacity': bytes(_find(lay, '<opacity>'))[0],
            'clipping': 1 if clip is not None else 0, 'mask': bytes(mask) if mask is not None else None, 'lsct': None}


# An empty layer that opens (1, 2) or closes (3) a group
def psd_divider(base, lsct, name):
    return {'rect': (0, 0, 0, 0), 'ids': [-1] + list(range(base)), 'kind': 'f', 'seed': b'', 'method': 0,
            'name': name, 'blend': b'pass' if lsct != 3 else b'norm', 'flags': 0x08, 'opacity': 255,
            'clipping': 0, 'mask': None, 'lsct': lsct}


# The layer records and the channel image data of the layers
def psd_layers(specs, depth, psb):
    records, data = b'', b''
    for sp in specs:
        x0, y0, lw, lh = sp['rect']
        chan_info, chan_data = b'', b''
        for k, cid in enumerate(sp['ids']):
            if not (lw and lh):
                rows = []
            elif cid == -2:
                rows = psd_plane('g', sp['seed'] + b'm', lw, lh, depth)
            else:
                rows = psd_plane(sp['kind'], sp['seed'] + bytes([k]), lw, lh, depth)
            method = sp['method'] if rows else 0
            counts, packed = psd_compress(rows, method, depth, psb)
            block = _be(method, 2) + counts + packed
            chan_info += _be(cid, 2) + _be(len(block), 8 if psb else 4)
            chan_data += block
        extra = b''
        if sp['mask'] is not None:
            m = sp['mask']
            extra += _be(20, 4) + _be(y0, 4) + _be(x0, 4) + _be(y0 + lh, 4) + _be(x0 + lw, 4) + bytes([m[0] % 2 * 255, m[1] % 4]) + b'\x00\x00'
        else:
            extra += _be(0, 4)
        extra += _be(0, 4)
        extra += _pascal(sp['name'], 4)
        luni = _pad(_utf16(sp['name'].decode('latin-1')), 4)
        extra += b'8BIM' + b'luni' + _be(len(luni), 4) + luni
        if sp['lsct'] is not None:
            lsct = _be(sp['lsct'], 4)
            extra += b'8BIM' + b'lsct' + _be(len(lsct), 4) + lsct
        records += _be(y0, 4) + _be(x0, 4) + _be(y0 + lh, 4) + _be(x0 + lw, 4) + _be(len(sp['ids']), 2) + chan_info
        records += b'8BIM' + sp['blend'] + bytes([sp['opacity'], sp['clipping'], sp['flags'], 0]) + _be(len(extra), 4) + extra
        data += chan_data
    return records, data


def psd_file(draft):
    psb = _find(draft, '<psb>') is not None
    mode_node = _find(draft, '<mode>')
    mode_key = bytes(mode_node)[:1]
    mode, base = _MODES[mode_key]
    d = _find(mode_node, '<depth>') or _find(mode_node, '<deep>')
    depth = 1 if mode == 0 else 8 if mode == 2 else int(bytes(d))
    if mode == 7:
        base = 1 + bytes(_find(mode_node, '<multi_count>'))[0] % 4
    extra = bytes(_find(draft, '<extra_channels>'))[0] % 3 if mode in (1, 3, 4, 9) else 0
    more = _find(draft, '<more_channels>')
    if more is not None and mode in (1, 3, 4, 7, 9):
        extra = bytes(more)[0] % (57 - base)
    channels = base + extra
    w = bytes(_find(draft, '<width>'))[0]
    h = bytes(_find(draft, '<height>'))[0]
    # A document of more than 8 channels is at most 16x16, so that the file
    # stays small
    if channels > 8:
        w, h = min(w, 16), min(h, 16)
    kind = bytes(_find(draft, '<kind>')).decode()
    seed = bytes(_find(draft, '<seed>'))

    header = b'8BPS' + _be(2 if psb else 1, 2) + bytes(6) + _be(channels, 2) + _be(h, 4) + _be(w, 4) + _be(depth, 2) + _be(mode, 2)
    if mode == 2:
        cmd = _stream(seed + b'palette', 768)
    elif mode == 8:
        cmd = bytes(_find(mode_node, '<duotone_data>'))
    else:
        cmd = b''
    out = header + _be(len(cmd), 4) + cmd

    resources = b''.join(psd_resource(r) for r in _all(draft, '<resource>'))
    out += _be(len(resources), 4) + resources

    layers = _all(draft, '<layer>')
    if mode not in (1, 3, 4, 8, 9) or (depth != 8 and _find(draft, '<deep_layers>') is None):
        layers = []
    specs = [psd_layer_spec(lay, base, w, h) for lay in layers]
    group = _find(draft, '<grouped>')
    if specs and group is not None:
        # Layers go from the bottom up: the divider that closes the group,
        # the layers in it, and the layer that opens it (1 open, 2 closed)
        specs = [psd_divider(base, 3, b'</Layer group>')] + specs + [psd_divider(base, 1 + bytes(group)[0] % 2, b'Group')]
    lm = b''
    if specs:
        records, data = psd_layers(specs, depth, psb)
        count = len(specs)
        if _find(draft, '<merged_alpha>') is not None:
            count = -count
        info = _pad(_be(count, 2) + records + data, 4)
        if depth == 8:
            lm += _be(len(info), 8 if psb else 4) + info
        else:
            lm += _be(0, 8 if psb else 4)
    else:
        lm += _be(0, 8 if psb else 4)
    gm = _find(draft, '<global_mask>')
    if gm is not None:
        g = bytes(gm)
        # overlay colour space, four colour components, opacity (0 to 100),
        # kind (colour selected, colour protected, or per layer: 0, 1, 128)
        gdata = _be(0, 2) + g[0:8] + _be(g[8] % 101, 2) + bytes([(0, 1, 128)[g[9] % 3]]) + b'\x00\x00\x00'
        lm += _be(len(gdata), 4) + gdata
    else:
        lm += _be(0, 4)
    if specs and depth != 8:
        key = b'Lr16' if depth == 16 else b'Lr32'
        lm += b'8BIM' + key + _be(len(info), 8 if psb else 4) + info
    out += _be(len(lm), 8 if psb else 4) + lm

    method = _METHODS[bytes(_find(draft, '<merged_packing>'))]
    # Prediction is for samples of 8 bits and more: a bitmap is ZIP without it
    if method == 3 and depth == 1:
        method = 2
    planes = [psd_plane(kind, seed + bytes([c]), w, h, depth) for c in range(channels)]
    if method == 1:
        packed = [[packbits(r) for r in rows] for rows in planes]
        counts = b''.join(_be(len(p), 4 if psb else 2) for rows in packed for p in rows)
        body = counts + b''.join(p for rows in packed for p in rows)
    elif method in (2, 3):
        # one zlib stream for the rows of every channel
        body = psd_compress([r for rows in planes for r in rows], method, depth, psb)[1]
    else:
        body = b''.join(r for rows in planes for r in rows)
    return out + _be(method, 2) + body


<start> ::= <psd>
<psd> ::= <psd_file> := psd_file(<psd_draft>)
<psd_file> ::= rb'(?s).+'

# The draft: what psd_file() makes the file from
<psd_draft> ::= <mode> <width> <height> <extra_channels> <merged_packing> <kind> <seed> <resources> <layers>
# Bitmap, grayscale, indexed, RGB, CMYK, multichannel, duotone, Lab
<mode> ::= b'0' | b'1' <depth> | b'2' | b'3' <depth> | b'4' <depth> \
         | b'7' <depth> <multi_count> | b'8' <depth> <duotone_data> | b'9' <depth>
<depth> ::= b'8' | b'16'
<multi_count> ::= rb'[\x00-\xff]'
<duotone_data> ::= rb'[\x00-\xff]{0,40}'
# Alpha or spot channels: 0 to 2
<extra_channels> ::= rb'[\x00-\xff]'
<width> ::= rb'[\x01-\x40]'
<height> ::= rb'[\x01-\x40]'
# Raw (r) or PackBits (l)
<merged_packing> ::= b'r' | b'l'
<kind> ::= b'n' | b'r' | b'g' | b'f'
<seed> ::= rb'[\x00-\xff]{1,8}'

<resources> ::= <resource>{0,4}
# Resolution, version info, global angle, a plug-in resource
<resource> ::= b'R' <res_values> | b'V' | b'A' <angle> | b'U' <res_id> <res_name> <res_data>
<res_values> ::= rb'[\x00-\xff]{6}'
<angle> ::= rb'[\x00-\xff]{4}'
<res_id> ::= rb'[\x00-\xff]{2}'
<res_name> ::= rb'[\x20-\x7e]{0,12}'
# At least one byte: empty data is in psd-boundary
<res_data> ::= rb'[\x00-\xff]{1,32}'

<layers> ::= b'-' | <layer> | <layer> <layer> | <layer> <layer> <layer>
<layer> ::= <rect> <layer_alpha> <blend> <opacity> <flags> <layer_name> <layer_packing> <kind> <seed>
<rect> ::= rb'[\x00-\xff]{4}'
# With a transparency channel (a) or not (n)
<layer_alpha> ::= b'a' | b'n'
<blend> ::= b'norm' | b'mul ' | b'scrn' | b'over' | b'dark' | b'lite' | b'diss'
<opacity> ::= rb'[\x00-\xff]'
# Transparency protected, hidden, and Photoshop 5 bits
<flags> ::= b'\x00' | b'\x01' | b'\x02' | b'\x08' | b'\x0a'
<layer_name> ::= rb'[\x20-\x7e]{0,20}'
<layer_packing> ::= b'r' | b'l'
