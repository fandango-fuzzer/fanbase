# bzip2 files at the edges of what the format allows: every block size from
# 1 to 9, a stream with no blocks at all (empty data), long runs of one byte,
# all 256 byte values (the largest symbol map), random data that does not
# compress, a stream of more than one block, and two streams one after the
# other with different block sizes. The blocks come from Python's bz2 module
# (libbzip2), and where constraints decompress every stream.
#
# TODO:
# * The data is drawn with `random`, not by Fandango.
# * Each block size goes with one kind of data, always the same.

import bz2
import random


def _rand_bytes(lo, hi):
    n = random.randint(lo, hi)
    if n <= 0:
        return b''
    return bytes(random.choices(range(256), k=n))


# The blocks and end-of-stream marker of a stream at this block size, without
# the four-byte header: data of the given shape, compressed.
def gen_tail(level, shape):
    if shape == 'small':
        data = _rand_bytes(1, 60)
    elif shape == 'runs':
        data = (bytes([random.randint(0, 255)]) * random.randint(8, 500)) + _rand_bytes(0, 40)
    elif shape == 'alpha':
        data = bytes(range(256)) * random.randint(1, 4)
    elif shape == 'inc':
        data = _rand_bytes(200, 900)
    elif shape == 'empty':
        data = b''
    elif shape == 'multiblock':
        # 102,400 bytes without runs: more than one 100 kB block (runs would
        # shrink in bzip2's first run-length stage and fit in one)
        data = (bytes(range(256)) * 400) + _rand_bytes(0, 60)
    else:
        data = _rand_bytes(1, 100)
    return bz2.compress(data, level)[4:]


# Whether libbzip2 decompresses the whole stream: every block CRC and the
# combined CRC match, and the blocks fit the block size in the header.
def dec_ok(full):
    try:
        bz2.decompress(bytes(full))
        return True
    except Exception:
        return False


<start> ::= <bz2_file>

<bz2_file> ::= <stream> | <multi_stream>

<stream> ::= <s_l1> | <s_l2> | <s_l3> | <s_l4> | <s_l5> \
           | <s_l6> | <s_l7> | <s_l8> | <s_l9> | <s_empty>

# One stream per block size, 100 kB to 900 kB
<s_l1> ::= b'BZh1' <t_l1>
<t_l1> ::= <byte>* := gen_tail(1, 'multiblock')

<s_l2> ::= b'BZh2' <t_l2>
<t_l2> ::= <byte>* := gen_tail(2, 'runs')

<s_l3> ::= b'BZh3' <t_l3>
<t_l3> ::= <byte>* := gen_tail(3, 'alpha')

<s_l4> ::= b'BZh4' <t_l4>
<t_l4> ::= <byte>* := gen_tail(4, 'inc')

<s_l5> ::= b'BZh5' <t_l5>
<t_l5> ::= <byte>* := gen_tail(5, 'small')

<s_l6> ::= b'BZh6' <t_l6>
<t_l6> ::= <byte>* := gen_tail(6, 'alpha')

<s_l7> ::= b'BZh7' <t_l7>
<t_l7> ::= <byte>* := gen_tail(7, 'runs')

<s_l8> ::= b'BZh8' <t_l8>
<t_l8> ::= <byte>* := gen_tail(8, 'inc')

<s_l9> ::= b'BZh9' <t_l9>
<t_l9> ::= <byte>* := gen_tail(9, 'small')

# No blocks: the header, the end-of-stream marker and a combined CRC of 0
<s_empty> ::= b'BZh9' <t_empty>
<t_empty> ::= <byte>* := gen_tail(9, 'empty')

# Two streams, the second with another block size
<multi_stream> ::= b'BZh9' <t_ma> b'BZh1' <t_mb>
<t_ma> ::= <byte>* := gen_tail(9, 'alpha')
<t_mb> ::= <byte>* := gen_tail(1, 'runs')

where dec_ok(b'BZh1' + bytes(<t_l1>))
where dec_ok(b'BZh2' + bytes(<t_l2>))
where dec_ok(b'BZh3' + bytes(<t_l3>))
where dec_ok(b'BZh4' + bytes(<t_l4>))
where dec_ok(b'BZh5' + bytes(<t_l5>))
where dec_ok(b'BZh6' + bytes(<t_l6>))
where dec_ok(b'BZh7' + bytes(<t_l7>))
where dec_ok(b'BZh8' + bytes(<t_l8>))
where dec_ok(b'BZh9' + bytes(<t_l9>))
where dec_ok(b'BZh9' + bytes(<t_empty>))
where dec_ok(b'BZh9' + bytes(<t_ma>) + b'BZh1' + bytes(<t_mb>))
