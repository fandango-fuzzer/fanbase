# ZIP archives of three stored entries whose fields sit at the edges of what
# the format allows. The first, LEGACY.TXT, is an MS-DOS 8.3 name dated
# 1980-01-01, needing version 1.0, with an extended timestamp whose access
# time is 0x7fffffff (January 2038), and Unix and DOS attributes at once. The
# second is a directory with a non-ASCII UTF-8 name (general purpose bit 11),
# the latest DOS date and time there are, and an Info-ZIP Unix extra field
# with uid 0xffffffff. The third, payload.bin, is made by Unix version 0, is
# world-writable, and holds 4 to 40 random bytes. The archive has a comment.
#
# TODO:
# * The first two entries, and every header field but the third entry's CRC-32
#   and sizes, are fixed bytes: what varies is the third entry's data (and the
#   offset of the central directory that follows it).
# * All entries are stored; no deflate, ZIP64 or data descriptors.

import zlib

<start> ::= <local0> <local1> <local2> <central0> <central1> <central2> <eocd>

# Integers are little-endian
<byte> ::= rb'(?s).'
<u32>  ::= <byte> <byte> <byte> <byte>

# Entry 0, LEGACY.TXT: local header, extra field and 32 bytes of text
<local0> ::= (
    b'\x50\x4b\x03\x04\x0a\x00\x00\x00\x00\x00\x00\x00\x21\x00\x27\x31'
    b'\x12\xed\x20\x00\x00\x00\x20\x00\x00\x00\x0a\x00\x0d\x00\x4c\x45'
    b'\x47\x41\x43\x59\x2e\x54\x58\x54\x55\x54\x09\x00\x03\x00\x00\x00'
    b'\x00\xff\xff\xff\x7f\x4d\x53\x2d\x44\x4f\x53\x20\x38\x2e\x33\x20'
    b'\x6c\x65\x67\x61\x63\x79\x20\x73\x74\x6f\x72\x65\x64\x20\x65\x6e'
    b'\x74\x72\x79\x0d\x0a' )

# Entry 1, the UTF-8 directory: local header and Unix extra field, no data
<local1> ::= (
    b'\x50\x4b\x03\x04\x0a\x00\x00\x08\x00\x00\x7d\xbf\x9f\xff\x00\x00'
    b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x09\x00\x0f\x00\x77\x65'
    b'\x69\x72\x64\xe2\x98\x83\x2f\x75\x78\x0b\x00\x01\x04\xff\xff\xff'
    b'\xff\x04\x00\x00\x00\x00' )

# Entry 2, payload.bin: the only entry whose data varies
<local2> ::= (
    b'\x50\x4b\x03\x04\x0a\x00\x00\x00\x00\x00\x00\x00\x21\x00'
    <crc2> <csize2> <usize2>
    b'\x0b\x00\x00\x00\x70\x61\x79\x6c\x6f\x61\x64\x2e\x62\x69\x6e'
    <data2> )

<data2>  ::= <byte>{4,40}
<crc2>   ::= <u32>
<csize2> ::= <u32>
<usize2> ::= <u32>

# The central directory records of entries 0 and 1
<central0> ::= (
    b'\x50\x4b\x01\x02\x1e\x03\x0a\x00\x00\x00\x00\x00\x00\x00\x21\x00'
    b'\x27\x31\x12\xed\x20\x00\x00\x00\x20\x00\x00\x00\x0a\x00\x09\x00'
    b'\x06\x00\x00\x00\x01\x00\x20\x00\xa4\x81\x00\x00\x00\x00\x4c\x45'
    b'\x47\x41\x43\x59\x2e\x54\x58\x54\x55\x54\x05\x00\x03\x00\x00\x00'
    b'\x00\x6c\x65\x67\x61\x63\x79' )

<central1> ::= (
    b'\x50\x4b\x01\x02\x14\x03\x0a\x00\x00\x08\x00\x00\x7d\xbf\x9f\xff'
    b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x09\x00\x0f\x00'
    b'\x00\x00\x00\x00\x00\x00\x10\x00\xed\x41\x55\x00\x00\x00\x77\x65'
    b'\x69\x72\x64\xe2\x98\x83\x2f\x75\x78\x0b\x00\x01\x04\xff\xff\xff'
    b'\xff\x04\x00\x00\x00\x00' )

# The record of entry 2 repeats its CRC-32 and sizes; its local header
# is at offset 139
<central2> ::= (
    b'\x50\x4b\x01\x02\x00\x03\x0a\x00\x00\x00\x00\x00\x00\x00\x21\x00'
    <ccrc2> <ccsize2> <cusize2>
    b'\x0b\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\x81'
    b'\x8b\x00\x00\x00'
    b'\x70\x61\x79\x6c\x6f\x61\x64\x2e\x62\x69\x6e' )

<ccrc2>   ::= <u32>
<ccsize2> ::= <u32>
<cusize2> ::= <u32>

# End of central directory: three entries, a central directory of 198
# bytes, and a comment of 25
<eocd> ::= (
    b'\x50\x4b\x05\x06\x00\x00\x00\x00\x03\x00\x03\x00\xc6\x00\x00\x00'
    <cd_off>
    b'\x19\x00\x5a\x49\x50\x20\x65\x78\x74\x72\x65\x6d\x65\x73\x20\x66'
    b'\x75\x7a\x7a\x20\x61\x72\x63\x68\x69\x76\x65' )

<cd_off> ::= <u32>

where <crc2>    == int.to_bytes(zlib.crc32(bytes(<data2>)) & 0xffffffff, 4, 'little')
where <csize2>  == int.to_bytes(len(bytes(<data2>)), 4, 'little')
where <usize2>  == int.to_bytes(len(bytes(<data2>)), 4, 'little')
where <ccrc2>   == int.to_bytes(zlib.crc32(bytes(<data2>)) & 0xffffffff, 4, 'little')
where <ccsize2> == int.to_bytes(len(bytes(<data2>)), 4, 'little')
where <cusize2> == int.to_bytes(len(bytes(<data2>)), 4, 'little')
where <cd_off>  == int.to_bytes(180 + len(bytes(<data2>)), 4, 'little')
