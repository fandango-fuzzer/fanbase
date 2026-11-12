# TrueType fonts: an sfnt of version 1.0 with TrueType outlines and the tables
# every such font has (head, hhea, maxp, OS/2, hmtx, cmap, loca, glyf, name,
# post), and, as each font chooses, hinting (cvt, fpgm, prep, the glyphs'
# programs), gasp, device metrics (hdmx, LTSH, VDMX), kerning (kern), vertical
# metrics (vhea, vmtx) and an empty DSIG.
#
# The rules say what is in a font: its glyphs, as contours of points or as
# components of earlier glyphs; which characters map to which glyphs, and in
# which cmap formats; its names, metrics, settings and programs. What follows
# from that is computed when the font is laid out, by sfnt() and the functions
# it calls: counts, offsets and lengths, bounding boxes, maxp, loca, hmtx, the
# side bearings, the table checksums and checkSumAdjustment, and how outlines
# are encoded (flags, one- or two-byte coordinates, repeated flags).
#
# Fandango gives each input a budget of tree nodes, so the fields of a table,
# and the points of a glyph, are records that one rule writes out, as the
# comments above them say, rather than one rule per field.
#
# The OTF, WOFF and WOFF2 specs include this one and use its tables.
#
# TODO:
# * No OpenType layout (GDEF, GSUB, GPOS), no variations (fvar, gvar, ...), no
#   colour or bitmap glyphs, no font collections.
# * The programs use a part of the instruction set, and no twilight zone; their
#   point numbers are not checked against the glyph's points.
# * `fandango parse` cannot read a font back: nothing undoes the layout.

import struct


# --- reading the rules' values

def sym(node):
    return str(node.symbol)


def kids(node, name):
    return [c for c in node.children if c.is_non_terminal and sym(c) == name]


def kid(node, name):
    found = kids(node, name)
    return found[0] if found else None


def alt(node):
    """The non-terminal under a node: which alternative it is."""
    for c in node.children:
        if c.is_non_terminal:
            return c
    return None


def tok(node):
    return bytes(node)


def uint(data):
    return int.from_bytes(data, "big")


def sint(data):
    return int.from_bytes(data, "big", signed=True)


class Reader:
    """Reads a record that a rule wrote out, field by field."""

    def __init__(self, data):
        self.data, self.at = data, 0

    def take(self, n):
        piece = self.data[self.at:self.at + n]
        self.at += n
        return piece

    def u8(self):
        return self.take(1)[0]

    def i8(self):
        return sint(self.take(1))

    def u16(self):
        return uint(self.take(2))

    def i16(self):
        return sint(self.take(2))

    def text(self):
        end = self.data.index(b"\x00", self.at)
        piece = self.data[self.at:end]
        self.at = end + 1
        return piece.decode("ascii")

    def left(self):
        return len(self.data) - self.at


# --- packing

def u8(n):
    return struct.pack(">B", n & 0xFF)


def u16(n):
    return struct.pack(">H", n & 0xFFFF)


def i16(n):
    return struct.pack(">h", max(-32768, min(32767, int(n))))


def u24(n):
    return (n & 0xFFFFFF).to_bytes(3, "big")


def u32(n):
    return struct.pack(">I", n & 0xFFFFFFFF)


def pad4(data):
    return data + b"\0" * (-len(data) % 4)


def table_checksum(data):
    data = pad4(data)
    return sum(struct.unpack(">%dI" % (len(data) // 4), data)) & 0xFFFFFFFF


def binary_search_fields(count, unit):
    """searchRange, entrySelector and rangeShift for `count` records of `unit` bytes."""
    selector = max(count, 1).bit_length() - 1
    search = unit << selector
    return search, selector, count * unit - search


# The order fonts usually put their tables in; the directory is sorted by tag.
TABLE_ORDER = [b"head", b"hhea", b"maxp", b"OS/2", b"hmtx", b"LTSH", b"VDMX", b"hdmx", b"cmap", b"fpgm",
               b"prep", b"cvt ", b"loca", b"glyf", b"kern", b"name", b"post", b"gasp", b"vhea", b"vmtx",
               b"CFF ", b"DSIG"]


def sfnt_layout(version, tables):
    tags = sorted(tables)
    search, selector, shift = binary_search_fields(len(tags), 16)
    header = version + struct.pack(">HHHH", len(tags), search, selector, shift)
    order = [t for t in TABLE_ORDER if t in tables] + [t for t in tags if t not in TABLE_ORDER]
    offset = 12 + 16 * len(tags)
    placed, body = {}, b""
    for tag in order:
        placed[tag] = offset
        body += pad4(tables[tag])
        offset += len(pad4(tables[tag]))
    directory = b"".join(tag + u32(table_checksum(tables[tag])) + u32(placed[tag]) + u32(len(tables[tag]))
                         for tag in tags)
    font = bytearray(header + directory + body)
    if b"head" in tables:
        at = placed[b"head"] + 8
        font[at:at + 4] = u32((0xB1B0AFBA - table_checksum(bytes(font))) & 0xFFFFFFFF)
    return bytes(font)


def sfnt(version, font):
    return sfnt_layout(tok(version), truetype_tables(font))


# --- glyphs: what every kind of outline gives the other tables

def glyph_bbox(points):
    if not points:
        return None
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    return (min(xs), min(ys), max(xs), max(ys))


def union_bbox(boxes):
    boxes = [b for b in boxes if b]
    if not boxes:
        return (0, 0, 0, 0)
    return (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))


def glyph_header(reader):
    """The advance width and the post name (('std', number) or ('custom', name)) that start a glyph's record."""
    advance = reader.u16()
    if reader.u8() == 0:
        return advance, ("std", reader.u8())
    return advance, ("custom", reader.text())


# --- TrueType outlines

def read_simple(reader, glyph):
    options = reader.u8()
    glyph["overlap"], glyph["repeat"] = bool(options & 1), not options & 2
    contours, current = [], []
    x = y = 0
    while reader.left():
        kind = reader.u8()
        move = (kind >> 1) & 3
        if move == 0:
            x, y = reader.i16(), reader.i16()
        elif move == 1:
            x, y = x + reader.i16(), y + reader.i16()
        elif move == 2:
            y += reader.i16()
        else:
            x += reader.i16()
        current.append((x, y, bool(kind & 1)))
        if kind & 8:
            contours.append(current)
            current = []
    if current:
        contours.append(current)
    glyph["contours"] = contours


SCALES = {0: 0, 1: 1, 2: 2, 3: 4}


def read_composite(reader, glyph, index):
    glyph["overlap"] = bool(reader.u8() & 1)
    plans = []
    while reader.left():
        ref = reader.u8()
        placing = reader.u8()
        kind = placing >> 5
        if kind == 0:
            args = [reader.i8(), reader.i8()]
        elif kind == 1:
            args = [reader.i16(), reader.i16()]
        else:
            args = [reader.u8(), reader.u8()]
        transform = reader.u8()
        scale = [reader.i16() / 16384.0 for _ in range(SCALES[transform])]
        plans.append({"glyph": ref % index, "kind": ("bytes", "words", "points")[kind], "args": args,
                      "transform": transform, "scale": scale, "round": bool(placing & 1),
                      "my_metrics": bool(placing & 2), "offsets": ("default", "scaled", "unscaled", "default")[(placing >> 2) & 3]})
    glyph["plans"] = plans


def em_scale(font, units):
    """What the glyphs' records are measured in (an em of `units`) scaled to the font's unitsPerEm."""
    upem = units_per_em(font)
    return lambda v: int(round(v * upem / units))


def read_glyphs(font):
    """Each glyph as a dict: its outline, advance, name and program, scaled to the font's em."""
    scale = em_scale(font, 2048)
    glyphs_node = kid(font, "<glyphs>")
    nodes = [alt(kid(glyphs_node, "<notdef>"))] + [alt(g) for g in kids(glyphs_node, "<glyph>")]
    glyphs = []
    for index, node in enumerate(nodes):
        kind = sym(node)
        record = node if kind == "<empty_glyph>" else alt(node)
        reader = Reader(tok(record))
        advance, name = glyph_header(reader)
        glyph = {"advance": advance, "name": ("std", 0) if index == 0 else name, "kind": "empty",
                 "contours": [], "plans": [], "program": kid(node, "<glyph_program>"), "overlap": False,
                 "repeat": True, "node": node}
        if kind == "<simple_glyph>":
            glyph["kind"] = "simple"
            read_simple(reader, glyph)
            glyph["contours"] = [[(scale(x), scale(y), on) for x, y, on in c] for c in glyph["contours"]]
        elif kind == "<composite_glyph>":
            glyph["kind"] = "composite"
            read_composite(reader, glyph, index)
            for plan in glyph["plans"]:
                if plan["kind"] != "points":
                    plan["args"] = [scale(a) for a in plan["args"]]
        glyph["advance"] = scale(advance)
        glyphs.append(glyph)
    return glyphs


def transform_point(plan, x, y):
    s = plan["scale"]
    if plan["transform"] == 1:
        return x * s[0], y * s[0]
    if plan["transform"] == 2:
        return x * s[0], y * s[1]
    if plan["transform"] == 3:
        return x * s[0] + y * s[2], x * s[1] + y * s[3]
    return x, y


def resolve_composites(glyphs):
    """The points of every glyph as drawn, with the components placed."""
    for glyph in glyphs:
        if glyph["kind"] == "simple":
            glyph["points"] = [(p[0], p[1]) for c in glyph["contours"] for p in c]
            glyph["n_contours"], glyph["depth"] = len(glyph["contours"]), 0
        elif glyph["kind"] == "empty":
            glyph["points"], glyph["n_contours"], glyph["depth"] = [], 0, 0
        else:
            points, contours, depth = [], 0, 0
            used_metrics = False
            kept = []
            for plan in glyph["plans"]:
                child = glyphs[plan["glyph"]]
                if len(points) + len(child["points"]) > 4000:  # components of components: keep it drawable
                    break
                kept.append(plan)
                moved = [transform_point(plan, x, y) for x, y in child["points"]]
                if plan["kind"] == "points":
                    if points and moved:
                        plan["args"] = [plan["args"][0] % len(points), plan["args"][1] % len(moved)]
                        px, py = points[plan["args"][0]]
                        cx, cy = moved[plan["args"][1]]
                        dx, dy = px - cx, py - cy
                    else:  # nothing to match yet: placed by an offset instead
                        plan["kind"], plan["args"] = "words", [0, 0]
                        dx, dy = 0, 0
                else:
                    dx, dy = plan["args"]
                    if plan["offsets"] == "scaled":
                        dx, dy = transform_point(plan, dx, dy)
                if plan["my_metrics"]:
                    plan["my_metrics"] = not used_metrics
                    used_metrics = True
                points += [(round(x + dx), round(y + dy)) for x, y in moved]
                contours += child["n_contours"]
                depth = max(depth, child["depth"] + 1)
            glyph["points"], glyph["n_contours"], glyph["depth"], glyph["plans"] = points, contours, depth, kept
        glyph["bbox"] = glyph_bbox(glyph["points"])
    return glyphs


def encode_simple(glyph, program):
    points = [p for c in glyph["contours"] for p in c]
    ends, total = [], 0
    for contour in glyph["contours"]:
        total += len(contour)
        ends.append(total - 1)
    flags, xs, ys = [], b"", b""
    px = py = 0
    for i, point in enumerate(points):
        x, y, on = point
        dx, dy = x - px, y - py
        px, py = x, y
        flag = 0x01 if on else 0
        if i == 0 and glyph["overlap"]:
            flag |= 0x40
        if dx == 0:
            flag |= 0x10
        elif -255 <= dx <= 255:
            flag |= 0x02 | (0x10 if dx > 0 else 0)
            xs += u8(abs(dx))
        else:
            xs += i16(dx)
        if dy == 0:
            flag |= 0x20
        elif -255 <= dy <= 255:
            flag |= 0x04 | (0x20 if dy > 0 else 0)
            ys += u8(abs(dy))
        else:
            ys += i16(dy)
        flags.append(flag)
    packed = b""
    i = 0
    while i < len(flags):
        run = 1
        while glyph["repeat"] and i + run < len(flags) and flags[i + run] == flags[i] and run < 256:
            run += 1
        packed += u8(flags[i] | 0x08) + u8(run - 1) if run > 1 else u8(flags[i])
        i += run
    return (struct.pack(">h", len(glyph["contours"])) + b"".join(i16(v) for v in glyph["bbox"])
            + b"".join(u16(e) for e in ends) + u16(len(program)) + program + packed + xs + ys)


def encode_composite(glyph, program):
    box = glyph["bbox"] or (0, 0, 0, 0)
    out = struct.pack(">h", -1) + b"".join(i16(v) for v in box)
    plans = glyph["plans"]
    for n, plan in enumerate(plans):
        flags = 0
        a, b = plan["args"]
        if plan["kind"] == "points":
            if a > 255 or b > 255:
                flags |= 0x0001
                args = u16(a) + u16(b)
            else:
                args = u8(a) + u8(b)
        else:
            flags |= 0x0002
            if plan["kind"] == "words" or not (-128 <= a <= 127 and -128 <= b <= 127):
                flags |= 0x0001
                args = i16(a) + i16(b)
            else:
                args = struct.pack(">bb", a, b)
            if plan["round"]:
                flags |= 0x0004
        flags |= (0, 0x0008, 0x0040, 0x0080)[plan["transform"]]
        if n + 1 < len(plans):
            flags |= 0x0020
        elif program:
            flags |= 0x0100
        if plan["my_metrics"]:
            flags |= 0x0200
        if n == 0 and glyph["overlap"]:
            flags |= 0x0400
        if plan["offsets"] == "scaled":
            flags |= 0x0800
        elif plan["offsets"] == "unscaled":
            flags |= 0x1000
        out += u16(flags) + u16(plan["glyph"]) + args + b"".join(i16(round(s * 16384)) for s in plan["scale"])
    if program:
        out += u16(len(program)) + program
    return out


# --- the tables every sfnt has, whatever its outlines

def head_table(head, box, long_loca):
    fields = [tok(c) for c in head.children if c.is_non_terminal]
    revision, flags, upem, created, modified, settings = fields
    return (b"\x00\x01\x00\x00" + revision + u32(0) + u32(0x5F0F3CF5) + flags + upem + created + modified
            + b"".join(i16(v) for v in box) + settings[:6] + u16(1 if long_loca else 0) + u16(0))


def units_per_em(font):
    return uint(tok(kid(kid(font, "<head>"), "<units_per_em>")))


def hmetrics_count(glyphs, hhea):
    if tok(hhea)[-1] == 0:
        return len(glyphs)
    n = len(glyphs)
    while n > 1 and glyphs[n - 2]["advance"] == glyphs[-1]["advance"]:
        n -= 1
    return n


def lsb(glyph):
    return glyph["bbox"][0] if glyph["bbox"] else 0


def hhea_table(hhea, glyphs):
    fields = tok(hhea)
    drawn = [g for g in glyphs if g["bbox"]]
    return (b"\x00\x01\x00\x00" + fields[0:6] + u16(max(g["advance"] for g in glyphs))
            + i16(min([lsb(g) for g in drawn] or [0])) + i16(min([g["advance"] - g["bbox"][2] for g in drawn] or [0]))
            + i16(max([g["bbox"][2] for g in drawn] or [0])) + fields[6:12] + bytes(8) + u16(0)
            + u16(hmetrics_count(glyphs, hhea)))


def hmtx_table(hhea, glyphs):
    n = hmetrics_count(glyphs, hhea)
    return (b"".join(u16(g["advance"]) + i16(lsb(g)) for g in glyphs[:n])
            + b"".join(i16(lsb(g)) for g in glyphs[n:]))


def os2_table(os2, glyphs, mapping):
    widths = [g["advance"] for g in glyphs if g["advance"]]
    average = sum(widths) // len(widths) if widths else 0
    codes = [c for c in mapping if c <= 0xFFFF] or [0]
    common = kid(os2, "<os2_common>")
    parts = {sym(c): tok(c) for c in common.children if c.is_non_terminal}
    rest = b"".join(tok(c) for c in os2.children if c.is_non_terminal and sym(c) != "<os2_common>")
    return (tok(os2.children[0]) + i16(average) + parts["<os2_classes>"] + parts["<os2_script_metrics>"]
            + parts["<os2_identity>"] + u16(min(codes)) + u16(min(max(codes), 0xFFFF)) + parts["<os2_line_metrics>"]
            + rest)


MAC_ROMAN = "mac_roman"


def name_table(name):
    platforms = tok(kid(name, "<name_platforms>"))
    records = {}
    for entry in kids(name, "<name_entry>"):
        data = tok(entry)
        name_id, text = uint(data[:2]), data[2:].decode("utf-8")
        if platforms in (b"windows", b"both"):
            records[(3, 1, 0x409, name_id)] = text.encode("utf-16-be")
        if platforms in (b"mac", b"both"):
            records[(1, 0, 0, name_id)] = text.encode(MAC_ROMAN, errors="replace")
    tags_node = kid(name, "<lang_tags>")
    tags = tok(tags_node).decode("ascii").split(",") if tags_node is not None else []
    if tags:
        family = next((records[key] for key in sorted(records) if key[0] == 3), "Fanbase".encode("utf-16-be"))
        for n, tag in enumerate(tags):
            records[(3, 1, 0x8000 + n, 1)] = family
    storage = [b""]
    placed = {}

    def place(data):
        if data not in placed:
            placed[data] = len(storage[0])
            storage[0] += data
        return placed[data]

    lines = b"".join(struct.pack(">HHHHHH", key[0], key[1], key[2], key[3], len(records[key]), place(records[key]))
                     for key in sorted(records))
    tag_lines = b"".join(u16(len(t.encode("utf-16-be"))) + u16(place(t.encode("utf-16-be"))) for t in tags)
    count = len(records)
    if tags:
        start = 6 + 12 * count + 2 + 4 * len(tags)
        return u16(1) + u16(count) + u16(start) + lines + u16(len(tags)) + tag_lines + storage[0]
    return u16(0) + u16(count) + u16(6 + 12 * count) + lines + storage[0]


def post_table(post, glyphs):
    version = tok(post.children[0])
    header = tok(kid(post, "<post_header>"))
    if version == b"\x00\x03\x00\x00":
        return version + header
    indexes, names = [], []
    for glyph in glyphs:
        kind, value = glyph["name"]
        if kind == "std":
            indexes.append(value)
        else:
            indexes.append(258 + len(names))
            names.append(value.encode("ascii")[:255])
    return (version + header + u16(len(glyphs)) + b"".join(u16(i) for i in indexes)
            + b"".join(u8(len(n)) + n for n in names))


# --- cmap

def char_map(cmap, glyph_count):
    """Which character maps to which glyph, from the ranges of the rules."""
    mapping = {}
    if glyph_count < 2:
        return mapping
    for r in kids(cmap, "<cmap_range>"):
        data = tok(r)
        start, length, first, style = uint(data[0:3]), data[3], data[4], data[5]
        for i in range(length):
            code = start + i
            if code > 0x10FFFF or 0xD800 <= code <= 0xDFFF or code == 0xFFFF:
                continue
            if style == 0:
                gid = first + i
            elif style == 1:
                gid = first * 7 + i * 13
            else:
                gid = first
            mapping[code] = 1 + gid % (glyph_count - 1)
    return mapping


def cmap_format4(mapping, ranges_only):
    codes = sorted(c for c in mapping if c < 0xFFFF)
    runs = []
    for code in codes:
        if runs and code == runs[-1][-1] + 1:
            runs[-1].append(code)
        else:
            runs.append([code])
    segments = []   # (start, end, delta, glyph ids or None)
    for run in runs:
        if ranges_only:
            segments.append((run[0], run[-1], 0, [mapping[c] for c in run]))
            continue
        piece = [run[0]]
        for code in run[1:]:
            if mapping[code] - code == mapping[piece[0]] - piece[0]:
                piece.append(code)
            else:
                segments.append((piece[0], piece[-1], mapping[piece[0]] - piece[0], None))
                piece = [code]
        segments.append((piece[0], piece[-1], mapping[piece[0]] - piece[0], None))
    segments.append((0xFFFF, 0xFFFF, 1, None))
    n = len(segments)
    search, selector, shift = binary_search_fields(n, 2)
    offsets, array = b"", b""
    for i, s in enumerate(segments):
        if s[3] is None:
            offsets += u16(0)
        else:
            offsets += u16(2 * (n - i) + len(array))
            array += b"".join(u16(g) for g in s[3])
    body = (u16(n * 2) + u16(search) + u16(selector) + u16(shift) + b"".join(u16(s[1]) for s in segments) + u16(0)
            + b"".join(u16(s[0]) for s in segments) + b"".join(u16(s[2]) for s in segments) + offsets + array)
    return u16(4) + u16(6 + len(body)) + u16(0) + body


def cmap_groups(mapping, same_glyph):
    groups = []
    for code in sorted(mapping):
        gid = mapping[code]
        if groups and code == groups[-1][1] + 1 and (
                gid == groups[-1][2] if same_glyph else gid == groups[-1][2] + code - groups[-1][0]):
            groups[-1][1] = code
        else:
            groups.append([code, code, gid])
    body = b"".join(u32(g[0]) + u32(g[1]) + u32(g[2]) for g in groups)
    return u16(13 if same_glyph else 12) + u16(0) + u32(16 + len(body)) + u32(0) + u32(len(groups)) + body


def mac_glyphs(mapping):
    out = []
    for b in range(256):
        gid = mapping.get(ord(bytes([b]).decode(MAC_ROMAN)), 0)
        out.append(gid if gid < 256 else 0)
    return out


def cmap_format14(selectors, mapping, glyph_count):
    bases = sorted(mapping)
    records, tail = [], b""
    start = 10 + 11 * len(selectors)
    others = bases[3:7]
    for selector in sorted(selectors):
        kind = selectors[selector] if others else 0
        default = nondefault = 0
        if kind != 1:
            default = start + len(tail)
            ranges = []
            for code in bases[:3]:
                if ranges and code <= ranges[-1][0] + ranges[-1][1] + 1:
                    ranges[-1][1] = min(255, code - ranges[-1][0])
                else:
                    ranges.append([code, 0])
            tail += u32(len(ranges)) + b"".join(u24(r[0]) + u8(r[1]) for r in ranges)
        if kind != 0:
            nondefault = start + len(tail)
            tail += u32(len(others)) + b"".join(u24(c) + u16(1 + mapping[c] % (glyph_count - 1)) for c in others)
        records.append(u24(selector) + u32(default) + u32(nondefault))
    body = b"".join(records) + tail
    return u16(14) + u32(10 + len(body)) + u32(len(selectors)) + body


CMAP_UNICODE, CMAP_MAC0, CMAP_MAC6, CMAP_LAST_RESORT = 1, 2, 4, 8


def cmap_table(cmap, mapping, glyph_count):
    options = tok(kid(cmap, "<cmap_subtables>"))
    ranges_only, extras = options[0] == 1, options[1]
    subtables = {}
    bmp = cmap_format4(mapping, ranges_only)
    subtables[(3, 1)] = bmp
    full = cmap_groups(mapping, False) if any(c > 0xFFFF for c in mapping) else None
    if full:
        subtables[(3, 10)] = full
    if extras & CMAP_UNICODE:
        subtables[(0, 3)] = bmp
        if full:
            subtables[(0, 4)] = full
    if extras & CMAP_MAC0:
        subtables[(1, 0)] = u16(0) + u16(262) + u16(0) + bytes(mac_glyphs(mapping))
    elif extras & CMAP_MAC6:
        glyphs = mac_glyphs(mapping)[32:127]
        subtables[(1, 0)] = (u16(6) + u16(10 + 2 * len(glyphs)) + u16(0) + u16(32) + u16(len(glyphs))
                             + b"".join(u16(g) for g in glyphs))
    if extras & CMAP_LAST_RESORT and mapping:
        subtables[(0, 6)] = cmap_groups(mapping, True)
    selectors = {}
    for i in range(2, len(options) - 1, 2):
        number = options[i]
        selectors[0xFE00 + number if number < 16 else 0xE0100 + number - 16] = options[i + 1]
    if selectors and len(mapping) >= 2:
        subtables[(0, 5)] = cmap_format14(selectors, mapping, glyph_count)
    shared = {}
    records, body = b"", b""
    offset = 4 + 8 * len(subtables)
    for key in sorted(subtables):
        data = subtables[key]
        if data not in shared:
            shared[data] = offset + len(body)
            body += data
        records += u16(key[0]) + u16(key[1]) + u32(shared[data])
    return u16(0) + u16(len(subtables)) + records + body


# --- the optional tables

def gasp_table(gasp):
    data = tok(gasp)
    ranges = {}
    for at in range(2, len(data), 3):
        ranges[data[at]] = data[at + 1:at + 3]
    sizes = sorted(ranges)
    behaviors = [ranges[s] for s in sizes]
    sizes[-1] = 0xFFFF
    return data[:2] + u16(len(sizes)) + b"".join(u16(s) + b for s, b in zip(sizes, behaviors))


def hdmx_table(hdmx, glyphs, upem):
    sizes = sorted(set(tok(hdmx)))
    size = len(pad4(bytes(2 + len(glyphs))))
    records = b""
    for ppem in sizes:
        widths = [min(255, (g["advance"] * ppem + upem // 2) // upem) for g in glyphs]
        records += pad4(u8(ppem) + u8(max(widths)) + bytes(widths))
    return u16(0) + u16(len(sizes)) + u32(size) + records


def vdmx_table(vdmx, box, upem):
    data = tok(vdmx)
    ratios = [data[i:i + 4] for i in range(1, len(data) - 2, 4)]
    low, high = sorted(data[-2:])
    low, high = min(low, 254), min(max(high, low + 1), low + 32, 255)   # two sizes or more, as in fonts
    group = u16(high - low + 1) + u8(low) + u8(high)
    for ppem in range(low, high + 1):
        group += u16(ppem) + i16(-(-box[3] * ppem // upem)) + i16(box[1] * ppem // upem)
    start = 6 + 6 * len(ratios)
    return u16(data[0]) + u16(1) + u16(len(ratios)) + b"".join(ratios) + u16(start) * len(ratios) + group


def kern_table(kern, glyph_count):
    data = tok(kern)
    pairs = {}
    for at in range(2, len(data), 4):
        pairs[(data[at] % glyph_count, data[at + 1] % glyph_count)] = sint(data[at + 2:at + 4])
    search, selector, shift = binary_search_fields(len(pairs), 6)
    body = u16(len(pairs)) + u16(search) + u16(selector) + u16(shift)
    body += b"".join(u16(key[0]) + u16(key[1]) + i16(pairs[key]) for key in sorted(pairs))
    return u16(0) + u16(1) + u16(0) + u16(6 + len(body)) + data[:2] + body


def vertical_tables(vertical, glyphs):
    data = tok(vertical)
    ascent, descent = sint(data[4:6]), sint(data[6:8])
    advance = ascent - descent
    tsbs = [ascent - g["bbox"][3] if g["bbox"] else 0 for g in glyphs]
    drawn = [g for g in glyphs if g["bbox"]]
    vhea = (data[:10] + u16(advance) + i16(min(tsbs)) + i16(min([g["bbox"][1] - descent for g in drawn] or [0]))
            + i16(max([ascent - g["bbox"][1] for g in drawn] or [0])) + i16(0) + i16(1) + i16(0) + bytes(8)
            + u16(0) + u16(len(glyphs)))
    return vhea, b"".join(u16(advance) + i16(t) for t in tsbs)


def shared_tables(font, glyphs):
    """The tables of a font that do not depend on its kind of outlines."""
    hhea = kid(font, "<hhea>")
    mapping = char_map(kid(font, "<cmap>"), len(glyphs))
    tables = {b"hhea": hhea_table(hhea, glyphs), b"hmtx": hmtx_table(hhea, glyphs),
              b"OS/2": os2_table(kid(font, "<os2>"), glyphs, mapping), b"name": name_table(kid(font, "<name>")),
              b"post": post_table(kid(font, "<post>"), glyphs), b"cmap": cmap_table(kid(font, "<cmap>"), mapping, len(glyphs))}
    box = union_bbox([g["bbox"] for g in glyphs])
    upem = units_per_em(font)
    extras = kid(font, "<extra_tables>")
    if extras is None:
        extras = kid(font, "<cff_extra_tables>")
    for node in kids(extras, "<gasp>"):
        tables[b"gasp"] = gasp_table(node)
    for node in kids(extras, "<hdmx>"):
        tables[b"hdmx"] = hdmx_table(node, glyphs, upem)
    for node in kids(extras, "<ltsh>"):
        tables[b"LTSH"] = u16(0) + u16(len(glyphs)) + tok(node) * len(glyphs)
    for node in kids(extras, "<vdmx>"):
        tables[b"VDMX"] = vdmx_table(node, box, upem)
    for node in kids(extras, "<kern>"):
        tables[b"kern"] = kern_table(node, len(glyphs))
    for node in kids(extras, "<vertical>"):
        tables[b"vhea"], tables[b"vmtx"] = vertical_tables(node, glyphs)
    for node in kids(extras, "<dsig>"):
        tables[b"DSIG"] = u32(1) + u16(0) + tok(node)
    return tables, box


def truetype_tables(font):
    glyphs = resolve_composites(read_glyphs(font))
    tables, box = shared_tables(font, glyphs)
    hinting = kid(font, "<hinting>")
    functions = 0
    if hinting is not None:
        tables[b"cvt "] = tok(kid(hinting, "<cvt>"))
        bodies = kids(hinting, "<function>")
        tables[b"fpgm"] = b"".join(u8(0xB0) + u8(n) + b"\x2c" + tok(f) + b"\x2d" for n, f in enumerate(bodies))
        functions = len(bodies)
        if kid(hinting, "<prep>") is not None:
            tables[b"prep"] = tok(kid(hinting, "<prep>"))
    glyf, offsets, longest = b"", [], 0
    for glyph in glyphs:
        program = tok(glyph["program"]) if glyph["program"] is not None and hinting is not None else b""
        longest = max(longest, len(program))
        offsets.append(len(glyf))
        if glyph["kind"] == "simple":
            glyf += pad4(encode_simple(glyph, program))
        elif glyph["kind"] == "composite":
            glyf += pad4(encode_composite(glyph, program))
    offsets.append(len(glyf))
    settings = tok(kid(kid(font, "<head>"), "<head_settings>"))
    long_loca = settings[6] == 1 or len(glyf) > 0x1FFFE
    tables[b"glyf"] = glyf
    tables[b"loca"] = b"".join(u32(o) for o in offsets) if long_loca else b"".join(u16(o // 2) for o in offsets)
    tables[b"head"] = head_table(kid(font, "<head>"), box, long_loca)
    simple = [g for g in glyphs if g["kind"] == "simple"]
    composite = [g for g in glyphs if g["kind"] == "composite"]
    tables[b"maxp"] = (b"\x00\x01\x00\x00" + u16(len(glyphs))
                       + u16(max([len(g["points"]) for g in simple] or [0]))
                       + u16(max([g["n_contours"] for g in simple] or [0]))
                       + u16(max([len(g["points"]) for g in composite] or [0]))
                       + u16(max([g["n_contours"] for g in composite] or [0]))
                       + u16(1) + u16(0) + u16(16 if hinting is not None else 0) + u16(functions) + u16(0)
                       + u16(16 if hinting is not None else 0) + u16(longest)
                       + u16(max([len(g["plans"]) for g in composite] or [0]))
                       + u16(max([g["depth"] for g in glyphs] or [0])))
    return tables


<start> ::= <ttf>
<ttf> ::= <font_file> := sfnt(<sfnt_version>, <truetype_font>)
<font_file> ::= rb'(?s).+'
<sfnt_version> ::= b"\x00\x01\x00\x00"

<truetype_font> ::= <glyphs> <hinting>? <head> <hhea> <os2> <post> <cmap> <name> <extra_tables>


# --- the glyphs: glyph 0 (.notdef), drawn, and up to 15 more
<glyphs> ::= <notdef> <glyph>{0,15}
<notdef> ::= <simple_glyph>
<glyph> ::= <empty_glyph> | <simple_glyph> | <composite_glyph>

# A glyph is measured in an em of 2048 units, which is scaled to the font's
# unitsPerEm. Every glyph's record starts with its advance width (0 to 2047) and its name in
# post: 00 and the number of a name of the standard Macintosh set, or 01 and a
# name of its own, ended by 00. (.notdef's name is always .notdef.)
<empty_glyph> ::= rb'[\x00-\x07][\x00-\xff](?:\x00[\x01-\xff]|\x01(?:[A-Za-z][A-Za-z0-9._]{0,15}|uni[0-9A-F]{4}|u[0-9A-F]{5})\x00)'

# A simple glyph: then a byte of options (bit 0: overlapping contours, bit 1:
# no repeated flags), then 1 to 24 points. A point is a byte (bit 0: on the
# curve, bit 3: the last point of its contour, bits 1 and 2: how it is placed),
# and then either an x and a y (-2048 to 4095), or the steps (-256 to 255) from
# the point before it, along both axes, only up, or only across.
<simple_glyph> ::= <simple_outline> <glyph_program>?
<simple_outline> ::= rb'[\x00-\x07][\x00-\xff](?:\x00[\x01-\xff]|\x01(?:[A-Za-z][A-Za-z0-9._]{0,15}|uni[0-9A-F]{4}|u[0-9A-F]{5})\x00)[\x00-\x03](?:[\x00\x01\x08\x09](?:[\xf8-\xff\x00-\x0f][\x00-\xff]){2}|[\x02\x03\x0a\x0b](?:[\xff\x00][\x00-\xff]){2}|[\x04-\x07\x0c-\x0f][\xff\x00][\x00-\xff]){1,24}'

# A composite glyph: then a byte of options (bit 0: overlapping), then 1 to 4
# components. A component is the glyph it draws (counted among the glyphs before
# this one), a byte that says how it is placed (bits 5-7: by two signed bytes,
# two signed words, or two point numbers to match; bit 0: round to the grid,
# bit 1: use its metrics, bits 2-3: scale the offset or not), and its scale:
# none, one, x and y, or a 2x2 matrix (F2Dot14).
<composite_glyph> ::= <composite_outline> <glyph_program>?
<composite_outline> ::= rb'[\x00-\x07][\x00-\xff](?:\x00[\x01-\xff]|\x01(?:[A-Za-z][A-Za-z0-9._]{0,15}|uni[0-9A-F]{4}|u[0-9A-F]{5})\x00)[\x00\x01](?:[\x00-\xff](?:[\x00-\x1f][\x00-\xff]{2}|[\x20-\x3f](?:[\xf0-\xff\x00-\x0f][\x00-\xff]){2}|[\x40-\x5f][\x00-\xff]{2})(?:\x00|\x01(?:[\x20-\x5f\xa0-\xdf][\x00-\xff]|\x40\x00)|\x02(?:[\x20-\x5f\xa0-\xdf][\x00-\xff]|\x40\x00){2}|\x03(?:[\x20-\x5f\xa0-\xdf][\x00-\xff]|\x40\x00|\x00\x00){4})){1,4}'


# --- hinting: 8 to 24 control values, four functions, a control value program,
# and the glyphs' programs (only in a font that has these tables)
#
# A program is a sequence of instructions, each with what it pops pushed before
# it: setting the vectors (SVTCA, SPVTCA, SFVTCA) and the rounding (RTG, RTHG,
# RTDG, RUTG, RDTG, ROFF, SROUND, S45ROUND), control values (SCVTCI, SSWCI, SSW,
# SMD, SCANTYPE, SCANCTRL), arithmetic and measurement whose result is popped
# (ADD, SUB, MUL, MAX, MIN, MPPEM, MPS), storage (WS, RS), the control values
# (WCVTP, WCVTF, RCVT), IF/ELSE/EIF, CALL; and in glyphs, moving points (MDAP,
# MIAP, MDRP, MIRP, SRP0-2, SHP, IP, ALIGNRP, DELTAP1) and IUP.
<hinting> ::= <cvt> <function>{4} <prep>?
<cvt> ::= rb'(?:[\x00-\x07\xf8-\xff][\x00-\xff]){8,24}'
<function> ::= rb'(?:[\x00-\x05\x18\x19\x3d\x7a\x7c\x7d]|\xb0[\x00-\xff][\x76\x77\x1d\x1e\x1f\x1a\x8d]|\xb8[\x00-\xff]{2}\x85|[\x4b\x4c]\x21|\xb1[\x00-\xff]{2}[\x60\x61\x63\x8b\x8c]\x21|\xb1[\x00-\x0f][\x00-\xff]\x42|\xb0[\x00-\x0f]\x43\x21|\xb1[\x00-\x07][\x00-\xff][\x44\x70]|\xb0[\x00-\x07]\x45\x21){1,6}'
<prep> ::= rb'(?:[\x00-\x05\x18\x19\x3d\x7a\x7c\x7d]|\xb0[\x00-\xff][\x76\x77\x1d\x1e\x1f\x1a\x8d]|\xb8[\x00-\xff]{2}\x85|[\x4b\x4c]\x21|\xb1[\x00-\xff]{2}[\x60\x61\x63\x8b\x8c]\x21|\xb1[\x00-\x0f][\x00-\xff]\x42|\xb0[\x00-\x0f]\x43\x21|\xb1[\x00-\x07][\x00-\xff][\x44\x70]|\xb0[\x00-\x07]\x45\x21|\xb0[\x00-\x03]\x2b|\xb0[\x00\x01]\x58(?:[\x00-\x05\x18\x19\x3d\x7a\x7c\x7d]|[\x4b\x4c]\x21){1,3}(?:\x1b(?:[\x00-\x05\x18\x19\x3d\x7a\x7c\x7d]|[\x4b\x4c]\x21){1,3})?\x59){1,8}'
<glyph_program> ::= rb'(?:[\x00-\x05\x18\x19\x3d\x7a\x7c\x7d\x30\x31]|\xb0[\x00-\xff][\x76\x77\x1d\x1e\x1f\x1a\x8d]|[\x4b\x4c]\x21|\xb1[\x00-\x0f][\x00-\xff]\x42|\xb1[\x00-\x07][\x00-\xff][\x44\x70]|\xb0[\x00-\x03]\x2b|\xb0[\x00-\x0f][\x2e\x2f\x10-\x12\x32\x33\x39\x3c\xc0-\xdf]|\xb1[\x00-\x0f][\x00-\x07][\x3e\x3f\xe0-\xff]|\xb2[\x00-\xff][\x00-\x0f]\x01\x5d|\xb4[\x00-\xff][\x00-\x0f][\x00-\xff][\x00-\x0f]\x02\x5d|\xb0[\x00\x01]\x58(?:[\x00-\x05\x18\x19\x30\x31]|[\x4b\x4c]\x21){1,3}(?:\x1b(?:[\x00-\x05\x18\x19\x30\x31]|[\x4b\x4c]\x21){1,3})?\x59){1,10}'


# --- head: what is not computed (the bounding box, checkSumAdjustment)
<head> ::= <font_revision> <head_flags> <units_per_em> <created> <modified> <head_settings>
<font_revision> ::= rb'\x00\x01\x00\x00|\x00\x01[\x00-\xff]{2}|[\x00-\x0f][\x00-\xff]{3}'
<head_flags> ::= rb'\x00[\x0b\x03\x09\x1b]|[\x00-\x3f][\x00-\xff]'
<units_per_em> ::= rb'\x03\xe8|\x04\x00|\x08\x00|\x01\x00|\x10\x00|[\x01-\x3f][\x00-\xff]|\x00[\x10-\xff]'
# seconds since 1904, from 1996 to 2036
<created> ::= rb'\x00{4}[\xad-\xff][\x00-\xff]{3}'
<modified> ::= rb'\x00{4}[\xad-\xff][\x00-\xff]{3}'
# macStyle, lowestRecPPEM, fontDirectionHint, and 00 for short loca or 01 for long
<head_settings> ::= rb'\x00[\x00-\x7f]\x00[\x03-\x20](?:\x00[\x00-\x02]|\xff[\xfe\xff])[\x00\x01]'

# hhea: ascender, descender and line gap, caret slope (rise and run) and offset,
# and 00 if every glyph has its advance in hmtx, 01 if the last ones share one
<hhea> ::= rb'[\x01-\x0f][\x00-\xff][\xf8-\xff][\x00-\xff]\x00[\x00-\xff](?:\x00\x01\x00\x00|[\x01-\x07][\x00-\xff]\x00[\x00-\xff])(?:\x00\x00|[\xff\x00][\x00-\xff])[\x00\x01]'

# OS/2, versions 0 to 5 (xAvgCharWidth and the first and last character are computed)
<os2> ::= b"\x00\x00" <os2_common> | b"\x00\x01" <os2_common> <code_pages> | b"\x00\x02" <os2_common> <code_pages> <os2_v2_fields> | b"\x00\x03" <os2_common> <code_pages> <os2_v2_fields> | b"\x00\x04" <os2_common> <code_pages> <os2_v2_fields> | b"\x00\x05" <os2_common> <code_pages> <os2_v2_fields> <optical_sizes>
<os2_common> ::= <os2_classes> <os2_script_metrics> <os2_identity> <os2_line_metrics>
# usWeightClass, usWidthClass, fsType
<os2_classes> ::= rb'(?:\x01\x90|\x02\xbc|\x00\x64|\x03\x84|\x01\x2c|\x00[\x01-\xff]|[\x01-\x03][\x00-\xff])\x00[\x01-\x09](?:\x00\x00|\x00\x02|\x00\x04|\x00\x08|\x01\x00|\x02\x00|\x03\x08)'
# subscript, superscript and strikeout sizes and positions
<os2_script_metrics> ::= rb'(?:[\x00-\x03][\x00-\xff]){10}'
# sFamilyClass, panose, ulUnicodeRange1-4, achVendID, fsSelection
<os2_identity> ::= rb'(?:\x00\x00|[\x01-\x0c][\x00-\x0f])(?:\x00{10}|\x02[\x00-\x0f]{9})(?:\x00\x00\x00\x01\x00{12}|[\x00-\xff]{16})(?:[A-Z]{4}|NONE|    |[A-Za-z]{2}  )(?:\x00\x40|\x00\x20|\x00\x01|\x00\x21|\x00\xc0|\x01\x40|\x02\x01|\x00[\x00-\x7f])'
# sTypoAscender, sTypoDescender, sTypoLineGap, usWinAscent, usWinDescent
<os2_line_metrics> ::= rb'[\x01-\x0f][\x00-\xff][\xf8-\xff][\x00-\xff]\x00[\x00-\xff][\x00-\x0f][\x00-\xff][\x00-\x07][\x00-\xff]'
<code_pages> ::= rb'\x00\x00\x00\x01\x00{4}|[\x00-\xff]{8}'
# sxHeight, sCapHeight, usDefaultChar, usBreakChar, usMaxContext
<os2_v2_fields> ::= rb'[\x00-\x07][\x00-\xff][\x00-\x0f][\x00-\xff](?:\x00\x00|\x00\x20)\x00\x20\x00[\x00-\x04]'
<optical_sizes> ::= rb'\x00[\x00-\xff]\xff[\x00-\xff]'

# post, version 2 (with the glyph names) or 3 (without): italicAngle,
# underlinePosition, underlineThickness, isFixedPitch, and the memory hints
<post> ::= b"\x00\x02\x00\x00" <post_header> | b"\x00\x03\x00\x00" <post_header>
<post_header> ::= rb'(?:\x00\x00\x00\x00|\xff\xf4\x00\x00|\xff\xf6\x80\x00|[\xff\x00][\x00-\xff]{3})(?:[\xff\x00][\x00-\xff]){2}\x00\x00\x00[\x00\x01](?:\x00{16}|[\x00-\xff]{16})'

# cmap: which characters map to which glyphs, in ranges: the first character
# (one of the common blocks, or any), how many (1 to 96), a glyph, and whether
# they map to consecutive glyphs, to glyphs here and there, or to that one glyph
<cmap> ::= <cmap_range>{1,6} <cmap_subtables>
<cmap_range> ::= rb'(?:\x00\x00\x20|\x00\x00\xa0|\x00\x03\x91|\x00\x04\x10|\x00\x20\x10|\x00\x4e\x00|\x00\xe0\x00|\x00\xff\x00|\x01\xf6\x00|\x01\xd4\x00|\x0f\x00\x00|\x00[\x00-\xff]{2}|[\x01-\x10][\x00-\xff]{2})[\x01-\x60][\x00-\xff][\x00-\x02]'
# The subtables: format 4 always, in segments of deltas (00) or of glyph
# arrays (01); format 12 when a character is outside the BMP; then a byte
# that adds (bit 0) copies for the Unicode platform, (bits 1, 2) a Macintosh
# format 0 or 6, (bit 3) a format 13; then up to three variation selectors
# (format 14), each a selector (FE00 on) and whether its sequences are the
# default glyphs (00), other glyphs (01) or both (02)
<cmap_subtables> ::= rb'[\x00\x01][\x00-\x0f](?:[\x00-\x1f][\x00-\x02]){0,3}'

# name: the strings for Windows (UTF-16), the Macintosh (Mac Roman) or both;
# a string is its name ID and its text (ID 6, the PostScript name, has a text
# of its own); language tags make it version 1, each with the family name
<name> ::= <name_platforms> <name_entry>{2,10} <lang_tags>?
<name_platforms> ::= b"windows" | b"mac" | b"both"
<name_entry> ::= rb'\x00\x06[A-Za-z][A-Za-z0-9-]{0,40}|(?:\x00[\x00-\x05\x07-\x0e\x10-\x19]|\x01[\x00-\x10])(?:[A-Za-z0-9]{1,12}|Gr\xc3\xbc\xc3\x9fe|\xc3\x85ngstr\xc3\xb6m|\xc2\xa9 2026|\xe2\x84\xa2|Bold Italic|Version 1\.000)(?: (?:[A-Za-z0-9]{1,12}|Regular|Italic)){0,5}'
<lang_tags> ::= rb'(?:en|de-CH|zh-Hant|sr-Latn|pt-BR|[a-z]{2,3})(?:,(?:en|de-CH|zh-Hant|sr-Latn|pt-BR|[a-z]{2,3})){0,2}'


# --- the tables a font may also have
<extra_tables> ::= <gasp>? <hdmx>? <ltsh>? <vdmx>? <kern>? <vertical>? <dsig>?

# gasp: version 0 (two behaviour bits) or 1 (four), and up to four sizes and
# their behaviour (the last size becomes FFFF)
<gasp> ::= rb'\x00\x00(?:[\x00-\xff]\x00[\x00-\x03]){1,4}|\x00\x01(?:[\x00-\xff]\x00[\x00-\x0f]){1,4}'
# hdmx: the sizes it has widths for (they are computed); LTSH: one threshold for every glyph
<hdmx> ::= rb'[\x08-\x40]{1,4}'
<ltsh> ::= rb'[\x01-\xff]'
# VDMX: its version, up to three aspect ratios (charset, x, y from, y to), and the sizes of its group
<vdmx> ::= rb'[\x00\x01](?:\x01\x00\x00\x00|\x01\x01\x01\x01|\x01\x02\x01\x01|\x00[\x00-\xff]{3}){1,3}[\x00-\xff]{2}'
# kern: the coverage of its subtable, and up to 12 pairs of glyphs and their value
<kern> ::= rb'(?:\x00\x01|\x00\x03|\x00\x05|\x00\x09)(?:[\x00-\xff]{2}[\xfe\xff\x00\x01][\x00-\xff]){1,12}'
# vhea and vmtx: version, ascender, descender and line gap (the metrics are computed)
<vertical> ::= rb'(?:\x00\x01\x00\x00|\x00\x01\x10\x00)[\x01-\x07][\x00-\xff][\xf8-\xff][\x00-\xff]\x00[\x00-\xff]'
# an empty DSIG, as fonts that were once signed have: its flags
<dsig> ::= rb'\x00[\x00\x01]'
