# Snappy streams in the framing format (.sz): the stream identifier, then
# chunks of Snappy-compressed data, of uncompressed data, of padding, and a
# reserved one that readers skip, each with its length and (for data) the
# masked CRC-32C of the data. Half the streams are made by the Snappy
# compressor (Python package python-snappy) from data that Fandango draws,
# one to three chunks of it. In the others the compressed blocks are written
# out here: a literal, a literal with an extra length byte, and copies with
# 1-, 2- and 4-byte offsets, of literal bytes that Fandango draws; where
# constraints tie each length to what it counts, and each CRC to the data,
# which the block decoder here gets from a compressed block.
#
# TODO:
# * The blocks written out here always have the same shape: only the literal
#   bytes change.

import snappy


# The masked CRC-32C of the data: CRC-32C (Castagnoli), rotated right by 15
# bits, plus 0xa282ead8
def sz_crc(data):
    data = bytes(data)
    crc = 0xFFFFFFFF
    for b in data:
        crc = crc ^ b
        j = 0
        while j < 8:
            if crc & 1:
                crc = (crc >> 1) ^ 0x82F63B78
            else:
                crc = crc >> 1
            j = j + 1
    crc = crc ^ 0xFFFFFFFF
    masked = (((crc >> 15) | (crc << 17)) & 0xFFFFFFFF) + 0xa282ead8
    return (masked & 0xFFFFFFFF).to_bytes(4, "little")


# What a Snappy block decompresses to: after the length (a varint), each
# element is a literal or a copy, by the low two bits of its tag
def sz_decompress(block):
    data = bytes(block)
    i = 0
    shift = 0
    length = 0
    while True:
        b = data[i]
        i = i + 1
        length = length | ((b & 0x7F) << shift)
        shift = shift + 7
        if not (b & 0x80):
            break
    out = bytearray()
    n = len(data)
    while i < n:
        tag = data[i]
        i = i + 1
        t = tag & 0x03
        if t == 0:
            ln = tag >> 2
            if ln < 60:
                litlen = ln + 1
            else:
                extra = ln - 59
                litlen = 0
                k = 0
                while k < extra:
                    litlen = litlen | (data[i] << (8 * k))
                    i = i + 1
                    k = k + 1
                litlen = litlen + 1
            out.extend(data[i:i + litlen])
            i = i + litlen
        elif t == 1:
            lc = ((tag >> 2) & 0x07) + 4
            off = ((tag >> 5) << 8) | data[i]
            i = i + 1
            c = 0
            while c < lc:
                out.append(out[len(out) - off])
                c = c + 1
        elif t == 2:
            lc = (tag >> 2) + 1
            off = data[i] | (data[i + 1] << 8)
            i = i + 2
            c = 0
            while c < lc:
                out.append(out[len(out) - off])
                c = c + 1
        else:
            lc = (tag >> 2) + 1
            off = (data[i] | (data[i + 1] << 8) |
                   (data[i + 2] << 16) | (data[i + 3] << 24))
            i = i + 4
            c = 0
            while c < lc:
                out.append(out[len(out) - off])
                c = c + 1
    return bytes(out)


def le3(n):
    return (n & 0xFFFFFF).to_bytes(3, "little")


<start> ::= <f_snappy> | <f_written>
<f_written> ::= <f_lit> | <f_lit_ext> | <f_copy1> | <f_copy2> | <f_copy4> \
              | <f_uncompressed> | <f_padding> | <f_skippable> | <f_multi>

<byte> ::= rb'[\x00-\xff]'

# The stream identifier: type 0xff, length 6, "sNaPpY"
<stream_id> ::= b'\xff\x06\x00\x00sNaPpY'


# A compressed chunk: 32 literal bytes
<f_lit> ::= <stream_id> <ch_lit>
<ch_lit> ::= b'\x00' <clen1> <crc1> <block1>
    where bytes(<clen1>) == le3(4 + len(bytes(<block1>)))
    where bytes(<crc1>) == sz_crc(sz_decompress(bytes(<block1>)))
<clen1> ::= <byte>{3}
<crc1> ::= <byte>{4}
<block1> ::= b'\x20\x7c' <lit1>
<lit1> ::= <byte>{32}


# 100 literal bytes, the length in an extra byte (tag 0xf0)
<f_lit_ext> ::= <stream_id> <ch_ext>
<ch_ext> ::= b'\x00' <clen2> <crc2> <block2>
    where bytes(<clen2>) == le3(4 + len(bytes(<block2>)))
    where bytes(<crc2>) == sz_crc(sz_decompress(bytes(<block2>)))
<clen2> ::= <byte>{3}
<crc2> ::= <byte>{4}
<block2> ::= b'\x64\xf0\x63' <lit2>
<lit2> ::= <byte>{100}


# Four literal bytes, and a copy of them with a 1-byte offset
<f_copy1> ::= <stream_id> <ch_c1>
<ch_c1> ::= b'\x00' <clen3> <crc3> <block3>
    where bytes(<clen3>) == le3(4 + len(bytes(<block3>)))
    where bytes(<crc3>) == sz_crc(sz_decompress(bytes(<block3>)))
<clen3> ::= <byte>{3}
<crc3> ::= <byte>{4}
<block3> ::= b'\x08\x0c' <lit3> b'\x01\x04'
<lit3> ::= <byte>{4}


# Eight literal bytes, and a copy of them with a 2-byte offset
<f_copy2> ::= <stream_id> <ch_c2>
<ch_c2> ::= b'\x00' <clen4> <crc4> <block4>
    where bytes(<clen4>) == le3(4 + len(bytes(<block4>)))
    where bytes(<crc4>) == sz_crc(sz_decompress(bytes(<block4>)))
<clen4> ::= <byte>{3}
<crc4> ::= <byte>{4}
<block4> ::= b'\x10\x1c' <lit4> b'\x1e\x08\x00'
<lit4> ::= <byte>{8}


# 16 literal bytes, and a copy of them with a 4-byte offset
<f_copy4> ::= <stream_id> <ch_c4>
<ch_c4> ::= b'\x00' <clen5> <crc5> <block5>
    where bytes(<clen5>) == le3(4 + len(bytes(<block5>)))
    where bytes(<crc5>) == sz_crc(sz_decompress(bytes(<block5>)))
<clen5> ::= <byte>{3}
<crc5> ::= <byte>{4}
<block5> ::= b'\x20\x3c' <lit5> b'\x3f\x10\x00\x00\x00'
<lit5> ::= <byte>{16}


# An uncompressed chunk (0x01): the CRC, then the data
<f_uncompressed> ::= <stream_id> <ch_unc>
<ch_unc> ::= b'\x01' <clen6> <crc6> <raw6>
    where bytes(<clen6>) == le3(4 + len(bytes(<raw6>)))
    where bytes(<crc6>) == sz_crc(bytes(<raw6>))
<clen6> ::= <byte>{3}
<crc6> ::= <byte>{4}
<raw6> ::= <byte>{48}


# A padding chunk (0xfe), then a compressed chunk
<f_padding> ::= <stream_id> <ch_pad> <ch_lit7>
<ch_pad> ::= b'\xfe' <clen7> <pad7>
    where bytes(<clen7>) == le3(len(bytes(<pad7>)))
<clen7> ::= <byte>{3}
<pad7> ::= <byte>{16}
<ch_lit7> ::= b'\x00' <clen7b> <crc7> <block7>
    where bytes(<clen7b>) == le3(4 + len(bytes(<block7>)))
    where bytes(<crc7>) == sz_crc(sz_decompress(bytes(<block7>)))
<clen7b> ::= <byte>{3}
<crc7> ::= <byte>{4}
<block7> ::= b'\x20\x7c' <lit7>
<lit7> ::= <byte>{32}


# A reserved chunk that readers skip (0x80), then an uncompressed one
<f_skippable> ::= <stream_id> <ch_skip> <ch_unc8>
<ch_skip> ::= b'\x80' <clen8> <skip8>
    where bytes(<clen8>) == le3(len(bytes(<skip8>)))
<clen8> ::= <byte>{3}
<skip8> ::= <byte>{24}
<ch_unc8> ::= b'\x01' <clen8b> <crc8> <raw8>
    where bytes(<clen8b>) == le3(4 + len(bytes(<raw8>)))
    where bytes(<crc8>) == sz_crc(bytes(<raw8>))
<clen8b> ::= <byte>{3}
<crc8> ::= <byte>{4}
<raw8> ::= <byte>{40}


# Uncompressed, compressed, and padding chunks
<f_multi> ::= <stream_id> <ch_uncA> <ch_litA> <ch_padA>
<ch_uncA> ::= b'\x01' <clenA> <crcA> <rawA>
    where bytes(<clenA>) == le3(4 + len(bytes(<rawA>)))
    where bytes(<crcA>) == sz_crc(bytes(<rawA>))
<clenA> ::= <byte>{3}
<crcA> ::= <byte>{4}
<rawA> ::= <byte>{24}
<ch_litA> ::= b'\x00' <clenB> <crcB> <blockB>
    where bytes(<clenB>) == le3(4 + len(bytes(<blockB>)))
    where bytes(<crcB>) == sz_crc(sz_decompress(bytes(<blockB>)))
<clenB> ::= <byte>{3}
<crcB> ::= <byte>{4}
<blockB> ::= b'\x10\x3c' <litB>
<litB> ::= <byte>{16}
<ch_padA> ::= b'\xfe' <clenC> <padC>
    where bytes(<clenC>) == le3(len(bytes(<padC>)))
<clenC> ::= <byte>{3}
<padC> ::= <byte>{8}


# Chunks from the compressor: the data, as letters and as it is, repeated up
# to 16 times, in one to three compressed chunks (an uncompressed one when
# compressing does not make it smaller)
def snappy_stream(params):
    raw = bytes(_find(params, '<sz_data>'))
    letters = bytes(b"etaoin shrdlu"[x % 13] for x in raw)
    data = (letters + raw) * (1 + bytes(_find(params, '<sz_repeat>'))[0])
    parts = bytes(_find(params, '<sz_parts>'))[0]
    step = max(1, -(-len(data) // parts))
    out = b'\xff\x06\x00\x00sNaPpY'
    for at in range(0, len(data), step):
        part = data[at:at + step]
        packed = snappy.compress(part)
        if len(packed) < len(part):
            out += b'\x00' + le3(4 + len(packed)) + sz_crc(part) + packed
        else:
            out += b'\x01' + le3(4 + len(part)) + sz_crc(part) + part
    return out


def _find(node, name):
    """The first symbol called `name` under `node` (or `node` itself), or None."""
    if str(node.symbol) == name:
        return node
    for c in node.children:
        if c.is_non_terminal:
            found = _find(c, name)
            if found is not None:
                return found
    return None


# A stream from the compressor, one terminal (made from the draft <sz_params>)
<f_snappy> ::= rb'(?s).+' := snappy_stream(<sz_params>)
<sz_params> ::= <sz_parts> <sz_repeat> <sz_data>
<sz_parts> ::= rb'[\x01-\x03]'
<sz_repeat> ::= rb'[\x00-\x0f]'
<sz_data> ::= rb'[\x00-\xff]{1,256}'
