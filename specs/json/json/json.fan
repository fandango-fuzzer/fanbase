# JSON texts (RFC 8259): one value with white space around it, an object, an
# array or a scalar. Objects of up to four members and arrays of up to five
# elements nest up to three levels, with the levels written out one by one;
# another branch nests twelve deep. Strings are short or long, with characters
# from ASCII and every Unicode plane, the escapes of RFC 8259 and surrogate
# pairs; numbers are integers, fractions and exponents, and values at the
# edges (-0, 1e-999999, 1E+999999, twenty fraction digits, a negative integer
# of 64 digits). Some documents put every kind of value side by side, empty
# names, escaped names and white space between every token. Comments, trailing
# commas, NaN, Infinity and single quotes are left out, as they are not JSON.
#
# TODO:
# * Containers nest only as deep as the rules are written out (three levels,
#   or twelve along one branch).

# A JSON text: one value, and white space around it
<start> ::= <json_text>
<json_text> ::= <ws> <document> <ws>
<document> ::= <value3> | <deep_value12> | <unusual_document>

# Values, objects and arrays, by how many levels may still be nested in them
<value3> ::= <scalar> | <object3> | <array3>
<value2> ::= <scalar> | <object2> | <array2>
<value1> ::= <scalar> | <object1> | <array1>
<value0> ::= <scalar>
<scalar> ::= <string> | <number> | "true" | "false" | "null"

<object3> ::= "{" <ws> "}" | "{" <ws> <member3> (<ws> "," <ws> <member3>){0,3} <ws> "}"
<member3> ::= <string> <ws> ":" <ws> <value2>
<array3> ::= "[" <ws> "]" | "[" <ws> <value2> (<ws> "," <ws> <value2>){0,4} <ws> "]"

<object2> ::= "{" <ws> "}" | "{" <ws> <member2> (<ws> "," <ws> <member2>){0,3} <ws> "}"
<member2> ::= <string> <ws> ":" <ws> <value1>
<array2> ::= "[" <ws> "]" | "[" <ws> <value1> (<ws> "," <ws> <value1>){0,4} <ws> "]"

<object1> ::= "{" <ws> "}" | "{" <ws> <member1> (<ws> "," <ws> <member1>){0,3} <ws> "}"
<member1> ::= <string> <ws> ":" <ws> <value0>
<array1> ::= "[" <ws> "]" | "[" <ws> <value0> (<ws> "," <ws> <value0>){0,4} <ws> "]"

# Strings: no raw control characters, quotation marks or reverse solidi;
# escapes, and surrogate pairs, for the rest
<string> ::= <short_string> | <long_string> | <all_escapes_string>
<short_string> ::= "\"" <string_char>{0,24} "\""
<long_string> ::= "\"" <string_char>{32,64} "\""
<all_escapes_string> ::= "\"" "\\\"" "\\\\" "\\/" "\\b" "\\f" "\\n" "\\r" "\\t" "\\u0000" "\\u001F" "\\uD834\\uDD1E" "\""
<string_char> ::= <unescaped_ascii> | <unescaped_unicode> | <escape>
<unescaped_ascii> ::= r'[\x20-\x21\x23-\x5B\x5D-\x7E]'
<unescaped_unicode> ::= r'[\u0080-\u07FF]' | r'[\u0800-\uD7FF]' | r'[\uE000-\uFFFF]' | r'[\U00010000-\U0010FFFF]'
<escape> ::= <simple_escape> | <unicode_escape>
<simple_escape> ::= "\\\"" | "\\\\" | "\\/" | "\\b" | "\\f" | "\\n" | "\\r" | "\\t"
<unicode_escape> ::= "\\u" <bmp_code_unit> | "\\u" <high_surrogate> "\\u" <low_surrogate>
<bmp_code_unit> ::= r'[0-9A-Ca-cE-Fe-f][0-9A-Fa-f]{3}' | r'[Dd][0-7][0-9A-Fa-f]{2}'
<high_surrogate> ::= r'[Dd][89AaBb][0-9A-Fa-f]{2}'
<low_surrogate> ::= r'[Dd][CcDdEeFf][0-9A-Fa-f]{2}'

# Numbers: the whole syntax, and values at its edges
<number> ::= <regular_number> | <edge_number>
<regular_number> ::= <minus>? <integer> <fraction>? <exponent>?
<minus> ::= "-"
<integer> ::= "0" | <nonzero_digit> <digit>{0,19}
<fraction> ::= "." <digit>{1,20}
<exponent> ::= <exponent_marker> <exponent_sign>? <digit>{1,6}
<exponent_marker> ::= "e" | "E"
<exponent_sign> ::= "+" | "-"
<digit> ::= r'[0-9]'
<nonzero_digit> ::= r'[1-9]'
<edge_number> ::= "0" | "-0" | "0.0" | "-0.0" | "1e0" | "1E+0" | "1e-999999" | "1E+999999" | "0.00000000000000000001" | "-9999999999999999999999999999999999999999999999999999999999999999"

# Twelve levels, an array or an object at each
<deep_value12> ::= "[" <ws> <deep_value11> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <deep_value11> <ws> "}"
<deep_value11> ::= "[" <ws> <deep_value10> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <deep_value10> <ws> "}"
<deep_value10> ::= "[" <ws> <deep_value9> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <deep_value9> <ws> "}"
<deep_value9> ::= "[" <ws> <deep_value8> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <deep_value8> <ws> "}"
<deep_value8> ::= "[" <ws> <deep_value7> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <deep_value7> <ws> "}"
<deep_value7> ::= "[" <ws> <deep_value6> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <deep_value6> <ws> "}"
<deep_value6> ::= "[" <ws> <deep_value5> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <deep_value5> <ws> "}"
<deep_value5> ::= "[" <ws> <deep_value4> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <deep_value4> <ws> "}"
<deep_value4> ::= "[" <ws> <deep_value3> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <deep_value3> <ws> "}"
<deep_value3> ::= "[" <ws> <deep_value2> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <deep_value2> <ws> "}"
<deep_value2> ::= "[" <ws> <deep_value1> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <deep_value1> <ws> "}"
<deep_value1> ::= "[" <ws> <scalar> <ws> "]" | "{" <ws> <string> <ws> ":" <ws> <scalar> <ws> "}"

# Every kind of scalar in one array, empty and escaped names, Unicode,
# empty containers inside each other, and white space between every token
<unusual_document> ::= <heterogeneous_array> | <edge_object> | <whitespace_document>
<heterogeneous_array> ::= "[" <ws> "null" <ws> "," <ws> "true" <ws> "," <ws> "false" <ws> "," <ws> <edge_number> <ws> "," <ws> <all_escapes_string> <ws> "," <ws> "[]" <ws> "," <ws> "{}" <ws> "]"
<edge_object> ::= "{" <ws> "\"\"" <ws> ":" <ws> "\"\"" <ws> "," <ws> "\"\\u0000\"" <ws> ":" <ws> <edge_number> <ws> "," <ws> "\"\\uD834\\uDD1E\"" <ws> ":" <ws> "[" <ws> "{}" <ws> "," <ws> "[]" <ws> "]" <ws> "}"
<whitespace_document> ::= "{" "\r\n\t " "\"spaced\"" " " ":" "\t" "[" "\n" "-0" "\r" "," " " "1E+999999" "\n" "]" "\r\n" "}"

# The four white space characters of JSON
<ws> ::= r'[\x20\x09\x0A\x0D]{0,4}'
