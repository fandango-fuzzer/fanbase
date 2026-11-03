# Same as cbor, at the edges of what is well-formed: heads longer than their
# argument needs (an argument of 0 in eight bytes); the largest arguments
# (2^64 - 1, and -2^64); strings of 0, 23, 24, 255 and 256 bytes, with lengths
# in one, two, four and eight bytes; strings, arrays and maps of indefinite
# length, closed by a break, and strings in chunks; text with the first and
# last code points of each UTF-8 length, U+FEFF and NUL; containers nested
# sixteen deep; every simple value there is (0 to 19, false, true, null,
# undefined, and 32 to 255 in two bytes); zeros, infinities, NaNs (quiet and
# signaling, with payloads), subnormals and the largest finite values of every
# float width; and tags with numbers of every width, the largest
# (2^64 - 1) included, tags on tags, and keys of every type.
#
# TODO:
# * Most of it is well-formed but not valid: unassigned tags and simple values,
#   map keys that repeat or are themselves arrays and maps.
# * The strings of fixed lengths are random bytes or ASCII.

<start> ::= <item>

<item> ::= <int> | <bstr> | <tstr> | <array> | <map> | <tagged> | <simple> | <float>

# Integers, major types 0 and 1: any argument in any head width, and the ends
<int> ::= rb'[\x00-\x17]' | rb'[\x20-\x37]' \
        | rb'[\x18\x38]' <byte> | rb'[\x19\x39]' <byte>{2} | rb'[\x1a\x3a]' <byte>{4} | rb'[\x1b\x3b]' <byte>{8} \
        | b'\x18\x00' | b'\x19\x00\x00' | b'\x1a\x00\x00\x00\x00' | b'\x1b\x00\x00\x00\x00\x00\x00\x00\x00' \
        | b'\x1b\xff\xff\xff\xff\xff\xff\xff\xff' | b'\x3b\xff\xff\xff\xff\xff\xff\xff\xff' \
        | b'\x17' | b'\x37' | b'\x18\x18' | b'\x38\x18' | b'\x19\x01\x00' | b'\x1a\x00\x01\x00\x00' \
        | b'\x1b\x00\x00\x00\x01\x00\x00\x00\x00'

# Byte strings of the lengths where the head changes width, in every width
<bstr> ::= b'\x40' | b'\x57' <byte>{23} | b'\x58\x18' <byte>{24} | b'\x58\xff' <byte>{255} \
         | b'\x59\x01\x00' <byte>{256} | b'\x58\x00' | b'\x59\x00\x00' | b'\x5a\x00\x00\x00\x00' \
         | b'\x5a\x00\x00\x01\x00' <byte>{256} | b'\x5b\x00\x00\x00\x00\x00\x00\x00\x01' <byte> \
         | b'\x5f' <bchunk>{0,4} b'\xff'
<bchunk> ::= b'\x40' | b'\x41' <byte> | b'\x44' <byte>{4} | b'\x58\x18' <byte>{24}

# Text strings likewise; and text at the edges of UTF-8
<tstr>  ::= b'\x60' | b'\x77' <ascii>{23} | b'\x78\x18' <ascii>{24} | b'\x78\xff' <ascii>{255} \
          | b'\x79\x01\x00' <ascii>{256} | b'\x7a\x00\x00\x00\x01' <ascii> \
          | b'\x7b\x00\x00\x00\x00\x00\x00\x00\x01' <ascii> | <tedge> \
          | b'\x7f' <tchunk>{0,4} b'\xff'
<tchunk> ::= b'\x60' | b'\x61' <ascii> | <tedge>
<tedge> ::= b'\x61\x00' | b'\x61\x7f' | b'\x62\xc2\x80' | b'\x62\xdf\xbf' | b'\x63\xe0\xa0\x80' \
          | b'\x63\xef\xbf\xbf' | b'\x63\xef\xbb\xbf' | b'\x63\xed\x9f\xbf' | b'\x63\xee\x80\x80' \
          | b'\x64\xf0\x90\x80\x80' | b'\x64\xf4\x8f\xbf\xbf'
<ascii> ::= rb'[\x20-\x7e]'

# Arrays and maps: empty, with counts in every head width, of indefinite
# length, and nested sixteen deep
<array> ::= b'\x80' | b'\x81' <item> | b'\x82' <item>{2} | b'\x97' <leaf>{23} | b'\x98\x18' <leaf>{24} \
          | b'\x98\x00' | b'\x99\x00\x01' <item> | b'\x9a\x00\x00\x00\x02' <item>{2} \
          | b'\x9b\x00\x00\x00\x00\x00\x00\x00\x01' <item> | b'\x9f' <item>{0,3} b'\xff' \
          | b'\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81\x81' <leaf>
<map>   ::= b'\xa0' | b'\xa1' <pair> | b'\xa2' <pair>{2} | b'\xb8\x00' | b'\xb9\x00\x01' <pair> \
          | b'\xba\x00\x00\x00\x01' <pair> | b'\xbb\x00\x00\x00\x00\x00\x00\x00\x01' <pair> \
          | b'\xbf' <pair>{0,3} b'\xff' | b'\xa2' <leaf> <item> <leaf> <item>
<pair>  ::= <item> <item>
<leaf>  ::= rb'[\x00-\x17]' | rb'[\x20-\x37]' | b'\x40' | b'\x60' | rb'[\xf4-\xf7]'

# Tags: numbers in every head width, the smallest and largest of each, and tags
# on tags
<tagged> ::= rb'[\xc0-\xd7]' <item> | b'\xd8' <byte> <item> | b'\xd9' <byte>{2} <item> \
           | b'\xda' <byte>{4} <item> | b'\xdb' <byte>{8} <item> | b'\xd8\x00' <item> \
           | b'\xdb\xff\xff\xff\xff\xff\xff\xff\xff' <item> | b'\xd9\xd9\xf7' <item> \
           | b'\xc6\xc7\xc8' <item>

# Simple values: 0 to 19 and the four that are named, in one byte, and 32 to
# 255 in two (below 32 in two bytes is not well-formed)
<simple> ::= rb'[\xe0-\xf7]' | b'\xf8' rb'[\x20-\xff]' | b'\xf8\x20' | b'\xf8\xff'

# Floats: any bits, and the values at the edges of each width
<float> ::= b'\xf9' <byte>{2} | b'\xfa' <byte>{4} | b'\xfb' <byte>{8} \
          | b'\xf9\x00\x00' | b'\xf9\x80\x00' | b'\xf9\x7c\x00' | b'\xf9\xfc\x00' | b'\xf9\x7e\x00' \
          | b'\xf9\x7c\x01' | b'\xf9\x00\x01' | b'\xf9\x03\xff' | b'\xf9\x7b\xff' \
          | b'\xfa\x7f\x80\x00\x00' | b'\xfa\x7f\xc0\x00\x00' | b'\xfa\x7f\x80\x00\x01' | b'\xfa\x00\x00\x00\x01' \
          | b'\xfa\x7f\x7f\xff\xff' | b'\xfb\x7f\xf0\x00\x00\x00\x00\x00\x00' | b'\xfb\x7f\xf8\x00\x00\x00\x00\x00\x01' \
          | b'\xfb\x00\x00\x00\x00\x00\x00\x00\x01' | b'\xfb\x7f\xef\xff\xff\xff\xff\xff\xff' \
          | b'\xfb\x80\x00\x00\x00\x00\x00\x00\x00'
