# Same as mp3, with values taken from the edges of what the format allows:
# ID3v2.3 or 2.4 with the unsynchronisation and extended-header flags and a
# TXXX frame, then eight frames from 8 to 448 kbit/s (MPEG-1, 2 and 2.5,
# Layers I to III, every channel mode, padding and the private bit, CCITT and
# reserved emphasis, a CRC-16), and an ID3v1.1 tag.
#
# TODO:
# * The ID3v2 flags are set with no extended header or unsynchronised data
#   behind them, and eight frames of different kinds in a row are not one
#   stream to a decoder, so no file decodes.

# helpers

def synchsafe(n):
    # ID3v2 28-bit synchsafe integer: 4 bytes, each with the high bit clear.
    return bytes([(n >> 21) & 0x7f, (n >> 14) & 0x7f, (n >> 7) & 0x7f, n & 0x7f])

def crc16_mp3(data):
    # MPEG audio CRC-16: poly 0x8005, init 0xFFFF, MSB-first, no reflection.
    crc = 0xFFFF
    for byte in data:
        crc ^= (byte << 8)
        for _ in range(8):
            if crc & 0x8000:
                crc = ((crc << 1) ^ 0x8005) & 0xFFFF
            else:
                crc = (crc << 1) & 0xFFFF
    return crc.to_bytes(2, 'big')

# ID3v2 tag, frames, ID3v1.1 tag

<start> ::= <id3v2> <frames> <id3v1>

# ID3v2: "ID3", version (2 bytes), flags, synchsafe size (4 bytes), frames

<id3v2> ::= b'ID3' <id3ver> <id3flags> <id3size> <id3body>
where bytes(<id3size>) == synchsafe(len(bytes(<id3body>)))

<id3ver>   ::= b'\x03\x00' | b'\x04\x00'        # ID3v2.3.0 / ID3v2.4.0
<id3flags> ::= b'\x00' | b'\x80' | b'\xc0'      # none / unsync / unsync+extended
<id3size>  ::= <byte>{4}

<id3body> ::= <fr_tit2> <fr_txxx> <id3pad>

# Text-information frame: ID[4] size[4 BE] flags[2] encoding-byte text
<fr_tit2> ::= b'TIT2' <fsz1> b'\x00\x00' <text1>
where bytes(<fsz1>) == len(bytes(<text1>)).to_bytes(4, 'big')
<fsz1>  ::= <byte>{4}
<text1> ::= b'\x00' <ascii>                     # 0x00 = ISO-8859-1 encoding

# User-defined text frame: encoding, NUL-terminated description, value
<fr_txxx> ::= b'TXXX' <fsz2> b'\x00\x00' <text2>
where bytes(<fsz2>) == len(bytes(<text2>)).to_bytes(4, 'big')
<fsz2>  ::= <byte>{4}
<text2> ::= b'\x03' <ascii> b'\x00' <ascii>     # 0x03 = UTF-8 encoding

<id3pad> ::= b'\x00'{0,6}                        # trailing padding after frames
<ascii>  ::= rb'[\x20-\x7e]{1,16}'

# One frame of each kind. The body is the frame length minus the 4-byte header
# (and minus 2 for a CRC); the frame length is
#   Layer I   : (12000*kbps // sr + pad) * 4
#   Layer II/III (v1)  : 144000*kbps // sr + pad
#   Layer III (v2/2.5) :  72000*kbps // sr + pad

<frames> ::= <f_v1_l3_max> <f_v1_l3_min> <f_v2_l3_min> <f_v25_l3> \
             <f_v1_l1_max> <f_v1_l2_max> <f_v1_l3_crc> <f_emph_reserved>

# 1) MPEG-1 Layer III, 320 kbps, 48000 Hz, stereo, no pad. len=960
<f_v1_l3_max> ::= b'\xff\xfb\xe4\x00' <byte>{956}

# 2) MPEG-1 Layer III, 32 kbps, 44100 Hz, mono, padding=1. len=105
<f_v1_l3_min> ::= b'\xff\xfb\x12\xc0' <byte>{101}

# 3) MPEG-2 Layer III, 8 kbps, 22050 Hz, mono, no pad. len=26
<f_v2_l3_min> ::= b'\xff\xf3\x10\xc0' <byte>{22}

# 4) MPEG-2.5 Layer III, 160 kbps, 11025 Hz, joint-stereo. len=1044
<f_v25_l3> ::= b'\xff\xe3\xe0\x40' <byte>{1040}

# 5) MPEG-1 Layer I, 448 kbps, 32000 Hz, dual-channel. len=672
<f_v1_l1_max> ::= b'\xff\xff\xe8\x80' <byte>{668}

# 6) MPEG-1 Layer II, 384 kbps, 44100 Hz, stereo, pad+private, emphasis 50/15us.
#    len=1254
<f_v1_l2_max> ::= b'\xff\xfd\xe3\x01' <byte>{1250}

# 7) MPEG-1 Layer III, 128 kbps, 44100 Hz, mono, CCITT emphasis, with a CRC.
#    Protection bit = 0 -> 16-bit CRC follows the header, then 17-byte L3
#    mono side information, then main data.  len=417.
<f_v1_l3_crc> ::= b'\xff\xfa\x90\xc3' <crc7> <si7> <byte>{394}
where bytes(<crc7>) == crc16_mp3(b'\x90\xc3' + bytes(<si7>))
<crc7> ::= <byte>{2}
<si7>  ::= <byte>{17}

# 8) MPEG-1 Layer III, 320 kbps, 48000 Hz, stereo, RESERVED emphasis (10).
#    len=960
<f_emph_reserved> ::= b'\xff\xfb\xe4\x02' <byte>{956}

# ID3v1.1 trailer (128 bytes):
#   "TAG" title[30] artist[30] album[30] year[4] comment[28] 0x00 track genre

<id3v1> ::= b'TAG' <byte>{30} <byte>{30} <byte>{30} <byte>{4} \
            <byte>{28} b'\x00' <byte> <byte>

<byte> ::= rb'[\x00-\xff]'
