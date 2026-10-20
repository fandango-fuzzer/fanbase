# MP3 built around ID3 metadata: an optional leading ID3v2 tag (v2.2, or v2.3
# and v2.4 with extended headers, unsynchronisation, a footer, and CHAP, APIC,
# PRIV and GEOB frames), then one to three MPEG audio frames (MPEG-1, 2 and
# 2.5, Layers I to III, with Xing and VBRI VBR headers), then an optional
# trailing tag (ID3v1, ID3v1.1, an enhanced TAG+ or an APEv2 footer). The tags
# and frames are exact-size literals, so what varies is which of them a file
# has.
#
# TODO:
# * The audio frame bodies are bytes from a small alphabet, not coded audio,
#   so a file mostly exercises the ID3, APE and VBR metadata, not the decoder.

<start> ::= <leading_metadata>? <audio_stream> <trailing_metadata>?

# ID3v2 tags are complete, exact-size alternatives.  The syncsafe tag sizes
# are written to match their bodies rather than solved by a length constraint.
<leading_metadata> ::= <id3v22> | <id3v23_basic> | <id3v23_extended> | <id3v23_unsynchronised> | <id3v24_basic> | <id3v24_extended> | <id3v24_footer> | <id3v24_chapter> | <id3v24_picture> | <id3v24_private>

# ID3v2.2: one TT2 frame; body = 6-byte frame header + 3-byte payload.
<id3v22> ::= b"ID3\x02\x00\x00\x00\x00\x00\x09TT2\x00\x00\x03\x00OK"

# ID3v2.3: one 10-byte frame header plus six payload bytes.
<id3v23_basic> ::= b"ID3\x03\x00\x00\x00\x00\x00\x10TIT2\x00\x00\x00\x06\x00Title"

# v2.3 extended-header size excludes its own four size bytes: 10 + 16 bytes.
<id3v23_extended> ::= b"ID3\x03\x00\x40\x00\x00\x00\x1a\x00\x00\x00\x06\x00\x00\x00\x00\x00\x00TPE1\x00\x00\x00\x06\x00Artist"

# Tag-level unsynchronisation contains the required inserted 00 after FF.
# Body is one binary GEOB frame: 10-byte header plus 4-byte payload.
<id3v23_unsynchronised> ::= b"ID3\x03\x00\x80\x00\x00\x00\x0eGEOB\x00\x00\x00\x04\x00\xff\x00\xe0"

# ID3v2.4 uses syncsafe frame sizes as well as a syncsafe tag size.
<id3v24_basic> ::= b"ID3\x04\x00\x00\x00\x00\x00\x10TALB\x00\x00\x00\x06\x00\x00\x00Album"

# v2.4 minimum extended header is six bytes including its size field.
<id3v24_extended> ::= b"ID3\x04\x00\x40\x00\x00\x00\x16\x00\x00\x00\x06\x01\x00TCON\x00\x00\x00\x06\x00\x00\x00Other"

# Footer is outside the 16-byte tag body and mirrors the v2.4 header.
<id3v24_footer> ::= b"ID3\x04\x00\x10\x00\x00\x00\x10TDRC\x00\x00\x00\x06\x00\x00\x002024!3DI\x04\x00\x10\x00\x00\x00\x10"

# CHAP embeds a TIT2 subframe.  Element id 'c', times 0..1000 ms, no offsets.
# CHAP payload = 18-byte chapter prefix + 16-byte nested TIT2; body = 44 bytes.
<id3v24_chapter> ::= b"ID3\x04\x00\x00\x00\x00\x00\x2cCHAP\x00\x00\x00\x22\x00\x00c\x00\x00\x00\x00\x00\x00\x00\x03\xe8\xff\xff\xff\xff\xff\xff\xff\xffTIT2\x00\x00\x00\x06\x00\x00\x00Intro"

# APIC with MIME image/png, front-cover type, empty description, PNG signature.
# Payload = 21 bytes and tag body = 31 bytes.
<id3v24_picture> ::= b"ID3\x04\x00\x00\x00\x00\x00\x1fAPIC\x00\x00\x00\x15\x00\x00image/png\x00\x03\x00\x89PNG\x0d\x0a\x1a\x0a"

# PRIV carries an owner identifier and three opaque bytes (13-byte payload).
<id3v24_private> ::= b"ID3\x04\x00\x00\x00\x00\x00\x18PRIV\x00\x00\x00\x0e\x00\x00owner.test\x00\x01\x02\x03"

# A short stream is enough for fuzzing while allowing mixed MPEG generations,
# layers, padding modes, channel modes, and VBR signalling.
<audio_stream> ::= <mpeg_frame>{1,3}
<mpeg_frame> ::= <mpeg1_l3> | <mpeg1_l3_padded> | <mpeg1_l3_low_rate> | <mpeg1_l3_high_rate> | <mpeg1_l3_xing> | <mpeg1_l3_vbri> | <mpeg1_l2> | <mpeg1_l1> | <mpeg1_l1_padded> | <mpeg2_l3> | <mpeg2_l3_padded> | <mpeg2_l2> | <mpeg2_l1> | <mpeg25_l3> | <mpeg25_l3_padded> | <mpeg25_l3_low_rate> | <mpeg25_l3_high_rate>

# MPEG-1 Layer III, 128 kbit/s, 44.1 kHz: floor(144*128000/44100).
# Header byte four alternatives exercise stereo/joint/dual/mono and ancillary bits.
<mpeg1_l3> ::= b"\xff\xfb" <mpeg1_l3_rate_flags> <mode_flags> <main_data>{413}
<mpeg1_l3_padded> ::= b"\xff\xfb" <mpeg1_l3_padded_flags> <mode_flags> <main_data>{414}

# MPEG-1 Layer III bitrate boundaries at 44.1 kHz: 32 and 320 kbit/s.
<mpeg1_l3_low_rate> ::= b"\xff\xfb\x10" <mode_flags> <main_data>{100}
<mpeg1_l3_high_rate> ::= b"\xff\xfb\xe0" <mode_flags> <main_data>{1040}

# Xing/Info-style VBR metadata begins after the 32-byte MPEG-1 stereo side info.
# Flags announce frame and byte counts, kept small and consistent.
<mpeg1_l3_xing> ::= b"\xff\xfb\x90\x00" <zero>{32} b"Xing\x00\x00\x00\x03\x00\x00\x00\x01\x00\x00\x01\xa1" <main_data>{365}

# Fraunhofer VBRI begins 32 bytes after the MPEG header.  Its bounded TOC has
# one entry of one byte, scale one, and one frame per entry.
<mpeg1_l3_vbri> ::= b"\xff\xfb\x90\x00" <zero>{32} b"VBRI\x00\x01\x00\x00\x00\x64\x00\x00\x01\xa1\x00\x00\x00\x01\x00\x01\x00\x01\x00\x01\x00\x01\x01" <main_data>{356}

# MPEG-1 Layer II uses the same 144 coefficient at this rate/sample rate.
<mpeg1_l2> ::= b"\xff\xfd\x80" <mode_flags> <main_data>{413}

# Layer I length is floor(12*128000/44100)*4, with padding adding four bytes.
<mpeg1_l1> ::= b"\xff\xff\x40" <mode_flags> <main_data>{132}
<mpeg1_l1_padded> ::= b"\xff\xff\x42" <mode_flags> <main_data>{136}

# MPEG-2 Layer III, 64 kbit/s, 22.05 kHz uses coefficient 72.
<mpeg2_l3> ::= b"\xff\xf3\x80" <mode_flags> <main_data>{204}
<mpeg2_l3_padded> ::= b"\xff\xf3\x82" <mode_flags> <main_data>{205}

# MPEG-2 Layer II and I, 64 kbit/s at 22.05 kHz.
<mpeg2_l2> ::= b"\xff\xf5\x80" <mode_flags> <main_data>{413}
<mpeg2_l1> ::= b"\xff\xf7\x40" <mode_flags> <main_data>{132}

# MPEG-2.5 Layer III, 32 kbit/s, 11.025 kHz; coefficient 72.
<mpeg25_l3> ::= b"\xff\xe3\x40" <mode_flags> <main_data>{204}
<mpeg25_l3_padded> ::= b"\xff\xe3\x42" <mode_flags> <main_data>{205}

# MPEG-2.5 Layer III boundaries at 8 kHz: 8 and 160 kbit/s.
<mpeg25_l3_low_rate> ::= b"\xff\xe3\x18" <mode_flags> <main_data>{68}
<mpeg25_l3_high_rate> ::= b"\xff\xe3\xe8" <mode_flags> <main_data>{1436}

# The third-byte alternatives toggle the private bit while retaining the exact
# rate/sample/padding combination used by the corresponding frame extent.
<mpeg1_l3_rate_flags> ::= b"\x90" | b"\x91"
<mpeg1_l3_padded_flags> ::= b"\x92" | b"\x93"

# Fourth-byte alternatives cover stereo, joint stereo, dual channel and mono;
# mode extension; copyright/original; 50/15 us and rare CCITT J.17 emphasis.
<mode_flags> ::= b"\x00" | b"\x5c" | b"\xad" | b"\xf3"

# Payload bytes come from a small fixed alphabet: 0x00, 0x55, 0xAA and 0xFF.
<main_data> ::= b"\x00" | b"\x55" | b"\xaa" | b"\xff"
<zero> ::= b"\x00"

# Trailing metadata covers ID3v1.0/1.1, the TAG+ extension, and an APEv2 footer.
<trailing_metadata> ::= <id3v1> | <id3v11> | <tagplus> <id3v1> | <apev2_footer> | <apev2_footer> <id3v11>

# Exactly 128 bytes: TAG, 30 title, 30 artist, 30 album, year, 30 comment, genre.
<id3v1> ::= b"TAG" <space>{30} <space>{30} <space>{30} b"1999" <space>{30} b"\xff"

# ID3v1.1 uses comment[28], zero separator, nonzero track, and genre 17 (Rock).
<id3v11> ::= b"TAG" <space>{30} <space>{30} <space>{30} b"2001" <space>{28} b"\x00\x01\x11"

# Enhanced TAG+: 60 title, 60 artist, 60 album, speed, 30 genre, start/end time.
<tagplus> ::= b"TAG+" <space>{60} <space>{60} <space>{60} b"\x02" <space>{30} b"000000000000"

# APEv2.0 footer-only empty tag: version 2000, size 32, zero items and flags.
<apev2_footer> ::= b"APETAGEX\xd0\x07\x00\x00\x20\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
<space> ::= b" "
