# gzip files (RFC 1952) of one member, or two: the ten-byte header (magic,
# CM 8, the flags, MTIME, XFL and OS), the optional fields that the flags
# announce (FEXTRA with one subfield, FNAME, FCOMMENT, and FHCRC, the CRC-16
# of the header), a raw DEFLATE stream, and the CRC-32 and size of the data.
# There is a member for each flag alone, one with all of them, and one with
# none; the DEFLATE streams are stored, with fixed Huffman codes, or with
# codes of their own (dynamic). Python's zlib module compresses data that
# Fandango draws and that never goes into the file; where constraints
# decompress the stream to make the CRC-32 and the size from it, and tie the
# lengths and the CRC-16 to the header.
#
# TODO:
# * The data of a member is small: at most 200 bytes.
# * FEXTRA holds a single subfield.

import zlib


def u16le(n):
    return (n & 0xFFFF).to_bytes(2, "little")


def u32le(n):
    return (n & 0xFFFFFFFF).to_bytes(4, "little")


# The data, made from what Fandango drew: its first 200 bytes as they are,
# 64 times its first byte, or text of the letters of "the quick brown fox".
def _shape(seed, mode):
    seed = bytes(seed)
    if not seed:
        seed = b"\x00"
    if mode == "raw":
        return seed[:200]
    if mode == "run":
        return bytes([seed[0]]) * 64
    if mode == "text":
        alpha = b"the quick brown fox "
        return bytes(alpha[b % len(alpha)] for b in seed[:120]) or b"a"
    return seed[:200]


# A raw DEFLATE stream of that data
def make_deflate(seed, mode, level, strat):
    data = _shape(seed, mode)
    co = zlib.compressobj(level, zlib.DEFLATED, -15, 8, strat)
    return co.compress(data) + co.flush()


def _inflate(deflate_stream):
    d = zlib.decompressobj(-15)
    out = d.decompress(bytes(deflate_stream))
    out += d.flush()
    return out


# The CRC-32 and the size (modulo 2^32) of what a stream decompresses to
def crc32_of_deflate(deflate_stream):
    return u32le(zlib.crc32(_inflate(deflate_stream)) & 0xFFFFFFFF)


def isize_of_deflate(deflate_stream):
    return u32le(len(_inflate(deflate_stream)))


<start> ::= <member_min> | <member_ftext> | <member_extra> | <member_fname> \
          | <member_comment> | <member_fhcrc> | <member_all> | <member_multi>


<byte> ::= rb'[\x00-\xff]'

# The data before it is compressed: Fandango draws it, and it goes into no file
<seed> ::= <byte>+

# XFL: none, the slowest compression (2), the fastest (4)
<xfl> ::= b'\x00' | b'\x02' | b'\x04'

# OS: the systems 0 (FAT) to 13 (Acorn RISCOS), or 255 (unknown)
<os> ::= b'\x00' | b'\x01' | b'\x02' | b'\x03' | b'\x04' | b'\x05' | b'\x06' \
       | b'\x07' | b'\x08' | b'\x09' | b'\x0a' | b'\x0b' | b'\x0c' | b'\x0d' \
       | b'\xff'


# No flags, a stored block

<member_min> ::= b'\x1f' b'\x8b' b'\x08' b'\x00' <byte>{4} <xfl> <os> \
                 <cdata_min> <crc_min> <isize_min>
    where bytes(<crc_min>) == crc32_of_deflate(bytes(<cdata_min>))
    where bytes(<isize_min>) == isize_of_deflate(bytes(<cdata_min>))
<cdata_min> ::= <byte>* := make_deflate(bytes(<seed>), 'raw', 0, zlib.Z_DEFAULT_STRATEGY)
<crc_min> ::= <byte>{4}
<isize_min> ::= <byte>{4}


# FTEXT, codes of its own (Huffman coding only)

<member_ftext> ::= b'\x1f' b'\x8b' b'\x08' b'\x01' <byte>{4} <xfl> <os> \
                   <cdata_ftext> <crc_ftext> <isize_ftext>
    where bytes(<crc_ftext>) == crc32_of_deflate(bytes(<cdata_ftext>))
    where bytes(<isize_ftext>) == isize_of_deflate(bytes(<cdata_ftext>))
<cdata_ftext> ::= <byte>* := make_deflate(bytes(<seed>), 'text', 9, zlib.Z_HUFFMAN_ONLY)
<crc_ftext> ::= <byte>{4}
<isize_ftext> ::= <byte>{4}


# FEXTRA: XLEN, then one subfield (SI1, SI2, LEN and up to 16 bytes)

<member_extra> ::= b'\x1f' b'\x8b' b'\x08' b'\x04' <byte>{4} <xfl> <os> \
                   <xlen_e> <extra_e> <cdata_extra> <crc_extra> <isize_extra>
    where bytes(<xlen_e>) == u16le(len(bytes(<extra_e>)))
    where bytes(<crc_extra>) == crc32_of_deflate(bytes(<cdata_extra>))
    where bytes(<isize_extra>) == isize_of_deflate(bytes(<cdata_extra>))
<xlen_e> ::= <byte>{2}
<extra_e> ::= <si1_e> <si2_e> <sublen_e> <subdata_e>
    where bytes(<sublen_e>) == u16le(len(bytes(<subdata_e>)))
<si1_e> ::= <byte>
<si2_e> ::= <byte>
<sublen_e> ::= <byte>{2}
<subdata_e> ::= rb'[\x00-\xff]{0,16}'
<cdata_extra> ::= <byte>* := make_deflate(bytes(<seed>), 'run', 6, zlib.Z_DEFAULT_STRATEGY)
<crc_extra> ::= <byte>{4}
<isize_extra> ::= <byte>{4}


# FNAME: a name of up to 24 printable characters, then a zero byte

<member_fname> ::= b'\x1f' b'\x8b' b'\x08' b'\x08' <byte>{4} <xfl> <os> \
                   <fname_f> <cdata_fname> <crc_fname> <isize_fname>
    where bytes(<crc_fname>) == crc32_of_deflate(bytes(<cdata_fname>))
    where bytes(<isize_fname>) == isize_of_deflate(bytes(<cdata_fname>))
<fname_f> ::= <fnchars_f> b'\x00'
<fnchars_f> ::= rb'[\x21-\x7e]{1,24}'
<cdata_fname> ::= <byte>* := make_deflate(bytes(<seed>), 'text', 9, zlib.Z_HUFFMAN_ONLY)
<crc_fname> ::= <byte>{4}
<isize_fname> ::= <byte>{4}


# FCOMMENT: a comment, then a zero byte

<member_comment> ::= b'\x1f' b'\x8b' b'\x08' b'\x10' <byte>{4} <xfl> <os> \
                     <comment_c> <cdata_comment> <crc_comment> <isize_comment>
    where bytes(<crc_comment>) == crc32_of_deflate(bytes(<cdata_comment>))
    where bytes(<isize_comment>) == isize_of_deflate(bytes(<cdata_comment>))
<comment_c> ::= <cmchars_c> b'\x00'
<cmchars_c> ::= rb'[\x20-\x7e]{1,32}'
<cdata_comment> ::= <byte>* := make_deflate(bytes(<seed>), 'run', 6, zlib.Z_DEFAULT_STRATEGY)
<crc_comment> ::= <byte>{4}
<isize_comment> ::= <byte>{4}


# FHCRC: the low 16 bits of the CRC-32 of the header before it

<member_fhcrc> ::= <id1_h> <id2_h> <cm_h> <flg_h> <mt_h> <xfl_h> <os_h> \
                   <fhcrc_h> <cdata_fhcrc> <crc_fhcrc> <isize_fhcrc>
    where bytes(<fhcrc_h>) == u16le(zlib.crc32(
              bytes(<id1_h>) + bytes(<id2_h>) + bytes(<cm_h>) + bytes(<flg_h>)
              + bytes(<mt_h>) + bytes(<xfl_h>) + bytes(<os_h>)) & 0xFFFF)
    where bytes(<crc_fhcrc>) == crc32_of_deflate(bytes(<cdata_fhcrc>))
    where bytes(<isize_fhcrc>) == isize_of_deflate(bytes(<cdata_fhcrc>))
<id1_h> ::= b'\x1f'
<id2_h> ::= b'\x8b'
<cm_h> ::= b'\x08'
<flg_h> ::= b'\x02'
<mt_h> ::= <byte>{4}
<xfl_h> ::= <xfl>
<os_h> ::= <os>
<fhcrc_h> ::= <byte>{2}
<cdata_fhcrc> ::= <byte>* := make_deflate(bytes(<seed>), 'raw', 1, zlib.Z_DEFAULT_STRATEGY)
<crc_fhcrc> ::= <byte>{4}
<isize_fhcrc> ::= <byte>{4}


# Every flag, so FHCRC covers the extra field, the name and the comment

<member_all> ::= <id1_a> <id2_a> <cm_a> <flg_a> <mt_a> <xfl_a> <os_a> \
                 <xlen_a> <extra_a> <fname_a> <comment_a> <fhcrc_a> \
                 <cdata_all> <crc_all> <isize_all>
    where bytes(<xlen_a>) == u16le(len(bytes(<extra_a>)))
    where bytes(<fhcrc_a>) == u16le(zlib.crc32(
              bytes(<id1_a>) + bytes(<id2_a>) + bytes(<cm_a>) + bytes(<flg_a>)
              + bytes(<mt_a>) + bytes(<xfl_a>) + bytes(<os_a>)
              + bytes(<xlen_a>) + bytes(<extra_a>)
              + bytes(<fname_a>) + bytes(<comment_a>)) & 0xFFFF)
    where bytes(<crc_all>) == crc32_of_deflate(bytes(<cdata_all>))
    where bytes(<isize_all>) == isize_of_deflate(bytes(<cdata_all>))
<id1_a> ::= b'\x1f'
<id2_a> ::= b'\x8b'
<cm_a> ::= b'\x08'
<flg_a> ::= b'\x1f'
<mt_a> ::= <byte>{4}
<xfl_a> ::= <xfl>
<os_a> ::= <os>
<xlen_a> ::= <byte>{2}
<extra_a> ::= <si1_a> <si2_a> <sublen_a> <subdata_a>
    where bytes(<sublen_a>) == u16le(len(bytes(<subdata_a>)))
<si1_a> ::= <byte>
<si2_a> ::= <byte>
<sublen_a> ::= <byte>{2}
<subdata_a> ::= rb'[\x00-\xff]{0,12}'
<fname_a> ::= <fnchars_a> b'\x00'
<fnchars_a> ::= rb'[\x21-\x7e]{1,16}'
<comment_a> ::= <cmchars_a> b'\x00'
<cmchars_a> ::= rb'[\x20-\x7e]{1,16}'
<fhcrc_a> ::= <byte>{2}
<cdata_all> ::= <byte>* := make_deflate(bytes(<seed>), 'text', 9, zlib.Z_HUFFMAN_ONLY)
<crc_all> ::= <byte>{4}
<isize_all> ::= <byte>{4}


# Two members, one after the other

<member_multi> ::= <mm_a> <mm_b>
<mm_a> ::= b'\x1f' b'\x8b' b'\x08' b'\x00' <byte>{4} <xfl> <os> \
           <cdata_ma> <crc_ma> <isize_ma>
    where bytes(<crc_ma>) == crc32_of_deflate(bytes(<cdata_ma>))
    where bytes(<isize_ma>) == isize_of_deflate(bytes(<cdata_ma>))
<cdata_ma> ::= <byte>* := make_deflate(bytes(<seed>), 'run', 6, zlib.Z_DEFAULT_STRATEGY)
<crc_ma> ::= <byte>{4}
<isize_ma> ::= <byte>{4}
<mm_b> ::= b'\x1f' b'\x8b' b'\x08' b'\x00' <byte>{4} <xfl> <os> \
           <cdata_mb> <crc_mb> <isize_mb>
    where bytes(<crc_mb>) == crc32_of_deflate(bytes(<cdata_mb>))
    where bytes(<isize_mb>) == isize_of_deflate(bytes(<cdata_mb>))
<cdata_mb> ::= <byte>* := make_deflate(bytes(<seed>), 'text', 9, zlib.Z_HUFFMAN_ONLY)
<crc_mb> ::= <byte>{4}
<isize_mb> ::= <byte>{4}
