# Same XPM3 scope as xpm, with the surrounding C lexical detail varied
# instead: storage-class spelling (static/const static/static const),
# optional const qualifier, arbitrary identifiers, interspersed comments,
# and the fuller X colour notation (rgb:/rgbi: intensities alongside hex
# and named colours). Bounded to four pixels across and 1..4 rows.

<start> ::= <xpm_file>;

<xpm_file> ::= (<magic> <c_gap> <declaration> <c_gap> <xpm_without_extensions> <c_gap> <array_close> <c_gap>
              | <magic> <c_gap> <declaration> <c_gap> <xpm_with_extensions> <c_gap> <array_close> <c_gap>);

# 1. Magic identifier and comments.
<magic> ::= "/* XPM */";
<c_gap> ::= (<horizontal_space> | <newline> | <c_comment>)*;
<horizontal_space> ::= r'[ \t]+';
<newline> ::= "\n";
<c_comment> ::= "/*" <comment_text>? "*/";
<comment_text> ::= r'([^*]|\*+[^*/])*';

# 2. C declaration.  These are the conventional declarations accepted for
# XPM data arrays; the array element type is a pointer to character data.
<declaration> ::= (<storage_class> <decl_space> "char" <decl_space> "*" <decl_space>? <identifier> <decl_space>? "[" <decl_space>? "]" <decl_space>? "=" <decl_space>? "{"
                  | "static" <decl_space> "char" <decl_space> "*" <decl_space>? "const" <decl_space> <identifier> <decl_space>? "[" <decl_space>? "]" <decl_space>? "=" <decl_space>? "{");
<storage_class> ::= "static" | "const static" | "static const";
<decl_space> ::= r'[ \t]+';
<identifier> ::= r'[A-Za-z_][A-Za-z0-9_]{0,31}';
<array_close> ::= "}" <decl_space>? ";";

# 3. Values/header line.  The four structural alternatives below make the
# number of following raster rows exactly equal to the declared height.  The
# width-to-row-length relationship is stated explicitly on <pixel_row_data>.
<xpm_without_extensions> ::= (<values_line_plain_1> <c_gap> <color_table> <c_gap> <pixel_rows_1>
                            | <values_line_plain_2> <c_gap> <color_table> <c_gap> <pixel_rows_2>
                            | <values_line_plain_3> <c_gap> <color_table> <c_gap> <pixel_rows_3>
                            | <values_line_plain_4> <c_gap> <color_table> <c_gap> <pixel_rows_4>);
<xpm_with_extensions> ::= (<values_line_extended_1> <c_gap> <color_table> <c_gap> <pixel_rows_comma_1> <c_gap> <extension_blocks> <c_gap> <extension_end>
                         | <values_line_extended_2> <c_gap> <color_table> <c_gap> <pixel_rows_comma_2> <c_gap> <extension_blocks> <c_gap> <extension_end>
                         | <values_line_extended_3> <c_gap> <color_table> <c_gap> <pixel_rows_comma_3> <c_gap> <extension_blocks> <c_gap> <extension_end>
                         | <values_line_extended_4> <c_gap> <color_table> <c_gap> <pixel_rows_comma_4> <c_gap> <extension_blocks> <c_gap> <extension_end>);

<values_line_plain_1> ::= <values_prefix> "1 " <ncolors> " " <chars_per_pixel> <hotspot>? "\"," <c_line_comment>?;
<values_line_plain_2> ::= <values_prefix> "2 " <ncolors> " " <chars_per_pixel> <hotspot>? "\"," <c_line_comment>?;
<values_line_plain_3> ::= <values_prefix> "3 " <ncolors> " " <chars_per_pixel> <hotspot>? "\"," <c_line_comment>?;
<values_line_plain_4> ::= <values_prefix> "4 " <ncolors> " " <chars_per_pixel> <hotspot>? "\"," <c_line_comment>?;
<values_line_extended_1> ::= <values_prefix> "1 " <ncolors> " " <chars_per_pixel> <hotspot>? " XPMEXT\"," <c_line_comment>?;
<values_line_extended_2> ::= <values_prefix> "2 " <ncolors> " " <chars_per_pixel> <hotspot>? " XPMEXT\"," <c_line_comment>?;
<values_line_extended_3> ::= <values_prefix> "3 " <ncolors> " " <chars_per_pixel> <hotspot>? " XPMEXT\"," <c_line_comment>?;
<values_line_extended_4> ::= <values_prefix> "4 " <ncolors> " " <chars_per_pixel> <hotspot>? " XPMEXT\"," <c_line_comment>?;
<values_prefix> ::= "\"" <width> " ";
<width> ::= "4";
<ncolors> ::= "4";
<chars_per_pixel> ::= "1";
where int(<width>) >= 1 and int(<width>) <= 65535 and int(<ncolors>) == len("abcd") and int(<chars_per_pixel>) == len("a");
<hotspot> ::= " " <x_hotspot> " " <y_hotspot>
where int(<x_hotspot>) >= 0 and int(<x_hotspot>) < int(<width>) and int(<y_hotspot>) == 0;
<x_hotspot> ::= r'[0-3]';
<y_hotspot> ::= "0";
<c_line_comment> ::= <decl_space>? <c_comment>;

# 4. Color table.  Exactly four distinct codes are declared, matching the
# header's ncolors value.  Every attributes list must contain a color (c) key;
# any of the other standard visual/symbolic keys may accompany it.
<color_table> ::= <color_entry_a> <c_gap> <color_entry_b> <c_gap> <color_entry_c> <c_gap> <color_entry_d>;
<color_entry_a> ::= "\"a" <color_attributes> "\"," <c_line_comment>?;
<color_entry_b> ::= "\"b" <color_attributes> "\"," <c_line_comment>?;
<color_entry_c> ::= "\"c" <color_attributes> "\"," <c_line_comment>?;
<color_entry_d> ::= "\"d" <color_attributes> "\"," <c_line_comment>?;
<color_attributes> ::= <symbolic_attribute>? <mono_attribute>? <gray4_attribute>? <gray_attribute>? <color_attribute>;
<symbolic_attribute> ::= " s " <symbolic_name>;
<mono_attribute> ::= " m " <color_value>;
<gray4_attribute> ::= " g4 " <color_value>;
<gray_attribute> ::= " g " <color_value>;
<color_attribute> ::= " c " <color_value>;
<symbolic_name> ::= r'[A-Za-z_][A-Za-z0-9_.-]{0,20}';

# 5. X color values.  Named values permit embedded spaces as used by the X11
# color database; the remaining alternatives cover the standard XParseColor
# numeric notations usable by libXpm.
<color_value> ::= "None" | <named_color> | <hex_color> | <rgb_color> | <rgbi_color>;
<named_color> ::= "black" | "white" | "red" | "green" | "blue" | "yellow" | "gray" | "grey" | "Light Sky Blue" | "Dark Slate Gray";
<hex_color> ::= "#" <hex_digit>{3,3} | "#" <hex_digit>{6,6} | "#" <hex_digit>{9,9} | "#" <hex_digit>{12,12};
<hex_digit> ::= r'[0-9A-Fa-f]';
<rgb_color> ::= "rgb:" <hex_component> "/" <hex_component> "/" <hex_component>;
<hex_component> ::= <hex_digit> | <hex_digit>{2,2} | <hex_digit>{3,3} | <hex_digit>{4,4};
<rgbi_color> ::= "rgbi:" <unit_intensity> "/" <unit_intensity> "/" <unit_intensity>;
<unit_intensity> ::= "0" | "1" | "0.0" | "0.25" | "0.5" | "0.75" | "1.0";

# 6. Pixel raster.  The height alternatives enforce the header's row count.
# Each row contains exactly width * chars-per-pixel bytes and only a/b/c/d,
# all of which are declared above.  This repeated-row invariant is structural
# so that it applies to every occurrence rather than one selected tree node.
<pixel_rows_1> ::= <pixel_row_last>;
<pixel_rows_2> ::= <pixel_row_more> <c_gap> <pixel_row_last>;
<pixel_rows_3> ::= <pixel_row_more> <c_gap> <pixel_row_more> <c_gap> <pixel_row_last>;
<pixel_rows_4> ::= <pixel_row_more> <c_gap> <pixel_row_more> <c_gap> <pixel_row_more> <c_gap> <pixel_row_last>;
<pixel_rows_comma_1> ::= <pixel_row_more>;
<pixel_rows_comma_2> ::= <pixel_row_more> <c_gap> <pixel_row_more>;
<pixel_rows_comma_3> ::= <pixel_row_more> <c_gap> <pixel_row_more> <c_gap> <pixel_row_more>;
<pixel_rows_comma_4> ::= <pixel_row_more> <c_gap> <pixel_row_more> <c_gap> <pixel_row_more> <c_gap> <pixel_row_more>;
<pixel_row_more> ::= "\"" <pixel_row_data> "\"," <c_line_comment>?;
<pixel_row_last> ::= "\"" <pixel_row_data> "\"" <c_line_comment>?;
<pixel_row_data> ::= r'[abcd]{4,4}';

# 7. XPM extension section.  XPMEXT in the header is structurally required
# whenever these blocks are present; XPMENDEXT terminates the section.
<extension_blocks> ::= <extension_block>+;
<extension_block> ::= "\"XPMEXT " <extension_name> "\"," <c_line_comment>? <c_gap> <extension_data_lines>;
<extension_name> ::= r'[A-Za-z0-9_.-]{1,24}';
<extension_data_lines> ::= <extension_data_line>*;
<extension_data_line> ::= "\"" <extension_text> "\"," <c_line_comment>? <c_gap>;
<extension_text> ::= (<string_safe_char> | <c_escape>)*;
<string_safe_char> ::= r'[ !#-\[\]-~]';
<c_escape> ::= "\\\\" | "\\\"" | "\\t";
<extension_end> ::= "\"XPMENDEXT\"" <c_line_comment>?;
