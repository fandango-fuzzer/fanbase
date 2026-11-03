# JSON texts (RFC 8259) at the edges of what parsers agree on: numbers past
# the precision of doubles and of 64-bit integers (2^53 + 1, -2^63 - 1, digits
# of arbitrary length), overflowing and underflowing exponents (1e400,
# 1e-400), the smallest subnormal and the largest double, -0 and 0e0; strings
# of up to 800 characters with every escape, surrogate pairs at the ends of
# their ranges, and lone surrogates (\uD800, \uDFFF), which are valid JSON but
# not valid UTF-16; objects with a repeated key; and runs of ten arrays, six
# objects or six of both around any value, so nesting goes as deep as Fandango
# takes it. White space may be between every token, or none.
#
# TODO:
# * Lone surrogates make some parsers (jq, Perl's JSON::PP) refuse a file and
#   others accept it: that is what they are for.

# One value, with white space around it or none
<start> ::= <ws> <value> <ws>

<value> ::= <object> | <array> | <string> | <number> | "true" | "false" | "null" | <deep_array> | <deep_object> | <deep_mixed> | <long_string>

# Objects; one kind of member is a key written twice
<object> ::= "{" <ws> "}" | "{" <ws> <members> <ws> "}"

<members> ::= <pair> | <pair> <ws> "," <ws> <members> | <dup_pair>

<pair> ::= <string> <ws> ":" <ws> <value>

<dup_pair> ::= '"__dup__"' <ws> ":" <ws> <value> <ws> "," <ws> '"__dup__"' <ws> ":" <ws> <value>

# Arrays
<array> ::= "[" <ws> "]" | "[" <ws> <elements> <ws> "]"

<elements> ::= <value> | <value> <ws> "," <ws> <elements>

# Strings: characters outside the surrogates, escapes, pairs of surrogates,
# and surrogates on their own; and strings of 200 to 800 characters
<string> ::= '"' <chars> '"'

<chars> ::= <char>*

<char> ::= <unescaped> | <simple_escape> | <unicode_escape> | <surrogate_pair_escape> | <lone_surrogate_escape>

<unescaped> ::= r'[\x20-\x21\x23-\x5B\x5D-\uD7FF\uE000-\U0010FFFF]'

<simple_escape> ::= "\\\"" | "\\\\" | "\\/" | "\\b" | "\\f" | "\\n" | "\\r" | "\\t"

<unicode_escape> ::= "\\u" <hex4>
<hex4> ::= <hex> <hex> <hex> <hex>
<hex> ::= r'[0-9a-fA-F]'

<surrogate_pair_escape> ::= "\\u" <high_surrogate_hex> "\\u" <low_surrogate_hex>
<high_surrogate_hex> ::= "D800" | "D83D" | "D9AB" | "DBFF"
<low_surrogate_hex> ::= "DC00" | "DE00" | "DD34" | "DFFF"

<lone_surrogate_escape> ::= "\\uD800" | "\\uDFFF" | "\\uD83D"

<long_string> ::= '"' <char>{200,800} '"'

# Numbers: the whole syntax, and values at the edges of doubles and integers
<number> ::= <generic_number> | <edge_number>

<generic_number> ::= <minus>? <int_part> <frac_part>? <exp_part>?

<minus> ::= "-"
<int_part> ::= "0" | <nonzero_digit> <digit>*
<nonzero_digit> ::= r'[1-9]'
<digit> ::= r'[0-9]'
<frac_part> ::= "." <digit>+
<exp_part> ::= <exp_e> <exp_sign>? <digit>+
<exp_e> ::= "e" | "E"
<exp_sign> ::= "+" | "-"

<edge_number> ::= "0" | "-0" | "-0.0" | "0.0" | "1e400" | "-1e400" | "1E+400" | "1e-400" | "123456789012345678901234567890123456789" | "-123456789012345678901234567890123456789" | "1.0000000000000000000000000000000001" | "9007199254740993" | "-9223372036854775809" | "1e0" | "0e0" | "5e-324" | "1.7976931348623157e308" | "0.000000000000000000001" | "1E5" | "10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

# Ten arrays, six objects, or both mixed, around any value
<deep_array> ::= "[[[[[[[[[[" <ws> <value> <ws> "]]]]]]]]]]"

<deep_object> ::= '{"k":{"k":{"k":{"k":{"k":{"k":' <ws> <value> <ws> '}}}}}}'

<deep_mixed> ::= '[{"a":[{"a":[{"a":' <ws> <value> <ws> '}]}]}]'

# White space, or none
<ws> ::= r'[ \t\n\r]+' | ""
