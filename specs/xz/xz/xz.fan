# .xz files: a stream of one to three blocks, then the Index and the stream
# footer. A block is LZMA2, or Delta (a distance of 1 to 256) and LZMA2, with
# or without the compressed and uncompressed sizes in its header, with any of
# the LZMA2 dictionary sizes 4 KiB to 4 MiB, and holds data that Fandango
# draws: some bytes, repeated up to 16 times, or none. The check of every
# block is of one kind, the one the stream flags name: none, CRC-32, CRC-64
# or SHA-256.
#
# Fandango draws the stream as a draft (<xz_stream>), and xz_file() makes the
# file from it: it compresses each block with Python's lzma module and writes
# the CRC-32s, the sizes, the Index records and the backward size, so that
# they all agree with the blocks of the same file.
#
# TODO:
# * xz_file() also knows what only xz-boundary draws: BCJ filters, padded
#   block headers, data that does not compress, LZMA2 data in more than one
#   chunk, streams of no blocks, and more than one stream.

import hashlib
import lzma
import struct
import zlib


# A variable-length integer: seven bits a byte, the lowest first, the top bit
# set on every byte but the last
def _vli(n):
    out = bytearray()
    while n >= 0x80:
        out.append((n & 0x7f) | 0x80)
        n >>= 7
    out.append(n & 0x7f)
    return bytes(out)


_CRC64_TAB = []

# CRC-64 (ECMA-182), as xz checks with it
def _crc64(data):
    if not _CRC64_TAB:
        poly = 0xC96C5795D7870F42
        for i in range(256):
            c = i
            for _ in range(8):
                c = (c >> 1) ^ (poly if (c & 1) else 0)
            _CRC64_TAB.append(c)
    crc = 0xFFFFFFFFFFFFFFFF
    for b in data:
        crc = _CRC64_TAB[(crc ^ b) & 0xff] ^ (crc >> 8)
    return crc ^ 0xFFFFFFFFFFFFFFFF


def _crc32le(data):
    return struct.pack('<I', zlib.crc32(data) & 0xFFFFFFFF)


# The check of a block's data: none (0), CRC-32 (1), CRC-64 (4), SHA-256 (10)
def _check(cid, data):
    if cid == 1:
        return _crc32le(data)
    if cid == 4:
        return struct.pack('<Q', _crc64(data))
    if cid == 10:
        return hashlib.sha256(data).digest()
    return b''


# The dictionary size that an LZMA2 property byte says
def _dict_size(prop):
    return (2 | (prop & 1)) << (prop // 2 + 11)


# The BCJ filters: xz's filter ID and Python's
_BCJ = {0x04: lzma.FILTER_X86, 0x05: lzma.FILTER_POWERPC, 0x06: lzma.FILTER_IA64,
        0x07: lzma.FILTER_ARM, 0x08: lzma.FILTER_ARMTHUMB, 0x09: lzma.FILTER_SPARC}


def _kids(node):
    return [c for c in node.children if c.is_non_terminal]


def _find(node, name):
    """The first symbol called `name` under `node` (or `node` itself), or None."""
    if str(node.symbol) == name:
        return node
    for c in _kids(node):
        found = _find(c, name)
        if found is not None:
            return found
    return None


def _all(node, name):
    """Every symbol called `name` under `node`, in file order."""
    if str(node.symbol) == name:
        return [node]
    found = []
    for c in _kids(node):
        found += _all(c, name)
    return found


def _parts(node, names):
    """The symbols under `node` called one of `names`, in file order (not
    looking inside them)."""
    if str(node.symbol) in names:
        return [node]
    found = []
    for c in _kids(node):
        found += _parts(c, names)
    return found


# The data of a block: <data> repeated, or 4,096 bytes that do not compress,
# made from <noise> (LZMA2 stores them as they are, in an uncompressed chunk)
def _data(node):
    noise = _find(node, '<noise>')
    if noise is None:
        return bytes(_find(node, '<data>')) * (1 + bytes(_find(node, '<repeat>'))[0])
    seed, out = bytes(noise), b''
    while len(out) < 4096:
        out += hashlib.sha256(seed + len(out).to_bytes(4, 'little')).digest()
    return out


# LZMA2 data written here, in uncompressed chunks: as many as <chunks> says
# (2 to 4), the first resetting the dictionary, then the end marker
def _chunked(data, chunks):
    n = bytes(chunks)[0]
    step = max(1, -(-len(data) // n))
    out = b''
    for k, at in enumerate(range(0, len(data), step)):
        part = data[at:at + step]
        out += bytes([1 if k == 0 else 2]) + (len(part) - 1).to_bytes(2, 'big') + part
    return out + b'\x00'


# One block: its header (size, flags, the sizes if asked for, the filter
# flags, padding, CRC-32), the compressed data, padding to four bytes, and
# the check. Returns the block, its unpadded size and its data's size.
def _block(node, cid):
    data = _data(node)
    prop = bytes(_find(node, '<dict_prop>'))[0]
    chain, flags = [], b''
    bcj = _find(node, '<bcj>')
    if bcj is not None:
        fid = bytes(_find(bcj, '<bcj_id>'))[0]
        chain.append({'id': _BCJ[fid]})
        flags += _vli(fid) + _vli(0)
    delta = _find(node, '<delta>')
    if delta is not None:
        dist = bytes(_find(delta, '<delta_dist>'))[0] + 1
        chain.append({'id': lzma.FILTER_DELTA, 'dist': dist})
        flags += _vli(0x03) + _vli(1) + bytes([dist - 1])
    # The compressor needs no more than 1 MiB for this little data, and a
    # stream made with a smaller dictionary decodes with the larger one the
    # header says (a large one is slow to set up, every time)
    chain.append({'id': lzma.FILTER_LZMA2, 'dict_size': min(_dict_size(prop), 1 << 20)})
    flags += _vli(0x21) + _vli(1) + bytes([prop])
    chunks = _find(node, '<chunks>')
    if chunks is not None and len(chain) == 1:
        packed = _chunked(data, chunks)
    else:
        packed = lzma.compress(data, format=lzma.FORMAT_RAW, filters=chain)
    block_flags, sizes = len(chain) - 1, b''
    if _find(node, '<sizes>') is not None:
        block_flags |= 0x40 | 0x80
        sizes = _vli(len(packed)) + _vli(len(data))
    body = bytes([block_flags]) + sizes + flags
    size = 1 + len(body) + 4
    size += (-size) % 4
    words = _find(node, '<header_words>')
    if words is not None:
        size += 4 * bytes(words)[0]
    header = bytes([size // 4 - 1]) + body + b'\x00' * (size - 1 - len(body) - 4)
    header += _crc32le(header)
    check = _check(cid, data)
    block = header + packed + b'\x00' * ((-len(packed)) % 4) + check
    return block, len(header) + len(packed) + len(check), len(data)


# One stream: header (magic, flags, CRC-32), the blocks, the Index (one record
# per block: unpadded size and data size) and the footer (CRC-32, backward
# size, flags, "YZ")
def _stream(node):
    cid = bytes(_find(node, '<check_id>'))[0]
    flags = bytes([0x00, cid])
    out = b'\xfd7zXZ\x00' + flags + _crc32le(flags)
    records = []
    for b in _all(node, '<block>'):
        block, unpadded, size = _block(b, cid)
        out += block
        records.append((unpadded, size))
    index = b'\x00' + _vli(len(records))
    for unpadded, size in records:
        index += _vli(unpadded) + _vli(size)
    index += b'\x00' * ((-len(index)) % 4)
    index += _crc32le(index)
    backward = struct.pack('<I', len(index) // 4 - 1) + flags
    return out + index + _crc32le(backward) + backward + b'YZ'


# The file: every stream, each one after the stream padding (zero bytes, a
# multiple of four) that comes before it
def xz_file(streams):
    out = b''
    for part in _parts(streams, ('<stream>', '<stream_padding>')):
        if str(part.symbol) == '<stream>':
            out += _stream(part)
        else:
            out += bytes(part)
    return out


<start> ::= <xz>
<xz> ::= <xz_file> := xz_file(<streams>)
<xz_file> ::= rb'(?s).+'

# The draft: what xz_file() makes the file from
<streams> ::= <stream>
<stream> ::= <check_id> <block>{1,3}

# None, CRC-32, CRC-64, SHA-256
<check_id> ::= b'\x00' | b'\x01' | b'\x04' | b'\x0a'

<block> ::= <filters> <sizes>? <dict_prop> <repeat> <data>

# LZMA2 alone, or Delta before it
<filters> ::= <lzma2> | <delta> <lzma2>
<lzma2> ::= b'L'
<delta> ::= b'D' <delta_dist>
# The distance less one
<delta_dist> ::= <byte>

# Whether the block header gives the compressed and the uncompressed size
<sizes> ::= b'S'

# The dictionary size: 4 KiB (0) to 4 MiB (20)
<dict_prop> ::= rb'[\x00-\x14]'

# The data is <data>, repeated (one more time than <repeat> says)
<repeat> ::= rb'[\x00-\x0f]'
<data> ::= rb'[\x00-\xff]{0,64}'
