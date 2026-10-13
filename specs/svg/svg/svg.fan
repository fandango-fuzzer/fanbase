# SVG 1.1: document structure (svg/g/defs/symbol/use/switch/a), basic
# shapes, paths, text, gradients/patterns, clipping/masking, filters,
# markers/images, style/script, and SMIL animation. Every element writes
# its own literal open/close tags, so start/end names match by
# construction.

<start> ::= <svg_document>

<svg_document> ::= <xml_decl> <svg_root> "\n"

<xml_decl> ::= '<?xml version="1.0" encoding="UTF-8"?>' "\n"

<svg_root> ::= (
      '<svg xmlns="http://www.w3.org/2000/svg"'
      ' xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1"'
      ' width="' <length> '" height="' <length> '"'
      ' viewBox="' <viewbox> '">' "\n"
      <desc_block>
      <element>{1,6}
      "</svg>"
    )

# descriptive block shown once near the top
<desc_block> ::= <title_el> <desc_el>?

<title_el>    ::= "<title>" <text_content> "</title>" "\n"
<desc_el>     ::= "<desc>" <text_content> "</desc>" "\n"
<metadata_el> ::= "<metadata>" <text_content> "</metadata>" "\n"

# Top-level element choice
<element> ::= ( <leaf_element>
              | <container_g>
              | <defs_el>
              | <use_el>
              | <symbol_el>
              | <switch_el>
              | <a_el>
              | <lineargradient_el>
              | <radialgradient_el>
              | <pattern_el>
              | <clippath_el>
              | <mask_el>
              | <filter_el>
              | <marker_el>
              | <style_el>
              | <script_el>
              | <animation_el>
              | <metadata_el> )

<animation_el> ::= ( <animate_el>
                   | <animatetransform_el>
                   | <animatemotion_el>
                   | <set_el> )

# Leaf (non-container) elements -- safe to nest without recursion blow-up.
<leaf_element> ::= ( <rect_el>
                   | <circle_el>
                   | <ellipse_el>
                   | <line_el>
                   | <polyline_el>
                   | <polygon_el>
                   | <path_el>
                   | <text_el>
                   | <image_el>
                   | <use_el> )

# Containers
<container_g> ::= "<g" <common_attrs> ">" "\n" <leaf_element>{1,5} "</g>" "\n"

<defs_el> ::= "<defs>" "\n" <def_item>{1,5} "</defs>" "\n"

<def_item> ::= ( <lineargradient_el>
               | <radialgradient_el>
               | <pattern_el>
               | <clippath_el>
               | <mask_el>
               | <filter_el>
               | <marker_el>
               | <symbol_el>
               | <container_g> )

<symbol_el> ::= (
      '<symbol id="' <name> '" viewBox="' <viewbox> '">' "\n"
      <leaf_element>{1,4}
      "</symbol>" "\n" )

<switch_el> ::= "<switch>" "\n" <leaf_element>{1,3} "</switch>" "\n"

<a_el> ::= (
      '<a xlink:href="' <uri> '">' "\n"
      <leaf_element>{1,3}
      "</a>" "\n" )

<use_el> ::= (
      '<use xlink:href="#' <name> '"'
      ' x="' <coordinate> '" y="' <coordinate> '"'
      <common_attrs> "/>" "\n" )

# Basic shapes
<rect_el> ::= (
      '<rect x="' <coordinate> '" y="' <coordinate> '"'
      ' width="' <length> '" height="' <length> '"'
      <rxry>? <common_attrs> "/>" "\n" )

<rxry> ::= ' rx="' <length> '" ry="' <length> '"'

<circle_el> ::= (
      '<circle cx="' <coordinate> '" cy="' <coordinate> '"'
      ' r="' <length> '"' <common_attrs> "/>" "\n" )

<ellipse_el> ::= (
      '<ellipse cx="' <coordinate> '" cy="' <coordinate> '"'
      ' rx="' <length> '" ry="' <length> '"' <common_attrs> "/>" "\n" )

<line_el> ::= (
      '<line x1="' <coordinate> '" y1="' <coordinate> '"'
      ' x2="' <coordinate> '" y2="' <coordinate> '"'
      <common_attrs> "/>" "\n" )

<polyline_el> ::= '<polyline points="' <points> '"' <common_attrs> "/>" "\n"
<polygon_el>  ::= '<polygon points="' <points> '"' <common_attrs> "/>" "\n"

<path_el> ::= '<path d="' <path_data> '"' <common_attrs> "/>" "\n"

# Text
<text_el> ::= (
      '<text x="' <coordinate> '" y="' <coordinate> '"'
      <text_attrs> <common_attrs> ">"
      <text_run>
      "</text>" "\n" )

<text_run> ::= <text_content> <tspan_el>* <textpath_el>?

<tspan_el> ::= (
      '<tspan x="' <coordinate> '" dy="' <number> '"'
      <text_attrs> ">" <text_content> "</tspan>" )

<textpath_el> ::= (
      '<textPath xlink:href="#' <name> '">'
      <text_content> "</textPath>" )

<text_attrs> ::= <a_fontfamily>? <a_fontsize>? <a_textanchor>?

<a_fontfamily> ::= ' font-family="' <fontname> '"'
<a_fontsize>   ::= ' font-size="' <length> '"'
<a_textanchor> ::= ' text-anchor="' <anchor> '"'
<anchor>       ::= "start" | "middle" | "end"
<fontname>     ::= "sans-serif" | "serif" | "monospace" | "Arial" | "Verdana"

# Paint servers: gradients / patterns
<lineargradient_el> ::= (
      '<linearGradient id="' <name> '"'
      ' x1="' <pct> '%" y1="' <pct> '%" x2="' <pct> '%" y2="' <pct> '%">' "\n"
      <stop_el>{2,4}
      "</linearGradient>" "\n" )

<radialgradient_el> ::= (
      '<radialGradient id="' <name> '"'
      ' cx="' <pct> '%" cy="' <pct> '%" r="' <pct> '%">' "\n"
      <stop_el>{2,4}
      "</radialGradient>" "\n" )

<stop_el> ::= (
      '<stop offset="' <ratio> '" stop-color="' <color> '"'
      <stopopacity>? "/>" "\n" )

<stopopacity> ::= ' stop-opacity="' <ratio> '"'

<pattern_el> ::= (
      '<pattern id="' <name> '" width="' <length> '" height="' <length> '"'
      ' patternUnits="' <units> '">' "\n"
      <leaf_element>{1,3}
      "</pattern>" "\n" )

<units> ::= "userSpaceOnUse" | "objectBoundingBox"

# Clipping / masking
<clippath_el> ::= (
      '<clipPath id="' <name> '">' "\n"
      <leaf_element>{1,3}
      "</clipPath>" "\n" )

<mask_el> ::= (
      '<mask id="' <name> '">' "\n"
      <leaf_element>{1,3}
      "</mask>" "\n" )

# Filters
<filter_el> ::= (
      '<filter id="' <name> '">' "\n"
      <fe_primitive>{1,4}
      "</filter>" "\n" )

<fe_primitive> ::= ( <fe_gaussianblur>
                   | <fe_offset>
                   | <fe_blend>
                   | <fe_flood>
                   | <fe_colormatrix>
                   | <fe_merge>
                   | <fe_composite>
                   | <fe_morphology>
                   | <fe_turbulence>
                   | <fe_dropshadow> )

<fe_gaussianblur> ::= (
      '<feGaussianBlur in="' <fe_in> '" stdDeviation="' <number> '"/>' "\n" )

<fe_offset> ::= (
      '<feOffset in="' <fe_in> '" dx="' <number> '" dy="' <number> '"/>' "\n" )

<fe_blend> ::= (
      '<feBlend in="' <fe_in> '" in2="' <fe_in> '" mode="' <blendmode> '"/>' "\n" )

<fe_flood> ::= (
      '<feFlood flood-color="' <color> '" flood-opacity="' <ratio> '"/>' "\n" )

<fe_colormatrix> ::= (
      '<feColorMatrix type="matrix" values="' <matrix_values> '"/>' "\n" )

<fe_merge> ::= "<feMerge>" "\n" <fe_mergenode>{1,3} "</feMerge>" "\n"

<fe_mergenode> ::= '<feMergeNode in="' <fe_in> '"/>' "\n"

<fe_composite> ::= (
      '<feComposite in="' <fe_in> '" in2="' <fe_in> '" operator="' <compositeop> '"/>' "\n" )

<fe_morphology> ::= (
      '<feMorphology operator="' <morphop> '" radius="' <upos> '"/>' "\n" )

<fe_turbulence> ::= (
      '<feTurbulence type="' <turbtype> '" baseFrequency="' <ratio> '"'
      ' numOctaves="' <smallint> '"/>' "\n" )

<fe_dropshadow> ::= (
      '<feDropShadow dx="' <number> '" dy="' <number> '"'
      ' stdDeviation="' <upos> '" flood-color="' <color> '"/>' "\n" )

<fe_in>      ::= "SourceGraphic" | "SourceAlpha" | "BackgroundImage"
<blendmode>  ::= "normal" | "multiply" | "screen" | "darken" | "lighten"
<compositeop>::= "over" | "in" | "out" | "atop" | "xor" | "arithmetic"
<morphop>    ::= "erode" | "dilate"
<turbtype>   ::= "turbulence" | "fractalNoise"

# Markers / images
<marker_el> ::= (
      '<marker id="' <name> '" markerWidth="' <length> '"'
      ' markerHeight="' <length> '" orient="' <orient> '">' "\n"
      <leaf_element>{1,2}
      "</marker>" "\n" )

<orient> ::= "auto" | "auto-start-reverse" | <number>

<image_el> ::= (
      '<image xlink:href="' <uri> '" x="' <coordinate> '" y="' <coordinate> '"'
      ' width="' <length> '" height="' <length> '"/>' "\n" )

# Styling / scripting
<style_el> ::= '<style type="text/css">' <css_rules> "</style>" "\n"

<css_rules> ::= <css_rule>{1,3}
<css_rule>  ::= <css_selector> " { " <css_decl>{1,3} "}" "\n"
<css_selector> ::= ( "." <name> ) | ( "#" <name> ) | <shapename>
<css_decl>  ::= <css_prop> ": " <css_val> "; "
<css_prop>  ::= "fill" | "stroke" | "opacity" | "stroke-width"
<css_val>   ::= <color> | <ratio> | <number>
<shapename> ::= "rect" | "circle" | "path" | "text" | "g"

<script_el> ::= '<script type="text/javascript"><![CDATA[' <js_body> ']]></script>' "\n"
<js_body>   ::= r'[A-Za-z0-9_ ;=().+*/-]{0,40}'

# Animation
<animate_el> ::= (
      '<animate attributeName="' <animattr> '" from="' <number> '"'
      ' to="' <number> '" dur="' <duration> '"'
      ' repeatCount="' <repeatcount> '"/>' "\n" )

<animatetransform_el> ::= (
      '<animateTransform attributeName="transform" type="' <transformtype> '"'
      ' from="' <number> '" to="' <number> '" dur="' <duration> '"/>' "\n" )

<animatemotion_el> ::= (
      '<animateMotion path="' <path_data> '" dur="' <duration> '"/>' "\n" )

<set_el> ::= (
      '<set attributeName="' <animattr> '" to="' <number> '" dur="' <duration> '"/>' "\n" )

<animattr>      ::= "x" | "y" | "cx" | "cy" | "r" | "opacity" | "width" | "height"
<transformtype> ::= "translate" | "scale" | "rotate" | "skewX" | "skewY"
<duration>      ::= <upos> "s"
<repeatcount>   ::= "indefinite" | <smallint>

# Common presentation attributes (distinct optional slots => no dup attributes)
<common_attrs> ::= ( <a_id>? <a_class>? <a_fill>? <a_stroke>?
                     <a_strokewidth>? <a_opacity>? <a_transform>? <a_style>? )

<a_id>          ::= ' id="' <name> '"'
<a_class>       ::= ' class="' <name> '"'
<a_fill>        ::= ' fill="' <paint> '"'
<a_stroke>      ::= ' stroke="' <paint> '"'
<a_strokewidth> ::= ' stroke-width="' <length> '"'
<a_opacity>     ::= ' opacity="' <ratio> '"'
<a_transform>   ::= ' transform="' <transform> '"'
<a_style>       ::= ' style="' <inline_style> '"'

<inline_style>  ::= <css_decl>{1,3}

# Attribute value primitives
# Paint = a color, "none", "currentColor", or a reference to a paint server.
<paint> ::= <color> | "none" | "currentColor" | ( 'url(#' <name> ')' )

<color> ::= <hexcolor> | <shorthexcolor> | <rgbcolor> | <namedcolor>

<hexcolor>      ::= "#" r'[0-9a-fA-F]{6}'
<shorthexcolor> ::= "#" r'[0-9a-fA-F]{3}'

# rgb() with each channel constrained to the legal 0..255 range.
<rgbcolor> ::= "rgb(" <channel> "," <channel> "," <channel> ")"
<channel>  ::= r'[0-9]{1,3}'
where int(str(<channel>)) <= 255

<namedcolor> ::= ( "black" | "white" | "red" | "green" | "blue" | "yellow"
                 | "orange" | "purple" | "gray" | "cyan" | "magenta"
                 | "navy" | "teal" | "silver" | "maroon" | "olive" )

# A ratio in the closed unit interval [0, 1] (opacity, gradient offset, ...).
<ratio> ::= "0" | "1" | ( "0." r'[0-9]{1,3}' )

# A percentage value 0..100 (bare number; caller appends the '%').
<pct> ::= r'[0-9]{1,3}'
where int(str(<pct>)) <= 100

# Signed numbers and positive lengths.
<number>     ::= r'-?(0|[1-9][0-9]{0,3})(\.[0-9]{1,2})?'
<upos>       ::= r'(0|[1-9][0-9]{0,3})(\.[0-9]{1,2})?'
<coordinate> ::= <number>
<smallint>   ::= r'[1-9]'

# A length is a positive number with an optional CSS unit.
<length> ::= <upos> <unit>?
<unit>   ::= "px" | "pt" | "em" | "ex" | "%" | "cm" | "mm" | "in"

# viewBox = min-x min-y width height ; width/height must be non-negative.
<viewbox> ::= <number> " " <number> " " <upos> " " <upos>

# points list for polyline/polygon
<points> ::= <point> ( " " <point> ){2,8}
<point>  ::= <number> "," <number>

# names / ids and URIs
<name> ::= r'[A-Za-z_][A-Za-z0-9_-]{0,12}'
<uri>  ::= ( ( "https://example.org/" r'[A-Za-z0-9_/.-]{1,16}' )
           | ( "data:image/png;base64," r'[A-Za-z0-9+/]{4,16}' ) )

# text content: printable, no XML-significant chars (< & > " ')
<text_content> ::= r'[A-Za-z0-9 .,!?:;()-]{1,30}'

# transform attribute
<transform> ::= <transform_fn> ( " " <transform_fn> ){0,2}

<transform_fn> ::= ( ( "translate(" <number> "," <number> ")" )
                   | ( "scale(" <upos> ")" )
                   | ( "rotate(" <number> ")" )
                   | ( "rotate(" <number> "," <number> "," <number> ")" )
                   | ( "skewX(" <number> ")" )
                   | ( "skewY(" <number> ")" )
                   | ( "matrix(" <number> "," <number> "," <number> ","
                                 <number> "," <number> "," <number> ")" ) )

<matrix_values> ::= <number> ( " " <number> ){19}

# path-data mini grammar (subset of the SVG path command set)
<path_data> ::= <moveto> <path_command>{1,6}

<moveto> ::= ( "M" | "m" ) " " <coord_pair>

<path_command> ::= ( <lineto>
                   | <hlineto>
                   | <vlineto>
                   | <curveto>
                   | <quadto>
                   | <arcto>
                   | <closepath> )

<lineto>    ::= " " ( "L" | "l" ) " " <coord_pair>
<hlineto>   ::= " " ( "H" | "h" ) " " <number>
<vlineto>   ::= " " ( "V" | "v" ) " " <number>
<curveto>   ::= " " ( "C" | "c" ) " " <coord_pair> " " <coord_pair> " " <coord_pair>
<quadto>    ::= " " ( "Q" | "q" ) " " <coord_pair> " " <coord_pair>
<arcto>     ::= ( " " ( "A" | "a" ) " " <upos> " " <upos> " " <number>
                  " " <flag> " " <flag> " " <coord_pair> )
<closepath> ::= " " ( "Z" | "z" )

<coord_pair> ::= <number> "," <number>
<flag>       ::= "0" | "1"
