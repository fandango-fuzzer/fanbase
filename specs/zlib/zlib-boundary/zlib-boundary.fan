# zlib streams at the edges of what RFC 1950 allows: every window size from
# 256 bytes to 32 KiB (CINFO 0 to 7), every FLEVEL, no data at all, and
# three stored blocks. The other streams hold one stored block, fixed Huffman
# codes, codes of their own (dynamic), or a run of one byte, from data that
# Fandango draws and Python's zlib module compresses; no distance in them is
# longer than the smallest window, so every header fits.
#
# TODO:
# * Few streams have codes of their own: Fandango picks short data, which
#   zlib's compressor codes with the fixed codes.
# * No streams that need a preset dictionary (FDICT): readers refuse them
#   unless they are given the dictionary, and Fandango either hardly ever
#   picks them or picks little else, so how many files decode would swing.

import zlib

# Data made from what Fandango drew: none, the first 200 bytes of it as they
# are, 64 times its first byte, or text of seven letters, four times over (no
# more than 200 bytes, so that no distance is longer than 256).
def _shape(seed, mode):
    if mode == 'empty':
        return b''
    if mode == 'raw':
        return seed[:200]
    if mode == 'run':
        b = seed[:1] if seed else b'\x00'
        return b * 64
    if mode == 'comp':
        base = seed if seed else b'a'
        alpha = b'abcdefg'
        data = bytes(alpha[c % 7] for c in base)
        return (data * 4)[:200]
    return seed[:200]


# A raw DEFLATE stream with a 32 KiB window, then the Adler-32 of the data
def deflate_body(raw, level, strategy):
    co = zlib.compressobj(level, zlib.DEFLATED, -15, 9, strategy)
    body = co.compress(raw) + co.flush()
    adler = (zlib.adler32(raw) & 0xffffffff).to_bytes(4, 'big')
    return body + adler


def plain_body(seed, mode, level, strategy):
    return deflate_body(_shape(seed, mode), level, strategy)


# Three stored blocks, written out here: BFINAL and BTYPE, LEN, NLEN, data
def multiblock_body(seed):
    data = _shape(seed, 'comp')[:90] or b'abc'
    n = len(data)
    step = max(1, n // 3)
    chunks = [data[0:step], data[step:2 * step], data[2 * step:]]
    chunks = [c for c in chunks if c] or [data]
    out = b''
    last = len(chunks) - 1
    for i, ch in enumerate(chunks):
        bfinal = 1 if i == last else 0
        ln = len(ch)
        out += (bytes([bfinal])
                + ln.to_bytes(2, 'little')
                + (0xffff ^ ln).to_bytes(2, 'little')
                + ch)
    adler = (zlib.adler32(data) & 0xffffffff).to_bytes(4, 'big')
    return out + adler


<start> ::= <s_stored> | <s_fixed> | <s_dynamic> | <s_run> \
          | <s_empty> | <s_multi>

<byte> ::= rb'[\x00-\xff]'

# CM 8 (DEFLATE) and CINFO 0 to 7: a window of 256 bytes to 32 KiB
<cmf> ::= rb'[\x08\x18\x28\x38\x48\x58\x68\x78]'

# One stored block
<s_stored>  ::= <cmf_a> <flg_a> <body_a>
<cmf_a>     ::= <cmf>
<flg_a>     ::= <byte>
where (((bytes(<cmf_a>)[0] * 256 + bytes(<flg_a>)[0]) % 31 == 0)
       and ((bytes(<flg_a>)[0] & 0x20) == 0x00))
<body_a>    ::= <p_a> := plain_body(bytes(<p_a>), 'raw', 0, zlib.Z_DEFAULT_STRATEGY)
<p_a>       ::= <byte>*

# Fixed Huffman codes
<s_fixed>   ::= <cmf_b> <flg_b> <body_b>
<cmf_b>     ::= <cmf>
<flg_b>     ::= <byte>
where (((bytes(<cmf_b>)[0] * 256 + bytes(<flg_b>)[0]) % 31 == 0)
       and ((bytes(<flg_b>)[0] & 0x20) == 0x00))
<body_b>    ::= <p_b> := plain_body(bytes(<p_b>), 'comp', 9, zlib.Z_FIXED)
<p_b>       ::= <byte>*

# Seven letters, for which the compressor may make codes of their own
<s_dynamic> ::= <cmf_c> <flg_c> <body_c>
<cmf_c>     ::= <cmf>
<flg_c>     ::= <byte>
where (((bytes(<cmf_c>)[0] * 256 + bytes(<flg_c>)[0]) % 31 == 0)
       and ((bytes(<flg_c>)[0] & 0x20) == 0x00))
<body_c>    ::= <p_c> := plain_body(bytes(<p_c>), 'comp', 9, zlib.Z_DEFAULT_STRATEGY)
<p_c>       ::= <byte>*

# 64 times one byte
<s_run>     ::= <cmf_d> <flg_d> <body_d>
<cmf_d>     ::= <cmf>
<flg_d>     ::= <byte>
where (((bytes(<cmf_d>)[0] * 256 + bytes(<flg_d>)[0]) % 31 == 0)
       and ((bytes(<flg_d>)[0] & 0x20) == 0x00))
<body_d>    ::= <p_d> := plain_body(bytes(<p_d>), 'run', 6, zlib.Z_RLE)
<p_d>       ::= <byte>*

# No data
<s_empty>   ::= <cmf_e> <flg_e> <body_e>
<cmf_e>     ::= <cmf>
<flg_e>     ::= <byte>
where (((bytes(<cmf_e>)[0] * 256 + bytes(<flg_e>)[0]) % 31 == 0)
       and ((bytes(<flg_e>)[0] & 0x20) == 0x00))
<body_e>    ::= <p_e> := plain_body(bytes(<p_e>), 'empty', 6, zlib.Z_DEFAULT_STRATEGY)
<p_e>       ::= <byte>*

# Three stored blocks, the last one final
<s_multi>   ::= <cmf_f> <flg_f> <body_f>
<cmf_f>     ::= <cmf>
<flg_f>     ::= <byte>
where (((bytes(<cmf_f>)[0] * 256 + bytes(<flg_f>)[0]) % 31 == 0)
       and ((bytes(<flg_f>)[0] & 0x20) == 0x00))
<body_f>    ::= <p_f> := multiblock_body(bytes(<p_f>))
<p_f>       ::= <byte>*
