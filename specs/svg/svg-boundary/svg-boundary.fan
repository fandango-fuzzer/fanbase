# Same as svg, biased toward parser-breaking extremes: deprecated DOCTYPEs,
# huge/negative coordinates, every legacy colour syntax, foreignObject, and
# SMIL timing edge cases. `where` is only used for genuine numeric ranges
# (rgb channels, percentages, opacity); everything else is literal
# alternation or bounded regex.

<start> ::= <svg_doc>

# Document: optional XML decl, optional DOCTYPE (legacy SVG 1.0/1.1 DTDs),
# optional comment/PI clutter, then the root <svg>.
<svg_doc> ::= <xml_decl>? <bom_junk>? <doctype>? <misc>* <svg_root> "\n"

<bom_junk> ::= ""
<misc> ::= <comment> | <pi> | <ws1>
<ws1> ::= " " | "\n" | "\t"

<xml_decl> ::= (
      "<?xml version=\"1.0\"?>\n"
    | "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    | "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?>\n"
    | "<?xml version=\"1.0\" encoding=\"ISO-8859-1\" standalone=\"yes\"?>\n"
    | "<?xml version=\"1.1\" encoding=\"US-ASCII\"?>\n"
)

# Deprecated / legacy DOCTYPE forms — many modern parsers barely handle these.
<doctype> ::= (
      "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\""
      " \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n"
    | "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\""
      " \"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\">\n"
    | "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1 Basic//EN\""
      " \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-basic.dtd\">\n"
    | "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1 Tiny//EN\""
      " \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-tiny.dtd\">\n"
    | "<!DOCTYPE svg>\n"
    | "<!DOCTYPE svg [\n  <!ENTITY ns_svg \"http://www.w3.org/2000/svg\">\n]>\n"
)

<comment> ::= "<!--" <comment_body> "-->"
<comment_body> ::= <dashseq>*
# never emit "--" inside a comment: after a "-" always append a non-dash char
<dashseq> ::= <ctext> | ("-" <ctext>)
<ctext> ::= r'[a-zA-Z0-9 .,:;/()!?=+*]'

<pi> ::= "<?" <pi_target> " " <pi_data> "?>"
<pi_target> ::= "xml-stylesheet" | "sodipodi" | "inkscape"
<pi_data> ::= <qseq>*
# never emit "?>" inside PI data: after "?" always a non-'>' char
<qseq> ::= <ptext> | ("?" <ptext>)
<ptext> ::= r'[a-zA-Z0-9 ."\-=/:]'

# Root <svg>. Namespaces declared here so prefixed names (xlink:href) bind.
# Bias: extreme viewBox values, unusual units, preserveAspectRatio corner cases,
# baseProfile tiny, zoomAndPan, negative coords.
<svg_root> ::= "<svg" <svg_ns> <svg_attrs> ">" <svg_content> "</svg>"

<svg_ns> ::= (
      " xmlns=\"http://www.w3.org/2000/svg\""
      " xmlns:xlink=\"http://www.w3.org/1999/xlink\""
    | " xmlns=\"http://www.w3.org/2000/svg\""
      " xmlns:xlink=\"http://www.w3.org/1999/xlink\""
      " xmlns:ev=\"http://www.w3.org/2001/xml-events\""
)

<svg_attrs> ::= <a_version>? <a_baseprofile>? <a_width>? <a_height>? \
    <a_viewbox>? <a_par>? <a_zoompan>? <a_x>? <a_y>? <a_id>? <a_overflow>? \
    <a_style>? <a_class>? <a_lang>?

<a_version> ::= " version=\"1.0\"" | " version=\"1.1\"" | " version=\"1.2\""
<a_baseprofile> ::= " baseProfile=\"none\"" | " baseProfile=\"tiny\"" \
    | " baseProfile=\"basic\"" | " baseProfile=\"full\""
<a_zoompan> ::= " zoomAndPan=\"disable\"" | " zoomAndPan=\"magnify\""
<a_overflow> ::= " overflow=\"visible\"" | " overflow=\"hidden\"" \
    | " overflow=\"scroll\"" | " overflow=\"auto\"" | " overflow=\"inherit\""

<a_width> ::= " width=\"" <length_or_pct> "\""
<a_height> ::= " height=\"" <length_or_pct> "\""
<a_x> ::= " x=\"" <coord> "\""
<a_y> ::= " y=\"" <coord> "\""

# viewBox biased to extremes: zero-size, huge, negative origins, fractional.
<a_viewbox> ::= " viewBox=\"" <coord> " " <coord> " " <nonneg_num> " " <nonneg_num> "\""

<a_par> ::= " preserveAspectRatio=\"" <par_val> "\""
<par_val> ::= (
      "none" | "none meet" | "none slice"
    | "xMinYMin meet" | "xMidYMid meet" | "xMaxYMax meet"
    | "xMinYMid slice" | "xMidYMin slice" | "xMaxYMid slice"
    | "xMinYMax meet" | "xMaxYMin slice" | "xMidYMax meet"
    | "defer xMidYMid meet"
)

# Root content: descriptive elements + any element, deeply mixed.
<svg_content> ::= <descriptive>* <element>{1,5}

<descriptive> ::= <title_el> | <desc_el> | <metadata_el>
<title_el> ::= "<title>" <text_body> "</title>"
<desc_el> ::= "<desc>" <text_body> "</desc>"
<metadata_el> ::= "<metadata>" <metadata_body> "</metadata>"
<metadata_body> ::= "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">" \
    "<rdf:Description/>" "</rdf:RDF>" | <text_body>

# The master element choice — everything reachable from here.
<element> ::= (
      <container_el>
    | <shape_el>
    | <path_el>
    | <text_el>
    | <image_el>
    | <use_el>
    | <gradient_el>
    | <pattern_el>
    | <clip_el>
    | <mask_el>
    | <filter_el>
    | <marker_el>
    | <style_el>
    | <script_el>
    | <animation_el>
    | <foreign_el>
    | <comment>
)

# Containers: g / defs / symbol / switch / a. Capped to one nesting level of
# leaves (containers hold leaf elements, not more containers) to keep
# recursion bounded.
<container_el> ::= <g_el> | <defs_el> | <symbol_el> | <switch_el> | <anchor_el>

<g_el> ::= "<g" <common_attrs> <a_transform>? ">" <leaf>{1,4} "</g>"
<defs_el> ::= "<defs" <common_attrs> ">" <def_child>{1,4} "</defs>"
<def_child> ::= <gradient_el> | <pattern_el> | <clip_el> | <mask_el> \
    | <filter_el> | <marker_el> | <symbol_el> | <shape_el> | <g_el>
<symbol_el> ::= "<symbol" <common_attrs> <a_viewbox>? <a_par>? ">" \
    <leaf>{1,3} "</symbol>"
<switch_el> ::= "<switch" <common_attrs> ">" <switch_child>{1,3} "</switch>"
<switch_child> ::= "<g" <sysattrs> <common_attrs> ">" <leaf>{1,2} "</g>" \
    | <shape_el>
# system-conditional attributes — rarely tested branches
<sysattrs> ::= <a_reqfeat>? <a_reqext>? <a_syslang>?
<a_reqfeat> ::= " requiredFeatures=\"http://www.w3.org/TR/SVG11/feature#Shape\""
<a_reqext> ::= " requiredExtensions=\"http://example.org/ext\""
<a_syslang> ::= " systemLanguage=\"" <langlist> "\""
<langlist> ::= "en" | "en-US,fr" | "de,zh-Hans,ar" | "x-custom"

<anchor_el> ::= "<a" <common_attrs> <a_href> <a_target>? ">" <leaf>{1,2} "</a>"
<a_target> ::= " target=\"_blank\"" | " target=\"_self\"" \
    | " target=\"_parent\"" | " target=\"_top\"" | " target=\"replace\""

# Leaf = non-container drawable (bounds recursion depth).
<leaf> ::= <shape_el> | <path_el> | <text_el> | <image_el> | <use_el> \
    | <animation_el> | <comment>

# Basic shapes — biased to zero/negative radii, huge coords, dasharrays, etc.
<shape_el> ::= <rect_el> | <circle_el> | <ellipse_el> | <line_el> \
    | <polyline_el> | <polygon_el>

<rect_el> ::= "<rect" <common_attrs> <a_x>? <a_y>? <a_width>? <a_height>? \
    <a_rx>? <a_ry>? <a_transform>? "/>"
<a_rx> ::= " rx=\"" <nonneg_num> "\""
<a_ry> ::= " ry=\"" <nonneg_num> "\""

<circle_el> ::= "<circle" <common_attrs> <a_cx>? <a_cy>? <a_r>? \
    <a_transform>? "/>"
<a_cx> ::= " cx=\"" <coord> "\""
<a_cy> ::= " cy=\"" <coord> "\""
<a_r> ::= " r=\"" <nonneg_num> "\""

<ellipse_el> ::= "<ellipse" <common_attrs> <a_cx>? <a_cy>? <a_rx>? <a_ry>? \
    <a_transform>? "/>"

<line_el> ::= "<line" <common_attrs> <a_x1>? <a_y1>? <a_x2>? <a_y2>? \
    <a_transform>? "/>"
<a_x1> ::= " x1=\"" <coord> "\""
<a_y1> ::= " y1=\"" <coord> "\""
<a_x2> ::= " x2=\"" <coord> "\""
<a_y2> ::= " y2=\"" <coord> "\""

<polyline_el> ::= "<polyline" <common_attrs> " points=\"" <points> "\"" \
    <a_transform>? "/>"
<polygon_el> ::= "<polygon" <common_attrs> " points=\"" <points> "\"" \
    <a_transform>? "/>"
<points> ::= <point> (<point_sep> <point>){0,12}
<point> ::= <num> "," <num>
<point_sep> ::= " " | "  " | "\n" | ", " | " ,"

# Path data mini-grammar. Bias: all command letters incl. rare S/T/A, relative
# lowercase forms, arc flags, comma/space separator chaos, exponent numbers.
<path_el> ::= "<path" <common_attrs> " d=\"" <path_data> "\"" \
    <a_pathlength>? <a_transform>? "/>"
<a_pathlength> ::= " pathLength=\"" <nonneg_num> "\""

<path_data> ::= <moveto> <draw_cmd>{0,10} <closepath>?
<moveto> ::= ("M" | "m") <wsp> <coord_pair> (<sep> <coord_pair>){0,3}
<closepath> ::= "Z" | "z"
<draw_cmd> ::= (
      <lineto> | <hlineto> | <vlineto> | <curveto> | <scurveto>
    | <quadto> | <squadto> | <arcto> | <moveto>
)
<lineto> ::= ("L" | "l") <wsp> <coord_pair> (<sep> <coord_pair>){0,3}
<hlineto> ::= ("H" | "h") <wsp> <num> (<sep> <num>){0,3}
<vlineto> ::= ("V" | "v") <wsp> <num> (<sep> <num>){0,3}
<curveto> ::= ("C" | "c") <wsp> <coord_triple>
<scurveto> ::= ("S" | "s") <wsp> <coord_pair> <sep> <coord_pair>
<quadto> ::= ("Q" | "q") <wsp> <coord_pair> <sep> <coord_pair>
<squadto> ::= ("T" | "t") <wsp> <coord_pair>
<arcto> ::= ("A" | "a") <wsp> <nonneg_num> <sep> <nonneg_num> <sep> <num> \
    <sep> <flag> <sep> <flag> <sep> <coord_pair>
<coord_pair> ::= <num> <sep> <num>
<coord_triple> ::= <coord_pair> <sep> <coord_pair> <sep> <coord_pair>
<flag> ::= "0" | "1"
<sep> ::= " " | "," | ", " | " ," | "\n" | ""
<wsp> ::= "" | " "

# Text: text/tspan/tref/textPath, font attrs, rotate lists, xml:space.
<text_el> ::= "<text" <common_attrs> <a_x>? <a_y>? <a_dx>? <a_dy>? \
    <a_rotate>? <a_textlen>? <a_lenadjust>? <a_xmlspace>? <font_attrs> \
    <a_textanchor>? <a_transform>? ">" <text_content> "</text>"
<a_dx> ::= " dx=\"" <numlist> "\""
<a_dy> ::= " dy=\"" <numlist> "\""
<a_rotate> ::= " rotate=\"" <numlist> "\""
<a_textlen> ::= " textLength=\"" <nonneg_num> "\""
<a_lenadjust> ::= " lengthAdjust=\"spacing\"" \
    | " lengthAdjust=\"spacingAndGlyphs\""
<a_xmlspace> ::= " xml:space=\"preserve\"" | " xml:space=\"default\""
<a_textanchor> ::= " text-anchor=\"start\"" | " text-anchor=\"middle\"" \
    | " text-anchor=\"end\"" | " text-anchor=\"inherit\""

<text_content> ::= (<text_body> | <tspan_el> | <tref_el> | <textpath_el>){1,4}
<tspan_el> ::= "<tspan" <common_attrs> <a_x>? <a_y>? <a_dx>? <a_dy>? \
    <a_rotate>? <font_attrs> ">" <text_body> "</tspan>"
<tref_el> ::= "<tref" <a_href> <common_attrs> "/>"
<textpath_el> ::= "<textPath" <a_href> <a_startoffset>? <a_method>? \
    <a_spacing>? ">" <text_body> "</textPath>"
<a_startoffset> ::= " startOffset=\"" <length_or_pct> "\""
<a_method> ::= " method=\"align\"" | " method=\"stretch\""
<a_spacing> ::= " spacing=\"auto\"" | " spacing=\"exact\""

<font_attrs> ::= <a_fontfamily>? <a_fontsize>? <a_fontstyle>? <a_fontweight>?
<a_fontfamily> ::= " font-family=\"" <fontname> "\""
<fontname> ::= "serif" | "sans-serif" | "monospace" | "cursive" \
    | "'Times New Roman', serif" | "Arial, Helvetica, sans-serif"
<a_fontsize> ::= " font-size=\"" <length_or_pct> "\"" \
    | " font-size=\"xx-small\"" | " font-size=\"larger\"" \
    | " font-size=\"smaller\"" | " font-size=\"medium\""
<a_fontstyle> ::= " font-style=\"normal\"" | " font-style=\"italic\"" \
    | " font-style=\"oblique\""
<a_fontweight> ::= " font-weight=\"normal\"" | " font-weight=\"bold\"" \
    | " font-weight=\"bolder\"" | " font-weight=\"lighter\"" \
    | " font-weight=\"100\"" | " font-weight=\"900\""

# image / use — xlink:href legacy vs href, negative sizes.
<image_el> ::= "<image" <common_attrs> <a_href> <a_x>? <a_y>? <a_width> \
    <a_height> <a_par>? <a_transform>? "/>"
<use_el> ::= "<use" <common_attrs> <a_href> <a_x>? <a_y>? <a_width>? \
    <a_height>? <a_transform>? "/>"

# Gradients + stops + patterns. Bias: gradientUnits, spreadMethod, transforms,
# out-of-order offsets, opacity extremes.
<gradient_el> ::= <lineargrad_el> | <radialgrad_el>
<lineargrad_el> ::= "<linearGradient" <a_id> <a_gradunits>? <a_spread>? \
    <a_gradtransform>? <a_x1>? <a_y1>? <a_x2>? <a_y2>? <a_href>? ">" \
    <stop_el>{1,5} "</linearGradient>"
<radialgrad_el> ::= "<radialGradient" <a_id> <a_gradunits>? <a_spread>? \
    <a_gradtransform>? <a_cx>? <a_cy>? <a_r>? <a_fx>? <a_fy>? <a_fr>? ">" \
    <stop_el>{1,5} "</radialGradient>"
<a_fx> ::= " fx=\"" <coord> "\""
<a_fy> ::= " fy=\"" <coord> "\""
<a_fr> ::= " fr=\"" <nonneg_num> "\""
<a_gradunits> ::= " gradientUnits=\"userSpaceOnUse\"" \
    | " gradientUnits=\"objectBoundingBox\""
<a_spread> ::= " spreadMethod=\"pad\"" | " spreadMethod=\"reflect\"" \
    | " spreadMethod=\"repeat\""
<a_gradtransform> ::= " gradientTransform=\"" <transform_list> "\""

<stop_el> ::= "<stop" <a_offset> <a_stopcolor>? <a_stopopacity>? <a_style>? "/>"
<a_offset> ::= " offset=\"" <ratio> "\"" | " offset=\"" <percentage> "%\""
<a_stopcolor> ::= " stop-color=\"" <color> "\"" \
    | " stop-color=\"currentColor\"" | " stop-color=\"inherit\""
<a_stopopacity> ::= " stop-opacity=\"" <ratio> "\""

<pattern_el> ::= "<pattern" <a_id> <a_patunits>? <a_patcontentunits>? \
    <a_pattransform>? <a_x>? <a_y>? <a_width> <a_height> <a_viewbox>? \
    <a_par>? <a_href>? ">" <leaf>{1,3} "</pattern>"
<a_patunits> ::= " patternUnits=\"userSpaceOnUse\"" \
    | " patternUnits=\"objectBoundingBox\""
<a_patcontentunits> ::= " patternContentUnits=\"userSpaceOnUse\"" \
    | " patternContentUnits=\"objectBoundingBox\""
<a_pattransform> ::= " patternTransform=\"" <transform_list> "\""

# Clipping / masking.
<clip_el> ::= "<clipPath" <a_id> <a_clippathunits>? <a_transform>? ">" \
    <clip_child>{1,3} "</clipPath>"
<clip_child> ::= <shape_el> | <path_el> | <text_el> | <use_el>
<a_clippathunits> ::= " clipPathUnits=\"userSpaceOnUse\"" \
    | " clipPathUnits=\"objectBoundingBox\""

<mask_el> ::= "<mask" <a_id> <a_maskunits>? <a_maskcontentunits>? \
    <a_x>? <a_y>? <a_width>? <a_height>? ">" <leaf>{1,3} "</mask>"
<a_maskunits> ::= " maskUnits=\"userSpaceOnUse\"" \
    | " maskUnits=\"objectBoundingBox\""
<a_maskcontentunits> ::= " maskContentUnits=\"userSpaceOnUse\"" \
    | " maskContentUnits=\"objectBoundingBox\""

# Filters — a wide range of fe* primitives, deep coverage.
<filter_el> ::= "<filter" <a_id> <a_filterunits>? <a_primunits>? \
    <a_x>? <a_y>? <a_width>? <a_height>? <a_filterres>? ">" \
    <fe_primitive>{1,6} "</filter>"
<a_filterunits> ::= " filterUnits=\"userSpaceOnUse\"" \
    | " filterUnits=\"objectBoundingBox\""
<a_primunits> ::= " primitiveUnits=\"userSpaceOnUse\"" \
    | " primitiveUnits=\"objectBoundingBox\""
<a_filterres> ::= " filterRes=\"" <nonneg_int> "\"" \
    | " filterRes=\"" <nonneg_int> " " <nonneg_int> "\""

<fe_primitive> ::= (
      <fe_gaussian> | <fe_offset> | <fe_blend> | <fe_flood> | <fe_colormatrix>
    | <fe_merge> | <fe_composite> | <fe_morphology> | <fe_turbulence>
    | <fe_dropshadow> | <fe_tile> | <fe_image> | <fe_displacement>
    | <fe_componenttransfer> | <fe_convolve>
)
<fe_common> ::= <a_x>? <a_y>? <a_width>? <a_height>? <a_result>? <a_in>?
<a_result> ::= " result=\"" <ncname> "\""
<a_in> ::= " in=\"" <fe_input> "\""
<a_in2> ::= " in2=\"" <fe_input> "\""
<fe_input> ::= "SourceGraphic" | "SourceAlpha" | "BackgroundImage" \
    | "BackgroundAlpha" | "FillPaint" | "StrokePaint" | <ncname>

<fe_gaussian> ::= "<feGaussianBlur" <fe_common> " stdDeviation=\"" \
    <numlist> "\"" <a_edgemode>? "/>"
<a_edgemode> ::= " edgeMode=\"duplicate\"" | " edgeMode=\"wrap\"" \
    | " edgeMode=\"none\""
<fe_offset> ::= "<feOffset" <fe_common> " dx=\"" <num> "\" dy=\"" <num> "\"/>"
<fe_blend> ::= "<feBlend" <fe_common> <a_in2> " mode=\"" <blendmode> "\"/>"
<blendmode> ::= "normal" | "multiply" | "screen" | "darken" | "lighten" \
    | "overlay" | "color-dodge" | "color-burn" | "hard-light" | "soft-light" \
    | "difference" | "exclusion" | "hue" | "saturation" | "color" | "luminosity"
<fe_flood> ::= "<feFlood" <fe_common> " flood-color=\"" <color> \
    "\" flood-opacity=\"" <ratio> "\"/>"
<fe_colormatrix> ::= "<feColorMatrix" <fe_common> " type=\"" <cm_type> "\"" \
    <a_cm_values>? "/>"
<cm_type> ::= "matrix" | "saturate" | "hueRotate" | "luminanceToAlpha"
<a_cm_values> ::= " values=\"" <numlist> "\""
<fe_merge> ::= "<feMerge" <fe_common> ">" <fe_mergenode>{1,4} "</feMerge>"
<fe_mergenode> ::= "<feMergeNode" <a_in>? "/>"
<fe_composite> ::= "<feComposite" <fe_common> <a_in2> " operator=\"" \
    <comp_op> "\"" <a_comp_k>? "/>"
<comp_op> ::= "over" | "in" | "out" | "atop" | "xor" | "arithmetic"
<a_comp_k> ::= " k1=\"" <num> "\" k2=\"" <num> "\" k3=\"" <num> \
    "\" k4=\"" <num> "\""
<fe_morphology> ::= "<feMorphology" <fe_common> " operator=\"" \
    <morph_op> "\" radius=\"" <numlist> "\"/>"
<morph_op> ::= "erode" | "dilate"
<fe_turbulence> ::= "<feTurbulence" <fe_common> " type=\"" <turb_type> \
    "\" baseFrequency=\"" <numlist> "\" numOctaves=\"" <nonneg_int> \
    "\" seed=\"" <num> "\"" <a_stitch>? "/>"
<turb_type> ::= "turbulence" | "fractalNoise"
<a_stitch> ::= " stitchTiles=\"stitch\"" | " stitchTiles=\"noStitch\""
<fe_dropshadow> ::= "<feDropShadow" <fe_common> " dx=\"" <num> "\" dy=\"" \
    <num> "\" stdDeviation=\"" <numlist> "\" flood-color=\"" <color> \
    "\" flood-opacity=\"" <ratio> "\"/>"
<fe_tile> ::= "<feTile" <fe_common> "/>"
<fe_image> ::= "<feImage" <fe_common> <a_href> <a_par>? "/>"
<fe_displacement> ::= "<feDisplacementMap" <fe_common> <a_in2> " scale=\"" \
    <num> "\" xChannelSelector=\"" <channel> "\" yChannelSelector=\"" \
    <channel> "\"/>"
<channel> ::= "R" | "G" | "B" | "A"
<fe_componenttransfer> ::= "<feComponentTransfer" <fe_common> ">" \
    <fe_func>{1,4} "</feComponentTransfer>"
<fe_func> ::= "<feFuncR" <transfer_attrs> "/>" | "<feFuncG" <transfer_attrs> "/>" \
    | "<feFuncB" <transfer_attrs> "/>" | "<feFuncA" <transfer_attrs> "/>"
<transfer_attrs> ::= " type=\"identity\"" \
    | " type=\"table\" tableValues=\"" <numlist> "\"" \
    | " type=\"discrete\" tableValues=\"" <numlist> "\"" \
    | " type=\"linear\" slope=\"" <num> "\" intercept=\"" <num> "\"" \
    | " type=\"gamma\" amplitude=\"" <num> "\" exponent=\"" <num> \
      "\" offset=\"" <num> "\""
<fe_convolve> ::= "<feConvolveMatrix" <fe_common> " order=\"" <nonneg_int> \
    "\" kernelMatrix=\"" <numlist> "\"" <a_divisor>? " edgeMode=\"" \
    <conv_edge> "\"/>"
<a_divisor> ::= " divisor=\"" <num> "\""
<conv_edge> ::= "duplicate" | "wrap" | "none"

# Markers.
<marker_el> ::= "<marker" <a_id> <a_markerunits>? <a_refx>? <a_refy>? \
    <a_markerw>? <a_markerh>? <a_orient>? <a_viewbox>? <a_par>? ">" \
    <leaf>{1,3} "</marker>"
<a_markerunits> ::= " markerUnits=\"strokeWidth\"" \
    | " markerUnits=\"userSpaceOnUse\""
<a_refx> ::= " refX=\"" <coord> "\""
<a_refy> ::= " refY=\"" <coord> "\""
<a_markerw> ::= " markerWidth=\"" <nonneg_num> "\""
<a_markerh> ::= " markerHeight=\"" <nonneg_num> "\""
<a_orient> ::= " orient=\"auto\"" | " orient=\"auto-start-reverse\"" \
    | " orient=\"" <num> "\"" | " orient=\"" <num> "deg\""

# style / script — CSS + CDATA-wrapped JS.
<style_el> ::= "<style type=\"text/css\">" <css_body> "</style>"
<css_body> ::= "<![CDATA[\n" <css_rule>{1,4} "]]>"
<css_rule> ::= <css_selector> " { " <css_decl>{1,3} "}\n"
<css_selector> ::= "." <ncname> | "#" <ncname> | <svg_tagname> \
    | <svg_tagname> ":hover" | "*"
<svg_tagname> ::= "rect" | "circle" | "path" | "text" | "g" | "svg"
<css_decl> ::= <css_prop> ": " <css_val> "; "
<css_prop> ::= "fill" | "stroke" | "stroke-width" | "opacity" | "font-size" \
    | "display" | "visibility"
<css_val> ::= <color> | <num> | "none" | "inherit" | "1px"

<script_el> ::= "<script type=\"text/ecmascript\">" <js_body> "</script>" \
    | "<script type=\"application/javascript\">" <js_body> "</script>"
<js_body> ::= "<![CDATA[\n" <js_text> "\n]]>"
<js_text> ::= r'[a-zA-Z0-9 ;=().,{}\n+\-*/]*'

# Animation — animate/animateTransform/animateMotion/set/animateColor(legacy).
<animation_el> ::= <animate_el> | <animatetransform_el> | <animatemotion_el> \
    | <set_el> | <animatecolor_el>
<animate_el> ::= "<animate" <a_attrname> <anim_timing> <anim_values> \
    <a_repeatcount>? <a_fill_freeze>? <a_calcmode>? "/>"
<animatetransform_el> ::= "<animateTransform" <a_attrname> \
    " attributeType=\"XML\" type=\"" <transform_type> "\"" <anim_timing> \
    <anim_values> <a_repeatcount>? <a_additive>? <a_accumulate>? "/>"
<transform_type> ::= "translate" | "scale" | "rotate" | "skewX" | "skewY"
<animatemotion_el> ::= "<animateMotion" <anim_timing> " path=\"" <path_data> \
    "\"" <a_rotate_anim>? <a_keypoints>? <a_repeatcount>? "/>"
<a_rotate_anim> ::= " rotate=\"auto\"" | " rotate=\"auto-reverse\"" \
    | " rotate=\"" <num> "\""
<a_keypoints> ::= " keyPoints=\"" <ratio> ";" <ratio> "\" calcMode=\"linear\""
<set_el> ::= "<set" <a_attrname> " to=\"" <anim_val> "\"" <anim_timing> \
    <a_fill_freeze>? "/>"
<animatecolor_el> ::= "<animateColor" <a_attrname> " from=\"" <color> \
    "\" to=\"" <color> "\"" <anim_timing> "/>"

<a_attrname> ::= " attributeName=\"" <anim_attr> "\""
<anim_attr> ::= "x" | "y" | "cx" | "cy" | "r" | "width" | "height" \
    | "opacity" | "fill" | "stroke" | "transform" | "d" | "offset"
<anim_timing> ::= " begin=\"" <clock> "\" dur=\"" <clock> "\"" <a_end>?
<a_end> ::= " end=\"" <clock> "\""
<clock> ::= <nonneg_num> "s" | <nonneg_num> "ms" | "0" | "indefinite" \
    | r'[0-9]{1,2}:[0-9]{2}:[0-9]{2}' | "click" | "mouseover"
<anim_values> ::= " from=\"" <anim_val> "\" to=\"" <anim_val> "\"" \
    | " values=\"" <anim_vlist> "\"" \
    | " by=\"" <anim_val> "\""
<anim_val> ::= <num> | <color> | <length_or_pct>
<anim_vlist> ::= <anim_val> (";" <anim_val>){1,4}
<a_repeatcount> ::= " repeatCount=\"" <nonneg_int> "\"" \
    | " repeatCount=\"indefinite\""
<a_fill_freeze> ::= " fill=\"freeze\"" | " fill=\"remove\""
<a_calcmode> ::= " calcMode=\"discrete\"" | " calcMode=\"linear\"" \
    | " calcMode=\"paced\"" | " calcMode=\"spline\""
<a_additive> ::= " additive=\"replace\"" | " additive=\"sum\""
<a_accumulate> ::= " accumulate=\"none\"" | " accumulate=\"sum\""

# foreignObject — the rarely-handled escape into non-SVG namespaces.
<foreign_el> ::= "<foreignObject" <common_attrs> <a_x>? <a_y>? <a_width> \
    <a_height> ">" <foreign_body> "</foreignObject>"
<foreign_body> ::= "<body xmlns=\"http://www.w3.org/1999/xhtml\">" \
    <text_body> "</body>" | "<div xmlns=\"http://www.w3.org/1999/xhtml\">" \
    <text_body> "</div>"

# Common presentation attributes shared by drawables. Distinct optional slots
# (no duplicate-attr collision). Biased to legacy + edge paint values.
<common_attrs> ::= <a_id>? <a_class>? <a_fill>? <a_fillrule>? <a_stroke>? \
    <a_strokewidth>? <a_strokelinecap>? <a_strokelinejoin>? \
    <a_strokedasharray>? <a_strokedashoffset>? <a_strokemiterlimit>? \
    <a_opacity>? <a_fillopacity>? <a_strokeopacity>? <a_style>? \
    <a_clippath>? <a_mask>? <a_filter>? <a_display>? <a_visibility>? \
    <a_colorinterp>? <a_shaperendering>? <a_paintorder>? <a_lang>?

<a_id> ::= " id=\"" <ncname> "\""
<a_class> ::= " class=\"" <ncname> "\"" | " class=\"" <ncname> " " <ncname> "\""
<a_lang> ::= " xml:lang=\"" <langtag> "\""
<langtag> ::= "en" | "en-US" | "de" | "zh-Hans" | "ar-EG"
<a_style> ::= " style=\"" <css_decl>{1,3} "\""

<a_fill> ::= " fill=\"" <paint> "\""
<a_fillrule> ::= " fill-rule=\"nonzero\"" | " fill-rule=\"evenodd\"" \
    | " fill-rule=\"inherit\""
<a_stroke> ::= " stroke=\"" <paint> "\""
<a_strokewidth> ::= " stroke-width=\"" <nonneg_num> "\"" \
    | " stroke-width=\"" <percentage> "%\""
<a_strokelinecap> ::= " stroke-linecap=\"butt\"" | " stroke-linecap=\"round\"" \
    | " stroke-linecap=\"square\""
<a_strokelinejoin> ::= " stroke-linejoin=\"miter\"" \
    | " stroke-linejoin=\"round\"" | " stroke-linejoin=\"bevel\"" \
    | " stroke-linejoin=\"arcs\"" | " stroke-linejoin=\"miter-clip\""
<a_strokedasharray> ::= " stroke-dasharray=\"none\"" \
    | " stroke-dasharray=\"" <nonneg_num> (<sep> <nonneg_num>){1,6} "\""
<a_strokedashoffset> ::= " stroke-dashoffset=\"" <num> "\""
<a_strokemiterlimit> ::= " stroke-miterlimit=\"" <nonneg_num> "\""
<a_opacity> ::= " opacity=\"" <ratio> "\""
<a_fillopacity> ::= " fill-opacity=\"" <ratio> "\""
<a_strokeopacity> ::= " stroke-opacity=\"" <ratio> "\""
<a_display> ::= " display=\"none\"" | " display=\"inline\"" \
    | " display=\"block\"" | " display=\"inherit\""
<a_visibility> ::= " visibility=\"visible\"" | " visibility=\"hidden\"" \
    | " visibility=\"collapse\""
<a_colorinterp> ::= " color-interpolation=\"auto\"" \
    | " color-interpolation-filters=\"linearRGB\"" \
    | " color-interpolation-filters=\"sRGB\""
<a_shaperendering> ::= " shape-rendering=\"auto\"" \
    | " shape-rendering=\"crispEdges\"" \
    | " shape-rendering=\"optimizeSpeed\"" \
    | " shape-rendering=\"geometricPrecision\""
<a_paintorder> ::= " paint-order=\"normal\"" \
    | " paint-order=\"stroke fill markers\"" \
    | " paint-order=\"fill\""
<a_clippath> ::= " clip-path=\"" <funciri> "\"" | " clip-path=\"none\""
<a_mask> ::= " mask=\"" <funciri> "\"" | " mask=\"none\""
<a_filter> ::= " filter=\"" <funciri> "\"" | " filter=\"none\""

<a_transform> ::= " transform=\"" <transform_list> "\""

# transform list — all seven forms, chained.
<transform_list> ::= <transform> (<tsep> <transform>){0,3}
<tsep> ::= " " | ", " | ",\n"
<transform> ::= (
      "translate(" <num> ")" | "translate(" <num> <sep> <num> ")"
    | "scale(" <num> ")" | "scale(" <num> <sep> <num> ")"
    | "rotate(" <num> ")" | "rotate(" <num> <sep> <num> <sep> <num> ")"
    | "skewX(" <num> ")" | "skewY(" <num> ")"
    | "matrix(" <num> <sep> <num> <sep> <num> <sep> <num> <sep> <num> \
      <sep> <num> ")"
)

# Shared references: href (both legacy xlink:href and modern href).
<a_href> ::= " xlink:href=\"" <iri> "\"" | " href=\"" <iri> "\""
<iri> ::= "#" <ncname> | "url(#" <ncname> ")" | <uri>
<uri> ::= (
      "http://example.org/" <pathpart>
    | "https://example.com/" <pathpart> ".svg"
    | "data:image/png;base64,iVBORw0KGgo="
    | <pathpart> ".svg"
)
<pathpart> ::= r'[a-zA-Z0-9_/.-]{1,20}'
<funciri> ::= "url(#" <ncname> ")"

# Paint / color values — biased to every legacy color syntax.
<paint> ::= <color> | "none" | "currentColor" | "inherit" | "transparent" \
    | <funciri> | (<funciri> " " <color>) | (<funciri> " none")
<color> ::= (
      <hex_color> | <rgb_color> | <rgb_pct_color> | <named_color>
    | <rgba_color> | <hsl_color> | "currentColor"
)
<hex_color> ::= "#" r'[0-9a-fA-F]{3}' | "#" r'[0-9a-fA-F]{6}'
<rgb_color> ::= "rgb(" <rgbval> "," <rgbval> "," <rgbval> ")"
<rgb_pct_color> ::= "rgb(" <percentage> "%," <percentage> "%," <percentage> "%)"
<rgba_color> ::= "rgba(" <rgbval> "," <rgbval> "," <rgbval> "," <ratio> ")"
<hsl_color> ::= "hsl(" <hue> "," <percentage> "%," <percentage> "%)"
<hue> ::= r'[0-9]{1,3}'
<rgbval> ::= r'[0-9]{1,3}'
<named_color> ::= "black" | "white" | "red" | "green" | "blue" | "none" \
    | "aliceblue" | "rebeccapurple" | "cornflowerblue" | "darkslategray" \
    | "transparent" | "orange" | "fuchsia" | "gold" | "silver"

# Numeric primitives — heavily biased to boundary/extreme values.
# Signed numbers, incl. leading dot, trailing dot, exponents, zero.
<num> ::= <int_num> | <float_num> | <exp_num>
<int_num> ::= "0" | "-0" | <sign>? r'[0-9]{1,6}'
<float_num> ::= <sign>? r'[0-9]{0,4}' "." r'[0-9]{1,4}'
<exp_num> ::= <sign>? r'[0-9]{1,3}' "." r'[0-9]{1,3}' <exp>
<exp> ::= ("e" | "E") <sign>? r'[0-9]{1,2}'
<sign> ::= "+" | "-"

<numlist> ::= <num> (<sep> <num>){0,6}

<nonneg_num> ::= "0" | r'[0-9]{1,6}' | (r'[0-9]{0,4}' "." r'[0-9]{1,4}')
<nonneg_int> ::= "0" | r'[0-9]{1,5}'
<int_signed> ::= <sign>? r'[0-9]{1,5}'

# coord = a signed number (may be extreme)
<coord> ::= <num>

# length with unit — every SVG unit incl. deprecated.
<length_or_pct> ::= <num> | (<nonneg_num> <unit>) | (<percentage> "%") | "0"
<unit> ::= "px" | "pt" | "pc" | "cm" | "mm" | "in" | "em" | "ex" | "%"

<percentage> ::= r'[0-9]{1,3}'

# ratio in [0,1] plus out-of-range extremes (clamp-testing) — no where needed
<ratio> ::= "0" | "1" | "0.0" | "1.0" | ("0." r'[0-9]{1,4}') \
    | ("1." r'[0-9]{1,4}') | "-0.5" | "1.5"

# Names / text.
<ncname> ::= r'[A-Za-z_][A-Za-z0-9_.-]{0,15}'

# text body: printable chars that need no XML escaping, plus explicit entities.
<text_body> ::= (<text_chunk> | <char_ref> | <ws1>){1,6}
<text_chunk> ::= r'[A-Za-z0-9 .,:;/()!?=_+*@#$%^~`|\[\]{}]{1,25}'
<char_ref> ::= "&amp;" | "&lt;" | "&gt;" | "&quot;" | "&apos;" \
    | "&#" <dec_cp> ";" | "&#x" <hex_cp> ";"
# bounded code points that stay legal (>=32) and don't hit surrogates/controls
<dec_cp> ::= "32" | "65" | "233" | "8364" | "9731" | "128512"
<hex_cp> ::= "41" | "20AC" | "263A" | "D7FF" | "1F600"

# Numeric range constraints — top-level (Fandango rejects inline `where`).
where int(str(<hue>)) <= 360
where int(str(<rgbval>)) <= 255
where int(str(<percentage>)) <= 100
