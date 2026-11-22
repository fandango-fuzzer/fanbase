# gzip files at the edges of RFC 1952 and of what readers do with them: a
# member with no data, one whose data takes two stored blocks (the first of
# the largest size, 65,535 bytes), a DEFLATE stream with a sync flush and a
# full flush in it (an empty stored block each), runs that make matches of
# the longest length (258), a name and a comment of up to 2,000 Latin-1
# characters or of none, several FEXTRA subfields under an FHCRC, MTIME, XFL
# and OS of any value, four members in a row (one with no data), and a member
# followed by zero bytes, which gzip skips with a warning and other readers
# may refuse. The CRC-32 and size of every member come from where
# constraints, as in gz.
#
# TODO:
# * The reserved flag bits and compression methods other than 8 are left
#   out: RFC 1952 says to refuse them, and readers do.

include("gz/gz.fan")


# A raw DEFLATE stream of data made from what Fandango drew: nothing; 65,536
# bytes or more, stored; three parts with a sync flush and a full flush
# between them; or one byte repeated 1,000 times or more.
def make_edge_deflate(seed, kind):
    seed = bytes(seed) or b"\x00"
    if kind == "empty":
        data, level = b"", 6
    elif kind == "big":
        data, level = (seed * (65536 // len(seed) + 2))[:65536 + len(seed)], 0
    elif kind == "longrun":
        data, level = bytes([seed[0]]) * (1000 + 37 * len(seed)), 9
    else:
        data, level = None, 6
    co = zlib.compressobj(level, zlib.DEFLATED, -15)
    if data is not None:
        return co.compress(data) + co.flush()
    third = max(1, len(seed) // 3)
    return (co.compress(seed[:third]) + co.flush(zlib.Z_SYNC_FLUSH)
            + co.compress(seed[third:2 * third]) + co.flush(zlib.Z_FULL_FLUSH)
            + co.compress(seed[2 * third:]) + co.flush())


<start> ::= <m_empty> | <m_big> | <m_sync> | <m_longrun> | <m_fields> \
          | <m_extras> | <m_members> | <m_padded>

<any_xfl> ::= <byte>
<any_os>  ::= <byte>
<max_mtime> ::= b'\xff\xff\xff\xff' | b'\x00\x00\x00\x80' | b'\x00\x00\x00\x00'


# No data: a stream of an end-of-block code only, CRC-32 and size 0
<m_empty> ::= b'\x1f\x8b\x08\x00' <max_mtime> <any_xfl> <any_os> \
              <cdata_e> <crc_e> <isize_e>
    where bytes(<crc_e>) == crc32_of_deflate(bytes(<cdata_e>))
    where bytes(<isize_e>) == isize_of_deflate(bytes(<cdata_e>))
<cdata_e> ::= <byte>* := make_edge_deflate(bytes(<seed>), 'empty')
<crc_e> ::= <byte>{4}
<isize_e> ::= <byte>{4}


# Two stored blocks: 65,535 bytes, then the rest
<m_big> ::= b'\x1f\x8b\x08\x00' <byte>{4} <xfl> <os> \
            <cdata_b> <crc_b> <isize_b>
    where bytes(<crc_b>) == crc32_of_deflate(bytes(<cdata_b>))
    where bytes(<isize_b>) == isize_of_deflate(bytes(<cdata_b>))
# One terminal, not a <byte> per byte: a tree of 65,000 nodes is slow to make
<cdata_b> ::= rb'[\x00-\xff]*' := make_edge_deflate(bytes(<seed>), 'big')
<crc_b> ::= <byte>{4}
<isize_b> ::= <byte>{4}


# A sync flush and a full flush, with FTEXT on data that need not be text
<m_sync> ::= b'\x1f\x8b\x08\x01' <byte>{4} <xfl> <os> \
             <cdata_s> <crc_s> <isize_s>
    where bytes(<crc_s>) == crc32_of_deflate(bytes(<cdata_s>))
    where bytes(<isize_s>) == isize_of_deflate(bytes(<cdata_s>))
<cdata_s> ::= <byte>* := make_edge_deflate(bytes(<seed>), 'sync')
<crc_s> ::= <byte>{4}
<isize_s> ::= <byte>{4}


# One byte, 1,000 times or more: matches of 258 bytes
<m_longrun> ::= b'\x1f\x8b\x08\x00' <byte>{4} <xfl> <os> \
                <cdata_l> <crc_l> <isize_l>
    where bytes(<crc_l>) == crc32_of_deflate(bytes(<cdata_l>))
    where bytes(<isize_l>) == isize_of_deflate(bytes(<cdata_l>))
<cdata_l> ::= <byte>* := make_edge_deflate(bytes(<seed>), 'longrun')
<crc_l> ::= <byte>{4}
<isize_l> ::= <byte>{4}


# FNAME and FCOMMENT, each empty or up to 2,000 Latin-1 characters (a
# comment may break lines with LF)
<m_fields> ::= b'\x1f\x8b\x08\x18' <byte>{4} <any_xfl> <any_os> \
               <long_name> <long_comment> <cdata_f> <crc_f> <isize_f>
    where bytes(<crc_f>) == crc32_of_deflate(bytes(<cdata_f>))
    where bytes(<isize_f>) == isize_of_deflate(bytes(<cdata_f>))
<long_name> ::= rb'[\x20-\x7e\xa0-\xff]{0,2000}' b'\x00'
<long_comment> ::= rb'[\x0a\x20-\x7e\xa0-\xff]{0,2000}' b'\x00'
<cdata_f> ::= <byte>* := make_deflate(bytes(<seed>), 'text', 6, zlib.Z_DEFAULT_STRATEGY)
<crc_f> ::= <byte>{4}
<isize_f> ::= <byte>{4}


# FEXTRA with two to six subfields (some of no data), and FHCRC over it all
<m_extras> ::= <id_x> <flg_x> <mt_x> <xfl_x> <os_x> <xlen_x> <extra_x> <fhcrc_x> \
               <cdata_x> <crc_x> <isize_x>
    where bytes(<xlen_x>) == u16le(len(bytes(<extra_x>)))
    where bytes(<fhcrc_x>) == u16le(zlib.crc32(
              bytes(<id_x>) + bytes(<flg_x>) + bytes(<mt_x>) + bytes(<xfl_x>)
              + bytes(<os_x>) + bytes(<xlen_x>) + bytes(<extra_x>)) & 0xFFFF)
    where bytes(<crc_x>) == crc32_of_deflate(bytes(<cdata_x>))
    where bytes(<isize_x>) == isize_of_deflate(bytes(<cdata_x>))
<id_x> ::= b'\x1f\x8b\x08'
<flg_x> ::= b'\x06'
<mt_x> ::= <byte>{4}
<xfl_x> ::= <any_xfl>
<os_x> ::= <any_os>
<xlen_x> ::= <byte>{2}
<extra_x> ::= <subfield>{2,6}
<subfield> ::= <si1> <si2> <sublen> <subdata>
    where bytes(<sublen>) == u16le(len(bytes(<subdata>)))
<si1> ::= rb'[\x41-\x5a\x61-\x7a]'
<si2> ::= rb'[\x01-\xff]'
<sublen> ::= <byte>{2}
<subdata> ::= rb'[\x00-\xff]{0,64}'
<fhcrc_x> ::= <byte>{2}
<cdata_x> ::= <byte>* := make_deflate(bytes(<seed>), 'raw', 9, zlib.Z_DEFAULT_STRATEGY)
<crc_x> ::= <byte>{4}
<isize_x> ::= <byte>{4}


# Four members, the second with no data
<m_members> ::= <mb_1> <mb_2> <mb_3> <mb_4>
<mb_1> ::= b'\x1f\x8b\x08\x00' <byte>{4} <xfl> <os> <cdata_1> <crc_1> <isize_1>
    where bytes(<crc_1>) == crc32_of_deflate(bytes(<cdata_1>))
    where bytes(<isize_1>) == isize_of_deflate(bytes(<cdata_1>))
<cdata_1> ::= <byte>* := make_deflate(bytes(<seed>), 'text', 9, zlib.Z_HUFFMAN_ONLY)
<crc_1> ::= <byte>{4}
<isize_1> ::= <byte>{4}
<mb_2> ::= b'\x1f\x8b\x08\x00' <byte>{4} <xfl> <os> <cdata_2> <crc_2> <isize_2>
    where bytes(<crc_2>) == crc32_of_deflate(bytes(<cdata_2>))
    where bytes(<isize_2>) == isize_of_deflate(bytes(<cdata_2>))
<cdata_2> ::= <byte>* := make_edge_deflate(bytes(<seed>), 'empty')
<crc_2> ::= <byte>{4}
<isize_2> ::= <byte>{4}
<mb_3> ::= b'\x1f\x8b\x08\x00' <byte>{4} <xfl> <os> <cdata_3> <crc_3> <isize_3>
    where bytes(<crc_3>) == crc32_of_deflate(bytes(<cdata_3>))
    where bytes(<isize_3>) == isize_of_deflate(bytes(<cdata_3>))
<cdata_3> ::= <byte>* := make_deflate(bytes(<seed>), 'raw', 0, zlib.Z_DEFAULT_STRATEGY)
<crc_3> ::= <byte>{4}
<isize_3> ::= <byte>{4}
<mb_4> ::= b'\x1f\x8b\x08\x00' <byte>{4} <xfl> <os> <cdata_4> <crc_4> <isize_4>
    where bytes(<crc_4>) == crc32_of_deflate(bytes(<cdata_4>))
    where bytes(<isize_4>) == isize_of_deflate(bytes(<cdata_4>))
<cdata_4> ::= <byte>* := make_deflate(bytes(<seed>), 'run', 6, zlib.Z_DEFAULT_STRATEGY)
<crc_4> ::= <byte>{4}
<isize_4> ::= <byte>{4}


# A member, then one to eight zero bytes
<m_padded> ::= b'\x1f\x8b\x08\x00' <byte>{4} <xfl> <os> <cdata_p> <crc_p> <isize_p> <zero_pad>
    where bytes(<crc_p>) == crc32_of_deflate(bytes(<cdata_p>))
    where bytes(<isize_p>) == isize_of_deflate(bytes(<cdata_p>))
<cdata_p> ::= <byte>* := make_deflate(bytes(<seed>), 'text', 6, zlib.Z_DEFAULT_STRATEGY)
<crc_p> ::= <byte>{4}
<isize_p> ::= <byte>{4}
<zero_pad> ::= rb'\x00{1,8}'
