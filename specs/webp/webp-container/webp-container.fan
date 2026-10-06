# WebP as a RIFF container, all five file shapes: simple lossy, simple
# lossless, extended lossy with ICCP, ALPH, EXIF and XMP, extended lossless,
# and animated with ANIM and ANMF. The canvas is 64x64 everywhere and chunk
# sizes are tied to their payload with where clauses. The VP8 and VP8L data
# are filler bytes, so the files do not decode.
#
# TODO:
# * Check for redundant defs (say, *_size fields or to_byte() calls)
# * Merge with the other `webp.fan` specifications.

<start> ::= <webp>

# primitive value fields
<byte>  ::= rb'[\x00-\xff]'
<u16>   ::= <byte> <byte>
<u32>   ::= <byte> <byte> <byte> <byte>
<bpair> ::= <byte> <byte>

# dedicated 4-byte size fields (one per referencing production)
<riff_size> ::= <byte> <byte> <byte> <byte>
<iccp_size> ::= <byte> <byte> <byte> <byte>
<alph_size> ::= <byte> <byte> <byte> <byte>
<vp8_size>  ::= <byte> <byte> <byte> <byte>
<vp8l_size> ::= <byte> <byte> <byte> <byte>
<exif_size> ::= <byte> <byte> <byte> <byte>
<xmp_size>  ::= <byte> <byte> <byte> <byte>
<anmf_size> ::= <byte> <byte> <byte> <byte>

# Top-level RIFF/WEBP container.
# size = len('WEBP' + chunks) = everything after the 4-byte size field.
<webp> ::= b'RIFF' <riff_size> <riff_content>
where <riff_size> == len(bytes(<riff_content>)).to_bytes(4, 'little')

<riff_content> ::= b'WEBP' <chunks>

# The five canonical WebP file shapes.
<chunks> ::= <lossy> \
           | <lossless> \
           | <ext_lossy> \
           | <ext_lossless> \
           | <animated>

# Simple file format - lossy:  a single 'VP8 ' chunk.
<lossy> ::= <vp8_chunk>

# Simple file format - lossless:  a single 'VP8L' chunk.
<lossless> ::= <vp8l_chunk>

# Extended file format - still image, lossy with an alpha channel.
# VP8X flags = ICC(0x20) | Alpha(0x10) | Exif(0x08) | XMP(0x04) = 0x3C.
<ext_lossy> ::= <vp8x_lossy> <iccp_chunk> <alph_chunk> <vp8_chunk> \
                <exif_chunk> <xmp_chunk>

# VP8X: 'VP8X' + size(10) + flags(1) + reserved(3) + canvasW-1(3) + canvasH-1(3)
<vp8x_lossy> ::= b'VP8X' b'\x0a\x00\x00\x00' \
                 b'\x3c\x00\x00\x00\x3f\x00\x00\x3f\x00\x00'

# Extended file format - still image, lossless.
# VP8X flags = ICC(0x20) | Exif(0x08) | XMP(0x04) = 0x2C.
<ext_lossless> ::= <vp8x_lossless> <iccp_chunk> <vp8l_chunk> \
                   <exif_chunk> <xmp_chunk>

<vp8x_lossless> ::= b'VP8X' b'\x0a\x00\x00\x00' \
                    b'\x2c\x00\x00\x00\x3f\x00\x00\x3f\x00\x00'

# Extended file format - animated.
# VP8X flags = ICC(0x20) | Exif(0x08) | XMP(0x04) | Animation(0x02) = 0x2E.
# 1..3 animation frames, each carrying an alpha chunk + a lossy image.
<animated> ::= <vp8x_anim> <iccp_chunk> <anim_chunk> <anmf_chunk>{1,3} \
               <exif_chunk> <xmp_chunk>

<vp8x_anim> ::= b'VP8X' b'\x0a\x00\x00\x00' \
                b'\x2e\x00\x00\x00\x3f\x00\x00\x3f\x00\x00'

# 'ANIM' global animation parameters (fixed 6-byte payload)
# Background colour (BGRA, 4 bytes) + loop count (u16 LE).
<anim_chunk> ::= b'ANIM' b'\x06\x00\x00\x00' <u32> <u16>

# 'ANMF' animation frame
# 16-byte header (X, Y, W-1, H-1, duration : 24-bit LE each; flags byte) then
# an embedded image chunk. size ties to the whole payload length.
<anmf_chunk> ::= b'ANMF' <anmf_size> <anmf_payload>
where <anmf_size> == len(bytes(<anmf_payload>)).to_bytes(4, 'little')

<anmf_payload> ::= <anmf_header> <anmf_framedata>

<anmf_header> ::= b'\x00\x00\x00\x00\x00\x00\x3f\x00\x00\x3f\x00\x00\x64\x00\x00\x00'

<anmf_framedata> ::= <alph_chunk> <vp8_chunk> \
                   | <vp8l_chunk>

# 'VP8 ' - lossy VP8 key-frame chunk.
# 10-byte header: frame-tag(3) + start-code 9d 01 2a + width(2) + height(2),
# encoding a 64x64 key-frame with first_partition_size = 8; then bitstream
# body (kept even, >= first_partition_size bytes).
<vp8_chunk> ::= b'VP8 ' <vp8_size> <vp8_payload>
where <vp8_size> == len(bytes(<vp8_payload>)).to_bytes(4, 'little')

<vp8_payload> ::= <vp8_header> <vp8_data>
<vp8_header>  ::= b'\x10\x01\x00\x9d\x01\x2a\x40\x00\x40\x00'
<vp8_data>    ::= <bpair>{4,16}

# 'VP8L' - lossless VP8L chunk.
# 5-byte header: signature 0x2f + 32 bits packing width-1(14) | height-1(14)
# | alpha(1) | version(3)  =>  64x64, no alpha, version 0.
# Body kept so the total payload length stays even.
<vp8l_chunk> ::= b'VP8L' <vp8l_size> <vp8l_payload>
where <vp8l_size> == len(bytes(<vp8l_payload>)).to_bytes(4, 'little')

<vp8l_payload> ::= <vp8l_header> <vp8l_data>
<vp8l_header>  ::= b'\x2f\x3f\xc0\x0f\x00'
<vp8l_data>    ::= <byte> <bpair>{1,8}

# 'ALPH' - alpha channel chunk.
# 1 flags byte (Rsv 2 | pre-processing 2 | filtering 2 | compression 2 = 0x00,
# uncompressed) followed by raw alpha samples; length kept even.
<alph_chunk> ::= b'ALPH' <alph_size> <alph_payload>
where <alph_size> == len(bytes(<alph_payload>)).to_bytes(4, 'little')

<alph_payload> ::= b'\x00' <byte> <bpair>{1,8}

# 'ICCP' / 'EXIF' / 'XMP ' - variable-length metadata chunks.
# Each length field equals the byte length of its payload; payloads are
# emitted in 2-byte pairs so every chunk length is even.
<iccp_chunk> ::= b'ICCP' <iccp_size> <iccp_data>
where <iccp_size> == len(bytes(<iccp_data>)).to_bytes(4, 'little')
<iccp_data> ::= <bpair>{2,16}

<exif_chunk> ::= b'EXIF' <exif_size> <exif_data>
where <exif_size> == len(bytes(<exif_data>)).to_bytes(4, 'little')
<exif_data> ::= <bpair>{2,16}

<xmp_chunk> ::= b'XMP ' <xmp_size> <xmp_data>
where <xmp_size> == len(bytes(<xmp_data>)).to_bytes(4, 'little')
<xmp_data> ::= <bpair>{2,16}
