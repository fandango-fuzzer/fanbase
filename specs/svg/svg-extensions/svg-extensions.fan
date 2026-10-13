# Same as svg, plus legacy SVG 1.1 font/glyph elements, the withdrawn SVG 2
# draft paint servers (meshGradient, hatch, solidColor), and a few non-SVG
# embedded tags (audio/video/canvas/iframe).
#
# TODO:
# * audio/video/canvas/iframe aren't real SVG elements; real renderers
#   treat them as inert unknown tags. Consider dropping them or labelling
#   them as decoys.

<start> ::= <xml_decl> <svg_element> "\n";

<xml_decl> ::= "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
<svg_element> ::= "<svg" <svg_root_attrs> ">" <svg_content>* "</svg>";
<svg_root_attrs> ::= " xmlns=\"http://www.w3.org/2000/svg\"" " xmlns:xlink=\"http://www.w3.org/1999/xlink\"" " version=\"1.1\"" <id_attr>? <view_box_attr> <width_attr> <height_attr> <common_attrs>;

<svg_content> ::= (<container_element> | <metadata_element> | <shape_element> | <text_element> | <embedded_element> | <paint_element> | <clipping_element> | <filter_element> | <animation_element> | <font_element> | <script_element> | <style_element>);

# Structural and container elements.
<container_element> ::= (<g_element> | <defs_element> | <symbol_element> | <use_element> | <switch_element> | <a_element> | <view_element>);
<g_element> ::= "<g" <id_attr>? <common_attrs> ">" <svg_content>* "</g>";
<defs_element> ::= "<defs" <id_attr>? <common_attrs> ">" <svg_content>* "</defs>";
<symbol_element> ::= "<symbol" <id_attr>? <view_box_attr>? <preserve_aspect_attr>? <common_attrs> ">" <svg_content>* "</symbol>";
<use_element> ::= "<use" <id_attr>? <href_attr> <x_attr>? <y_attr>? <width_attr>? <height_attr>? <common_attrs> "/>";
<switch_element> ::= "<switch" <id_attr>? <common_attrs> ">" <svg_content>+ "</switch>";
<a_element> ::= "<a" <id_attr>? <href_attr> <target_attr>? <common_attrs> ">" (<svg_content> | <text_node>)* "</a>";
<view_element> ::= "<view" <id_attr>? <view_box_attr> <preserve_aspect_attr>? "/>";

# Descriptive metadata.
<metadata_element> ::= (<title_element> | <desc_element> | <metadata_raw_element>);
<title_element> ::= "<title" <id_attr>? ">" <text_node> "</title>";
<desc_element> ::= "<desc" <id_attr>? ">" <text_node> "</desc>";
<metadata_raw_element> ::= "<metadata" <id_attr>? ">" <text_node> "</metadata>";

# Paths and basic shapes.
<shape_element> ::= (<path_element> | <rect_element> | <circle_element> | <ellipse_element> | <line_element> | <polyline_element> | <polygon_element>);
<path_element> ::= "<path" <id_attr>? " d=\"" <path_data> "\"" <path_length_attr>? <common_attrs> "/>";
<rect_element> ::= "<rect" <id_attr>? <x_attr>? <y_attr>? <width_attr> <height_attr> <rx_attr>? <ry_attr>? <common_attrs> "/>";
<circle_element> ::= "<circle" <id_attr>? <cx_attr>? <cy_attr>? <r_attr> <common_attrs> "/>";
<ellipse_element> ::= "<ellipse" <id_attr>? <cx_attr>? <cy_attr>? <rx_attr> <ry_attr> <common_attrs> "/>";
<line_element> ::= "<line" <id_attr>? <x1_attr> <y1_attr> <x2_attr> <y2_attr> <common_attrs> "/>";
<polyline_element> ::= "<polyline" <id_attr>? " points=\"" <point_pair> (" " <point_pair>){1,8} "\"" <common_attrs> "/>";
<polygon_element> ::= "<polygon" <id_attr>? " points=\"" <point_pair> (" " <point_pair>){2,8} "\"" <common_attrs> "/>";

# Text and text-on-path.
<text_element> ::= (<text_root_element> | <tspan_element> | <text_path_element>);
<text_root_element> ::= "<text" <id_attr>? <x_attr>? <y_attr>? <dx_attr>? <dy_attr>? <rotate_attr>? <text_attrs> <common_attrs> ">" (<text_node> | <tspan_element> | <text_path_element> | <a_element>)+ "</text>";
<tspan_element> ::= "<tspan" <id_attr>? <x_attr>? <y_attr>? <dx_attr>? <dy_attr>? <rotate_attr>? <text_attrs> <common_attrs> ">" (<text_node> | <tspan_element>)+ "</tspan>";
<text_path_element> ::= "<textPath" <id_attr>? <href_attr> <start_offset_attr>? <method_attr>? <spacing_attr>? <common_attrs> ">" (<text_node> | <tspan_element>)+ "</textPath>";

# Embedded content and external resources.
<embedded_element> ::= (<image_element> | <foreign_object_element> | <audio_element> | <video_element> | <iframe_element> | <canvas_element>);
<image_element> ::= "<image" <id_attr>? <href_image_attr> <x_attr>? <y_attr>? <width_attr> <height_attr> <preserve_aspect_attr>? <common_attrs> "/>";
<foreign_object_element> ::= "<foreignObject" <id_attr>? <x_attr>? <y_attr>? <width_attr> <height_attr> <common_attrs> ">" <text_node>? "</foreignObject>";
<audio_element> ::= "<audio" <id_attr>? <href_media_attr> <common_attrs> "/>";
<video_element> ::= "<video" <id_attr>? <href_media_attr> <x_attr>? <y_attr>? <width_attr> <height_attr> <common_attrs> "/>";
<iframe_element> ::= "<iframe" <id_attr>? <href_attr> <x_attr>? <y_attr>? <width_attr> <height_attr> <common_attrs> "/>";
<canvas_element> ::= "<canvas" <id_attr>? <x_attr>? <y_attr>? <width_attr> <height_attr> <common_attrs> "/>";

# Paint servers and markers.
<paint_element> ::= (<linear_gradient_element> | <radial_gradient_element> | <mesh_gradient_element> | <pattern_element> | <marker_element> | <solid_color_element> | <hatch_element> | <hatch_path_element> | <stop_element> | <mesh_row_element> | <mesh_patch_element>);
<linear_gradient_element> ::= "<linearGradient" <id_attr>? <gradient_units_attr>? <gradient_transform_attr>? <spread_method_attr>? <x1_attr>? <y1_attr>? <x2_attr>? <y2_attr>? <href_attr>? ">" <stop_element>+ "</linearGradient>";
<radial_gradient_element> ::= "<radialGradient" <id_attr>? <gradient_units_attr>? <gradient_transform_attr>? <spread_method_attr>? <cx_attr>? <cy_attr>? <r_attr> <fx_attr>? <fy_attr>? <fr_attr>? <href_attr>? ">" <stop_element>+ "</radialGradient>";
<stop_element> ::= "<stop" <id_attr>? <offset_attr> <stop_color_attr> <stop_opacity_attr>? <common_attrs> "/>";
<pattern_element> ::= "<pattern" <id_attr>? <pattern_units_attr>? <pattern_content_units_attr>? <pattern_transform_attr>? <x_attr>? <y_attr>? <width_attr> <height_attr> <view_box_attr>? <href_attr>? ">" <svg_content>* "</pattern>";
<marker_element> ::= "<marker" <id_attr>? <marker_units_attr>? <ref_x_attr>? <ref_y_attr>? <marker_width_attr>? <marker_height_attr>? <orient_attr>? <view_box_attr>? <preserve_aspect_attr>? ">" <svg_content>* "</marker>";
<solid_color_element> ::= "<solidColor" <id_attr>? " solid-color=\"" <color> "\"" <solid_opacity_attr>? "/>";
<hatch_element> ::= "<hatch" <id_attr>? <hatch_units_attr>? <hatch_content_units_attr>? <pitch_attr> <rotate_single_attr>? <x_attr>? <y_attr>? ">" <hatch_path_element>+ "</hatch>";
<hatch_path_element> ::= "<hatchpath" <id_attr>? " d=\"" <path_data> "\"" <offset_attr>? <common_attrs> "/>";
<mesh_gradient_element> ::= "<meshgradient" <id_attr>? <x_attr>? <y_attr>? <gradient_units_attr>? <gradient_transform_attr>? <href_attr>? ">" <mesh_row_element>+ "</meshgradient>";
<mesh_row_element> ::= "<meshrow" <id_attr>? ">" <mesh_patch_element>+ "</meshrow>";
<mesh_patch_element> ::= "<meshpatch" <id_attr>? ">" <stop_element>{1,4} "</meshpatch>";

# Clipping and masking.
<clipping_element> ::= (<clip_path_element> | <mask_element>);
<clip_path_element> ::= "<clipPath" <id_attr>? <clip_path_units_attr>? <common_attrs> ">" (<shape_element> | <text_element> | <use_element>)+ "</clipPath>";
<mask_element> ::= "<mask" <id_attr>? <mask_units_attr>? <mask_content_units_attr>? <x_attr>? <y_attr>? <width_attr>? <height_attr>? <common_attrs> ">" <svg_content>* "</mask>";

# Filters and SVG filter primitives.
<filter_element> ::= (<filter_root_element> | <fe_blend_element> | <fe_color_matrix_element> | <fe_component_transfer_element> | <fe_func_r_element> | <fe_func_g_element> | <fe_func_b_element> | <fe_func_a_element> | <fe_composite_element> | <fe_convolve_matrix_element> | <fe_diffuse_lighting_element> | <fe_displacement_map_element> | <fe_distant_light_element> | <fe_drop_shadow_element> | <fe_flood_element> | <fe_gaussian_blur_element> | <fe_image_element> | <fe_merge_element> | <fe_merge_node_element> | <fe_morphology_element> | <fe_offset_element> | <fe_point_light_element> | <fe_specular_lighting_element> | <fe_spot_light_element> | <fe_tile_element> | <fe_turbulence_element>);
<filter_root_element> ::= "<filter" <id_attr>? <filter_units_attr>? <primitive_units_attr>? <x_attr>? <y_attr>? <width_attr>? <height_attr>? <color_interpolation_filters_attr>? <href_attr>? ">" <filter_primitive>+ "</filter>";
<filter_primitive> ::= (<fe_blend_element> | <fe_color_matrix_element> | <fe_component_transfer_element> | <fe_composite_element> | <fe_convolve_matrix_element> | <fe_diffuse_lighting_element> | <fe_displacement_map_element> | <fe_drop_shadow_element> | <fe_flood_element> | <fe_gaussian_blur_element> | <fe_image_element> | <fe_merge_element> | <fe_morphology_element> | <fe_offset_element> | <fe_specular_lighting_element> | <fe_tile_element> | <fe_turbulence_element>);
<fe_blend_element> ::= "<feBlend" <filter_common_attrs> <in_attr>? <in2_attr>? <blend_mode_attr>? "/>";
<fe_color_matrix_element> ::= "<feColorMatrix" <filter_common_attrs> <in_attr>? <color_matrix_type_attr>? <color_matrix_values_attr>? "/>";
<fe_component_transfer_element> ::= "<feComponentTransfer" <filter_common_attrs> <in_attr>? ">" (<fe_func_r_element> | <fe_func_g_element> | <fe_func_b_element> | <fe_func_a_element>)+ "</feComponentTransfer>";
<fe_func_r_element> ::= "<feFuncR" <component_transfer_attrs> "/>";
<fe_func_g_element> ::= "<feFuncG" <component_transfer_attrs> "/>";
<fe_func_b_element> ::= "<feFuncB" <component_transfer_attrs> "/>";
<fe_func_a_element> ::= "<feFuncA" <component_transfer_attrs> "/>";
<fe_composite_element> ::= "<feComposite" <filter_common_attrs> <in_attr>? <in2_attr>? <operator_attr>? <k1_attr>? <k2_attr>? <k3_attr>? <k4_attr>? "/>";
<fe_convolve_matrix_element> ::= "<feConvolveMatrix" <filter_common_attrs> <in_attr>? <order_attr> <kernel_matrix_attr> <divisor_attr>? <bias_attr>? <target_x_attr>? <target_y_attr>? <edge_mode_attr>? <kernel_unit_length_attr>? <preserve_alpha_attr>? "/>";
<fe_diffuse_lighting_element> ::= "<feDiffuseLighting" <filter_common_attrs> <in_attr>? <surface_scale_attr>? <diffuse_constant_attr>? <lighting_color_attr>? ">" <light_source> "</feDiffuseLighting>";
<fe_displacement_map_element> ::= "<feDisplacementMap" <filter_common_attrs> <in_attr>? <in2_attr>? <scale_attr>? <x_channel_selector_attr>? <y_channel_selector_attr>? "/>";
<fe_distant_light_element> ::= "<feDistantLight" <azimuth_attr>? <elevation_attr>? "/>";
<fe_drop_shadow_element> ::= "<feDropShadow" <filter_common_attrs> <in_attr>? <dx_attr>? <dy_attr>? <std_deviation_attr>? <flood_color_attr>? <flood_opacity_attr>? "/>";
<fe_flood_element> ::= "<feFlood" <filter_common_attrs> <flood_color_attr>? <flood_opacity_attr>? "/>";
<fe_gaussian_blur_element> ::= "<feGaussianBlur" <filter_common_attrs> <in_attr>? <std_deviation_attr>? <edge_mode_attr>? "/>";
<fe_image_element> ::= "<feImage" <filter_common_attrs> <href_image_attr> <preserve_aspect_attr>? <crossorigin_attr>? "/>";
<fe_merge_element> ::= "<feMerge" <filter_common_attrs> ">" <fe_merge_node_element>+ "</feMerge>";
<fe_merge_node_element> ::= "<feMergeNode" <in_attr>? "/>";
<fe_morphology_element> ::= "<feMorphology" <filter_common_attrs> <in_attr>? <morphology_operator_attr>? <radius_pair_attr>? "/>";
<fe_offset_element> ::= "<feOffset" <filter_common_attrs> <in_attr>? <dx_attr>? <dy_attr>? "/>";
<fe_point_light_element> ::= "<fePointLight" <x_attr>? <y_attr>? <z_attr>? "/>";
<fe_specular_lighting_element> ::= "<feSpecularLighting" <filter_common_attrs> <in_attr>? <surface_scale_attr>? <specular_constant_attr>? <specular_exponent_attr>? <lighting_color_attr>? ">" <light_source> "</feSpecularLighting>";
<fe_spot_light_element> ::= "<feSpotLight" <x_attr>? <y_attr>? <z_attr>? <points_at_x_attr>? <points_at_y_attr>? <points_at_z_attr>? <specular_exponent_attr>? <limiting_cone_angle_attr>? "/>";
<fe_tile_element> ::= "<feTile" <filter_common_attrs> <in_attr>? "/>";
<fe_turbulence_element> ::= "<feTurbulence" <filter_common_attrs> <base_frequency_attr>? <num_octaves_attr>? <seed_attr>? <stitch_tiles_attr>? <turbulence_type_attr>? "/>";
<light_source> ::= (<fe_distant_light_element> | <fe_point_light_element> | <fe_spot_light_element>);

# SMIL animation.
<animation_element> ::= (<animate_element> | <set_element> | <animate_motion_element> | <mpath_element> | <animate_transform_element> | <discard_element>);
<animate_element> ::= "<animate" <id_attr>? <href_attr>? <attribute_name_attr> <animation_timing_attrs> <animation_value_attrs> <additive_attr>? <accumulate_attr>? "/>";
<set_element> ::= "<set" <id_attr>? <href_attr>? <attribute_name_attr> <animation_timing_attrs> <to_attr> "/>";
<animate_motion_element> ::= "<animateMotion" <id_attr>? <href_attr>? <animation_timing_attrs> <path_attr>? <key_points_attr>? <rotate_motion_attr>? <origin_attr>? ">" <mpath_element>? "</animateMotion>";
<mpath_element> ::= "<mpath" <id_attr>? <href_attr> "/>";
<animate_transform_element> ::= "<animateTransform" <id_attr>? <href_attr>? <attribute_name_attr> <transform_type_attr> <animation_timing_attrs> <animation_value_attrs> <additive_attr>? <accumulate_attr>? "/>";
<discard_element> ::= "<discard" <id_attr>? <href_attr>? <begin_attr>? "/>";

# Scripting and styling.
<script_element> ::= "<script" <id_attr>? <script_type_attr>? <href_script_attr>? ">" <script_text>? "</script>";
<style_element> ::= "<style" <id_attr>? " type=\"text/css\"" <media_attr>? ">" <css_text> "</style>";

# SVG 1.1 fonts and glyphs.
<font_element> ::= (<font_root_element> | <font_face_element> | <font_face_src_element> | <font_face_uri_element> | <font_face_format_element> | <font_face_name_element> | <glyph_element> | <missing_glyph_element> | <hkern_element> | <vkern_element>);
<font_root_element> ::= "<font" <id_attr>? <horiz_origin_x_attr>? <horiz_origin_y_attr>? <horiz_adv_x_attr> <vert_origin_x_attr>? <vert_origin_y_attr>? <vert_adv_y_attr>? ">" <font_face_element> (<glyph_element> | <missing_glyph_element> | <hkern_element> | <vkern_element>)+ "</font>";
<font_face_element> ::= "<font-face" <id_attr>? <font_family_attr> <units_per_em_attr> <ascent_attr>? <descent_attr>? <cap_height_attr>? <x_height_attr>? <alphabetic_attr>? <underline_position_attr>? <underline_thickness_attr>? ">" <font_face_src_element>? "</font-face>";
<font_face_src_element> ::= "<font-face-src>" (<font_face_uri_element> | <font_face_name_element>)+ "</font-face-src>";
<font_face_uri_element> ::= "<font-face-uri" <href_font_attr> ">" <font_face_format_element>? "</font-face-uri>";
<font_face_format_element> ::= "<font-face-format" " string=\"" <font_format> "\"/>";
<font_face_name_element> ::= "<font-face-name" " name=\"" <safe_name> "\"/>";
<glyph_element> ::= "<glyph" <id_attr>? " unicode=\"" <glyph_char> "\"" <glyph_name_attr>? <orientation_attr>? <arabic_form_attr>? <lang_attr>? <horiz_adv_x_attr>? " d=\"" <path_data> "\"/>";
<missing_glyph_element> ::= "<missing-glyph" <id_attr>? <horiz_adv_x_attr>? " d=\"" <path_data> "\"/>";
<hkern_element> ::= "<hkern" (<u1_attr> | <g1_attr>) (<u2_attr> | <g2_attr>) <k_attr> "/>";
<vkern_element> ::= "<vkern" (<u1_attr> | <g1_attr>) (<u2_attr> | <g2_attr>) <k_attr> "/>";

# Shared presentation, geometry, and XML attributes.
<common_attrs> ::= <class_attr>? <style_attr>? <transform_attr>? <fill_attr>? <fill_rule_attr>? <fill_opacity_attr>? <stroke_attr>? <stroke_width_attr>? <stroke_opacity_attr>? <stroke_linecap_attr>? <stroke_linejoin_attr>? <stroke_dasharray_attr>? <opacity_attr>? <display_attr>? <visibility_attr>? <clip_path_attr>? <mask_attr>? <filter_attr>? <vector_effect_attr>? <pointer_events_attr>? <lang_attr>? <tabindex_attr>?;
<id_attr> ::= " id=\"" <xml_id> "\"";
<class_attr> ::= " class=\"" <safe_name> "\"";
<style_attr> ::= " style=\"" <style_declaration> "\"";
<lang_attr> ::= " xml:lang=\"" <language_tag> "\"";
<tabindex_attr> ::= " tabindex=\"" <small_int> "\"";
<target_attr> ::= " target=\"" ("_self" | "_blank" | "_parent" | "_top") "\"";
<media_attr> ::= " media=\"" ("all" | "screen" | "print") "\"";
<crossorigin_attr> ::= " crossorigin=\"" ("anonymous" | "use-credentials") "\"";

<x_attr> ::= " x=\"" <coord> "\"";
<y_attr> ::= " y=\"" <coord> "\"";
<z_attr> ::= " z=\"" <coord> "\"";
<x1_attr> ::= " x1=\"" <coord> "\"";
<y1_attr> ::= " y1=\"" <coord> "\"";
<x2_attr> ::= " x2=\"" <coord> "\"";
<y2_attr> ::= " y2=\"" <coord> "\"";
<cx_attr> ::= " cx=\"" <coord> "\"";
<cy_attr> ::= " cy=\"" <coord> "\"";
<fx_attr> ::= " fx=\"" <coord> "\"";
<fy_attr> ::= " fy=\"" <coord> "\"";
<fr_attr> ::= " fr=\"" <nonnegative_length> "\"";
<r_attr> ::= " r=\"" <positive_length> "\"";
<rx_attr> ::= " rx=\"" <positive_length> "\"";
<ry_attr> ::= " ry=\"" <positive_length> "\"";
<width_attr> ::= " width=\"" <positive_length> "\"";
<height_attr> ::= " height=\"" <positive_length> "\"";
<dx_attr> ::= " dx=\"" <coord> "\"";
<dy_attr> ::= " dy=\"" <coord> "\"";
<rotate_attr> ::= " rotate=\"" <angle> "\"";
<rotate_single_attr> ::= " rotate=\"" <angle> "\"";
<path_length_attr> ::= " pathLength=\"" <positive_number> "\"";
<view_box_attr> ::= " viewBox=\"" <vb_min_x> " " <vb_min_y> " " <vb_width> " " <vb_height> "\"";
<preserve_aspect_attr> ::= " preserveAspectRatio=\"" ("none" | (("xMin" | "xMid" | "xMax") ("YMin" | "YMid" | "YMax") (" meet" | " slice")?)) "\"";
<transform_attr> ::= " transform=\"" <transform_list> "\"";

<fill_attr> ::= " fill=\"" <paint> "\"";
<stroke_attr> ::= " stroke=\"" <paint> "\"";
<fill_rule_attr> ::= " fill-rule=\"" ("nonzero" | "evenodd") "\"";
<fill_opacity_attr> ::= " fill-opacity=\"" <unit_interval> "\"";
<stroke_opacity_attr> ::= " stroke-opacity=\"" <unit_interval> "\"";
<stroke_width_attr> ::= " stroke-width=\"" <nonnegative_length> "\"";
<stroke_linecap_attr> ::= " stroke-linecap=\"" ("butt" | "round" | "square") "\"";
<stroke_linejoin_attr> ::= " stroke-linejoin=\"" ("miter" | "miter-clip" | "round" | "bevel" | "arcs") "\"";
<stroke_dasharray_attr> ::= " stroke-dasharray=\"" ("none" | (<nonnegative_number> (" " <nonnegative_number>){1,5})) "\"";
<opacity_attr> ::= " opacity=\"" <unit_interval> "\"";
<display_attr> ::= " display=\"" ("inline" | "none") "\"";
<visibility_attr> ::= " visibility=\"" ("visible" | "hidden" | "collapse") "\"";
<clip_path_attr> ::= " clip-path=\"url(#" <xml_id> ")\"";
<mask_attr> ::= " mask=\"url(#" <xml_id> ")\"";
<filter_attr> ::= " filter=\"url(#" <xml_id> ")\"";
<vector_effect_attr> ::= " vector-effect=\"" ("none" | "non-scaling-stroke") "\"";
<pointer_events_attr> ::= " pointer-events=\"" ("bounding-box" | "visiblePainted" | "visibleFill" | "visibleStroke" | "visible" | "painted" | "fill" | "stroke" | "all" | "none") "\"";

# Text attributes.
<text_attrs> ::= <text_anchor_attr>? <dominant_baseline_attr>? <font_family_css_attr>? <font_size_attr>? <font_style_attr>? <font_weight_attr>? <letter_spacing_attr>? <word_spacing_attr>? <text_decoration_attr>? <writing_mode_attr>? <direction_attr>? <unicode_bidi_attr>? <length_adjust_attr>? <text_length_attr>?;
<text_anchor_attr> ::= " text-anchor=\"" ("start" | "middle" | "end") "\"";
<dominant_baseline_attr> ::= " dominant-baseline=\"" ("auto" | "text-bottom" | "alphabetic" | "ideographic" | "middle" | "central" | "mathematical" | "hanging" | "text-top") "\"";
<font_family_css_attr> ::= " font-family=\"" <safe_name> "\"";
<font_size_attr> ::= " font-size=\"" <positive_length> "\"";
<font_style_attr> ::= " font-style=\"" ("normal" | "italic" | "oblique") "\"";
<font_weight_attr> ::= " font-weight=\"" ("normal" | "bold" | "100" | "200" | "300" | "400" | "500" | "600" | "700" | "800" | "900") "\"";
<letter_spacing_attr> ::= " letter-spacing=\"" ("normal" | <coord>) "\"";
<word_spacing_attr> ::= " word-spacing=\"" ("normal" | <coord>) "\"";
<text_decoration_attr> ::= " text-decoration=\"" ("none" | "underline" | "overline" | "line-through") "\"";
<writing_mode_attr> ::= " writing-mode=\"" ("horizontal-tb" | "vertical-rl" | "vertical-lr") "\"";
<direction_attr> ::= " direction=\"" ("ltr" | "rtl") "\"";
<unicode_bidi_attr> ::= " unicode-bidi=\"" ("normal" | "embed" | "isolate" | "bidi-override" | "isolate-override" | "plaintext") "\"";
<length_adjust_attr> ::= " lengthAdjust=\"" ("spacing" | "spacingAndGlyphs") "\"";
<text_length_attr> ::= " textLength=\"" <nonnegative_length> "\"";
<start_offset_attr> ::= " startOffset=\"" <length_or_percent> "\"";
<method_attr> ::= " method=\"" ("align" | "stretch") "\"";
<spacing_attr> ::= " spacing=\"" ("auto" | "exact") "\"";

# Resource references.
<href_attr> ::= " href=\"#" <xml_id> "\"";
<href_image_attr> ::= " href=\"data:image/svg+xml,%3Csvg/%3E\"";
<href_media_attr> ::= " href=\"media.bin\"";
<href_script_attr> ::= " href=\"script.js\"";
<href_font_attr> ::= " xlink:href=\"font.woff\"";

# Gradient, pattern, marker, clipping, and mask attributes.
<gradient_units_attr> ::= " gradientUnits=\"" ("userSpaceOnUse" | "objectBoundingBox") "\"";
<gradient_transform_attr> ::= " gradientTransform=\"" <transform_list> "\"";
<spread_method_attr> ::= " spreadMethod=\"" ("pad" | "reflect" | "repeat") "\"";
<offset_attr> ::= " offset=\"" <unit_interval> "\"";
<stop_color_attr> ::= " stop-color=\"" <color> "\"";
<stop_opacity_attr> ::= " stop-opacity=\"" <unit_interval> "\"";
<solid_opacity_attr> ::= " solid-opacity=\"" <unit_interval> "\"";
<pattern_units_attr> ::= " patternUnits=\"" ("userSpaceOnUse" | "objectBoundingBox") "\"";
<pattern_content_units_attr> ::= " patternContentUnits=\"" ("userSpaceOnUse" | "objectBoundingBox") "\"";
<pattern_transform_attr> ::= " patternTransform=\"" <transform_list> "\"";
<marker_units_attr> ::= " markerUnits=\"" ("strokeWidth" | "userSpaceOnUse") "\"";
<ref_x_attr> ::= " refX=\"" <coord> "\"";
<ref_y_attr> ::= " refY=\"" <coord> "\"";
<marker_width_attr> ::= " markerWidth=\"" <positive_length> "\"";
<marker_height_attr> ::= " markerHeight=\"" <positive_length> "\"";
<orient_attr> ::= " orient=\"" ("auto" | "auto-start-reverse" | <angle>) "\"";
<hatch_units_attr> ::= " hatchUnits=\"" ("userSpaceOnUse" | "objectBoundingBox") "\"";
<hatch_content_units_attr> ::= " hatchContentUnits=\"" ("userSpaceOnUse" | "objectBoundingBox") "\"";
<pitch_attr> ::= " pitch=\"" <positive_length> "\"";
<clip_path_units_attr> ::= " clipPathUnits=\"" ("userSpaceOnUse" | "objectBoundingBox") "\"";
<mask_units_attr> ::= " maskUnits=\"" ("userSpaceOnUse" | "objectBoundingBox") "\"";
<mask_content_units_attr> ::= " maskContentUnits=\"" ("userSpaceOnUse" | "objectBoundingBox") "\"";

# Filter attributes.
<filter_common_attrs> ::= <id_attr>? <x_attr>? <y_attr>? <width_attr>? <height_attr>? <result_attr>?;
<filter_units_attr> ::= " filterUnits=\"" ("userSpaceOnUse" | "objectBoundingBox") "\"";
<primitive_units_attr> ::= " primitiveUnits=\"" ("userSpaceOnUse" | "objectBoundingBox") "\"";
<color_interpolation_filters_attr> ::= " color-interpolation-filters=\"" ("auto" | "sRGB" | "linearRGB") "\"";
<result_attr> ::= " result=\"" <safe_name> "\"";
<in_attr> ::= " in=\"" <filter_input> "\"";
<in2_attr> ::= " in2=\"" <filter_input> "\"";
<filter_input> ::= ("SourceGraphic" | "SourceAlpha" | "BackgroundImage" | "BackgroundAlpha" | "FillPaint" | "StrokePaint" | <safe_name>);
<blend_mode_attr> ::= " mode=\"" ("normal" | "multiply" | "screen" | "darken" | "lighten" | "overlay" | "color-dodge" | "color-burn" | "hard-light" | "soft-light" | "difference" | "exclusion" | "hue" | "saturation" | "color" | "luminosity") "\"";
<color_matrix_type_attr> ::= " type=\"" ("matrix" | "saturate" | "hueRotate" | "luminanceToAlpha") "\"";
<color_matrix_values_attr> ::= " values=\"" <signed_number> (" " <signed_number>){0,19} "\"";
<component_transfer_attrs> ::= <component_type_attr> <table_values_attr>? <slope_attr>? <intercept_attr>? <amplitude_attr>? <exponent_attr>? <offset_number_attr>?;
<component_type_attr> ::= " type=\"" ("identity" | "table" | "discrete" | "linear" | "gamma") "\"";
<table_values_attr> ::= " tableValues=\"" <signed_number> (" " <signed_number>){1,7} "\"";
<slope_attr> ::= " slope=\"" <signed_number> "\"";
<intercept_attr> ::= " intercept=\"" <signed_number> "\"";
<amplitude_attr> ::= " amplitude=\"" <nonnegative_number> "\"";
<exponent_attr> ::= " exponent=\"" <nonnegative_number> "\"";
<offset_number_attr> ::= " offset=\"" <signed_number> "\"";
<operator_attr> ::= " operator=\"" ("over" | "in" | "out" | "atop" | "xor" | "lighter" | "arithmetic") "\"";
<k1_attr> ::= " k1=\"" <signed_number> "\"";
<k2_attr> ::= " k2=\"" <signed_number> "\"";
<k3_attr> ::= " k3=\"" <signed_number> "\"";
<k4_attr> ::= " k4=\"" <signed_number> "\"";
<order_attr> ::= " order=\"" <kernel_order> "\"";
<kernel_matrix_attr> ::= " kernelMatrix=\"" <signed_number> (" " <signed_number>){0,8} "\"";
<divisor_attr> ::= " divisor=\"" <nonzero_number> "\"";
<bias_attr> ::= " bias=\"" <signed_number> "\"";
<target_x_attr> ::= " targetX=\"" <kernel_index> "\"";
<target_y_attr> ::= " targetY=\"" <kernel_index> "\"";
<edge_mode_attr> ::= " edgeMode=\"" ("duplicate" | "wrap" | "none") "\"";
<kernel_unit_length_attr> ::= " kernelUnitLength=\"" <positive_number> (" " <positive_number>)? "\"";
<preserve_alpha_attr> ::= " preserveAlpha=\"" ("true" | "false") "\"";
<surface_scale_attr> ::= " surfaceScale=\"" <signed_number> "\"";
<diffuse_constant_attr> ::= " diffuseConstant=\"" <nonnegative_number> "\"";
<lighting_color_attr> ::= " lighting-color=\"" <color> "\"";
<scale_attr> ::= " scale=\"" <signed_number> "\"";
<x_channel_selector_attr> ::= " xChannelSelector=\"" ("R" | "G" | "B" | "A") "\"";
<y_channel_selector_attr> ::= " yChannelSelector=\"" ("R" | "G" | "B" | "A") "\"";
<azimuth_attr> ::= " azimuth=\"" <angle> "\"";
<elevation_attr> ::= " elevation=\"" <bounded_angle> "\"";
<std_deviation_attr> ::= " stdDeviation=\"" <nonnegative_number> (" " <nonnegative_number>)? "\"";
<flood_color_attr> ::= " flood-color=\"" <color> "\"";
<flood_opacity_attr> ::= " flood-opacity=\"" <unit_interval> "\"";
<morphology_operator_attr> ::= " operator=\"" ("erode" | "dilate") "\"";
<radius_pair_attr> ::= " radius=\"" <nonnegative_number> (" " <nonnegative_number>)? "\"";
<points_at_x_attr> ::= " pointsAtX=\"" <coord> "\"";
<points_at_y_attr> ::= " pointsAtY=\"" <coord> "\"";
<points_at_z_attr> ::= " pointsAtZ=\"" <coord> "\"";
<specular_constant_attr> ::= " specularConstant=\"" <nonnegative_number> "\"";
<specular_exponent_attr> ::= " specularExponent=\"" <specular_exponent> "\"";
<limiting_cone_angle_attr> ::= " limitingConeAngle=\"" <cone_angle> "\"";
<base_frequency_attr> ::= " baseFrequency=\"" <positive_fraction> (" " <positive_fraction>)? "\"";
<num_octaves_attr> ::= " numOctaves=\"" <octave_count> "\"";
<seed_attr> ::= " seed=\"" <signed_number> "\"";
<stitch_tiles_attr> ::= " stitchTiles=\"" ("stitch" | "noStitch") "\"";
<turbulence_type_attr> ::= " type=\"" ("fractalNoise" | "turbulence") "\"";

# Animation attributes and timing/value semantics.
<animation_timing_attrs> ::= <begin_attr>? <dur_attr> <end_attr>? <min_attr>? <max_attr>? <restart_attr>? <repeat_count_attr>? <repeat_dur_attr>? <fill_timing_attr>?;
<animation_value_attrs> ::= (<from_attr> <to_attr> | <from_attr> <by_attr> | <values_attr>) <calc_mode_attr>? <key_times_attr>? <key_splines_attr>?;
<attribute_name_attr> ::= " attributeName=\"" <animatable_attribute> "\"";
<begin_attr> ::= " begin=\"" <clock_value> "\"";
<dur_attr> ::= " dur=\"" <positive_clock> "s\"";
<end_attr> ::= " end=\"" <clock_value> "\"";
<min_attr> ::= " min=\"" <nonnegative_clock> "s\"";
<max_attr> ::= " max=\"" <positive_clock> "s\"";
<restart_attr> ::= " restart=\"" ("always" | "whenNotActive" | "never") "\"";
<repeat_count_attr> ::= " repeatCount=\"" ("indefinite" | <positive_number>) "\"";
<repeat_dur_attr> ::= " repeatDur=\"" ("indefinite" | (<positive_clock> "s")) "\"";
<fill_timing_attr> ::= " fill=\"" ("remove" | "freeze") "\"";
<from_attr> ::= " from=\"" <animation_value> "\"";
<to_attr> ::= " to=\"" <animation_value> "\"";
<by_attr> ::= " by=\"" <animation_value> "\"";
<values_attr> ::= " values=\"" <animation_value> ";" <animation_value> (";" <animation_value>){0,4} "\"";
<calc_mode_attr> ::= " calcMode=\"" ("discrete" | "linear" | "paced" | "spline") "\"";
<key_times_attr> ::= " keyTimes=\"0;1\"";
<key_splines_attr> ::= " keySplines=\"" <unit_interval> " " <unit_interval> " " <unit_interval> " " <unit_interval> "\"";
<additive_attr> ::= " additive=\"" ("replace" | "sum") "\"";
<accumulate_attr> ::= " accumulate=\"" ("none" | "sum") "\"";
<path_attr> ::= " path=\"" <path_data> "\"";
<key_points_attr> ::= " keyPoints=\"0;1\"";
<rotate_motion_attr> ::= " rotate=\"" ("auto" | "auto-reverse" | <angle>) "\"";
<origin_attr> ::= " origin=\"default\"";
<transform_type_attr> ::= " type=\"" ("translate" | "scale" | "rotate" | "skewX" | "skewY") "\"";

# Script/style lexical content.
<script_type_attr> ::= " type=\"application/ecmascript\"";
<script_text> ::= "var n=1;";
<css_text> ::= ".shape{fill:" <color> ";stroke:" <color> ";}";
<style_declaration> ::= "fill:" <color> ";stroke:" <color>;

# Legacy font attributes.
<horiz_origin_x_attr> ::= " horiz-origin-x=\"" <coord> "\"";
<horiz_origin_y_attr> ::= " horiz-origin-y=\"" <coord> "\"";
<horiz_adv_x_attr> ::= " horiz-adv-x=\"" <nonnegative_number> "\"";
<vert_origin_x_attr> ::= " vert-origin-x=\"" <coord> "\"";
<vert_origin_y_attr> ::= " vert-origin-y=\"" <coord> "\"";
<vert_adv_y_attr> ::= " vert-adv-y=\"" <nonnegative_number> "\"";
<font_family_attr> ::= " font-family=\"" <safe_name> "\"";
<units_per_em_attr> ::= " units-per-em=\"" <positive_int> "\"";
<ascent_attr> ::= " ascent=\"" <signed_number> "\"";
<descent_attr> ::= " descent=\"" <signed_number> "\"";
<cap_height_attr> ::= " cap-height=\"" <nonnegative_number> "\"";
<x_height_attr> ::= " x-height=\"" <nonnegative_number> "\"";
<alphabetic_attr> ::= " alphabetic=\"" <signed_number> "\"";
<underline_position_attr> ::= " underline-position=\"" <signed_number> "\"";
<underline_thickness_attr> ::= " underline-thickness=\"" <nonnegative_number> "\"";
<glyph_name_attr> ::= " glyph-name=\"" <safe_name> "\"";
<orientation_attr> ::= " orientation=\"" ("h" | "v") "\"";
<arabic_form_attr> ::= " arabic-form=\"" ("initial" | "medial" | "terminal" | "isolated") "\"";
<u1_attr> ::= " u1=\"" <glyph_char> "\"";
<u2_attr> ::= " u2=\"" <glyph_char> "\"";
<g1_attr> ::= " g1=\"" <safe_name> "\"";
<g2_attr> ::= " g2=\"" <safe_name> "\"";
<k_attr> ::= " k=\"" <signed_number> "\"";
<font_format> ::= ("woff" | "woff2" | "truetype" | "opentype" | "svg");

# Lexical primitives with semantic range constraints.
<xml_id> ::= r'[A-Za-z][A-Za-z0-9_-]{0,11}';
<safe_name> ::= r'[A-Za-z][A-Za-z0-9_-]{0,11}';
<language_tag> ::= ("en" | "de" | "fr" | "es" | "ja" | "ar");
<text_node> ::= r'[A-Za-z0-9 .,!?-]{1,24}';
<glyph_char> ::= r'[A-Za-z0-9]';
<small_int> ::= r'-?[0-9]{1,2}'
where -99 <= int(<small_int>) <= 99;
<positive_int> ::= r'[1-9][0-9]{0,3}'
where 1 <= int(<positive_int>) <= 4096;
<nonnegative_int> ::= r'[0-9]{1,3}'
where 0 <= int(<nonnegative_int>) <= 999;
<octave_count> ::= r'[1-9]'
where 1 <= int(<octave_count>) <= 9;
<kernel_order> ::= r'[1-3]( [1-3])?';
<kernel_index> ::= r'[0-2]'
where 0 <= int(<kernel_index>) <= 2;
<coord> ::= r'-?[0-9]{1,3}'
where -999 <= int(<coord>) <= 999;
<signed_number> ::= r'-?[0-9]{1,3}'
where -999 <= int(<signed_number>) <= 999;
<nonzero_number> ::= r'-?[1-9][0-9]{0,2}'
where -999 <= int(<nonzero_number>) <= 999 and int(<nonzero_number>) != 0;
<nonnegative_number> ::= r'[0-9]{1,3}'
where 0 <= int(<nonnegative_number>) <= 999;
<positive_number> ::= r'[1-9][0-9]{0,2}'
where 0 < int(<positive_number>) <= 999;
<unit_interval> ::= ("0" | "1");
<positive_fraction> ::= "1";
<positive_length> ::= <positive_number> <length_unit>?;
<nonnegative_length> ::= <nonnegative_number> <length_unit>?;
<length_or_percent> ::= (<nonnegative_length> | (<unit_interval> "%"));
<length_unit> ::= ("px" | "pt" | "pc" | "mm" | "cm" | "in" | "em" | "ex");
<angle> ::= r'-?[0-9]{1,3}'
where -360 <= int(<angle>) <= 360;
<bounded_angle> ::= r'-?[0-9]{1,2}'
where -90 <= int(<bounded_angle>) <= 90;
<cone_angle> ::= r'[0-9]{1,2}'
where 0 <= int(<cone_angle>) <= 90;
<specular_exponent> ::= r'[1-9][0-9]?'
where 1 <= int(<specular_exponent>) <= 128;
<positive_clock> ::= r'[1-9][0-9]{0,2}'
where 0 < int(<positive_clock>) <= 999;
<nonnegative_clock> ::= r'[0-9]{1,3}'
where 0 <= int(<nonnegative_clock>) <= 999;
<clock_value> ::= (<nonnegative_clock> "s" | "indefinite");
<vb_min_x> ::= <coord>;
<vb_min_y> ::= <coord>;
<vb_width> ::= <positive_number>;
<vb_height> ::= <positive_number>;

<point_pair> ::= <coord> "," <coord>;
<path_data> ::= "M " <coord> " " <coord> " " <path_segment> (" " <path_segment>){0,5};
<path_segment> ::= (<line_to> | <horizontal_to> | <vertical_to> | <cubic_to> | <quadratic_to> | <arc_to> | <close_path>);
<line_to> ::= "L " <coord> " " <coord>;
<horizontal_to> ::= "H " <coord>;
<vertical_to> ::= "V " <coord>;
<cubic_to> ::= "C " <coord> " " <coord> " " <coord> " " <coord> " " <coord> " " <coord>;
<quadratic_to> ::= "Q " <coord> " " <coord> " " <coord> " " <coord>;
<arc_to> ::= "A " <positive_number> " " <positive_number> " " <angle> " " <flag> " " <flag> " " <coord> " " <coord>;
<close_path> ::= "Z";
<flag> ::= ("0" | "1");
<transform_list> ::= <transform_fn> (" " <transform_fn>){0,3};
<transform_fn> ::= ("translate(" <coord> ("," <coord>)? ")" | "scale(" <positive_number> ("," <positive_number>)? ")" | "rotate(" <angle> ("," <coord> "," <coord>)? ")" | "skewX(" <angle> ")" | "skewY(" <angle> ")" | "matrix(" <signed_number> "," <signed_number> "," <signed_number> "," <signed_number> "," <signed_number> "," <signed_number> ")");
<paint> ::= ("none" | "currentColor" | <color> | ("url(#" <xml_id> ")"));
<color> ::= (<named_color> | ("#" <hex_digit>{6}) | ("rgb(" <rgb_channel> "," <rgb_channel> "," <rgb_channel> ")"));
<named_color> ::= ("black" | "white" | "red" | "green" | "blue" | "yellow" | "cyan" | "magenta" | "gray" | "orange" | "purple" | "transparent");
<hex_digit> ::= r'[0-9A-Fa-f]';
<rgb_channel> ::= r'[0-9]{1,3}'
where 0 <= int(<rgb_channel>) <= 255;
<animation_value> ::= (<signed_number> | <color> | <coord> | <safe_name>);
<animatable_attribute> ::= ("x" | "y" | "cx" | "cy" | "r" | "width" | "height" | "opacity" | "fill" | "stroke" | "stroke-width" | "transform" | "d");
