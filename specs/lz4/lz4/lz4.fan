# LZ4 files: one frame of the LZ4 frame format, a skippable frame, or a
# legacy frame. The frames cover the flags one at a time and all together
# (independent blocks, block and content checksums, content size, dictionary
# ID), every block size (64 KB to 4 MB), blocks stored as they are and blocks
# that are LZ4-compressed, one block or several. One frame holds a block that
# an LZ4 compressor here makes from data Fandango draws, with matches, copies
# that overlap what they copy, and long literal runs and matches. Every field
# that depends on another is a where constraint: block sizes, the content
# size, the header checksum, and the XXH32 of each block and of the content,
# computed by the XXH32 here.
#
# TODO:
# * The other frames hold a fixed number of bytes, and their compressed blocks
#   are literals only.
# * Blocks that depend on the one before them (no "independent blocks" flag)
#   are made only one at a time, so none refers back into another block.

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


# An LZ4 block of literals only: a token (the number of literals, under 15),
# then the literals
def litblock(literals):
    return bytes([(len(literals) & 0x0F) << 4]) + bytes(literals)



# A length of 15 or more: what is left after 15, in bytes of 255 and a last
# one under 255
def _more(v):
    out = bytearray()
    v -= 15
    while v >= 255:
        out.append(255)
        v -= 255
    out.append(v)
    return bytes(out)


# An LZ4 block of the data: each match found through the last position at
# which its four bytes were seen, if it is within 64 KiB. As the block format
# asks, no match starts in the last 12 bytes and the last 5 are literals.
def lz4_block(data):
    data = bytes(data)
    n = len(data)
    out = bytearray()
    seen = dict()
    anchor = 0
    i = 0
    while i <= n - 12:
        key = data[i:i + 4]
        j = seen.get(key)
        seen[key] = i
        if j is None or i - j > 65535:
            i += 1
            continue
        m = 4
        while i + m < n - 5 and data[j + m] == data[i + m]:
            m += 1
        lit = i - anchor
        out.append((min(lit, 15) << 4) | min(m - 4, 15))
        if lit >= 15:
            out += _more(lit)
        out += data[anchor:i]
        out += (i - j).to_bytes(2, "little")
        if m - 4 >= 15:
            out += _more(m - 4)
        i += m
        anchor = i
    lit = n - anchor
    out.append(min(lit, 15) << 4)
    if lit >= 15:
        out += _more(lit)
    out += data[anchor:]
    return bytes(out)


# What an LZ4 block decompresses to
def lz4_unblock(block):
    b = bytes(block)
    out = bytearray()
    i = 0
    while i < len(b):
        token = b[i]
        i += 1
        lit = token >> 4
        if lit == 15:
            while True:
                lit += b[i]
                i += 1
                if b[i - 1] != 255:
                    break
        out += b[i:i + lit]
        i += lit
        if i >= len(b):
            break
        offset = b[i] | (b[i + 1] << 8)
        i += 2
        m = token & 15
        if m == 15:
            while True:
                m += b[i]
                i += 1
                if b[i - 1] != 255:
                    break
        for _ in range(m + 4):
            out.append(out[-offset])
    return bytes(out)


# Data with something to match: the bytes Fandango drew as letters, repeated
# up to seven times, then the bytes themselves
def lz4_data(seed):
    seed = bytes(seed)
    letters = bytes(b"abcdefgh "[x % 9] for x in seed)
    return letters * (1 + len(seed) % 7) + seed


<start> ::= <f_min> | <f_bindep> | <f_bcksum> | <f_csize> | <f_ccksum> \
          | <f_dictid> | <f_compressed> | <f_multi> | <f_all> \
          | <f_skippable> | <f_legacy> | <f_lz4>

<byte> ::= rb'[\x00-\xff]'
<magic> ::= b'\x04\x22\x4d\x18'
<endmark> ::= b'\x00\x00\x00\x00'


# No flags, 4 MB blocks: one stored block

<f_min> ::= <magic> b'\x40' b'\x70' <hc1> <bsz1> <blk1> <endmark>
    where bytes(<bsz1>) == bsize(len(bytes(<blk1>)), True)
    where bytes(<hc1>) == hc(b'\x40\x70')
<hc1> ::= <byte>
<bsz1> ::= <byte>{4}
<blk1> ::= <byte>{24}


# Independent blocks, 64 KB

<f_bindep> ::= <magic> b'\x60' b'\x40' <hc2> <bsz2> <blk2> <endmark>
    where bytes(<bsz2>) == bsize(len(bytes(<blk2>)), True)
    where bytes(<hc2>) == hc(b'\x60\x40')
<hc2> ::= <byte>
<bsz2> ::= <byte>{4}
<blk2> ::= <byte>{40}


# Block checksums, 256 KB

<f_bcksum> ::= <magic> b'\x50' b'\x50' <hc3> <bsz3> <blk3> <bck3> <endmark>
    where bytes(<bsz3>) == bsize(len(bytes(<blk3>)), True)
    where bytes(<bck3>) == xxh32le(bytes(<blk3>))
    where bytes(<hc3>) == hc(b'\x50\x50')
<hc3> ::= <byte>
<bsz3> ::= <byte>{4}
<blk3> ::= <byte>{32}
<bck3> ::= <byte>{4}


# The content size, 1 MB

<f_csize> ::= <magic> b'\x48' b'\x60' <csz4> <hc4> <bsz4> <blk4> <endmark>
    where bytes(<bsz4>) == bsize(len(bytes(<blk4>)), True)
    where bytes(<csz4>) == u64le(len(bytes(<blk4>)))
    where bytes(<hc4>) == hc(b'\x48\x60' + bytes(<csz4>))
<csz4> ::= <byte>{8}
<hc4> ::= <byte>
<bsz4> ::= <byte>{4}
<blk4> ::= <byte>{28}


# The content checksum, after the end mark

<f_ccksum> ::= <magic> b'\x44' b'\x70' <hc5> <bsz5> <blk5> <endmark> <cck5>
    where bytes(<bsz5>) == bsize(len(bytes(<blk5>)), True)
    where bytes(<hc5>) == hc(b'\x44\x70')
    where bytes(<cck5>) == xxh32le(bytes(<blk5>))
<hc5> ::= <byte>
<bsz5> ::= <byte>{4}
<blk5> ::= <byte>{36}
<cck5> ::= <byte>{4}


# A dictionary ID

<f_dictid> ::= <magic> b'\x41' b'\x40' <did6> <hc6> <bsz6> <blk6> <endmark>
    where bytes(<bsz6>) == bsize(len(bytes(<blk6>)), True)
    where bytes(<hc6>) == hc(b'\x41\x40' + bytes(<did6>))
<did6> ::= <byte>{4}
<hc6> ::= <byte>
<bsz6> ::= <byte>{4}
<blk6> ::= <byte>{20}


# A compressed block, of literals only

<f_compressed> ::= <magic> b'\x40' b'\x70' <hc7> <bsz7> <tok7> <lit7> <endmark>
    where bytes(<tok7>) == bytes([(len(bytes(<lit7>)) & 0x0F) << 4])
    where bytes(<bsz7>) == bsize(1 + len(bytes(<lit7>)), False)
    where bytes(<hc7>) == hc(b'\x40\x70')
<hc7> ::= <byte>
<bsz7> ::= <byte>{4}
<tok7> ::= <byte>
<lit7> ::= <byte>{12}


# Three stored blocks, each with its checksum

<f_multi> ::= <magic> b'\x50' b'\x50' <hc8> \
              <bsz8a> <blk8a> <bck8a> \
              <bsz8b> <blk8b> <bck8b> \
              <bsz8c> <blk8c> <bck8c> <endmark>
    where bytes(<bsz8a>) == bsize(len(bytes(<blk8a>)), True)
    where bytes(<bsz8b>) == bsize(len(bytes(<blk8b>)), True)
    where bytes(<bsz8c>) == bsize(len(bytes(<blk8c>)), True)
    where bytes(<bck8a>) == xxh32le(bytes(<blk8a>))
    where bytes(<bck8b>) == xxh32le(bytes(<blk8b>))
    where bytes(<bck8c>) == xxh32le(bytes(<blk8c>))
    where bytes(<hc8>) == hc(b'\x50\x50')
<hc8> ::= <byte>
<bsz8a> ::= <byte>{4}
<bsz8b> ::= <byte>{4}
<bsz8c> ::= <byte>{4}
<blk8a> ::= <byte>{12}
<blk8b> ::= <byte>{20}
<blk8c> ::= <byte>{16}
<bck8a> ::= <byte>{4}
<bck8b> ::= <byte>{4}
<bck8c> ::= <byte>{4}


# Every flag: the content size, a dictionary ID, two blocks with checksums,
# and the content checksum

<f_all> ::= <magic> b'\x7d' b'\x70' <csz9> <did9> <hc9> \
            <bsz9a> <blk9a> <bck9a> \
            <bsz9b> <blk9b> <bck9b> <endmark> <cck9>
    where bytes(<bsz9a>) == bsize(len(bytes(<blk9a>)), True)
    where bytes(<bsz9b>) == bsize(len(bytes(<blk9b>)), True)
    where bytes(<csz9>) == u64le(len(bytes(<blk9a>)) + len(bytes(<blk9b>)))
    where bytes(<hc9>) == hc(b'\x7d\x70' + bytes(<csz9>) + bytes(<did9>))
    where bytes(<bck9a>) == xxh32le(bytes(<blk9a>))
    where bytes(<bck9b>) == xxh32le(bytes(<blk9b>))
    where bytes(<cck9>) == xxh32le(bytes(<blk9a>) + bytes(<blk9b>))
<csz9> ::= <byte>{8}
<did9> ::= <byte>{4}
<hc9> ::= <byte>
<bsz9a> ::= <byte>{4}
<bsz9b> ::= <byte>{4}
<blk9a> ::= <byte>{14}
<blk9b> ::= <byte>{18}
<bck9a> ::= <byte>{4}
<bck9b> ::= <byte>{4}
<cck9> ::= <byte>{4}


# A skippable frame (magic 0x184D2A50 to 0x184D2A5F): its size, and data

<f_skippable> ::= <smagic> <sfsz> <sdata>
    where bytes(<sfsz>) == u32le(len(bytes(<sdata>)))
<smagic> ::= rb'[\x50-\x5f]' b'\x2a\x4d\x18'
<sfsz> ::= <byte>{4}
<sdata> ::= <byte>{48}


# A legacy frame (magic 0x184C2102): a block size and a compressed block, with
# no descriptor and no end mark

<f_legacy> ::= b'\x02\x21\x4c\x18' <lbsz> <ltok> <llit>
    where bytes(<ltok>) == bytes([(len(bytes(<llit>)) & 0x0F) << 4])
    where bytes(<lbsz>) == u32le(1 + len(bytes(<llit>)))
<lbsz> ::= <byte>{4}
<ltok> ::= <byte>
<llit> ::= <byte>{13}


# Content size, content checksum, 4 MB blocks: one block from the compressor
<f_lz4> ::= <magic> b'\x4c' b'\x70' <csz12> <hc12> <bsz12> <blk12> <endmark> <cck12>
    where bytes(<bsz12>) == bsize(len(bytes(<blk12>)), False)
    where bytes(<csz12>) == u64le(len(lz4_unblock(bytes(<blk12>))))
    where bytes(<hc12>) == hc(b'\x4c\x70' + bytes(<csz12>))
    where bytes(<cck12>) == xxh32le(lz4_unblock(bytes(<blk12>)))
<csz12> ::= <byte>{8}
<hc12> ::= <byte>
<bsz12> ::= <byte>{4}
<blk12> ::= <byte>* := lz4_block(lz4_data(bytes(<lz4_seed>)))
<cck12> ::= <byte>{4}

# The data before it is compressed: Fandango draws it, and it goes into no file
<lz4_seed> ::= <byte>{8,512}
