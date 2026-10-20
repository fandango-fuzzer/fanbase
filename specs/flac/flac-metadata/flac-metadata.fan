# STREAMINFO and up to five more metadata blocks of any type (reserved type
# 126 included), the last one flagged, then no frame or one complete frame:
# mono CONSTANT, VERBATIM, FIXED (orders 0 and 4), LPC (orders 1 and 32) or
# with wasted bits, or stereo independent, left/side, right/side or
# mid/side. Blocks and frames are literals with their lengths and CRCs
# worked out, so what varies is which of them a file has, and in what order.
#
# TODO:
# * One frame per file, of 16 to 64 samples at 8 kHz and 8 bits.

<start> ::= <flac_file>

<flac_file> ::= b"fLaC" <metadata_only_chain> | b"fLaC" <mono_audio_chain> <mono_frame> | b"fLaC" <stereo_audio_chain> <stereo_frame>

# STREAMINFO is mandatory and first.  A one-block file uses its last flag;
# longer chains place the last flag only on the final metadata block.
<metadata_only_chain> ::= <streaminfo_last_general> | <streaminfo_nonlast_general> <metadata_nonlast>{0,4} <metadata_last>
<mono_audio_chain> ::= <streaminfo_last_mono> | <streaminfo_nonlast_mono> <metadata_nonlast>{0,4} <metadata_last>
<stereo_audio_chain> ::= <streaminfo_last_stereo> | <streaminfo_nonlast_stereo> <metadata_nonlast>{0,4} <metadata_last>

<streaminfo_last_general> ::= b"\x80\x00\x00\x22" <streaminfo_general_payload>
<streaminfo_nonlast_general> ::= b"\x00\x00\x00\x22" <streaminfo_general_payload>
<streaminfo_last_mono> ::= b"\x80\x00\x00\x22" <streaminfo_mono_payload>
<streaminfo_nonlast_mono> ::= b"\x00\x00\x00\x22" <streaminfo_mono_payload>
<streaminfo_last_stereo> ::= b"\x80\x00\x00\x22" <streaminfo_stereo_payload>
<streaminfo_nonlast_stereo> ::= b"\x00\x00\x00\x22" <streaminfo_stereo_payload>

# STREAMINFO when there is no frame: small blocks, CD audio, or the largest
# block size, sample rate, channel count and sample size. Total samples and
# MD5 are zero (unknown).
<streaminfo_general_payload> ::= b"\x00\x10\x00\x10\x00\x00\x00\x00\x00\x00\x01\xf4\x00\x70\x00\x00\x00\x00" b"\x00"{16} | b"\x00\x10\xff\xff\x00\x00\x00\xff\xff\xff\x9f\xff\x6f\xf0\x00\x00\x00\x00" b"\x00"{16} | b"\x01\x00\x10\x00\x00\x00\x00\x00\x00\x00\x0a\xc4\x42\xf0\x00\x00\x00\x00" b"\x00"{16}

# With a frame: 16 to 64 samples per block, 8 kHz, 8 bits
<streaminfo_mono_payload> ::= b"\x00\x10\x00\x40\x00\x00\x00\x00\x00\x00\x01\xf4\x00\x70\x00\x00\x00\x00" b"\x00"{16}
<streaminfo_stereo_payload> ::= b"\x00\x10\x00\x10\x00\x00\x00\x00\x00\x00\x01\xf4\x02\x70\x00\x00\x00\x00" b"\x00"{16}

<metadata_nonlast> ::= <padding_nonlast> | <application_nonlast> | <seektable_nonlast> | <vorbis_comment_nonlast> | <cuesheet_nonlast> | <picture_nonlast> | <reserved_nonlast>
<metadata_last> ::= <padding_last> | <application_last> | <seektable_last> | <vorbis_comment_last> | <cuesheet_last> | <picture_last> | <reserved_last>

# PADDING: 0, 1, 16 or 255 bytes
<padding_nonlast> ::= b"\x01\x00\x00\x00" | b"\x01\x00\x00\x01\x00" | b"\x01\x00\x00\x10" b"\x00"{16} | b"\x01\x00\x00\xff" b"\x00"{255}
<padding_last> ::= b"\x81\x00\x00\x00" | b"\x81\x00\x00\x01\x00" | b"\x81\x00\x00\x10" b"\x00"{16} | b"\x81\x00\x00\xff" b"\x00"{255}

# APPLICATION: a few ids, with no data or with 8 bytes
<application_nonlast> ::= b"\x02\x00\x00\x04" <application_id> | b"\x02\x00\x00\x0c" <application_id> <application_data>
<application_last> ::= b"\x82\x00\x00\x04" <application_id> | b"\x82\x00\x00\x0c" <application_id> <application_data>
<application_id> ::= b"FAN0" | b"riff" | b"aiff" | b"\x00\x00\x00\x00"
<application_data> ::= b"\x00\x01\x02\x03\xfc\xfd\xfe\xff" | b"legacy00"

# SEEKTABLE: a seek point, a placeholder (sample number all ones), or both
<seektable_nonlast> ::= b"\x03\x00\x00\x12" <seekpoint_real> | b"\x03\x00\x00\x12" <seekpoint_placeholder> | b"\x03\x00\x00\x24" <seekpoint_real> <seekpoint_placeholder>
<seektable_last> ::= b"\x83\x00\x00\x12" <seekpoint_real> | b"\x83\x00\x00\x12" <seekpoint_placeholder> | b"\x83\x00\x00\x24" <seekpoint_real> <seekpoint_placeholder>
<seekpoint_real> ::= b"\x00"{16} b"\x00\x10"
<seekpoint_placeholder> ::= b"\xff"{8} b"\x00"{10}

# VORBIS_COMMENT (little-endian lengths): empty, or a vendor and an empty TITLE
<vorbis_comment_nonlast> ::= b"\x04\x00\x00\x08" <vorbis_empty> | b"\x04\x00\x00\x1a" <vorbis_named>
<vorbis_comment_last> ::= b"\x84\x00\x00\x08" <vorbis_empty> | b"\x84\x00\x00\x1a" <vorbis_named>
<vorbis_empty> ::= b"\x00\x00\x00\x00\x00\x00\x00\x00"
<vorbis_named> ::= b"\x08\x00\x00\x00Fandango\x01\x00\x00\x00\x06\x00\x00\x00TITLE="

# CUESHEET: not a CD, with only the lead-out track (170); 432 bytes
<cuesheet_nonlast> ::= b"\x05\x00\x01\xb0" <cuesheet_payload>
<cuesheet_last> ::= b"\x85\x00\x01\xb0" <cuesheet_payload>
<cuesheet_payload> ::= b"\x00"{128} b"\x00"{8} b"\x00" b"\x00"{258} b"\x01" <leadout_track>
<leadout_track> ::= b"\x00"{8} b"\xaa" b"\x00"{12} b"\x00" b"\x00"{13} b"\x00"

# PICTURE given as a URL (MIME type "-->"), so width, height, depth and
# colours are zero
<picture_nonlast> ::= b"\x06\x00\x00\x2c" <picture_url_payload>
<picture_last> ::= b"\x86\x00\x00\x2c" <picture_url_payload>
<picture_url_payload> ::= b"\x00\x00\x00\x03\x00\x00\x00\x03-->\x00\x00\x00\x00" b"\x00"{16} b"\x00\x00\x00\x09https://x"

# Reserved types (7 to 126) are to be skipped by readers: type 126, empty or
# with one byte. Type 127 is invalid, and not made.
<reserved_nonlast> ::= b"\x7e\x00\x00\x00" | b"\x7e\x00\x00\x01\xa5"
<reserved_last> ::= b"\xfe\x00\x00\x00" | b"\xfe\x00\x00\x01\xa5"

# Complete frames (fixed block size, frame number 0): header, CRC-8, one or
# two subframes, padding to a byte, CRC-16
<mono_frame> ::= <constant_frame> | <verbatim_frame> | <fixed0_frame> | <fixed4_frame> | <lpc1_frame> | <lpc32_frame> | <wasted_bits_frame>
<stereo_frame> ::= <independent_stereo_frame> | <left_side_frame> | <right_side_frame> | <mid_side_frame>

<constant_frame> ::= b"\xff\xf8\x64\x02\x00\x0f\x49\x00\x00\xfb\xea"
<verbatim_frame> ::= b"\xff\xf8\x64\x02\x00\x0f\x49\x02\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff\x00\x01\x02\x03\x04\x05\x06\x07\xcf\x29"
<fixed0_frame> ::= b"\xff\xf8\x64\x02\x00\x0f\x49\x10\x00\x3f\xff\xc0\xf4\x53"
<fixed4_frame> ::= b"\xff\xf8\x64\x02\x00\x0f\x49\x18\x00\x00\x00\x00\x00\xe2\x22\x22\x22\x22\x22\x00\x25\x7c"
<lpc1_frame> ::= b"\xff\xf8\x64\x02\x00\x0f\x49\x40\x00\x00\x10\x07\xff\xf0\x25\xa0"
<lpc32_frame> ::= b"\xff\xf8\x64\x02\x00\x3f\xd9\x7e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x0f\xff\xff\xf0\x79\x56"
<wasted_bits_frame> ::= b"\xff\xf8\x64\x02\x00\x0f\x49\x01\x02\xfd\xe6"

<independent_stereo_frame> ::= b"\xff\xf8\x64\x12\x00\x0f\xeb\x00\x00\x00\x00\xab\xe5"
<left_side_frame> ::= b"\xff\xf8\x64\x82\x00\x0f\x42\x00\x00\x00\x00\x00\x00\x88\x53"
<right_side_frame> ::= b"\xff\xf8\x64\x92\x00\x0f\xe0\x00\x00\x00\x00\x00\x00\x1e\xf9"
<mid_side_frame> ::= b"\xff\xf8\x64\xa2\x00\x0f\x01\x00\x00\x00\x00\x00\x00\xcc\x17"
