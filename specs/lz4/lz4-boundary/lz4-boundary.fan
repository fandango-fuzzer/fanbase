# LZ4 files at the edges of the frame and block formats: a compressed block
# of a token alone (no data), a frame with no blocks, a content size of 0, a
# literal run long enough to need an extra length byte, a match that copies
# the byte before it (a copy that overlaps itself) and starts closer to the
# end of the block than the block format allows (12 bytes; decoders take it),
# a stored block, every block size, every flag alone and all together, four
# blocks with checksums (one of a single byte), skippable frames of every
# magic number and of no data, and legacy frames of one block and of two.
# Sizes and checksums are where constraints, as in lz4.
#
# TODO:
# * Each frame holds a fixed number of bytes.

# XXH32 with seed 0, the only one LZ4 uses
def xxh32(data):
    seed = 0
    data = bytes(data)
    P1, P2, P3, P4, P5 = (0x9E3779B1, 0x85EBCA77, 0xC2B2AE3D,
                          0x27D4EB2F, 0x165667B1)
    M = 0xFFFFFFFF
    def rotl(x, r):
        return ((x << r) | (x >> (32 - r))) & M
    def rnd(acc, lane):
        return (rotl((acc + (lane * P2 & M)) & M, 13) * P1) & M
    n = len(data)
    i = 0
    if n >= 16:
        v1 = (seed + P1 + P2) & M
        v2 = (seed + P2) & M
        v3 = seed & M
        v4 = (seed - P1) & M
        while i <= n - 16:
            v1 = rnd(v1, int.from_bytes(data[i:i + 4], "little")); i += 4
            v2 = rnd(v2, int.from_bytes(data[i:i + 4], "little")); i += 4
            v3 = rnd(v3, int.from_bytes(data[i:i + 4], "little")); i += 4
            v4 = rnd(v4, int.from_bytes(data[i:i + 4], "little")); i += 4
        h = (rotl(v1, 1) + rotl(v2, 7) + rotl(v3, 12) + rotl(v4, 18)) & M
    else:
        h = (seed + P5) & M
    h = (h + n) & M
    while i <= n - 4:
        h = (h + (int.from_bytes(data[i:i + 4], "little") * P3 & M)) & M
        h = (rotl(h, 17) * P4) & M
        i += 4
    while i < n:
        h = (h + (data[i] * P5 & M)) & M
        h = (rotl(h, 11) * P1) & M
        i += 1
    h ^= h >> 15
    h = (h * P2) & M
    h ^= h >> 13
    h = (h * P3) & M
    h ^= h >> 16
    return h & M


def xxh32le(data):
    return (xxh32(data)).to_bytes(4, "little")


# The header checksum: the second byte of the XXH32 of the descriptor
def hc(desc):
    return bytes([(xxh32(bytes(desc)) >> 8) & 0xFF])


def u32le(n):
    return (n & 0xFFFFFFFF).to_bytes(4, "little")


def u64le(n):
    return (n & 0xFFFFFFFFFFFFFFFF).to_bytes(8, "little")


# The block size; its highest bit says that the block is stored as it is
def bsize(length, uncompressed):
    return u32le(length | (0x80000000 if uncompressed else 0))



<start> ::= <f_emptyblock> | <f_noblocks> | <f_litext> | <f_match> \
          | <f_uncomp> | <f_bcksum> | <f_csize0> | <f_ccksum_empty> \
          | <f_dictid> | <f_multi> | <f_all> | <f_bd_sweep> \
          | <f_skippable> | <f_skip0> | <f_legacy> | <f_legacy_multi>

<byte> ::= rb'[\x00-\xff]'
<magic> ::= b'\x04\x22\x4d\x18'
<endmark> ::= b'\x00\x00\x00\x00'


# A compressed block of one token, 0x00: no literals, no match, no data
<f_emptyblock> ::= <magic> b'\x40' b'\x40' <hc1> <bsz1> b'\x00' <endmark>
    where bytes(<bsz1>) == bsize(1, False)
    where bytes(<hc1>) == hc(b'\x40\x40')
<hc1> ::= <byte>
<bsz1> ::= <byte>{4}


# No blocks: the descriptor, the end mark, and the checksum of no content
<f_noblocks> ::= <magic> b'\x44' b'\x70' <hc2> <endmark> <cck2>
    where bytes(<hc2>) == hc(b'\x44\x70')
    where bytes(<cck2>) == xxh32le(b'')
<hc2> ::= <byte>
<cck2> ::= <byte>{4}


# 20 literals: a token of 15 (0xf0), then an extra length byte of 5
<f_litext> ::= <magic> b'\x40' b'\x50' <hc3> <bsz3> b'\xf0' b'\x05' <lit3> <endmark>
    where bytes(<bsz3>) == bsize(1 + 1 + len(bytes(<lit3>)), False)
    where bytes(<hc3>) == hc(b'\x40\x50')
<hc3> ::= <byte>
<bsz3> ::= <byte>{4}
<lit3> ::= <byte>{20}


# Six literals, a match of four bytes at offset 1 (the byte before, copied
# over itself), and five literals. The match starts nine bytes before the end,
# closer than the 12 the block format allows.
<f_match> ::= <magic> b'\x40' b'\x70' <hc4> <bsz4> \
              b'\x60' <lit4a> b'\x01\x00' b'\x50' <lit4b> <endmark>
    where bytes(<bsz4>) == bsize(1 + len(bytes(<lit4a>)) + 2 + 1 + len(bytes(<lit4b>)), False)
    where bytes(<hc4>) == hc(b'\x40\x70')
<hc4> ::= <byte>
<bsz4> ::= <byte>{4}
<lit4a> ::= <byte>{6}
<lit4b> ::= <byte>{5}


# A stored block, independent blocks, 1 MB
<f_uncomp> ::= <magic> b'\x60' b'\x60' <hc5> <bsz5> <blk5> <endmark>
    where bytes(<bsz5>) == bsize(len(bytes(<blk5>)), True)
    where bytes(<hc5>) == hc(b'\x60\x60')
<hc5> ::= <byte>
<bsz5> ::= <byte>{4}
<blk5> ::= <byte>{47}


# A block checksum
<f_bcksum> ::= <magic> b'\x50' b'\x50' <hc6> <bsz6> <blk6> <bck6> <endmark>
    where bytes(<bsz6>) == bsize(len(bytes(<blk6>)), True)
    where bytes(<bck6>) == xxh32le(bytes(<blk6>))
    where bytes(<hc6>) == hc(b'\x50\x50')
<hc6> ::= <byte>
<bsz6> ::= <byte>{4}
<blk6> ::= <byte>{33}
<bck6> ::= <byte>{4}


# A content size of 0, and the block of a token alone
<f_csize0> ::= <magic> b'\x48' b'\x40' <csz7> <hc7> <bsz7> b'\x00' <endmark>
    where bytes(<bsz7>) == bsize(1, False)
    where bytes(<csz7>) == u64le(0)
    where bytes(<hc7>) == hc(b'\x48\x40' + bytes(<csz7>))
<csz7> ::= <byte>{8}
<hc7> ::= <byte>
<bsz7> ::= <byte>{4}


# The content checksum of one stored block
<f_ccksum_empty> ::= <magic> b'\x44' b'\x70' <hc8> <bsz8> <blk8> <endmark> <cck8>
    where bytes(<bsz8>) == bsize(len(bytes(<blk8>)), True)
    where bytes(<hc8>) == hc(b'\x44\x70')
    where bytes(<cck8>) == xxh32le(bytes(<blk8>))
<hc8> ::= <byte>
<bsz8> ::= <byte>{4}
<blk8> ::= <byte>{29}
<cck8> ::= <byte>{4}


# A dictionary ID
<f_dictid> ::= <magic> b'\x41' b'\x40' <did9> <hc9> <bsz9> <blk9> <endmark>
    where bytes(<bsz9>) == bsize(len(bytes(<blk9>)), True)
    where bytes(<hc9>) == hc(b'\x41\x40' + bytes(<did9>))
<did9> ::= <byte>{4}
<hc9> ::= <byte>
<bsz9> ::= <byte>{4}
<blk9> ::= <byte>{21}


# Four stored blocks with checksums, of 1, 16, 7 and 22 bytes
<f_multi> ::= <magic> b'\x50' b'\x50' <hcA> \
              <bszAa> <blkAa> <bckAa> \
              <bszAb> <blkAb> <bckAb> \
              <bszAc> <blkAc> <bckAc> \
              <bszAd> <blkAd> <bckAd> <endmark>
    where bytes(<bszAa>) == bsize(len(bytes(<blkAa>)), True)
    where bytes(<bszAb>) == bsize(len(bytes(<blkAb>)), True)
    where bytes(<bszAc>) == bsize(len(bytes(<blkAc>)), True)
    where bytes(<bszAd>) == bsize(len(bytes(<blkAd>)), True)
    where bytes(<bckAa>) == xxh32le(bytes(<blkAa>))
    where bytes(<bckAb>) == xxh32le(bytes(<blkAb>))
    where bytes(<bckAc>) == xxh32le(bytes(<blkAc>))
    where bytes(<bckAd>) == xxh32le(bytes(<blkAd>))
    where bytes(<hcA>) == hc(b'\x50\x50')
<hcA> ::= <byte>
<bszAa> ::= <byte>{4}
<bszAb> ::= <byte>{4}
<bszAc> ::= <byte>{4}
<bszAd> ::= <byte>{4}
<blkAa> ::= <byte>{1}
<blkAb> ::= <byte>{16}
<blkAc> ::= <byte>{7}
<blkAd> ::= <byte>{22}
<bckAa> ::= <byte>{4}
<bckAb> ::= <byte>{4}
<bckAc> ::= <byte>{4}
<bckAd> ::= <byte>{4}


# Every flag: the content size, a dictionary ID, two blocks with checksums,
# and the content checksum
<f_all> ::= <magic> b'\x7d' b'\x70' <cszB> <didB> <hcB> \
            <bszBa> <blkBa> <bckBa> \
            <bszBb> <blkBb> <bckBb> <endmark> <cckB>
    where bytes(<bszBa>) == bsize(len(bytes(<blkBa>)), True)
    where bytes(<bszBb>) == bsize(len(bytes(<blkBb>)), True)
    where bytes(<cszB>) == u64le(len(bytes(<blkBa>)) + len(bytes(<blkBb>)))
    where bytes(<hcB>) == hc(b'\x7d\x70' + bytes(<cszB>) + bytes(<didB>))
    where bytes(<bckBa>) == xxh32le(bytes(<blkBa>))
    where bytes(<bckBb>) == xxh32le(bytes(<blkBb>))
    where bytes(<cckB>) == xxh32le(bytes(<blkBa>) + bytes(<blkBb>))
<cszB> ::= <byte>{8}
<didB> ::= <byte>{4}
<hcB> ::= <byte>
<bszBa> ::= <byte>{4}
<bszBb> ::= <byte>{4}
<blkBa> ::= <byte>{14}
<blkBb> ::= <byte>{18}
<bckBa> ::= <byte>{4}
<bckBb> ::= <byte>{4}
<cckB> ::= <byte>{4}


# Every block size (BD 0x40 to 0x70)
<f_bd_sweep> ::= <magic> b'\x40' <bdC> <hcC> <bszC> <blkC> <endmark>
    where int(<bdC>) in (0x40, 0x50, 0x60, 0x70)
    where bytes(<bszC>) == bsize(len(bytes(<blkC>)), True)
    where bytes(<hcC>) == hc(b'\x40' + bytes(<bdC>))
<bdC> ::= <byte>
<hcC> ::= <byte>
<bszC> ::= <byte>{4}
<blkC> ::= <byte>{25}


# A skippable frame of any of its 16 magic numbers, with 50 bytes
<f_skippable> ::= <smagic> <sfsz> <sdata>
    where bytes(<sfsz>) == u32le(len(bytes(<sdata>)))
<smagic> ::= rb'[\x50-\x5f]' b'\x2a\x4d\x18'
<sfsz> ::= <byte>{4}
<sdata> ::= <byte>{50}


# A skippable frame of no data
<f_skip0> ::= <smagic0> <sfsz0>
    where bytes(<sfsz0>) == u32le(0)
<smagic0> ::= rb'[\x50-\x5f]' b'\x2a\x4d\x18'
<sfsz0> ::= <byte>{4}


# A legacy frame of one block
<f_legacy> ::= b'\x02\x21\x4c\x18' <lbsz> <ltok> <llit>
    where bytes(<ltok>) == bytes([(len(bytes(<llit>)) & 0x0F) << 4])
    where bytes(<lbsz>) == u32le(1 + len(bytes(<llit>)))
<lbsz> ::= <byte>{4}
<ltok> ::= <byte>
<llit> ::= <byte>{13}


# A legacy frame of two blocks
<f_legacy_multi> ::= b'\x02\x21\x4c\x18' \
                     <lb1> <lt1> <ll1> \
                     <lb2> <lt2> <ll2>
    where bytes(<lt1>) == bytes([(len(bytes(<ll1>)) & 0x0F) << 4])
    where bytes(<lb1>) == u32le(1 + len(bytes(<ll1>)))
    where bytes(<lt2>) == bytes([(len(bytes(<ll2>)) & 0x0F) << 4])
    where bytes(<lb2>) == u32le(1 + len(bytes(<ll2>)))
<lb1> ::= <byte>{4}
<lt1> ::= <byte>
<ll1> ::= <byte>{9}
<lb2> ::= <byte>{4}
<lt2> ::= <byte>
<ll2> ::= <byte>{11}
