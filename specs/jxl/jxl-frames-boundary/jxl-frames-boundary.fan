# Same frame internals as jxl-frames, with fields approximated by fixed
# byte-aligned values (ImageMetadata/ColorEncoding/ToneMapping/frame-header
# bundles) instead of JXL's real bit-level packing.
#
# TODO:
# * A byte-aligned approximation isn't true bit packing, so files don't
#   decode. Rework using jxl.fan's bit-packing approach, extended to cover
#   frame internals.

<start> ::= <jxl_codestream>

<jxl_codestream> ::= <codestream_signature> <size_header> <image_metadata> <global_optional_data> <frame_sequence> <codestream_trailer>
<codestream_signature> ::= "\xff\x0a"

# SizeHeader: small dimensions, ratio-derived width, and extended U32 forms.
<size_header> ::= <size_small_square> | <size_small_ratio> | <size_extended>
<size_small_square> ::= "\x08\x00" | "\x10\x00" | "\x20\x00" | "\x40\x00"
<size_small_ratio> ::= "\x08\x01" | "\x10\x02" | "\x20\x03" | "\x40\x04" | "\x80\x05"
<size_extended> ::= "\x00" <u32_dimension> <u32_dimension>
<u32_dimension> ::= "\x01" | "\xff\x00" | "\x00\x01" | "\xff\xff\x00\x00" | "\xff\xff\xff\x7f"

# ImageMetadata base and explicit bundles.  These bundles include all_default,
# orientation/intrinsic/preview/animation flags, bit depth and extra-channel
# count coding through the next byte boundary.
<image_metadata> ::= <metadata_default> | <metadata_explicit>
<metadata_default> ::= "\x01\x00"
<metadata_explicit> ::= "\x00" <orientation_bundle> <intrinsic_size_bundle> <preview_bundle> <animation_bundle> <bit_depth_bundle> <extra_channel_bundle> <xyb_bundle> <color_bundle> <tone_mapping_bundle> <metadata_extensions>
<orientation_bundle> ::= "\x00" | "\x01" | "\x02" | "\x03" | "\x04" | "\x05" | "\x06" | "\x07"
<intrinsic_size_bundle> ::= "\x00" | "\x01\x01\x01" | "\x01\xff\x00\xff\x00"
<preview_bundle> ::= "\x00" | "\x01" <preview_header>
<preview_header> ::= "\x08\x08\x00" | "\x10\x10\x01" | "\x20\x18\x02"
<animation_bundle> ::= "\x00" | "\x01" <animation_header>
<animation_header> ::= "\x01\x00\x01\x00" | "\x18\x00\x01\x01" | "\x3c\x00\xff\x01"
<bit_depth_bundle> ::= "\x08" | "\x0a" | "\x0c" | "\x10" | "\x20\x05" | "\x20\x08"
<extra_channel_bundle> ::= "\x00" | "\x01" <extra_channel_info> | "\x02" <extra_channel_info> <extra_channel_info> | "\x04" <extra_channel_info> <extra_channel_info> <extra_channel_info> <extra_channel_info>
<extra_channel_info> ::= <extra_channel_type> <extra_channel_depth> <extra_channel_dim_shift> <extra_channel_name>
<extra_channel_type> ::= "\x00" | "\x01" | "\x02" | "\x03" | "\x04" | "\x05" | "\x06" | "\x0f"
<extra_channel_depth> ::= "\x08" | "\x10" | "\x20\x05"
<extra_channel_dim_shift> ::= "\x00" | "\x01" | "\x03"
<extra_channel_name> ::= "\x00" | "\x01A" | "\x05alpha" | "\x04spot"
<xyb_bundle> ::= "\x00" | "\x01"

# ColorEncoding includes predefined encodings and the explicit/custom path.
<color_bundle> ::= <color_srgb> | <color_gray> | <color_p3> | <color_rec2100> | <color_explicit> | <color_want_icc>
<color_srgb> ::= "\x01\x00"
<color_gray> ::= "\x01\x01"
<color_p3> ::= "\x01\x02"
<color_rec2100> ::= "\x01\x03"
<color_explicit> ::= "\x00" <color_space> <white_point> <primaries> <transfer_function> <rendering_intent>
<color_space> ::= "\x00" | "\x01" | "\x02" | "\x03"
<white_point> ::= "\x01" | "\x02" | "\x0a" <custom_xy>
<primaries> ::= "\x01" | "\x02" | "\x09" | "\x0b" <custom_xy> <custom_xy> <custom_xy>
<custom_xy> ::= "\x00\x00\x00\x00" | "\xff\xff\x00\x00" | "\x00\x00\xff\x7f"
<transfer_function> ::= "\x01" | "\x08" | "\x0d" | "\x10" | "\x12" | "\x80\x00" | "\xff\x0f"
<rendering_intent> ::= "\x00" | "\x01" | "\x02" | "\x03"
<color_want_icc> ::= "\x80\x00"
<tone_mapping_bundle> ::= "\x00" | "\x01\x00\x00\x80\x3f\x00\x00\x00\x00" | "\x01\x00\x00\x80\x47\x00\x00\x80\x3f"

# Extensions are length-delimited in the real stream.  Here each bundle carries
# its complete U64 key/U32 length/payload coding and is capped at two entries.
<metadata_extensions> ::= "\x00" | "\x01" <metadata_extension> | "\x02" <metadata_extension> <metadata_extension>
<metadata_extension> ::= "\x01\x00\x01\x00" <one_byte_payload> | "\x80\x01\x04\x00" <four_byte_payload>
<one_byte_payload> ::= r'[\x00-\xff]'
<four_byte_payload> ::= r'[\x00-\xff]{4}'

# Optional global ICC and preview frames precede the main frame sequence.
<global_optional_data> ::= <icc_stream>? <preview_frame>?
<icc_stream> ::= <icc_header> <icc_commands>
<icc_header> ::= "\x04\x00\x00\x00" | "\x0c\x00\x00\x00"
<icc_commands> ::= "\x00\x00\x00\x00" | "\x01sRGB" | "\x02XYZ \x00\x00\x00\x00" | "\x03acsp\x00\x00\x00\x00"
<preview_frame> ::= <preview_frame_header> <toc> <lf_global> <group_data>
<preview_frame_header> ::= "\x00\x00\x00" | "\x20\x00\x01"

# One ordinary frame is the reliable base.  Up to three frames cover animation,
# reference-only and progressive combinations without unbounded recursion.
<frame_sequence> ::= <frame> | <frame> <frame> | <frame> <frame> <frame>
<frame> ::= <frame_header> <frame_optional_features> <toc> <lf_global> <pass_groups> <frame_padding>
<frame_header> ::= <regular_frame_header> | <lf_frame_header> | <reference_frame_header> | <skip_progressive_frame_header>
<regular_frame_header> ::= "\x00" <encoding_selector> <frame_flags> <frame_dimensions> <blend_info> <frame_name>
<lf_frame_header> ::= "\x01" <encoding_selector> <frame_flags> <frame_dimensions> <blend_info> <frame_name>
<reference_frame_header> ::= "\x02" <encoding_selector> <frame_flags> <frame_dimensions> <blend_info> <frame_name>
<skip_progressive_frame_header> ::= "\x03" <encoding_selector> <frame_flags> <frame_dimensions> <blend_info> <frame_name>
<encoding_selector> ::= "\x00" | "\x01"
<frame_flags> ::= "\x00\x00" | "\x01\x00" | "\x04\x00" | "\x20\x00" | "\x00\x01" | "\xff\x03"
<frame_dimensions> ::= "\x00" | "\x01\x00\x00\x08\x08" | "\x01\x01\x01\x10\x10"
<blend_info> ::= "\x00\x00" | "\x01\x00" | "\x02\x01" | "\x03\x00" | "\x04\x01"
<frame_name> ::= "\x00" | "\x01f" | "\x04main" | "\x06legacy"

# Frame-level optional tools, including features omitted by all_default paths.
<frame_optional_features> ::= <passes_info> <lf_level> <crop_bundle> <reference_bundle> <save_before_ct_bundle> <frame_extensions> <restoration_filters> <special_frames>
<passes_info> ::= "\x01\x00" | "\x02\x01\x01" | "\x04\x03\x02\x01\x00"
<lf_level> ::= "\x00" | "\x01" | "\x02" | "\x03"
<crop_bundle> ::= "\x00" | "\x01\x00\x00\x08\x08" | "\x01\xff\x00\xff\x00\x20\x20"
<reference_bundle> ::= "\x00" | "\x01" | "\x02" | "\x03"
<save_before_ct_bundle> ::= "\x00" | "\x01"
<frame_extensions> ::= "\x00" | "\x01" <frame_extension>
<frame_extension> ::= "\x02\x01" <one_byte_payload> | "\x81\x01\x04" <four_byte_payload>
<restoration_filters> ::= <gab_filter> <epf_filter>
<gab_filter> ::= "\x00" | "\x01\x00" | "\x01\xff"
<epf_filter> ::= "\x00" | "\x01\x00\x00" | "\x02\x80\x80" | "\x03\xff\xff"
<special_frames> ::= <noise_bundle>? <patches_bundle>? <splines_bundle>?
<noise_bundle> ::= "\x00" <noise_parameters>
<noise_parameters> ::= "\x00\x00\x00\x00" | "\xff\x00\xff\x00" | "\xff\xff\xff\xff"
<patches_bundle> ::= "\x01\x01" <patch_record> | "\x01\x02" <patch_record> <patch_record> | "\x01\x03" <patch_record> <patch_record> <patch_record>
<patch_record> ::= "\x00\x00\x08\x08\x00" | "\x01\x01\x10\x10\x01"
<splines_bundle> ::= "\x02\x01" <spline_record> | "\x02\x02" <spline_record> <spline_record>
<spline_record> ::= "\x00\x00\x01\x01\x00" | "\x7f\x7f\x02\x02\xff"

# TOC permutations and entry-size codings are explicit and bounded, keeping
# the group-offset arithmetic non-recursive.
<toc> ::= <toc_single> | <toc_multi> | <toc_permuted>
<toc_single> ::= "\x00" <toc_size>
<toc_multi> ::= "\x01" <toc_size> <toc_size> | "\x02" <toc_size> <toc_size> <toc_size> <toc_size>
<toc_permuted> ::= "\x81" <toc_permutation> <toc_size> <toc_size> <toc_size> <toc_size>
<toc_permutation> ::= "\x00\x01\x02\x03" | "\x03\x02\x01\x00" | "\x01\x03\x00\x02"
<toc_size> ::= "\x00" | "\x01" | "\x10" | "\xff\x00" | "\xff\xff\x00\x00"

# LFGlobal covers both VarDCT and modular image encodings.
<lf_global> ::= <lf_global_vardct> | <lf_global_modular>
<lf_global_vardct> ::= "\x00" <lf_dequant> <hf_block_context> <lf_channel_corr> <vardct_global>
<lf_global_modular> ::= "\x01" <lf_channel_corr> <modular_global>
<lf_dequant> ::= "\x00" | "\x01\x80\x80\x80" | "\x01\xff\x00\xff"
<hf_block_context> ::= "\x00" | "\x01\x00\x00" | "\x02\x01\x02\x03"
<lf_channel_corr> ::= "\x00\x00" | "\x80\x80" | "\xff\x01"
<vardct_global> ::= <quantizer> <hf_global> <global_tree>?
<quantizer> ::= "\x00\x00" | "\x01\x80" | "\xff\xff"
<hf_global> ::= "\x00" <dct_params> | "\x01" <dct_params> <dct_params>
<dct_params> ::= "\x00\x00" | "\x01\x01" | "\x02\xff"
<global_tree> ::= "\x00" <tree_node> | "\x01" <tree_node> <tree_node> | "\x02" <tree_node> <tree_node> <tree_node> <tree_node>
<tree_node> ::= "\x00\x00" | "\x01\x01" | "\x02\x7f" | "\x03\xff"

# Modular global state: transforms include palette, squeeze and the deprecated
# RCT path.  Tree depth is represented by capped node lists, never recursion.
<modular_global> ::= <modular_header> <transform_list> <modular_tree> <modular_channels>
<modular_header> ::= "\x00\x00" | "\x01\x00" | "\xff\x03"
<transform_list> ::= "\x00" | "\x01" <modular_transform> | "\x02" <modular_transform> <modular_transform> | "\x04" <modular_transform> <modular_transform> <modular_transform> <modular_transform>
<modular_transform> ::= <transform_rct> | <transform_palette> | <transform_squeeze>
<transform_rct> ::= "\x00\x00" | "\x00\x06" | "\x00\x2a"
<transform_palette> ::= "\x01\x00\x01\x00" | "\x01\x03\xff\x01"
<transform_squeeze> ::= "\x02\x00\x00\x00" | "\x02\x01\x03\x01"
<modular_tree> ::= "\x00" <modular_leaf> | "\x01" <modular_leaf> <modular_leaf> | "\x03" <modular_leaf> <modular_leaf> <modular_leaf> <modular_leaf> <modular_leaf> <modular_leaf> <modular_leaf> <modular_leaf>
<modular_leaf> ::= <predictor> <context_value>
<predictor> ::= "\x00" | "\x01" | "\x02" | "\x03" | "\x04" | "\x05" | "\x06" | "\x07" | "\x08" | "\x09" | "\x0d"
<context_value> ::= "\x00" | "\x01" | "\x7f" | "\xff"
<modular_channels> ::= <channel_stream> | <channel_stream> <channel_stream> <channel_stream> | <channel_stream> <channel_stream> <channel_stream> <channel_stream>
<channel_stream> ::= <entropy_header> <residual_data>

# Entropy coding includes prefix and ANS distribution modes, hybrid uint config,
# LZ77, and bounded residual bytes.
<entropy_header> ::= <prefix_entropy> | <ans_entropy>
<prefix_entropy> ::= "\x00" <hybrid_uint_config> <prefix_code>
<ans_entropy> ::= "\x01" <hybrid_uint_config> <ans_distribution>
<hybrid_uint_config> ::= "\x00" | "\x01\x00" | "\x04\x02" | "\x08\x04"
<prefix_code> ::= "\x00\x00" | "\x01\x01\x01" | "\x02\x02\x03\x03"
<ans_distribution> ::= "\x00\x00" | "\x01\x01\x01" | "\x02\x01\x02\x04\x08"
<residual_data> ::= r'[\x00-\xff]{1,8}' | <lz77_data>
<lz77_data> ::= "\xff\x00\x01" | "\xff\x01\x04" <four_byte_payload>

# Pass groups cover LF group data, HF metadata, VarDCT coefficients and modular
# pass data.  Repetition caps model large/deep layouts without explosive output.
<pass_groups> ::= <group_data> | <group_data> <group_data> | <group_data> <group_data> <group_data> <group_data>
<group_data> ::= <lf_group> <hf_metadata>? <pass_group>{1,4}
<lf_group> ::= <lf_coefficients> <lf_modular>?
<lf_coefficients> ::= "\x00\x00" | "\x01\x80\x80" | "\xff\xff\xff"
<lf_modular> ::= <modular_tree> <channel_stream>
<hf_metadata> ::= <block_transform_map> <sharpness_map>? <epf_sigma_map>?
<block_transform_map> ::= "\x00" | "\x01\x00\x01\x02" | "\x02\x00\x03\x06\x0c"
<sharpness_map> ::= "\x00" | "\x01\x01\x02\x03"
<epf_sigma_map> ::= "\x00" | "\x01\x40\x80\xff"
<pass_group> ::= <vardct_pass_group> | <modular_pass_group>
<vardct_pass_group> ::= "\x00" <coeff_order> <ac_coefficients>
<modular_pass_group> ::= "\x01" <channel_stream>
<coeff_order> ::= "\x00" | "\x01\x00\x01\x02\x03" | "\xff\x03\x02\x01\x00"
<ac_coefficients> ::= <entropy_header> r'[\x00-\xff]{1,12}'

# Zero padding is the normal terminator.  Nonzero extension trailers are bounded
# alternatives for forward-compatible decoders and truncation/error campaigns.
<frame_padding> ::= "" | "\x00" | "\x00\x00" | "\x00\x00\x00"
<codestream_trailer> ::= "" | "\x00" | <bounded_unknown_extension>
<bounded_unknown_extension> ::= "\xfe\x01" <one_byte_payload> | "\xfe\x04" <four_byte_payload>
