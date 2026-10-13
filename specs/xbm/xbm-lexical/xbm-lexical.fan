# Same X11/X10 dialects as xbm, with the surrounding C lexical detail varied
# instead of the geometry: arbitrary identifier stems, block comments and
# whitespace between tokens, char/unsigned-char/short/unsigned-short element
# types, and an optional trailing comma.

<start> ::= <x11_without_hotspot> | <x11_with_hotspot> | <x10_without_hotspot> | <x10_with_hotspot>

<x11_without_hotspot> ::= <x11_width_define> <x11_height_define> <x11_declaration>
<x11_with_hotspot> ::= <x11h_width_define> <x11h_height_define> <x11h_x_hot_define> <x11h_y_hot_define> <x11h_declaration>
<x10_without_hotspot> ::= <x10_width_define> <x10_height_define> <x10_declaration>
<x10_with_hotspot> ::= <x10h_width_define> <x10h_height_define> <x10h_x_hot_define> <x10h_y_hot_define> <x10h_declaration>
where str(<x11_width_stem>) == str(<x11_height_stem>) and str(<x11_width_stem>) == str(<x11_array_stem>) and str(<x11_data>).count("0x") + str(<x11_data>).count("0X") == ((int(<x11_width>) + 7) // 8) * int(<x11_height>)
where str(<x11h_width_stem>) == str(<x11h_height_stem>) and str(<x11h_width_stem>) == str(<x11h_x_hot_stem>) and str(<x11h_width_stem>) == str(<x11h_y_hot_stem>) and str(<x11h_width_stem>) == str(<x11h_array_stem>) and int(<x11h_x_hot>) >= 0 and int(<x11h_x_hot>) < int(<x11h_width>) and int(<x11h_y_hot>) >= 0 and int(<x11h_y_hot>) < int(<x11h_height>) and str(<x11h_data>).count("0x") + str(<x11h_data>).count("0X") == ((int(<x11h_width>) + 7) // 8) * int(<x11h_height>)
where str(<x10_width_stem>) == str(<x10_height_stem>) and str(<x10_width_stem>) == str(<x10_array_stem>) and str(<x10_data>).count("0x") + str(<x10_data>).count("0X") == ((int(<x10_width>) + 15) // 16) * int(<x10_height>)
where str(<x10h_width_stem>) == str(<x10h_height_stem>) and str(<x10h_width_stem>) == str(<x10h_x_hot_stem>) and str(<x10h_width_stem>) == str(<x10h_y_hot_stem>) and str(<x10h_width_stem>) == str(<x10h_array_stem>) and int(<x10h_x_hot>) >= 0 and int(<x10h_x_hot>) < int(<x10h_width>) and int(<x10h_y_hot>) >= 0 and int(<x10h_y_hot>) < int(<x10h_height>) and str(<x10h_data>).count("0x") + str(<x10h_data>).count("0X") == ((int(<x10h_width>) + 15) // 16) * int(<x10h_height>)

<x11_width_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x11_width_stem> "_width" <hspace1> <x11_width> <hspace> <eol>
<x11_height_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x11_height_stem> "_height" <hspace1> <x11_height> <hspace> <eol>
<x11_declaration> ::= <array_space> "static" <hspace1> <char_type> <hspace1> <x11_array_stem> "_bits" <hspace> "[" <hspace> "]" <hspace> "=" <array_space> "{" <array_space> <x11_data> <array_space> "}" <hspace> ";" <hspace> <eof_space>
<x11_data> ::= <hex_byte> (<element_separator> <hex_byte>)* <optional_trailing_comma>

<x11h_width_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x11h_width_stem> "_width" <hspace1> <x11h_width> <hspace> <eol>
<x11h_height_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x11h_height_stem> "_height" <hspace1> <x11h_height> <hspace> <eol>
<x11h_x_hot_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x11h_x_hot_stem> "_x_hot" <hspace1> <x11h_x_hot> <hspace> <eol>
<x11h_y_hot_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x11h_y_hot_stem> "_y_hot" <hspace1> <x11h_y_hot> <hspace> <eol>
<x11h_declaration> ::= <array_space> "static" <hspace1> <char_type> <hspace1> <x11h_array_stem> "_bits" <hspace> "[" <hspace> "]" <hspace> "=" <array_space> "{" <array_space> <x11h_data> <array_space> "}" <hspace> ";" <hspace> <eof_space>
<x11h_data> ::= <hex_byte> (<element_separator> <hex_byte>)* <optional_trailing_comma>

<x10_width_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x10_width_stem> "_width" <hspace1> <x10_width> <hspace> <eol>
<x10_height_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x10_height_stem> "_height" <hspace1> <x10_height> <hspace> <eol>
<x10_declaration> ::= <array_space> "static" <hspace1> <short_type> <hspace1> <x10_array_stem> "_bits" <hspace> "[" <hspace> "]" <hspace> "=" <array_space> "{" <array_space> <x10_data> <array_space> "}" <hspace> ";" <hspace> <eof_space>
<x10_data> ::= <hex_word> (<element_separator> <hex_word>)* <optional_trailing_comma>

<x10h_width_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x10h_width_stem> "_width" <hspace1> <x10h_width> <hspace> <eol>
<x10h_height_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x10h_height_stem> "_height" <hspace1> <x10h_height> <hspace> <eol>
<x10h_x_hot_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x10h_x_hot_stem> "_x_hot" <hspace1> <x10h_x_hot> <hspace> <eol>
<x10h_y_hot_define> ::= <hspace> "#" <hspace> "define" <hspace1> <x10h_y_hot_stem> "_y_hot" <hspace1> <x10h_y_hot> <hspace> <eol>
<x10h_declaration> ::= <array_space> "static" <hspace1> <short_type> <hspace1> <x10h_array_stem> "_bits" <hspace> "[" <hspace> "]" <hspace> "=" <array_space> "{" <array_space> <x10h_data> <array_space> "}" <hspace> ";" <hspace> <eof_space>
<x10h_data> ::= <hex_word> (<element_separator> <hex_word>)* <optional_trailing_comma>

<char_type> ::= "char" | "unsigned" <hspace1> "char"
<short_type> ::= "short" | "unsigned" <hspace1> "short"
<hex_byte> ::= <hex_prefix> <hex_digit> | <hex_prefix> <hex_digit> <hex_digit>
<hex_word> ::= <hex_prefix> <hex_digit> | <hex_prefix> <hex_digit> <hex_digit> | <hex_prefix> <hex_digit> <hex_digit> <hex_digit> | <hex_prefix> <hex_digit> <hex_digit> <hex_digit> <hex_digit>
<hex_prefix> ::= "0x" | "0X"
<hex_digit> ::= r'[0-9A-Fa-f]'
<element_separator> ::= <array_space> "," <array_space>
<optional_trailing_comma> ::= "" | <array_space> ","

<x11_width_stem> ::= <identifier>
<x11_height_stem> ::= <identifier>
<x11_array_stem> ::= <identifier>
<x11h_width_stem> ::= <identifier>
<x11h_height_stem> ::= <identifier>
<x11h_x_hot_stem> ::= <identifier>
<x11h_y_hot_stem> ::= <identifier>
<x11h_array_stem> ::= <identifier>
<x10_width_stem> ::= <identifier>
<x10_height_stem> ::= <identifier>
<x10_array_stem> ::= <identifier>
<x10h_width_stem> ::= <identifier>
<x10h_height_stem> ::= <identifier>
<x10h_x_hot_stem> ::= <identifier>
<x10h_y_hot_stem> ::= <identifier>
<x10h_array_stem> ::= <identifier>
<identifier> ::= r'[A-Za-z_][A-Za-z0-9_]*'

<x11_width> ::= <positive_uint32>
<x11_height> ::= <positive_uint32>
<x11h_width> ::= <positive_uint32>
<x11h_height> ::= <positive_uint32>
<x11h_x_hot> ::= <uint32>
<x11h_y_hot> ::= <uint32>
<x10_width> ::= <positive_uint32>
<x10_height> ::= <positive_uint32>
<x10h_width> ::= <positive_uint32>
<x10h_height> ::= <positive_uint32>
<x10h_x_hot> ::= <uint32>
<x10h_y_hot> ::= <uint32>
<positive_uint32> ::= r'[1-3]' | r'[4-6]' | r'[7-9]' | r'[1-9][0-9]{1,9}'
where int(<positive_uint32>) <= 4294967295
<uint32> ::= r'[0-2]' | r'[3-5]' | r'[6-9]' | r'[0-9]{2,10}'
where int(<uint32>) <= 4294967295

<hspace> ::= r'[ \t]*'
<hspace1> ::= r'[ \t]+'
<eol> ::= "\n" | "\r\n"
<array_space> ::= r'(?:[ \t\r\n]+|/\*[A-Za-z _-]*\*/)*'
<eof_space> ::= r'(?:[ \t\r\n]+|/\*[A-Za-z _-]*\*/)*'
