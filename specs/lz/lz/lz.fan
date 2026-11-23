# lzip files of one or two members. A member is the header ("LZIP", version 1
# and the coded dictionary size), an LZMA stream (lc=3, lp=0, pb=2, with an
# end marker) and a trailer: the CRC-32 and the size of the data, and the size
# of the member. The dictionary sizes are 4 KiB, 64 KiB, 256 KiB, 1 MiB,
# 8 MiB, and 960 KiB, one that is not a power of two. Python's lzma module
# compresses text, one byte repeated, or random bytes, and where constraints
# decompress the stream to make the trailer from it.
#
# TODO:
# * The data is drawn with `random`, not by Fandango.
# * Each member has the same dictionary size and kind of data every time.

import lzma
import zlib
import random


def u32le(n):
    return (n & 0xFFFFFFFF).to_bytes(4, "little")


def u64le(n):
    return (n & 0xFFFFFFFFFFFFFFFF).to_bytes(8, "little")


# The dictionary size that the coded byte says: 2 to the power of its low five
# bits, less as many sixteenths of that as its top three bits say.
def decode_ds(ds_byte):
    exp = ds_byte & 0x1F
    frac = (ds_byte >> 5) & 0x7
    size = 1 << exp
    if frac:
        size -= (size >> 4) * frac
    return size


# The data of a member: one byte repeated, text, or random bytes ("mix").
def _shape(mode):
    if mode == "run":
        return bytes([random.randrange(256)]) * random.randint(16, 160)
    if mode == "text":
        alpha = b"the quick brown lzip fox jumps over the lazy dog. "
        n = random.randint(20, 400)
        return (alpha * ((n // len(alpha)) + 1))[:n]
    return bytes(random.choices(range(256), k=random.randint(8, 200)))


# The LZMA stream of a member: an .lzma stream with lzip's parameters, without
# its 13-byte header.
def make_lzma(mode, ds_byte):
    data = _shape(mode)
    filt = [{"id": lzma.FILTER_LZMA1, "dict_size": decode_ds(ds_byte),
             "lc": 3, "lp": 0, "pb": 2}]
    return lzma.compress(data, format=lzma.FORMAT_ALONE, filters=filt)[13:]


# The data of a member's LZMA stream, decompressed with the dictionary size
# of its header.
def lzip_inflate(stream, ds_byte):
    dsz = decode_ds(ds_byte)
    header = bytes([0x5D]) + dsz.to_bytes(4, "little") + u64le(0xFFFFFFFFFFFFFFFF)
    return lzma.decompress(header + bytes(stream), format=lzma.FORMAT_ALONE)


def crc_of(stream, ds):
    return u32le(zlib.crc32(lzip_inflate(stream, bytes(ds)[0])))


def dsize_of(stream, ds):
    return u64le(len(lzip_inflate(stream, bytes(ds)[0])))


# header (6 bytes) + stream + trailer (20 bytes)
def msize_of(stream):
    return u64le(6 + len(bytes(stream)) + 20)


<start> ::= <member_a> | <member_b> | <member_c> | <member_wedge> | <member_multi>


<byte>  ::= rb'[\x00-\xff]'
<magic> ::= b'LZIP'
<vn>    ::= b'\x01'


# 4 KiB dictionary, text
<member_a> ::= <magic> <vn> <ds_a> <body_a> <crc_a> <dsize_a> <msize_a>
    where bytes(<crc_a>)   == crc_of(bytes(<body_a>), bytes(<ds_a>))
    where bytes(<dsize_a>) == dsize_of(bytes(<body_a>), bytes(<ds_a>))
    where bytes(<msize_a>) == msize_of(bytes(<body_a>))
<ds_a>    ::= b'\x0c'
<body_a>  ::= <byte>* := make_lzma('text', 0x0c)
<crc_a>   ::= <byte>{4}
<dsize_a> ::= <byte>{8}
<msize_a> ::= <byte>{8}


# 1 MiB dictionary, one byte repeated
<member_b> ::= <magic> <vn> <ds_b> <body_b> <crc_b> <dsize_b> <msize_b>
    where bytes(<crc_b>)   == crc_of(bytes(<body_b>), bytes(<ds_b>))
    where bytes(<dsize_b>) == dsize_of(bytes(<body_b>), bytes(<ds_b>))
    where bytes(<msize_b>) == msize_of(bytes(<body_b>))
<ds_b>    ::= b'\x14'
<body_b>  ::= <byte>* := make_lzma('run', 0x14)
<crc_b>   ::= <byte>{4}
<dsize_b> ::= <byte>{8}
<msize_b> ::= <byte>{8}


# 8 MiB dictionary, random bytes
<member_c> ::= <magic> <vn> <ds_c> <body_c> <crc_c> <dsize_c> <msize_c>
    where bytes(<crc_c>)   == crc_of(bytes(<body_c>), bytes(<ds_c>))
    where bytes(<dsize_c>) == dsize_of(bytes(<body_c>), bytes(<ds_c>))
    where bytes(<msize_c>) == msize_of(bytes(<body_c>))
<ds_c>    ::= b'\x17'
<body_c>  ::= <byte>* := make_lzma('mix', 0x17)
<crc_c>   ::= <byte>{4}
<dsize_c> ::= <byte>{8}
<msize_c> ::= <byte>{8}


# A dictionary size that is not a power of two: 0x34 is 2^20 less one
# sixteenth of it, 983,040 bytes
<member_wedge> ::= <magic> <vn> <ds_w> <body_w> <crc_w> <dsize_w> <msize_w>
    where bytes(<crc_w>)   == crc_of(bytes(<body_w>), bytes(<ds_w>))
    where bytes(<dsize_w>) == dsize_of(bytes(<body_w>), bytes(<ds_w>))
    where bytes(<msize_w>) == msize_of(bytes(<body_w>))
<ds_w>    ::= b'\x34'
<body_w>  ::= <byte>* := make_lzma('text', 0x34)
<crc_w>   ::= <byte>{4}
<dsize_w> ::= <byte>{8}
<msize_w> ::= <byte>{8}


# Two members, with 64 KiB and 256 KiB dictionaries
<member_multi> ::= <mm_one> <mm_two>
<mm_one> ::= <magic> <vn> <ds_m1> <body_m1> <crc_m1> <dsize_m1> <msize_m1>
    where bytes(<crc_m1>)   == crc_of(bytes(<body_m1>), bytes(<ds_m1>))
    where bytes(<dsize_m1>) == dsize_of(bytes(<body_m1>), bytes(<ds_m1>))
    where bytes(<msize_m1>) == msize_of(bytes(<body_m1>))
<ds_m1>    ::= b'\x10'
<body_m1>  ::= <byte>* := make_lzma('text', 0x10)
<crc_m1>   ::= <byte>{4}
<dsize_m1> ::= <byte>{8}
<msize_m1> ::= <byte>{8}
<mm_two> ::= <magic> <vn> <ds_m2> <body_m2> <crc_m2> <dsize_m2> <msize_m2>
    where bytes(<crc_m2>)   == crc_of(bytes(<body_m2>), bytes(<ds_m2>))
    where bytes(<dsize_m2>) == dsize_of(bytes(<body_m2>), bytes(<ds_m2>))
    where bytes(<msize_m2>) == msize_of(bytes(<body_m2>))
<ds_m2>    ::= b'\x12'
<body_m2>  ::= <byte>* := make_lzma('run', 0x12)
<crc_m2>   ::= <byte>{4}
<dsize_m2> ::= <byte>{8}
<msize_m2> ::= <byte>{8}
