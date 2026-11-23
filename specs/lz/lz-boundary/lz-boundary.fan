# Same as lz, with members at the edges of what lzip allows: no data at all
# (a data size of 0), a single byte, the smallest dictionary (4 KiB) and the
# largest (512 MiB), dictionary sizes that are not powers of two (every one
# that a coded byte can say, from 7,680 bytes up), random data that does not
# compress, and two members whose dictionary sizes differ. The trailers are
# made by the where constraints of lz.
#
# TODO:
# * The data is drawn with `random`, not by Fandango.

include("lz/lz.fan")


# The data of a member: as in lz, and also none at all, or one byte. The runs
# and the random data are longer.
def _shape(mode):
    if mode == "empty":
        return b""
    if mode == "onebyte":
        return bytes([random.randrange(256)])
    if mode == "run":
        return bytes([random.randrange(256)]) * random.randint(64, 400)
    if mode == "text":
        alpha = b"the quick brown lzip fox jumps over the lazy dog. "
        n = random.randint(20, 400)
        return (alpha * ((n // len(alpha)) + 1))[:n]
    return bytes(random.choices(range(256), k=random.randint(16, 256)))


<start> ::= <member_empty> | <member_onebyte> | <member_a> | <member_max> \
          | <member_c> | <member_wedge> | <member_multi_edge>


# No data, the smallest dictionary
<member_empty> ::= <magic> <vn> <ds_e> <body_e> <crc_e> <dsize_e> <msize_e>
    where bytes(<crc_e>)   == crc_of(bytes(<body_e>), bytes(<ds_e>))
    where bytes(<dsize_e>) == dsize_of(bytes(<body_e>), bytes(<ds_e>))
    where bytes(<msize_e>) == msize_of(bytes(<body_e>))
<ds_e>    ::= b'\x0c'
<body_e>  ::= <byte>* := make_lzma('empty', 0x0c)
<crc_e>   ::= <byte>{4}
<dsize_e> ::= <byte>{8}
<msize_e> ::= <byte>{8}


# One byte, a 16 KiB dictionary
<member_onebyte> ::= <magic> <vn> <ds_o> <body_o> <crc_o> <dsize_o> <msize_o>
    where bytes(<crc_o>)   == crc_of(bytes(<body_o>), bytes(<ds_o>))
    where bytes(<dsize_o>) == dsize_of(bytes(<body_o>), bytes(<ds_o>))
    where bytes(<msize_o>) == msize_of(bytes(<body_o>))
<ds_o>    ::= b'\x0e'
<body_o>  ::= <byte>* := make_lzma('onebyte', 0x0e)
<crc_o>   ::= <byte>{4}
<dsize_o> ::= <byte>{8}
<msize_o> ::= <byte>{8}


# The largest dictionary, 512 MiB, and one byte repeated
<member_max> ::= <magic> <vn> <ds_mx> <body_mx> <crc_mx> <dsize_mx> <msize_mx>
    where bytes(<crc_mx>)   == crc_of(bytes(<body_mx>), bytes(<ds_mx>))
    where bytes(<dsize_mx>) == dsize_of(bytes(<body_mx>), bytes(<ds_mx>))
    where bytes(<msize_mx>) == msize_of(bytes(<body_mx>))
<ds_mx>    ::= b'\x1d'
<body_mx>  ::= <byte>* := make_lzma('run', 0x1d)
<crc_mx>   ::= <byte>{4}
<dsize_mx> ::= <byte>{8}
<msize_mx> ::= <byte>{8}


# Every dictionary size that is not a power of two: 2^13 to 2^29 (the low
# five bits), less one to seven sixteenths of it (the top three bits). The
# stream is the same for any of them: the data is far smaller than the
# smallest dictionary.
<ds_w> ::= rb'[\x2d-\x3d\x4d-\x5d\x6d-\x7d\x8d-\x9d\xad-\xbd\xcd-\xdd\xed-\xfd]'


# Two members: 64 KiB, then 2^21 less two sixteenths of it (1,835,008 bytes)
<member_multi_edge> ::= <me_one> <me_two>
<me_one> ::= <magic> <vn> <ds_e1> <body_e1> <crc_e1> <dsize_e1> <msize_e1>
    where bytes(<crc_e1>)   == crc_of(bytes(<body_e1>), bytes(<ds_e1>))
    where bytes(<dsize_e1>) == dsize_of(bytes(<body_e1>), bytes(<ds_e1>))
    where bytes(<msize_e1>) == msize_of(bytes(<body_e1>))
<ds_e1>    ::= b'\x10'
<body_e1>  ::= <byte>* := make_lzma('text', 0x10)
<crc_e1>   ::= <byte>{4}
<dsize_e1> ::= <byte>{8}
<msize_e1> ::= <byte>{8}
<me_two> ::= <magic> <vn> <ds_e2> <body_e2> <crc_e2> <dsize_e2> <msize_e2>
    where bytes(<crc_e2>)   == crc_of(bytes(<body_e2>), bytes(<ds_e2>))
    where bytes(<dsize_e2>) == dsize_of(bytes(<body_e2>), bytes(<ds_e2>))
    where bytes(<msize_e2>) == msize_of(bytes(<body_e2>))
<ds_e2>    ::= b'\x55'
<body_e2>  ::= <byte>* := make_lzma('run', 0x55)
<crc_e2>   ::= <byte>{4}
<dsize_e2> ::= <byte>{8}
<msize_e2> ::= <byte>{8}
