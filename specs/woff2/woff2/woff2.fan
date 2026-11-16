# WOFF2 fonts: a TrueType or a CFF font, as the TTF and OTF specs make them,
# whose tables are compressed together with Brotli, and optionally an extended
# metadata block (the XML of the WOFF spec, compressed with Brotli) and a
# private data block.
#
# The glyf and loca tables of a TrueType font are transformed (glyf as streams
# of contour and point counts, flags, triplet-encoded coordinates, composite
# records, bounding boxes and instructions, loca left out) or given the null
# transform, as the font chooses; so is hmtx, whose left side bearings can be
# left out when they are the glyphs' xMin. The header, the table directory
# (known tags by number, UIntBase128 lengths) and the streams' sizes are
# computed.
#
# TODO:
# * No font collections.
# * Coordinates are triplet-encoded in the smallest or the largest form, not a
#   mixture.

include("woff/woff.fan")

import brotli


KNOWN_TAGS = [b"cmap", b"head", b"hhea", b"hmtx", b"maxp", b"name", b"OS/2", b"post", b"cvt ", b"fpgm", b"glyf",
              b"loca", b"prep", b"CFF ", b"VORG", b"EBDT", b"EBLC", b"gasp", b"hdmx", b"kern", b"LTSH", b"PCLT",
              b"VDMX", b"vhea", b"vmtx", b"BASE", b"GDEF", b"GPOS", b"GSUB", b"EBSC", b"JSTF", b"MATH", b"CBDT",
              b"CBLC", b"COLR", b"CPAL", b"SVG ", b"sbix", b"acnt", b"avar", b"bdat", b"bloc", b"bsln", b"cvar",
              b"fdsc", b"feat", b"fmtx", b"fvar", b"gvar", b"hsty", b"just", b"lcar", b"mort", b"morx", b"opbd",
              b"prop", b"trak", b"Zapf", b"Silf", b"Glat", b"Gloc", b"Feat", b"Sill"]


def base128(n):
    out = [n & 0x7F]
    n >>= 7
    while n:
        out.insert(0, 0x80 | (n & 0x7F))
        n >>= 7
    return bytes(out)


def uint255(n, widest):
    if widest:
        return b"\xfd" + u16(n)
    if n < 253:
        return u8(n)
    if n < 506:
        return b"\xff" + u8(n - 253)
    if n < 762:
        return b"\xfe" + u8(n - 506)
    return b"\xfd" + u16(n)


def triplet(on, dx, dy, widest):
    """A point's flag byte and its coordinate bytes, as WOFF2 encodes them."""
    off = 0 if on else 128
    ax, ay = abs(dx), abs(dy)
    xs, ys = 0 if dx < 0 else 1, 0 if dy < 0 else 1
    if widest or ax >= 4096 or ay >= 4096:
        return u8(off + 124 + xs + 2 * ys), u16(ax) + u16(ay)
    if dx == 0 and ay < 1280:
        return u8(off + ((ay & 0xF00) >> 7) + ys), u8(ay & 0xFF)
    if dy == 0 and ax < 1280:
        return u8(off + 10 + ((ax & 0xF00) >> 7) + xs), u8(ax & 0xFF)
    if ax < 65 and ay < 65:
        return (u8(off + 20 + ((ax - 1) & 0x30) + (((ay - 1) & 0x30) >> 2) + xs + 2 * ys),
                u8((((ax - 1) & 0xF) << 4) | ((ay - 1) & 0xF)))
    if ax < 769 and ay < 769:
        return (u8(off + 84 + 12 * (((ax - 1) & 0x300) >> 8) + (((ay - 1) & 0x300) >> 6) + xs + 2 * ys),
                u8((ax - 1) & 0xFF) + u8((ay - 1) & 0xFF))
    return u8(off + 120 + xs + 2 * ys), u8(ax >> 4) + u8(((ax & 0xF) << 4) | (ay >> 8)) + u8(ay & 0xFF)


def read_points(data, at, count):
    """The flags and coordinates of a simple glyph's `count` points, from `at`; and where they end."""
    flags = []
    while len(flags) < count:
        flag = data[at]
        at += 1
        repeat = 1
        if flag & 0x08:
            repeat += data[at]
            at += 1
        flags += [flag] * repeat
    deltas = []
    for axis, short, same in ((0, 0x02, 0x10), (1, 0x04, 0x20)):
        values = []
        for flag in flags:
            if flag & short:
                value = data[at]
                at += 1
                values.append(value if flag & same else -value)
            elif flag & same:
                values.append(0)
            else:
                values.append(sint(data[at:at + 2]))
                at += 2
        deltas.append(values)
    return flags, deltas[0], deltas[1], at


def component_records(data):
    """The bytes of a composite glyph's components, and whether it has instructions."""
    at, more, instructions = 10, True, False
    while more:
        flags = uint(data[at:at + 2])
        size = 4 + (4 if flags & 0x0001 else 2)
        size += 2 if flags & 0x0008 else 4 if flags & 0x0040 else 8 if flags & 0x0080 else 0
        more, instructions = bool(flags & 0x0020), instructions or bool(flags & 0x0100)
        at += size
    return data[10:at], instructions, at


def transform_glyf(glyf, loca, count, long_loca, explicit_boxes, widest):
    if long_loca:
        offsets = [uint(loca[4 * i:4 * i + 4]) for i in range(count + 1)]
    else:
        offsets = [2 * uint(loca[2 * i:2 * i + 2]) for i in range(count + 1)]
    contours, points, flags, glyphs, composites, boxes, programs = b"", b"", b"", b"", b"", b"", b""
    box_bits, overlap_bits = bytearray(4 * ((count + 31) // 32)), bytearray((count + 7) // 8)
    for i in range(count):
        data = glyf[offsets[i]:offsets[i + 1]]
        if not data:
            contours += i16(0)
            continue
        n = sint(data[0:2])
        if n >= 0:
            ends = [uint(data[10 + 2 * c:12 + 2 * c]) for c in range(n)]
            at = 10 + 2 * n
            length = uint(data[at:at + 2])
            program = data[at + 2:at + 2 + length]
            point_flags, xs, ys, at = read_points(data, at + 2 + length, ends[-1] + 1)
            contours += i16(n)
            last = -1
            for end in ends:
                points += uint255(end - last, widest)
                last = end
            for flag, dx, dy in zip(point_flags, xs, ys):
                f, coords = triplet(flag & 1, dx, dy, widest)
                flags += f
                glyphs += coords
            glyphs += uint255(len(program), widest)
            programs += program
            if point_flags[0] & 0x40:
                overlap_bits[i >> 3] |= 0x80 >> (i & 7)
            if explicit_boxes:
                box_bits[i >> 3] |= 0x80 >> (i & 7)
                boxes += data[2:10]
        else:
            records, has_program, at = component_records(data)
            contours += i16(-1)
            composites += records
            if has_program:
                length = uint(data[at:at + 2])
                glyphs += uint255(length, widest)
                programs += data[at + 2:at + 2 + length]
            box_bits[i >> 3] |= 0x80 >> (i & 7)
            boxes += data[2:10]
    overlaps = any(overlap_bits)
    boxes = bytes(box_bits) + boxes
    streams = [contours, points, flags, glyphs, composites, boxes, programs]
    return (u16(0) + u16(1 if overlaps else 0) + u16(count) + u16(1 if long_loca else 0)
            + b"".join(u32(len(s)) for s in streams) + b"".join(streams) + (bytes(overlap_bits) if overlaps else b""))


def transform_hmtx(hmtx, metrics, count, flags):
    advances = b"".join(hmtx[4 * i:4 * i + 2] for i in range(metrics))
    bearings = b"".join(hmtx[4 * i + 2:4 * i + 4] for i in range(metrics))
    rest = hmtx[4 * metrics:]
    return u8(flags) + advances + (b"" if flags & 1 else bearings) + (b"" if flags & 2 else rest)


def woff2(font):
    settings = tok(kid(font, "<woff2_settings>"))
    glyf_null, hmtx_flags, explicit_boxes, widest, quality = settings[4], settings[5], settings[6], settings[7], settings[8]
    version, tables = font_flavor(kid(font, "<woff_flavor>"))
    tags = sorted(tables)
    if b"loca" in tags:
        tags.remove(b"loca")
        tags.insert(tags.index(b"glyf") + 1, b"loca")
    count = uint(tables[b"maxp"][4:6])
    stream, directory = b"", b""
    for tag in tags:
        data, transformed, flags = tables[tag], None, 0
        if tag in (b"glyf", b"loca"):
            if glyf_null:
                flags = 0xC0
            elif tag == b"glyf":
                long_loca = uint(tables[b"head"][50:52]) == 1
                transformed = transform_glyf(data, tables[b"loca"], count, long_loca, explicit_boxes, widest)
            else:
                transformed = b""
        elif tag == b"hmtx" and hmtx_flags and b"glyf" in tables and not glyf_null:
            flags = 0x40
            transformed = transform_hmtx(data, uint(tables[b"hhea"][34:36]), count, hmtx_flags)
        if tag in KNOWN_TAGS:
            flags |= KNOWN_TAGS.index(tag)
            entry = u8(flags)
        else:
            entry = u8(flags | 63) + tag
        entry += base128(len(data))
        if transformed is not None:
            entry += base128(len(transformed))
            stream += transformed
        else:
            stream += data
        directory += entry
    packed = brotli.compress(stream, quality=quality)
    total = 12 + 16 * len(tags) + sum(len(pad4(tables[t])) for t in tags)
    start = 48 + len(directory)
    meta, private = kid(font, "<woff_metadata>"), kid(font, "<woff_private>")
    blocks = packed

    def align(data):   # every block starts, and the file ends, at a multiple of four bytes
        return data + b"\0" * (-(start + len(data)) % 4)

    blocks = align(blocks)
    meta_offset = meta_length = meta_original = private_offset = private_length = 0
    if meta is not None:
        xml = woff_metadata(meta)
        compressed = brotli.compress(xml)
        meta_offset, meta_length, meta_original = start + len(blocks), len(compressed), len(xml)
        blocks = align(blocks + compressed)
    if private is not None:
        private_offset, private_length = start + len(blocks), len(tok(private))
        blocks = align(blocks + tok(private))
    header = (b"wOF2" + version + u32(start + len(blocks)) + u16(len(tags)) + u16(0) + u32(total) + u32(len(packed))
              + settings[0:4] + u32(meta_offset) + u32(meta_length) + u32(meta_original) + u32(private_offset)
              + u32(private_length))
    return header + directory + blocks


<start> ::= <woff2>
<woff2> ::= <woff2_file> := woff2(<woff2_font>)
<woff2_file> ::= rb'(?s).+'

<woff2_font> ::= <woff2_settings> <woff_metadata>? <woff_private>? <woff_flavor>

# majorVersion and minorVersion (the font's version), then whether glyf and loca
# are transformed (00) or given the null transform (01); the flags of the hmtx
# transform (00: none; bit 0: leave out the advance-width glyphs' bearings,
# bit 1: the others'); whether simple glyphs have their bounding box too (01) or
# only composites (00); whether numbers take their smallest form (00) or the
# largest (01); and the Brotli quality (0 to 11)
<woff2_settings> ::= rb'(?:\x00\x01|[\x00-\x0f][\x00-\xff])[\x00-\xff]{2}[\x00\x01][\x00-\x03][\x00\x01][\x00\x01][\x00-\x0b]'
