# Same as aac, with values taken from the edges of what the format allows: one
# ADTS frame of every flavour (LC, Main, SSR and LTP profiles, MPEG-2
# signalling, a CRC-protected frame, two raw_data_blocks, 7.1 channels,
# channel_configuration 0 and a reserved sampling-rate index), then zero to
# four more, or a legacy ADIF file with or without a copyright identifier.
# aac_frame_length is a where constraint; the ADIF header bits are packed by a
# helper and chosen freely (:=).
#
# TODO:
# * Frame payloads and the ADIF audio are random bytes, not coded audio, so
#   most files are read only as far as their headers.

import random

# ADTS variable-header tail: bytes 3..6 of the header. The 13-bit
# aac_frame_length straddles byte3(bits1-0), byte4(all 8) and byte5(bits7-5);
# channel_config low 2 bits, the flag bits, adts_buffer_fullness(11) and
# no_raw_data_blocks_in_frame_minus1(2) fill the rest. A helper packs them.
def adts_tail(flen: int, chan: int, orig: int, home: int,
              cid: int, cis: int, buffull: int, nblk: int) -> bytes:
    b3 = (((chan & 3) << 6) | ((orig & 1) << 5) | ((home & 1) << 4)
          | ((cid & 1) << 3) | ((cis & 1) << 2) | ((flen >> 11) & 3))
    b4 = (flen >> 3) & 0xFF
    b5 = ((flen & 7) << 5) | ((buffull >> 6) & 0x1F)
    b6 = ((buffull & 0x3F) << 2) | (nblk & 3)
    return bytes([b3, b4, b5, b6])

# Pack a bit string (MSB-first) into bytes, zero-padding the final byte. Used
# only for the ADIF header, whose fields are not byte-aligned.
def bits_to_bytes(bits: str) -> bytes:
    if len(bits) % 8:
        bits = bits + '0' * (8 - len(bits) % 8)
    return int(bits, 2).to_bytes(len(bits) // 8, 'big')

# ADIF header, no copyright_id, VBR, one PCE (31 payload bits -> 4 bytes):
#   copyright_id_present=0, original_copy=0, home=0, bitstream_type=1(VBR),
#   bitrate(23 random), num_program_config_elements=0 (=> one element).
def adif_hdr_nc() -> bytes:
    b = '0' + '0' + '0' + '1'
    b += format(random.randint(0, (1 << 23) - 1), '023b')
    b += '0000'
    return bits_to_bytes(b)

# ADIF header, copyright_id present, CBR (123 payload bits -> 16 bytes):
#   copyright_id_present=1, copyright_id(72 random), original_copy=1, home=1,
#   bitstream_type=0(CBR), bitrate(23), num_pce=0, adif_buffer_fullness=0xFFFFF.
def adif_hdr_cc() -> bytes:
    b = '1' + format(random.randint(0, (1 << 72) - 1), '072b')
    b += '1' + '1' + '0'
    b += format(random.randint(0, (1 << 23) - 1), '023b')
    b += '0000'
    b += format(0xFFFFF, '020b')
    return bits_to_bytes(b)

# ADTS is the dominant real-world form, so it is listed several times against
# the single legacy ADIF branch (the two are unambiguous -- ADTS begins 0xFFFx,
# ADIF begins 'ADIF' -- so no parse conflict from the repetition).
<start> ::= <adts_stream> | <adts_stream> | <adts_stream> | <adif_file>

<byte> ::= rb'[\x00-\xff]'

# One of every ADTS flavour, mandatory, so a single file covers all extremes,
# then zero to four more frames of any flavour.
<adts_stream> ::= <f_lc> <f_main> <f_ssr> <f_ltp> <f_mpeg2> <f_crc> \
                  <f_multiblock> <f_8ch> <f_chan0> <f_resv> <adts_any>{0,4}

<adts_any> ::= <f_lc> | <f_main> | <f_ssr> | <f_ltp> | <f_mpeg2> | <f_crc> \
             | <f_multiblock> | <f_8ch> | <f_chan0> | <f_resv>

# ADTS flavours. B0=0xFF sync-high; B1 = sync-low(1111) ID layer(00)
# protection_absent; B2 = profile(2) samp_idx(4) private(1) chan-high(1).
# B3..B6 = <tail_x>, solved by the `where` to carry aac_frame_length.

# LC, MPEG-4, 44.1 kHz, stereo, no CRC.  B1=0xF1 B2=0x50
<f_lc> ::= b'\xff' b'\xf1' b'\x50' <tail_lc> <payload_lc>
    where bytes(<tail_lc>) == adts_tail(7 + len(bytes(<payload_lc>)), 2, 0, 0, 0, 0, 0x7FF, 0)
<tail_lc> ::= <byte>{4}
<payload_lc> ::= rb'[\x00-\xff]{7,64}'

# Main profile, MPEG-4, 96 kHz (samp_idx 0 = max rate), mono, no CRC.
# B1=0xF1 B2=0x00
<f_main> ::= b'\xff' b'\xf1' b'\x00' <tail_main> <payload_main>
    where bytes(<tail_main>) == adts_tail(7 + len(bytes(<payload_main>)), 1, 0, 0, 0, 0, 0x7FF, 0)
<tail_main> ::= <byte>{4}
<payload_main> ::= rb'[\x00-\xff]{7,64}'

# SSR profile (deprecated), 8 kHz (samp_idx 11), mono, no CRC.  B1=0xF1 B2=0xAC
<f_ssr> ::= b'\xff' b'\xf1' b'\xac' <tail_ssr> <payload_ssr>
    where bytes(<tail_ssr>) == adts_tail(7 + len(bytes(<payload_ssr>)), 1, 0, 0, 0, 0, 0x555, 0)
<tail_ssr> ::= <byte>{4}
<payload_ssr> ::= rb'[\x00-\xff]{7,64}'

# LTP profile, 7350 Hz (samp_idx 12 = min rate), mono, no CRC.  B1=0xF1 B2=0xF0
<f_ltp> ::= b'\xff' b'\xf1' b'\xf0' <tail_ltp> <payload_ltp>
    where bytes(<tail_ltp>) == adts_tail(7 + len(bytes(<payload_ltp>)), 1, 0, 0, 0, 0, 0x7FF, 0)
<tail_ltp> ::= <byte>{4}
<payload_ltp> ::= rb'[\x00-\xff]{7,64}'

# LC, MPEG-2 (ID=1), 48 kHz (samp_idx 3), stereo, no CRC.  B1=0xF9 B2=0x4C
<f_mpeg2> ::= b'\xff' b'\xf9' b'\x4c' <tail_mpeg2> <payload_mpeg2>
    where bytes(<tail_mpeg2>) == adts_tail(7 + len(bytes(<payload_mpeg2>)), 2, 0, 0, 0, 0, 0x2AA, 0)
<tail_mpeg2> ::= <byte>{4}
<payload_mpeg2> ::= rb'[\x00-\xff]{7,64}'

# LC, MPEG-4, 44.1 kHz, stereo, WITH CRC (protection_absent=0, 9-byte header).
# B1=0xF0 B2=0x50; frame_length counts the 7 header + 2 CRC + payload bytes.
<f_crc> ::= b'\xff' b'\xf0' b'\x50' <tail_crc> <crc_c> <payload_crc>
    where bytes(<tail_crc>) == adts_tail(9 + len(bytes(<payload_crc>)), 2, 0, 0, 0, 0, 0x7FF, 0)
<tail_crc> ::= <byte>{4}
<crc_c> ::= b'\xff\xff'
<payload_crc> ::= rb'[\x00-\xff]{7,64}'

# LC, MPEG-4, 44.1 kHz, stereo, TWO raw_data_blocks (nblk minus1 = 1), no CRC.
# B1=0xF1 B2=0x50; larger opaque payload holds both blocks.
<f_multiblock> ::= b'\xff' b'\xf1' b'\x50' <tail_mb> <payload_mb>
    where bytes(<tail_mb>) == adts_tail(7 + len(bytes(<payload_mb>)), 2, 0, 0, 0, 0, 0x7FF, 1)
<tail_mb> ::= <byte>{4}
<payload_mb> ::= rb'[\x00-\xff]{16,80}'

# LC, MPEG-4, 24 kHz (samp_idx 6), 7.1 channels (chan 7 = max), private_bit=1,
# original=home=copyright bits all set, buffer_fullness 0 (CBR-full).
# B1=0xF1 B2=0x5B
<f_8ch> ::= b'\xff' b'\xf1' b'\x5b' <tail_8ch> <payload_8ch>
    where bytes(<tail_8ch>) == adts_tail(7 + len(bytes(<payload_8ch>)), 7, 1, 1, 1, 1, 0x000, 0)
<tail_8ch> ::= <byte>{4}
<payload_8ch> ::= rb'[\x00-\xff]{7,64}'

# LC, MPEG-4, 44.1 kHz, channel_configuration 0 (channel layout defined by a
# PCE inside the payload), no CRC.  B1=0xF1 B2=0x50
<f_chan0> ::= b'\xff' b'\xf1' b'\x50' <tail_chan0> <payload_chan0>
    where bytes(<tail_chan0>) == adts_tail(7 + len(bytes(<payload_chan0>)), 0, 0, 0, 0, 0, 0x7FF, 0)
<tail_chan0> ::= <byte>{4}
<payload_chan0> ::= rb'[\x00-\xff]{7,64}'

# LC, MPEG-4, RESERVED sampling_frequency_index 13, stereo, no CRC. This is an
# edge most decoders reject.  B1=0xF1 B2=0x74
<f_resv> ::= b'\xff' b'\xf1' b'\x74' <tail_resv> <payload_resv>
    where bytes(<tail_resv>) == adts_tail(7 + len(bytes(<payload_resv>)), 2, 0, 0, 0, 0, 0x7FF, 0)
<tail_resv> ::= <byte>{4}
<payload_resv> ::= rb'[\x00-\xff]{7,64}'

# ADIF flavours (legacy single-header format).  'ADIF' magic + bit-packed
# header (free-choice `:=`, no cross-field length) + opaque audio bitstream.
<adif_file> ::= <adif_nc> | <adif_cc>

<adif_nc> ::= b'ADIF' <adif_hdr_nc> <adif_data_nc>
<adif_hdr_nc> ::= <byte>{4} := adif_hdr_nc()
<adif_data_nc> ::= rb'[\x00-\xff]{16,128}'

<adif_cc> ::= b'ADIF' <adif_hdr_cc> <adif_data_cc>
<adif_hdr_cc> ::= <byte>{16} := adif_hdr_cc()
<adif_data_cc> ::= rb'[\x00-\xff]{16,128}'
