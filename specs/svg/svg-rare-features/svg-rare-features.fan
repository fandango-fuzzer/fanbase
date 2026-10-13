# Same as svg, biased toward obscure and rarely-implemented corners of the
# spec: mesh gradients, uncommon filter primitives, and seldom-used root
# attributes like baseProfile/contentScriptType.

# ─── TOP LEVEL ────────────────────────────────────────────────────────────────

<start> ::= <xml_decl>? <doctype>? <svg_root>

<xml_decl> ::= '<?xml version="' <xml_version> '" encoding="' <encoding> '"?>\n'
<xml_version> ::= '1.0' | '1.1'
<encoding> ::= 'UTF-8' | 'UTF-16' | 'ISO-8859-1'

<doctype> ::= '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"\n  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n'

# ─── SVG ROOT ─────────────────────────────────────────────────────────────────

<svg_root> ::= '<svg ' <svg_root_attrs> '>\n' <svg_body> '</svg>'

<svg_root_attrs> ::= \
    'xmlns="http://www.w3.org/2000/svg" ' \
    'xmlns:xlink="http://www.w3.org/1999/xlink" ' \
    'xmlns:xml="http://www.w3.org/XML/1998/namespace" ' \
    'version="' <svg_version> '" ' \
    'width="' <length_val> '" ' \
    'height="' <length_val> '" ' \
    'viewBox="' <viewbox> '" ' \
    <extra_svg_attrs>?

<svg_version> ::= '1.1' | '1.2' | '2.0'

<extra_svg_attrs> ::= \
    'preserveAspectRatio="' <preserve_aspect_ratio> '" ' | \
    'baseProfile="' <base_profile> '" ' | \
    'contentScriptType="' <content_type> '" ' | \
    'contentStyleType="text/css" ' | \
    'xml:space="' <xml_space> '" ' | \
    'xml:lang="' <lang_code> '" '

<base_profile> ::= 'full' | 'basic' | 'tiny' | 'none'
<content_type> ::= 'text/ecmascript' | 'application/ecmascript' | 'text/javascript'
<xml_space> ::= 'preserve' | 'default'
<lang_code> ::= 'en' | 'de' | 'zh' | 'ar' | 'he' | 'ja'

# ─── VIEWBOX / ASPECT RATIO ───────────────────────────────────────────────────

<viewbox> ::= <vb_coord> ' ' <vb_coord> ' ' <vb_size> ' ' <vb_size>
<vb_coord> ::= '-' <pos_num> | '0' | <pos_num>
<vb_size> ::= <pos_num> | '0.001' | '1e10' | '0'
<pos_num> ::= r'[1-9][0-9]{0,3}' | r'[1-9]\.[0-9]{1,4}'

<preserve_aspect_ratio> ::= <align_val> ' ' <meet_or_slice>
<align_val> ::= 'none' | 'xMinYMin' | 'xMidYMid' | 'xMaxYMax' | \
                'xMinYMid' | 'xMidYMin' | 'xMaxYMin' | \
                'xMinYMax' | 'xMidYMax' | 'xMaxYMid'
<meet_or_slice> ::= 'meet' | 'slice'

# ─── SVG BODY ─────────────────────────────────────────────────────────────────

<svg_body> ::= <defs_block>? <svg_element>*

<defs_block> ::= '<defs>\n' <def_item>* '</defs>\n'

<def_item> ::= \
    <gradient_def> | \
    <filter_def> | \
    <pattern_def> | \
    <marker_def> | \
    <clippath_def> | \
    <mask_def> | \
    <symbol_def> | \
    <font_def>

# ─── GRADIENTS ────────────────────────────────────────────────────────────────

<gradient_def> ::= <linear_gradient> | <radial_gradient> | <mesh_gradient>

<linear_gradient> ::= \
    '<linearGradient id="' <id_val> '" ' <gradient_attrs> '>\n' \
    <stop_list> \
    '</linearGradient>\n'

<gradient_attrs> ::= \
    'x1="' <coord_pct> '" y1="' <coord_pct> '" ' \
    'x2="' <coord_pct> '" y2="' <coord_pct> '" ' \
    'gradientUnits="' <gradient_units> '" ' \
    'spreadMethod="' <spread_method> '" ' \
    ('gradientTransform="' <transform_list> '" ')?

<radial_gradient> ::= \
    '<radialGradient id="' <id_val> '" ' <radial_attrs> '>\n' \
    <stop_list> \
    '</radialGradient>\n'

<radial_attrs> ::= \
    'cx="' <coord_pct> '" cy="' <coord_pct> '" r="' <coord_pct> '" ' \
    'fx="' <coord_pct> '" fy="' <coord_pct> '" ' \
    ('fr="' <coord_pct> '" ')? \
    'gradientUnits="' <gradient_units> '" ' \
    'spreadMethod="' <spread_method> '" '

# SVG 2.0 mesh gradient – rarely implemented, likely to trigger edge cases
<mesh_gradient> ::= \
    '<meshGradient id="' <id_val> '" x="' <number> '" y="' <number> '">\n' \
    '<meshrow>\n' <meshpatch>+ '</meshrow>\n' \
    '</meshGradient>\n'

<meshpatch> ::= '<meshpatch>\n' <stop_list> '</meshpatch>\n'

<gradient_units> ::= 'userSpaceOnUse' | 'objectBoundingBox'
<spread_method> ::= 'pad' | 'repeat' | 'reflect'

<stop_list> ::= <stop_item>{2,5}
<stop_item> ::= '<stop offset="' <offset_val> '" stop-color="' <color> '" stop-opacity="' <opacity_val> '"/>\n'
<offset_val> ::= r'0\.[0-9]{1,4}' | '0' | '1' | r'[1-9][0-9]?%'

# ─── FILTERS ──────────────────────────────────────────────────────────────────

<filter_def> ::= \
    '<filter id="' <id_val> '" ' <filter_attrs> '>\n' \
    <filter_primitive>+ \
    '</filter>\n'

<filter_attrs> ::= \
    'x="' <filter_coord> '" y="' <filter_coord> '" ' \
    'width="' <filter_size> '" height="' <filter_size> '" ' \
    'filterUnits="' <gradient_units> '" ' \
    'primitiveUnits="' <gradient_units> '" ' \
    ('color-interpolation-filters="' <color_interp> '" ')?

<filter_coord> ::= '-10%' | '-20%' | '0%' | '-5%'
<filter_size> ::= '120%' | '140%' | '200%' | '110%'
<color_interp> ::= 'auto' | 'sRGB' | 'linearRGB'

<filter_primitive> ::= \
    <fe_gaussian_blur> | <fe_turbulence> | <fe_displacement_map> | \
    <fe_composite> | <fe_blend> | <fe_color_matrix> | \
    <fe_convolve_matrix> | <fe_morphology> | <fe_flood> | \
    <fe_component_transfer> | <fe_merge> | <fe_offset> | \
    <fe_specular_lighting> | <fe_diffuse_lighting> | \
    <fe_tile> | <fe_image> | <fe_drop_shadow>

<fe_gaussian_blur> ::= \
    '<feGaussianBlur in="' <fe_in> '" stdDeviation="' <stddev_val> '" result="' <id_val> '" edgeMode="' <edge_mode> '"/>\n'
<stddev_val> ::= r'[0-9]{1,2}(\.[0-9]{1,2})?' | r'[0-9]+ [0-9]+'
<edge_mode> ::= 'duplicate' | 'wrap' | 'none'

<fe_turbulence> ::= \
    '<feTurbulence type="' <turb_type> '" baseFrequency="' <base_freq> '" numOctaves="' <num_octaves> '" seed="' <seed_val> '" stitchTiles="' <stitch_tiles> '" result="' <id_val> '"/>\n'
<turb_type> ::= 'fractalNoise' | 'turbulence'
<base_freq> ::= r'0\.[0-9]{2,4}' | r'0\.[0-9]+ 0\.[0-9]+'
<num_octaves> ::= '1' | '2' | '4' | '8' | '10'
<seed_val> ::= r'[0-9]{1,6}'
<stitch_tiles> ::= 'stitch' | 'noStitch'

<fe_displacement_map> ::= \
    '<feDisplacementMap in="' <fe_in> '" in2="' <fe_in> '" scale="' <number> '" xChannelSelector="' <channel_sel> '" yChannelSelector="' <channel_sel> '" result="' <id_val> '"/>\n'
<channel_sel> ::= 'R' | 'G' | 'B' | 'A'

<fe_composite> ::= \
    '<feComposite in="' <fe_in> '" in2="' <fe_in> '" operator="' <composite_op> '" ' <arithmetic_attrs>? 'result="' <id_val> '"/>\n'
<composite_op> ::= 'over' | 'in' | 'out' | 'atop' | 'xor' | 'lighter' | 'arithmetic'
<arithmetic_attrs> ::= 'k1="' <number> '" k2="' <number> '" k3="' <number> '" k4="' <number> '" '

<fe_blend> ::= \
    '<feBlend in="' <fe_in> '" in2="' <fe_in> '" mode="' <blend_mode> '" result="' <id_val> '"/>\n'
<blend_mode> ::= 'normal' | 'multiply' | 'screen' | 'overlay' | 'darken' | \
                 'lighten' | 'color-dodge' | 'color-burn' | 'hard-light' | \
                 'soft-light' | 'difference' | 'exclusion' | 'hue' | \
                 'saturation' | 'color' | 'luminosity'

<fe_color_matrix> ::= \
    '<feColorMatrix in="' <fe_in> '" type="' <color_matrix_type> '" values="' <color_matrix_values> '" result="' <id_val> '"/>\n'
<color_matrix_type> ::= 'matrix' | 'saturate' | 'hueRotate' | 'luminanceToAlpha'
<color_matrix_values> ::= \
    r'[01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+ ' \
    r'[01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+ ' \
    r'[01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+ ' \
    r'[01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+ [01]\.[0-9]+' | \
    r'[0-3](\.[0-9]+)?' | r'[0-9]{1,3}'

<fe_convolve_matrix> ::= \
    '<feConvolveMatrix order="' <conv_order> '" kernelMatrix="' <kernel_matrix> '" divisor="' <pos_num> '" bias="' <number> '" targetX="' <conv_digit> '" targetY="' <conv_digit> '" edgeMode="' <edge_mode> '" preserveAlpha="' <bool_val> '" result="' <id_val> '"/>\n'
<conv_order> ::= '3' | '5' | '3 3' | '5 5'
<kernel_matrix> ::= r'-?[0-9] -?[0-9] -?[0-9] -?[0-9] -?[0-9] -?[0-9] -?[0-9] -?[0-9] -?[0-9]'
<conv_digit> ::= '0' | '1' | '2'

<fe_morphology> ::= \
    '<feMorphology in="' <fe_in> '" operator="' <morphology_op> '" radius="' <morph_radius> '" result="' <id_val> '"/>\n'
<morphology_op> ::= 'erode' | 'dilate'
<morph_radius> ::= r'[1-9]' | r'[1-9] [1-9]'

<fe_flood> ::= \
    '<feFlood flood-color="' <color> '" flood-opacity="' <opacity_val> '" result="' <id_val> '"/>\n'

<fe_component_transfer> ::= \
    '<feComponentTransfer in="' <fe_in> '" result="' <id_val> '">\n' \
    '<feFuncR type="' <transfer_type> '" ' <transfer_attrs> '/>\n' \
    '<feFuncG type="' <transfer_type> '" ' <transfer_attrs> '/>\n' \
    '<feFuncB type="' <transfer_type> '" ' <transfer_attrs> '/>\n' \
    '<feFuncA type="' <transfer_type> '" ' <transfer_attrs> '/>\n' \
    '</feComponentTransfer>\n'
<transfer_type> ::= 'identity' | 'linear' | 'gamma' | 'table' | 'discrete'
<transfer_attrs> ::= \
    'slope="' <number> '" intercept="' <number> '"' | \
    'amplitude="' <number> '" exponent="' <number> '" offset="' <number> '"' | \
    'tableValues="0 0.5 1"'

<fe_merge> ::= \
    '<feMerge result="' <id_val> '">\n' \
    '<feMergeNode in="' <fe_in> '"/>\n' \
    '<feMergeNode in="' <fe_in> '"/>\n' \
    '</feMerge>\n'

<fe_offset> ::= \
    '<feOffset in="' <fe_in> '" dx="' <number> '" dy="' <number> '" result="' <id_val> '"/>\n'

<fe_specular_lighting> ::= \
    '<feSpecularLighting in="' <fe_in> '" surfaceScale="' <number> '" specularConstant="' <number> '" specularExponent="' <number> '" result="' <id_val> '">\n' \
    <light_source> \
    '</feSpecularLighting>\n'

<fe_diffuse_lighting> ::= \
    '<feDiffuseLighting in="' <fe_in> '" surfaceScale="' <number> '" diffuseConstant="' <number> '" result="' <id_val> '">\n' \
    <light_source> \
    '</feDiffuseLighting>\n'

<light_source> ::= \
    '<fePointLight x="' <number> '" y="' <number> '" z="' <number> '"/>\n' | \
    '<feDistantLight azimuth="' <number> '" elevation="' <number> '"/>\n' | \
    '<feSpotLight x="' <number> '" y="' <number> '" z="' <number> '" pointsAtX="' <number> '" pointsAtY="' <number> '" pointsAtZ="' <number> '" specularExponent="' <number> '" limitingConeAngle="' <number> '"/>\n'

<fe_tile> ::= \
    '<feTile in="' <fe_in> '" result="' <id_val> '"/>\n'

<fe_image> ::= \
    '<feImage xlink:href="' <data_uri_img> '" result="' <id_val> '" preserveAspectRatio="' <preserve_aspect_ratio> '"/>\n'

<fe_drop_shadow> ::= \
    '<feDropShadow dx="' <number> '" dy="' <number> '" stdDeviation="' <stddev_val> '" flood-color="' <color> '" flood-opacity="' <opacity_val> '" result="' <id_val> '"/>\n'

<fe_in> ::= 'SourceGraphic' | 'SourceAlpha' | 'BackgroundImage' | 'BackgroundAlpha' | 'FillPaint' | 'StrokePaint'

# ─── PATTERN ──────────────────────────────────────────────────────────────────

<pattern_def> ::= \
    '<pattern id="' <id_val> '" ' <pattern_attrs> '>\n' \
    <svg_element>{1,3} \
    '</pattern>\n'

<pattern_attrs> ::= \
    'x="' <number> '" y="' <number> '" ' \
    'width="' <length_val> '" height="' <length_val> '" ' \
    'patternUnits="' <gradient_units> '" ' \
    'patternContentUnits="' <gradient_units> '" ' \
    ('patternTransform="' <transform_list> '" ')? \
    ('viewBox="' <viewbox> '" ')?

# ─── MARKER ───────────────────────────────────────────────────────────────────

<marker_def> ::= \
    '<marker id="' <id_val> '" ' <marker_attrs> '>\n' \
    <svg_element>{1,2} \
    '</marker>\n'

<marker_attrs> ::= \
    'markerWidth="' <number> '" markerHeight="' <number> '" ' \
    'refX="' <number> '" refY="' <number> '" ' \
    'orient="' <marker_orient> '" ' \
    'markerUnits="' <marker_units> '" ' \
    ('viewBox="' <viewbox> '" ')? \
    ('preserveAspectRatio="' <preserve_aspect_ratio> '" ')?
<marker_orient> ::= 'auto' | 'auto-start-reverse' | r'[0-9]{1,3}'
<marker_units> ::= 'strokeWidth' | 'userSpaceOnUse'

# ─── CLIPPATH / MASK ──────────────────────────────────────────────────────────

<clippath_def> ::= \
    '<clipPath id="' <id_val> '" clipPathUnits="' <gradient_units> '">\n' \
    <svg_element>{1,2} \
    '</clipPath>\n'

<mask_def> ::= \
    '<mask id="' <id_val> '" ' <mask_attrs> '>\n' \
    <svg_element>{1,2} \
    '</mask>\n'
<mask_attrs> ::= \
    'x="' <number> '" y="' <number> '" ' \
    'width="' <length_val> '" height="' <length_val> '" ' \
    'maskUnits="' <gradient_units> '" ' \
    'maskContentUnits="' <gradient_units> '" '

# ─── SYMBOL ───────────────────────────────────────────────────────────────────

<symbol_def> ::= \
    '<symbol id="' <id_val> '" ' <symbol_attrs> '>\n' \
    <svg_element>{1,3} \
    '</symbol>\n'
<symbol_attrs> ::= \
    'viewBox="' <viewbox> '" ' \
    'preserveAspectRatio="' <preserve_aspect_ratio> '" ' \
    ('overflow="' <overflow_val> '" ')?
<overflow_val> ::= 'visible' | 'hidden' | 'scroll' | 'auto'

# ─── FONT (SVG fonts – deprecated but still parsed by some engines) ────────────

<font_def> ::= \
    '<font id="' <id_val> '" horiz-adv-x="' <number> '">\n' \
    '<font-face font-family="' <font_family_name> '" units-per-em="' <number> '" ' \
    'ascent="' <number> '" descent="-' <pos_num> '" ' \
    'x-height="' <number> '" cap-height="' <number> '"/>\n' \
    '<missing-glyph horiz-adv-x="' <number> '"/>\n' \
    <glyph_def>{1,4} \
    '</font>\n'

<glyph_def> ::= \
    '<glyph unicode="' <unicode_char> '" horiz-adv-x="' <number> '" d="' <path_data> '"/>\n'

<unicode_char> ::= 'A' | 'B' | 'a' | '0' | '&#x263A;' | '&#x2665;'
<font_family_name> ::= 'FuzzFont' | 'EdgeCaseSerif' | r'[A-Z][a-z]{3,8}'

# ─── SVG ELEMENTS ─────────────────────────────────────────────────────────────

<svg_element> ::= \
    <rect_elem> | <circle_elem> | <ellipse_elem> | \
    <line_elem> | <polyline_elem> | <polygon_elem> | \
    <path_elem> | <text_elem> | <tspan_elem_wrap> | \
    <image_elem> | <use_elem> | <group_elem> | \
    <switch_elem> | <foreign_object> | \
    <animate_elem> | <animate_transform> | <animate_motion> | \
    <set_elem> | \
    <a_elem> | \
    <svg_nested>

# ─── SHAPES ───────────────────────────────────────────────────────────────────

<rect_elem> ::= \
    '<rect ' <shape_attrs> \
    'x="' <number> '" y="' <number> '" ' \
    'width="' <length_val> '" height="' <length_val> '" ' \
    ('rx="' <number> '" ry="' <number> '" ')? \
    <presentation_attrs> \
    <event_attrs>? \
    '/>\n'

<circle_elem> ::= \
    '<circle ' <shape_attrs> \
    'cx="' <number> '" cy="' <number> '" r="' <pos_num> '" ' \
    <presentation_attrs> <event_attrs>? '/>\n'

<ellipse_elem> ::= \
    '<ellipse ' <shape_attrs> \
    'cx="' <number> '" cy="' <number> '" rx="' <pos_num> '" ry="' <pos_num> '" ' \
    <presentation_attrs> <event_attrs>? '/>\n'

<line_elem> ::= \
    '<line ' <shape_attrs> \
    'x1="' <number> '" y1="' <number> '" x2="' <number> '" y2="' <number> '" ' \
    <presentation_attrs> <event_attrs>? '/>\n'

<polyline_elem> ::= \
    '<polyline ' <shape_attrs> \
    'points="' <point_list> '" ' \
    <presentation_attrs> <event_attrs>? '/>\n'

<polygon_elem> ::= \
    '<polygon ' <shape_attrs> \
    'points="' <point_list> '" ' \
    'fill-rule="' <fill_rule> '" ' \
    <presentation_attrs> <event_attrs>? '/>\n'

<path_elem> ::= \
    '<path ' <shape_attrs> \
    'd="' <path_data> '" ' \
    'pathLength="' <pos_num> '" ' \
    <presentation_attrs> <event_attrs>? '/>\n'

<shape_attrs> ::= ('id="' <id_val> '" ')? ('class="' <class_val> '" ')?

# ─── PATH DATA ────────────────────────────────────────────────────────────────

<path_data> ::= <path_cmd>+
<path_cmd> ::= \
    <path_moveto> | <path_lineto> | <path_hlineto> | <path_vlineto> | \
    <path_curveto> | <path_smooth_curveto> | \
    <path_qcurveto> | <path_smooth_qcurveto> | \
    <path_arc> | <path_closepath>

<path_moveto>         ::= ('M' | 'm') ' ' <coord_pair> ' '
<path_lineto>         ::= ('L' | 'l') ' ' <coord_pair> ' '
<path_hlineto>        ::= ('H' | 'h') ' ' <number> ' '
<path_vlineto>        ::= ('V' | 'v') ' ' <number> ' '
<path_curveto>        ::= ('C' | 'c') ' ' <coord_pair> ' ' <coord_pair> ' ' <coord_pair> ' '
<path_smooth_curveto> ::= ('S' | 's') ' ' <coord_pair> ' ' <coord_pair> ' '
<path_qcurveto>       ::= ('Q' | 'q') ' ' <coord_pair> ' ' <coord_pair> ' '
<path_smooth_qcurveto>::= ('T' | 't') ' ' <coord_pair> ' '
<path_arc>            ::= ('A' | 'a') ' ' <pos_num> ' ' <pos_num> ' ' <number> ' ' <arc_flag> ' ' <arc_flag> ' ' <coord_pair> ' '
<path_closepath>      ::= ('Z' | 'z')

<arc_flag> ::= '0' | '1'
<coord_pair> ::= <number> ',' <number>

# ─── TEXT ─────────────────────────────────────────────────────────────────────

<text_elem> ::= \
    '<text ' <text_attrs> <presentation_attrs> '>' \
    <text_content> \
    '</text>\n'

<text_attrs> ::= \
    ('id="' <id_val> '" ')? \
    'x="' <number> '" y="' <number> '" ' \
    ('dx="' <number> '" dy="' <number> '" ')? \
    ('rotate="' <rotate_list> '" ')? \
    ('textLength="' <pos_num> '" ')? \
    ('lengthAdjust="' <length_adjust> '" ')? \
    'text-anchor="' <text_anchor> '" ' \
    'dominant-baseline="' <dominant_baseline> '" '

<rotate_list> ::= r'-?[0-9]{1,3}(,-?[0-9]{1,3}){0,5}'
<length_adjust> ::= 'spacing' | 'spacingAndGlyphs'
<text_anchor> ::= 'start' | 'middle' | 'end'
<dominant_baseline> ::= 'auto' | 'middle' | 'hanging' | 'mathematical' | \
                        'ideographic' | 'alphabetic' | 'text-bottom' | 'text-top'

<text_content> ::= <text_str> | <text_str> <tspan_elem>+ | <textpath_elem>

<text_str> ::= r'[A-Za-z0-9 .,!?]{1,30}'

<tspan_elem_wrap> ::= \
    '<text x="' <number> '" y="' <number> '" ' <presentation_attrs> '>' \
    <tspan_elem>+ \
    '</text>\n'

<tspan_elem> ::= \
    '<tspan ' \
    ('x="' <number> '" ')? ('y="' <number> '" ')? \
    ('dx="' <number> '" ')? ('dy="' <number> '" ')? \
    ('baseline-shift="' <baseline_shift> '" ')? \
    ('font-variant="' <font_variant> '" ')? \
    <presentation_attrs> \
    '>' <text_str> '</tspan>'

<baseline_shift> ::= 'baseline' | 'super' | 'sub' | r'-?[0-9]{1,3}%'
<font_variant> ::= 'normal' | 'small-caps'

<textpath_elem> ::= \
    '<textPath xlink:href="#' <id_val> '" ' \
    'startOffset="' <start_offset> '" ' \
    'method="' <textpath_method> '" ' \
    'spacing="' <textpath_spacing> '" ' \
    '>' <text_str> '</textPath>'

<start_offset> ::= r'[0-9]{1,3}%' | r'[0-9]{1,3}'
<textpath_method> ::= 'align' | 'stretch'
<textpath_spacing> ::= 'auto' | 'exact'

# ─── IMAGE ────────────────────────────────────────────────────────────────────

<image_elem> ::= \
    '<image ' <shape_attrs> \
    'x="' <number> '" y="' <number> '" ' \
    'width="' <length_val> '" height="' <length_val> '" ' \
    'xlink:href="' <image_href> '" ' \
    ('href="' <image_href> '" ')? \
    'preserveAspectRatio="' <preserve_aspect_ratio> '" ' \
    ('image-rendering="' <image_rendering> '" ')? \
    <presentation_attrs> '/>\n'

<image_href> ::= <data_uri_img>
<image_rendering> ::= 'auto' | 'optimizeSpeed' | 'optimizeQuality' | 'pixelated' | 'crisp-edges'

# Minimal 1x1 red pixel GIF data URI
<data_uri_img> ::= \
    'data:image/gif;base64,R0lGODlhAQABAIAAAP8AAAAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==' | \
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwADhQGAWjR9awAAAABJRU5ErkJggg==' | \
    'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjwvc3ZnPg=='

# ─── USE ──────────────────────────────────────────────────────────────────────

<use_elem> ::= \
    '<use xlink:href="#' <id_val> '" ' \
    ('href="#' <id_val> '" ')? \
    'x="' <number> '" y="' <number> '" ' \
    ('width="' <length_val> '" height="' <length_val> '" ')? \
    <presentation_attrs> '/>\n'

# ─── GROUP ────────────────────────────────────────────────────────────────────

<group_elem> ::= \
    '<g ' \
    ('id="' <id_val> '" ')? \
    ('class="' <class_val> '" ')? \
    <presentation_attrs> \
    <group_extra_attrs>? \
    '>\n' \
    <svg_element>{1,4} \
    '</g>\n'

<group_extra_attrs> ::= \
    'isolation="' <isolation_val> '" ' | \
    'mix-blend-mode="' <blend_mode> '" ' | \
    'enable-background="' <enable_bg> '" '

<isolation_val> ::= 'auto' | 'isolate'
<enable_bg> ::= 'accumulate' | 'new'

# ─── SWITCH ───────────────────────────────────────────────────────────────────

<switch_elem> ::= \
    '<switch>\n' \
    '<g systemLanguage="' <lang_code> '">\n' <svg_element> '</g>\n' \
    '<g>\n' <svg_element> '</g>\n' \
    '</switch>\n'

# ─── FOREIGNOBJECT ────────────────────────────────────────────────────────────

<foreign_object> ::= \
    '<foreignObject x="' <number> '" y="' <number> '" ' \
    'width="' <length_val> '" height="' <length_val> '" ' \
    'requiredExtensions="http://www.w3.org/1999/xhtml">\n' \
    '<div xmlns="http://www.w3.org/1999/xhtml" style="font-size:10px">' \
    <text_str> '</div>\n' \
    '</foreignObject>\n'

# ─── NESTED SVG ───────────────────────────────────────────────────────────────

<svg_nested> ::= \
    '<svg x="' <number> '" y="' <number> '" ' \
    'width="' <length_val> '" height="' <length_val> '" ' \
    'viewBox="' <viewbox> '" ' \
    'overflow="' <overflow_val> '">\n' \
    <svg_element>{1,3} \
    '</svg>\n'

# ─── ANIMATIONS ───────────────────────────────────────────────────────────────

<animate_elem> ::= \
    '<rect x="10" y="10" width="100" height="100" fill="' <color> '">\n' \
    '<animate ' <anim_attrs> '/>\n' \
    '</rect>\n'

<animate_transform> ::= \
    '<rect x="50" y="50" width="80" height="80" fill="' <color> '">\n' \
    '<animateTransform ' <anim_attrs> \
    'type="' <anim_transform_type> '" ' \
    'additive="' <additive_val> '" ' \
    'accumulate="' <accumulate_val> '" ' \
    '/>\n' \
    '</rect>\n'

<animate_motion> ::= \
    '<circle r="5" fill="' <color> '">\n' \
    '<animateMotion dur="' <duration> '" repeatCount="' <repeat_count> '" ' \
    'path="' <path_data> '" ' \
    'rotate="' <anim_rotate> '" ' \
    'keyPoints="' <key_points> '" ' \
    'keyTimes="' <key_times> '" ' \
    'calcMode="' <calc_mode> '"' \
    '/>\n' \
    '</circle>\n'

<set_elem> ::= \
    '<rect x="10" y="10" width="50" height="50" fill="' <color> '">\n' \
    '<set attributeName="' <set_attr_name> '" to="' <color> '" ' <anim_timing_attrs> '/>\n' \
    '</rect>\n'
<set_attr_name> ::= 'fill' | 'display' | 'visibility' | 'opacity'

<anim_attrs> ::= \
    'attributeName="' <anim_attr_name> '" ' \
    <anim_value_spec> \
    <anim_timing_attrs>

<anim_attr_name> ::= \
    'cx' | 'cy' | 'r' | 'x' | 'y' | 'width' | 'height' | \
    'fill' | 'stroke' | 'opacity' | 'stroke-width' | \
    'fill-opacity' | 'stroke-opacity' | 'rx' | 'ry' | \
    'd' | 'transform' | 'viewBox'

<anim_value_spec> ::= \
    'from="' <anim_val> '" to="' <anim_val> '" ' | \
    'values="' <anim_val> ';' <anim_val> ';' <anim_val> '" ' \
    'keyTimes="' <key_times> '" ' \
    'calcMode="' <calc_mode> '" ' | \
    'by="' <number> '" '

<anim_val> ::= <number> | <color> | <length_val>

<anim_timing_attrs> ::= \
    'begin="' <anim_begin> '" ' \
    'dur="' <duration> '" ' \
    'end="' <anim_end> '" ' \
    'repeatCount="' <repeat_count> '" ' \
    'repeatDur="' <repeat_dur> '" ' \
    'fill="' <anim_fill> '" ' \
    'restart="' <restart_val> '" ' \
    'additive="' <additive_val> '"'

<anim_begin> ::= '0s' | '1s' | '2.5s' | 'click' | 'indefinite' | '0' | '-1s'
<anim_end> ::= '5s' | '10s' | 'indefinite'
<duration> ::= r'[1-9](\.[0-9])?s' | 'indefinite'
<repeat_count> ::= 'indefinite' | '1' | '2' | '5' | '0.5'
<repeat_dur> ::= '10s' | 'indefinite'
<anim_fill> ::= 'freeze' | 'remove'
<restart_val> ::= 'always' | 'whenNotActive' | 'never'
<additive_val> ::= 'replace' | 'sum'
<accumulate_val> ::= 'none' | 'sum'
<anim_rotate> ::= 'auto' | 'auto-reverse' | r'[0-9]{1,3}'
<anim_transform_type> ::= 'translate' | 'scale' | 'rotate' | 'skewX' | 'skewY'
<key_times> ::= '0;0.5;1' | '0;0.25;0.75;1'
<key_points> ::= '0;0.5;1' | '0;0.3;0.7;1'
<calc_mode> ::= 'linear' | 'discrete' | 'paced' | 'spline'

# ─── HYPERLINK ────────────────────────────────────────────────────────────────

<a_elem> ::= \
    '<a xlink:href="' <href_val> '" ' \
    ('href="' <href_val> '" ')? \
    ('target="' <target_val> '" ')? \
    ('xlink:show="' <xlink_show> '" ')? \
    ('xlink:actuate="' <xlink_actuate> '" ')? \
    '>\n' \
    <svg_element> \
    '</a>\n'

<href_val> ::= 'https://example.com' | 'javascript:void(0)' | '#' <id_val> | ''
<target_val> ::= '_blank' | '_self' | '_parent' | '_top'
<xlink_show> ::= 'new' | 'replace' | 'embed'
<xlink_actuate> ::= 'onRequest' | 'onLoad'

# ─── PRESENTATION ATTRIBUTES ──────────────────────────────────────────────────

<presentation_attrs> ::= \
    ('fill="' <paint_val> '" ')? \
    ('fill-opacity="' <opacity_val> '" ')? \
    ('fill-rule="' <fill_rule> '" ')? \
    ('stroke="' <paint_val> '" ')? \
    ('stroke-width="' <stroke_width> '" ')? \
    ('stroke-opacity="' <opacity_val> '" ')? \
    ('stroke-linecap="' <linecap> '" ')? \
    ('stroke-linejoin="' <linejoin> '" ')? \
    ('stroke-miterlimit="' <number> '" ')? \
    ('stroke-dasharray="' <dash_array> '" ')? \
    ('stroke-dashoffset="' <number> '" ')? \
    ('opacity="' <opacity_val> '" ')? \
    ('transform="' <transform_list> '" ')? \
    ('filter="url(#' <id_val> ')" ')? \
    ('clip-path="url(#' <id_val> ')" ')? \
    ('mask="url(#' <id_val> ')" ')? \
    ('marker-start="url(#' <id_val> ')" ')? \
    ('marker-mid="url(#' <id_val> ')" ')? \
    ('marker-end="url(#' <id_val> ')" ')? \
    ('font-family="' <font_family> '" ')? \
    ('font-size="' <font_size> '" ')? \
    ('font-weight="' <font_weight> '" ')? \
    ('font-style="' <font_style> '" ')? \
    ('letter-spacing="' <number> '" ')? \
    ('word-spacing="' <number> '" ')? \
    ('text-decoration="' <text_decoration> '" ')? \
    ('writing-mode="' <writing_mode> '" ')? \
    ('direction="' <direction> '" ')? \
    ('color-interpolation="' <color_interp> '" ')? \
    ('color-rendering="' <color_rendering> '" ')? \
    ('shape-rendering="' <shape_rendering> '" ')? \
    ('text-rendering="' <text_rendering> '" ')? \
    ('image-rendering="' <image_rendering> '" ')? \
    ('visibility="' <visibility> '" ')? \
    ('display="' <display> '" ')? \
    ('overflow="' <overflow_val> '" ')? \
    ('vector-effect="' <vector_effect> '" ')? \
    ('paint-order="' <paint_order> '" ')? \
    ('style="' <inline_style> '"')?

<paint_val> ::= <color> | 'none' | 'inherit' | \
    'url(#' <id_val> ')' | \
    'url(#' <id_val> ') ' <color> | \
    'context-fill' | 'context-stroke'

<fill_rule> ::= 'nonzero' | 'evenodd'
<linecap> ::= 'butt' | 'round' | 'square'
<linejoin> ::= 'miter' | 'round' | 'bevel' | 'miter-clip' | 'arcs'
<stroke_width> ::= r'[0-9]{1,3}(\.[0-9]{1,2})?' | '0' | '0.5' | '0.1'
<dash_array> ::= 'none' | r'[1-9]{1,2}' | r'[1-9] [1-9] [1-9]' | r'[0-9],[0-9]'
<visibility> ::= 'visible' | 'hidden' | 'collapse'
<display> ::= 'inline' | 'none' | 'block'
<vector_effect> ::= 'none' | 'non-scaling-stroke' | 'non-scaling-size' | 'non-rotation' | 'fixed-position'
<paint_order> ::= 'normal' | 'stroke fill' | 'fill stroke' | 'markers'
<color_rendering> ::= 'auto' | 'optimizeSpeed' | 'optimizeQuality'
<shape_rendering> ::= 'auto' | 'optimizeSpeed' | 'crispEdges' | 'geometricPrecision'
<text_rendering> ::= 'auto' | 'optimizeSpeed' | 'optimizeLegibility' | 'geometricPrecision'
<writing_mode> ::= 'lr-tb' | 'rl-tb' | 'tb-rl' | 'lr' | 'rl' | 'tb' | \
                   'horizontal-tb' | 'vertical-rl' | 'vertical-lr'
<direction> ::= 'ltr' | 'rtl'
<text_decoration> ::= 'none' | 'underline' | 'overline' | 'line-through' | 'blink'

# ─── INLINE STYLE ─────────────────────────────────────────────────────────────

<inline_style> ::= <css_prop> (';' <css_prop>)*
<css_prop> ::= \
    'fill:' <color> | \
    'stroke:' <color> | \
    'opacity:' <opacity_val> | \
    'stroke-width:' <stroke_width> | \
    'fill-rule:' <fill_rule> | \
    'display:none' | \
    'visibility:hidden' | \
    'mix-blend-mode:' <blend_mode> | \
    'isolation:isolate'

# ─── EVENT ATTRIBUTES (trigger script parsing edge cases) ─────────────────────

<event_attrs> ::= <event_attr> (<event_attr>)*

<event_attr> ::= \
    'onclick="' <script_val> '" ' | \
    'onmouseover="' <script_val> '" ' | \
    'onload="' <script_val> '" ' | \
    'onerror="' <script_val> '" ' | \
    'onactivate="' <script_val> '" ' | \
    'onfocusin="' <script_val> '" '

<script_val> ::= 'void(0)' | 'return false;' | '1+1'

# ─── TRANSFORMS ───────────────────────────────────────────────────────────────

<transform_list> ::= <transform_fn> (' ' <transform_fn>)*

<transform_fn> ::= \
    'translate(' <number> ',' <number> ')' | \
    'translate(' <number> ')' | \
    'scale(' <number> ')' | \
    'scale(' <number> ',' <number> ')' | \
    'rotate(' <number> ')' | \
    'rotate(' <number> ',' <number> ',' <number> ')' | \
    'skewX(' <number> ')' | \
    'skewY(' <number> ')' | \
    'matrix(' <number> ',' <number> ',' <number> ',' <number> ',' <number> ',' <number> ')'

# ─── COLOR ────────────────────────────────────────────────────────────────────

<color> ::= \
    <hex_color> | <rgb_color> | <rgba_color> | <hsl_color> | <named_color> | \
    <lab_color> | <oklch_color> | <device_cmyk_color> | 'currentColor' | 'inherit'

<hex_color> ::= '#' <hex6> | '#' <hex3> | '#' <hex8> | '#' <hex4>
<hex6>  ::= r'[0-9a-fA-F]{6}'
<hex3>  ::= r'[0-9a-fA-F]{3}'
<hex8>  ::= r'[0-9a-fA-F]{8}'
<hex4>  ::= r'[0-9a-fA-F]{4}'

<rgb_color>  ::= 'rgb(' <byte_val> ',' <byte_val> ',' <byte_val> ')'
<rgba_color> ::= 'rgba(' <byte_val> ',' <byte_val> ',' <byte_val> ',' <opacity_val> ')'
<hsl_color>  ::= 'hsl(' <hue_val> ',' <pct> '%,' <pct> '%)'
<lab_color>  ::= 'lab(' <number> ' ' <number> ' ' <number> ')'
<oklch_color> ::= 'oklch(' <opacity_val> ' ' <opacity_val> ' ' <hue_val> ')'
<device_cmyk_color> ::= 'device-cmyk(' <opacity_val> ' ' <opacity_val> ' ' <opacity_val> ' ' <opacity_val> ')'

<byte_val> ::= r'[0-9]{1,2}' | '255' | '128' | '0'
<hue_val>  ::= r'[0-9]{1,3}' | '360' | '0'
<pct>      ::= r'[0-9]{1,2}' | '100' | '0'

<named_color> ::= 'red' | 'green' | 'blue' | 'black' | 'white' | 'transparent' | \
                  'rebeccapurple' | 'aliceblue' | 'mediumaquamarine' | 'cornflowerblue'

# ─── SHARED PRIMITIVES ────────────────────────────────────────────────────────

<number> ::= r'-?[0-9]{1,4}(\.[0-9]{1,4})?' | \
             r'-?[0-9]+e-?[0-9]+' | \
             '0' | '-0' | 'Infinity' | '-Infinity' | 'NaN'

<length_val> ::= r'[1-9][0-9]{0,3}' | \
                 r'[1-9][0-9]{0,3}\.[0-9]{1,2}' | \
                 r'[1-9][0-9]{0,3}(px|pt|pc|mm|cm|in|em|ex|ch|vw|vh|vmin|vmax|%)' | \
                 '0' | '100%' | '50%' | 'auto'

<coord_pct> ::= r'[0-9]{1,3}%' | r'[0-9]{1,3}' | '50%' | '0' | '100%'

<opacity_val> ::= r'0\.[0-9]{1,4}' | '0' | '1' | r'[0-9]{1,2}%'

<bool_val> ::= 'true' | 'false'

<id_val> ::= r'[a-zA-Z][a-zA-Z0-9_-]{0,15}'

<class_val> ::= r'[a-zA-Z][a-zA-Z0-9_-]{0,10}'

<point_list> ::= <coord_pair> (' ' <coord_pair>){2,8}

<font_family> ::= 'sans-serif' | 'serif' | 'monospace' | 'cursive' | 'fantasy' | \
                  'Arial' | 'Times New Roman' | 'Courier New'

<font_size> ::= r'[0-9]{1,2}(px|pt|em|%)?' | 'small' | 'medium' | 'large' | 'x-large'

<font_weight> ::= 'normal' | 'bold' | 'bolder' | 'lighter' | \
                  '100' | '200' | '300' | '400' | '500' | '600' | '700' | '800' | '900'

<font_style> ::= 'normal' | 'italic' | 'oblique'
