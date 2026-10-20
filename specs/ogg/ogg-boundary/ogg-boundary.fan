# Same as ogg, with values taken from the edges of what the format allows:
# 1, 2 or 255 channels, any sample rate and bitrate, the smallest and largest
# block sizes, all-ones framing bytes, granule position -1 and pages with no
# segment; after the Vorbis stream, up to two streams of bare pages (one page
# with both BOS and EOS set, or two or three pages), and a page whose only
# segment is 255 bytes long, a packet that never ends.
#
# TODO:
# * The Vorbis stream has no setup header and the other streams have no
#   codec, so no file decodes: they test the Ogg layer only.

# A Vorbis stream, up to two streams of bare pages, maybe the long page

<start> ::= <vorbis_stream> <generic_stream>{0,2} <solo_big>?

<generic_stream> ::= <lb_solo> | <lb_v2> | <lb_v3>

# Vorbis stream: identification header, comment header, audio, EOS, with
# one serial number and the sequence numbers 0 to 3

<vorbis_stream> ::= <page_vid> <page_vcomment> <page_vaudio> <page_veos>

# The serial number is a literal: an equality between pages, on a field that
# is also under each page's CRC, makes generation much slower. (The streams
# of bare pages below do tie their serial numbers with where constraints.)

# Vorbis identification header page (bos, sequence 0, granule 0)
<page_vid> ::= <capture_pattern> <stream_version> <header_type_bos> \
    <granule_zero8> <v_serial> <seq0> <ck_vid> <seg_vid>

# One segment of 30 bytes, as literals for the same reason
<seg_vid> ::= b'\x01' b'\x1e' <vorbis_id_body>

# 30-byte Vorbis I identification header. vorbis_version is the constant 0.
<vorbis_id_body> ::= b'\x01vorbis' <v_version> <v_channels> <v_srate> \
    <v_bitrate_max> <v_bitrate_nom> <v_bitrate_min> <v_blocksizes> <v_framing>

<v_version> ::= b'\x00\x00\x00\x00'
# channels: 1, 2 or 255
<v_channels> ::= b'\x01' | b'\x02' | b'\xff'
# sample rate: any 32-bit value, 0 included
<v_srate> ::= <byte>{4}
# bitrates: any signed 32-bit value
<v_bitrate_max> ::= <byte>{4}
<v_bitrate_nom> ::= <byte>{4}
<v_bitrate_min> ::= <byte>{4}
# block sizes (short exponent in the low nibble): 64/64, 64/2048, 64/8192,
# 2048/8192, 8192/8192
<v_blocksizes> ::= b'\x66' | b'\xb6' | b'\xd6' | b'\xdb' | b'\xdd'
# framing flag: 0x01, or all bits set
<v_framing> ::= b'\x01' | b'\xff'

<ck_vid> ::= <byte>{4}
where forall <p> in <page_vid>: <p>..<ck_vid> == ogg_crc32_bytes(zero_checksum(bytes(<p>)))

# Vorbis comment header page (interior, sequence 1, granule 0)
<page_vcomment> ::= <capture_pattern> <stream_version> <header_type_mid> \
    <granule_zero8> <v_serial> <seq1> <ck_vcomment> <seg_vcomment>

# One segment of 24 bytes (7 + 4 + 8 + 4 + 1)
<seg_vcomment> ::= b'\x01' b'\x18' <vorbis_comment_body>

# 0x03 "vorbis", an 8-byte vendor, no comments, framing flag
<vorbis_comment_body> ::= b'\x03vorbis' <vendor_len> <vendor_str> <n_comments> <v_framing2>
<vendor_len>  ::= b'\x08\x00\x00\x00'
<vendor_str>  ::= <byte>{8}
<n_comments>  ::= b'\x00\x00\x00\x00'
<v_framing2>  ::= b'\x01' | b'\xff'

<ck_vcomment> ::= <byte>{4}
where forall <p> in <page_vcomment>: <p>..<ck_vcomment> == ogg_crc32_bytes(zero_checksum(bytes(<p>)))

# Vorbis audio page (interior, sequence 2, granule normal or -1)
<page_vaudio> ::= <capture_pattern> <stream_version> <header_type_mid> \
    <granule_position> <v_serial> <seq2> <ck_vaudio> <segments_2>

<ck_vaudio> ::= <byte>{4}
where forall <p> in <page_vaudio>: <p>..<ck_vaudio> == ogg_crc32_bytes(zero_checksum(bytes(<p>)))

# Vorbis EOS page (sequence 3)
<page_veos> ::= <capture_pattern> <stream_version> <header_type_eos> \
    <granule_position> <v_serial> <seq3> <ck_veos> <segments_1>

<ck_veos> ::= <byte>{4}
where forall <p> in <page_veos>: <p>..<ck_veos> == ogg_crc32_bytes(zero_checksum(bytes(<p>)))

<v_serial> ::= b'\x2c\x01\x00\x00'
<seq0> ::= b'\x00\x00\x00\x00'
<seq1> ::= b'\x01\x00\x00\x00'
<seq2> ::= b'\x02\x00\x00\x00'
<seq3> ::= b'\x03\x00\x00\x00'
<granule_zero8> ::= b'\x00\x00\x00\x00\x00\x00\x00\x00'

# Streams of bare pages, with no codec: one page with BOS and EOS set, or two
# or three pages of 0 to 2 segments, with one serial number and consecutive
# sequence numbers

<lb_solo> ::= <page_solo>
<lb_v2>   ::= <page_bos> <page_eos>
<lb_v3>   ::= <page_bos> <page_mid_a> <page_eos>

where forall <s> in <lb_v2>:
    <s>.<page_eos>..<stream_serial_number> == bytes(<s>.<page_bos>..<stream_serial_number>)
where forall <s> in <lb_v2>:
    <s>.<page_eos>..<page_sequence_number> == uint32_le(int.from_bytes(bytes(<s>.<page_bos>..<page_seq_zero>), 'little') + 1)

where forall <s> in <lb_v3>:
    <s>.<page_mid_a>..<stream_serial_number> == bytes(<s>.<page_bos>..<stream_serial_number>)
where forall <s> in <lb_v3>:
    <s>.<page_eos>..<stream_serial_number> == bytes(<s>.<page_bos>..<stream_serial_number>)
where forall <s> in <lb_v3>:
    <s>.<page_mid_a>..<page_sequence_number> == uint32_le(int.from_bytes(bytes(<s>.<page_bos>..<page_seq_zero>), 'little') + 1)
where forall <s> in <lb_v3>:
    <s>.<page_eos>..<page_sequence_number> == uint32_le(int.from_bytes(bytes(<s>.<page_mid_a>..<page_sequence_number>), 'little') + 1)

<page_bos>   ::= <page_bos_0> | <page_bos_1> | <page_bos_2>
<page_mid_a> ::= <page_mid_a_0> | <page_mid_a_1> | <page_mid_a_2>
<page_eos>   ::= <page_eos_0> | <page_eos_1> | <page_eos_2>
<page_solo>  ::= <page_solo_0> | <page_solo_1> | <page_solo_2>

<page_bos_0> ::= <capture_pattern> <stream_version> <header_type_bos> <granule_position> <stream_serial_number> <page_seq_zero> <ck_bos_0> <segments_0>
<page_bos_1> ::= <capture_pattern> <stream_version> <header_type_bos> <granule_position> <stream_serial_number> <page_seq_zero> <ck_bos_1> <segments_1>
<page_bos_2> ::= <capture_pattern> <stream_version> <header_type_bos> <granule_position> <stream_serial_number> <page_seq_zero> <ck_bos_2> <segments_2>

<page_mid_a_0> ::= <capture_pattern> <stream_version> <header_type_mid> <granule_position> <stream_serial_number> <page_sequence_number> <ck_mid_a_0> <segments_0>
<page_mid_a_1> ::= <capture_pattern> <stream_version> <header_type_mid> <granule_position> <stream_serial_number> <page_sequence_number> <ck_mid_a_1> <segments_1>
<page_mid_a_2> ::= <capture_pattern> <stream_version> <header_type_mid> <granule_position> <stream_serial_number> <page_sequence_number> <ck_mid_a_2> <segments_2>

<page_eos_0> ::= <capture_pattern> <stream_version> <header_type_eos> <granule_position> <stream_serial_number> <page_sequence_number> <ck_eos_0> <segments_0>
<page_eos_1> ::= <capture_pattern> <stream_version> <header_type_eos> <granule_position> <stream_serial_number> <page_sequence_number> <ck_eos_1> <segments_1>
<page_eos_2> ::= <capture_pattern> <stream_version> <header_type_eos> <granule_position> <stream_serial_number> <page_sequence_number> <ck_eos_2> <segments_2>

<page_solo_0> ::= <capture_pattern> <stream_version> <header_type_solo> <granule_position> <stream_serial_number> <page_seq_zero> <ck_solo_0> <segments_0>
<page_solo_1> ::= <capture_pattern> <stream_version> <header_type_solo> <granule_position> <stream_serial_number> <page_seq_zero> <ck_solo_1> <segments_1>
<page_solo_2> ::= <capture_pattern> <stream_version> <header_type_solo> <granule_position> <stream_serial_number> <page_seq_zero> <ck_solo_2> <segments_2>

<ck_bos_0> ::= <byte>{4}
<ck_bos_1> ::= <byte>{4}
<ck_bos_2> ::= <byte>{4}
<ck_mid_a_0> ::= <byte>{4}
<ck_mid_a_1> ::= <byte>{4}
<ck_mid_a_2> ::= <byte>{4}
<ck_eos_0> ::= <byte>{4}
<ck_eos_1> ::= <byte>{4}
<ck_eos_2> ::= <byte>{4}
<ck_solo_0> ::= <byte>{4}
<ck_solo_1> ::= <byte>{4}
<ck_solo_2> ::= <byte>{4}

where forall <p> in <page_bos_0>:   <p>..<ck_bos_0>   == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_bos_1>:   <p>..<ck_bos_1>   == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_bos_2>:   <p>..<ck_bos_2>   == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_mid_a_0>: <p>..<ck_mid_a_0> == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_mid_a_1>: <p>..<ck_mid_a_1> == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_mid_a_2>: <p>..<ck_mid_a_2> == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_eos_0>:   <p>..<ck_eos_0>   == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_eos_1>:   <p>..<ck_eos_1>   == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_eos_2>:   <p>..<ck_eos_2>   == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_solo_0>:  <p>..<ck_solo_0>  == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_solo_1>:  <p>..<ck_solo_1>  == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_solo_2>:  <p>..<ck_solo_2>  == ogg_crc32_bytes(zero_checksum(bytes(<p>)))

# A page whose only segment is 255 bytes long: its packet goes on to a next
# page that never comes

<solo_big> ::= <capture_pattern> <stream_version> <header_type_solo> <granule_no_packet> <stream_serial_number> <page_seq_zero> <ck_big> <seg_big>
<seg_big>  ::= b'\x01' b'\xff' <big_body>
<big_body> ::= b'\x00'{255}
<ck_big>   ::= <byte>{4}
where forall <p> in <solo_big>: <p>..<ck_big> == ogg_crc32_bytes(zero_checksum(bytes(<p>)))

# Page header

<capture_pattern>  ::= b'OggS'
<stream_version>   ::= b'\x00'

# bit0=continued packet, bit1=bos, bit2=eos. bos/solo pages never continue a
# prior packet, so 0x02 / 0x06 are their only valid flags; interior and eos
# pages may carry a continued-packet tail (0x01 / 0x05).
<header_type_bos>  ::= b'\x02'
<header_type_mid>  ::= b'\x00' | b'\x01'
<header_type_eos>  ::= b'\x04' | b'\x05'
<header_type_solo> ::= b'\x06'

<stream_serial_number> ::= <byte>{4}
<page_seq_zero>        ::= b'\x00\x00\x00\x00'
<page_sequence_number> ::= <byte>{4}

# granule position: -1 (no packet ends on this page), or non-negative
<granule_position>  ::= <granule_no_packet> | <granule_normal>
<granule_no_packet> ::= b'\xff\xff\xff\xff\xff\xff\xff\xff'
<granule_normal>    ::= <byte>{7} <granule_top_byte>
<granule_top_byte>  ::= r'[\x00-\x7f]'

# Segment table, then the segments; each lacing value is the length of its
# segment, 0 included

<segments_0> ::= b'\x00'
<segments_1> ::= b'\x01' <lac_1> <seg_data_1>
<segments_2> ::= b'\x02' <lac_1> <lac_2> <seg_data_1> <seg_data_2>

<lac_1> ::= <byte>
<lac_2> ::= <byte>
<seg_data_1> ::= <byte>{lacing_value(<lac_1>)}
<seg_data_2> ::= <byte>{lacing_value(<lac_2>)}

def lacing_value(x) -> int:
    return bytes(x)[0]

def uint32_le(n: int) -> bytes:
    return n.to_bytes(4, 'little')

def zero_checksum(page_bytes: bytes) -> bytes:
    # page_checksum sits at byte offset 22 (4+1+1+8+4+4) for every page role.
    b = bytearray(page_bytes)
    b[22:26] = b'\x00\x00\x00\x00'
    return bytes(b)

_OGG_CRC_TABLE = None

def _ogg_crc_table():
    global _OGG_CRC_TABLE
    if _OGG_CRC_TABLE is None:
        table = []
        for i in range(256):
            r = i << 24
            for _ in range(8):
                if r & 0x80000000:
                    r = ((r << 1) ^ 0x04c11db7) & 0xffffffff
                else:
                    r = (r << 1) & 0xffffffff
            table.append(r)
        _OGG_CRC_TABLE = table
    return _OGG_CRC_TABLE

def ogg_crc32_bytes(data: bytes) -> bytes:
    table = _ogg_crc_table()
    crc = 0
    for c in data:
        crc = ((crc << 8) ^ table[((crc >> 24) & 0xff) ^ c]) & 0xffffffff
    return crc.to_bytes(4, 'little')
