# Same as wav, with values taken from the edges of what the format allows:
# eight fmt layouts (1 Hz and 192 kHz, 8 to 32 bits, IEEE float, A-law,
# mu-law, 18 channels), every loop type of smpl including an undefined one,
# and a random bext.
#
# TODO:
# * Like wav, data is not a whole number of blocks, so FFmpeg rejects
#   about half the files.

<start> ::= b'RIFF' <riff_size> <wave>
where <riff_size> == len(bytes(<wave>)).to_bytes(4, 'little')

<wave> ::= b'WAVE' <fmt> <fact> <data> <cue> <smpl> <list> <bext> <junk>

# fmt (16 bytes). Each layout is written out with nBlockAlign = channels *
# bits / 8 and nAvgBytesPerSec = rate * nBlockAlign.
<fmt> ::= b'fmt ' <fmt_size> <fmt_body>
where <fmt_size> == len(bytes(<fmt_body>)).to_bytes(4, 'little')

<fmt_body> ::= (
      b'\x01\x00\x01\x00\x40\x1f\x00\x00\x40\x1f\x00\x00\x01\x00\x08\x00'   # PCM  8-bit mono 8000
    | b'\x01\x00\x02\x00\x44\xac\x00\x00\x10\xb1\x02\x00\x04\x00\x10\x00'   # PCM 16-bit stereo 44100
    | b'\x01\x00\x02\x00\x00\x77\x01\x00\x00\xca\x08\x00\x06\x00\x18\x00'   # PCM 24-bit stereo 96000
    | b'\x03\x00\x01\x00\x00\xee\x02\x00\x00\xb8\x0b\x00\x04\x00\x20\x00'   # IEEE float 32-bit mono 192000
    | b'\x01\x00\x01\x00\x01\x00\x00\x00\x02\x00\x00\x00\x02\x00\x10\x00'   # PCM 16-bit mono sr=1 (min)
    | b'\x06\x00\x01\x00\x40\x1f\x00\x00\x40\x1f\x00\x00\x01\x00\x08\x00'   # A-law 8-bit mono 8000
    | b'\x07\x00\x01\x00\x40\x1f\x00\x00\x40\x1f\x00\x00\x01\x00\x08\x00'   # mu-law 8-bit mono 8000
    | b'\x01\x00\x12\x00\x80\xbb\x00\x00\x00\x5e\x1a\x00\x24\x00\x10\x00'   # PCM 16-bit 18ch 48000
    )

# fact (dwSampleLength)
<fact> ::= b'fact' <fact_size> <fact_body>
where <fact_size> == len(bytes(<fact_body>)).to_bytes(4, 'little')
<fact_body> ::= <dword>

# data
<data> ::= b'data' <data_size> <data_body>
where <data_size> == len(bytes(<data_body>)).to_bytes(4, 'little')
<data_body> ::= <spair>{1,64}

# cue (playlist cue points, 24 bytes each)
<cue> ::= b'cue ' <cue_size> <cue_count> <cue_points>
where <cue_count> == (len(bytes(<cue_points>)) // 24).to_bytes(4, 'little')
where <cue_size> == len(bytes(<cue_count>) + bytes(<cue_points>)).to_bytes(4, 'little')
<cue_points> ::= <cue_point>{1,4}
<cue_point> ::= <dword> <dword> b'data' <dword> <dword> <dword>

# smpl (sampler / loops)
<smpl> ::= b'smpl' <smpl_size> <smpl_hdr> <smpl_loops>
where <smpl_size> == len(bytes(<smpl_hdr>) + bytes(<smpl_loops>)).to_bytes(4, 'little')
where <smpl_num_loops> == (len(bytes(<smpl_loops>)) // 24).to_bytes(4, 'little')
<smpl_hdr> ::= <dword> <dword> <dword> <dword> <dword> <dword> <dword> <smpl_num_loops> <dword>
<smpl_num_loops> ::= <dword>
<smpl_loops> ::= <smpl_loop>{1,3}
<smpl_loop> ::= <dword> <loop_type> <dword> <dword> <dword> <dword>
<loop_type> ::= (
      b'\x00\x00\x00\x00'    # forward
    | b'\x01\x00\x00\x00'    # alternating (ping-pong)
    | b'\x02\x00\x00\x00'    # backward
    | b'\xff\xff\xff\xff'    # undefined
    )

# LIST / INFO
<list> ::= b'LIST' <list_size> b'INFO' <info_items>
where <list_size> == len(b'INFO' + bytes(<info_items>)).to_bytes(4, 'little')
<info_items> ::= <info_item>{1,6}
<info_item> ::= <info_id> <info_isize> <info_text>
where <info_isize> == len(bytes(<info_text>)).to_bytes(4, 'little')
<info_id> ::= (
      b'IART' | b'INAM' | b'ICMT' | b'ISFT' | b'IGNR'
    | b'ICRD' | b'ICOP' | b'IPRD' | b'IKEY' | b'IENG'
    )
<info_text> ::= <apair>{1,12} <info_null>
<info_null> ::= b'\x00\x00'

# bext (Broadcast Extension core, fixed 602 bytes)
<bext> ::= b'bext' <bext_size> <bext_body>
where <bext_size> == len(bytes(<bext_body>)).to_bytes(4, 'little')
<bext_body> ::= <byte>{602}

# JUNK (filler)
<junk> ::= b'JUNK' <junk_size> <junk_body>
where <junk_size> == len(bytes(<junk_body>)).to_bytes(4, 'little')
<junk_body> ::= <spair>{1,32}

# size fields
<riff_size> ::= <dword>
<fmt_size>  ::= <dword>
<fact_size> ::= <dword>
<data_size> ::= <dword>
<cue_size>  ::= <dword>
<cue_count> ::= <dword>
<smpl_size> ::= <dword>
<list_size> ::= <dword>
<info_isize> ::= <dword>
<bext_size> ::= <dword>
<junk_size> ::= <dword>

# primitives
<dword> ::= <byte> <byte> <byte> <byte>
<spair> ::= <byte> <byte>
<apair> ::= <achar> <achar>
<byte>  ::= rb'[\x00-\xff]'
<achar> ::= rb'[\x20-\x7e]'
