# Same as flac, with values taken from the edges of what the format allows:
# block sizes 16 and 65535, an unknown and the largest frame size, total
# samples unknown, placeholder seek points, a 128-character catalog number,
# the CD flag, picture type 0, and PADDING as the last block.
#
# TODO:
# * The picture is a few random bytes said to be PNG. FFmpeg decodes it as
#   a cover and rejects the file; flac and libsndfile do not look at it.

<start> ::= <flac_stream>

<flac_stream> ::= b'fLaC' <metadata_section> <frames>

# One block of each type: STREAMINFO first, PADDING last, the only one with
# the last-block flag
<metadata_section> ::= <streaminfo_block> <application_block> \
                       <seektable_block> <vorbis_comment_block> \
                       <cuesheet_block> <picture_block> \
                       <padding_block_last>

# STREAMINFO (type 0): block sizes (u16 each), frame sizes (u24 each), 64
# bits of sample rate (20), channels - 1 (3), bits per sample - 1 (5) and
# total samples (36), then the MD5
<streaminfo_block> ::= b'\x00' b'\x00\x00\x22' <streaminfo_body>
<streaminfo_body> ::= <min_blocksize> <max_blocksize> \
                      <min_framesize> <max_framesize> \
                      <si_packed> <md5>
<min_blocksize> ::= b'\x00\x10'                 # 16 = minimum legal blocksize
<max_blocksize> ::= b'\xff\xff'                 # 65535 = maximum blocksize
<min_framesize> ::= b'\x00\x00\x00'             # 0 = unknown
<max_framesize> ::= b'\xff\xff\xff'             # 16777215 = max 24-bit
# packed 64 bits: rate=44100(0x0AC44), chan=1(000), bps=8(00111), total=0
<si_packed> ::= b'\x0a\xc4\x40\x70\x00\x00\x00\x00'
<md5> ::= b'\x00' {16}

# APPLICATION (type 2): a 4-byte id and its data
<application_block> ::= b'\x02' <app_len> <application_body>
<application_body> ::= <app_id> <app_data>
<app_id> ::= b'RIFF'
<app_data> ::= rb'[\x00-\xff]' {0,64}
<app_len> ::= <b3>

# SEEKTABLE (type 3): 18-byte seek points (sample number, offset, samples),
# placeholders among them (sample number all ones)
<seektable_block> ::= b'\x03' <seektable_len> <seektable_body>
<seektable_body> ::= <seekpoint> {1,4}
<seekpoint> ::= <sp_sample> <sp_offset> <sp_frame_samples>
<sp_sample> ::= b'\x00' {8} | b'\xff' {8}          # real point | placeholder
<sp_offset> ::= b'\x00' {8}
<sp_frame_samples> ::= b'\x10\x00' | b'\x00\x00'   # 4096 | placeholder 0
<seektable_len> ::= <b3>

# VORBIS_COMMENT (type 4), with little-endian lengths inside
<vorbis_comment_block> ::= b'\x04' <vc_len> <vorbis_comment_body>
<vorbis_comment_body> ::= <vendor_len> <vendor_str> <comment_count> <comments>
<vendor_str> ::= rb'[\x20-\x7e]' {0,32}
<vendor_len> ::= <b4le>
# two comments
<comment_count> ::= b'\x02\x00\x00\x00'
<comments> ::= <comment0> <comment1>
<comment0> ::= <comment0_len> <comment0_str>
<comment0_str> ::= rb'[\x20-\x7e]' {1,40}
<comment0_len> ::= <b4le>
<comment1> ::= <comment1_len> <comment1_str>
<comment1_str> ::= rb'[\x20-\x7e]' {1,40}
<comment1_len> ::= <b4le>
<vc_len> ::= <b3>

# CUESHEET (type 5): catalog number (128 bytes), lead-in (8), the CD flag
# and 258 reserved bytes, the number of tracks, then the tracks
<cuesheet_block> ::= b'\x05' <cuesheet_len> <cuesheet_body>
<cuesheet_body> ::= <cs_catalog> <cs_leadin> <cs_flags> <cs_reserved> \
                    <cs_ntracks> <cs_tracks>
<cs_catalog> ::= b'0' {128}                        # 128-char media catalog num
<cs_leadin> ::= b'\x00' {8}
<cs_flags> ::= b'\x80'                             # is-CD bit set
<cs_reserved> ::= b'\x00' {258}
<cs_ntracks> ::= b'\x02'                           # 1 audio + lead-out
<cs_tracks> ::= <cs_track> <cs_leadout_track>
<cs_track> ::= b'\x00' {8} b'\x01' b'0' {12} b'\x00' b'\x00' {13} b'\x01' \
               <cs_index>
<cs_index> ::= b'\x00' {8} b'\x01' b'\x00' {3}     # one index point
<cs_leadout_track> ::= b'\x00' {8} b'\xaa' b'0' {12} b'\x00' b'\x00' {13} b'\x00'
<cuesheet_len> ::= <b3>

# PICTURE (type 6): type, MIME type, description, width, height, depth,
# colours and data, with big-endian lengths; type 0 (other)
<picture_block> ::= b'\x06' <picture_len> <picture_body>
<picture_body> ::= <pic_type> <pic_mime_len> <pic_mime> \
                   <pic_desc_len> <pic_desc> \
                   <pic_w> <pic_h> <pic_depth> <pic_colors> \
                   <pic_data_len> <pic_data>
<pic_type> ::= b'\x00\x00\x00\x00'                 # 0 = Other
<pic_mime> ::= b'image/png'
<pic_mime_len> ::= <b4>
<pic_desc> ::= rb'[\x20-\x7e]' {0,16}
<pic_desc_len> ::= <b4>
<pic_w> ::= b'\x00\x00\x00\x01'
<pic_h> ::= b'\x00\x00\x00\x01'
<pic_depth> ::= b'\x00\x00\x00\x18'                # 24-bit
<pic_colors> ::= b'\x00\x00\x00\x00'               # 0 = not indexed
<pic_data> ::= rb'[\x00-\xff]' {1,32}
<pic_data_len> ::= <b4>
<picture_len> ::= <b3>

# PADDING (type 1), the last block (0x81)
<padding_block_last> ::= b'\x81' <padding_len> <padding_body>
<padding_body> ::= b'\x00' {0,64}
<padding_len> ::= <b3>

# Frames as in flac: FF F8 19 02, the frame number, CRC-8, a CONSTANT
# subframe with one 8-bit sample, CRC-16
<frames> ::= <frame> {1,3}
<frame> ::= <frame_header> <frame_crc8> <subframe> <frame_crc16>
<frame_header> ::= b'\xff\xf8\x19\x02' <frame_number>
<frame_number> ::= rb'[\x00-\x7f]'                 # UTF-8 coded, single byte
<subframe> ::= b'\x00' <constant_sample>
<constant_sample> ::= rb'[\x00-\xff]'
<frame_crc8> ::= <byte>
<frame_crc16> ::= <byte> {2}

# Shared primitives
<byte> ::= rb'[\x00-\xff]'
<b3> ::= <byte> {3}
<b4> ::= <byte> {4}
<b4le> ::= <byte> {4}

# Block lengths (24 bits, big-endian)
where <app_len> == len(bytes(<application_body>)).to_bytes(3, 'big')
where <seektable_len> == len(bytes(<seektable_body>)).to_bytes(3, 'big')
where <vc_len> == len(bytes(<vorbis_comment_body>)).to_bytes(3, 'big')
where <cuesheet_len> == len(bytes(<cuesheet_body>)).to_bytes(3, 'big')
where <picture_len> == len(bytes(<picture_body>)).to_bytes(3, 'big')
where <padding_len> == len(bytes(<padding_body>)).to_bytes(3, 'big')

# Lengths inside VORBIS_COMMENT (32 bits, little-endian)
where <vendor_len> == len(bytes(<vendor_str>)).to_bytes(4, 'little')
where <comment0_len> == len(bytes(<comment0_str>)).to_bytes(4, 'little')
where <comment1_len> == len(bytes(<comment1_str>)).to_bytes(4, 'little')

# Lengths inside PICTURE (32 bits, big-endian)
where <pic_mime_len> == len(bytes(<pic_mime>)).to_bytes(4, 'big')
where <pic_desc_len> == len(bytes(<pic_desc>)).to_bytes(4, 'big')
where <pic_data_len> == len(bytes(<pic_data>)).to_bytes(4, 'big')

# CRC-8 of the frame header, CRC-16 of the frame
where <frame_crc8> == flac_crc8(bytes(<frame_header>)).to_bytes(1, 'big')
where <frame_crc16> == flac_crc16(bytes(<frame>)[:-2]).to_bytes(2, 'big')

def flac_crc8(data: bytes) -> int:
    crc = 0
    for b in data:
        crc ^= b
        for _ in range(8):
            crc = ((crc << 1) ^ 0x07) & 0xff if (crc & 0x80) else (crc << 1) & 0xff
    return crc

def flac_crc16(data: bytes) -> int:
    crc = 0
    for b in data:
        crc ^= (b << 8)
        for _ in range(8):
            crc = ((crc << 1) ^ 0x8005) & 0xffff if (crc & 0x8000) else (crc << 1) & 0xffff
    return crc
