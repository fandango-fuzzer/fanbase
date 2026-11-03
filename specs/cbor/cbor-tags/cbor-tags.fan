# CBOR items built around the registered tags, each with content that is
# valid for it: date-times (0) with fractions of seconds and offsets from UTC,
# epoch times (1) as integers and floats, bignums (2, 3) of up to 16 bytes,
# decimal fractions and bigfloats (4, 5) with bignum mantissas, expected
# conversions (21 to 23), embedded CBOR (24), shared values and references to
# them (28, 29), rational numbers (30), URIs (32), base64url and base64 text
# (33, 34), regular expressions (35), MIME messages (36), UUIDs (37), IPv4 and
# IPv6 addresses (52, 54), days since the epoch and full dates (100, 1004),
# sets (258), network addresses and prefixes (260, 261), and the self-described
# CBOR prefix (55799). An item is one tagged value, an array of four, or a map
# of names to them. Every length is written out: there are no constraints.
#
# TODO:
# * The regular expressions, MIME messages and URIs come from short lists.
# * A set may hold the same number twice.

<start> ::= <tagged> | b'\x84' <tagged>{4} | b'\xa3' <name> <tagged> <name> <tagged> <name> <tagged>
<name>  ::= b'\x61' rb'[a-z]' | b'\x64' rb'[a-z]{4}'

<tagged> ::= <t_datetime> | <t_epoch> | <t_bignum> | <t_decimal> | <t_expected> | <t_cbor> \
           | <t_shared> | <t_rational> | <t_uri> | <t_base64> | <t_regex> | <t_mime> | <t_uuid> \
           | <t_ip> | <t_days> | <t_date> | <t_set> | <t_netaddr> | <t_prefix> | <t_self>

# Integers small enough for any tag that takes one
<small> ::= rb'[\x00-\x17]' | b'\x18' rb'[\x18-\xff]' | b'\x19' rb'[\x01-\x7f]' <byte>
<neg>   ::= rb'[\x20-\x37]' | b'\x38' rb'[\x18-\xff]'

# 0: RFC 3339 date-times of 20, 24, 25 and 29 characters
<t_datetime> ::= b'\xc0\x74' <date> b'T' <time> b'Z' \
               | b'\xc0\x78\x18' <date> b'T' <time> b'.' rb'[0-9]{3}' b'Z' \
               | b'\xc0\x78\x19' <date> b'T' <time> <offset> \
               | b'\xc0\x78\x1d' <date> b'T' <time> b'.' rb'[0-9]{3}' <offset>
<date>   ::= rb'(19|20)[0-9]{2}' b'-' rb'0[1-9]|1[0-2]' b'-' rb'0[1-9]|1[0-9]|2[0-8]'
<time>   ::= rb'[01][0-9]|2[0-3]' b':' rb'[0-5][0-9]' b':' rb'[0-5][0-9]'
<offset> ::= rb'[+-]' rb'0[0-9]|1[0-3]' b':' rb'00|15|30|45'

# 1: seconds since the epoch: integers of up to 32 bits, negative ones, and
# floats with a fraction
<t_epoch> ::= b'\xc1' <small> | b'\xc1\x1a' rb'[\x00-\x7f]' <byte>{3} | b'\xc1' <neg> \
            | b'\xc1\xfb\x41\xd4\x52\xd9\xec\x20\x00\x00' | b'\xc1\xf9\x3c\x00' | b'\xc1\xfa\x47\xc3\x50\x00'

# 2 and 3: bignums, a byte string of the magnitude
<t_bignum>  ::= rb'[\xc2\xc3]' <magnitude>
<magnitude> ::= b'\x40' | b'\x41' <byte> | b'\x42' <byte>{2} | b'\x48' <byte>{8} | b'\x49' <byte>{9} \
              | b'\x50' <byte>{16} | b'\x49\x01' b'\x00'{8}

# 4 and 5: [exponent, mantissa], the mantissa an integer or a bignum
<t_decimal> ::= rb'[\xc4\xc5]' b'\x82' (<small> | <neg>) (<small> | <neg> | <t_bignum>)

# 21, 22 and 23 on byte strings
<t_expected> ::= rb'[\xd5\xd6\xd7]' <magnitude>

# 24: a byte string that holds one encoded item, its length written out
<t_cbor> ::= b'\xd8\x18' ( b'\x41' rb'[\x00-\x17\x20-\x37\xf4-\xf7]' | b'\x42\x18' rb'[\x18-\xff]' \
                         | b'\x43\x19' <byte>{2} | b'\x45\x1a' <byte>{4} | b'\x43\xf9' <byte>{2} \
                         | b'\x43\x82' <small1> <small1> | b'\x42\x61' rb'[a-z]' )
<small1> ::= rb'[\x00-\x17]'

# 28 and 29: a value marked as shared, and a reference to it (the first shared
# value is number 0)
<t_shared> ::= b'\x82\xd8\x1c' (<small> | <name> | b'\x82' <small> <small>) b'\xd8\x1d\x00'

# 30: [numerator, denominator], the denominator positive
<t_rational> ::= b'\xd8\x1e\x82' (<small> | <neg> | <t_bignum>) (rb'[\x01-\x17]' | b'\x18' rb'[\x18-\xff]' | b'\x19' rb'[\x01-\xff]' <byte>)

# 32: URIs
<t_uri> ::= b'\xd8\x20' ( b'\x73https://example.org' | b'\x78\x1bhttps://example.org/a?b=c#d' \
                        | b'\x6emailto:a@b.org' | b'\x70urn:isbn:0451450' | b'\x70file:///etc/host' \
                        | b'\x6chttp://[::1]' )

# 33 and 34: base64url text without padding, and base64 text with it
<t_base64> ::= b'\xd8\x21' (b'\x64' <b64u>{4} | b'\x68' <b64u>{8} | b'\x66' <b64u>{6}) \
             | b'\xd8\x22' (b'\x64' <b64>{4} | b'\x68' <b64>{8} | b'\x64' <b64>{2} b'==' | b'\x68' <b64>{7} b'=')
<b64u> ::= rb'[A-Za-z0-9_-]'
<b64>  ::= rb'[A-Za-z0-9+/]'

# 35: regular expressions
<t_regex> ::= b'\xd8\x23' ( b'\x61a' | b'\x64a+b*' | b'\x6a[a-z]{2,3}' | b'\x66(x|y)?' | b'\x63^.$' \
                          | b'\x68\\d+\\.\\d*' | b'\x67(?i)abc' )

# 36: MIME messages
<t_mime> ::= b'\xd8\x24' ( b'\x60' | b'\x78\x1eContent-Type: text/plain\r\n\r\nhi' \
                         | b'\x78\x20Subject: test\r\nFrom: a@b.org\r\n\r\n' )

# 37: UUIDs, version 4 and any
<t_uuid> ::= b'\xd8\x25\x50' <byte>{6} rb'[\x40-\x4f]' <byte> rb'[\x80-\xbf]' <byte>{7} | b'\xd8\x25\x50' <byte>{16}

# 52 and 54: IPv4 and IPv6 addresses
<t_ip> ::= b'\xd8\x34\x44' <byte>{4} | b'\xd8\x36\x50' <byte>{16}

# 100: days since 1970-01-01; 1004: a full date
<t_days> ::= b'\xd8\x64' (<small> | <neg>)
<t_date> ::= b'\xd9\x03\xec\x6a' <date>

# 258: a set of numbers and names
<t_set> ::= b'\xd9\x01\x02' (b'\x80' | b'\x81' <small> | b'\x82' <small> <name> | b'\x83' <small1> <name> <neg>)

# 260: an address, IPv4 (4 bytes), MAC (6) or IPv6 (16); 261: a prefix, a map
# of an address to its length in bits
<t_netaddr> ::= b'\xd9\x01\x04' (b'\x44' <byte>{4} | b'\x46' <byte>{6} | b'\x50' <byte>{16})
<t_prefix>  ::= b'\xd9\x01\x05\xa1\x44' <byte>{4} (rb'[\x00-\x17]' | b'\x18' rb'[\x18-\x20]')

# 55799: self-described CBOR
<t_self> ::= b'\xd9\xd9\xf7' (<t_datetime> | <t_bignum> | <t_uuid> | <small>)
