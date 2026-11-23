# Same as sz, with chunks and Snappy elements at their edges: a compressed
# block of no data; literals of 1, 60, 61 and 300 bytes (none, one and two
# extra length bytes, and a two-byte varint length); copies of the shortest
# and longest lengths with 1-, 2- and 4-byte offsets, one at offset 1 that
# copies what it writes; uncompressed chunks of no data and of 200; and a
# stream of padding of no bytes, both ends of the reserved skippable types,
# and the stream identifier a second time. The lengths and CRCs are where
# constraints, with the helpers of sz.
#
# TODO:
# * No reserved unskippable chunks (0x02 to 0x7f): readers refuse them, and
#   how many files decode would depend on how often Fandango picks them.

include("sz/sz.fan")

<start> ::= <f_empty_block> | <f_lit_min> | <f_lit_short_max> \
          | <f_lit_ext1> | <f_lit_ext2> | <f_rle> | <f_copy1_min> \
          | <f_copy2_max> | <f_copy4_min> | <f_unc_empty> | <f_unc_big> \
          | <f_multi>

# A compressed block of no data: a length of 0, no elements
<f_empty_block> ::= <stream_id> <ch_e>
<ch_e> ::= b'\x00' <clen_e> <crc_e> <block_e>
    where bytes(<clen_e>) == le3(4 + len(bytes(<block_e>)))
    where bytes(<crc_e>) == sz_crc(sz_decompress(bytes(<block_e>)))
<clen_e> ::= <byte>{3}
<crc_e> ::= <byte>{4}
<block_e> ::= b'\x00'

# A literal of one byte, the shortest
<f_lit_min> ::= <stream_id> <ch_lm>
<ch_lm> ::= b'\x00' <clen_lm> <crc_lm> <block_lm>
    where bytes(<clen_lm>) == le3(4 + len(bytes(<block_lm>)))
    where bytes(<crc_lm>) == sz_crc(sz_decompress(bytes(<block_lm>)))
<clen_lm> ::= <byte>{3}
<crc_lm> ::= <byte>{4}
<block_lm> ::= b'\x01\x00' <lit_lm>
<lit_lm> ::= <byte>{1}

# A literal of 60 bytes, the longest without an extra length byte
<f_lit_short_max> ::= <stream_id> <ch_ls>
<ch_ls> ::= b'\x00' <clen_ls> <crc_ls> <block_ls>
    where bytes(<clen_ls>) == le3(4 + len(bytes(<block_ls>)))
    where bytes(<crc_ls>) == sz_crc(sz_decompress(bytes(<block_ls>)))
<clen_ls> ::= <byte>{3}
<crc_ls> ::= <byte>{4}
<block_ls> ::= b'\x3c\xec' <lit_ls>
<lit_ls> ::= <byte>{60}

# 61 bytes, one more: one extra length byte
<f_lit_ext1> ::= <stream_id> <ch_e1>
<ch_e1> ::= b'\x00' <clen_e1> <crc_e1> <block_e1>
    where bytes(<clen_e1>) == le3(4 + len(bytes(<block_e1>)))
    where bytes(<crc_e1>) == sz_crc(sz_decompress(bytes(<block_e1>)))
<clen_e1> ::= <byte>{3}
<crc_e1> ::= <byte>{4}
<block_e1> ::= b'\x3d\xf0\x3c' <lit_e1>
<lit_e1> ::= <byte>{61}

# 300 bytes: two extra length bytes, and a length of two varint bytes
<f_lit_ext2> ::= <stream_id> <ch_e2>
<ch_e2> ::= b'\x00' <clen_e2> <crc_e2> <block_e2>
    where bytes(<clen_e2>) == le3(4 + len(bytes(<block_e2>)))
    where bytes(<crc_e2>) == sz_crc(sz_decompress(bytes(<block_e2>)))
<clen_e2> ::= <byte>{3}
<crc_e2> ::= <byte>{4}
<block_e2> ::= b'\xac\x02\xf4\x2b\x01' <lit_e2>
<lit_e2> ::= <byte>{300}

# One byte, and a copy of 11 bytes (the longest with a 1-byte offset) at
# offset 1, which copies what it writes
<f_rle> ::= <stream_id> <ch_rle>
<ch_rle> ::= b'\x00' <clen_r> <crc_r> <block_r>
    where bytes(<clen_r>) == le3(4 + len(bytes(<block_r>)))
    where bytes(<crc_r>) == sz_crc(sz_decompress(bytes(<block_r>)))
<clen_r> ::= <byte>{3}
<crc_r> ::= <byte>{4}
<block_r> ::= b'\x0c\x00' <lit_r> b'\x1d\x01'
<lit_r> ::= <byte>{1}

# A copy of four bytes (the shortest with a 1-byte offset), at offset 3
<f_copy1_min> ::= <stream_id> <ch_c1>
<ch_c1> ::= b'\x00' <clen_c1> <crc_c1> <block_c1>
    where bytes(<clen_c1>) == le3(4 + len(bytes(<block_c1>)))
    where bytes(<crc_c1>) == sz_crc(sz_decompress(bytes(<block_c1>)))
<clen_c1> ::= <byte>{3}
<crc_c1> ::= <byte>{4}
<block_c1> ::= b'\x07\x08' <lit_c1> b'\x01\x03'
<lit_c1> ::= <byte>{3}

# A copy of 64 bytes (the longest), with a 2-byte offset
<f_copy2_max> ::= <stream_id> <ch_c2>
<ch_c2> ::= b'\x00' <clen_c2> <crc_c2> <block_c2>
    where bytes(<clen_c2>) == le3(4 + len(bytes(<block_c2>)))
    where bytes(<crc_c2>) == sz_crc(sz_decompress(bytes(<block_c2>)))
<clen_c2> ::= <byte>{3}
<crc_c2> ::= <byte>{4}
<block_c2> ::= b'\x80\x01\xf0\x3f' <lit_c2> b'\xfe\x40\x00'
<lit_c2> ::= <byte>{64}

# A copy of one byte (the shortest), with a 4-byte offset
<f_copy4_min> ::= <stream_id> <ch_c4>
<ch_c4> ::= b'\x00' <clen_c4> <crc_c4> <block_c4>
    where bytes(<clen_c4>) == le3(4 + len(bytes(<block_c4>)))
    where bytes(<crc_c4>) == sz_crc(sz_decompress(bytes(<block_c4>)))
<clen_c4> ::= <byte>{3}
<crc_c4> ::= <byte>{4}
<block_c4> ::= b'\x06\x10' <lit_c4> b'\x03\x05\x00\x00\x00'
<lit_c4> ::= <byte>{5}

# An uncompressed chunk of no data: the CRC alone
<f_unc_empty> ::= <stream_id> <ch_ue>
<ch_ue> ::= b'\x01' <clen_ue> <crc_ue>
    where bytes(<clen_ue>) == le3(4)
    where bytes(<crc_ue>) == sz_crc(b'')
<clen_ue> ::= <byte>{3}
<crc_ue> ::= <byte>{4}

# An uncompressed chunk of 200 bytes
<f_unc_big> ::= <stream_id> <ch_ub>
<ch_ub> ::= b'\x01' <clen_ub> <crc_ub> <raw_ub>
    where bytes(<clen_ub>) == le3(4 + len(bytes(<raw_ub>)))
    where bytes(<crc_ub>) == sz_crc(bytes(<raw_ub>))
<clen_ub> ::= <byte>{3}
<crc_ub> ::= <byte>{4}
<raw_ub> ::= <byte>{200}

# Padding of no bytes, reserved chunks of the first and last skippable types
# (0x80, 0xfd) around a compressed chunk, the stream identifier again, and
# an uncompressed chunk
<f_multi> ::= <stream_id> <ch_pad0> <ch_skip_lo> <ch_litM> <ch_skip_hi> \
              <stream_id> <ch_uncM>

<ch_pad0> ::= b'\xfe\x00\x00\x00'

<ch_skip_lo> ::= b'\x80' <clen_sl> <skip_sl>
    where bytes(<clen_sl>) == le3(len(bytes(<skip_sl>)))
<clen_sl> ::= <byte>{3}
<skip_sl> ::= <byte>{7}

<ch_litM> ::= b'\x00' <clen_m> <crc_m> <block_m>
    where bytes(<clen_m>) == le3(4 + len(bytes(<block_m>)))
    where bytes(<crc_m>) == sz_crc(sz_decompress(bytes(<block_m>)))
<clen_m> ::= <byte>{3}
<crc_m> ::= <byte>{4}
<block_m> ::= b'\x20\x3c' <lit_m> b'\x3e\x10\x00'
<lit_m> ::= <byte>{16}

<ch_skip_hi> ::= b'\xfd' <clen_sh> <skip_sh>
    where bytes(<clen_sh>) == le3(len(bytes(<skip_sh>)))
<clen_sh> ::= <byte>{3}
<skip_sh> ::= <byte>{5}

<ch_uncM> ::= b'\x01' <clen_um> <crc_um> <raw_um>
    where bytes(<clen_um>) == le3(4 + len(bytes(<raw_um>)))
    where bytes(<crc_um>) == sz_crc(bytes(<raw_um>))
<clen_um> ::= <byte>{3}
<crc_um> ::= <byte>{4}
<raw_um> ::= <byte>{12}
