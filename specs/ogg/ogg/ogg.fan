# Ogg Vorbis (RFC 3533, Vorbis I): one or two chained streams of four pages
# each: the identification header, the comment and setup headers, an audio
# page and an end-of-stream page. Serial and sequence numbers, the vendor
# length and the CRC-32 of every page are where constraints, and segment
# lengths follow their lacing values.
#
# TODO:
# * The setup header is 9 random bytes, not codebooks, so no Vorbis decoder
#   gets past it: the files test the Ogg layer and the first two headers.

# One or two chained Vorbis streams

<start> ::= <vorbis_stream>{1,2}

# Four pages per stream, numbered 0 to 3, all with the serial number of the
# first (BOS) page

<vorbis_stream> ::= <page_id> <page_head> <page_audio> <page_eos>

where forall <s> in <vorbis_stream>:
    <s>.<page_head>..<stream_serial_number>  == bytes(<s>.<page_id>..<stream_serial_number>)
where forall <s> in <vorbis_stream>:
    <s>.<page_audio>..<stream_serial_number> == bytes(<s>.<page_id>..<stream_serial_number>)
where forall <s> in <vorbis_stream>:
    <s>.<page_eos>..<stream_serial_number>   == bytes(<s>.<page_id>..<stream_serial_number>)
where forall <s> in <vorbis_stream>:
    <s>.<page_head>..<page_sequence_number>  == uint32_le(1)
where forall <s> in <vorbis_stream>:
    <s>.<page_audio>..<page_sequence_number> == uint32_le(2)
where forall <s> in <vorbis_stream>:
    <s>.<page_eos>..<page_sequence_number>   == uint32_le(3)

# Audio pages have 1 to 3 segments, the EOS page 0 to 3. Each number of
# segments is a production of its own, so that every CRC constraint is on a
# page of one fixed shape.

<page_audio> ::= <page_audio_1> | <page_audio_2> | <page_audio_3>
<page_eos>   ::= <page_eos_0> | <page_eos_1> | <page_eos_2> | <page_eos_3>

# BOS page: the Vorbis identification header, one 30-byte segment.
<page_id> ::= <capture_pattern> <stream_version> <header_type_bos> <granule_zero> \
              <stream_serial_number> <page_seq_zero> <page_checksum_id> \
              b'\x01' <lac_id> <vorbis_id_header>

# Second page: comment header packet then setup header packet, two segments.
<page_head> ::= <capture_pattern> <stream_version> <header_type_fresh> <granule_zero> \
                <stream_serial_number> <page_sequence_number> <page_checksum_head> \
                b'\x02' <lac_comment> <lac_setup> <vorbis_comment_header> <vorbis_setup_header>

<page_audio_1> ::= <capture_pattern> <stream_version> <header_type_audio> <granule_normal> \
                   <stream_serial_number> <page_sequence_number> <page_checksum_audio_1> <segments_1>
<page_audio_2> ::= <capture_pattern> <stream_version> <header_type_audio> <granule_normal> \
                   <stream_serial_number> <page_sequence_number> <page_checksum_audio_2> <segments_2>
<page_audio_3> ::= <capture_pattern> <stream_version> <header_type_audio> <granule_normal> \
                   <stream_serial_number> <page_sequence_number> <page_checksum_audio_3> <segments_3>

<page_eos_0> ::= <capture_pattern> <stream_version> <header_type_eos> <granule_normal> \
                 <stream_serial_number> <page_sequence_number> <page_checksum_eos_0> <segments_0>
<page_eos_1> ::= <capture_pattern> <stream_version> <header_type_eos> <granule_normal> \
                 <stream_serial_number> <page_sequence_number> <page_checksum_eos_1> <segments_1>
<page_eos_2> ::= <capture_pattern> <stream_version> <header_type_eos> <granule_normal> \
                 <stream_serial_number> <page_sequence_number> <page_checksum_eos_2> <segments_2>
<page_eos_3> ::= <capture_pattern> <stream_version> <header_type_eos> <granule_normal> \
                 <stream_serial_number> <page_sequence_number> <page_checksum_eos_3> <segments_3>

# Page header

<capture_pattern> ::= b'OggS'
<stream_version>  ::= b'\x00'

# header_type bits: bit0=continued packet, bit1=bos, bit2=eos.
# BOS page = 0x02; header/audio pages either start fresh (0x00) or continue a
# packet from the previous page (0x01); EOS page = 0x04 / 0x05.
<header_type_bos>   ::= b'\x02'
<header_type_fresh> ::= b'\x00'
<header_type_audio> ::= b'\x00' | b'\x01'
<header_type_eos>   ::= b'\x04' | b'\x05'

<stream_serial_number> ::= <byte>{4}

# The BOS page is number 0; the others are set by the constraints above
<page_seq_zero>        ::= b'\x00\x00\x00\x00'
<page_sequence_number> ::= <byte>{4}

# Granule position: 0 on header pages, a non-negative int64 on the others
<granule_zero>     ::= b'\x00\x00\x00\x00\x00\x00\x00\x00'
<granule_normal>   ::= <byte>{7} <granule_top_byte>
<granule_top_byte> ::= r'[\x00-\x7f]'

# One checksum field per page production, each with its CRC constraint
<page_checksum_id>      ::= <byte>{4}
<page_checksum_head>    ::= <byte>{4}
<page_checksum_audio_1> ::= <byte>{4}
<page_checksum_audio_2> ::= <byte>{4}
<page_checksum_audio_3> ::= <byte>{4}
<page_checksum_eos_0>   ::= <byte>{4}
<page_checksum_eos_1>   ::= <byte>{4}
<page_checksum_eos_2>   ::= <byte>{4}
<page_checksum_eos_3>   ::= <byte>{4}

where forall <p> in <page_id>:      <p>..<page_checksum_id>      == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_head>:    <p>..<page_checksum_head>    == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_audio_1>: <p>..<page_checksum_audio_1> == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_audio_2>: <p>..<page_checksum_audio_2> == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_audio_3>: <p>..<page_checksum_audio_3> == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_eos_0>:   <p>..<page_checksum_eos_0>   == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_eos_1>:   <p>..<page_checksum_eos_1>   == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_eos_2>:   <p>..<page_checksum_eos_2>   == ogg_crc32_bytes(zero_checksum(bytes(<p>)))
where forall <p> in <page_eos_3>:   <p>..<page_checksum_eos_3>   == ogg_crc32_bytes(zero_checksum(bytes(<p>)))

# Segment table, then the segments. On audio and EOS pages a lacing value
# is the length of its segment; header pages have fixed lacing values.

<lac_id>      ::= b'\x1e'   # identification header = 30 bytes
<lac_comment> ::= b'\x1f'   # comment header = 7+4+15+4+1 = 31 bytes
<lac_setup>   ::= b'\x10'   # opaque setup packet = 16 bytes

<segments_0> ::= b'\x00'
<segments_1> ::= b'\x01' <lac_1> <seg_data_1>
<segments_2> ::= b'\x02' <lac_1> <lac_2> <seg_data_1> <seg_data_2>
<segments_3> ::= b'\x03' <lac_1> <lac_2> <lac_3> <seg_data_1> <seg_data_2> <seg_data_3>

<lac_1> ::= <byte>
<lac_2> ::= <byte>
<lac_3> ::= <byte>
<seg_data_1> ::= <byte>{lacing_value(<lac_1>)}
<seg_data_2> ::= <byte>{lacing_value(<lac_2>)}
<seg_data_3> ::= <byte>{lacing_value(<lac_3>)}

# Identification header (Vorbis I, 4.2.2), 30 bytes: 0x01 "vorbis", version
# 0, channels, sample rate, maximum, nominal and minimum bitrate, block
# sizes, framing flag
<vorbis_id_header> ::= b'\x01vorbis' <vi_version> <vi_channels> <vi_sample_rate> \
                       <vi_bitrate_max> <vi_bitrate_nominal> <vi_bitrate_min> \
                       <vi_blocksize> <vi_framing>
<vi_version>       ::= b'\x00\x00\x00\x00'
<vi_channels>      ::= b'\x01' | b'\x02'
<vi_sample_rate>   ::= b'\x44\xac\x00\x00' | b'\x80\xbb\x00\x00' | b'\x22\x56\x00\x00'
<vi_bitrate_max>   ::= <byte>{4}
<vi_bitrate_nominal> ::= <byte>{4}
<vi_bitrate_min>   ::= <byte>{4}
# Block sizes: the short exponent in the low nibble, the long one in the
# high nibble, each 6..13, short <= long
<vi_blocksize>     ::= b'\x88' | b'\x99' | b'\xb8' | b'\xbb'
<vi_framing>       ::= b'\x01'

# Comment header (4.2.3), 31 bytes: 0x03 "vorbis", vendor length and vendor,
# no comments, framing flag
<vorbis_comment_header> ::= b'\x03vorbis' <cmt_vendor_length> <cmt_vendor> \
                            <cmt_user_count> <cmt_framing>
<cmt_vendor_length> ::= <byte>{4}
<cmt_vendor>        ::= b'Fandango-Vorbis'
<cmt_user_count>    ::= b'\x00\x00\x00\x00'
<cmt_framing>       ::= b'\x01'

where forall <c> in <vorbis_comment_header>:
    <c>.<cmt_vendor_length> == uint32_le(len(<c>.<cmt_vendor>))

# Setup header (4.2.4): 0x05 "vorbis", then 9 random bytes where the
# codebooks, floors, residues, mappings and modes would be
<vorbis_setup_header> ::= b'\x05vorbis' <setup_payload>
<setup_payload>       ::= <byte>{9}

# Helpers

def lacing_value(x) -> int:
    return bytes(x)[0]

def uint32_le(n: int) -> bytes:
    return n.to_bytes(4, 'little')

def zero_checksum(page_bytes: bytes) -> bytes:
    # page_checksum sits at byte offset 22 (4+1+1+8+4+4) and is 4 bytes long.
    b = bytearray(page_bytes)
    b[22:26] = b'\x00\x00\x00\x00'
    return bytes(b)

_OGG_CRC_TABLE = None

def _ogg_crc_table():
    # 256-entry table for the (unreflected, poly 0x04c11db7, init 0, no
    # xorout) CRC-32 variant libogg uses for Ogg page checksums.
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
