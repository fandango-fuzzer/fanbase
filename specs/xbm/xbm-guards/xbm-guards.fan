# X-Windows Bitmap (XBM) C source.
#
# Modern X11 files store ceil(width / 8) bytes per scanline.  The legacy X10
# representation stores 16-bit shorts and word-pads each scanline.  Each
# geometry below therefore has an exact, statically bounded raster length.

<start> ::= <plain_file> | <guarded_file> | <nested_file>;

<plain_file> ::= <preamble> <bitmap>;
<guarded_file> ::= "#ifndef IMAGE_XBM_INCLUDED" <nl> "#define IMAGE_XBM_INCLUDED" <nl> <preamble> <bitmap> "#endif" <nl>;
<nested_file> ::= "#if 1" <nl> "#if defined(__STDC__)" <nl> "#if 1" <nl> <preamble> <bitmap> "#endif" <nl> "#endif" <nl> "#endif" <nl>;

<preamble> ::= "" | "/* X bitmap */" <nl> | "/* X11 bitmap: least-significant bit first in each byte. */" <nl>;

<bitmap> ::= <x11_1x1> | <x11_8x1> | <x11_9x2> | <x11_17x3> | <x11_32x4> | <x11_64x8> | <x11_257x1> | <x11_1x17> | <x10_1x1> | <x10_9x2> | <x10_17x3> | <x10_32x4>;

<x11_1x1> ::= <defs_1x1> <decl_u8_open> <bytes_1> <array_close>;
<x11_8x1> ::= <defs_8x1> <decl_u8_open> <bytes_1> <array_close>;
<x11_9x2> ::= <defs_9x2> <hotspots_9x2> <decl_u8_open> <bytes_4> <array_close>;
<x11_17x3> ::= <defs_17x3> <decl_u8_open> <bytes_9> <array_close>;
<x11_32x4> ::= <defs_32x4> <decl_u8_open> <bytes_16> <array_close>;
<x11_64x8> ::= <defs_64x8> <hotspots_64x8> <decl_u8_open> <bytes_64> <array_close>;
<x11_257x1> ::= <defs_257x1> <hotspots_257x1> <decl_u8_open> <bytes_33> <array_close>;
<x11_1x17> ::= <defs_1x17> <decl_u8_open> <bytes_17> <array_close>;

<x10_1x1> ::= <defs_1x1> <decl_short_open> <shorts_1> <array_close>;
<x10_9x2> ::= <defs_9x2> <hotspots_9x2> <decl_short_open> <shorts_2> <array_close>;
<x10_17x3> ::= <defs_17x3> <decl_short_open> <shorts_6> <array_close>;
<x10_32x4> ::= <defs_32x4> <decl_short_open> <shorts_8> <array_close>;

<defs_1x1> ::= "#define" <hws> "image_width" <hws> "1" <nl> "#define" <hws> "image_height" <hws> "1" <nl>;
<defs_8x1> ::= "#define" <hws> "image_width" <hws> "8" <nl> "#define" <hws> "image_height" <hws> "1" <nl>;
<defs_9x2> ::= "#define" <hws> "image_width" <hws> "9" <nl> "#define" <hws> "image_height" <hws> "2" <nl>;
<defs_17x3> ::= "#define" <hws> "image_width" <hws> "17" <nl> "#define" <hws> "image_height" <hws> "3" <nl>;
<defs_32x4> ::= "#define" <hws> "image_width" <hws> "32" <nl> "#define" <hws> "image_height" <hws> "4" <nl>;
<defs_64x8> ::= "#define" <hws> "image_width" <hws> "64" <nl> "#define" <hws> "image_height" <hws> "8" <nl>;
<defs_257x1> ::= "#define" <hws> "image_width" <hws> "257" <nl> "#define" <hws> "image_height" <hws> "1" <nl>;
<defs_1x17> ::= "#define" <hws> "image_width" <hws> "1" <nl> "#define" <hws> "image_height" <hws> "17" <nl>;

<hotspots_9x2> ::= "" | <hotspots_9x2_xy> | <hotspots_9x2_yx>;
<hotspots_9x2_xy> ::= "#define" <hws> "image_x_hot" <hws> <hot_x_9> <nl> "#define" <hws> "image_y_hot" <hws> <hot_y_2> <nl>;
<hotspots_9x2_yx> ::= "#define" <hws> "image_y_hot" <hws> <hot_y_2> <nl> "#define" <hws> "image_x_hot" <hws> <hot_x_9> <nl>;
<hot_x_9> ::= <hot_x_9_value>;
<hot_x_9_value> ::= r'[0-9]';
where int(<hot_x_9_value>) >= 0 and int(<hot_x_9_value>) < 9
<hot_y_2> ::= <hot_y_2_value>;
<hot_y_2_value> ::= r'[0-9]';
where int(<hot_y_2_value>) >= 0 and int(<hot_y_2_value>) < 2

<hotspots_64x8> ::= "" | "#define" <hws> "image_x_hot" <hws> <hot_x_64> <nl> "#define" <hws> "image_y_hot" <hws> <hot_y_8> <nl>;
<hot_x_64> ::= <hot_x_64_value>;
<hot_x_64_value> ::= r'[0-9]{1,2}';
where int(<hot_x_64_value>) >= 0 and int(<hot_x_64_value>) < 64
<hot_y_8> ::= <hot_y_8_value>;
<hot_y_8_value> ::= r'[0-9]';
where int(<hot_y_8_value>) >= 0 and int(<hot_y_8_value>) < 8

<hotspots_257x1> ::= "" | "#define" <hws> "image_x_hot" <hws> <hot_x_257> <nl> "#define" <hws> "image_y_hot" <hws> "0" <nl>;
<hot_x_257> ::= <hot_x_257_value>;
<hot_x_257_value> ::= r'[0-9]{1,3}';
where int(<hot_x_257_value>) >= 0 and int(<hot_x_257_value>) < 257

<decl_u8_open> ::= <storage_u8> <hws> "image_bits[]" <ows> "=" <ows> "{" <data_lead>;
<storage_u8> ::= "static unsigned char" | "static const unsigned char" | "static unsigned const char";
<decl_short_open> ::= "static short" <hws> "image_bits[]" <ows> "=" <ows> "{" <data_lead>;
<array_close> ::= <trailing_comma> <data_tail> "};" <nl>;

<bytes_1> ::= <byte>;
<bytes_4> ::= <byte> (<element_sep> <byte>){3};
<bytes_9> ::= <byte> (<element_sep> <byte>){8};
<bytes_16> ::= <byte> (<element_sep> <byte>){15};
<bytes_17> ::= <byte> (<element_sep> <byte>){16};
<bytes_33> ::= <byte> (<element_sep> <byte>){32};
<bytes_64> ::= <byte> (<element_sep> <byte>){63};
<byte> ::= r'0x[0-9a-fA-F]{2}';

<shorts_1> ::= <short>;
<shorts_2> ::= <short> (<element_sep> <short>){1};
<shorts_6> ::= <short> (<element_sep> <short>){5};
<shorts_8> ::= <short> (<element_sep> <short>){7};
<short> ::= r'0x[0-9a-fA-F]{4}';

<element_sep> ::= <ows> "," <separator_space>;
<separator_space> ::= <hws> | <nl> <hws>;
<trailing_comma> ::= "" | <ows> ",";
<data_lead> ::= <hws> | <nl> <hws>;
<data_tail> ::= <hws> | <nl>;
<ows> ::= r'[ \t]{0,2}';
<hws> ::= r'[ \t]{1,4}';
<nl> ::= "\n" | "\r\n";
