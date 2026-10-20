# AAC in an ADTS stream: two to four frames, each a seven-byte header and an
# opaque raw_data_block. The syncword, MPEG version, layer and
# protection_absent bits are fixed; the profile, sampling-frequency index,
# channel configuration and header flags are free bytes. The sampling-frequency
# index is held to a defined rate, the frame_length high bits to zero, and
# frame_length is written for each payload size, to equal the whole frame.
#
# TODO:
# * The payload is random bytes, not a coded raw_data_block, so a decoder
#   reads the framing but finds no audio behind it: no file decodes.
# * The profile, channel configuration and flag bits take any value, so a
#   frame may name a profile or layout its payload does not carry.

<start>       ::= <adts_frame>{2,4}

# A frame is its header and a payload of 1 to 48 bytes, one alternative per
# payload size, so that frame_length (byte 4 and the top of byte 5) can be
# written for it: 7 + the payload size. Short (1 to 8) and longer payloads are
# chosen equally often.
<adts_frame>  ::= <short_frame> | <long_frame>
<short_frame> ::= <frame_1> | <frame_2> | <frame_3> | <frame_4> | <frame_5> | <frame_6> | <frame_7> | <frame_8>
<long_frame>  ::= <frame_9> | <frame_10> | <frame_11> | <frame_12> | <frame_13> | <frame_14> | <frame_15> | <frame_16> | <frame_17> | <frame_18> | <frame_19> | <frame_20> | <frame_21> | <frame_22> | <frame_23> | <frame_24> | <frame_25> | <frame_26> | <frame_27> | <frame_28> | <frame_29> | <frame_30> | <frame_31> | <frame_32> | <frame_33> | <frame_34> | <frame_35> | <frame_36> | <frame_37> | <frame_38> | <frame_39> | <frame_40> | <frame_41> | <frame_42> | <frame_43> | <frame_44> | <frame_45> | <frame_46> | <frame_47> | <frame_48>

<frame_head>  ::= <syncword> <h1> <h2> <h3>

# Byte 0: fixed high 8 bits of the 12-bit syncword.
<syncword>    ::= b'\xff'

# Byte 1: 1111 (syncword low) | version | 00 (layer) | 1 (protection_absent).
#   0xF1 = MPEG-4 (version bit 0), 0xF9 = MPEG-2 (version bit 1).
# Layer is fixed 00 and protection_absent fixed 1 (7-byte header, no CRC).
<h1>          ::= b'\xf1' | b'\xf9'

# Byte 2: profile(2) | sampling_frequency_index(4) | private(1) | chan_cfg MSB(1).
# Only the bytes whose sampling_frequency_index is a defined value (0..12);
# indices 13/14 are reserved and 15 (explicit rate) is illegal in ADTS.
<h2>          ::= rb'[\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3]'

# Byte 3: chan_cfg low(2) | original(1) | home(1) | copyright_id(1)
#          | copyright_id_start(1) | frame_length high 2 bits.
# The two frame_length high bits are 0 (frame length < 2048), the six upper
# bits (channel/flags) free.
<h3>          ::= rb'[\x00\x04\x08\x0c\x10\x14\x18\x1c\x20\x24\x28\x2c\x30\x34\x38\x3c\x40\x44\x48\x4c\x50\x54\x58\x5c\x60\x64\x68\x6c\x70\x74\x78\x7c\x80\x84\x88\x8c\x90\x94\x98\x9c\xa0\xa4\xa8\xac\xb0\xb4\xb8\xbc\xc0\xc4\xc8\xcc\xd0\xd4\xd8\xdc\xe0\xe4\xe8\xec\xf0\xf4\xf8\xfc]'

# Byte 4: middle 8 bits of frame_length, written in each <frame_N>.
# Byte 5: frame_length low 3 bits | buffer_fullness high 5 bits: the bytes
# whose top 3 bits are the low bits of the frame length.
<h5_0> ::= rb'[\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f]'
<h5_1> ::= rb'[\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x30\x31\x32\x33\x34\x35\x36\x37\x38\x39\x3a\x3b\x3c\x3d\x3e\x3f]'
<h5_2> ::= rb'[\x40\x41\x42\x43\x44\x45\x46\x47\x48\x49\x4a\x4b\x4c\x4d\x4e\x4f\x50\x51\x52\x53\x54\x55\x56\x57\x58\x59\x5a\x5b\x5c\x5d\x5e\x5f]'
<h5_3> ::= rb'[\x60\x61\x62\x63\x64\x65\x66\x67\x68\x69\x6a\x6b\x6c\x6d\x6e\x6f\x70\x71\x72\x73\x74\x75\x76\x77\x78\x79\x7a\x7b\x7c\x7d\x7e\x7f]'
<h5_4> ::= rb'[\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9d\x9e\x9f]'
<h5_5> ::= rb'[\xa0\xa1\xa2\xa3\xa4\xa5\xa6\xa7\xa8\xa9\xaa\xab\xac\xad\xae\xaf\xb0\xb1\xb2\xb3\xb4\xb5\xb6\xb7\xb8\xb9\xba\xbb\xbc\xbd\xbe\xbf]'
<h5_6> ::= rb'[\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7\xc8\xc9\xca\xcb\xcc\xcd\xce\xcf\xd0\xd1\xd2\xd3\xd4\xd5\xd6\xd7\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf]'
<h5_7> ::= rb'[\xe0\xe1\xe2\xe3\xe4\xe5\xe6\xe7\xe8\xe9\xea\xeb\xec\xed\xee\xef\xf0\xf1\xf2\xf3\xf4\xf5\xf6\xf7\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff]'

# Byte 6: buffer_fullness low 6 bits | number_of_raw_data_blocks_in_frame-1 (2 bits).
<h6>          ::= <anybyte>

# Frames by payload size (the raw_data_block: opaque coded-audio bytes)
<frame_1> ::= <frame_head> b'\x01' <h5_0> <h6> <anybyte>{1}
<frame_2> ::= <frame_head> b'\x01' <h5_1> <h6> <anybyte>{2}
<frame_3> ::= <frame_head> b'\x01' <h5_2> <h6> <anybyte>{3}
<frame_4> ::= <frame_head> b'\x01' <h5_3> <h6> <anybyte>{4}
<frame_5> ::= <frame_head> b'\x01' <h5_4> <h6> <anybyte>{5}
<frame_6> ::= <frame_head> b'\x01' <h5_5> <h6> <anybyte>{6}
<frame_7> ::= <frame_head> b'\x01' <h5_6> <h6> <anybyte>{7}
<frame_8> ::= <frame_head> b'\x01' <h5_7> <h6> <anybyte>{8}
<frame_9> ::= <frame_head> b'\x02' <h5_0> <h6> <anybyte>{9}
<frame_10> ::= <frame_head> b'\x02' <h5_1> <h6> <anybyte>{10}
<frame_11> ::= <frame_head> b'\x02' <h5_2> <h6> <anybyte>{11}
<frame_12> ::= <frame_head> b'\x02' <h5_3> <h6> <anybyte>{12}
<frame_13> ::= <frame_head> b'\x02' <h5_4> <h6> <anybyte>{13}
<frame_14> ::= <frame_head> b'\x02' <h5_5> <h6> <anybyte>{14}
<frame_15> ::= <frame_head> b'\x02' <h5_6> <h6> <anybyte>{15}
<frame_16> ::= <frame_head> b'\x02' <h5_7> <h6> <anybyte>{16}
<frame_17> ::= <frame_head> b'\x03' <h5_0> <h6> <anybyte>{17}
<frame_18> ::= <frame_head> b'\x03' <h5_1> <h6> <anybyte>{18}
<frame_19> ::= <frame_head> b'\x03' <h5_2> <h6> <anybyte>{19}
<frame_20> ::= <frame_head> b'\x03' <h5_3> <h6> <anybyte>{20}
<frame_21> ::= <frame_head> b'\x03' <h5_4> <h6> <anybyte>{21}
<frame_22> ::= <frame_head> b'\x03' <h5_5> <h6> <anybyte>{22}
<frame_23> ::= <frame_head> b'\x03' <h5_6> <h6> <anybyte>{23}
<frame_24> ::= <frame_head> b'\x03' <h5_7> <h6> <anybyte>{24}
<frame_25> ::= <frame_head> b'\x04' <h5_0> <h6> <anybyte>{25}
<frame_26> ::= <frame_head> b'\x04' <h5_1> <h6> <anybyte>{26}
<frame_27> ::= <frame_head> b'\x04' <h5_2> <h6> <anybyte>{27}
<frame_28> ::= <frame_head> b'\x04' <h5_3> <h6> <anybyte>{28}
<frame_29> ::= <frame_head> b'\x04' <h5_4> <h6> <anybyte>{29}
<frame_30> ::= <frame_head> b'\x04' <h5_5> <h6> <anybyte>{30}
<frame_31> ::= <frame_head> b'\x04' <h5_6> <h6> <anybyte>{31}
<frame_32> ::= <frame_head> b'\x04' <h5_7> <h6> <anybyte>{32}
<frame_33> ::= <frame_head> b'\x05' <h5_0> <h6> <anybyte>{33}
<frame_34> ::= <frame_head> b'\x05' <h5_1> <h6> <anybyte>{34}
<frame_35> ::= <frame_head> b'\x05' <h5_2> <h6> <anybyte>{35}
<frame_36> ::= <frame_head> b'\x05' <h5_3> <h6> <anybyte>{36}
<frame_37> ::= <frame_head> b'\x05' <h5_4> <h6> <anybyte>{37}
<frame_38> ::= <frame_head> b'\x05' <h5_5> <h6> <anybyte>{38}
<frame_39> ::= <frame_head> b'\x05' <h5_6> <h6> <anybyte>{39}
<frame_40> ::= <frame_head> b'\x05' <h5_7> <h6> <anybyte>{40}
<frame_41> ::= <frame_head> b'\x06' <h5_0> <h6> <anybyte>{41}
<frame_42> ::= <frame_head> b'\x06' <h5_1> <h6> <anybyte>{42}
<frame_43> ::= <frame_head> b'\x06' <h5_2> <h6> <anybyte>{43}
<frame_44> ::= <frame_head> b'\x06' <h5_3> <h6> <anybyte>{44}
<frame_45> ::= <frame_head> b'\x06' <h5_4> <h6> <anybyte>{45}
<frame_46> ::= <frame_head> b'\x06' <h5_5> <h6> <anybyte>{46}
<frame_47> ::= <frame_head> b'\x06' <h5_6> <h6> <anybyte>{47}
<frame_48> ::= <frame_head> b'\x06' <h5_7> <h6> <anybyte>{48}

<anybyte>     ::= rb'[\x00-\xff]'
