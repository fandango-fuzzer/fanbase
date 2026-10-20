# WAVE (RIFF, little-endian): a 16-byte fmt chunk followed by fact, data,
# cue, smpl, LIST/INFO, bext and JUNK. The RIFF size, every chunk size and
# the cue and loop counts are tied to the bytes they describe with where
# constraints.
#
# TODO:
# * fmt is one of five fixed PCM/float layouts, and data is not a whole
#   number of blocks (nBlockAlign), so FFmpeg rejects about half the files.
# * The chunks always come in the same order, and all of them are there.

<start> ::= b'RIFF' <riff_size> <wave_body>
where <riff_size> == len(bytes(<wave_body>)).to_bytes(4, 'little')

<wave_body> ::= b'WAVE' <fmt_chunk> <fact_chunk> <data_chunk> <cue_chunk> <smpl_chunk> <list_chunk> <bext_chunk> <junk_chunk>

# fmt: wFormatTag nChannels nSamplesPerSec nAvgBytesPerSec nBlockAlign
# wBitsPerSample (PCMWAVEFORMAT, 16 bytes)
<fmt_chunk> ::= b'fmt ' b'\x10\x00\x00\x00' <fmt_body>
<fmt_body> ::= <fmt_pcm8_mono_8k> | <fmt_pcm16_mono_22k> | <fmt_pcm16_stereo_44k> | <fmt_pcm24_mono_48k> | <fmt_float32_stereo_48k>

# PCM  8-bit  mono   8000 Hz  -> blockAlign 1, avg 8000
<fmt_pcm8_mono_8k> ::= b'\x01\x00\x01\x00\x40\x1f\x00\x00\x40\x1f\x00\x00\x01\x00\x08\x00'
# PCM 16-bit  mono  22050 Hz  -> blockAlign 2, avg 44100
<fmt_pcm16_mono_22k> ::= b'\x01\x00\x01\x00\x22\x56\x00\x00\x44\xac\x00\x00\x02\x00\x10\x00'
# PCM 16-bit  stereo 44100 Hz -> blockAlign 4, avg 176400
<fmt_pcm16_stereo_44k> ::= b'\x01\x00\x02\x00\x44\xac\x00\x00\x10\xb1\x02\x00\x04\x00\x10\x00'
# PCM 24-bit  mono  48000 Hz  -> blockAlign 3, avg 144000
<fmt_pcm24_mono_48k> ::= b'\x01\x00\x01\x00\x80\xbb\x00\x00\x80\x32\x02\x00\x03\x00\x18\x00'
# IEEE float 32-bit stereo 48000 Hz -> tag 3, blockAlign 8, avg 384000
<fmt_float32_stereo_48k> ::= b'\x03\x00\x02\x00\x80\xbb\x00\x00\x00\xdc\x05\x00\x08\x00\x20\x00'

# fact
<fact_chunk> ::= b'fact' b'\x04\x00\x00\x00' <u32>

# data
<data_chunk> ::= b'data' <data_size> <samples>
where <data_size> == len(bytes(<samples>)).to_bytes(4, 'little')
<samples> ::= <spair>{1,32}

# cue: dwCuePoints, then that many 24-byte cue points
<cue_chunk> ::= b'cue ' <cue_size> <cue_count> <cue_points>
where <cue_size> == (len(bytes(<cue_count>)) + len(bytes(<cue_points>))).to_bytes(4, 'little')
<cue_points> ::= <cue_point>{1,4}
<cue_point> ::= <u32> <u32> b'data' <u32> <u32> <u32>
<cue_count> ::= <c4>
where <c4> == (len(bytes(<cue_points>)) // 24).to_bytes(4, 'little')

# smpl: 36-byte header (9 dwords), then cSampleLoops 24-byte loops
<smpl_chunk> ::= b'smpl' <smpl_size> <smpl_body>
where <smpl_size> == len(bytes(<smpl_body>)).to_bytes(4, 'little')
<smpl_body> ::= <u32> <u32> <u32> <u32> <u32> <u32> <u32> <smpl_loopcount> <u32> <smpl_loops>
<smpl_loops> ::= <smpl_loop>{1,3}
<smpl_loop> ::= <u32> <u32> <u32> <u32> <u32> <u32>
<smpl_loopcount> ::= <c4b>
where <c4b> == (len(bytes(<smpl_loops>)) // 24).to_bytes(4, 'little')

# LIST/INFO
<list_chunk> ::= b'LIST' <list_size> b'INFO' <info_subs>
where <list_size> == (4 + len(bytes(<info_subs>))).to_bytes(4, 'little')
<info_subs> ::= <info_sub>{1,6}
<info_sub> ::= <info_id> <info_size> <info_text>
where <info_size> == len(bytes(<info_text>)).to_bytes(4, 'little')
<info_id> ::= b'IART' | b'INAM' | b'ICMT' | b'ICRD' | b'IGNR' | b'ISFT' | b'IPRD' | b'ICOP' | b'IENG' | b'ISRC' | b'ISBJ' | b'ITCH'
<info_text> ::= <apair>{1,16} b'\x00\x00'

# bext (Broadcast Wave): the 602-byte fixed part, no coding history
<bext_chunk> ::= b'bext' b'\x5a\x02\x00\x00' <bext_body>
<bext_body> ::= <spair>{128} <spair>{16} <spair>{16} <achar>{10} <achar>{8} <u32> <u32> <u16> <spair>{32} <spair>{5} <spair>{90}

# JUNK
<junk_chunk> ::= b'JUNK' <junk_size> <junk_data>
where <junk_size> == len(bytes(<junk_data>)).to_bytes(4, 'little')
<junk_data> ::= <spair>{1,16}

# primitives
<riff_size> ::= <byte> <byte> <byte> <byte>
<data_size> ::= <byte> <byte> <byte> <byte>
<cue_size>  ::= <byte> <byte> <byte> <byte>
<smpl_size> ::= <byte> <byte> <byte> <byte>
<list_size> ::= <byte> <byte> <byte> <byte>
<junk_size> ::= <byte> <byte> <byte> <byte>
<info_size> ::= <byte> <byte> <byte> <byte>
<c4>  ::= <byte> <byte> <byte> <byte>
<c4b> ::= <byte> <byte> <byte> <byte>
<u32> ::= <byte> <byte> <byte> <byte>
<u16> ::= <byte> <byte>
<spair> ::= <byte> <byte>
<apair> ::= <achar> <achar>
<byte>  ::= rb'[\x00-\xff]'
<achar> ::= rb'[\x20-\x7e]'
