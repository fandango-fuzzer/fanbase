# X11 bitmap fonts in the Portable Compiled Format: a table of contents and
# the tables bdftopcf writes, properties, accelerators, metrics, bitmaps, ink
# metrics, encodings, scalable widths, glyph names and BDF accelerators, of
# which ink metrics, scalable widths, glyph names and one of the two
# accelerator tables are as the font chooses.
#
# The rules say what is in a font: its glyphs (metrics, and a pattern of bits
# their bitmaps repeat), which codes map to them (one byte, or rows of two),
# its properties, and how its tables are written: most or least significant
# byte and bit first, rows padded to 1, 2, 4 or 8 bytes, scan units of 1, 2 or
# 4 bytes, compressed metrics or not, accelerators with ink bounds or not.
# What follows from that is computed: the table of contents, the bitmaps and
# their offsets and sizes for every padding, the accelerators' bounds and
# flags, the scalable widths and the glyph names.
#
# TODO:
# * The ink metrics are the metrics; a glyph's bitmap is a repeated pattern.
# * Tables are always in the order of their type.

import struct


def sym(node):
    return str(node.symbol)


def kids(node, name):
    return [c for c in node.children if c.is_non_terminal and sym(c) == name]


def kid(node, name):
    found = kids(node, name)
    return found[0] if found else None


def tok(node):
    return bytes(node)


PROPERTIES, ACCELERATORS, METRICS, BITMAPS, INK_METRICS, ENCODINGS, SWIDTHS, GLYPH_NAMES, BDF_ACCELERATORS = (
    1, 2, 4, 8, 16, 32, 64, 128, 256)
MSB_BYTE, MSB_BIT, COMPRESSED, WITH_INK_BOUNDS = 4, 8, 0x100, 0x100


def packer(fmt):
    """Packs integers in the byte order of a table of format `fmt`."""
    order = ">" if fmt & MSB_BYTE else "<"

    def pack(code, *values):
        return struct.pack(order + code, *values)

    return pack


def pcf_glyphs(font):
    glyphs = []
    for node in kids(font, "<pcf_glyph>"):
        data = tok(node)
        lsb = struct.unpack("b", data[0:1])[0]
        glyphs.append({"lsb": lsb, "rsb": lsb + data[1], "width": data[2], "ascent": data[3], "descent": data[4],
                       "pattern": data[5:]})
    return glyphs


def bitmap_rows(glyph):
    """The rows of a glyph's bitmap, most significant bit first, each as many bytes as its width needs."""
    pixels = glyph["rsb"] - glyph["lsb"]
    per_row = (pixels + 7) // 8
    rows = []
    pattern = glyph["pattern"]
    for row in range(glyph["ascent"] + glyph["descent"]):
        line = bytearray(pattern[(row * per_row + i) % len(pattern)] for i in range(per_row))
        if pixels % 8:
            line[-1] &= (0xFF << (8 - pixels % 8)) & 0xFF
        rows.append(bytes(line))
    return rows


def reverse_bits(b):
    return int("{:08b}".format(b)[::-1], 2)


def bitmap_data(glyph, pad, fmt, unit):
    out = b""
    for row in bitmap_rows(glyph):
        row = row + bytes(-len(row) % pad)
        if bool(fmt & MSB_BYTE) != bool(fmt & MSB_BIT) and unit > 1:
            row = b"".join(row[i:i + unit][::-1] for i in range(0, len(row), unit))
        if not fmt & MSB_BIT:
            row = bytes(reverse_bits(b) for b in row)
        out += row
    return out


def metric_fields(g):
    return [g["lsb"], g["rsb"], g["width"], g["ascent"], g["descent"]]


def metrics_table(glyphs, fmt, compressed):
    p = packer(fmt)
    if compressed:
        return (struct.pack("<I", fmt | COMPRESSED) + p("h", len(glyphs))
                + b"".join(bytes(v + 0x80 for v in metric_fields(g)) for g in glyphs))
    return struct.pack("<I", fmt) + p("i", len(glyphs)) + b"".join(p("6h", *(metric_fields(g) + [0])) for g in glyphs)


def bounds(glyphs, pick):
    return [pick(g[k] for g in glyphs) for k in ("lsb", "rsb", "width", "ascent", "descent")] + [0]


def accelerators_table(glyphs, fmt, ink_bounds):
    p = packer(fmt)
    ascent, descent = max(g["ascent"] for g in glyphs), max(g["descent"] for g in glyphs)
    overlap = max(g["rsb"] - g["width"] for g in glyphs)
    first = metric_fields(glyphs[0])
    constant = all(metric_fields(g) == first for g in glyphs)
    widths = all(g["width"] == glyphs[0]["width"] for g in glyphs)
    inside = all(g["lsb"] >= 0 and g["rsb"] <= g["width"] and g["ascent"] <= ascent and g["descent"] <= descent
                 for g in glyphs)
    terminal = constant and inside and first[0] == 0 and first[1] == first[2]
    low, high = bounds(glyphs, min), bounds(glyphs, max)
    out = (struct.pack("<I", fmt | (WITH_INK_BOUNDS if ink_bounds else 0))
           + bytes([overlap <= 0, constant, terminal, widths, inside, 0, 0, 0])
           + p("3i", ascent, descent, overlap) + p("6h", *low) + p("6h", *high))
    if ink_bounds:
        out += p("6h", *low) + p("6h", *high)
    return out


def encoding(node, count):
    """The ranges of codes, the glyph each code maps to (0xFFFF for none), and the default character."""
    data = tok(node)
    two_bytes, first, columns, first_row, rows, style = data[0], data[1], data[2], data[3], data[4], data[5]
    default = struct.unpack(">H", data[6:8])[0]
    if not two_bytes:
        first_row, rows = 0, 1
    last = min(255, first + columns - 1)
    cells = (last - first + 1) * rows
    indices, glyph = [], 0
    for n in range(cells):
        if (style == 1 and n % 2) or glyph >= count:
            indices.append(0xFFFF)
            continue
        indices.append(count - 1 - glyph if style == 2 else glyph)
        glyph += 1
    return first, last, first_row, min(255, first_row + rows - 1), default, indices


def pcf(font):
    layout = tok(kid(font, "<pcf_layout>"))
    optional, order, pad_bits, unit_bits, compressed, ink_bounds, mixed = layout[:7]
    glyphs = pcf_glyphs(font)
    pad, unit = 1 << pad_bits, min(1 << unit_bits, 1 << pad_bits)
    base = order | pad_bits | (unit.bit_length() - 1) << 4

    def fmt(n):
        return base ^ (MSB_BYTE if mixed and n % 2 else 0)

    tables = {}
    names, props = {}, []
    for node in kids(font, "<pcf_property>"):
        data = tok(node)
        name, value = data[1:].split(b"\x00", 1)
        names[name] = (data[:1] == b"S", value)
    strings = b""
    entries = []
    for name in names:
        is_string, value = names[name]
        at = len(strings)
        strings += name + b"\x00"
        if is_string:
            entries.append((at, 1, len(strings)))
            strings += value + b"\x00"
        else:
            entries.append((at, 0, struct.unpack(">h", value)[0]))
    p = packer(fmt(0))
    tables[PROPERTIES] = (struct.pack("<I", fmt(0)) + p("i", len(entries))
                          + b"".join(p("i", a) + bytes([s]) + p("i", v) for a, s, v in entries)
                          + bytes(-len(entries) % 4) + p("i", len(strings)) + strings)
    if optional & 8:
        tables[ACCELERATORS] = accelerators_table(glyphs, fmt(1), ink_bounds)
    tables[METRICS] = metrics_table(glyphs, fmt(2), compressed)
    f = fmt(3)
    p = packer(f)
    images = [bitmap_data(g, pad, f, unit) for g in glyphs]
    offsets, at = [], 0
    for image in images:
        offsets.append(at)
        at += len(image)
    sizes = [sum(len(bitmap_data(g, 1 << n, f, min(unit, 1 << n))) for g in glyphs) for n in range(4)]
    tables[BITMAPS] = (struct.pack("<I", f) + p("i", len(glyphs)) + b"".join(p("i", o) for o in offsets)
                       + b"".join(p("i", s) for s in sizes) + b"".join(images))
    if optional & 1:
        tables[INK_METRICS] = metrics_table(glyphs, fmt(4), compressed)
    first, last, first_row, last_row, default, indices = encoding(kid(font, "<pcf_encoding>"), len(glyphs))
    p = packer(fmt(5))
    tables[ENCODINGS] = (struct.pack("<I", fmt(5)) + p("5H", first, last, first_row, last_row, default)
                         + b"".join(p("H", i) for i in indices))
    if optional & 2:
        p = packer(fmt(6))
        tables[SWIDTHS] = struct.pack("<I", fmt(6)) + p("i", len(glyphs)) + b"".join(
            p("i", g["width"] * 1000 // max(1, max(h["ascent"] + h["descent"] for h in glyphs))) for g in glyphs)
    if optional & 4:
        p = packer(fmt(7))
        codes = {}
        columns = last - first + 1
        for n, i in enumerate(indices):
            if i != 0xFFFF and i not in codes:
                codes[i] = (first_row + n // columns) * 256 + first + n % columns
        text, starts = b"", []
        for n in range(len(glyphs)):
            starts.append(len(text))
            text += (("uni%04X" % codes[n]) if n in codes else "glyph%d" % n).encode("ascii") + b"\x00"
        tables[GLYPH_NAMES] = (struct.pack("<I", fmt(7)) + p("i", len(glyphs)) + b"".join(p("i", s) for s in starts)
                               + p("i", len(text)) + text)
    if optional & 16:
        tables[BDF_ACCELERATORS] = accelerators_table(glyphs, fmt(8), ink_bounds)
    kinds = sorted(tables)
    offset = 8 + 16 * len(kinds)
    toc, body = b"", b""
    for kind in kinds:
        data = tables[kind] + bytes(-len(tables[kind]) % 4)
        toc += struct.pack("<4I", kind, struct.unpack("<I", data[:4])[0], len(data), offset + len(body))
        body += data
    return b"\x01fcp" + struct.pack("<I", len(kinds)) + toc + body


<start> ::= <pcf>
<pcf> ::= <pcf_file> := pcf(<pcf_font>)
<pcf_file> ::= rb'(?s).+'

<pcf_font> ::= <pcf_layout> <pcf_encoding> <pcf_glyph>{1,24} <pcf_property>{1,12}

# How the tables are written: which of the optional tables the font has (bit 0:
# ink metrics, 1: scalable widths, 2: glyph names, 3: accelerators, 4: BDF
# accelerators; one of the two accelerator tables at least), the byte and bit
# order (04: most significant byte first, 08: most significant bit first), the
# padding of a row (1, 2, 4 or 8 bytes), the scan unit (1, 2 or 4 bytes, no
# more than the padding), compressed metrics, accelerators with ink bounds, and
# whether the tables alternate between the two byte orders
<pcf_layout> ::= rb'[\x08-\x1f][\x00\x04\x08\x0c][\x00-\x03][\x00-\x02][\x00\x01][\x00\x01][\x00\x01]'

# The encoding: one byte (00) or two (01); the first code (of a row); how many
# codes in a row; the first row and how many rows (two bytes only); whether the
# codes map to the glyphs in order (00), every other code to none (01), or in
# reverse order (02); and the default character
<pcf_encoding> ::= rb'[\x00\x01](?:\x00|\x20|\x41|\x80|\xa0|[\x00-\xff])[\x01-\x60][\x01-\xff][\x01-\x03][\x00-\x02][\x00-\xff]{2}'

# A glyph: its left side bearing (-4 to 4), the width of its ink (0 to 16
# pixels), its advance (0 to 20), ascent (0 to 16) and descent (0 to 6), and 1
# to 8 bytes of a pattern its bitmap repeats
<pcf_glyph> ::= rb'[\xfc-\xff\x00-\x04][\x00-\x10][\x00-\x14][\x00-\x10][\x00-\x06][\x00-\xff]{1,8}'

# A property of the font: S and a name with a text, or I and a name with a
# number (two bytes)
<pcf_property> ::= rb'S(?:FOUNDRY|FAMILY_NAME|WEIGHT_NAME|SLANT|SETWIDTH_NAME|ADD_STYLE_NAME|SPACING|CHARSET_REGISTRY|CHARSET_ENCODING|COPYRIGHT|NOTICE|FONT|FACE_NAME)\x00[ -~]{0,24}|I(?:PIXEL_SIZE|POINT_SIZE|RESOLUTION_X|RESOLUTION_Y|AVERAGE_WIDTH|FONT_ASCENT|FONT_DESCENT|DEFAULT_CHAR|CAP_HEIGHT|X_HEIGHT|UNDERLINE_POSITION|UNDERLINE_THICKNESS|WEIGHT|RESOLUTION|QUAD_WIDTH)\x00[\x00-\xff]{2}'
