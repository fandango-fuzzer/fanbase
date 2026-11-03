# CBOR (RFC 8949): one data item, in preferred serialization (every head as
# short as its argument allows), of any of the major types: unsigned and
# negative integers, byte strings, UTF-8 text strings, arrays and maps of
# items, tagged items, the simple values false, true, null and undefined, and
# half-, single- and double-precision floats. The tags are among the common
# ones: date-time strings (0) and epoch times (1), bignums (2, 3), decimal
# fractions (4) and bigfloats (5), expected conversions (21 to 23), embedded
# CBOR (24), URIs (32), UUIDs (37) and the self-described CBOR prefix (55799).
# The head of a string is tied to its length in bytes by where constraints;
# arrays and maps have one alternative per number of elements.
#
# TODO:
# * Map keys can repeat (small integers do), which makes a map well-formed but
#   not valid.
# * Floats are any bit pattern of their width, so some could be written
#   shorter than they are.

<start> ::= <array> | <map> | <item>

<item> ::= <uint> | <nint> | <bstr> | <tstr> | <array> | <map> | <tagged> | <simple> | <float>

# The argument of a head after the first byte, at least as large as needs it:
# 24 or more in one byte, 256 or more in two, and so on
<arg1> ::= rb'[\x18-\xff]'
<arg2> ::= rb'[\x01-\xff]' <byte>
<arg4> ::= <nz2> <byte>{2}
<arg8> ::= <nz4> <byte>{4}
<nz2>  ::= rb'[\x01-\xff]' <byte> | b'\x00' rb'[\x01-\xff]'
<nz3>  ::= rb'[\x01-\xff]' <byte>{2} | b'\x00' <nz2>
<nz4>  ::= rb'[\x01-\xff]' <byte>{3} | b'\x00' <nz3>

# Major type 0, unsigned integers, and 1, negative ones (-1 - argument)
<uint> ::= rb'[\x00-\x17]' | b'\x18' <arg1> | b'\x19' <arg2> | b'\x1a' <arg4> | b'\x1b' <arg8>
<nint> ::= rb'[\x20-\x37]' | b'\x38' <arg1> | b'\x39' <arg2> | b'\x3a' <arg4> | b'\x3b' <arg8>

# Major type 2, byte strings: up to 23 bytes with the length in the first
# byte, 24 to 64 with it in the next
<bstr>       ::= <bstr_short> | <bstr_long>
<bstr_short> ::= <bs_head> <bs_data>
<bs_head>    ::= <byte>
<bs_data>    ::= <byte>{0,23}
<bstr_long>  ::= b'\x58' <bl_len> <bl_data>
<bl_len>     ::= <byte>
<bl_data>    ::= <byte>{24,64}

# Major type 3, text strings: UTF-8, characters of one to four bytes
<tstr>       ::= <tstr_short> | <tstr_long>
<tstr_short> ::= <ts_head> <ts_text>
<ts_head>    ::= <byte>
<ts_text>    ::= <tchar>{0,5}
<tstr_long>  ::= b'\x78' <tl_len> <tl_text>
<tl_len>     ::= <byte>
<tl_text>    ::= <ascii>{24} <tchar>{0,30}

<tchar> ::= <ascii> | <utf8_2> | <utf8_3> | <utf8_4>
<ascii> ::= rb'[\x20-\x7e]'
<utf8_2> ::= rb'[\xc2-\xdf]' <cont>
<utf8_3> ::= b'\xe2' <cont> <cont> | rb'[\xe4-\xe9]' <cont> <cont>
<utf8_4> ::= b'\xf0' rb'[\x90-\xbf]' <cont> <cont>
<cont>   ::= rb'[\x80-\xbf]'

# Major type 4, arrays, and 5, maps: the count is the number of elements (of
# pairs, for a map)
<array> ::= b'\x80' | b'\x81' <item> | b'\x82' <item>{2} | b'\x83' <item>{3} \
          | b'\x84' <item>{4} | b'\x85' <item>{5} | b'\x98\x18' <atom>{24}
<map>   ::= b'\xa0' | b'\xa1' <pair> | b'\xa2' <pair>{2} | b'\xa3' <pair>{3} | b'\xa4' <pair>{4}
<pair>  ::= <tstr> <item> | <uint> <item>

# Items that hold no other item
<atom> ::= <uint> | <nint> | <bstr> | <tstr> | <simple> | <float>

# Major type 6, tags
<tagged> ::= <tag_datetime> | <tag_epoch> | <tag_bignum> | <tag_decimal> | <tag_expected> \
           | <tag_cbor> | <tag_uri> | <tag_uuid> | <tag_self>

# 0: an RFC 3339 date-time, 20 characters
<tag_datetime> ::= b'\xc0\x74' <year> b'-' <month> b'-' <day> b'T' <hour> b':' <sixty> b':' <sixty> b'Z'
<year>  ::= rb'(19|20)[0-9]{2}'
<month> ::= rb'0[1-9]|1[0-2]'
<day>   ::= rb'0[1-9]|1[0-9]|2[0-8]'
<hour>  ::= rb'[01][0-9]|2[0-3]'
<sixty> ::= rb'[0-5][0-9]'

# 1: seconds since the epoch, as an integer of up to 32 bits
<tag_epoch> ::= b'\xc1' (rb'[\x00-\x17]' | b'\x18' <arg1> | b'\x19' <arg2> | b'\x1a' <arg4>)

# 2 and 3: positive and negative bignums, whose content is a byte string
<tag_bignum> ::= rb'[\xc2\xc3]' <bstr>

# 4 and 5: decimal fractions and bigfloats, an array of an exponent and a
# mantissa
<tag_decimal> ::= rb'[\xc4\xc5]' b'\x82' (rb'[\x00-\x17]' | rb'[\x20-\x37]') (<uint> | <nint>)

# 21, 22 and 23: the content is expected to be written as base64url, base64 or
# base16 when it is turned into JSON
<tag_expected> ::= rb'[\xd5\xd6\xd7]' <item>

# 24: embedded CBOR, a byte string that holds one encoded item
<tag_cbor>  ::= b'\xd8\x18' <emb_head> <emb_item>
<emb_head>  ::= <byte>
<emb_item>  ::= <uint> | <nint> | <simple> | <float>

# 32: a URI, as a text string
<tag_uri>  ::= b'\xd8\x20' <uri_head> <uri>
<uri_head> ::= <byte>
<uri>      ::= rb'https?://' rb'[a-z]{1,8}' rb'\.(org|net|com)' rb'(/[a-z0-9]{0,4})?'

# 37: a UUID, 16 bytes
<tag_uuid> ::= b'\xd8\x25\x50' <byte>{16}

# 55799: self-described CBOR, the prefix d9 d9 f7
<tag_self> ::= b'\xd9\xd9\xf7' <item>

# Major type 7: false, true, null, undefined, and floats of 16, 32 and 64 bits
<simple> ::= b'\xf4' | b'\xf5' | b'\xf6' | b'\xf7'
<float>  ::= b'\xf9' <byte>{2} | b'\xfa' <byte>{4} | b'\xfb' <byte>{8}

# A string's head is its major type and its length in bytes; so is the head of
# the byte string around embedded CBOR, and of a URI
where forall <s> in <bstr_short>: bytes(<s>.<bs_head>) == bytes([0x40 + len(bytes(<s>.<bs_data>))])
where forall <s> in <bstr_long>: bytes(<s>.<bl_len>) == bytes([len(bytes(<s>.<bl_data>))])
where forall <s> in <tstr_short>: bytes(<s>.<ts_head>) == bytes([0x60 + len(bytes(<s>.<ts_text>))])
where forall <s> in <tstr_long>: bytes(<s>.<tl_len>) == bytes([len(bytes(<s>.<tl_text>))])
where forall <t> in <tag_cbor>: bytes(<t>.<emb_head>) == bytes([0x40 + len(bytes(<t>.<emb_item>))])
where forall <t> in <tag_uri>: bytes(<t>.<uri_head>) == bytes([0x60 + len(bytes(<t>.<uri>))])
