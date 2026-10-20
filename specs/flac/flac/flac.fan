# FLAC (RFC 9639): the fLaC marker, STREAMINFO, one block of each other
# metadata type (PADDING, APPLICATION, SEEKTABLE, VORBIS_COMMENT, CUESHEET,
# PICTURE), a last block with the last-block flag set, and one to three
# frames. Block lengths, the lengths inside VORBIS_COMMENT and PICTURE, and
# the CRC-8 and CRC-16 of each frame are where constraints.
#
# TODO:
# * Frames are mono, 8 bits, with one CONSTANT subframe each: VERBATIM,
#   FIXED and LPC subframes are never made.
# * Every metadata block type is always there, in the same order.

<start> ::= b'fLaC' <metadata_section> <frame>{1,3}

# STREAMINFO, one block of each other type, then a last block of any type.
# The types are a sequence rather than a choice: with Fandango's default
# node limit, an alternative as large as CUESHEET is otherwise never picked.
<metadata_section> ::= <streaminfo_notlast> <padding_notlast> <application_notlast> \
                       <seektable_notlast> <vorbiscomment_notlast> <cuesheet_notlast> \
                       <picture_notlast> <final_block>

<final_block> ::= <padding_last> | <application_last> | <seektable_last> \
                | <vorbiscomment_last> | <cuesheet_last> | <picture_last>

# STREAMINFO (type 0): the body is 34 bytes, so the header is fixed.
#   min_block_size u16 (>= 16), max_block_size u16, min_frame_size u24,
#   max_frame_size u24 (0: unknown), then 64 bits: sample rate (20),
#   channels - 1 (3), bits per sample - 1 (5), total samples (36, 0:
#   unknown), and the MD5 of the audio (16 bytes, zero: not computed).
<streaminfo_notlast> ::= b'\x00\x00\x00\x22' <si_body>

<si_body> ::= <si_min_bs> <si_max_bs> <si_min_fs> <si_max_fs> <si_packed> <si_md5>

<si_min_bs> ::= <byte>{2}
<si_max_bs> ::= <byte>{2}
where int.from_bytes(bytes(<si_min_bs>), 'big') >= 16
where int.from_bytes(bytes(<si_max_bs>), 'big') >= int.from_bytes(bytes(<si_min_bs>), 'big')

<si_min_fs> ::= <byte>{3}
<si_max_fs> ::= <byte>{3}

# 44100 Hz, mono, 8 bits, total samples unknown: what the frames below are.
<si_packed> ::= <byte>{8} := ((44100 << 44) | (0 << 41) | (7 << 36) | 0).to_bytes(8, 'big')

<si_md5> ::= <byte>{16}

# PADDING (type 1): zero bytes
<padding_notlast> ::= b'\x01' <pad_len_n> <pad_body_n>
<padding_last>    ::= b'\x81' <pad_len_l> <pad_body_l>
<pad_len_n> ::= <byte>{3}
<pad_len_l> ::= <byte>{3}
<pad_body_n> ::= b'\x00'{0,16}
<pad_body_l> ::= b'\x00'{0,16}
where <pad_len_n> == len(bytes(<pad_body_n>)).to_bytes(3, 'big')
where <pad_len_l> == len(bytes(<pad_body_l>)).to_bytes(3, 'big')

# APPLICATION (type 2): a 4-byte application id, then its data
<application_notlast> ::= b'\x02' <app_len_n> <app_body_n>
<application_last>    ::= b'\x82' <app_len_l> <app_body_l>
<app_len_n> ::= <byte>{3}
<app_len_l> ::= <byte>{3}
<app_body_n> ::= <app_id_n> <app_data_n>
<app_body_l> ::= <app_id_l> <app_data_l>
<app_id_n> ::= <byte>{4}
<app_id_l> ::= <byte>{4}
<app_data_n> ::= <byte>{0,16}
<app_data_l> ::= <byte>{0,16}
where <app_len_n> == len(bytes(<app_body_n>)).to_bytes(3, 'big')
where <app_len_l> == len(bytes(<app_body_l>)).to_bytes(3, 'big')

# SEEKTABLE (type 3): 18-byte seek points: sample number (u64, all ones
# for a placeholder), offset of the frame from the first frame (u64), and
# the number of samples in it (u16)
<seektable_notlast> ::= b'\x03' <seek_len_n> <seek_body_n>
<seektable_last>    ::= b'\x83' <seek_len_l> <seek_body_l>
<seek_len_n> ::= <byte>{3}
<seek_len_l> ::= <byte>{3}
<seek_body_n> ::= <seekpoint>{1,3}
<seek_body_l> ::= <seekpoint>{1,3}
where <seek_len_n> == len(bytes(<seek_body_n>)).to_bytes(3, 'big')
where <seek_len_l> == len(bytes(<seek_body_l>)).to_bytes(3, 'big')

<seekpoint> ::= <seek_sample> <seek_offset> <seek_nsamples>
<seek_sample> ::= <byte>{8}
<seek_offset> ::= <byte>{8}
<seek_nsamples> ::= <byte>{2}

# VORBIS_COMMENT (type 4): a Vorbis comment packet, so its lengths are
# little-endian u32, unlike the rest of FLAC: vendor length, vendor, number
# of comments (two here), then each comment's length and "NAME=value".
<vorbiscomment_notlast> ::= b'\x04' <vc_len_n> <vc_body_n>
<vorbiscomment_last>    ::= b'\x84' <vc_len_l> <vc_body_l>
<vc_len_n> ::= <byte>{3}
<vc_len_l> ::= <byte>{3}
<vc_body_n> ::= <vc_vendor_len_n> <vc_vendor_n> b'\x02\x00\x00\x00' <vc_comment_a_n> <vc_comment_b_n>
<vc_body_l> ::= <vc_vendor_len_l> <vc_vendor_l> b'\x02\x00\x00\x00' <vc_comment_a_l> <vc_comment_b_l>
where <vc_len_n> == len(bytes(<vc_body_n>)).to_bytes(3, 'big')
where <vc_len_l> == len(bytes(<vc_body_l>)).to_bytes(3, 'big')

<vc_vendor_len_n> ::= <byte>{4}
<vc_vendor_len_l> ::= <byte>{4}
<vc_vendor_n> ::= r'[ -~]{0,16}'
<vc_vendor_l> ::= r'[ -~]{0,16}'
where <vc_vendor_len_n> == len(bytes(<vc_vendor_n>)).to_bytes(4, 'little')
where <vc_vendor_len_l> == len(bytes(<vc_vendor_l>)).to_bytes(4, 'little')

<vc_comment_a_n> ::= <vc_clen_a_n> <vc_ctext_a_n>
<vc_comment_b_n> ::= <vc_clen_b_n> <vc_ctext_b_n>
<vc_comment_a_l> ::= <vc_clen_a_l> <vc_ctext_a_l>
<vc_comment_b_l> ::= <vc_clen_b_l> <vc_ctext_b_l>
<vc_clen_a_n> ::= <byte>{4}
<vc_clen_b_n> ::= <byte>{4}
<vc_clen_a_l> ::= <byte>{4}
<vc_clen_b_l> ::= <byte>{4}
<vc_ctext_a_n> ::= r'[A-Z]{1,8}=[ -~]{0,12}'
<vc_ctext_b_n> ::= r'[A-Z]{1,8}=[ -~]{0,12}'
<vc_ctext_a_l> ::= r'[A-Z]{1,8}=[ -~]{0,12}'
<vc_ctext_b_l> ::= r'[A-Z]{1,8}=[ -~]{0,12}'
where <vc_clen_a_n> == len(bytes(<vc_ctext_a_n>)).to_bytes(4, 'little')
where <vc_clen_b_n> == len(bytes(<vc_ctext_b_n>)).to_bytes(4, 'little')
where <vc_clen_a_l> == len(bytes(<vc_ctext_a_l>)).to_bytes(4, 'little')
where <vc_clen_b_l> == len(bytes(<vc_ctext_b_l>)).to_bytes(4, 'little')

# CUESHEET (type 5): media catalog number (128 bytes), lead-in samples
# (u64), the CD flag and 258 reserved bytes, the number of tracks, then
# each track: offset (u64), number (1..99, 170 for the lead-out), ISRC (12
# bytes), flags and 13 reserved bytes, the number of index points, and the
# index points (offset u64, number, 3 reserved bytes).
<cuesheet_notlast> ::= b'\x05' <cue_len_n> <cue_body_n>
<cuesheet_last>    ::= b'\x85' <cue_len_l> <cue_body_l>
<cue_len_n> ::= <byte>{3}
<cue_len_l> ::= <byte>{3}
<cue_body_n> ::= <cue_catalog> <cue_leadin> <cue_flags_resv> b'\x02' <cue_track_audio> <cue_track_leadout>
<cue_body_l> ::= <cue_catalog> <cue_leadin> <cue_flags_resv> b'\x02' <cue_track_audio> <cue_track_leadout>
where <cue_len_n> == len(bytes(<cue_body_n>)).to_bytes(3, 'big')
where <cue_len_l> == len(bytes(<cue_body_l>)).to_bytes(3, 'big')

# The long runs of zeros are single literals and not b'\x00'{128}: every
# repetition is a node, and that many of them crowd the other blocks out.
<cue_catalog> ::= b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
<cue_leadin> ::= <byte>{8}
# CD flag (0x80) and 258 reserved bytes
<cue_flags_resv> ::= b'\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'

# One audio track with one index point, then the lead-out track (number
# 170, no index points)
<cue_track_audio> ::= <cue_toffset_a> <cue_tnum_a> <cue_isrc_a> <cue_tflags_a> b'\x01' <cue_index_a>
<cue_toffset_a> ::= <byte>{8}
<cue_tnum_a> ::= rb'[\x01-\x63]'
<cue_isrc_a> ::= b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
<cue_tflags_a> ::= b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
<cue_index_a> ::= <cue_ioffset_a> <cue_inum_a> b'\x00\x00\x00'
<cue_ioffset_a> ::= <byte>{8}
<cue_inum_a> ::= <byte>

<cue_track_leadout> ::= <cue_toffset_o> b'\xaa' <cue_isrc_o> <cue_tflags_o> b'\x00'
<cue_toffset_o> ::= <byte>{8}
<cue_isrc_o> ::= b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
<cue_tflags_o> ::= b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'

# PICTURE (type 6), big-endian u32 fields: picture type (0..20, 3 is the
# front cover), MIME type length and MIME type, description length and
# description, width, height, colour depth, number of colours (0 if not
# indexed), data length and data
<picture_notlast> ::= b'\x06' <pic_len_n> <pic_body_n>
<picture_last>    ::= b'\x86' <pic_len_l> <pic_body_l>
<pic_len_n> ::= <byte>{3}
<pic_len_l> ::= <byte>{3}
<pic_body_n> ::= <pic_type_n> <pic_mlen_n> <pic_mime_n> <pic_dlen_n> <pic_desc_n> \
                 <pic_w_n> <pic_h_n> <pic_depth_n> <pic_ncol_n> <pic_datalen_n> <pic_data_n>
<pic_body_l> ::= <pic_type_l> <pic_mlen_l> <pic_mime_l> <pic_dlen_l> <pic_desc_l> \
                 <pic_w_l> <pic_h_l> <pic_depth_l> <pic_ncol_l> <pic_datalen_l> <pic_data_l>
where <pic_len_n> == len(bytes(<pic_body_n>)).to_bytes(3, 'big')
where <pic_len_l> == len(bytes(<pic_body_l>)).to_bytes(3, 'big')

# picture type 0..20: three zero bytes and a low byte
<pic_type_n> ::= b'\x00\x00\x00' <pic_type_lo_n>
<pic_type_l> ::= b'\x00\x00\x00' <pic_type_lo_l>
<pic_type_lo_n> ::= rb'[\x00-\x14]'
<pic_type_lo_l> ::= rb'[\x00-\x14]'

<pic_mime_n> ::= r'image/(png|jpeg|gif)'
<pic_mime_l> ::= r'image/(png|jpeg|gif)'
<pic_mlen_n> ::= <byte>{4}
<pic_mlen_l> ::= <byte>{4}
where <pic_mlen_n> == len(bytes(<pic_mime_n>)).to_bytes(4, 'big')
where <pic_mlen_l> == len(bytes(<pic_mime_l>)).to_bytes(4, 'big')

<pic_desc_n> ::= r'[ -~]{0,16}'
<pic_desc_l> ::= r'[ -~]{0,16}'
<pic_dlen_n> ::= <byte>{4}
<pic_dlen_l> ::= <byte>{4}
where <pic_dlen_n> == len(bytes(<pic_desc_n>)).to_bytes(4, 'big')
where <pic_dlen_l> == len(bytes(<pic_desc_l>)).to_bytes(4, 'big')

<pic_w_n> ::= <byte>{4}
<pic_w_l> ::= <byte>{4}
<pic_h_n> ::= <byte>{4}
<pic_h_l> ::= <byte>{4}
<pic_depth_n> ::= <byte>{4}
<pic_depth_l> ::= <byte>{4}
<pic_ncol_n> ::= <byte>{4}
<pic_ncol_l> ::= <byte>{4}

<pic_data_n> ::= <byte>{0,16}
<pic_data_l> ::= <byte>{0,16}
<pic_datalen_n> ::= <byte>{4}
<pic_datalen_l> ::= <byte>{4}
where <pic_datalen_n> == len(bytes(<pic_data_n>)).to_bytes(4, 'big')
where <pic_datalen_l> == len(bytes(<pic_data_l>)).to_bytes(4, 'big')

# Frames: fixed block size, mono, 8 bits and one CONSTANT subframe, so that
# every field falls on a byte.
#   FF F8  sync (14 bits), a reserved bit, fixed block size
#   19     block size 192, sample rate 44.1 kHz
#   02     mono, 8 bits per sample
#   then the frame number (UTF-8 coded, one byte for 0..127), the CRC-8 of
#   the header, the subframe (00: CONSTANT, no wasted bits; the sample), and
#   the CRC-16 of everything before it in the frame
<frame> ::= <frame_header> <frame_crc8> <subframe> <frame_crc16>
<frame_header> ::= b'\xff\xf8\x19\x02' <frame_number>
<frame_number> ::= r'[\x00-\x7f]'
<frame_crc8> ::= <byte>
<subframe> ::= b'\x00' <constant_sample>
<constant_sample> ::= <byte>
<frame_crc16> ::= <byte>{2}

where <frame_crc8> == flac_crc8(bytes(<frame_header>))
where <frame_crc16> == flac_crc16(bytes(<frame>)[:-2])

# bytes and checksums
<byte> ::= rb'[\x00-\xff]'

def flac_crc8(data: bytes) -> bytes:
    # CRC-8, polynomial x^8+x^2+x+1 (0x07), init 0, no reflection, no xorout.
    crc = 0
    for x in data:
        crc ^= x
        for _ in range(8):
            if crc & 0x80:
                crc = ((crc << 1) ^ 0x07) & 0xff
            else:
                crc = (crc << 1) & 0xff
    return bytes([crc])

def flac_crc16(data: bytes) -> bytes:
    # CRC-16, polynomial x^16+x^15+x^2+1 (0x8005), init 0, no reflection,
    # stored big-endian.
    crc = 0
    for x in data:
        crc ^= (x << 8)
        for _ in range(8):
            if crc & 0x8000:
                crc = ((crc << 1) ^ 0x8005) & 0xffff
            else:
                crc = (crc << 1) & 0xffff
    return crc.to_bytes(2, 'big')
