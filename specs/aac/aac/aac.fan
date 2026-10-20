# AAC in an ADTS stream: two to four frames, each a seven-byte header and an
# opaque raw_data_block. The syncword, MPEG version, layer and
# protection_absent bits are fixed; the profile, sampling-frequency index,
# channel configuration and header flags are free bytes. The sampling-frequency
# index is held to a defined rate, the frame_length high bits to zero, and
# frame_length is a constraint equal to the whole frame.
#
# TODO:
# * The payload is random bytes, not a coded raw_data_block, so a decoder
#   reads the framing but finds no audio behind it: no file decodes.
# * The profile, channel configuration and flag bits take any value, so a
#   frame may name a profile or layout its payload does not carry.

<start>       ::= <adts_frame>{2,4}

<adts_frame>  ::= <syncword> <h1> <h2> <h3> <h4> <h5> <h6> <payload>

# Byte 0: fixed high 8 bits of the 12-bit syncword.
<syncword>    ::= b'\xff'

# Byte 1: 1111 (syncword low) | version | 00 (layer) | 1 (protection_absent).
#   0xF1 = MPEG-4 (version bit 0), 0xF9 = MPEG-2 (version bit 1).
# Layer is fixed 00 and protection_absent fixed 1 (7-byte header, no CRC).
<h1>          ::= b'\xf1' | b'\xf9'

# Byte 2: profile(2) | sampling_frequency_index(4) | private(1) | chan_cfg MSB(1).
# Constrained so the sampling_frequency_index is a defined value (0..12);
# indices 13/14 are reserved and 15 (explicit rate) is illegal in ADTS.
<h2>          ::= <anybyte>

# Byte 3: chan_cfg low(2) | original(1) | home(1) | copyright_id(1)
#          | copyright_id_start(1) | frame_length high 2 bits.
# The two frame_length high bits are pinned to 0 (frame length < 2048),
# leaving the six upper bits (channel/flags) free.
<h3>          ::= <anybyte>

# Byte 4: middle 8 bits of frame_length.
<h4>          ::= <anybyte>

# Byte 5: frame_length low 3 bits | buffer_fullness high 5 bits.
<h5>          ::= <anybyte>

# Byte 6: buffer_fullness low 6 bits | number_of_raw_data_blocks_in_frame-1 (2 bits).
<h6>          ::= <anybyte>

# raw_data_block payload: opaque coded-audio bytes, in a short and a longer
# size range. frame_length ties its length back into the header below.
<payload>     ::= <anybyte>{1,8} | <anybyte>{9,48}

<anybyte>     ::= rb'[\x00-\xff]'

# semantic constraints (applied to every frame in the stream)

# sampling_frequency_index (byte 2 bits 5..2) must be a defined rate 0..12.
where forall <fr> in <adts_frame>:
    ((bytes(<fr>.<h2>)[0] >> 2) & 15) <= 12

# frame_length high 2 bits (byte 3 bits 1..0) == 0  => length fits in 11 bits.
where forall <fr> in <adts_frame>:
    (bytes(<fr>.<h3>)[0] & 3) == 0

# frame_length (byte4<<3 | byte5>>5) MUST equal the whole frame size:
# 7-byte header + payload bytes. Cross-field length equality.
where forall <fr> in <adts_frame>:
    ((bytes(<fr>.<h4>)[0] << 3) | ((bytes(<fr>.<h5>)[0] >> 5) & 7)) == 7 + len(<fr>.<payload>)
