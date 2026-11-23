# zlib streams (RFC 1950): the CMF and FLG bytes, a DEFLATE stream (RFC 1951)
# and the Adler-32 of the data. CMF names a window of 512 bytes to 32 KiB, and
# a where constraint makes CMF and FLG a multiple of 31, as FCHECK must. The
# DEFLATE stream is one stored block, one with fixed Huffman codes, one with
# codes of its own (dynamic), a run of one byte, three bytes or fewer, or
# three stored blocks; Python's zlib module compresses data that Fandango
# draws (and never puts in the file) with a 512-byte window, which fits any
# window the header names.
#
# TODO:
# * CMF and FLG come out much the same in a run: CINFO 4 in most files.

<start> ::= <stored> | <fixed> | <dynamic> | <run> | <empty> | <multi>


<cmf_a> ::= rb'[\x18\x28\x38\x48\x58\x68\x78]'
<cmf_b> ::= rb'[\x18\x28\x38\x48\x58\x68\x78]'
<cmf_c> ::= rb'[\x18\x28\x38\x48\x58\x68\x78]'
<cmf_d> ::= rb'[\x18\x28\x38\x48\x58\x68\x78]'
<cmf_e> ::= rb'[\x18\x28\x38\x48\x58\x68\x78]'
<cmf_f> ::= rb'[\x18\x28\x38\x48\x58\x68\x78]'

<flg_a> ::= <byte>
<flg_b> ::= <byte>
<flg_c> ::= <byte>
<flg_d> ::= <byte>
<flg_e> ::= <byte>
<flg_f> ::= <byte>

<p_a> ::= <byte>*
<p_b> ::= <byte>*
<p_c> ::= <byte>*
<p_d> ::= <byte>*
<p_e> ::= <byte>*
<p_f> ::= <byte>*

<byte> ::= rb'[\x00-\xff]'

# One stored block (no compression)
<stored> ::= <cmf_a> <flg_a> <body_a>
<body_a> ::= <p_a> := deflate_body(bytes(<p_a>), 0, zlib.Z_DEFAULT_STRATEGY)
where (bytes(<cmf_a>)[0] * 256 + bytes(<flg_a>)[0]) % 31 == 0 and (bytes(<flg_a>)[0] & 0x20) == 0x00

# Fixed Huffman codes, on text made from the data
<fixed> ::= <cmf_b> <flg_b> <body_b>
<body_b> ::= <p_b> := deflate_body(shape(bytes(<p_b>), 'comp'), 9, zlib.Z_FIXED)
where (bytes(<cmf_b>)[0] * 256 + bytes(<flg_b>)[0]) % 31 == 0 and (bytes(<flg_b>)[0] & 0x20) == 0x00

# Codes of its own (dynamic), Huffman coding only, no matches
<dynamic> ::= <cmf_c> <flg_c> <body_c>
<body_c> ::= <p_c> := deflate_dyn(shape(bytes(<p_c>), 'comp'))
where (bytes(<cmf_c>)[0] * 256 + bytes(<flg_c>)[0]) % 31 == 0 and (bytes(<flg_c>)[0] & 0x20) == 0x00

# 64 times one byte
<run> ::= <cmf_d> <flg_d> <body_d>
<body_d> ::= <p_d> := deflate_body(shape(bytes(<p_d>), 'run'), 9, zlib.Z_RLE)
where (bytes(<cmf_d>)[0] * 256 + bytes(<flg_d>)[0]) % 31 == 0 and (bytes(<flg_d>)[0] & 0x20) == 0x00

# Three bytes of data or fewer
<empty> ::= <cmf_e> <flg_e> <body_e>
<body_e> ::= <p_e> := deflate_body(bytes(<p_e>)[:3], 6, zlib.Z_DEFAULT_STRATEGY)
where (bytes(<cmf_e>)[0] * 256 + bytes(<flg_e>)[0]) % 31 == 0 and (bytes(<flg_e>)[0] & 0x20) == 0x00

# Three stored blocks, the last one final
<multi> ::= <cmf_f> <flg_f> <body_f>
<body_f> ::= <p_f> := deflate_multi(bytes(<p_f>))
where (bytes(<cmf_f>)[0] * 256 + bytes(<flg_f>)[0]) % 31 == 0 and (bytes(<flg_f>)[0] & 0x20) == 0x00

import zlib

# Data made from what Fandango drew: text of the letters of "the quick brown
# fox" (four times the same 180 bytes or fewer), or 64 times its first byte.
def shape(raw, mode):
    if mode == 'comp':
        alpha = b'the quick brown fox'
        return bytes(alpha[b % len(alpha)] for b in raw)[:180] * 4
    if mode == 'run':
        b = raw[0] if raw else 0x41
        return bytes([b]) * 64
    return raw[:180]

# A raw DEFLATE stream with a 512-byte window, then the Adler-32 of the data
def deflate_body(raw, level, strat):
    co = zlib.compressobj(level, zlib.DEFLATED, -9, 8, strat)
    body = co.compress(raw) + co.flush()
    adler = (zlib.adler32(raw) & 0xffffffff).to_bytes(4, 'big')
    return body + adler

# Huffman coding only (no matches): codes of its own, made for the data
def deflate_dyn(raw):
    if not raw:
        raw = b'aaaabbbccd'
    co = zlib.compressobj(9, zlib.DEFLATED, -9, 8, zlib.Z_HUFFMAN_ONLY)
    body = co.compress(raw) + co.flush()
    adler = (zlib.adler32(raw) & 0xffffffff).to_bytes(4, 'big')
    return body + adler

# Three stored blocks, written out here: BFINAL and BTYPE, LEN, NLEN, data
def deflate_multi(raw):
    data = (raw[:120] if raw else b'block')
    n = max(1, len(data) // 3)
    chunks = [data[0:n], data[n:2*n], data[2*n:]]
    out = b''
    for i, chunk in enumerate(chunks):
        bfinal = 1 if i == 2 else 0
        ln = len(chunk)
        out = out + bytes([bfinal]) + ln.to_bytes(2, 'little') + (0xffff ^ ln).to_bytes(2, 'little') + chunk
    adler = (zlib.adler32(data) & 0xffffffff).to_bytes(4, 'big')
    return out + adler
