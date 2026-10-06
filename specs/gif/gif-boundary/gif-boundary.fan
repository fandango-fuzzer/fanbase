# GIF87a / GIF89a built from a fixed set of edge values: tiny and huge screen
# sizes, the packed byte flag combinations, 2, 4 and 256 entry color tables,
# unknown extension labels and a 255 byte sub-block. Images are 1x1 with valid
# LZW data.
# 
# TODO:
# * Build these based on `gif.fan` rather than writing things from scratch.
# * Replace constant strings with computed values.

<start> ::= <gif87a> | <gif89a>

<gif87a> ::= "GIF87a" <body87_no_gct> | "GIF87a" <body87_gct2> | "GIF87a" <body87_gct4> | "GIF87a" <body87_gct256>
<gif89a> ::= "GIF89a" <body89_no_gct> | "GIF89a" <body89_gct2> | "GIF89a" <body89_gct4> | "GIF89a" <body89_gct256>

<body87_no_gct> ::= <screen87_no_gct> <image87_local_required>{1,3} <trailer>
<body87_gct2> ::= <screen87_gct2> <image87_active_small>{1,3} <trailer>
<body87_gct4> ::= <screen87_gct4> <image87_active_small>{1,3} <trailer>
<body87_gct256> ::= <screen87_gct256> <image87_active_large>{1,3} <trailer>

<body89_no_gct> ::= <screen_no_gct> <general_extension>{0,3} <controlled_image_local> (<general_extension>{0,2} <controlled_image_local>){0,2} <general_extension>{0,3} <trailer>
<body89_gct2> ::= <screen_gct2> <gct_extension>{0,3} <controlled_render_small> (<gct_extension>{0,2} <controlled_render_small>){0,2} <gct_extension>{0,3} <trailer>
<body89_gct4> ::= <screen_gct4> <gct_extension>{0,3} <controlled_render_small> (<gct_extension>{0,2} <controlled_render_small>){0,2} <gct_extension>{0,3} <trailer>
<body89_gct256> ::= <screen_gct256> <gct_extension>{0,3} <controlled_render_large> (<gct_extension>{0,2} <controlled_render_large>){0,2} <gct_extension>{0,3} <trailer>

# Logical Screen Descriptor and the immediately following optional global table.
<screen_no_gct> ::= <screen_dimensions> <packed_no_gct> "\x00" <pixel_aspect>
<screen_gct2> ::= <screen_dimensions> <packed_gct2> <background_2> <pixel_aspect> <color_table_2>
<screen_gct4> ::= <screen_dimensions> <packed_gct4> <background_4> <pixel_aspect> <color_table_4>
<screen_gct256> ::= <screen_dimensions> <packed_gct256> <background_256> <pixel_aspect> <color_table_256>
<screen87_no_gct> ::= <screen_dimensions> "\x00\x00" <pixel_aspect>
<screen87_gct2> ::= <screen_dimensions> "\x80" <background_2> <pixel_aspect> <color_table_2>
<screen87_gct4> ::= <screen_dimensions> "\x81" <background_4> <pixel_aspect> <color_table_4>
<screen87_gct256> ::= <screen_dimensions> "\x87" <background_256> <pixel_aspect> <color_table_256>
<screen_dimensions> ::= "\x01\x00\x01\x00" | "\x02\x00\x02\x00" | "\xff\xff\xff\xff" | "\x00\x01\x00\x01" | "\x40\x01\xc8\x00"
<packed_no_gct> ::= "\x00" | "\x70" | "\x78" | "\x07"
<packed_gct2> ::= "\x80" | "\xf0" | "\xf8" | "\x88"
<packed_gct4> ::= "\x81" | "\xf1" | "\xf9" | "\x99"
<packed_gct256> ::= "\x87" | "\xf7" | "\xff" | "\x8f"
<background_2> ::= "\x00" | "\x01"
<background_4> ::= "\x00" | "\x01" | "\x02" | "\x03"
<background_256> ::= "\x00" | "\x01" | "\x7f" | "\xfe" | "\xff"
<pixel_aspect> ::= "\x00" | "\x01" | "\x31" | "\x71" | "\xff"

# Tables include canonical palettes plus generated boundary-heavy tables.
<color_table_2> ::= "\x00\x00\x00\xff\xff\xff" | "\xff\x00\x00\x00\x00\xff" | <rgb>{2}
<color_table_4> ::= "\x00\x00\x00\xff\x00\x00\x00\xff\x00\x00\x00\xff" | <rgb>{4}
<color_table_256> ::= <rgb>{256}
<rgb> ::= "\x00\x00\x00" | "\xff\xff\xff" | "\xff\x00\x00" | "\x00\xff\x00" | "\x00\x00\xff" | "\x7f\x80\x01"

# Rendering blocks. A Graphic Control Extension is adjacent to the rendering block it controls.
<controlled_image_local> ::= <graphic_control>? <image_local_required>
<controlled_render_small> ::= <graphic_control>? <image_active_small> | <graphic_control>? <plain_text_extension>
<controlled_render_large> ::= <graphic_control>? <image_active_large> | <graphic_control>? <plain_text_extension>

# All images are a valid 1x1 raster positioned at the origin; rare descriptor flags and local tables vary.
<image_local_required> ::= "\x2c\x00\x00\x00\x00\x01\x00\x01\x00" (<local_2> <image_data_2> | <local_4> <image_data_2> | <local_256> <image_data_8>)
<image_active_small> ::= "\x2c\x00\x00\x00\x00\x01\x00\x01\x00" (<no_local_flags> <image_data_2> | <local_2> <image_data_2> | <local_4> <image_data_2> | <local_256> <image_data_8>)
<image_active_large> ::= "\x2c\x00\x00\x00\x00\x01\x00\x01\x00" (<no_local_flags> <image_data_8> | <local_2> <image_data_2> | <local_4> <image_data_2> | <local_256> <image_data_8>)
<image87_local_required> ::= "\x2c\x00\x00\x00\x00\x01\x00\x01\x00" (<local87_2> <image_data_2> | <local87_4> <image_data_2> | <local87_256> <image_data_8>)
<image87_active_small> ::= "\x2c\x00\x00\x00\x00\x01\x00\x01\x00" (<no_local_flags> <image_data_2> | <local87_2> <image_data_2> | <local87_4> <image_data_2> | <local87_256> <image_data_8>)
<image87_active_large> ::= "\x2c\x00\x00\x00\x00\x01\x00\x01\x00" (<no_local_flags> <image_data_8> | <local87_2> <image_data_2> | <local87_4> <image_data_2> | <local87_256> <image_data_8>)
<no_local_flags> ::= "\x00" | "\x40"
<local_2> ::= <packed_local_2> <color_table_2>
<local_4> ::= <packed_local_4> <color_table_4>
<local_256> ::= <packed_local_256> <color_table_256>
<local87_2> ::= ("\x80" | "\xc0") <color_table_2>
<local87_4> ::= ("\x81" | "\xc1") <color_table_4>
<local87_256> ::= ("\x87" | "\xc7") <color_table_256>
<packed_local_2> ::= "\x80" | "\x88" | "\xc0" | "\xc8"
<packed_local_4> ::= "\x81" | "\x89" | "\xc1" | "\xc9"
<packed_local_256> ::= "\x87" | "\x8f" | "\xc7" | "\xcf"

# Valid LZW streams: clear, one palette index, end-of-information, then the zero terminator.
<image_data_2> ::= "\x02\x02\x44\x01\x00" | "\x02\x02\x4c\x01\x00"
<image_data_8> ::= "\x08\x04\x00\x01\x04\x04\x00"

# GIF89a extensions, including legacy Plain Text and common application protocols.
<general_extension> ::= <comment_extension> | <application_extension> | <unknown_extension>
<gct_extension> ::= <general_extension> | <plain_text_extension>
<graphic_control> ::= "\x21\xf9\x04" (<gce_opaque> | <gce_transparent>) "\x00"
<gce_opaque> ::= <gce_opaque_packed> <delay_time> <ignored_color_index>
<gce_transparent> ::= <gce_transparent_packed> <delay_time> "\x00"
<gce_opaque_packed> ::= "\x00" | "\x02" | "\x04" | "\x06" | "\x08" | "\x0a" | "\x0c" | "\x0e"
<gce_transparent_packed> ::= "\x01" | "\x03" | "\x05" | "\x07" | "\x09" | "\x0b" | "\x0d" | "\x0f"
<delay_time> ::= "\x00\x00" | "\x01\x00" | "\x64\x00" | "\xff\xff"
<ignored_color_index> ::= "\x00" | "\x01" | "\x7f" | "\xff"

<comment_extension> ::= "\x21\xfe" <data_subblocks>
<plain_text_extension> ::= "\x21\x01" <plain_text_header> <data_subblocks>
<plain_text_header> ::= "\x0c" <plain_text_fields>
where len(str(<plain_text_fields>)) == 12
<plain_text_fields> ::= "\x00\x00\x00\x00\x01\x00\x01\x00\x01\x01\x00\x01" | "\x00\x00\x00\x00\x01\x00\x01\x00\xff\xff\x01\x00"

<application_extension> ::= <netscape_loop> | <animexts_loop> | <generic_application>
<netscape_loop> ::= "\x21\xff\x0bNETSCAPE2.0\x03\x01" <loop_count> "\x00"
<animexts_loop> ::= "\x21\xff\x0bANIMEXTS1.0\x03\x01" <loop_count> "\x00"
<loop_count> ::= "\x00\x00" | "\x01\x00" | "\xff\xff"
<generic_application> ::= "\x21\xff\x0b" <application_identifier> <data_subblocks>
where len(str(<application_identifier>)) == 11
<application_identifier> ::= "ICCRGBG1012" | "XMP DataXMP" | "MGK8BIM0000" | <app_ascii>{11}
<app_ascii> ::= r'[A-Z0-9 ]'

# Unknown labels are syntactically forward-compatible extension blocks.
<unknown_extension> ::= "\x21" <unknown_label> <data_subblocks>
<unknown_label> ::= "\x02" | "\x7f" | "\xfc"

# Each branch's size byte exactly matches its payload; the maximum 255-byte sub-block is included.
<data_subblocks> ::= <data_subblock>{0,3} "\x00"
<data_subblock> ::= "\x01" <data_byte> | "\x02" <data_byte>{2} | "\x03" <data_byte>{3} | "\x08" <data_byte>{8} | "\xff" <data_byte>{255}
<data_byte> ::= r'[\x00-\x7f]'

<trailer> ::= "\x3b"
