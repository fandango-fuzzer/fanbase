# WOFF 1.0 fonts: a TrueType or a CFF font, as the TTF and OTF specs make
# them, with each table compressed with zlib (or stored, when that is no
# smaller, or as the font chooses), and optionally an extended metadata block
# (XML, compressed) and a private data block.
#
# The header (flavor, length, totalSfntSize, the offsets and lengths of the
# blocks), the table directory (offsets, compressed and original lengths, the
# original checksums) and the padding between blocks are computed.
#
# TODO:
# * The metadata is always well-formed and in the elements' usual order.

include("otf/otf.fan")

import zlib


def sfnt_tables(font):
    """The tables of an sfnt as they are laid out in it, head's checkSumAdjustment included."""
    count = uint(font[4:6])
    tables = {}
    for n in range(count):
        record = font[12 + 16 * n:28 + 16 * n]
        offset, length = uint(record[8:12]), uint(record[12:16])
        tables[record[:4]] = font[offset:offset + length]
    return tables


def font_flavor(flavor):
    """The sfnt version and the tables of the font a WOFF or WOFF2 file holds."""
    inner = alt(flavor)
    if sym(inner) == "<truetype_font>":
        version, tables = b"\x00\x01\x00\x00", truetype_tables(inner)
    else:
        version, tables = b"OTTO", otf_tables(inner)
    return version, sfnt_tables(sfnt_layout(version, tables))


def woff_metadata(node):
    return (b'<?xml version="1.0" encoding="UTF-8"?>\n<metadata version="1.0">\n'
            + b"".join(tok(e) + b"\n" for e in kids(node, "<meta_element>")) + b"</metadata>\n")


def woff(font):
    settings = tok(kid(font, "<woff_settings>"))
    version, tables = font_flavor(kid(font, "<woff_flavor>"))
    store, level, in_sfnt_order = settings[4], settings[5], settings[6]
    tags = sorted(tables)
    order = [t for t in TABLE_ORDER if t in tables] + [t for t in tags if t not in TABLE_ORDER] if in_sfnt_order else tags
    data = {}
    for n, tag in enumerate(tags):
        packed = zlib.compress(tables[tag], level)
        keep = store == 0 or (store == 2 and n % 2 == 0)
        data[tag] = packed if keep and len(packed) < len(tables[tag]) else tables[tag]
    offset = 44 + 20 * len(tags)
    placed, blocks = {}, b""
    for tag in order:
        placed[tag] = offset + len(blocks)
        blocks += pad4(data[tag])
    end = offset + len(blocks)
    meta = kid(font, "<woff_metadata>")
    private = kid(font, "<woff_private>")
    meta_offset = meta_length = meta_original = 0
    if meta is not None:   # padded only if the private block follows it
        xml = woff_metadata(meta)
        packed = zlib.compress(xml, level or 6)
        meta_offset, meta_length, meta_original = end, len(packed), len(xml)
        blocks += pad4(packed) if private is not None else packed
        end += len(pad4(packed))
    private_offset = private_length = 0
    if private is not None:
        private_offset, private_length = end, len(tok(private))
        blocks += tok(private)
    total = 12 + 16 * len(tags) + sum(len(pad4(tables[t])) for t in tags)
    directory = b"".join(tag + u32(placed[tag]) + u32(len(data[tag])) + u32(len(tables[tag]))
                         + u32(table_checksum(tables[tag])) for tag in tags)
    header = (b"wOFF" + version + u32(44 + len(directory) + len(blocks)) + u16(len(tags)) + u16(0) + u32(total)
              + settings[0:4] + u32(meta_offset) + u32(meta_length) + u32(meta_original) + u32(private_offset)
              + u32(private_length))
    return header + directory + blocks


<start> ::= <woff>
<woff> ::= <woff_file> := woff(<woff_font>)
<woff_file> ::= rb'(?s).+'

<woff_font> ::= <woff_settings> <woff_metadata>? <woff_private>? <woff_flavor>
<woff_flavor> ::= <truetype_font> | <cff_font>

# majorVersion and minorVersion (the font's version), then a byte that says
# which tables are compressed (00: each one that gets smaller, 01: none, 02:
# every other one), the zlib level, and whether the tables are in the order of
# the directory (00) or the usual order of an sfnt (01). Tables are padded to
# four bytes, the block at the end of the file is not.
<woff_settings> ::= rb'(?:\x00\x01|[\x00-\x0f][\x00-\xff])[\x00-\xff]{2}[\x00-\x02][\x00-\x09][\x00\x01]'

# the extended metadata: the elements of WOFF's metadata format
<woff_metadata> ::= <meta_element>{1,6}
<meta_element> ::= <meta_uniqueid> | <meta_vendor> | <meta_credits> | <meta_description> | <meta_license> | <meta_copyright> | <meta_trademark> | <meta_licensee> | <meta_extension>
<meta_uniqueid> ::= rb'<uniqueid id="[a-z]{2,8}(?:\.[a-z0-9]{1,8}){1,3}"/>'
<meta_vendor> ::= rb'<vendor name="[A-Za-z][A-Za-z ]{0,19}"(?: url="https?://[a-z]{1,12}\.(?:com|org|de)/?")?(?: dir="(?:ltr|rtl)")?(?: class="[a-z]{1,8}")?/>'
<meta_credits> ::= rb'<credits>(?:<credit name="[A-Za-z][A-Za-z ]{0,19}"(?: url="https://[a-z]{1,10}\.org")?(?: role="[A-Za-z]{1,12}")?(?: dir="(?:ltr|rtl)")?/>){1,3}</credits>'
<meta_description> ::= rb'<description(?: url="https://[a-z]{1,10}\.org")?>(?:<text(?: xml:lang="(?:en|de|fr|ja)")?(?: dir="rtl")?>[A-Za-z0-9 .,]{0,60}</text>){1,3}</description>'
<meta_license> ::= rb'<license(?: url="https://[a-z]{1,10}\.org/license")?(?: id="[A-Za-z0-9.-]{1,12}")?>(?:<text(?: xml:lang="(?:en|de)")?>[A-Za-z0-9 .,]{0,60}</text>){0,2}</license>'
<meta_copyright> ::= rb'<copyright><text(?: xml:lang="en")?>(?:Copyright|\xc2\xa9) 20[0-9]{2} [A-Za-z][A-Za-z ]{0,19}</text></copyright>'
<meta_trademark> ::= rb'<trademark><text>[A-Za-z][A-Za-z ]{0,19} is a trademark\.</text></trademark>'
<meta_licensee> ::= rb'<licensee name="[A-Za-z][A-Za-z ]{0,19}"(?: dir="(?:ltr|rtl)")?(?: class="[a-z]{1,8}")?/>'
<meta_extension> ::= rb'<extension(?: id="[a-z]{1,8}")?>(?:<name(?: xml:lang="en")?>[A-Za-z][A-Za-z ]{0,15}</name>)?(?:<item(?: id="[a-z]{1,8}")?><name>[A-Za-z][A-Za-z ]{0,15}</name><value>[A-Za-z0-9 ]{1,16}</value></item>){1,3}</extension>'

# private data: anything
<woff_private> ::= rb'[\x00-\xff]{1,64}'
