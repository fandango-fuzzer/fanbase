# JPEG XL frame internals that jxl.fan stubs out: FrameHeader, TOC, LFGlobal,
# patches, splines, noise, modular stream header and transforms, HFGlobal,
# dequant matrices, block context maps, VarDCT groups, and entropy streams.
#
# TODO:
# * Uses literal ASCII tag bytes (b"S", b"M", b"F", ...) and decimal-digit
#   fields instead of JXL's real bit-packed encoding, so files don't decode
#   at all. Rework to pack fields the way jxl.fan does, extended to cover
#   these frame internals.

<start> ::= <jxl_codestream>;

<jxl_codestream> ::= <constrained_core_codestream>;

# A bounded reference profile keeps default fuzzing fast while still exercising
# ranges, cross-field equality, nesting, a payload length, and a check digit.
# The <complete_structured_codestream> start symbol expands every element family
# below when exhaustive structural fuzzing is desired.
<constrained_core_codestream> ::= (
    <codestream_signature> <core_level> <core_size> <core_metadata>
    <core_frame> <codestream_end>
);
<core_level> ::= "5" | "10";
where int(<core_level>) in (5, 10);
<core_size> ::= b"S" <core_width> b"x" <core_height>;
<core_width> ::= r"[1-9][0-9]{0,2}";
<core_height> ::= r"[1-9][0-9]{0,2}";
where 1 <= int(<core_width>) <= 512;
where int(<core_height>) == int(<core_width>);
<core_metadata> ::= b"M" <core_colour_space> <core_bit_depth>;
<core_colour_space> ::= "0" | "1" | "2" | "3";
<core_bit_depth> ::= "8" | "10" | "12" | "16";
where int(<core_colour_space>) in (0, 1, 2, 3);
where int(<core_bit_depth>) in (8, 10, 12, 16);
<core_frame> ::= b"F" <core_frame_type> <core_encoding> <core_payload_length> b":" <core_payload>;
<core_frame_type> ::= "0" | "1" | "2" | "3";
<core_encoding> ::= "0" | "1";
<core_payload_length> ::= r"[1-4]";
<core_payload> ::= <core_payload_octet>{1,4};
<core_payload_octet> ::= b"a" | b"c" | b"m" | b"v";
where int(<core_frame_type>) in (0, 1, 2, 3);
where int(<core_encoding>) in (0, 1);
where int(<core_payload_length>) == len(<core_payload>);
<complete_structured_codestream> ::= (
    <codestream_signature> <codestream_level> <size_header> <image_metadata>
    <frame_sequence> <codestream_end>
);

<codestream_signature> ::= b"\xff\x0a";
<codestream_level> ::= "5" | "10";
where int(<codestream_level>) == 5 or int(<codestream_level>) == 10;
<codestream_end> ::= b"\x00";

# SizeHeader and global ImageMetadata.

<size_header> ::= (
    b"S" <div8_flag> <height_value> <aspect_ratio_code> <width_value>
    <orientation> <intrinsic_size_record>? <preview_header>? <animation_header>?
);
<div8_flag> ::= "0" | "1";
where int(<div8_flag>) == 0 or int(<div8_flag>) == 1;
<height_value> ::= r"[1-9][0-9]{0,3}";
where 1 <= int(<height_value>) <= 8192;
<width_value> ::= r"[1-9][0-9]{0,3}";
where 1 <= int(<width_value>) <= 8192;
<aspect_ratio_code> ::= r"[0-7]";
where 0 <= int(<aspect_ratio_code>) <= 7;
<orientation> ::= r"[1-8]";
where 1 <= int(<orientation>) <= 8;
<intrinsic_size_record> ::= b"I" <intrinsic_width> b"," <intrinsic_height>;
<intrinsic_width> ::= r"[1-9][0-9]{0,3}";
<intrinsic_height> ::= r"[1-9][0-9]{0,3}";
where 1 <= int(<intrinsic_width>) <= 8192;
where 1 <= int(<intrinsic_height>) <= 8192;

<preview_header> ::= b"P" <preview_width> b"," <preview_height>;
<preview_width> ::= r"[1-9][0-9]{0,2}";
<preview_height> ::= r"[1-9][0-9]{0,2}";
where 1 <= int(<preview_width>) <= 512;
where 1 <= int(<preview_height>) <= 512;

<animation_header> ::= b"A" <tps_numerator> b"/" <tps_denominator> <loop_count> <have_timecodes>;
<tps_numerator> ::= r"[1-9][0-9]{0,2}";
<tps_denominator> ::= r"[1-9][0-9]{0,2}";
<loop_count> ::= r"[0-9]{1,3}";
<have_timecodes> ::= "0" | "1";
where 1 <= int(<tps_numerator>) <= 1000;
where 1 <= int(<tps_denominator>) <= 1000;
where 0 <= int(<loop_count>) <= 255;

<image_metadata> ::= (
    b"M" <all_default_metadata> <extra_fields_flag> <bit_depth>
    <modular_16bit_buffers> <extra_channel_table> <xyb_encoded>
    <colour_encoding> <tone_mapping>? <extensions> <default_m>
    <opsin_inverse_matrix>? <cw_mask> <global_icc_profile>?
);
<all_default_metadata> ::= "0" | "1";
<extra_fields_flag> ::= "0" | "1";
<modular_16bit_buffers> ::= "0" | "1";
<xyb_encoded> ::= "0" | "1";
<default_m> ::= "0" | "1";
where int(<all_default_metadata>) in (0, 1);
where int(<extra_fields_flag>) in (0, 1);
where int(<xyb_encoded>) in (0, 1);

<bit_depth> ::= <integer_bit_depth> | <floating_bit_depth>;
<integer_bit_depth> ::= b"U" <bits_per_sample>;
<floating_bit_depth> ::= b"F" <floating_bits_per_sample> <exponent_bits>;
<bits_per_sample> ::= r"(?:8|10|12|16|24|32)";
<floating_bits_per_sample> ::= "16" | "32";
<exponent_bits> ::= "5" | "8";
where int(<bits_per_sample>) in (8, 10, 12, 16, 24, 32);
where int(<floating_bits_per_sample>) in (16, 32);
where int(<exponent_bits>) < int(<floating_bits_per_sample>);

<extra_channel_table> ::= b"E" <extra_channel_count> b":" <extra_channel_payload>;
<extra_channel_count> ::= r"[0-4]";
<extra_channel_payload> ::= <extra_channel_record>{0,4};
<extra_channel_record> ::= b"a" | b"d" | b"s" | b"c";
where int(<extra_channel_count>) == len(<extra_channel_payload>);

<extra_channel_info> ::= (
    <extra_channel_type> <extra_channel_bit_depth> <dim_shift>
    <extra_channel_name_record>? <alpha_associated>?
);
<extra_channel_type> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "15";
<extra_channel_bit_depth> ::= <integer_bit_depth> | <floating_bit_depth>;
<dim_shift> ::= r"[0-3]";
<alpha_associated> ::= "0" | "1";
where int(<extra_channel_type>) in (0, 1, 2, 3, 4, 5, 6, 15);
where 0 <= int(<dim_shift>) <= 3;
<extra_channel_name_record> ::= <extra_name_length> b":" <extra_channel_name>;
<extra_name_length> ::= r"[1-8]";
<extra_channel_name> ::= r"[A-Za-z]{1,8}";
where int(<extra_name_length>) == len(<extra_channel_name>);

<colour_encoding> ::= (
    b"C" <want_icc> <colour_space> <white_point> <primaries>
    <transfer_function> <rendering_intent>
);
<want_icc> ::= "0" | "1";
<colour_space> ::= "0" | "1" | "2" | "3";
<white_point> ::= "1" | "2" | "10" | <custom_xy>;
<primaries> ::= "1" | "9" | "11" | <custom_primaries>;
<transfer_function> ::= "1" | "2" | "8" | "13" | "16" | "17" | "18" | "255";
<rendering_intent> ::= r"[0-3]";
where int(<want_icc>) in (0, 1);
where int(<colour_space>) in (0, 1, 2, 3);
where int(<rendering_intent>) in (0, 1, 2, 3);
<custom_xy> ::= b"(" <cie_x> b"," <cie_y> b")";
<cie_x> ::= r"[0-9]{1,5}";
<cie_y> ::= r"[0-9]{1,5}";
where 0 <= int(<cie_x>) <= 100000;
where 0 <= int(<cie_y>) <= 100000;
<custom_primaries> ::= <custom_xy> <custom_xy> <custom_xy>;

<tone_mapping> ::= b"T" <intensity_target> b"," <min_nits> b"," <relative_to_max_display> b"," <linear_below>;
<intensity_target> ::= r"[1-9][0-9]{1,4}";
<min_nits> ::= r"[0-9]{1,3}";
<relative_to_max_display> ::= "0" | "1";
<linear_below> ::= r"[0-9]{1,3}";
where 1 <= int(<intensity_target>) <= 10000;
where 0 <= int(<min_nits>) <= int(<intensity_target>);

<extensions> ::= b"X" <extension_bitmap> <extension_record>*;
<extension_bitmap> ::= "0" | "1" | "2" | "3" | "255";
<extension_record> ::= <extension_id> <extension_length> b":" <extension_payload>;
<extension_id> ::= r"[1-9]";
<extension_length> ::= r"[1-4]";
<extension_payload> ::= <byte>{1,4};
where 1 <= int(<extension_id>) <= 9;
where int(<extension_length>) == len(<extension_payload>);

<opsin_inverse_matrix> ::= b"O" <matrix_entry>{12};
<matrix_entry> ::= r"-?[0-9]{1,3},";
<cw_mask> ::= b"W" <cw_bit>{3};
<cw_bit> ::= "0" | "1";
<global_icc_profile> ::= b"ICC" <icc_length> b":" <icc_payload>;
<icc_length> ::= r"[1-8]";
<icc_payload> ::= <icc_command>{1,8};
<icc_command> ::= b"c" | b"p" | b"s" | b"d";
where int(<icc_length>) == len(<icc_payload>);

# Frames, FrameHeader fields, blending, restoration and TOC.

<frame_sequence> ::= <frame>{1,2};
<frame> ::= (
    b"F" <frame_header> <frame_toc> <lf_global> <modular_frame>?
    <lf_group>* <hf_global>? <pass_group>* <frame_end>
);
<frame_header> ::= (
    <all_default_frame> <frame_type> <encoding> <frame_flags> <do_ycbcr>
    <jpeg_upsampling> <extra_channel_upsampling> <group_size_shift>
    <passes_info> <frame_size_record>? <frame_origin>? <duration>
    <timecode>? <frame_name_record>? <restoration_filter>
    <blending_info> <extra_channel_blending>* <is_last>
);
<all_default_frame> ::= "0" | "1";
<frame_type> ::= "0" | "1" | "2" | "3";
<encoding> ::= "0" | "1";
<frame_flags> ::= "0" | "1" | "2" | "4" | "8" | "16";
<do_ycbcr> ::= "0" | "1";
<jpeg_upsampling> ::= r"[0-3]";
<extra_channel_upsampling> ::= r"[0-3]";
<group_size_shift> ::= "0" | "1" | "2" | "3";
<is_last> ::= "0" | "1";
where int(<frame_type>) in (0, 1, 2, 3);
where int(<encoding>) in (0, 1);
where 0 <= int(<group_size_shift>) <= 3;

<passes_info> ::= b"Q" <num_passes> <num_ds> <shift_values>;
<num_passes> ::= r"[1-4]";
<num_ds> ::= r"[0-3]";
<shift_values> ::= <pass_shift>{0,3};
<pass_shift> ::= r"[0-3]";
where 1 <= int(<num_passes>) <= 4;
where int(<num_ds>) == len(<shift_values>);

<frame_size_record> ::= b"Z" <frame_width> b"," <frame_height>;
<frame_width> ::= r"[1-9][0-9]{0,3}";
<frame_height> ::= r"[1-9][0-9]{0,3}";
where 1 <= int(<frame_width>) <= int(<width_value>);
where 1 <= int(<frame_height>) <= int(<height_value>);
<frame_origin> ::= b"@" <x0> b"," <y0>;
<x0> ::= r"-?[0-9]{1,3}";
<y0> ::= r"-?[0-9]{1,3}";
where -8192 <= int(<x0>) <= 8192;
where -8192 <= int(<y0>) <= 8192;
<duration> ::= b"D" <duration_ticks>;
<duration_ticks> ::= r"[0-9]{1,3}";
where 0 <= int(<duration_ticks>) <= 255;
<timecode> ::= b"TC" <timecode_hours> <timecode_minutes> <timecode_seconds> <timecode_frames>;
<timecode_hours> ::= r"(?:[01][0-9]|2[0-3])";
<timecode_minutes> ::= r"[0-5][0-9]";
<timecode_seconds> ::= r"[0-5][0-9]";
<timecode_frames> ::= r"[0-9]{2}";
where 0 <= int(<timecode_hours>) <= 23;
where 0 <= int(<timecode_minutes>) <= 59;
where 0 <= int(<timecode_seconds>) <= 59;
<frame_name_record> ::= b"N" <frame_name_length> b":" <frame_name>;
<frame_name_length> ::= r"[1-8]";
<frame_name> ::= r"[A-Za-z0-9_]{1,8}";
where int(<frame_name_length>) == len(<frame_name>);

<blending_info> ::= b"B" <blend_mode> <blend_source> <blend_alpha> <clamp_flag>;
<extra_channel_blending> ::= b"b" <blend_mode> <blend_source> <blend_alpha> <clamp_flag>;
<blend_mode> ::= "0" | "1" | "2" | "3" | "4";
<blend_source> ::= r"[0-3]";
<blend_alpha> ::= r"[0-3]";
<clamp_flag> ::= "0" | "1";
where int(<blend_mode>) in (0, 1, 2, 3, 4);
where 0 <= int(<blend_source>) <= 3;

<restoration_filter> ::= b"R" <gab_enabled> <epf_iters> <epf_sharp_lut> <epf_channel_scale> <epf_sigma>;
<gab_enabled> ::= "0" | "1";
<epf_iters> ::= r"[0-3]";
<epf_sharp_lut> ::= <sharp_entry>{8};
<sharp_entry> ::= r"[0-7]";
<epf_channel_scale> ::= r"[1-9][0-9]?";
<epf_sigma> ::= r"[1-9][0-9]?";
where 0 <= int(<epf_iters>) <= 3;

<frame_toc> ::= b"TOC" <toc_permuted> <toc_entry_count> b":" <toc_entries>;
<toc_permuted> ::= "0" | "1";
<toc_entry_count> ::= r"[1-4]";
<toc_entries> ::= <toc_entry>{1,4};
<toc_entry> ::= <toc_group_kind> <toc_group_size>;
<toc_group_kind> ::= b"L" | b"H" | b"P" | b"M";
<toc_group_size> ::= r"[1-9]";
where int(<toc_entry_count>) * 2 == len(<toc_entries>);
<toc_permutation> ::= b"PERM" <permutation_index>{1,4};
<permutation_index> ::= r"[0-3]";

# LFGlobal, patches, splines, noise, dequantization and quantizer metadata.

<lf_global> ::= (
    b"LG" <lf_global_flags> <patch_dictionary>? <spline_data>? <noise_parameters>?
    <lf_dequant> <global_scale> <quantizer> <hf_block_context>?
);
<lf_global_flags> ::= "0" | "1" | "2" | "3" | "7";
<patch_dictionary> ::= b"PATCH" <patch_count> b":" <patches>;
<patch_count> ::= r"[0-3]";
<patches> ::= <patch_record>{0,3};
<patch_record> ::= b"p";
where int(<patch_count>) == len(<patches>);
<patch_position> ::= <patch_ref> <patch_x> <patch_y> <patch_width> <patch_height> <patch_blending>;
<patch_ref> ::= r"[0-3]";
<patch_x> ::= r"[0-9]{1,3}";
<patch_y> ::= r"[0-9]{1,3}";
<patch_width> ::= r"[1-9][0-9]{0,2}";
<patch_height> ::= r"[1-9][0-9]{0,2}";
<patch_blending> ::= <blending_info>;
where int(<patch_x>) + int(<patch_width>) <= int(<width_value>);
where int(<patch_y>) + int(<patch_height>) <= int(<height_value>);

<spline_data> ::= b"SPL" <spline_count> b":" <spline_records>;
<spline_count> ::= r"[0-3]";
<spline_records> ::= <spline_record>{0,3};
<spline_record> ::= b"s";
where int(<spline_count>) == len(<spline_records>);
<spline_control_points> ::= <spline_point>{2,8};
<spline_point> ::= b"(" <spline_dx> b"," <spline_dy> b")";
<spline_dx> ::= r"-?[0-9]{1,2}";
<spline_dy> ::= r"-?[0-9]{1,2}";
<spline_coefficients> ::= <spline_coeff>{32};
<spline_coeff> ::= r"-?[0-9]{1,3},";

<noise_parameters> ::= b"NOISE" <noise_lut>{8};
<noise_lut> ::= r"[0-9]{1,3},";
<lf_dequant> ::= b"LFDQ" <lf_dequant_value>{3};
<lf_dequant_value> ::= r"[1-9][0-9]{0,2},";
<global_scale> ::= b"GS" <global_scale_value>;
<global_scale_value> ::= r"[1-9][0-9]{0,3}";
<quantizer> ::= b"QT" <quant_dc> <quant_m_ac>;
<quant_dc> ::= r"[1-9][0-9]{0,2}";
<quant_m_ac> ::= r"[1-9][0-9]{0,2}";
where 1 <= int(<global_scale_value>) <= 4096;
where 1 <= int(<quant_dc>) <= 256;

<hf_block_context> ::= b"HBC" <num_block_clusters> <lf_thresholds> <qf_thresholds> <block_context_map>;
<num_block_clusters> ::= r"[1-8]";
<lf_thresholds> ::= <threshold_value>{0,4};
<qf_thresholds> ::= <threshold_value>{0,4};
<threshold_value> ::= r"[0-9]{1,3},";
<block_context_map> ::= <context_cluster>{1,8};
<context_cluster> ::= r"[0-7]";
where 1 <= int(<num_block_clusters>) <= 8;

# Modular coding: headers, transforms, MA tree, predictors and channel data.

<modular_frame> ::= b"MOD" <modular_header> <transform_list> <global_ma_tree> <modular_channels>;
<modular_header> ::= <use_global_tree> <wp_header> <modular_nb_meta_channels>;
<use_global_tree> ::= "0" | "1";
<modular_nb_meta_channels> ::= r"[0-4]";
<wp_header> ::= b"WP" <wp_p1> <wp_p2> <wp_p3a> <wp_p3b> <wp_p3c> <wp_weight>;
<wp_p1> ::= r"[0-9]{1,2}";
<wp_p2> ::= r"[0-9]{1,2}";
<wp_p3a> ::= r"[0-9]{1,2}";
<wp_p3b> ::= r"[0-9]{1,2}";
<wp_p3c> ::= r"[0-9]{1,2}";
<wp_weight> ::= r"[1-9][0-9]?";

<transform_list> ::= b"TR" <transform_count> b":" <transform_records>;
<transform_count> ::= r"[0-3]";
<transform_records> ::= <transform_record>{0,3};
<transform_record> ::= b"r" | b"p" | b"s";
where int(<transform_count>) == len(<transform_records>);
<rct_transform> ::= b"RCT" <rct_begin_c> <rct_type>;
<rct_begin_c> ::= r"[0-3]";
<rct_type> ::= r"[0-9]{1,2}";
where 0 <= int(<rct_type>) <= 41;
<palette_transform> ::= b"PAL" <palette_begin_c> <palette_num_c> <palette_size> <palette_predictor> <palette_delta>;
<palette_begin_c> ::= r"[0-3]";
<palette_num_c> ::= r"[1-4]";
<palette_size> ::= r"[1-9][0-9]{0,2}";
<palette_predictor> ::= r"[0-7]";
<palette_delta> ::= "0" | "1";
where 1 <= int(<palette_size>) <= 256;
<squeeze_transform> ::= b"SQ" <squeeze_count> <squeeze_parameters>;
<squeeze_count> ::= r"[1-4]";
<squeeze_parameters> ::= <squeeze_parameter>{1,4};
<squeeze_parameter> ::= <squeeze_horizontal> <squeeze_in_place> <squeeze_begin_c> <squeeze_num_c>;
<squeeze_horizontal> ::= "0" | "1";
<squeeze_in_place> ::= "0" | "1";
<squeeze_begin_c> ::= r"[0-3]";
<squeeze_num_c> ::= r"[1-4]";
where int(<squeeze_count>) * 4 == len(<squeeze_parameters>);

<global_ma_tree> ::= b"MAT" <ma_node_count> b":" <ma_nodes>;
<ma_node_count> ::= r"[1-4]";
<ma_nodes> ::= <ma_node>{1,4};
<ma_node> ::= b"n";
where int(<ma_node_count>) == len(<ma_nodes>);
<ma_branch_node> ::= <ma_property> <ma_predictor> <ma_offset> <ma_multiplier> <ma_split_value>;
<ma_property> ::= r"[0-9]{1,2}";
<ma_predictor> ::= r"[0-9]{1,2}";
<ma_offset> ::= r"-?[0-9]{1,3}";
<ma_multiplier> ::= r"[1-9][0-9]{0,2}";
<ma_split_value> ::= r"-?[0-9]{1,3}";
where 0 <= int(<ma_property>) <= 15;
where 0 <= int(<ma_predictor>) <= 13;
<ma_leaf_node> ::= <leaf_predictor> <leaf_offset> <leaf_multiplier> <leaf_context>;
<leaf_predictor> ::= r"[0-9]{1,2}";
<leaf_offset> ::= r"-?[0-9]{1,3}";
<leaf_multiplier> ::= r"[1-9][0-9]{0,2}";
<leaf_context> ::= r"[0-9]{1,2}";

<modular_channels> ::= b"CH" <modular_channel_count> b":" <modular_channel_records>;
<modular_channel_count> ::= r"[1-4]";
<modular_channel_records> ::= <modular_channel_record>{1,4};
<modular_channel_record> ::= b"m";
where int(<modular_channel_count>) == len(<modular_channel_records>);
<modular_channel_header> ::= <channel_width> <channel_height> <channel_hshift> <channel_vshift>;
<channel_width> ::= r"[1-9][0-9]{0,3}";
<channel_height> ::= r"[1-9][0-9]{0,3}";
<channel_hshift> ::= r"[0-3]";
<channel_vshift> ::= r"[0-3]";
where 1 <= int(<channel_width>) <= int(<width_value>);
where 1 <= int(<channel_height>) <= int(<height_value>);
<modular_channel_data> ::= <entropy_stream> <residual_symbol>*;
<residual_symbol> ::= r"-?[0-9]{1,3},";

# LF groups, HFGlobal/pass metadata and VarDCT group structures.

<lf_group> ::= b"LFG" <lf_group_index> <lf_coefficients> <lf_group_modular>?;
<lf_group_index> ::= r"[0-9]{1,2}";
<lf_coefficients> ::= <lf_coefficient>{3,12};
<lf_coefficient> ::= r"-?[0-9]{1,3},";
<lf_group_modular> ::= <modular_channel_data>;

<hf_global> ::= b"HG" <hf_global_flags> <dequant_matrices> <used_orders> <hf_histograms>;
<hf_global_flags> ::= "0" | "1" | "2" | "3";
<dequant_matrices> ::= b"DQ" <dequant_matrix>{1,3};
<dequant_matrix> ::= <dct_select> <matrix_encoding> <matrix_values>;
<dct_select> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9";
<matrix_encoding> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6";
<matrix_values> ::= <matrix_quant_value>{1,8};
<matrix_quant_value> ::= r"[1-9][0-9]{0,2},";
where int(<dct_select>) in (0, 1, 2, 3, 4, 5, 6, 7, 8, 9);
where int(<matrix_encoding>) in (0, 1, 2, 3, 4, 5, 6);
<used_orders> ::= b"ORD" <order_mask> <coefficient_order>*;
<order_mask> ::= "0" | "1" | "3" | "7" | "15";
<coefficient_order> ::= <order_index>{1,8};
<order_index> ::= r"[0-7]";
<hf_histograms> ::= b"HIST" <entropy_stream>;

<pass_group> ::= b"PG" <pass_index> <group_index> <vardct_group> <modular_pass_group>?;
<pass_index> ::= r"[0-3]";
<group_index> ::= r"[0-9]{1,3}";
where int(<pass_index>) < int(<num_passes>);
<vardct_group> ::= (
    <block_splitting> <ac_strategy_map> <quant_field> <sharpness_map>
    <coefficient_orders> <ac_coefficients>
);
<block_splitting> ::= b"BS" <block_count> b":" <block_records>;
<block_count> ::= r"[1-4]";
<block_records> ::= <block_record>{1,4};
<block_record> ::= b"x";
where int(<block_count>) == len(<block_records>);
<block_record_detail> ::= <block_x> <block_y> <block_transform> <block_transpose>;
<block_x> ::= r"[0-9]{1,3}";
<block_y> ::= r"[0-9]{1,3}";
<block_transform> ::= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" | "10" | "11" | "12" | "13" | "14" | "15" | "16" | "17" | "18" | "19" | "20" | "21" | "22" | "23" | "24" | "25" | "26";
<block_transpose> ::= "0" | "1";
where 0 <= int(<block_transform>) <= 26;
<ac_strategy_map> ::= b"AS" <ac_strategy>{1,8};
<ac_strategy> ::= r"[0-9]{1,2},";
<quant_field> ::= b"QF" <quant_value>{1,8};
<quant_value> ::= r"[1-9][0-9]{0,2},";
<sharpness_map> ::= b"SM" <sharp_entry>{1,8};
<coefficient_orders> ::= b"CO" <coefficient_order>{1,3};
<ac_coefficients> ::= b"AC" <entropy_stream> <ac_coefficient>*;
<ac_coefficient> ::= r"-?[0-9]{1,3},";
<modular_pass_group> ::= b"MP" <modular_channel_data>;

# Entropy coding: context maps, histograms, ANS, prefix codes and hybrid uints.

<entropy_stream> ::= b"EN" <lz77_enabled> <cluster_map> <entropy_distributions> <entropy_payload> <ans_final_state>;
<lz77_enabled> ::= "0" | "1";
<cluster_map> ::= <simple_cluster_map> | <mtf_cluster_map>;
<simple_cluster_map> ::= b"CS" <cluster_count> b":" <cluster_ids>;
<mtf_cluster_map> ::= b"CM" <cluster_count> b":" <cluster_ids>;
<cluster_count> ::= r"[1-4]";
<cluster_ids> ::= <cluster_id>{1,4};
<cluster_id> ::= r"[0-3]";
where int(<cluster_count>) == len(<cluster_ids>);
<entropy_distributions> ::= <ans_distribution> | <prefix_distribution>;
<ans_distribution> ::= b"ANS" <ans_log_alphabet_size> <ans_frequency_table>;
<ans_log_alphabet_size> ::= r"[1-8]";
<ans_frequency_table> ::= <ans_frequency>{1,8};
<ans_frequency> ::= r"[0-9]{1,3},";
where 1 <= int(<ans_log_alphabet_size>) <= 8;
<prefix_distribution> ::= b"PRE" <hskip> <code_length_count> <code_lengths>;
<hskip> ::= r"[0-3]";
<code_length_count> ::= r"[1-8]";
<code_lengths> ::= <code_length>{1,8};
<code_length> ::= r"[0-7]";
where int(<code_length_count>) == len(<code_lengths>);
<hybrid_uint_config> ::= b"HU" <split_exponent> <msb_in_token> <lsb_in_token>;
<split_exponent> ::= r"[0-9]{1,2}";
<msb_in_token> ::= r"[0-9]";
<lsb_in_token> ::= r"[0-9]";
where int(<msb_in_token>) + int(<lsb_in_token>) <= int(<split_exponent>);
<hybrid_uint_symbol> ::= <hybrid_token> <hybrid_raw_bits>;
<hybrid_token> ::= r"[0-9]{1,3}";
<hybrid_raw_bits> ::= r"[01]{0,8}";
<entropy_payload> ::= <entropy_symbol>{1,8};
<entropy_symbol> ::= b"0" | b"1" | b"2" | b"3";
<ans_final_state> ::= "1245184";
where int(<ans_final_state>) == 0x130000;

# Frame alignment records.

<frame_padding> ::= b"\x00"{0,7};
<frame_end> ::= <frame_padding> b";";
