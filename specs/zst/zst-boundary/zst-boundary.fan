# Same as zst, with frames at the edges of RFC 8878: the content size in
# two bytes (which hold the size less 256) and in eight, no content size and
# the largest window that decoders allow by default (128 MiB), dictionary ID
# fields of two and four bytes, a Raw block of no bytes, an RLE block of
# 100,000 bytes, five blocks of every kind but compressed, skippable frames
# of the first and the last magic number, and two frames in a row.
#
# TODO:
# * No compressed blocks: zst has them, from the compressor.
# * No frames that need a dictionary or a window over 128 MiB: decoders
#   refuse them unless they are given the dictionary or more memory, so how
#   many files decode would depend on how often Fandango picks them.

include("zst/zst.fan")

<start> ::= <stream>

# One frame, or two
<stream> ::= <frame> | <frame> <frame>

<frame> ::= <f_fcs2_ss> | <f_fcs8_ss> | <f_unknown_win> | <f_dict2_chk> \
          | <f_dict4_chk> | <f_empty_block> | <f_rle_huge> | <f_multiblock> \
          | <skippable_lo> | <skippable_hi>

# The content size in two bytes, which hold the size less 256: 300 bytes
<f_fcs2_ss> ::= <magic> b'\x60' <fcs1> <bh1> <c1>
    where bytes(<fcs1>) == (len(bytes(<c1>)) - 256).to_bytes(2, 'little')
    where bytes(<bh1>) == (1 + (len(bytes(<c1>)) << 3)).to_bytes(3, 'little')
<fcs1> ::= <byte>{2}
<bh1>  ::= <byte>{3}
<c1>   ::= <byte>{300}

# The content size in eight bytes, and the checksum
<f_fcs8_ss> ::= <magic> b'\xe4' <fcs2> <bh2> <c2> <ck2>
    where bytes(<fcs2>) == len(bytes(<c2>)).to_bytes(8, 'little')
    where bytes(<bh2>) == (1 + (len(bytes(<c2>)) << 3)).to_bytes(3, 'little')
    where bytes(<ck2>) == xxh64_low4(bytes(<c2>))
<fcs2> ::= <byte>{8}
<bh2>  ::= <byte>{3}
<c2>   ::= <byte>{33}
<ck2>  ::= <byte>{4}

# No content size, and the largest window that decoders allow by default,
# 2^27 bytes (exponent 17, no eighths)
<f_unknown_win> ::= <magic> b'\x00' <wd3> <bh3> <c3>
    where bytes(<wd3>) == (17 << 3).to_bytes(1, 'little')
    where bytes(<bh3>) == (1 + (len(bytes(<c3>)) << 3)).to_bytes(3, 'little')
<wd3> ::= <byte>
<bh3> ::= <byte>{3}
<c3>  ::= <byte>{24}

# A two-byte dictionary ID field, holding 0: no dictionary
<f_dict2_chk> ::= <magic> b'\x06' <wd4> <did4> <bh4> <c4> <ck4>
    where bytes(<did4>) == (0).to_bytes(2, 'little')
    where bytes(<bh4>) == (1 + (len(bytes(<c4>)) << 3)).to_bytes(3, 'little')
    where bytes(<ck4>) == xxh64_low4(bytes(<c4>))
<wd4>  ::= rb'[\x00-\x88]'
<did4> ::= <byte>{2}
<bh4>  ::= <byte>{3}
<c4>   ::= <byte>{29}
<ck4>  ::= <byte>{4}

# A four-byte dictionary ID field, holding 0
<f_dict4_chk> ::= <magic> b'\x07' <wd5> <did5> <bh5> <c5> <ck5>
    where bytes(<did5>) == (0).to_bytes(4, 'little')
    where bytes(<bh5>) == (1 + (len(bytes(<c5>)) << 3)).to_bytes(3, 'little')
    where bytes(<ck5>) == xxh64_low4(bytes(<c5>))
<wd5>  ::= rb'[\x00-\x88]'
<did5> ::= <byte>{4}
<bh5>  ::= <byte>{3}
<c5>   ::= <byte>{16}
<ck5>  ::= <byte>{4}

# One Raw block of no bytes: a frame of no content
<f_empty_block> ::= <magic> b'\x20' <fcs6> <bh6>
    where bytes(<fcs6>) == (0).to_bytes(1, 'little')
    where bytes(<bh6>) == (1).to_bytes(3, 'little')
<fcs6> ::= <byte>
<bh6>  ::= <byte>{3}

# An RLE block of 100,000 bytes, from one
<f_rle_huge> ::= <magic> b'\xa4' <fcs7> <bh7> <rle7> <ck7>
    where bytes(<fcs7>) == (100000).to_bytes(4, 'little')
    where bytes(<bh7>) == (1 + (1 << 1) + (100000 << 3)).to_bytes(3, 'little')
    where bytes(<ck7>) == xxh64_low4(bytes(<rle7>) * 100000)
<fcs7> ::= <byte>{4}
<bh7>  ::= <byte>{3}
<rle7> ::= <byte>
<ck7>  ::= <byte>{4}

# Five blocks: Raw, RLE, an empty Raw block, RLE, Raw
<f_multiblock> ::= <magic> b'\xa4' <fcs8> \
                   <bh8a> <c8a> <bh8b> <r8b> <bh8c> <bh8d> <r8d> <bh8e> <c8e> <ck8>
    where bytes(<fcs8>) == (len(bytes(<c8a>)) + 50 + 30 + len(bytes(<c8e>))).to_bytes(4, 'little')
    where bytes(<bh8a>) == (len(bytes(<c8a>)) << 3).to_bytes(3, 'little')
    where bytes(<bh8b>) == ((1 << 1) + (50 << 3)).to_bytes(3, 'little')
    where bytes(<bh8c>) == (0).to_bytes(3, 'little')
    where bytes(<bh8d>) == ((1 << 1) + (30 << 3)).to_bytes(3, 'little')
    where bytes(<bh8e>) == (1 + (len(bytes(<c8e>)) << 3)).to_bytes(3, 'little')
    where bytes(<ck8>) == xxh64_low4(bytes(<c8a>) + bytes(<r8b>) * 50 + bytes(<r8d>) * 30 + bytes(<c8e>))
<fcs8> ::= <byte>{4}
<bh8a> ::= <byte>{3}
<c8a>  ::= <byte>{12}
<bh8b> ::= <byte>{3}
<r8b>  ::= <byte>
<bh8c> ::= <byte>{3}
<bh8d> ::= <byte>{3}
<r8d>  ::= <byte>
<bh8e> ::= <byte>{3}
<c8e>  ::= <byte>{18}
<ck8>  ::= <byte>{4}

# Skippable frames of the first and the last magic number, of no data and
# of 40 bytes
<skippable_lo> ::= b'\x50\x2a\x4d\x18' <sz9>
    where bytes(<sz9>) == (0).to_bytes(4, 'little')
<sz9> ::= <byte>{4}

<skippable_hi> ::= b'\x5f\x2a\x4d\x18' <sz10> <data10>
    where bytes(<sz10>) == len(bytes(<data10>)).to_bytes(4, 'little')
<sz10>   ::= <byte>{4}
<data10> ::= <byte>{40}
