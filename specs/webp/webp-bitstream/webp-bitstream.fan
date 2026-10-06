# WebP with the VP8 and VP8L internals spelled out (frame tag, key frame start
# code, partitions, VP8L transforms, color cache, Huffman groups) plus ALPH,
# ANIM/ANMF, ICCP, EXIF, XMP and junk chunks. Six layouts that all have the
# same total size, so the RIFF size is a constant.
#
# TODO:
# * Check for redundant defs (say, junk* fields)
# * Merge with the other `webp.fan` specifications.

<start> ::= <webp_file>

<webp_file> ::= "RIFF" <riff_size_124> "WEBP" <webp_chunks>
where len(<webp_file>) > 0
<riff_size_124> ::= "\x7c\x00\x00\x00"
<webp_chunks> ::= <simple_lossy_chunks> | <simple_lossless_chunks> | <extended_lossy_chunks> | <extended_lossless_chunks> | <animated_lossy_chunks> | <animated_lossless_chunks>

# Simple-file profiles.
<simple_lossy_chunks> ::= <vp8_chunk> <junk_84_chunk>
<simple_lossless_chunks> ::= <vp8l_chunk> <junk_84_chunk>

# Extended still-image profiles. ALPH precedes VP8; VP8L carries its own alpha.
<extended_lossy_chunks> ::= <vp8x_still_lossy_chunk> <iccp_chunk> <alph_chunk> <vp8_chunk> <exif_chunk> <xmp_chunk> <junk_10_chunk>
<extended_lossless_chunks> ::= <vp8x_still_lossless_chunk> <iccp_chunk> <vp8l_chunk> <exif_chunk> <xmp_chunk> <junk_26_chunk>

# Animated profiles. Frame image subchunks live inside ANMF rather than at top level.
<animated_lossy_chunks> ::= <vp8x_animation_chunk> <anim_chunk> <anmf_lossy_chunk> <junk_12_chunk>
<animated_lossless_chunks> ::= <vp8x_animation_chunk> <anim_chunk> <anmf_lossless_chunk> <junk_28_chunk>

# VP8X: one flags byte, three reserved bytes, and two 24-bit little-endian
# canvas-minus-one values. These files use a 16 by 16 canvas.
<vp8x_still_lossy_chunk> ::= "VP8X" <size_10> <vp8x_still_lossy_payload>
<vp8x_still_lossless_chunk> ::= "VP8X" <size_10> <vp8x_still_lossless_payload>
<vp8x_animation_chunk> ::= "VP8X" <size_10> <vp8x_animation_payload>
<size_10> ::= "\x0a\x00\x00\x00"
<vp8x_still_lossy_payload> ::= <vp8x_flags_still_lossy> <reserved_24> <canvas_width_minus_one> <canvas_height_minus_one>
<vp8x_still_lossless_payload> ::= <vp8x_flags_still_lossless> <reserved_24> <canvas_width_minus_one> <canvas_height_minus_one>
<vp8x_animation_payload> ::= <vp8x_flags_animation> <reserved_24> <canvas_width_minus_one> <canvas_height_minus_one>
<vp8x_flags_still_lossy> ::= "\x3c"
<vp8x_flags_still_lossless> ::= "\x3c"
<vp8x_flags_animation> ::= "\x3e"
<reserved_24> ::= "\x00\x00\x00"
<canvas_width_minus_one> ::= "\x0f\x00\x00"
<canvas_height_minus_one> ::= "\x0f\x00\x00"

<iccp_chunk> ::= "ICCP" <size_4> <iccp_payload>
<iccp_payload> ::= r'[\x00-\x7f]{4}'
<exif_chunk> ::= "EXIF" <size_5> <exif_payload> <riff_pad>
<exif_payload> ::= "Exif\x00"
<xmp_chunk> ::= "XMP " <size_5> <xmp_payload> <riff_pad>
<xmp_payload> ::= "<x/> "
<riff_pad> ::= "\x00"
<size_4> ::= "\x04\x00\x00\x00"
<size_5> ::= "\x05\x00\x00\x00"

# ALPH: bits 0-1 compression, 2-3 filter, 4-5 preprocessing, 6-7 reserved.
# Each legal filter is represented; raw and VP8L-compressed alpha encodings and
# the level-reduction preprocessing mode are represented by header alternatives.
<alph_chunk> ::= "ALPH" <size_8> <alph_payload>
<alph_payload> ::= <alpha_header> <alpha_data>
<alpha_header> ::= <alpha_raw_none> | <alpha_raw_horizontal> | <alpha_raw_vertical> | <alpha_raw_gradient> | <alpha_preprocessed> | <alpha_lossless_compressed>
<alpha_raw_none> ::= "\x00"
<alpha_raw_horizontal> ::= "\x04"
<alpha_raw_vertical> ::= "\x08"
<alpha_raw_gradient> ::= "\x0c"
<alpha_preprocessed> ::= "\x10"
<alpha_lossless_compressed> ::= "\x01"
<alpha_data> ::= r'[\x00-\x7f]{7}'
<size_8> ::= "\x08\x00\x00\x00"

# Animation global parameters: BGRA background and little-endian loop count.
<anim_chunk> ::= "ANIM" <size_6> <anim_payload>
<anim_payload> ::= <background_color> <loop_count>
<background_color> ::= "\x00\x00\x00\x00" | "\x7f\x7f\x7f\x7f"
<loop_count> ::= "\x00\x00" | "\x01\x00"
<size_6> ::= "\x06\x00\x00\x00"

# ANMF rectangle values encode half offsets and dimensions-minus-one. The
# 16x16 frame is at (0,0), lasts 100 ms, and chooses legal dispose/blend flags.
<anmf_lossy_chunk> ::= "ANMF" <size_60> <anmf_lossy_payload>
<anmf_lossless_chunk> ::= "ANMF" <size_44> <anmf_lossless_payload>
<anmf_lossy_payload> ::= <frame_header> <alph_chunk> <vp8_chunk>
<anmf_lossless_payload> ::= <frame_header> <vp8l_chunk>
<frame_header> ::= <frame_x_half> <frame_y_half> <frame_width_minus_one> <frame_height_minus_one> <frame_duration> <frame_flags>
<frame_x_half> ::= "\x00\x00\x00"
<frame_y_half> ::= "\x00\x00\x00"
<frame_width_minus_one> ::= "\x0f\x00\x00"
<frame_height_minus_one> ::= "\x0f\x00\x00"
<frame_duration> ::= "\x64\x00\x00"
<frame_flags> ::= "\x00" | "\x01" | "\x02" | "\x03"
<size_60> ::= "\x3c\x00\x00\x00"
<size_44> ::= "\x2c\x00\x00\x00"

# VP8 lossy key frame. The 24-bit frame tag has key-frame type 0, version 0,
# show-frame 1, and a four-byte first-partition size. Dimensions are 16x16,
# with both two-bit scaling fields zero.
<vp8_chunk> ::= "VP8 " <size_20> <vp8_payload>
<vp8_payload> ::= <vp8_frame_tag> <vp8_key_start_code> <vp8_horizontal_size> <vp8_vertical_size> <vp8_first_partition> <vp8_token_partitions>
<vp8_frame_tag> ::= "\x10\x00\x00"
<vp8_key_start_code> ::= "\x1d\x01\x2a"
<vp8_horizontal_size> ::= "\x10\x00"
<vp8_vertical_size> ::= "\x10\x00"
<vp8_first_partition> ::= r'[\x00-\x7f]{4}'
<vp8_token_partitions> ::= r'[\x00-\x7f]{6}'
<vp8_bool_coded_byte> ::= <opaque_byte>
<size_20> ::= "\x14\x00\x00\x00"

# VP8L lossless stream. The packed image header encodes width-1=15,
# height-1=15, alpha-used=0, version=0. The remaining productions expose the
# transform, color-cache, prefix-code, Huffman-group, LZ77, and EOS sections.
<vp8l_chunk> ::= "VP8L" <size_20> <vp8l_payload>
<vp8l_payload> ::= <vp8l_signature> <vp8l_image_header> <vp8l_transform_section> <vp8l_color_cache_section> <vp8l_meta_prefix_section> <vp8l_huffman_groups> <vp8l_lz77_image_data> <vp8l_end_code>
<vp8l_signature> ::= "\x2f"
<vp8l_image_header> ::= "\x0f\x40\x03\x00"
<vp8l_transform_section> ::= <vp8l_predictor_transform> | <vp8l_color_transform> | <vp8l_subtract_green_transform> | <vp8l_color_indexing_transform>
<vp8l_predictor_transform> ::= "\x01\x00\x00\x00"
<vp8l_color_transform> ::= "\x02\x00\x00\x00"
<vp8l_subtract_green_transform> ::= "\x03\x00\x00\x00"
<vp8l_color_indexing_transform> ::= "\x04\x00\x00\x00"
<vp8l_color_cache_section> ::= "\x00"
<vp8l_meta_prefix_section> ::= r'[\x00-\x7f]{2}'
<vp8l_huffman_groups> ::= r'[\x00-\x7f]{3}'
<vp8l_lz77_image_data> ::= <vp8l_literal_code> <vp8l_length_distance_code>
<vp8l_literal_code> ::= r'[\x00-\x7f]{2}'
<vp8l_length_distance_code> ::= r'[\x00-\x7f]{2}'
<vp8l_end_code> ::= "\x00"

# RIFF permits readers to ignore unknown chunks. JUNK is used to keep all
# profiles at one exact size while also exercising unknown-chunk handling.
<junk_84_chunk> ::= "JUNK" <size_84> <junk_payload_84>
<junk_10_chunk> ::= "JUNK" <size_10> <junk_payload_10>
<junk_26_chunk> ::= "JUNK" <size_26> <junk_payload_26>
<junk_12_chunk> ::= "JUNK" <size_12> <junk_payload_12>
<junk_28_chunk> ::= "JUNK" <size_28> <junk_payload_28>
<junk_payload_84> ::= r'[\x00-\x7f]{84}'
<junk_payload_10> ::= r'[\x00-\x7f]{10}'
<junk_payload_26> ::= r'[\x00-\x7f]{26}'
<junk_payload_12> ::= r'[\x00-\x7f]{12}'
<junk_payload_28> ::= r'[\x00-\x7f]{28}'
<size_84> ::= "\x54\x00\x00\x00"
<size_26> ::= "\x1a\x00\x00\x00"
<size_12> ::= "\x0c\x00\x00\x00"
<size_28> ::= "\x1c\x00\x00\x00"

<opaque_byte> ::= r'[\x00-\x7f]'
