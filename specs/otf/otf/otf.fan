# OpenType fonts with CFF outlines: an sfnt of version OTTO whose glyphs are
# Type 2 charstrings in a CFF table, with the tables of the TrueType spec that
# do not depend on the outlines (head, hhea, hmtx, maxp 0.5, OS/2, name, post,
# cmap, and gasp, kern, vhea and vmtx, DSIG as each font chooses).
#
# A glyph is a path of moves, lines and curves, written with the operator that
# fits each piece (rlineto or hlineto, rrcurveto or hhcurveto, flex, ...), and
# as the glyph chooses: its width, stem hints, hint masks, and a part of its
# path in a local or a global subroutine. The CFF table has a Name INDEX, one
# Top DICT, a String INDEX for the names that are not standard strings, a
# charset (format 0, 1 or 2), the CharStrings and a Private DICT. Offsets in
# the DICTs, the bounding boxes, the hints and the metrics are computed.
#
# TODO:
# * No CID-keyed fonts (ROS, FDArray, FDSelect), no CFF2, no seac accents.
# * A glyph's hints are computed from its bounding box, not chosen.

include("ttf/ttf.fan")


# --- Type 2 charstrings

def t2_number(v):
    v = int(v)
    if -107 <= v <= 107:
        return u8(v + 139)
    if 108 <= v <= 1131:
        v -= 108
        return u8((v >> 8) + 247) + u8(v & 0xFF)
    if -1131 <= v <= -108:
        v = -v - 108
        return u8((v >> 8) + 251) + u8(v & 0xFF)
    return b"\x1c" + i16(v)


def t2(args, operator):
    return b"".join(t2_number(a) for a in args) + operator


RMOVETO, HMOVETO, VMOVETO = b"\x15", b"\x16", b"\x04"
RLINETO, HLINETO, VLINETO, RRCURVETO = b"\x05", b"\x06", b"\x07", b"\x08"
HHCURVETO, VVCURVETO, HVCURVETO, VHCURVETO = b"\x1b", b"\x1a", b"\x1f", b"\x1e"
RCURVELINE, RLINECURVE, FLEX = b"\x18", b"\x19", b"\x0c\x23"
HSTEM, VSTEM, HSTEMHM, VSTEMHM, HINTMASK = b"\x01", b"\x03", b"\x12", b"\x17", b"\x13"
CALLSUBR, CALLGSUBR, RETURN, ENDCHAR = b"\x0a", b"\x1d", b"\x0b", b"\x0e"
SUBR_BIAS = 107

# what each kind of piece of a path takes: a move, a line, a horizontal or a
# vertical line, a curve, the four curves that start or end along an axis, a
# curve and a line, a line and a curve, and flex (two curves)
PIECE_ARGS = {0: 2, 1: 2, 2: 1, 3: 1, 4: 6, 5: 4, 6: 4, 7: 4, 8: 4, 9: 8, 10: 8, 11: 12}


def read_cff_outline(reader):
    options = reader.u8()
    pieces = []
    while reader.left():
        kind = reader.u8()
        args = [reader.i16() for _ in range(PIECE_ARGS[kind])]
        if kind == 11:
            args.append(reader.u8())
        pieces.append((kind, args))
    return options, pieces


def cff_path(pieces, combine):
    """The points a path goes through (for its bounding box) and its operators, as (operator, args)."""
    at = [0, 0]
    points, ops = [], []

    def go(dx, dy):
        at[0] += dx
        at[1] += dy
        points.append((at[0], at[1]))

    if pieces and pieces[0][0] != 0:
        ops.append((RMOVETO, [0, 0]))
        points.append((0, 0))
    for kind, a in pieces:
        if kind == 0:
            if a[0] == 0:
                ops.append((VMOVETO, [a[1]]))
            elif a[1] == 0:
                ops.append((HMOVETO, [a[0]]))
            else:
                ops.append((RMOVETO, a))
            go(a[0], a[1])
        elif kind == 1:
            ops.append((RLINETO, a))
            go(a[0], a[1])
        elif kind == 2:
            ops.append((HLINETO, a))
            go(a[0], 0)
        elif kind == 3:
            ops.append((VLINETO, a))
            go(0, a[0])
        elif kind == 4:
            ops.append((RRCURVETO, a))
            go(a[0], a[1])
            go(a[2], a[3])
            go(a[4], a[5])
        elif kind == 5:
            ops.append((HHCURVETO, a))
            go(a[0], 0)
            go(a[1], a[2])
            go(a[3], 0)
        elif kind == 6:
            ops.append((VVCURVETO, a))
            go(0, a[0])
            go(a[1], a[2])
            go(0, a[3])
        elif kind == 7:
            ops.append((HVCURVETO, a))
            go(a[0], 0)
            go(a[1], a[2])
            go(0, a[3])
        elif kind == 8:
            ops.append((VHCURVETO, a))
            go(0, a[0])
            go(a[1], a[2])
            go(a[3], 0)
        elif kind == 9:
            ops.append((RCURVELINE, a))
            for i in range(0, 8, 2):
                go(a[i], a[i + 1])
        elif kind == 10:
            ops.append((RLINECURVE, a))
            for i in range(0, 8, 2):
                go(a[i], a[i + 1])
        else:
            ops.append((FLEX, a[:12] + [a[12] & 0x7F]))
            for i in range(0, 12, 2):
                go(a[i], a[i + 1])
    if combine:   # consecutive lines and curves of one kind in one operator, as far as the stack allows
        merged = []
        for piece in ops:
            op, args = piece
            if (merged and op == merged[-1][0] and op in (RLINETO, RRCURVETO, HHCURVETO, VVCURVETO)
                    and len(merged[-1][1]) + len(args) <= 46):
                merged[-1] = (op, merged[-1][1] + args)
            else:
                merged.append((op, list(args)))
        ops = merged
    return points, ops


def mask(count, every=1):
    """A hint mask: one bit for each of `count` stems, from the first one on (or every other one)."""
    size = (count + 7) // 8
    bits = 0
    for n in range(0, count, every):
        bits |= 1 << (8 * size - 1 - n)
    return bits.to_bytes(size, "big")


def stems(low, high):
    """Stems at the two edges of a span, as Type 2 hints write them (each relative to the one before)."""
    if high - low > 60:
        return [low, 20, high - low - 40, 20]
    return [low, max(1, high - low)]


def read_cff_glyphs(font):
    """Each glyph as a dict: advance, name, bounding box, and its charstring before subroutines."""
    steps, widths = em_scale(font, 1000), em_scale(font, 2048)
    node = kid(font, "<cff_glyphs>")
    nodes = [alt(kid(node, "<cff_notdef>"))] + [alt(g) for g in kids(node, "<cff_glyph>")]
    glyphs = []
    for index, outline in enumerate(nodes):
        reader = Reader(tok(outline))
        advance, name = glyph_header(reader)
        glyph = {"advance": widths(advance), "name": ("std", 0) if index == 0 else name, "kind": "empty",
                 "options": 0, "ops": [], "points": []}
        if sym(outline) == "<cff_outline>":
            glyph["kind"] = "cff"
            glyph["options"], pieces = read_cff_outline(reader)
            pieces = [(kind, [steps(a) for a in args[:12]] + args[12:]) for kind, args in pieces]
            glyph["points"], glyph["ops"] = cff_path(pieces, glyph["options"] & 0x20)
        glyph["bbox"] = glyph_bbox(glyph["points"])
        glyphs.append(glyph)
    return glyphs


def charstring(glyph, nominal, local_subrs, global_subrs):
    options = glyph["options"]
    width = [glyph["advance"] - nominal] if options & 4 else []
    out = b""
    box = glyph["bbox"]
    if box and options & 1:
        h, v = stems(box[1], box[3]), stems(box[0], box[2])
        if options & 2:
            out += t2(width + h, HSTEMHM) + t2(v, VSTEMHM) + HINTMASK + mask((len(h) + len(v)) // 2)
        else:
            out += t2(width + h, HSTEM) + t2(v, VSTEM)
        width = []
    ops = glyph["ops"]
    if ops:
        first, rest = ops[0], ops[1:]
        out += t2(width + first[1], first[0])
        width = []
        body = b""
        for n, piece in enumerate(rest):
            if box and options & 3 == 3 and n == len(rest) // 2:
                h, v = stems(box[1], box[3]), stems(box[0], box[2])
                body += HINTMASK + mask((len(h) + len(v)) // 2, 2)
            body += t2(piece[1], piece[0])
        if body and options & 8:
            local_subrs.append(body + RETURN)
            body = t2([len(local_subrs) - 1 - SUBR_BIAS], CALLSUBR)
        elif body and options & 16:
            global_subrs.append(body + RETURN)
            body = t2([len(global_subrs) - 1 - SUBR_BIAS], CALLGSUBR)
        out += body
    return out + t2(width, ENDCHAR)


# --- the CFF table

def cff_index(items, off_size=1):
    if not items:
        return u16(0)
    offsets = [1]
    for item in items:
        offsets.append(offsets[-1] + len(item))
    size = max(off_size, (offsets[-1].bit_length() + 7) // 8)
    return (u16(len(items)) + u8(size) + b"".join(o.to_bytes(size, "big") for o in offsets)
            + b"".join(items))


def dict_int(v):
    v = int(v)
    if -1131 <= v <= 1131:
        return t2_number(v)
    if -32768 <= v <= 32767:
        return b"\x1c" + i16(v)
    return b"\x1d" + struct.pack(">i", v)


def dict_offset(v):
    return b"\x1d" + struct.pack(">i", v)


def dict_real(text):
    nibbles = []
    i = 0
    while i < len(text):
        c = text[i]
        if c.isdigit():
            nibbles.append(int(c))
        elif c == ".":
            nibbles.append(0xA)
        elif c == "-" and i == 0:
            nibbles.append(0xE)
        elif c in "eE":
            if text[i + 1] == "-":
                nibbles.append(0xC)
                i += 1
            else:
                nibbles.append(0xB)
                if text[i + 1] == "+":
                    i += 1
        i += 1
    nibbles.append(0xF)
    if len(nibbles) % 2:
        nibbles.append(0xF)
    return b"\x1e" + bytes(nibbles[n] << 4 | nibbles[n + 1] for n in range(0, len(nibbles), 2))


def private_dict(private):
    data = tok(private)
    mask = data[0]
    blues = sorted(sint(data[i:i + 2]) for i in range(1, 13, 2))
    std_hw, std_vw = data[13], data[14]
    default_width, nominal_width = uint(data[15:17]), uint(data[17:19])
    out = b""

    def deltas(values):
        return [values[0]] + [values[i] - values[i - 1] for i in range(1, len(values))]

    if mask & 1:
        out += b"".join(dict_int(v) for v in deltas(blues[:4])) + b"\x06"
    if mask & 2:
        out += b"".join(dict_int(v) for v in deltas(blues[4:6])) + b"\x07"
    if mask & 4:
        out += dict_int(std_hw) + b"\x0a" + dict_int(std_vw) + b"\x0b"
    if mask & 8:
        out += dict_int(std_hw) + dict_int(5) + b"\x0c\x0c" + dict_int(std_vw) + dict_int(7) + b"\x0c\x0d"
    if mask & 16:
        out += dict_real("0.039625") + b"\x0c\x09" + dict_int(7) + b"\x0c\x0a" + dict_int(1) + b"\x0c\x0b"
    if mask & 32:
        out += dict_int(1) + b"\x0c\x0e"
    if mask & 64:
        out += dict_int(1) + b"\x0c\x11"
    if mask & 128:
        out += dict_real("0.06") + b"\x0c\x12" + dict_int(0) + b"\x0c\x13"
    out += dict_int(default_width) + b"\x14" + dict_int(nominal_width) + b"\x15"
    return out, default_width, nominal_width


def charset(glyphs, strings, form):
    sids, used = [], set()
    for n, glyph in enumerate(glyphs[1:]):
        kind, value = glyph["name"]
        name = value if kind == "custom" else None
        if kind == "std" and value not in used:
            sid = value
        else:
            if not name or name in strings:
                name = "glyph%d" % (n + 1)
                while name in strings:
                    name += "_"
            if name not in strings:
                strings.append(name)
            sid = 391 + strings.index(name)
        used.add(sid)
        sids.append(sid)
    if form == 0:
        return u8(0) + b"".join(u16(s) for s in sids)
    ranges = []
    for sid in sids:
        if ranges and sid == ranges[-1][0] + ranges[-1][1] + 1 and ranges[-1][1] < (255 if form == 1 else 65535):
            ranges[-1][1] += 1
        else:
            ranges.append([sid, 0])
    left = u8 if form == 1 else u16
    return u8(form) + b"".join(u16(r[0]) + left(r[1]) for r in ranges)


def postscript_name(font):
    for entry in kids(kid(font, "<name>"), "<name_entry>"):
        data = tok(entry)
        if data[:2] == b"\x00\x06":
            return data[2:]
    return b"FanbaseSans-Regular"


def cff_table(font, glyphs, box):
    options = tok(kid(font, "<cff_options>"))
    form, off_size = options[0], options[1]
    private, default_width, nominal_width = private_dict(kid(font, "<cff_private>"))
    for glyph in glyphs:
        if not glyph["options"] & 4:
            glyph["advance"] = default_width
    local_subrs, global_subrs = [], []
    charstrings = [charstring(g, nominal_width, local_subrs, global_subrs) for g in glyphs]
    strings = ["1.000", "Made with Fandango", "Fanbase Sans", "Fanbase", "Regular"]
    charset_data = charset(glyphs, strings, form)
    upem = units_per_em(font)
    post_header = tok(kid(kid(font, "<post>"), "<post_header>"))
    top = (dict_int(391) + b"\x00" + dict_int(392) + b"\x01" + dict_int(393) + b"\x02" + dict_int(394) + b"\x03"
           + dict_int(395) + b"\x04" + dict_int(sint(post_header[4:6])) + b"\x0c\x03"
           + dict_int(sint(post_header[6:8])) + b"\x0c\x04")
    if upem != 1000:
        scale = "%.8g" % (1.0 / upem)
        top += dict_real(scale) + dict_int(0) + dict_int(0) + dict_real(scale) + dict_int(0) + dict_int(0) + b"\x0c\x07"
    top += b"".join(dict_int(v) for v in box) + b"\x05"
    fixed = len(top) + 23   # the offsets of the charset, the CharStrings and the Private DICT, below
    if local_subrs:
        private += dict_offset(len(private) + 6) + b"\x13"
    header = b"\x01\x00\x04" + u8(max(1, off_size))
    names = cff_index([postscript_name(font)], off_size)
    strings_index = cff_index([s.encode("ascii") for s in strings], off_size)
    globals_index = cff_index(global_subrs, off_size)
    top_size = len(cff_index([bytes(fixed)], off_size))
    start = len(header) + len(names) + top_size + len(strings_index) + len(globals_index)
    charstrings_at = start + len(charset_data)
    charstrings_index = cff_index(charstrings, off_size)
    private_at = charstrings_at + len(charstrings_index)
    top += (dict_offset(start) + b"\x0f" + dict_offset(charstrings_at) + b"\x11"
            + dict_offset(len(private)) + dict_offset(private_at) + b"\x12")
    return (header + names + cff_index([top], off_size) + strings_index + globals_index + charset_data
            + charstrings_index + private + cff_index(local_subrs, off_size))


def otf_tables(font):
    glyphs = read_cff_glyphs(font)
    box = union_bbox([g["bbox"] for g in glyphs])
    cff = cff_table(font, glyphs, box)
    tables, box = shared_tables(font, glyphs)
    tables[b"CFF "] = cff
    tables[b"head"] = head_table(kid(font, "<head>"), box, False)
    tables[b"maxp"] = b"\x00\x00\x50\x00" + u16(len(glyphs))
    return tables


def otf_sfnt(font):
    return sfnt_layout(b"OTTO", otf_tables(font))


<start> ::= <otf>
<otf> ::= <font_file> := otf_sfnt(<cff_font>)

<cff_font> ::= <cff_glyphs> <cff_private> <cff_options> <head> <hhea> <os2> <post> <cmap> <name> <cff_extra_tables>

# The glyphs: .notdef, drawn, and 1 to 15 more, their steps measured in an em
# of 1000 units scaled to the font's unitsPerEm. A glyph's record starts as a
# TrueType glyph's does (advance width, name), then a byte of options (bit 0:
# stem hints, bit 1: hint masks, bit 2: the width in the charstring rather than
# the default width, bit 3: its path in a local subroutine, bit 4: in a global
# one, bit 5: consecutive lines or curves in one operator), then 1 to 20 pieces
# of path. A piece is its kind and its steps (-512 to 511): 00 a move (dx dy),
# 01 a line (dx dy), 02 a horizontal line (dx), 03 a vertical one (dy), 04 a
# curve (three points), 05 and 06 curves that start and end horizontally or
# vertically, 07 and 08 curves that start along one axis and end along the
# other, 09 a curve and a line, 0A a line and a curve, 0B flex (two curves, and
# its depth).
<cff_glyphs> ::= <cff_notdef> <cff_glyph>{1,15}
<cff_notdef> ::= <cff_outline>
<cff_glyph> ::= <empty_glyph> | <cff_outline>
<cff_outline> ::= rb'[\x00-\x07][\x00-\xff](?:\x00[\x01-\xff]|\x01(?:[A-Za-z][A-Za-z0-9._]{0,15}|uni[0-9A-F]{4}|u[0-9A-F]{5})\x00)[\x00-\x3f](?:[\x00\x01](?:[\xfe\xff\x00\x01][\x00-\xff]){2}|[\x02\x03][\xfe\xff\x00\x01][\x00-\xff]|\x04(?:[\xfe\xff\x00\x01][\x00-\xff]){6}|[\x05-\x08](?:[\xfe\xff\x00\x01][\x00-\xff]){4}|[\x09\x0a](?:[\xfe\xff\x00\x01][\x00-\xff]){8}|\x0b(?:[\xfe\xff\x00\x01][\x00-\xff]){12}[\x00-\x7f]){1,20}'

# The Private DICT: a byte that says which entries it has (bit 0: BlueValues,
# 1: OtherBlues, 2: StdHW and StdVW, 3: StemSnapH and StemSnapV, 4: BlueScale,
# BlueShift and BlueFuzz, 5: ForceBold, 6: LanguageGroup, 7: ExpansionFactor
# and initialRandomSeed), six values for the blue zones, the two standard stem
# widths, defaultWidthX and nominalWidthX
<cff_private> ::= rb'[\x00-\xff](?:[\xfe\xff\x00-\x03][\x00-\xff]){6}[\x01-\xff]{2}[\x00-\x07][\x00-\xff][\x00-\x07][\x00-\xff]'

# The charset's format (0, 1 or 2), and the smallest size of the INDEXes' offsets
<cff_options> ::= rb'[\x00-\x02][\x01-\x04]'

# CFF fonts have no TrueType hinting or device metrics
<cff_extra_tables> ::= <gasp>? <kern>? <vertical>? <dsig>?
