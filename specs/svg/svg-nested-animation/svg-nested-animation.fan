# Same as svg, grounded directly in the SVG 2 recommendation, with SMIL
# <animate> elements nested as children of the shape they animate instead
# of appearing as unrelated top-level siblings.

import random

# ─────────────────────────────────────────────────────────────────────────────
# Top-level document
# ─────────────────────────────────────────────────────────────────────────────

<start> ::= <svg_doc>
<svg_doc> ::= <xml_decl> <svg_open> <svg_content> <svg_close>
<xml_decl> ::= ('<?xml version="1.0" encoding="UTF-8"?>\n' | '<?xml version="1.0"?>\n' | '')
<svg_open> ::= ('<svg xmlns="http://www.w3.org/2000/svg"' ' xmlns:xlink="http://www.w3.org/1999/xlink"' ' ' <svg_dims> <svg_attr>* '>\n')
<svg_dims> ::= ('width="' <length_val> '" height="' <length_val> '"' | 'viewBox="' <viewbox_val> '"' | 'width="' <length_val> '" height="' <length_val> '" viewBox="' <viewbox_val> '"')
<viewbox_val> ::= <num> ' ' <num> ' ' <num> ' ' <num>
<svg_attr> ::= (' version="2.0"' | ' preserveAspectRatio="' <par_val> '"' | ' id="' <id_val> '"' | ' class="' <class_val> '"' | ' style="' <style_decls> '"' | ' transform="' <transform_list> '"')
<par_val> ::= ('none' | 'xMinYMin' | 'xMidYMid' | 'xMaxYMax' | 'xMinYMid' | 'xMidYMin' | 'xMaxYMin' | 'xMinYMax' | 'xMidYMax' | 'xMaxYMid' | 'xMidYMid meet' | 'xMidYMid slice')
<svg_close> ::= '</svg>\n'

# ─────────────────────────────────────────────────────────────────────────────
# SVG body content
# ─────────────────────────────────────────────────────────────────────────────

<svg_content> ::= <defs_section>? <svg_element>+
<defs_section> ::= '<defs>\n' <def_item>+ '</defs>\n'
<def_item> ::= (<gradient_linear> | <gradient_radial> | <pattern_def> | <clippath_def> | <mask_def> | <filter_def> | <marker_def> | <symbol_def>)
<svg_element> ::= (<shape_elem> | <text_elem> | <image_elem> | <group_elem> | <use_elem> | <a_elem> | <switch_elem> | <animate_elem> | <foreignobj_elem>)

# ─────────────────────────────────────────────────────────────────────────────
# Shapes
# ─────────────────────────────────────────────────────────────────────────────

<shape_elem> ::= (<rect_elem> | <circle_elem> | <ellipse_elem> | <line_elem> | <polyline_elem> | <polygon_elem> | <path_elem>)

<common_attr> ::= (' id="' <id_val> '"' | ' class="' <class_val> '"' | ' style="' <style_decls> '"' | ' transform="' <transform_list> '"' | ' clip-path="url(#' <id_val> ')"' | ' mask="url(#' <id_val> ')"' | ' filter="url(#' <id_val> ')"' | ' opacity="' <opacity_val> '"' | ' visibility="' <visibility_val> '"' | ' display="' <display_val> '"' | ' pointer-events="' <pointer_events_val> '"')

<pres_attr> ::= (' fill="' <paint_val> '"' | ' fill-opacity="' <opacity_val> '"' | ' fill-rule="' <fill_rule_val> '"' | ' stroke="' <paint_val> '"' | ' stroke-opacity="' <opacity_val> '"' | ' stroke-width="' <length_val> '"' | ' stroke-linecap="' <linecap_val> '"' | ' stroke-linejoin="' <linejoin_val> '"' | ' stroke-miterlimit="' <num> '"' | ' stroke-dasharray="' <dasharray_val> '"' | ' stroke-dashoffset="' <length_val> '"' | ' marker-start="url(#' <id_val> ')"' | ' marker-mid="url(#' <id_val> ')"' | ' marker-end="url(#' <id_val> ')"' | ' color="' <color_val> '"' | ' shape-rendering="' <shape_rendering_val> '"' | ' vector-effect="' <vector_effect_val> '"' | ' paint-order="' <paint_order_val> '"')

<rect_elem> ::= ('<rect' <common_attr>* <pres_attr>* ' x="' <coord> '"' ' y="' <coord> '"' ' width="' <length_val> '"' ' height="' <length_val> '"' <rect_rounding>? '/>\n' | '<rect' <common_attr>* <pres_attr>* ' x="' <coord> '"' ' y="' <coord> '"' ' width="' <length_val> '"' ' height="' <length_val> '"' <rect_rounding>? '>\n' <animate_child>* '</rect>\n')
<rect_rounding> ::= (' rx="' <length_val> '"' | ' ry="' <length_val> '"' | ' rx="' <length_val> '" ry="' <length_val> '"')

<circle_elem> ::= ('<circle' <common_attr>* <pres_attr>* ' cx="' <coord> '"' ' cy="' <coord> '"' ' r="' <length_val> '"' '/>\n' | '<circle' <common_attr>* <pres_attr>* ' cx="' <coord> '"' ' cy="' <coord> '"' ' r="' <length_val> '"' '>\n' <animate_child>* '</circle>\n')

<ellipse_elem> ::= '<ellipse' <common_attr>* <pres_attr>* ' cx="' <coord> '"' ' cy="' <coord> '"' ' rx="' <length_val> '"' ' ry="' <length_val> '"' '/>\n'

<line_elem> ::= '<line' <common_attr>* <pres_attr>* ' x1="' <coord> '"' ' y1="' <coord> '"' ' x2="' <coord> '"' ' y2="' <coord> '"' '/>\n'

<polyline_elem> ::= '<polyline' <common_attr>* <pres_attr>* ' points="' <points_val> '"' '/>\n'

<polygon_elem> ::= '<polygon' <common_attr>* <pres_attr>* ' points="' <points_val> '"' '/>\n'

<path_elem> ::= ('<path' <common_attr>* <pres_attr>* ' d="' <path_data> '"' <path_extra>? '/>\n' | '<path' <common_attr>* <pres_attr>* ' d="' <path_data> '"' <path_extra>? '>\n' <animate_child>* '</path>\n')
<path_extra> ::= ' pathLength="' <num> '"'

<path_data> ::= <path_cmd>+
<path_cmd> ::= <moveto> <drawto_cmd>*
<moveto> ::= ('M ' <coord_pair> | 'm ' <coord_pair>)
<drawto_cmd> ::= (<lineto> | <hlineto> | <vlineto> | <curveto> | <smooth_curveto> | <quad_bezier> | <smooth_quad> | <arc_cmd> | <closepath>)
<lineto>         ::= (' L ' <coord_pair> | ' l ' <coord_pair>)
<hlineto>        ::= (' H ' <num> | ' h ' <num>)
<vlineto>        ::= (' V ' <num> | ' v ' <num>)
<curveto>        ::= (' C ' <coord_pair> ' ' <coord_pair> ' ' <coord_pair> | ' c ' <coord_pair> ' ' <coord_pair> ' ' <coord_pair>)
<smooth_curveto> ::= (' S ' <coord_pair> ' ' <coord_pair> | ' s ' <coord_pair> ' ' <coord_pair>)
<quad_bezier>    ::= (' Q ' <coord_pair> ' ' <coord_pair> | ' q ' <coord_pair> ' ' <coord_pair>)
<smooth_quad>    ::= (' T ' <coord_pair> | ' t ' <coord_pair>)
<arc_cmd>        ::= (' A ' <arc_args> | ' a ' <arc_args>)
<closepath>      ::= (' Z' | ' z')
<arc_args> ::= <num> ' ' <num> ' ' <num> ' ' <arc_flag> ' ' <arc_flag> ' ' <coord_pair>
<arc_flag> ::= ('0' | '1')
<coord_pair> ::= <coord> ',' <coord>

# ─────────────────────────────────────────────────────────────────────────────
# Text
# ─────────────────────────────────────────────────────────────────────────────

<text_elem> ::= '<text' <common_attr>* <pres_attr>* <text_pos_attr>* <text_pres_attr>* '>' <text_content_item>* '</text>\n'

<text_pos_attr> ::= (' x="' <coord> '"' | ' y="' <coord> '"' | ' dx="' <length_val> '"' | ' dy="' <length_val> '"' | ' rotate="' <num> '"' | ' textLength="' <length_val> '"' | ' lengthAdjust="' <length_adjust_val> '"')

<text_pres_attr> ::= (' font-family="' <font_family_val> '"' | ' font-size="' <font_size_val> '"' | ' font-style="' <font_style_val> '"' | ' font-weight="' <font_weight_val> '"' | ' font-variant="' <font_variant_val> '"' | ' text-anchor="' <text_anchor_val> '"' | ' text-decoration="' <text_decoration_val> '"' | ' dominant-baseline="' <dominant_baseline_val> '"' | ' alignment-baseline="' <alignment_baseline_val> '"' | ' baseline-shift="' <baseline_shift_val> '"' | ' word-spacing="' <length_val> '"' | ' letter-spacing="' <length_val> '"' | ' writing-mode="' <writing_mode_val> '"' | ' direction="' <direction_val> '"')

<text_content_item> ::= (<tspan_elem> | <text_str> | <textpath_elem>)
<tspan_elem> ::= '<tspan' <text_pos_attr>* <text_pres_attr>* <pres_attr>* '>' <text_str> '</tspan>'
<textpath_elem> ::= '<textPath href="#' <id_val> '"' <textpath_attr>* '>' <text_str> '</textPath>'
<textpath_attr> ::= (' method="' <textpath_method_val> '"' | ' spacing="' <textpath_spacing_val> '"' | ' startOffset="' <length_val> '"')
<text_str> ::= r'[A-Za-z0-9 !?.,;:\-]{1,40}'

# ─────────────────────────────────────────────────────────────────────────────
# Image
# ─────────────────────────────────────────────────────────────────────────────

<image_elem> ::= '<image' <common_attr>* <pres_attr>* ' x="' <coord> '"' ' y="' <coord> '"' ' width="' <length_val> '"' ' height="' <length_val> '"' ' href="' <image_href> '"' <image_extra_attr>? '/>\n'
<image_href> ::= ('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==' | 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjwvc3ZnPg==')
<image_extra_attr> ::= (' preserveAspectRatio="' <par_val> '"' | ' crossorigin="anonymous"')

# ─────────────────────────────────────────────────────────────────────────────
# Group, use, anchor, switch, foreignObject
# ─────────────────────────────────────────────────────────────────────────────

<group_elem> ::= '<g' <common_attr>* <pres_attr>* '>\n' <svg_element>+ '</g>\n'

<use_elem> ::= '<use' <common_attr>* <pres_attr>* ' href="#' <id_val> '"' ' x="' <coord> '"' ' y="' <coord> '"' ' width="' <length_val> '"' ' height="' <length_val> '"' '/>\n'

<a_elem> ::= '<a href="' <href_val> '"' <a_attr>* '>\n' <svg_element> '</a>\n'
<a_attr> ::= (' target="' <target_val> '"' | ' type="' <mime_type_val> '"' | ' download="' <id_val> '"')
<href_val>      ::= ('#' <id_val> | 'https://example.com')
<target_val>    ::= ('_self' | '_blank' | '_parent' | '_top')
<mime_type_val> ::= ('image/svg+xml' | 'text/html' | 'application/octet-stream')

<switch_elem> ::= '<switch' <common_attr>* '>\n' <shape_elem> '</switch>\n'

<foreignobj_elem> ::= '<foreignObject' <common_attr>* ' x="' <coord> '"' ' y="' <coord> '"' ' width="' <length_val> '"' ' height="' <length_val> '"' '>\n' '<div xmlns="http://www.w3.org/1999/xhtml">' <text_str> '</div>\n' '</foreignObject>\n'

# ─────────────────────────────────────────────────────────────────────────────
# Gradients
# ─────────────────────────────────────────────────────────────────────────────

<gradient_linear> ::= '<linearGradient id="' <id_val> '"' <linear_grad_attr>* '>\n' <stop_elem>+ '</linearGradient>\n'
<gradient_radial> ::= '<radialGradient id="' <id_val> '"' <radial_grad_attr>* '>\n' <stop_elem>+ '</radialGradient>\n'

<linear_grad_attr> ::= (' x1="' <length_val> '"' | ' y1="' <length_val> '"' | ' x2="' <length_val> '"' | ' y2="' <length_val> '"' | ' gradientUnits="' <gradient_units_val> '"' | ' gradientTransform="' <transform_list> '"' | ' spreadMethod="' <spread_method_val> '"' | ' href="#' <id_val> '"')

<radial_grad_attr> ::= (' cx="' <length_val> '"' | ' cy="' <length_val> '"' | ' r="' <length_val> '"' | ' fx="' <length_val> '"' | ' fy="' <length_val> '"' | ' fr="' <length_val> '"' | ' gradientUnits="' <gradient_units_val> '"' | ' gradientTransform="' <transform_list> '"' | ' spreadMethod="' <spread_method_val> '"')

<stop_elem> ::= '<stop offset="' <offset_val> '"' ' stop-color="' <color_val> '"' <stop_opacity_attr>? '/>\n'
<stop_opacity_attr> ::= ' stop-opacity="' <opacity_val> '"'
<gradient_units_val> ::= ('userSpaceOnUse' | 'objectBoundingBox')
<spread_method_val>  ::= ('pad' | 'reflect' | 'repeat')
<offset_val>         ::= (<num_01> | <percentage_val>)

# ─────────────────────────────────────────────────────────────────────────────
# Pattern
# ─────────────────────────────────────────────────────────────────────────────

<pattern_def> ::= '<pattern id="' <id_val> '"' ' x="' <coord> '"' ' y="' <coord> '"' ' width="' <length_val> '"' ' height="' <length_val> '"' <pattern_attr>* '>\n' <shape_elem> '</pattern>\n'
<pattern_attr> ::= (' patternUnits="' <gradient_units_val> '"' | ' patternContentUnits="' <gradient_units_val> '"' | ' patternTransform="' <transform_list> '"' | ' viewBox="' <viewbox_val> '"' | ' preserveAspectRatio="' <par_val> '"')

# ─────────────────────────────────────────────────────────────────────────────
# clipPath, mask
# ─────────────────────────────────────────────────────────────────────────────

<clippath_def> ::= '<clipPath id="' <id_val> '"' <clippath_attr>? '>\n' <shape_elem> '</clipPath>\n'
<clippath_attr> ::= (' clipPathUnits="' <gradient_units_val> '"' | ' transform="' <transform_list> '"')

<mask_def> ::= '<mask id="' <id_val> '"' <mask_attr>* '>\n' <shape_elem> '</mask>\n'
<mask_attr> ::= (' x="' <coord> '"' | ' y="' <coord> '"' | ' width="' <length_val> '"' | ' height="' <length_val> '"' | ' maskUnits="' <gradient_units_val> '"' | ' maskContentUnits="' <gradient_units_val> '"')

# ─────────────────────────────────────────────────────────────────────────────
# filter
# ─────────────────────────────────────────────────────────────────────────────

<filter_def> ::= '<filter id="' <id_val> '"' <filter_attr>* '>\n' <filter_primitive>+ '</filter>\n'
<filter_attr> ::= (' x="' <length_val> '"' | ' y="' <length_val> '"' | ' width="' <length_val> '"' | ' height="' <length_val> '"' | ' filterUnits="' <gradient_units_val> '"' | ' primitiveUnits="' <gradient_units_val> '"' | ' color-interpolation-filters="' <color_interp_val> '"')

<filter_primitive> ::= (<fe_gaussian_blur> | <fe_color_matrix> | <fe_blend> | <fe_composite> | <fe_displacement_map> | <fe_flood> | <fe_image_fe> | <fe_merge> | <fe_morphology> | <fe_offset> | <fe_turbulence> | <fe_convolve_matrix> | <fe_component_transfer> | <fe_diffuse_lighting> | <fe_specular_lighting> | <fe_tile>)

<fe_common_attr> ::= (' result="' <id_val> '"' | ' in="' <fe_in_val> '"' | ' x="' <length_val> '"' | ' y="' <length_val> '"' | ' width="' <length_val> '"' | ' height="' <length_val> '"')
<fe_in_val> ::= ('SourceGraphic' | 'SourceAlpha' | 'BackgroundImage' | 'BackgroundAlpha' | 'FillPaint' | 'StrokePaint' | <id_val>)

<fe_gaussian_blur>     ::= '<feGaussianBlur' <fe_common_attr>* ' stdDeviation="' <num> '"' ' edgeMode="' <edge_mode_val> '"' '/>\n'
<fe_color_matrix>      ::= ('<feColorMatrix' <fe_common_attr>* ' type="' <color_matrix_type> '"' '/>\n' | '<feColorMatrix' <fe_common_attr>* ' type="' <color_matrix_type> '"' ' values="' <num> '"' '/>\n')
<color_matrix_type>    ::= ('matrix' | 'saturate' | 'hueRotate' | 'luminanceToAlpha')
<fe_blend>             ::= '<feBlend' <fe_common_attr>* ' in2="' <fe_in_val> '"' ' mode="' <blend_mode_val> '"' '/>\n'
<blend_mode_val>       ::= ('normal' | 'multiply' | 'screen' | 'overlay' | 'darken' | 'lighten' | 'color-dodge' | 'color-burn' | 'hard-light' | 'soft-light' | 'difference' | 'exclusion' | 'hue' | 'saturation' | 'color' | 'luminosity')
<fe_composite>         ::= '<feComposite' <fe_common_attr>* ' in2="' <fe_in_val> '"' ' operator="' <composite_op_val> '"' '/>\n'
<composite_op_val>     ::= ('over' | 'in' | 'out' | 'atop' | 'xor' | 'lighter' | 'arithmetic')
<fe_displacement_map>  ::= '<feDisplacementMap' <fe_common_attr>* ' in2="' <fe_in_val> '"' ' scale="' <num> '"' ' xChannelSelector="' <channel_selector_val> '"' ' yChannelSelector="' <channel_selector_val> '"' '/>\n'
<channel_selector_val> ::= ('R' | 'G' | 'B' | 'A')
<fe_flood>             ::= '<feFlood' <fe_common_attr>* ' flood-color="' <color_val> '"' ' flood-opacity="' <opacity_val> '"' '/>\n'
<fe_image_fe>          ::= '<feImage' <fe_common_attr>* ' href="' <image_href> '"' '/>\n'
<fe_merge>             ::= '<feMerge' <fe_common_attr>* '>\n' <fe_merge_node>+ '</feMerge>\n'
<fe_merge_node>        ::= '<feMergeNode in="' <fe_in_val> '"/>\n'
<fe_morphology>        ::= '<feMorphology' <fe_common_attr>* ' operator="' <morph_op_val> '"' ' radius="' <num> '"' '/>\n'
<morph_op_val>         ::= ('erode' | 'dilate')
<fe_offset>            ::= '<feOffset' <fe_common_attr>* ' dx="' <num> '"' ' dy="' <num> '"' '/>\n'
<fe_turbulence>        ::= '<feTurbulence' <fe_common_attr>* ' type="' <turbulence_type_val> '"' ' baseFrequency="' <num> '"' ' numOctaves="' <int_val> '"' ' seed="' <int_val> '"' ' stitchTiles="' <stitch_tiles_val> '"' '/>\n'
<turbulence_type_val>  ::= ('fractalNoise' | 'turbulence')
<stitch_tiles_val>     ::= ('stitch' | 'noStitch')
<edge_mode_val>        ::= ('duplicate' | 'wrap' | 'none')
<fe_convolve_matrix>   ::= '<feConvolveMatrix' <fe_common_attr>* ' order="' <int_val> '"' ' kernelMatrix="' <matrix3x3_val> '"' ' divisor="' <num> '"' ' bias="' <num> '"' ' edgeMode="' <edge_mode_val> '"' '/>\n'
<matrix3x3_val> ::= <num> ' ' <num> ' ' <num> ' ' <num> ' ' <num> ' ' <num> ' ' <num> ' ' <num> ' ' <num>
<fe_component_transfer> ::= '<feComponentTransfer' <fe_common_attr>* '>\n' '<feFuncR type="' <transfer_type_val> '"/>\n' '<feFuncG type="' <transfer_type_val> '"/>\n' '<feFuncB type="' <transfer_type_val> '"/>\n' '<feFuncA type="' <transfer_type_val> '"/>\n' '</feComponentTransfer>\n'
<transfer_type_val>    ::= ('identity' | 'linear' | 'gamma' | 'table' | 'discrete')
<fe_diffuse_lighting>  ::= '<feDiffuseLighting' <fe_common_attr>* ' surfaceScale="' <num> '"' ' diffuseConstant="' <num> '"' ' lighting-color="' <color_val> '"' '>\n' <light_source> '</feDiffuseLighting>\n'
<fe_specular_lighting> ::= '<feSpecularLighting' <fe_common_attr>* ' surfaceScale="' <num> '"' ' specularConstant="' <num> '"' ' specularExponent="' <num> '"' ' lighting-color="' <color_val> '"' '>\n' <light_source> '</feSpecularLighting>\n'
<light_source> ::= ('<fePointLight x="' <num> '" y="' <num> '" z="' <num> '"/>\n' | '<feSpotLight x="' <num> '" y="' <num> '" z="' <num> '"' ' pointsAtX="' <num> '" pointsAtY="' <num> '" pointsAtZ="' <num> '"' ' limitingConeAngle="' <num> '"' '/>\n' | '<feDistantLight azimuth="' <num> '" elevation="' <num> '"/>\n')
<fe_tile> ::= '<feTile' <fe_common_attr>* '/>\n'

# ─────────────────────────────────────────────────────────────────────────────
# marker, symbol
# ─────────────────────────────────────────────────────────────────────────────

<marker_def> ::= '<marker id="' <id_val> '"' <marker_attr>* '>\n' <shape_elem> '</marker>\n'
<marker_attr> ::= (' viewBox="' <viewbox_val> '"' | ' markerWidth="' <length_val> '"' | ' markerHeight="' <length_val> '"' | ' refX="' <coord> '"' | ' refY="' <coord> '"' | ' markerUnits="' <marker_units_val> '"' | ' orient="' <marker_orient_val> '"')
<marker_units_val>  ::= ('strokeWidth' | 'userSpaceOnUse')
<marker_orient_val> ::= ('auto' | 'auto-start-reverse' | <num>)

<symbol_def> ::= '<symbol id="' <id_val> '"' <symbol_attr>* '>\n' <shape_elem> '</symbol>\n'
<symbol_attr> ::= (' viewBox="' <viewbox_val> '"' | ' preserveAspectRatio="' <par_val> '"' | ' refX="' <coord> '"' | ' refY="' <coord> '"' | ' overflow="' <overflow_val> '"')
<overflow_val> ::= ('visible' | 'hidden' | 'scroll' | 'auto')

# ─────────────────────────────────────────────────────────────────────────────
# Animation elements
# ─────────────────────────────────────────────────────────────────────────────

<animate_elem> ::= (<animate_simple> | <animate_transform> | <animate_motion> | <set_elem>)
<animate_child> ::= (<animate_simple> | <animate_transform> | <animate_motion> | <set_elem>)
<animate_simple>    ::= '<animate' <animate_attr>* '/>\n'
<animate_transform> ::= '<animateTransform' <animate_attr>* ' type="' <animate_transform_type> '"' '/>\n'
<animate_transform_type> ::= ('translate' | 'scale' | 'rotate' | 'skewX' | 'skewY')
<animate_motion>    ::= '<animateMotion' <animate_timing_attr>* <anim_motion_attr>* '/>\n'
<anim_motion_attr>  ::= (' path="' <path_data> '"' | ' rotate="' <anim_motion_rotate_val> '"')
<anim_motion_rotate_val> ::= ('auto' | 'auto-reverse' | <num>)
<set_elem>          ::= '<set' <animate_attr>* '/>\n'

<animate_attr> ::= (' attributeName="' <animate_attr_name> '"' | ' from="' <animate_val> '"' | ' to="' <animate_val> '"' | ' by="' <animate_val> '"' | ' values="' <animate_val> ';' <animate_val> '"' | ' keyTimes="0;1"' | ' calcMode="' <calc_mode_val> '"' | ' additive="' <additive_val> '"' | ' accumulate="' <accumulate_val> '"' | <animate_timing_attr>)

<animate_timing_attr> ::= (' dur="' <clock_val> '"' | ' begin="' <animate_begin_val> '"' | ' end="' <clock_val> '"' | ' repeatCount="' <repeat_count_val> '"' | ' repeatDur="' <clock_val> '"' | ' fill="' <animate_fill_val> '"' | ' restart="' <restart_val> '"')

<animate_attr_name>  ::= ('cx' | 'cy' | 'r' | 'x' | 'y' | 'width' | 'height' | 'fill' | 'stroke' | 'opacity' | 'transform' | 'd' | 'viewBox' | 'color' | 'font-size' | 'stroke-width' | 'stroke-dasharray' | 'rx' | 'ry')
<animate_val>        ::= (<color_val> | <num> | <length_val>)
<animate_begin_val>  ::= ('0s' | '0' | 'indefinite' | <clock_val>)
<repeat_count_val>   ::= ('indefinite' | <int_val>)
<animate_fill_val>   ::= ('freeze' | 'remove')
<restart_val>        ::= ('always' | 'whenNotActive' | 'never')
<calc_mode_val>      ::= ('discrete' | 'linear' | 'paced' | 'spline')
<additive_val>       ::= ('replace' | 'sum')
<accumulate_val>     ::= ('none' | 'sum')
<clock_val>          ::= (<num> 's' | <num> 'ms')

# ─────────────────────────────────────────────────────────────────────────────
# Transforms
# ─────────────────────────────────────────────────────────────────────────────

<transform_list> ::= <transform_item> (' ' <transform_item>)*
<transform_item> ::= ('translate(' <num> ',' <num> ')' | 'scale(' <num> ')' | 'scale(' <num> ',' <num> ')' | 'rotate(' <num> ')' | 'rotate(' <num> ',' <num> ',' <num> ')' | 'skewX(' <num> ')' | 'skewY(' <num> ')' | 'matrix(' <num> ',' <num> ',' <num> ',' <num> ',' <num> ',' <num> ')')

# ─────────────────────────────────────────────────────────────────────────────
# Paint values
# ─────────────────────────────────────────────────────────────────────────────

<paint_val> ::= ('none' | 'currentColor' | <color_val> | 'url(#' <id_val> ')' | 'url(#' <id_val> ') ' <color_val> | 'context-fill' | 'context-stroke')

<color_val> ::= (<named_color> | '#' <hex_color> | 'rgb(' <color_component> ',' <color_component> ',' <color_component> ')' | 'rgba(' <color_component> ',' <color_component> ',' <color_component> ',' <opacity_val> ')' | 'hsl(' <hue_val> ',' <percentage_val> ',' <percentage_val> ')' | 'hsla(' <hue_val> ',' <percentage_val> ',' <percentage_val> ',' <opacity_val> ')')

<named_color> ::= ('red' | 'green' | 'blue' | 'black' | 'white' | 'yellow' | 'orange' | 'purple' | 'pink' | 'cyan' | 'magenta' | 'lime' | 'navy' | 'teal' | 'maroon' | 'silver' | 'gray' | 'transparent' | 'aliceblue' | 'aquamarine' | 'bisque' | 'blueviolet' | 'burlywood' | 'cadetblue' | 'chartreuse' | 'chocolate' | 'coral' | 'cornflowerblue' | 'crimson' | 'darkblue' | 'darkcyan' | 'darkgray' | 'darkgreen' | 'darkorange' | 'darkred' | 'darkviolet' | 'deepskyblue' | 'dodgerblue' | 'firebrick' | 'forestgreen' | 'fuchsia' | 'gainsboro' | 'goldenrod' | 'hotpink' | 'indianred' | 'indigo' | 'lavender' | 'lawngreen' | 'lightblue' | 'lightcoral' | 'lightcyan' | 'lightgreen' | 'lightpink' | 'lightsalmon' | 'lightseagreen' | 'lightskyblue' | 'lightsteelblue' | 'mediumblue' | 'mediumorchid' | 'mediumpurple' | 'mediumseagreen' | 'mediumslateblue' | 'mediumturquoise' | 'mediumvioletred' | 'midnightblue' | 'mintcream' | 'mistyrose' | 'navajowhite' | 'olivedrab' | 'orangered' | 'orchid' | 'palegoldenrod' | 'palegreen' | 'paleturquoise' | 'palevioletred' | 'papayawhip' | 'peachpuff' | 'peru' | 'plum' | 'powderblue' | 'rosybrown' | 'royalblue' | 'saddlebrown' | 'salmon' | 'sandybrown' | 'seagreen' | 'sienna' | 'skyblue' | 'slateblue' | 'slategray' | 'snow' | 'springgreen' | 'steelblue' | 'tan' | 'thistle' | 'tomato' | 'turquoise' | 'violet' | 'wheat' | 'yellowgreen')

<hex_color>         ::= (r'[0-9a-fA-F]{3}' | r'[0-9a-fA-F]{6}' | r'[0-9a-fA-F]{8}')
<color_component>   ::= (r'[0-9]{1,3}' | r'[0-9]{1,3}%')
<hue_val>           ::= r'[0-9]{1,3}'

# ─────────────────────────────────────────────────────────────────────────────
# Numeric / length values
# ─────────────────────────────────────────────────────────────────────────────

<length_val>     ::= <num> <length_unit>?
<length_unit>    ::= ('px' | 'pt' | 'pc' | 'mm' | 'cm' | 'in' | 'em' | 'ex' | 'rem' | 'vw' | 'vh' | 'vmin' | 'vmax' | '%')
<coord>          ::= <num>
<num>            ::= r'-?[0-9]{1,4}(\.[0-9]{1,4})?'
<int_val>        ::= r'[0-9]{1,4}'
<num_01>         ::= (r'0(\.[0-9]{1,4})?' | '1')
<percentage_val> ::= r'[0-9]{1,3}%'
<opacity_val>    ::= <num_01>

<points_val>     ::= <coord_pair> (' ' <coord_pair>)+

# ─────────────────────────────────────────────────────────────────────────────
# Style declarations (inline CSS)
# ─────────────────────────────────────────────────────────────────────────────

<style_decls> ::= <style_decl> (';' <style_decl>)*
<style_decl>  ::= ('fill:' <paint_val> | 'stroke:' <paint_val> | 'stroke-width:' <length_val> | 'opacity:' <opacity_val> | 'display:' <display_val> | 'visibility:' <visibility_val> | 'font-size:' <font_size_val> | 'font-family:' <font_family_val> | 'overflow:' <overflow_val> | 'clip-path:url(#' <id_val> ')' | 'mask:url(#' <id_val> ')' | 'filter:url(#' <id_val> ')')

# ─────────────────────────────────────────────────────────────────────────────
# ID / class name
# ─────────────────────────────────────────────────────────────────────────────

<id_val>    ::= r'[a-zA-Z][a-zA-Z0-9_-]{0,15}'
<class_val> ::= r'[a-z][a-z0-9-]{0,10}'

# ─────────────────────────────────────────────────────────────────────────────
# Enumerated property values
# ─────────────────────────────────────────────────────────────────────────────

<fill_rule_val>          ::= ('nonzero' | 'evenodd')
<linecap_val>            ::= ('butt' | 'round' | 'square')
<linejoin_val>           ::= ('miter' | 'miter-clip' | 'round' | 'bevel' | 'arcs')
<visibility_val>         ::= ('visible' | 'hidden' | 'collapse')
<display_val>            ::= ('inline' | 'block' | 'none')
<pointer_events_val>     ::= ('none' | 'all' | 'fill' | 'stroke' | 'painted' | 'visible' | 'visibleFill' | 'visibleStroke' | 'visiblePainted')
<color_interp_val>       ::= ('auto' | 'sRGB' | 'linearRGB')
<shape_rendering_val>    ::= ('auto' | 'optimizeSpeed' | 'crispEdges' | 'geometricPrecision')
<text_rendering_val>     ::= ('auto' | 'optimizeSpeed' | 'optimizeLegibility' | 'geometricPrecision')
<vector_effect_val>      ::= ('none' | 'non-scaling-stroke' | 'non-scaling-size' | 'non-rotation' | 'fixed-position')
<paint_order_val>        ::= ('normal' | 'fill stroke' | 'stroke fill' | 'fill markers' | 'stroke markers')
<dasharray_val>          ::= ('none' | <length_val> ' ' <length_val>)
<font_family_val>        ::= ('serif' | 'sans-serif' | 'monospace' | 'cursive' | 'fantasy' | 'Arial' | 'Georgia' | 'Verdana' | 'Impact')
<font_size_val>          ::= (<length_val> | 'xx-small' | 'x-small' | 'small' | 'medium' | 'large' | 'x-large' | 'xx-large')
<font_style_val>         ::= ('normal' | 'italic' | 'oblique')
<font_weight_val>        ::= ('normal' | 'bold' | 'bolder' | 'lighter' | '100' | '200' | '300' | '400' | '500' | '600' | '700' | '800' | '900')
<font_variant_val>       ::= ('normal' | 'small-caps')
<text_anchor_val>        ::= ('start' | 'middle' | 'end')
<text_decoration_val>    ::= ('none' | 'underline' | 'overline' | 'line-through')
<dominant_baseline_val>  ::= ('auto' | 'middle' | 'central' | 'hanging' | 'mathematical' | 'alphabetic' | 'ideographic' | 'text-before-edge' | 'text-after-edge')
<alignment_baseline_val> ::= ('auto' | 'baseline' | 'before-edge' | 'text-before-edge' | 'middle' | 'central' | 'after-edge' | 'text-after-edge' | 'ideographic' | 'alphabetic' | 'hanging' | 'mathematical')
<baseline_shift_val>     ::= ('baseline' | 'sub' | 'super' | <length_val>)
<length_adjust_val>      ::= ('spacing' | 'spacingAndGlyphs')
<writing_mode_val>       ::= ('lr-tb' | 'rl-tb' | 'tb-rl' | 'lr' | 'rl' | 'tb' | 'horizontal-tb' | 'vertical-rl' | 'vertical-lr')
<direction_val>          ::= ('ltr' | 'rtl')
<unicode_bidi_val>       ::= ('normal' | 'embed' | 'bidi-override')
<textpath_method_val>    ::= ('align' | 'stretch')
<textpath_spacing_val>   ::= ('auto' | 'exact')


