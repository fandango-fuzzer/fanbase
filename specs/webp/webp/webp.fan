# WebP (RIFF): lossless, lossy, extended with alpha, animated (one and three
# frames), and a file with metadata chunks. The image data are real 2x2
# encodings; what varies is the container (flags, ALPH header, frame durations,
# loop count, ...). The size is fixed per layout and checked with a where clause.
#
# TODO:
# * Check which constant string bytes are fixed and which are variable.
# * Introduce helper functions for similar constraints.

<start> ::= <webp_file>;
<webp_file> ::= <simple_lossless_file> | <simple_lossy_file> | <extended_alpha_file> | <animation_file> | <deep_animation_file> | <metadata_file>;

# RIFF sizes are checked against the WebP body of each layout, one constraint
# per layout.
<simple_lossless_file> ::= b"RIFF" <size_28> b"WEBP" <simple_lossless_body>;
<simple_lossy_file> ::= b"RIFF" <size_60> b"WEBP" <simple_lossy_body>;
<extended_alpha_file> ::= b"RIFF" <size_92> b"WEBP" <extended_alpha_body>;
<animation_file> ::= b"RIFF" <size_84> b"WEBP" <animation_body>;
<deep_animation_file> ::= b"RIFF" <size_180> b"WEBP" <deep_animation_body>;
<metadata_file> ::= b"RIFF" <size_264> b"WEBP" <metadata_body>;
where ord(str(<size_28>)[0]) + 256 * ord(str(<size_28>)[1]) + 65536 * ord(str(<size_28>)[2]) + 16777216 * ord(str(<size_28>)[3]) == 4 + len(str(<simple_lossless_body>));
where ord(str(<size_60>)[0]) + 256 * ord(str(<size_60>)[1]) + 65536 * ord(str(<size_60>)[2]) + 16777216 * ord(str(<size_60>)[3]) == 4 + len(str(<simple_lossy_body>));
where ord(str(<size_92>)[0]) + 256 * ord(str(<size_92>)[1]) + 65536 * ord(str(<size_92>)[2]) + 16777216 * ord(str(<size_92>)[3]) == 4 + len(str(<extended_alpha_body>));
where ord(str(<size_84>)[0]) + 256 * ord(str(<size_84>)[1]) + 65536 * ord(str(<size_84>)[2]) + 16777216 * ord(str(<size_84>)[3]) == 4 + len(str(<animation_body>));
where ord(str(<size_180>)[0]) + 256 * ord(str(<size_180>)[1]) + 65536 * ord(str(<size_180>)[2]) + 16777216 * ord(str(<size_180>)[3]) == 4 + len(str(<deep_animation_body>));
where ord(str(<size_264>)[0]) + 256 * ord(str(<size_264>)[1]) + 65536 * ord(str(<size_264>)[2]) + 16777216 * ord(str(<size_264>)[3]) == 4 + len(str(<metadata_body>));

<size_28> ::= b"\x1c\x00\x00\x00";
<size_60> ::= b"\x3c\x00\x00\x00";
<size_92> ::= b"\x5c\x00\x00\x00";
<size_84> ::= b"\x54\x00\x00\x00";
<size_180> ::= b"\xb4\x00\x00\x00";
<size_264> ::= b"\x08\x01\x00\x00";

# Legacy/simple encodings: exactly one VP8 or VP8L image chunk.
<simple_lossless_body> ::= <vp8l_chunk>;
<simple_lossy_body> ::= <vp8_chunk>;
<vp8l_chunk> ::= b"VP8L" b"\x0f\x00\x00\x00" <vp8l_payload> b"\x00";
<vp8l_payload> ::= b"\x2f\x01\x40\x00\x00\x07\x10\xe5\x8f\xfe\x07\x22\xa2\xff\x01";
<vp8_chunk> ::= b"VP8 " b"\x30\x00\x00\x00" <vp8_payload>;
<vp8_payload> ::= b"\xd0\x01\x00\x9d\x01\x2a\x02\x00\x02\x00\x02\x00\x34\x25\xa0\x02\x74\xba\x01\xf8\x00\x03\xb0\x00\xfe\xf0\xe8\xf7\xff\x20\xb9\x61\x75\xc8\xd7\xff\x20\x3f\xe3\x2a\x7c\x65\x4f\xf8\xf2\x00\x00\x00";

# Extended still image with raw alpha. The ALPH header alternatives cover all
# four filters, preprocessing on/off, and edge-valued alpha samples.
<extended_alpha_body> ::= <vp8x_alpha> <alph_chunk> <vp8_chunk>;
<vp8x_alpha> ::= b"VP8X" b"\x0a\x00\x00\x00" b"\x10\x00\x00\x00" <canvas_2x2>;
<canvas_2x2> ::= b"\x01\x00\x00\x01\x00\x00";
<alph_chunk> ::= b"ALPH" b"\x05\x00\x00\x00" <alpha_header> <alpha_plane> b"\x00";
<alpha_header> ::= b"\x00" | b"\x04" | b"\x08" | b"\x0c" | b"\x10" | b"\x14" | b"\x18" | b"\x1c";
<alpha_plane> ::= b"\x00\x40\x80\xff" | b"\xff\x80\x40\x00" | b"\x00\x00\xff\xff";

# Animation is bounded at one or three frames. Zero and maximum duration,
# infinite and maximum loop count, blending, and disposal flags are covered.
<animation_body> ::= <vp8x_animation> <anim_chunk> <anmf_chunk>;
<deep_animation_body> ::= <vp8x_animation> <anim_chunk> <anmf_chunk> <anmf_chunk> <anmf_chunk>;
<vp8x_animation> ::= b"VP8X" b"\x0a\x00\x00\x00" b"\x02\x00\x00\x00" <canvas_2x2>;
<anim_chunk> ::= b"ANIM" b"\x06\x00\x00\x00" <background_bgra> <loop_count>;
<background_bgra> ::= b"\x00\x00\x00\x00" | b"\xff\xff\xff\xff" | b"\x00\x00\xff\x80";
<loop_count> ::= b"\x00\x00" | b"\x01\x00" | b"\xff\xff";
<anmf_chunk> ::= b"ANMF" b"\x28\x00\x00\x00" <frame_header> <vp8l_chunk>;
<frame_header> ::= <frame_origin> <frame_extent> <frame_duration> <frame_flags>;
<frame_origin> ::= b"\x00\x00\x00\x00\x00\x00";
<frame_extent> ::= b"\x01\x00\x00\x01\x00\x00";
<frame_duration> ::= b"\x00\x00\x00" | b"\x01\x00\x00" | b"\xff\xff\xff";
<frame_flags> ::= b"\x00" | b"\x01" | b"\x02" | b"\x03";

# Extended metadata layout follows canonical chunk ordering. It combines an
# ICC v4 monitor profile, little-endian empty TIFF/Exif data, XMP, an image,
# and one legal unknown RIFF chunk (readers must ignore unknown chunks).
<metadata_body> ::= <vp8x_metadata> <iccp_chunk> <exif_chunk> <xmp_chunk> <vp8l_chunk> <private_chunk>;
<vp8x_metadata> ::= b"VP8X" b"\x0a\x00\x00\x00" b"\x2c\x00\x00\x00" <canvas_2x2>;
<iccp_chunk> ::= b"ICCP" b"\x84\x00\x00\x00" <icc_profile>;
<icc_profile> ::= <icc_header_1> <icc_header_2> <icc_header_3> <icc_tag_table>;
<icc_header_1> ::= b"\x00\x00\x00\x84\x00\x00\x00\x00\x04\x30\x00\x00mntrRGB XYZ ";
<icc_header_2> ::= b"\x07\xea\x00\x08\x00\x05\x00\x0c\x00\x00\x00\x00acspAPPL\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
<icc_header_3> ::= b"\x00\x00\x00\x00\x00\x00\xf6\xd6\x00\x01\x00\x00\x00\x00\xd3\x2dFAN0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
<icc_tag_table> ::= b"\x00\x00\x00\x00";
<exif_chunk> ::= b"EXIF" b"\x0e\x00\x00\x00" <minimal_tiff>;
<minimal_tiff> ::= b"II\x2a\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00";
<xmp_chunk> ::= b"XMP " <xmp_size> b"\x00\x00\x00" <xmp_packet> b"\x00";
<xmp_size> ::= b"\x23";
<xmp_packet> ::= b"<x:x xmlns:x='urn:x'>" <nonce> b"</x:x>";
<nonce> ::= rb'[A-Z0-9]{8}';
<private_chunk> ::= b"FUZ0" <private_size> b"\x00\x00\x00" <private_payload>;
<private_size> ::= b"\x04";
<private_payload> ::= rb'[A-Za-z0-9]{4}';
where ord(str(<xmp_size>)) == len(str(<xmp_packet>));
where ord(str(<private_size>)) == len(str(<private_payload>));
