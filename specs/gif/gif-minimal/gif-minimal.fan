# GIF87a / GIF89a with 1x1 images only. Every image has a valid one-pixel LZW
# stream, for each legal minimum code size. Covers global and local color
# tables, the interlace flag, and the graphic control, comment, plain text
# and application extensions. Block lengths and table sizes are checked with
# where clauses.
#
# TODO:
# * Replace constant image string with computed values.
# * Check which header and trailer bits are fixed and which are variable.
# * Use this structure in `gif.fan`, too

<start> ::= <gif87a_data_stream> | <gif89a_data_stream>

# GIF87a defines table-based images but not the GIF89a extension blocks.
<gif87a_data_stream> ::= b"GIF87a" <logical_screen> <table_based_image>+ <trailer>

# GIF89a permits rendering blocks and special-purpose extension blocks.
<gif89a_data_stream> ::= b"GIF89a" <logical_screen> <gif89a_block>* <rendering_block> <gif89a_block>* <trailer>
<gif89a_block> ::= <rendering_block> | <special_purpose_block>
<rendering_block> ::= <graphic_control_extension>? <graphic_rendering_block>
<graphic_rendering_block> ::= <table_based_image> | <plain_text_extension>
<special_purpose_block> ::= <comment_extension> | <application_extension>

# Logical Screen Descriptor. Width and height are nonzero unsigned 16-bit
# little-endian values. The two alternatives enforce the global-table flag.
<logical_screen> ::= <logical_screen_width> <logical_screen_height> <logical_screen_tail>
<logical_screen_width> ::= <byte> <byte>
where int.from_bytes(bytes(<logical_screen_width>), "little") >= 1
<logical_screen_height> ::= <byte> <byte>
where int.from_bytes(bytes(<logical_screen_height>), "little") >= 1
<logical_screen_tail> ::= <logical_screen_with_global_table> | <logical_screen_without_global_table>

# Packed byte: bit 7 = global-table flag; bits 6..4 = color resolution minus
# one; bit 3 = sort flag; bits 2..0 = global-table size exponent minus one.
<logical_screen_with_global_table> ::= (
    <global_table_packed> <background_color_index> <pixel_aspect_ratio> <global_color_table>
)
where len(bytes(<global_color_table>)) == 3 * (2 ** ((bytes(<global_table_packed>)[0] & 7) + 1)) and bytes(<background_color_index>)[0] < len(bytes(<global_color_table>)) // 3
<global_table_packed> ::= <byte>
where (bytes(<global_table_packed>)[0] & 128) == 128
<logical_screen_without_global_table> ::= <no_global_table_packed> <background_color_index> <pixel_aspect_ratio>
<no_global_table_packed> ::= <byte>
where (bytes(<no_global_table_packed>)[0] & 128) == 0
<background_color_index> ::= <byte>
<pixel_aspect_ratio> ::= <byte>

<global_color_table> ::= <rgb_color>{2,256}
<local_color_table> ::= <rgb_color>{2,256}
<rgb_color> ::= <red> <green> <blue>
<red> ::= <byte>
<green> ::= <byte>
<blue> ::= <byte>

# A Table-Based Image consists of descriptor, conditional local palette, and
# LZW image data. The raster is one pixel, so its zero origin is contained in
# every legal nonempty logical screen while preserving all descriptor flags.
<table_based_image> ::= b"\x2c" <image_left> <image_top> <image_width> <image_height> <image_table_and_data>
<image_left> ::= b"\x00\x00"
<image_top> ::= b"\x00\x00"
<image_width> ::= b"\x01\x00"
where int.from_bytes(bytes(<image_width>), "little") == 1
<image_height> ::= b"\x01\x00"
where int.from_bytes(bytes(<image_height>), "little") == 1
<image_table_and_data> ::= <image_with_local_table> | <image_without_local_table>

# Image packed byte: bit 7 = local-table flag; bit 6 = interlace; bit 5 = sort;
# bits 4..3 are reserved zero; bits 2..0 = local-table size exponent minus one.
<image_with_local_table> ::= <local_table_packed> <local_color_table> <lzw_image_data>
where len(bytes(<local_color_table>)) == 3 * (2 ** ((bytes(<local_table_packed>)[0] & 7) + 1))
<local_table_packed> ::= <byte>
where (bytes(<local_table_packed>)[0] & 152) == 128
<image_without_local_table> ::= <no_local_table_packed> <lzw_image_data>
<no_local_table_packed> ::= b"\x00" | b"\x40"

# Each alternative is: LZW minimum code size, one nonempty data sub-block with
# its exact length, compressed codes, and the zero-length block terminator.
# Codes are packed least-significant-bit first as required by GIF.
<lzw_image_data> ::= (
      b"\x02\x02\x44\x01\x00"
    | b"\x03\x02\x08\x09\x00"
    | b"\x04\x02\x10\x44\x00"
    | b"\x05\x03\x20\x10\x02\x00"
    | b"\x06\x03\x40\x40\x10\x00"
    | b"\x07\x03" <octet_80> b"\x00" <octet_81> b"\x00"
    | b"\x08\x04\x00\x01\x04\x04\x00"
)

# Graphic Control Extension: fixed block size 4 and fixed zero terminator.
# Packed reserved bits are zero; disposal method is one of the defined 0..3;
# user-input and transparency flags occupy bits 1 and 0.
<graphic_control_extension> ::= b"\x21" <octet_f9> b"\x04" <graphic_control_packed> <delay_time> <transparent_color_index> b"\x00"
<graphic_control_packed> ::= <byte>
where (bytes(<graphic_control_packed>)[0] & 224) == 0 and ((bytes(<graphic_control_packed>)[0] >> 2) & 7) <= 3
<delay_time> ::= <byte> <byte>
<transparent_color_index> ::= <byte>

# Comment Extension: a sequence of 1..255-byte sub-blocks, then terminator.
<comment_extension> ::= b"\x21" <octet_fe> <comment_data_sub_block>* b"\x00"
<comment_data_sub_block> ::= <comment_block_size> <comment_block_data>
where bytes(<comment_block_size>)[0] == len(bytes(<comment_block_data>))
<comment_block_size> ::= <nonzero_byte>
<comment_block_data> ::= <byte>{1,255}

# Plain Text Extension: fixed 12-byte header followed by text sub-blocks.
<plain_text_extension> ::= (
    b"\x21\x01\x0c" <text_grid_left> <text_grid_top> <text_grid_width> <text_grid_height>
    <character_cell_width> <character_cell_height> <text_foreground_color_index>
    <text_background_color_index> <plain_text_data_sub_block>* b"\x00"
)
<text_grid_left> ::= b"\x00\x00"
<text_grid_top> ::= b"\x00\x00"
<text_grid_width> ::= b"\x01\x00"
where int.from_bytes(bytes(<text_grid_width>), "little") == 1
<text_grid_height> ::= b"\x01\x00"
where int.from_bytes(bytes(<text_grid_height>), "little") == 1
<character_cell_width> ::= <nonzero_byte>
<character_cell_height> ::= <nonzero_byte>
<text_foreground_color_index> ::= <byte>
<text_background_color_index> ::= <byte>
<plain_text_data_sub_block> ::= <plain_text_block_size> <plain_text_block_data>
where bytes(<plain_text_block_size>)[0] == len(bytes(<plain_text_block_data>))
<plain_text_block_size> ::= <nonzero_byte>
<plain_text_block_data> ::= <byte>{1,255}

# Application Extension: fixed 11-byte application header (8-byte identifier
# plus 3-byte authentication code) and length-constrained application data.
<application_extension> ::= b"\x21" <octet_ff> b"\x0b" <application_identifier> <application_authentication_code> <application_data_sub_block>* b"\x00"
<application_identifier> ::= <byte>{8}
where len(bytes(<application_identifier>)) == 8
<application_authentication_code> ::= <byte>{3}
where len(bytes(<application_authentication_code>)) == 3
<application_data_sub_block> ::= <application_block_size> <application_block_data>
where bytes(<application_block_size>)[0] == len(bytes(<application_block_data>))
<application_block_size> ::= <nonzero_byte>
<application_block_data> ::= <byte>{1,255}

<trailer> ::= b"\x3b"
<nonzero_byte> ::= <byte>
where 1 <= bytes(<nonzero_byte>)[0] <= 255
<byte> ::= <bit> <bit> <bit> <bit> <bit> <bit> <bit> <bit>
where 0 <= bytes(<byte>)[0] <= 255
<bit> ::= 0 | 1
<octet_80> ::= 1 0 0 0 0 0 0 0
<octet_81> ::= 1 0 0 0 0 0 0 1
<octet_f9> ::= 1 1 1 1 1 0 0 1
<octet_fe> ::= 1 1 1 1 1 1 1 0
<octet_ff> ::= 1 1 1 1 1 1 1 1
