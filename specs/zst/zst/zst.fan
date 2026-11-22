# Zstandard files (RFC 8878): one frame. Half are frames that the Zstandard
# compressor (Python package zstandard) makes, from data that Fandango draws,
# at levels -7 to 19, with or without the content size and the checksum:
# compressed blocks with Huffman-coded literals and FSE-coded sequences, and
# more than one block when the data is over 128 KiB. The others are written
# out here: Raw and RLE blocks, one or two to a frame; the content size in one
# or four bytes or not at all, a window size of up to 128 MiB, a dictionary
# ID of 0 (no dictionary), the content checksum (the low four bytes of the
# XXH64 here), and skippable frames.
#
# TODO:
# * The frames written out here hold a fixed number of bytes.
# * No frames that need a dictionary or more than the default memory: those
#   are in zst-boundary.

import zstandard


# The data of a compressed frame: what Fandango drew, as letters and as it
# is, repeated 1 to 1,021 times (up to some 260 KB)
def zstd_data(params):
    raw = bytes(_find(params, '<zdata>'))
    letters = bytes(b"etaoin shrdlu"[x % 13] for x in raw)
    return (letters + raw) * (1 + 4 * bytes(_find(params, '<zrepeat>'))[0])


# A frame from the compressor: the level (-7 to 19), and the flags for the
# checksum (1) and the content size (2)
def zstd_frame(params):
    level = bytes(_find(params, '<zlevel>'))[0] - 7
    flags = bytes(_find(params, '<zflags>'))[0]
    c = zstandard.ZstdCompressor(level=level, write_checksum=bool(flags & 1),
                                 write_content_size=bool(flags & 2))
    return c.compress(zstd_data(params))


def _find(node, name):
    """The first symbol called `name` under `node` (or `node` itself), or None."""
    if str(node.symbol) == name:
        return node
    for c in node.children:
        if c.is_non_terminal:
            found = _find(c, name)
            if found is not None:
                return found
    return None


def _rotl64(x, r):
    x = x & 0xFFFFFFFFFFFFFFFF
    return ((x << r) | (x >> (64 - r))) & 0xFFFFFFFFFFFFFFFF

def _round64(acc, inp):
    acc = (acc + (inp * 0xC2B2AE3D27D4EB4F)) & 0xFFFFFFFFFFFFFFFF
    acc = _rotl64(acc, 31)
    acc = (acc * 0x9E3779B185EBCA87) & 0xFFFFFFFFFFFFFFFF
    return acc

def _merge64(acc, val):
    acc = (acc ^ _round64(0, val)) & 0xFFFFFFFFFFFFFFFF
    acc = (acc * 0x9E3779B185EBCA87) & 0xFFFFFFFFFFFFFFFF
    acc = (acc + 0x85EBCA77C2B2AE63) & 0xFFFFFFFFFFFFFFFF
    return acc

# The content checksum: the low four bytes of XXH64, seed 0
def xxh64_low4(data):
    P1 = 0x9E3779B185EBCA87
    P2 = 0xC2B2AE3D27D4EB4F
    P3 = 0x165667B19E3779F9
    P4 = 0x85EBCA77C2B2AE63
    P5 = 0x27D4EB2F165667C5
    M = 0xFFFFFFFFFFFFFFFF
    n = len(data)
    idx = 0
    if n >= 32:
        v1 = (P1 + P2) & M
        v2 = P2
        v3 = 0
        v4 = (0 - P1) & M
        limit = n - 32
        while idx <= limit:
            v1 = _round64(v1, int.from_bytes(data[idx:idx+8], 'little'))
            idx = idx + 8
            v2 = _round64(v2, int.from_bytes(data[idx:idx+8], 'little'))
            idx = idx + 8
            v3 = _round64(v3, int.from_bytes(data[idx:idx+8], 'little'))
            idx = idx + 8
            v4 = _round64(v4, int.from_bytes(data[idx:idx+8], 'little'))
            idx = idx + 8
        h = (_rotl64(v1, 1) + _rotl64(v2, 7) + _rotl64(v3, 12) + _rotl64(v4, 18)) & M
        h = _merge64(h, v1)
        h = _merge64(h, v2)
        h = _merge64(h, v3)
        h = _merge64(h, v4)
    else:
        h = P5 & M
    h = (h + n) & M
    while idx + 8 <= n:
        k1 = _round64(0, int.from_bytes(data[idx:idx+8], 'little'))
        h = (h ^ k1) & M
        h = _rotl64(h, 27)
        h = (h * P1) & M
        h = (h + P4) & M
        idx = idx + 8
    if idx + 4 <= n:
        h = (h ^ ((int.from_bytes(data[idx:idx+4], 'little') * P1) & M)) & M
        h = _rotl64(h, 23)
        h = (h * P2) & M
        h = (h + P3) & M
        idx = idx + 4
    while idx < n:
        h = (h ^ ((data[idx] * P5) & M)) & M
        h = _rotl64(h, 11)
        h = (h * P1) & M
        idx = idx + 1
    h = (h ^ (h >> 33)) & M
    h = (h * P2) & M
    h = (h ^ (h >> 29)) & M
    h = (h * P3) & M
    h = (h ^ (h >> 32)) & M
    return (h & 0xFFFFFFFF).to_bytes(4, 'little')


<start> ::= <frame>

<frame> ::= <f_zstd> | <f_written>
<f_written> ::= <f_raw_ss1> | <f_raw_chk> | <f_win_plain> | <f_win_dict_chk> | <f_rle_chk> | <f_multi_chk> | <skippable>

# A frame from the compressor, one terminal (made from the draft <zparams>)
<f_zstd> ::= rb'[\x00-\xff]*' := zstd_frame(<zparams>)
<zparams> ::= <zlevel> <zflags> <zrepeat> <zdata>
<zlevel> ::= rb'[\x00-\x1a]'
<zflags> ::= rb'[\x00-\x03]'
<zrepeat> ::= <byte>
<zdata> ::= rb'[\x00-\xff]{1,256}'

<byte>  ::= rb'[\x00-\xff]'
<magic> ::= b'\x28\xb5\x2f\xfd'


# Single segment, the content size in one byte: one Raw block
<f_raw_ss1> ::= <magic> b'\x20' <fcs_a> <bh_a> <c_a>
    where bytes(<fcs_a>) == len(bytes(<c_a>)).to_bytes(1, 'little')
    where bytes(<bh_a>) == (1 + (len(bytes(<c_a>)) << 3)).to_bytes(3, 'little')
<fcs_a> ::= <byte>
<bh_a>  ::= <byte>{3}
<c_a>   ::= <byte>{20}


# Single segment, the content size in four bytes, the checksum
<f_raw_chk> ::= <magic> b'\xa4' <fcs_b> <bh_b> <c_b> <ck_b>
    where bytes(<fcs_b>) == len(bytes(<c_b>)).to_bytes(4, 'little')
    where bytes(<bh_b>) == (1 + (len(bytes(<c_b>)) << 3)).to_bytes(3, 'little')
    where bytes(<ck_b>) == xxh64_low4(bytes(<c_b>))
<fcs_b> ::= <byte>{4}
<bh_b>  ::= <byte>{3}
<c_b>   ::= <byte>{28}
<ck_b>  ::= <byte>{4}


# A window descriptor and no content size. The window is at most 128 MiB,
# the most decoders allow by default: 2^(10 + exponent) and eighths of it,
# with the exponent up to 16, or 17 and no eighths.
<f_win_plain> ::= <magic> b'\x00' <wd_c> <bh_c> <c_c>
    where bytes(<bh_c>) == (1 + (len(bytes(<c_c>)) << 3)).to_bytes(3, 'little')
<wd_c> ::= rb'[\x00-\x88]'
<bh_c> ::= <byte>{3}
<c_c>  ::= <byte>{24}


# A window descriptor, a one-byte dictionary ID of 0 (no dictionary), the
# checksum
<f_win_dict_chk> ::= <magic> b'\x05' <wd_d> <did_d> <bh_d> <c_d> <ck_d>
    where bytes(<bh_d>) == (1 + (len(bytes(<c_d>)) << 3)).to_bytes(3, 'little')
    where bytes(<ck_d>) == xxh64_low4(bytes(<c_d>))
<wd_d>  ::= rb'[\x00-\x88]'
<did_d> ::= b'\x00'
<bh_d>  ::= <byte>{3}
<c_d>   ::= <byte>{30}
<ck_d>  ::= <byte>{4}


# An RLE block: one byte, 40 times
<f_rle_chk> ::= <magic> b'\xa4' <fcs_e> <bh_e> <rle_e> <ck_e>
    where bytes(<fcs_e>) == (40).to_bytes(4, 'little')
    where bytes(<bh_e>) == (1 + (1 << 1) + (40 << 3)).to_bytes(3, 'little')
    where bytes(<ck_e>) == xxh64_low4(bytes(<rle_e>) * 40)
<fcs_e> ::= <byte>{4}
<bh_e>  ::= <byte>{3}
<rle_e> ::= <byte>
<ck_e>  ::= <byte>{4}


# Two Raw blocks, only the second the last
<f_multi_chk> ::= <magic> b'\xa4' <fcs_f> <bh_f1> <c_f1> <bh_f2> <c_f2> <ck_f>
    where bytes(<fcs_f>) == (len(bytes(<c_f1>)) + len(bytes(<c_f2>))).to_bytes(4, 'little')
    where bytes(<bh_f1>) == (len(bytes(<c_f1>)) << 3).to_bytes(3, 'little')
    where bytes(<bh_f2>) == (1 + (len(bytes(<c_f2>)) << 3)).to_bytes(3, 'little')
    where bytes(<ck_f>) == xxh64_low4(bytes(<c_f1>) + bytes(<c_f2>))
<fcs_f> ::= <byte>{4}
<bh_f1> ::= <byte>{3}
<c_f1>  ::= <byte>{16}
<bh_f2> ::= <byte>{3}
<c_f2>  ::= <byte>{18}
<ck_f>  ::= <byte>{4}


# A skippable frame (magic 0x184D2A50 to 0x184D2A5F), its size and data
<skippable> ::= <skip_magic> <skip_size> <skip_data>
    where bytes(<skip_size>) == len(bytes(<skip_data>)).to_bytes(4, 'little')
<skip_magic> ::= rb'[\x50-\x5f]\x2a\x4d\x18'
<skip_size>  ::= <byte>{4}
<skip_data>  ::= <byte>{12}
