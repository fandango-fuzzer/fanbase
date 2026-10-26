# Same as rar, with the flags and values at the edges of what RAR 4 allows:
# main header flags for volumes, locked, solid and authenticated archives, new
# volume numbering and a recovery record; file header flags for passwords,
# solid files, extended times, Unicode names and directories; the host systems
# and decoder versions at both ends; and, after the file, a service block
# (CMT, RR, AV, ACL or STM) with its own data, the old comment block (0x75),
# the old sub block (0x77), and an end block that says another volume follows.
# Every header has its HEAD_SIZE and HEAD_CRC, and stored data its sizes and
# CRC-32, tied to the bytes by where constraints.
#
# TODO:
# * The flags are set on their own, so an archive can say it is a volume, or
#   that its file is encrypted, when nothing else in it agrees.
# * The data is always stored (method 0x30).

import zlib

# The service, comment and sub blocks are optional
<start> ::= ( <marker> <archive_header> <file_block>
             <service_block>? <old_comment_block>? <old_sub_block>? <end_block> )

<marker> ::= b'Rar!\x1a\x07\x00'

# Main header (0x73). Flags: 0x0001 volume, 0x0004 locked, 0x0008 solid,
# 0x0010 new volume numbering, 0x0020 authenticity information, 0x0100 first
# volume, 0x4000 encryption version
<archive_header> ::= <mh_crc> <mh_body>
<mh_crc>  ::= <byte> <byte>
<mh_body> ::= <mh_type> <mh_flags> <mh_size> <mh_reserved1> <mh_reserved2>
<mh_type> ::= b'\x73'
<mh_flags> ::= ( b'\x00\x00' | b'\x01\x00' | b'\x04\x00' | b'\x08\x00'
               | b'\x10\x00' | b'\x20\x00' | b'\x00\x01' | b'\x00\x40' )
<mh_size>  ::= <u16>
<mh_reserved1> ::= <u16> := b'\x00\x00'
<mh_reserved2> ::= <u32> := b'\x00\x00\x00\x00'

where bytes(<mh_size>) == (len(bytes(<mh_body>)) + 2).to_bytes(2, 'little')
where bytes(<mh_crc>) == (zlib.crc32(bytes(<mh_body>)) & 0xffff).to_bytes(2, 'little')

# File header (0x74), always with data after it (0x8000). Flags: 0x0004
# password, 0x0010 solid, 0x0100 extended time, 0x0200 Unicode name, 0x00E0
# directory. Host systems MS-DOS, Win32, Unix and BeOS; decoder versions
# 2.0, 2.9 and 3.6
<file_block> ::= <fh_crc> <fh_body> <file_data>
<fh_crc>  ::= <byte> <byte>
<fh_body> ::= ( <fh_type> <fh_flags> <fh_size> <fh_pack> <fh_unp> <fh_os>
                <fh_filecrc> <fh_time> <fh_ver> <fh_method> <fh_namesize>
                <fh_attr> <fh_name> )
<fh_type> ::= b'\x74'
<fh_flags> ::= ( b'\x00\x80' | b'\x10\x80' | b'\x00\x81' | b'\x00\x82'
               | b'\xe0\x80' | b'\x04\x80' )
<fh_size>  ::= <u16>
<fh_pack>  ::= <u32>
<fh_unp>   ::= <u32>
<fh_os>    ::= b'\x00' | b'\x02' | b'\x03' | b'\x05'
<fh_filecrc> ::= <u32>
<fh_time>  ::= <u32> := b'\x21\x21\x21\x21'
<fh_ver>   ::= b'\x14' | b'\x1d' | b'\x24'
<fh_method> ::= b'\x30'
<fh_namesize> ::= <u16>
<fh_attr>  ::= <u32> := b'\x20\x00\x00\x00'
<fh_name>  ::= <namechar>{1,24}
<namechar> ::= rb'[A-Za-z0-9._-]'
<file_data> ::= <byte>{0,20}

where bytes(<fh_pack>) == len(bytes(<file_data>)).to_bytes(4, 'little')
where bytes(<fh_unp>)  == len(bytes(<file_data>)).to_bytes(4, 'little')
where bytes(<fh_filecrc>) == (zlib.crc32(bytes(<file_data>)) & 0xffffffff).to_bytes(4, 'little')
where bytes(<fh_namesize>) == len(bytes(<fh_name>)).to_bytes(2, 'little')
where bytes(<fh_size>) == (len(bytes(<fh_body>)) + 2).to_bytes(2, 'little')
where bytes(<fh_crc>) == (zlib.crc32(bytes(<fh_body>)) & 0xffff).to_bytes(2, 'little')

# Service block (0x7a): a header like a file's, named after the service,
# with a few bytes of data
<service_block> ::= <sv_crc> <sv_body> <sv_data>
<sv_crc>  ::= <byte> <byte>
<sv_body> ::= ( <sv_type> <sv_flags> <sv_size> <sv_pack> <sv_unp> <sv_os>
                <sv_datacrc> <sv_time> <sv_ver> <sv_method> <sv_namesize>
                <sv_attr> <sv_name> )
<sv_type> ::= b'\x7a'
<sv_flags> ::= b'\x00\x80' | b'\x10\x80'
<sv_size>  ::= <u16>
<sv_pack>  ::= <u32>
<sv_unp>   ::= <u32>
<sv_os>    ::= b'\x03'
<sv_datacrc> ::= <u32>
<sv_time>  ::= <u32> := b'\x00\x00\x00\x00'
<sv_ver>   ::= b'\x1d'
<sv_method> ::= b'\x30'
<sv_namesize> ::= <u16>
<sv_attr>  ::= <u32> := b'\x00\x00\x00\x00'
<sv_name>  ::= b'CMT' | b'RR' | b'AV' | b'ACL' | b'STM'
<sv_data>  ::= <byte>{0,8}

where bytes(<sv_pack>) == len(bytes(<sv_data>)).to_bytes(4, 'little')
where bytes(<sv_unp>)  == len(bytes(<sv_data>)).to_bytes(4, 'little')
where bytes(<sv_datacrc>) == (zlib.crc32(bytes(<sv_data>)) & 0xffffffff).to_bytes(4, 'little')
where bytes(<sv_namesize>) == len(bytes(<sv_name>)).to_bytes(2, 'little')
where bytes(<sv_size>) == (len(bytes(<sv_body>)) + 2).to_bytes(2, 'little')
where bytes(<sv_crc>) == (zlib.crc32(bytes(<sv_body>)) & 0xffff).to_bytes(2, 'little')

# Old archive comment (0x75), as before RAR 3: a header and no data
<old_comment_block> ::= <oc_crc> <oc_body>
<oc_crc>  ::= <byte> <byte>
<oc_body> ::= <oc_type> <oc_flags> <oc_size> <oc_unp> <oc_ver> <oc_method> <oc_commcrc>
<oc_type> ::= b'\x75'
<oc_flags> ::= <u16> := b'\x00\x00'
<oc_size>  ::= <u16>
<oc_unp>   ::= <u16> := b'\x00\x00'
<oc_ver>   ::= b'\x1d'
<oc_method> ::= b'\x30'
<oc_commcrc> ::= <u16> := b'\x00\x00'

where bytes(<oc_size>) == (len(bytes(<oc_body>)) + 2).to_bytes(2, 'little')
where bytes(<oc_crc>) == (zlib.crc32(bytes(<oc_body>)) & 0xffff).to_bytes(2, 'little')

# Old sub block (0x77): the base header only
<old_sub_block> ::= <os_crc> <os_body>
<os_crc>  ::= <byte> <byte>
<os_body> ::= <os_type> <os_flags> <os_size>
<os_type> ::= b'\x77'
<os_flags> ::= <u16> := b'\x00\x00'
<os_size>  ::= <u16>

where bytes(<os_size>) == (len(bytes(<os_body>)) + 2).to_bytes(2, 'little')
where bytes(<os_crc>) == (zlib.crc32(bytes(<os_body>)) & 0xffff).to_bytes(2, 'little')

# End of archive (0x7b). Flags: 0x0001 another volume follows, 0x0004
# space reserved, 0x4000 not the last volume (old style)
<end_block> ::= <eb_crc> <eb_body>
<eb_crc>  ::= <byte> <byte>
<eb_body> ::= <eb_type> <eb_flags> <eb_size>
<eb_type> ::= b'\x7b'
<eb_flags> ::= b'\x00\x00' | b'\x01\x00' | b'\x04\x00' | b'\x00\x40'
<eb_size>  ::= <u16>

where bytes(<eb_size>) == (len(bytes(<eb_body>)) + 2).to_bytes(2, 'little')
where bytes(<eb_crc>) == (zlib.crc32(bytes(<eb_body>)) & 0xffff).to_bytes(2, 'little')

# Integers, little-endian
<u16> ::= <byte> <byte>
<u32> ::= <byte> <byte> <byte> <byte>
