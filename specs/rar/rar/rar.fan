# RAR 4 (the block format of RAR 1.5 to 4.x): the marker block, the main
# header, one stored file and its data, optional service blocks, and the end
# of archive block. Every block starts with HEAD_CRC, HEAD_TYPE, HEAD_FLAGS
# and HEAD_SIZE; HEAD_CRC is the low 16 bits of the CRC-32 of the header
# after it. The header sizes and CRCs, the packed and unpacked sizes, the
# length of the name and the CRC-32 of the file's data are tied to the bytes
# by where constraints. All fields are little-endian.
#
# TODO:
# * One file, stored (method 0x30): no compressed data, no solid archives,
#   no volumes, comments, recovery records or encryption.
# * The service blocks are bare headers, with no data area.

import zlib

<start> ::= <archive>

<archive> ::= <marker> <archive_header> <file_block> <extra_block>* <end_block>

# Marker block: HEAD_CRC 0x6152, HEAD_TYPE 0x72, HEAD_FLAGS 0x1a21, HEAD_SIZE 7
<marker> ::= b'Rar!\x1a\x07\x00'

# Main header (0x73): the base header and six reserved bytes, no flags
<archive_header> ::= <mh_crc> <mh_body>
<mh_body>        ::= <mh_type> <mh_flags> <mh_size> <mh_reserved1> <mh_reserved2>
<mh_crc>         ::= <byte>{2}
<mh_type>        ::= b'\x73'
<mh_flags>       ::= b'\x00\x00'
<mh_size>        ::= <byte>{2}
<mh_reserved1>   ::= b'\x00\x00'
<mh_reserved2>   ::= b'\x00\x00\x00\x00'

# File header (0x74), then PACK_SIZE bytes of data. Flags 0x8000: data
# follows the header. HOST_OS 0 to 5 (MS-DOS, OS/2, Windows, Unix, Mac OS,
# BeOS), UNP_VER 2.9, METHOD 0x30 (stored).
<file_block> ::= <fh_crc> <fh_body> <file_data>
<fh_body>    ::= <fh_type> <fh_flags> <fh_size> <pack_size> <unp_size> \
                 <host_os> <file_crc> <ftime> <unp_ver> <method> \
                 <name_size> <attr> <file_name>
<fh_crc>    ::= <byte>{2}
<fh_type>   ::= b'\x74'
<fh_flags>  ::= b'\x00\x80'
<fh_size>   ::= <byte>{2}
<pack_size> ::= <byte>{4}
<unp_size>  ::= <byte>{4}
<host_os>   ::= rb'[\x00-\x05]'
<file_crc>  ::= <byte>{4}
<ftime>     ::= <byte>{4}
<unp_ver>   ::= b'\x1d'
<method>    ::= b'\x30'
<name_size> ::= <byte>{2}
<attr>      ::= <byte>{4}
<file_name> ::= rb'[\x21-\x7e]{1,24}'
<file_data> ::= <byte>{1,64}

# Old style (0x77) and new style (0x7a) service blocks, seven bytes each:
# no data area, so a reader skips HEAD_SIZE bytes
<extra_block> ::= <sb_crc> <sb_body>
<sb_body>     ::= <sb_type> <sb_flags> <sb_size>
<sb_crc>      ::= <byte>{2}
<sb_type>     ::= b'\x77' | b'\x7a'
<sb_flags>    ::= b'\x00\x00'
<sb_size>     ::= <byte>{2}

# End of archive (0x7b), seven bytes, no flags
<end_block> ::= <eb_crc> <eb_body>
<eb_body>   ::= <eb_type> <eb_flags> <eb_size>
<eb_crc>    ::= <byte>{2}
<eb_type>   ::= b'\x7b'
<eb_flags>  ::= b'\x00\x00'
<eb_size>   ::= <byte>{2}

# HEAD_SIZE counts the whole header, HEAD_CRC included; HEAD_CRC covers what
# follows it, up to the end of the header.
where <mh_size> == (len(bytes(<mh_body>)) + 2).to_bytes(2, 'little')
where <mh_crc> == (zlib.crc32(bytes(<mh_body>)) & 0xffff).to_bytes(2, 'little')

# The file header's HEAD_SIZE does not count the data. A stored file packs to
# its own length, and FILE_CRC is the CRC-32 of the data.
where <fh_size> == (len(bytes(<fh_body>)) + 2).to_bytes(2, 'little')
where <pack_size> == len(bytes(<file_data>)).to_bytes(4, 'little')
where <unp_size>  == len(bytes(<file_data>)).to_bytes(4, 'little')
where <name_size> == len(bytes(<file_name>)).to_bytes(2, 'little')
where <file_crc> == (zlib.crc32(bytes(<file_data>)) & 0xffffffff).to_bytes(4, 'little')
where <fh_crc> == (zlib.crc32(bytes(<fh_body>)) & 0xffff).to_bytes(2, 'little')

where <sb_size> == (len(bytes(<sb_body>)) + 2).to_bytes(2, 'little')
where <sb_crc>  == (zlib.crc32(bytes(<sb_body>)) & 0xffff).to_bytes(2, 'little')

where <eb_size> == (len(bytes(<eb_body>)) + 2).to_bytes(2, 'little')
where <eb_crc>  == (zlib.crc32(bytes(<eb_body>)) & 0xffff).to_bytes(2, 'little')
