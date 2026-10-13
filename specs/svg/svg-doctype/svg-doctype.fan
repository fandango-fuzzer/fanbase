# Same as svg, with every element's optional presentation attributes
# toggled individually and a choice of legacy DOCTYPE/DTD declarations
# (or none).

# PRIMITIVE VALUE TYPES (defined early, used everywhere)

<number>      ::= r'-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?'
<pos_number>  ::= r'[0-9]+(\.[0-9]+)?'
<integer_val> ::= r'-?[0-9]+'
<byte_val>    ::= r'(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])'
<alpha_val>   ::= r'(0(\.[0-9]+)?|1(\.0+)?)'
<pct_val>     ::= r'(100|[0-9]{1,2})%'
<hex3>        ::= r'[0-9a-fA-F]{3}'
<hex6>        ::= r'[0-9a-fA-F]{6}'
<hex8>        ::= r'[0-9a-fA-F]{8}'
<id_val>      ::= r'[a-zA-Z][a-zA-Z0-9_\-]*'
<name_val>    ::= r'[a-zA-Z][a-zA-Z0-9_\-]*'
<text_chars>  ::= r'[A-Za-z0-9 .,!?;:\-]*'
<number_list> ::= <number> (' ' <number>)*
<_>           ::= ' '

# TOP-LEVEL DOCUMENT

<start> ::= <xml_decl> <doctype> <svg_element>

<xml_decl>  ::= ('<?xml version="1.0" encoding="UTF-8"?>\n' | '<?xml version="1.1" encoding="UTF-8"?>\n' | '')
<doctype>   ::= ('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n' | '<!DOCTYPE svg>\n' | '')

# ROOT SVG ELEMENT

<svg_element> ::= '<svg ' <xmlns_attr> <svg_dim_attrs> '>\n' <svg_content>* '</svg>\n'

<xmlns_attr> ::= ('xmlns="http://www.w3.org/2000/svg"' | 'xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"')

<svg_dim_attrs> ::= (' viewBox="' <number> ' ' <number> ' ' <pos_number> ' ' <pos_number> '"' | '') \
                    (' width="' <length_val> '" height="' <length_val> '"' | '')

# SVG CONTENT

<svg_content> ::= (<desc_element> | <title_element> | <defs_element> | <use_element> | \
    <g_element> | <symbol_element> | <switch_element> | <image_element> | \
    <shape_element> | <text_element> | <gradient_element> | <pattern_element> | \
    <clippath_element> | <mask_element> | <marker_element> | <filter_element> | \
    <animate_element> | <style_element> | <foreignobject_element> | <comment_node>)

# STRUCTURAL ELEMENTS

<g_element>       ::= '<g' <common_attrs> '>\n' <svg_content>* '</g>\n'
<defs_element>    ::= '<defs>\n' <def_content>* '</defs>\n'
<symbol_element>  ::= '<symbol' <common_attrs> <viewbox_opt> '>\n' <svg_content>* '</symbol>\n'
<switch_element>  ::= '<switch' <common_attrs> '>\n' <svg_content>* '</switch>\n'
<desc_element>    ::= '<desc>' <text_chars> '</desc>\n'
<title_element>   ::= '<title>' <text_chars> '</title>\n'
<comment_node>    ::= '<!-- ' <text_chars> ' -->\n'

<viewbox_opt> ::= (' viewBox="' <number> ' ' <number> ' ' <pos_number> ' ' <pos_number> '"' | '')

<def_content> ::= (<shape_element> | <g_element> | <gradient_element> | <pattern_element> | \
    <clippath_element> | <mask_element> | <marker_element> | <filter_element> | \
    <symbol_element> | <text_element>)

<use_element> ::= '<use' <common_attrs> \
    (' x="' <number> '"' | '') (' y="' <number> '"' | '') \
    (' width="' <length_val> '"' | '') (' height="' <length_val> '"' | '') \
    <href_opt> '/>\n'

<href_opt> ::= (' href="#' <id_val> '"' | ' xlink:href="#' <id_val> '"' | '')

<image_element> ::= '<image' <common_attrs> \
    (' x="' <number> '"' | '') (' y="' <number> '"' | '') \
    (' width="' <length_val> '"' | '') (' height="' <length_val> '"' | '') \
    (' preserveAspectRatio="' <preserve_ar> '"' | '') \
    <href_opt> '/>\n'

<foreignobject_element> ::= '<foreignObject' <common_attrs> \
    (' x="' <number> '"' | '') (' y="' <number> '"' | '') \
    (' width="' <length_val> '"' | '') (' height="' <length_val> '"' | '') \
    '></foreignObject>\n'

<style_element> ::= ('<style type="text/css"><![CDATA[\n' <css_rule>* ']]></style>\n' | '<style/>\n')

<css_rule>     ::= <css_selector> ' { ' <css_decl> ' }\n'
<css_selector> ::= ('svg' | 'rect' | 'circle' | 'path' | 'ellipse' | 'text' | '*' | '.cls')
<css_decl>     ::= ('fill: ' <color_val> | 'stroke: ' <color_val> | 'opacity: ' <alpha_val> | 'display: none' | 'visibility: hidden')

# SHAPE ELEMENTS

<shape_element> ::= (<rect_element> | <circle_element> | <ellipse_element> | \
    <line_element> | <polyline_element> | <polygon_element> | <path_element>)

<rect_element>     ::= '<rect' <common_attrs> \
    (' x="' <number> '"' | '') (' y="' <number> '"' | '') \
    (' width="' <length_val> '"' | '') (' height="' <length_val> '"' | '') \
    (' rx="' <pos_number> '"' | '') (' ry="' <pos_number> '"' | '') '/>\n'

<circle_element>   ::= '<circle' <common_attrs> \
    (' cx="' <number> '"' | '') (' cy="' <number> '"' | '') \
    (' r="' <pos_number> '"' | '') '/>\n'

<ellipse_element>  ::= '<ellipse' <common_attrs> \
    (' cx="' <number> '"' | '') (' cy="' <number> '"' | '') \
    (' rx="' <pos_number> '"' | '') (' ry="' <pos_number> '"' | '') '/>\n'

<line_element>     ::= '<line' <common_attrs> \
    (' x1="' <number> '"' | '') (' y1="' <number> '"' | '') \
    (' x2="' <number> '"' | '') (' y2="' <number> '"' | '') '/>\n'

<polyline_element> ::= '<polyline' <common_attrs> \
    (' points="' <points_list> '"' | '') '/>\n'

<polygon_element>  ::= '<polygon' <common_attrs> \
    (' points="' <points_list> '"' | '') '/>\n'

<path_element>     ::= '<path' <common_attrs> \
    (' d="' <path_data> '"' | '') \
    (' pathLength="' <pos_number> '"' | '') '/>\n'

<points_list> ::= <number> ',' <number> (' ' <number> ',' <number>)*

# PATH DATA

<path_data>     ::= <path_cmd>+

<path_cmd> ::= (<moveto> | <lineto> | <hlineto> | <vlineto> | <curveto> | \
    <smooth_curveto> | <quadto> | <smooth_quadto> | <arcto> | <closepath>)

<moveto>         ::= ('M' | 'm') ' ' <number> ',' <number>
<lineto>         ::= ('L' | 'l') ' ' <number> ',' <number>
<hlineto>        ::= ('H' | 'h') ' ' <number>
<vlineto>        ::= ('V' | 'v') ' ' <number>
<curveto>        ::= ('C' | 'c') ' ' <number> ',' <number> ' ' <number> ',' <number> ' ' <number> ',' <number>
<smooth_curveto> ::= ('S' | 's') ' ' <number> ',' <number> ' ' <number> ',' <number>
<quadto>         ::= ('Q' | 'q') ' ' <number> ',' <number> ' ' <number> ',' <number>
<smooth_quadto>  ::= ('T' | 't') ' ' <number> ',' <number>
<arcto>          ::= ('A' | 'a') ' ' <pos_number> ' ' <pos_number> ' ' <number> ' ' <arc_flag> ' ' <arc_flag> ' ' <number> ',' <number>
<closepath>      ::= ('Z' | 'z')
<arc_flag>       ::= ('0' | '1')

# TEXT ELEMENTS

<text_element> ::= '<text' <common_attrs> \
    (' x="' <number> '"' | '') (' y="' <number> '"' | '') \
    (' dx="' <number> '"' | '') (' dy="' <number> '"' | '') \
    (' text-anchor="' <text_anchor_val> '"' | '') \
    (' dominant-baseline="' <baseline_val> '"' | '') \
    (' font-family="' <font_family> '"' | '') \
    (' font-size="' <pos_number> '"' | '') \
    (' font-weight="' <font_weight> '"' | '') \
    (' textLength="' <pos_number> '"' | '') \
    (' lengthAdjust="' <length_adjust_val> '"' | '') \
    '>' <text_content>* '</text>\n'

<text_content>   ::= (<text_chars> | <tspan_element> | <textpath_element>)

<tspan_element>  ::= '<tspan' <common_attrs> \
    (' x="' <number> '"' | '') (' y="' <number> '"' | '') \
    (' dx="' <number> '"' | '') (' dy="' <number> '"' | '') \
    '>' <text_content>* '</tspan>'

<textpath_element> ::= '<textPath' <href_opt> \
    (' startOffset="' <length_val> '"' | '') \
    (' method="' <textpath_method> '"' | '') \
    '>' <text_chars> '</textPath>'

<textpath_method>   ::= ('align' | 'stretch')
<length_adjust_val> ::= ('spacing' | 'spacingAndGlyphs')
<text_anchor_val>   ::= ('start' | 'middle' | 'end')
<baseline_val>      ::= ('auto' | 'middle' | 'central' | 'hanging' | 'mathematical' | 'alphabetic')

# GRADIENT ELEMENTS

<gradient_element> ::= (<linear_gradient> | <radial_gradient>)

<linear_gradient> ::= '<linearGradient' <common_attrs> \
    (' x1="' <length_val> '"' | '') (' y1="' <length_val> '"' | '') \
    (' x2="' <length_val> '"' | '') (' y2="' <length_val> '"' | '') \
    (' gradientUnits="' <gradient_units> '"' | '') \
    (' gradientTransform="' <transform_list> '"' | '') \
    (' spreadMethod="' <spread_method> '"' | '') <href_opt> \
    '>\n' <stop_element>* '</linearGradient>\n'

<radial_gradient> ::= '<radialGradient' <common_attrs> \
    (' cx="' <length_val> '"' | '') (' cy="' <length_val> '"' | '') \
    (' r="' <length_val> '"' | '') (' fx="' <length_val> '"' | '') \
    (' fy="' <length_val> '"' | '') (' fr="' <length_val> '"' | '') \
    (' gradientUnits="' <gradient_units> '"' | '') \
    (' gradientTransform="' <transform_list> '"' | '') \
    (' spreadMethod="' <spread_method> '"' | '') <href_opt> \
    '>\n' <stop_element>* '</radialGradient>\n'

<stop_element>   ::= '<stop' \
    (' offset="' <alpha_val> '"' | '') \
    (' stop-color="' <color_val> '"' | '') \
    (' stop-opacity="' <alpha_val> '"' | '') '/>\n'

<gradient_units> ::= ('userSpaceOnUse' | 'objectBoundingBox')
<spread_method>  ::= ('pad' | 'reflect' | 'repeat')

# PATTERN

<pattern_element> ::= '<pattern' <common_attrs> \
    (' x="' <number> '"' | '') (' y="' <number> '"' | '') \
    (' width="' <length_val> '"' | '') (' height="' <length_val> '"' | '') \
    (' patternUnits="' <gradient_units> '"' | '') \
    (' patternContentUnits="' <gradient_units> '"' | '') \
    (' patternTransform="' <transform_list> '"' | '') \
    <viewbox_opt> <href_opt> \
    '>\n' <svg_content>* '</pattern>\n'

# CLIPPATH / MASK

<clippath_element> ::= '<clipPath' <common_attrs> \
    (' clipPathUnits="' <gradient_units> '"' | '') \
    '>\n' <shape_element>* '</clipPath>\n'

<mask_element> ::= '<mask' <common_attrs> \
    (' x="' <number> '"' | '') (' y="' <number> '"' | '') \
    (' width="' <length_val> '"' | '') (' height="' <length_val> '"' | '') \
    (' maskUnits="' <gradient_units> '"' | '') \
    (' maskContentUnits="' <gradient_units> '"' | '') \
    '>\n' <svg_content>* '</mask>\n'

# MARKER

<marker_element> ::= '<marker' <common_attrs> \
    (' markerWidth="' <length_val> '"' | '') \
    (' markerHeight="' <length_val> '"' | '') \
    (' refX="' <number> '"' | '') (' refY="' <number> '"' | '') \
    (' markerUnits="' <marker_units> '"' | '') \
    (' orient="' <marker_orient> '"' | '') \
    <viewbox_opt> \
    '>\n' <svg_content>* '</marker>\n'

<marker_units>  ::= ('strokeWidth' | 'userSpaceOnUse')
<marker_orient> ::= ('auto' | 'auto-start-reverse' | <number>)

# FILTER

<filter_element> ::= '<filter' <common_attrs> \
    (' x="' <number> '"' | '') (' y="' <number> '"' | '') \
    (' width="' <length_val> '"' | '') (' height="' <length_val> '"' | '') \
    (' filterUnits="' <gradient_units> '"' | '') \
    (' primitiveUnits="' <gradient_units> '"' | '') \
    '>\n' <filter_primitive>* '</filter>\n'

<filter_primitive> ::= (<fe_blend> | <fe_color_matrix> | <fe_component_transfer> | \
    <fe_composite> | <fe_convolve_matrix> | <fe_diffuse_lighting> | \
    <fe_displacement_map> | <fe_flood> | <fe_gaussian_blur> | <fe_image> | \
    <fe_merge> | <fe_morphology> | <fe_offset> | <fe_specular_lighting> | \
    <fe_tile> | <fe_turbulence>)

<fe_common> ::= (' in="' <fe_in_val> '"' | '') (' result="' <name_val> '"' | '') \
    (' x="' <number> '"' | '') (' y="' <number> '"' | '') \
    (' width="' <length_val> '"' | '') (' height="' <length_val> '"' | '')

<fe_in_val> ::= ('SourceGraphic' | 'SourceAlpha' | 'BackgroundImage' | \
    'BackgroundAlpha' | 'FillPaint' | 'StrokePaint')

<fe_in2> ::= (' in2="' <fe_in_val> '"' | '')

<fe_blend>   ::= '<feBlend' <fe_common> <fe_in2> \
    (' mode="' <blend_mode> '"' | '') '/>\n'

<blend_mode> ::= ('normal' | 'multiply' | 'screen' | 'overlay' | 'darken' | \
    'lighten' | 'color-dodge' | 'color-burn' | 'hard-light' | 'soft-light' | \
    'difference' | 'exclusion' | 'hue' | 'saturation' | 'color' | 'luminosity')

<fe_color_matrix> ::= '<feColorMatrix' <fe_common> \
    (' type="' <color_matrix_type> '"' | '') \
    (' values="' <number_list> '"' | '') '/>\n'

<color_matrix_type> ::= ('matrix' | 'saturate' | 'hueRotate' | 'luminanceToAlpha')

<fe_component_transfer> ::= '<feComponentTransfer' <fe_common> '>\n' <fe_func>* '</feComponentTransfer>\n'

<fe_func> ::= ('<feFuncR' <fe_func_attrs> '/>\n' | '<feFuncG' <fe_func_attrs> '/>\n' | \
    '<feFuncB' <fe_func_attrs> '/>\n' | '<feFuncA' <fe_func_attrs> '/>\n')

<fe_func_attrs> ::= ' type="' <fe_func_type> '"' \
    (' tableValues="' <number_list> '"' | '') \
    (' slope="' <number> '"' | '') \
    (' intercept="' <number> '"' | '') \
    (' amplitude="' <number> '"' | '') \
    (' exponent="' <number> '"' | '')

<fe_func_type> ::= ('identity' | 'table' | 'discrete' | 'linear' | 'gamma')

<fe_composite> ::= '<feComposite' <fe_common> <fe_in2> \
    (' operator="' <composite_op> '"' | '') \
    (' k1="' <number> '"' | '') (' k2="' <number> '"' | '') \
    (' k3="' <number> '"' | '') (' k4="' <number> '"' | '') '/>\n'

<composite_op> ::= ('over' | 'in' | 'out' | 'atop' | 'xor' | 'lighter' | 'arithmetic')

<fe_convolve_matrix> ::= '<feConvolveMatrix' <fe_common> \
    ' order="' <integer_val> ' ' <integer_val> '"' \
    (' kernelMatrix="' <number_list> '"' | '') \
    (' divisor="' <number> '"' | '') (' bias="' <number> '"' | '') \
    (' targetX="' <integer_val> '"' | '') (' targetY="' <integer_val> '"' | '') \
    (' edgeMode="' <edge_mode> '"' | '') \
    (' preserveAlpha="' <bool_val> '"' | '') '/>\n'

<edge_mode> ::= ('duplicate' | 'wrap' | 'none')

<fe_diffuse_lighting> ::= '<feDiffuseLighting' <fe_common> \
    (' surfaceScale="' <number> '"' | '') \
    (' diffuseConstant="' <number> '"' | '') \
    '>\n' <light_source> '</feDiffuseLighting>\n'

<fe_displacement_map> ::= '<feDisplacementMap' <fe_common> <fe_in2> \
    (' scale="' <number> '"' | '') \
    (' xChannelSelector="' <channel_sel> '"' | '') \
    (' yChannelSelector="' <channel_sel> '"' | '') '/>\n'

<channel_sel> ::= ('R' | 'G' | 'B' | 'A')

<fe_flood> ::= '<feFlood' <fe_common> \
    (' flood-color="' <color_val> '"' | '') \
    (' flood-opacity="' <alpha_val> '"' | '') '/>\n'

<fe_gaussian_blur> ::= '<feGaussianBlur' <fe_common> \
    (' stdDeviation="' <number_pair> '"' | '') \
    (' edgeMode="' <edge_mode> '"' | '') '/>\n'

<number_pair> ::= (<pos_number> | <pos_number> ' ' <pos_number>)

<fe_image>     ::= '<feImage' <fe_common> <href_opt> '/>\n'

<fe_merge>     ::= '<feMerge' <fe_common> '>\n' <fe_merge_node>* '</feMerge>\n'
<fe_merge_node>::= '<feMergeNode' (' in="' <fe_in_val> '"' | '') '/>\n'

<fe_morphology>::= '<feMorphology' <fe_common> \
    (' operator="' <morphology_op> '"' | '') \
    (' radius="' <number_pair> '"' | '') '/>\n'

<morphology_op>::= ('erode' | 'dilate')

<fe_offset>    ::= '<feOffset' <fe_common> \
    (' dx="' <number> '"' | '') (' dy="' <number> '"' | '') '/>\n'

<fe_specular_lighting> ::= '<feSpecularLighting' <fe_common> \
    (' surfaceScale="' <number> '"' | '') \
    (' specularConstant="' <number> '"' | '') \
    (' specularExponent="' <number> '"' | '') \
    '>\n' <light_source> '</feSpecularLighting>\n'

<light_source> ::= ( \
    '<fePointLight' (' x="' <number> '"' | '') (' y="' <number> '"' | '') (' z="' <number> '"' | '') '/>\n' | \
    '<feDistantLight' (' azimuth="' <number> '"' | '') (' elevation="' <number> '"' | '') '/>\n' | \
    '<feSpotLight' (' x="' <number> '"' | '') (' y="' <number> '"' | '') (' z="' <number> '"' | '') \
    (' pointsAtX="' <number> '"' | '') (' pointsAtY="' <number> '"' | '') (' pointsAtZ="' <number> '"' | '') \
    (' specularExponent="' <number> '"' | '') (' limitingConeAngle="' <number> '"' | '') '/>\n')

<fe_tile>       ::= '<feTile' <fe_common> '/>\n'

<fe_turbulence> ::= '<feTurbulence' <fe_common> \
    (' baseFrequency="' <number_pair> '"' | '') \
    (' numOctaves="' <integer_val> '"' | '') \
    (' seed="' <number> '"' | '') \
    (' stitchTiles="' <stitch_tiles> '"' | '') \
    (' type="' <turbulence_type> '"' | '') '/>\n'

<stitch_tiles>    ::= ('stitch' | 'noStitch')
<turbulence_type> ::= ('fractalNoise' | 'turbulence')

# ANIMATION ELEMENTS

<animate_element> ::= (<animate_elem> | <animatetransform_elem> | <animatemotion_elem> | <set_elem>)

<animate_elem>          ::= '<animate' <animate_core_attrs> '/>\n'
<animatetransform_elem> ::= '<animateTransform' <animate_core_attrs> \
    (' type="' <transform_type> '"' | '') '/>\n'
<animatemotion_elem>    ::= '<animateMotion' <animate_core_attrs> \
    (' path="' <path_data> '"' | '') \
    (' rotate="' <anim_rotate> '"' | '') '/>\n'
<set_elem>              ::= '<set' <animate_core_attrs> '/>\n'

<anim_rotate>  ::= ('auto' | 'auto-start-reverse' | <number>)

<animate_core_attrs> ::= (' attributeName="' <name_val> '"' | '') \
    (' from="' <anim_val> '"' | '') (' to="' <anim_val> '"' | '') \
    (' by="' <anim_val> '"' | '') \
    (' dur="' <clock_val> '"' | '') \
    (' begin="' <clock_val> '"' | '') \
    (' end="' <clock_val> '"' | '') \
    (' repeatCount="' <repeat_count> '"' | '') \
    (' fill="' <anim_fill> '"' | '') \
    (' calcMode="' <calc_mode> '"' | '') \
    (' keyTimes="' <number_list> '"' | '') \
    (' additive="' <additive_val> '"' | '') \
    (' accumulate="' <accumulate_val> '"' | '') \
    (' restart="' <restart_val> '"' | '')

<anim_val>      ::= (<number> | <color_val> | <length_val>)
<repeat_count>  ::= (<pos_number> | 'indefinite')
<anim_fill>     ::= ('freeze' | 'remove')
<calc_mode>     ::= ('discrete' | 'linear' | 'paced' | 'spline')
<additive_val>  ::= ('replace' | 'sum')
<accumulate_val>::= ('none' | 'sum')
<restart_val>   ::= ('always' | 'whenNotActive' | 'never')
<transform_type>::= ('translate' | 'scale' | 'rotate' | 'skewX' | 'skewY' | 'matrix')
<clock_val>     ::= (<pos_number> 's' | <pos_number> 'ms' | <pos_number> 'min' | 'indefinite')

# COMMON ATTRIBUTES

<common_attrs> ::= (<_> <common_attr>)*

<common_attr> ::= (<core_attr> | <pres_attr> | <event_attr>)

<core_attr> ::= ('id="' <id_val> '"' | 'class="' <name_val> '"' | \
    'style="' <inline_style> '"' | \
    'transform="' <transform_list> '"' | \
    'clip-path="url(#' <id_val> ')"' | \
    'mask="url(#' <id_val> ')"' | \
    'filter="url(#' <id_val> ')"')

<pres_attr> ::= ('fill="' <paint_val> '"' | \
    'fill-opacity="' <alpha_val> '"' | \
    'fill-rule="' <fill_rule> '"' | \
    'stroke="' <paint_val> '"' | \
    'stroke-width="' <length_val> '"' | \
    'stroke-opacity="' <alpha_val> '"' | \
    'stroke-linecap="' <linecap_val> '"' | \
    'stroke-linejoin="' <linejoin_val> '"' | \
    'stroke-miterlimit="' <pos_number> '"' | \
    'stroke-dasharray="' <dash_array> '"' | \
    'stroke-dashoffset="' <length_val> '"' | \
    'opacity="' <alpha_val> '"' | \
    'display="' <display_val> '"' | \
    'visibility="' <visibility_val> '"' | \
    'overflow="' <overflow_val> '"' | \
    'color="' <color_val> '"' | \
    'color-interpolation="' <color_interp> '"' | \
    'shape-rendering="' <shape_rendering> '"' | \
    'text-rendering="' <text_rendering> '"' | \
    'image-rendering="' <rendering_val> '"' | \
    'font-family="' <font_family> '"' | \
    'font-size="' <font_size_val> '"' | \
    'font-style="' <font_style> '"' | \
    'font-weight="' <font_weight> '"' | \
    'font-variant="' <font_variant> '"' | \
    'font-stretch="' <font_stretch> '"' | \
    'text-decoration="' <text_decoration> '"' | \
    'letter-spacing="' <length_val> '"' | \
    'word-spacing="' <length_val> '"' | \
    'marker-start="url(#' <id_val> ')"' | \
    'marker-mid="url(#' <id_val> ')"' | \
    'marker-end="url(#' <id_val> ')"' | \
    'paint-order="' <paint_order> '"' | \
    'vector-effect="' <vector_effect> '"' | \
    'pointer-events="' <pointer_events> '"' | \
    'cursor="' <cursor_val> '"' | \
    'clip-rule="' <fill_rule> '"' | \
    'flood-color="' <color_val> '"' | \
    'flood-opacity="' <alpha_val> '"' | \
    'lighting-color="' <color_val> '"' | \
    'stop-color="' <color_val> '"' | \
    'stop-opacity="' <alpha_val> '"' | \
    'baseline-shift="' <baseline_shift_val> '"' | \
    'direction="' <direction_val> '"' | \
    'unicode-bidi="' <unicode_bidi> '"')

<event_attr> ::= ('onclick="return;"' | 'onmouseover="return;"' | 'onmouseout="return;"' | \
    'onmousedown="return;"' | 'onmouseup="return;"' | 'onmousemove="return;"' | \
    'onfocusin="return;"' | 'onfocusout="return;"' | 'onload="return;"')

<inline_style> ::= <css_decl> ('; ' <css_decl>)*

# TRANSFORMS

<transform_list> ::= <transform_item> (' ' <transform_item>)*

<transform_item> ::= ('matrix(' <number> ',' <number> ',' <number> ',' <number> ',' <number> ',' <number> ')' | \
    'translate(' <number> ',' <number> ')' | \
    'translate(' <number> ')' | \
    'scale(' <number> ',' <number> ')' | \
    'scale(' <number> ')' | \
    'rotate(' <number> ')' | \
    'rotate(' <number> ',' <number> ',' <number> ')' | \
    'skewX(' <number> ')' | \
    'skewY(' <number> ')')

# PAINTS, COLORS, LENGTHS

<paint_val>   ::= (<color_val> | 'none' | 'currentColor' | 'url(#' <id_val> ')' | 'inherit')
<color_val>   ::= (<hex_color> | <rgb_color> | <rgba_color> | <hsl_color> | <named_color>)
<hex_color>   ::= ('#' <hex6> | '#' <hex3> | '#' <hex8>)
<rgb_color>   ::= 'rgb(' <byte_val> ',' <byte_val> ',' <byte_val> ')'
<rgba_color>  ::= 'rgba(' <byte_val> ',' <byte_val> ',' <byte_val> ',' <alpha_val> ')'
<hsl_color>   ::= 'hsl(' <number> ',' <pct_val> ',' <pct_val> ')'

<named_color> ::= ('red' | 'green' | 'blue' | 'black' | 'white' | 'gray' | 'grey' | \
    'yellow' | 'orange' | 'purple' | 'pink' | 'cyan' | 'magenta' | \
    'lime' | 'maroon' | 'navy' | 'olive' | 'teal' | 'silver' | 'aqua' | \
    'fuchsia' | 'transparent' | 'currentColor' | 'aliceblue' | \
    'antiquewhite' | 'aquamarine' | 'azure' | 'beige' | 'bisque' | \
    'blanchedalmond' | 'blueviolet' | 'brown' | 'burlywood' | \
    'cadetblue' | 'chartreuse' | 'chocolate' | 'coral' | 'cornflowerblue' | \
    'cornsilk' | 'crimson' | 'darkblue' | 'darkcyan' | 'darkgoldenrod' | \
    'darkgray' | 'darkgreen' | 'darkkhaki' | 'darkolivegreen' | \
    'darkorange' | 'darkorchid' | 'darkred' | 'darksalmon' | 'darkseagreen' | \
    'darkslateblue' | 'darkturquoise' | 'darkviolet' | 'deeppink' | \
    'deepskyblue' | 'dimgray' | 'dodgerblue' | 'firebrick' | 'floralwhite' | \
    'forestgreen' | 'gainsboro' | 'ghostwhite' | 'gold' | 'goldenrod' | \
    'greenyellow' | 'honeydew' | 'hotpink' | 'indianred' | 'indigo' | \
    'ivory' | 'khaki' | 'lavender' | 'lawngreen' | 'lemonchiffon' | \
    'lightblue' | 'lightcoral' | 'lightcyan' | 'lightgoldenrodyellow' | \
    'lightgray' | 'lightgreen' | 'lightpink' | 'lightsalmon' | \
    'lightseagreen' | 'lightskyblue' | 'lightslategray' | 'lightsteelblue' | \
    'lightyellow' | 'limegreen' | 'linen' | 'mediumaquamarine' | 'mediumblue' | \
    'mediumorchid' | 'mediumpurple' | 'mediumseagreen' | 'mediumslateblue' | \
    'mediumspringgreen' | 'mediumturquoise' | 'mediumvioletred' | 'midnightblue' | \
    'mintcream' | 'mistyrose' | 'moccasin' | 'navajowhite' | 'oldlace' | \
    'olivedrab' | 'orangered' | 'orchid' | 'palegoldenrod' | 'palegreen' | \
    'paleturquoise' | 'palevioletred' | 'papayawhip' | 'peachpuff' | 'peru' | \
    'plum' | 'powderblue' | 'rosybrown' | 'royalblue' | 'saddlebrown' | \
    'salmon' | 'sandybrown' | 'seagreen' | 'seashell' | 'sienna' | 'skyblue' | \
    'slateblue' | 'slategray' | 'snow' | 'springgreen' | 'steelblue' | 'tan' | \
    'thistle' | 'tomato' | 'turquoise' | 'violet' | 'wheat' | \
    'whitesmoke' | 'yellowgreen')

<length_val>  ::= (<number> <length_unit> | <number> '%' | <number> | 'auto' | 'inherit')
<length_unit> ::= ('px' | 'pt' | 'pc' | 'mm' | 'cm' | 'in' | 'em' | 'ex' | 'ch' | 'rem' | 'vw' | 'vh' | 'vmin' | 'vmax')

<fill_rule>    ::= ('nonzero' | 'evenodd' | 'inherit')
<linecap_val>  ::= ('butt' | 'round' | 'square' | 'inherit')
<linejoin_val> ::= ('miter' | 'round' | 'bevel' | 'miter-clip' | 'arcs' | 'inherit')
<display_val>  ::= ('inline' | 'block' | 'none' | 'inherit')
<visibility_val> ::= ('visible' | 'hidden' | 'collapse' | 'inherit')
<overflow_val> ::= ('visible' | 'hidden' | 'scroll' | 'auto' | 'inherit')
<color_interp> ::= ('auto' | 'sRGB' | 'linearRGB' | 'inherit')
<rendering_val>::= ('auto' | 'optimizeSpeed' | 'optimizeQuality' | 'inherit')
<shape_rendering> ::= ('auto' | 'optimizeSpeed' | 'crispEdges' | 'geometricPrecision' | 'inherit')
<text_rendering>  ::= ('auto' | 'optimizeSpeed' | 'optimizeLegibility' | 'geometricPrecision' | 'inherit')
<paint_order>  ::= ('normal' | 'fill stroke markers' | 'stroke fill markers')
<vector_effect>::= ('none' | 'non-scaling-stroke' | 'non-scaling-size' | 'non-rotation' | 'fixed-position')
<pointer_events> ::= ('bounding-box' | 'visiblePainted' | 'visibleFill' | 'visibleStroke' | \
    'visible' | 'painted' | 'fill' | 'stroke' | 'all' | 'none' | 'inherit')
<cursor_val>   ::= ('auto' | 'crosshair' | 'default' | 'pointer' | 'move' | 'text' | 'wait' | 'help' | 'inherit')
<baseline_shift_val> ::= ('baseline' | 'sub' | 'super' | <length_val>)
<direction_val>::= ('ltr' | 'rtl' | 'inherit')
<unicode_bidi> ::= ('normal' | 'embed' | 'bidi-override' | 'isolate' | 'inherit')
<dash_array>   ::= ('none' | <pos_number> (' ' <pos_number>)*)
<font_family>  ::= ('serif' | 'sans-serif' | 'monospace' | 'cursive' | 'fantasy' | 'Arial' | 'Helvetica' | 'Georgia' | 'Verdana' | 'inherit')
<font_size_val>::= (<length_val> | 'xx-small' | 'x-small' | 'small' | 'medium' | 'large' | 'x-large' | 'xx-large' | 'larger' | 'smaller' | 'inherit')
<font_style>   ::= ('normal' | 'italic' | 'oblique' | 'inherit')
<font_weight>  ::= ('normal' | 'bold' | 'bolder' | 'lighter' | '100' | '200' | '300' | '400' | '500' | '600' | '700' | '800' | '900' | 'inherit')
<font_variant> ::= ('normal' | 'small-caps' | 'inherit')
<font_stretch> ::= ('normal' | 'ultra-condensed' | 'extra-condensed' | 'condensed' | \
    'semi-condensed' | 'semi-expanded' | 'expanded' | 'extra-expanded' | 'ultra-expanded' | 'inherit')
<text_decoration> ::= ('none' | 'underline' | 'overline' | 'line-through' | 'inherit')

<preserve_ar>  ::= <align_param> (' ' <meet_or_slice> | '')
<align_param>  ::= ('none' | 'xMinYMin' | 'xMidYMin' | 'xMaxYMin' | 'xMinYMid' | \
    'xMidYMid' | 'xMaxYMid' | 'xMinYMax' | 'xMidYMax' | 'xMaxYMax')
<meet_or_slice>::= ('meet' | 'slice')
<bool_val>     ::= ('true' | 'false')
