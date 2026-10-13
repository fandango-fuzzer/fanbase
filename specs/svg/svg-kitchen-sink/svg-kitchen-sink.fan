# A single, near-fully-fixed SVG document packing almost every feature in
# at once (gradients, patterns, filters, animation, legacy fonts). Useful
# as a compatibility sample.
#
# TODO:
# * Almost every production is a fixed literal, so this barely fuzzes
#   anything; add real alternation to make it an actual generator.

<start> ::= <xml_decl> <svg_document>;

<xml_decl> ::= "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
<svg_document> ::= "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\"" <root_attrs> ">\n" <descriptive_block> <definitions_block>? <scene_block> <animation_block>? <legacy_block>? <script_block>? "</svg>\n";
<root_attrs> ::= " viewBox=\"0 0 640 480\" width=\"640\" height=\"480\"" <presentation_attrs>? <root_rare_attrs>?;
<root_rare_attrs> ::= " version=\"1.1\" baseProfile=\"full\" preserveAspectRatio=\"xMidYMid meet\" zoomAndPan=\"magnify\" xml:lang=\"en\" xml:space=\"preserve\" tabindex=\"0\"";

<descriptive_block> ::= "<title>Fandango SVG specimen</title>\n<desc>Bounded coverage of SVG graphics, resources, text, animation, filters, and legacy features.</desc>\n" <metadata>?;
<metadata> ::= "<metadata><rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"><rdf:Description rdf:about=\"\"/></rdf:RDF></metadata>\n";

<definitions_block> ::= "<defs>\n" <paint_servers> <symbol_defs> <clip_mask_defs> <marker_def>? <filter_def>? <style_def>? "</defs>\n";
<paint_servers> ::= <linear_gradient> <radial_gradient>? <pattern_def>? <solid_color_legacy>?;
<linear_gradient> ::= "<linearGradient id=\"grad-main\" x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"100%\" gradientUnits=\"objectBoundingBox\" spreadMethod=\"pad\" gradientTransform=\"rotate(15)\"><stop offset=\"0%\" stop-color=\"#ff006e\"/><stop offset=\"50%\" stop-color=\"rgb(40,120,255)\" stop-opacity=\"0.75\"/><stop offset=\"100%\" stop-color=\"currentColor\"/></linearGradient>\n";
<radial_gradient> ::= "<radialGradient id=\"grad-radial\" cx=\"50%\" cy=\"50%\" r=\"50%\" fx=\"25%\" fy=\"25%\" fr=\"0%\" gradientUnits=\"objectBoundingBox\" spreadMethod=\"reflect\"><stop offset=\"0\" stop-color=\"white\"/><stop offset=\"1\" stop-color=\"black\"/></radialGradient>\n";
<pattern_def> ::= "<pattern id=\"pattern-main\" x=\"0\" y=\"0\" width=\"16\" height=\"16\" patternUnits=\"userSpaceOnUse\" patternContentUnits=\"userSpaceOnUse\" patternTransform=\"skewX(8)\" viewBox=\"0 0 16 16\" preserveAspectRatio=\"none\"><rect width=\"8\" height=\"8\" fill=\"#ddd\"/><rect x=\"8\" y=\"8\" width=\"8\" height=\"8\" fill=\"#777\"/></pattern>\n";
<solid_color_legacy> ::= "<solidColor id=\"solid-legacy\" solid-color=\"navy\" solid-opacity=\"0.8\"/>\n";
<symbol_defs> ::= "<symbol id=\"symbol-main\" viewBox=\"0 0 20 20\" preserveAspectRatio=\"xMidYMid slice\"><circle cx=\"10\" cy=\"10\" r=\"9\"/><path d=\"M5 10h10M10 5v10\"/></symbol>\n";
<clip_mask_defs> ::= "<clipPath id=\"clip-main\" clipPathUnits=\"userSpaceOnUse\"><path d=\"M0 0H600V440H0Z M80 80V360H520V80Z\" clip-rule=\"evenodd\"/></clipPath>\n<mask id=\"mask-main\" x=\"-10%\" y=\"-10%\" width=\"120%\" height=\"120%\" maskUnits=\"objectBoundingBox\" maskContentUnits=\"userSpaceOnUse\" mask-type=\"luminance\"><rect width=\"640\" height=\"480\" fill=\"white\"/><circle cx=\"320\" cy=\"240\" r=\"80\" fill=\"black\"/></mask>\n";
<marker_def> ::= "<marker id=\"arrow\" markerUnits=\"strokeWidth\" markerWidth=\"8\" markerHeight=\"8\" refX=\"7\" refY=\"4\" orient=\"auto-start-reverse\" viewBox=\"0 0 8 8\" preserveAspectRatio=\"xMidYMid meet\" overflow=\"visible\"><path d=\"M0 0L8 4L0 8Z\"/></marker>\n";
<style_def> ::= "<style type=\"text/css\"><![CDATA[.accent { stroke: #663399; vector-effect: non-scaling-stroke; } text { font-family: sans-serif; }]]></style>\n";

<filter_def> ::= "<filter id=\"filter-main\" x=\"-20%\" y=\"-20%\" width=\"140%\" height=\"140%\" filterUnits=\"objectBoundingBox\" primitiveUnits=\"userSpaceOnUse\" color-interpolation-filters=\"linearRGB\">\n" <filter_primitives> "</filter>\n";
<filter_primitives> ::= <fe_gaussian> <fe_offset> <fe_color_matrix> <fe_blend> <filter_rare_primitives>?;
<fe_gaussian> ::= "<feGaussianBlur in=\"SourceGraphic\" stdDeviation=\"2 3\" edgeMode=\"duplicate\" result=\"blurred\"/>\n";
<fe_offset> ::= "<feOffset in=\"blurred\" dx=\"4\" dy=\"4\" result=\"shifted\"/>\n";
<fe_color_matrix> ::= "<feColorMatrix in=\"shifted\" type=\"matrix\" values=\"1 0 0 0 0 0 0.7 0 0 0 0 0 0.4 0 0 0 0 0 0.8 0\" result=\"colored\"/>\n";
<fe_blend> ::= "<feBlend in=\"SourceGraphic\" in2=\"colored\" mode=\"multiply\" result=\"composite\"/>\n";
<filter_rare_primitives> ::= <fe_component_transfer> <fe_composite> <fe_convolve> <fe_displacement> <fe_flood> <fe_image> <fe_lighting> <fe_morphology> <fe_tile> <fe_turbulence> <fe_merge>;
<fe_component_transfer> ::= "<feComponentTransfer in=\"composite\" result=\"transfer\"><feFuncR type=\"gamma\" amplitude=\"1\" exponent=\"0.8\" offset=\"0\"/><feFuncG type=\"linear\" slope=\"1.1\" intercept=\"0\"/><feFuncB type=\"table\" tableValues=\"0 0.4 1\"/><feFuncA type=\"identity\"/></feComponentTransfer>\n";
<fe_composite> ::= "<feComposite in=\"transfer\" in2=\"SourceGraphic\" operator=\"arithmetic\" k1=\"0\" k2=\"1\" k3=\"1\" k4=\"0\" result=\"arithmetic\"/>\n";
<fe_convolve> ::= "<feConvolveMatrix in=\"arithmetic\" order=\"3 3\" kernelMatrix=\"0 -1 0 -1 5 -1 0 -1 0\" divisor=\"1\" bias=\"0\" targetX=\"1\" targetY=\"1\" edgeMode=\"wrap\" kernelUnitLength=\"1 1\" preserveAlpha=\"true\" result=\"sharp\"/>\n";
<fe_displacement> ::= "<feDisplacementMap in=\"sharp\" in2=\"SourceGraphic\" scale=\"3\" xChannelSelector=\"R\" yChannelSelector=\"G\" result=\"displaced\"/>\n";
<fe_flood> ::= "<feFlood flood-color=\"#00ffff\" flood-opacity=\"0.2\" result=\"flood\"/>\n";
<fe_image> ::= "<feImage href=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg'/%3E\" x=\"0\" y=\"0\" width=\"1\" height=\"1\" preserveAspectRatio=\"none\" result=\"image\"/>\n";
<fe_lighting> ::= "<feDiffuseLighting in=\"SourceAlpha\" surfaceScale=\"2\" diffuseConstant=\"1\" kernelUnitLength=\"1\" lighting-color=\"white\" result=\"diffuse\"><feDistantLight azimuth=\"225\" elevation=\"45\"/></feDiffuseLighting><feSpecularLighting in=\"SourceAlpha\" surfaceScale=\"2\" specularConstant=\"1\" specularExponent=\"12\" lighting-color=\"white\" result=\"specular\"><fePointLight x=\"100\" y=\"100\" z=\"200\"/></feSpecularLighting><feSpecularLighting in=\"SourceAlpha\" surfaceScale=\"1\" specularConstant=\"0.5\" specularExponent=\"8\" result=\"spot\"><feSpotLight x=\"320\" y=\"0\" z=\"200\" pointsAtX=\"320\" pointsAtY=\"240\" pointsAtZ=\"0\" specularExponent=\"4\" limitingConeAngle=\"35\"/></feSpecularLighting>\n";
<fe_morphology> ::= "<feMorphology in=\"SourceAlpha\" operator=\"dilate\" radius=\"1 2\" result=\"morph\"/>\n";
<fe_tile> ::= "<feTile in=\"image\" x=\"0\" y=\"0\" width=\"640\" height=\"480\" result=\"tiled\"/>\n";
<fe_turbulence> ::= "<feTurbulence type=\"fractalNoise\" baseFrequency=\"0.01 0.03\" numOctaves=\"2\" seed=\"7\" stitchTiles=\"stitch\" result=\"noise\"/>\n";
<fe_merge> ::= "<feMerge result=\"merged\"><feMergeNode in=\"flood\"/><feMergeNode in=\"SourceGraphic\"/></feMerge>\n";

<scene_block> ::= <background> <shape_group> <path_group> <text_group> <embedded_group>? <use_group>? <bounded_nested_groups>?;
<background> ::= "<rect id=\"background\" x=\"0\" y=\"0\" width=\"100%\" height=\"100%\" rx=\"0\" ry=\"0\" fill=\"#f8f9fa\"/>\n";
<shape_group> ::= "<g id=\"shapes\"" <group_attrs>? ">\n" <rect_element> <circle_element> <ellipse_element>? <line_element> <polyline_element>? <polygon_element> "</g>\n";
<group_attrs> ::= " transform=\"translate(1 2) rotate(0) scale(1) skewX(0) skewY(0)\" opacity=\"0.95\" style=\"isolation:isolate;mix-blend-mode:normal\"";
<rect_element> ::= "<rect x=\"10\" y=\"10\" width=\"120\" height=\"70\" rx=\"8\" ry=\"12\"" <presentation_attrs> <geometry_rare_attrs>? "/>\n";
<circle_element> ::= "<circle cx=\"190\" cy=\"50\" r=\"40\" fill=\"url(#grad-main)\" stroke=\"#111\" stroke-width=\"1\"" <interaction_attrs>? "/>\n";
<ellipse_element> ::= "<ellipse cx=\"290\" cy=\"50\" rx=\"70\" ry=\"30\" fill=\"url(#grad-radial)\" transform=\"rotate(-12 290 50)\"/>\n";
<line_element> ::= "<line x1=\"380\" y1=\"20\" x2=\"610\" y2=\"85\" stroke=\"#246\" stroke-width=\"4\" stroke-linecap=\"round\" marker-start=\"url(#arrow)\" marker-mid=\"url(#arrow)\" marker-end=\"url(#arrow)\"/>\n";
<polyline_element> ::= "<polyline points=\"10,120 45,90 80,130 115,95 150,120\" fill=\"none\" stroke=\"green\" stroke-linejoin=\"bevel\" stroke-miterlimit=\"4\"/>\n";
<polygon_element> ::= "<polygon points=\"180,120 215,90 250,120 235,160 195,160\" fill=\"url(#pattern-main)\" fill-rule=\"nonzero\" paint-order=\"stroke fill markers\"/>\n";
<geometry_rare_attrs> ::= " pathLength=\"100\" vector-effect=\"non-scaling-stroke\" shape-rendering=\"crispEdges\" pointer-events=\"visiblePainted\"";

<path_group> ::= "<g id=\"paths\" fill=\"none\" stroke=\"#222\">\n" <path_all_commands> <path_arcs> <path_boundary>? "</g>\n";
<path_all_commands> ::= "<path id=\"path-main\" d=\"M20 210 L70 180 H120 V220 C140 150 180 260 210 190 S270 160 300 210 Q330 250 360 205 T420 200 A35 20 30 0 1 490 210 Z m10 10 l20 0 h10 v10 c5 5 10 -5 15 0 s10 5 15 0 q5 -5 10 0 t10 0 a5 5 0 1 0 10 0 z\" stroke-dasharray=\"8 3 2\" stroke-dashoffset=\"-2\" pathLength=\"500\"/>\n";
<path_arcs> ::= "<path d=\"M520 180A1 1 0 0 0 522 182A100 0.01 179 1 1 600 220\" stroke=\"tomato\"/>\n";
<path_boundary> ::= "<path d=\"M-1000000 -1000000L1000000 1000000\" stroke-width=\"0.001\" opacity=\"0.001\" vector-effect=\"non-scaling-stroke\"/>\n";

<text_group> ::= "<g id=\"text-content\" fill=\"#111\">\n" <text_element> <text_path_element>? <multiline_text>? "</g>\n";
<text_element> ::= "<text x=\"20\" y=\"290\" dx=\"0 1 -1\" dy=\"0 0 1\" rotate=\"0 5 -5\" textLength=\"300\" lengthAdjust=\"spacingAndGlyphs\" font-family=\"serif\" font-size=\"22\" font-style=\"italic\" font-weight=\"600\" font-stretch=\"condensed\" text-anchor=\"start\" dominant-baseline=\"alphabetic\" writing-mode=\"horizontal-tb\" direction=\"ltr\" unicode-bidi=\"embed\" letter-spacing=\"0.05em\" word-spacing=\"0.1em\" text-decoration=\"underline\">SVG &amp; XML <tspan x=\"20\" dy=\"1.3em\" baseline-shift=\"super\">tspan</tspan></text>\n";
<text_path_element> ::= "<text font-size=\"14\"><textPath href=\"#path-main\" xlink:href=\"#path-main\" startOffset=\"10%\" method=\"align\" spacing=\"auto\" side=\"left\">Text following a path</textPath></text>\n";
<multiline_text> ::= "<text x=\"400\" y=\"280\"><tspan x=\"400\">line one</tspan><tspan x=\"400\" dy=\"1.2em\">line two</tspan><tref xlink:href=\"#text-source\"/></text><text id=\"text-source\" display=\"none\">legacy tref source</text>\n";

<embedded_group> ::= "<g id=\"embedded\">\n" <image_element> <foreign_object>? <switch_element>? "</g>\n";
<image_element> ::= "<image x=\"500\" y=\"300\" width=\"1\" height=\"1\" href=\"data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==\" xlink:href=\"data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==\" preserveAspectRatio=\"xMaxYMax meet\" image-rendering=\"pixelated\" crossorigin=\"anonymous\"/>\n";
<foreign_object> ::= "<foreignObject x=\"20\" y=\"350\" width=\"180\" height=\"60\" requiredExtensions=\"http://www.w3.org/1999/xhtml\"><div xmlns=\"http://www.w3.org/1999/xhtml\" style=\"font:12px sans-serif\">foreignObject content</div></foreignObject>\n";
<switch_element> ::= "<switch><text systemLanguage=\"en\" x=\"220\" y=\"380\">English</text><text requiredFeatures=\"http://www.w3.org/TR/SVG11/feature#Shape\" x=\"220\" y=\"380\">Fallback</text></switch>\n";
<use_group> ::= "<g id=\"instances\"><use href=\"#symbol-main\" xlink:href=\"#symbol-main\" x=\"520\" y=\"390\" width=\"40\" height=\"40\"/><use href=\"#symbol-main\" x=\"570\" y=\"390\" width=\"0\" height=\"0\"/></g>\n";

<bounded_nested_groups> ::= "<g id=\"nest-1\" transform=\"translate(1 1)\"><g id=\"nest-2\" opacity=\"0.9\"><g id=\"nest-3\" clip-path=\"url(#clip-main)\"><g id=\"nest-4\" mask=\"url(#mask-main)\"><g id=\"nest-5\" filter=\"url(#filter-main)\"><circle cx=\"600\" cy=\"450\" r=\"4\"/></g></g></g></g></g>\n";

<animation_block> ::= "<g id=\"animated\">\n" <animate_element> <animate_transform> <animate_motion>? <set_element>? <discard_element>? "</g>\n";
<animate_element> ::= "<rect x=\"300\" y=\"320\" width=\"30\" height=\"30\"><animate attributeName=\"opacity\" attributeType=\"CSS\" from=\"0\" to=\"1\" dur=\"2s\" begin=\"0s;indefinite\" end=\"10s\" min=\"0.1s\" max=\"5s\" restart=\"always\" repeatCount=\"2\" repeatDur=\"4s\" fill=\"freeze\" calcMode=\"spline\" values=\"0;0.5;1\" keyTimes=\"0;0.4;1\" keySplines=\"0.42 0 0.58 1;0.42 0 0.58 1\" additive=\"replace\" accumulate=\"none\"/></rect>\n";
<animate_transform> ::= "<g><animateTransform attributeName=\"transform\" type=\"rotate\" from=\"0 360 360\" to=\"360 360 360\" dur=\"3s\" repeatCount=\"indefinite\" additive=\"sum\"/><rect x=\"350\" y=\"350\" width=\"20\" height=\"10\"/></g>\n";
<animate_motion> ::= "<circle r=\"5\"><animateMotion dur=\"4s\" rotate=\"auto-reverse\" path=\"M400 400C450 320 500 480 550 400\" keyPoints=\"0;0.5;1\" keyTimes=\"0;0.5;1\" calcMode=\"linear\"><mpath href=\"#path-main\" xlink:href=\"#path-main\"/></animateMotion></circle>\n";
<set_element> ::= "<set href=\"#background\" attributeName=\"visibility\" to=\"visible\" begin=\"1s\" dur=\"1ms\"/>\n";
<discard_element> ::= "<discard href=\"#text-source\" begin=\"60s\"/>\n";

<legacy_block> ::= "<g id=\"legacy-features\">\n" <legacy_font> <legacy_color_profile> <legacy_cursor> "</g>\n";
<legacy_font> ::= "<font id=\"font-legacy\" horiz-adv-x=\"1000\"><font-face font-family=\"LegacyVector\" units-per-em=\"1000\" ascent=\"800\" descent=\"-200\" alphabetic=\"0\" underline-position=\"-100\" underline-thickness=\"50\"/><missing-glyph horiz-adv-x=\"500\" d=\"M0 0H500V700H0Z\"/><glyph unicode=\"A\" glyph-name=\"A\" horiz-adv-x=\"700\" d=\"M0 0L350 700L700 0H550L450 200H250L150 0Z\"/><hkern u1=\"A\" u2=\"V\" k=\"-40\"/><vkern g1=\"A\" g2=\"A\" k=\"10\"/></font>\n";
<legacy_color_profile> ::= "<color-profile name=\"sRGB-legacy\" xlink:href=\"data:application/vnd.iccprofile;base64,\" rendering-intent=\"auto\"/>\n";
<legacy_cursor> ::= "<cursor id=\"cursor-legacy\" x=\"0\" y=\"0\" xlink:href=\"data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==\"/>\n";

<script_block> ::= "<script type=\"application/ecmascript\"><![CDATA[/* inert SVG script payload */ void 0;]]></script>\n";

<presentation_attrs> ::= " fill=\"" <paint> "\" fill-opacity=\"" <opacity> "\" fill-rule=\"evenodd\" stroke=\"" <paint> "\" stroke-opacity=\"" <opacity> "\" stroke-width=\"2\" stroke-linecap=\"square\" stroke-linejoin=\"round\" stroke-miterlimit=\"10\" stroke-dasharray=\"none\" opacity=\"" <opacity> "\" color=\"rebeccapurple\" color-interpolation=\"sRGB\" color-rendering=\"optimizeQuality\" display=\"inline\" visibility=\"visible\" overflow=\"hidden\"";
<paint> ::= "none" | "currentColor" | "#123456" | "rgb(1, 2, 3)" | "url(#grad-main) #808080" | "context-fill" | "context-stroke";
<opacity> ::= <opacity_percent> "%";
<opacity_percent> ::= "0" | "1" | "50" | "99" | "100";
<interaction_attrs> ::= " class=\"accent\" tabindex=\"-1\" focusable=\"true\" cursor=\"crosshair\" pointer-events=\"all\" touch-action=\"none\"";
