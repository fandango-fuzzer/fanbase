# cpio archives as cpio writes them to a device: one to three entries and the
# trailer, in odc, newc, crc or old binary format (both byte orders), filled
# with zeros to a whole 512-byte block. Every entry is a regular file with a
# name of one character and one byte of data; the inode, owner, group, time
# and device fields vary. The name and file sizes, the padding and the
# checksum of the crc format are tied to the bytes by where constraints.
#
# TODO:
# * Every name is one character and every file one byte long, and the crc
#   entries always hold "A".

# One archive and the zeros that fill its last block: each format has
# one, two or three entries, and the length of the fill for each
<start> ::= <odc_file> | <newc_file> | <crc_file> | <binary_file>

<odc_file> ::= <odc_archive_1> <odc_pad_346> | <odc_archive_2> <odc_pad_267> | <odc_archive_3> <odc_pad_188>
<odc_pad_346> ::= r'\x00{346}'
<odc_pad_267> ::= r'\x00{267}'
<odc_pad_188> ::= r'\x00{188}'

<newc_file> ::= <newc_archive_1> <newc_pad_272> | <newc_archive_2> <newc_pad_156> | <newc_archive_3> <newc_pad_40>
<newc_pad_272> ::= r'\x00{272}'
<newc_pad_156> ::= r'\x00{156}'
<newc_pad_40> ::= r'\x00{40}'

<crc_file> ::= <crc_archive_1> <newc_pad_272> | <crc_archive_2> <newc_pad_156> | <crc_archive_3> <newc_pad_40>

# Portable ASCII (odc, 070707): octal fields, no padding
<odc_archive_1> ::= <odc_entry> <odc_trailer>
<odc_archive_2> ::= <odc_entry> <odc_entry> <odc_trailer>
<odc_archive_3> ::= <odc_entry> <odc_entry> <odc_entry> <odc_trailer>
<odc_entry> ::= <odc_header> <odc_pathname> <odc_file_data>
where int(str(<odc_namesize>), 8) == len(str(<odc_pathname>)) and int(str(<odc_filesize>), 8) == len(str(<odc_file_data>))
<odc_header> ::= <odc_magic> <odc_dev> <odc_ino> <odc_mode> <odc_uid> <odc_gid> <odc_nlink> <odc_rdev> <odc_mtime> <odc_namesize> <odc_filesize>
<odc_magic> ::= "070707"
<odc_dev> ::= r'[0-7]{6}'
<odc_ino> ::= r'[0-7]{5}[1-7]'
<odc_mode> ::= r'10[0-7]{4}'
<odc_uid> ::= r'[0-7]{6}'
<odc_gid> ::= r'[0-7]{6}'
<odc_nlink> ::= "000001"
<odc_rdev> ::= r'[0-7]{6}'
<odc_mtime> ::= r'[0-7]{11}'
<odc_namesize> ::= "000002"
<odc_filesize> ::= "00000000001"
<odc_pathname> ::= <portable_name_char> "\x00"
<odc_file_data> ::= <portable_data>
<odc_trailer> ::= "070707" "000000" "000000" "000000" "000000" "000000" "000001" "000000" "00000000000" "000013" "00000000000" "TRAILER!!!\x00"

# New ASCII (newc, 070701): hexadecimal fields, the name and the data
# padded to four bytes, check 0
<newc_archive_1> ::= <newc_entry> <newc_trailer>
<newc_archive_2> ::= <newc_entry> <newc_entry> <newc_trailer>
<newc_archive_3> ::= <newc_entry> <newc_entry> <newc_entry> <newc_trailer>
<newc_entry> ::= <newc_header> <newc_pathname> <newc_name_padding> <newc_file_data> <newc_data_padding>
where int(str(<newc_namesize>), 16) == len(str(<newc_pathname>)) and int(str(<newc_filesize>), 16) == len(str(<newc_file_data>)) and len(str(<newc_name_padding>)) == (-(110 + len(str(<newc_pathname>)))) % 4 and len(str(<newc_data_padding>)) == (-len(str(<newc_file_data>))) % 4
<newc_header> ::= <newc_magic> <newc_ino> <newc_mode> <newc_uid> <newc_gid> <newc_nlink> <newc_mtime> <newc_filesize> <newc_devmajor> <newc_devminor> <newc_rdevmajor> <newc_rdevminor> <newc_namesize> <newc_check>
<newc_magic> ::= "070701"
<newc_ino> ::= r'[0-9A-F]{7}[1-9A-F]'
<newc_mode> ::= r'00008[0-9A-F]{3}'
<newc_uid> ::= r'[0-9A-F]{8}'
<newc_gid> ::= r'[0-9A-F]{8}'
<newc_nlink> ::= "00000001"
<newc_mtime> ::= r'[0-9A-F]{8}'
<newc_filesize> ::= "00000001"
<newc_devmajor> ::= r'[0-9A-F]{8}'
<newc_devminor> ::= r'[0-9A-F]{8}'
<newc_rdevmajor> ::= r'[0-9A-F]{8}'
<newc_rdevminor> ::= r'[0-9A-F]{8}'
<newc_namesize> ::= "00000002"
<newc_check> ::= "00000000"
<newc_pathname> ::= <portable_name_char> "\x00"
<newc_name_padding> ::= ""
<newc_file_data> ::= <portable_data>
<newc_data_padding> ::= "\x00\x00\x00"
<newc_trailer> ::= "070701" "00000000" "00000000" "00000000" "00000000" "00000001" "00000000" "00000000" "00000000" "00000000" "00000000" "00000000" "0000000B" "00000000" "TRAILER!!!\x00" "\x00\x00\x00"

# New ASCII with checksums (crc, 070702): check is the sum of the data
# bytes
<crc_archive_1> ::= <crc_entry> <crc_trailer>
<crc_archive_2> ::= <crc_entry> <crc_entry> <crc_trailer>
<crc_archive_3> ::= <crc_entry> <crc_entry> <crc_entry> <crc_trailer>
<crc_entry> ::= <crc_header> <crc_pathname> <crc_name_padding> <crc_file_data> <crc_data_padding>
where int(str(<crc_namesize>), 16) == len(str(<crc_pathname>)) and int(str(<crc_filesize>), 16) == len(str(<crc_file_data>)) and int(str(<crc_check>), 16) == sum(str(<crc_file_data>).encode("ascii")) and len(str(<crc_name_padding>)) == (-(110 + len(str(<crc_pathname>)))) % 4 and len(str(<crc_data_padding>)) == (-len(str(<crc_file_data>))) % 4
<crc_header> ::= <crc_magic> <crc_ino> <crc_mode> <crc_uid> <crc_gid> <crc_nlink> <crc_mtime> <crc_filesize> <crc_devmajor> <crc_devminor> <crc_rdevmajor> <crc_rdevminor> <crc_namesize> <crc_check>
<crc_magic> ::= "070702"
<crc_ino> ::= r'[0-9A-F]{7}[1-9A-F]'
<crc_mode> ::= r'00008[0-9A-F]{3}'
<crc_uid> ::= r'[0-9A-F]{8}'
<crc_gid> ::= r'[0-9A-F]{8}'
<crc_nlink> ::= "00000001"
<crc_mtime> ::= r'[0-9A-F]{8}'
<crc_filesize> ::= "00000001"
<crc_devmajor> ::= r'[0-9A-F]{8}'
<crc_devminor> ::= r'[0-9A-F]{8}'
<crc_rdevmajor> ::= r'[0-9A-F]{8}'
<crc_rdevminor> ::= r'[0-9A-F]{8}'
<crc_namesize> ::= "00000002"
<crc_check> ::= "00000041"
<crc_pathname> ::= <portable_name_char> "\x00"
<crc_name_padding> ::= ""
<crc_file_data> ::= "A"
<crc_data_padding> ::= "\x00\x00\x00"
<crc_trailer> ::= "070702" "00000000" "00000000" "00000000" "00000000" "00000001" "00000000" "00000000" "00000000" "00000000" "00000000" "00000000" "0000000B" "00000000" "TRAILER!!!\x00" "\x00\x00\x00"

# Names and data of the ASCII formats
<portable_name_char> ::= r'[A-Za-z0-9._-]'
<portable_data> ::= r'[\x20-\x7e]'

# Old binary, big-endian (71 c7) or little-endian (c7 71): 16-bit fields,
# the time and the file size 32 bits, high half first; the name and the
# data padded to two bytes
<binary_file> ::= <binary_archive_1> <binary_pad_444> | <binary_archive_2> <binary_pad_414> | <binary_archive_3> <binary_pad_384>
<binary_archive_1> ::= <binary_be_archive_1> | <binary_le_archive_1>
<binary_archive_2> ::= <binary_be_archive_2> | <binary_le_archive_2>
<binary_archive_3> ::= <binary_be_archive_3> | <binary_le_archive_3>
<binary_pad_444> ::= rb'\x00{444}'
<binary_pad_414> ::= rb'\x00{414}'
<binary_pad_384> ::= rb'\x00{384}'

<binary_be_archive_1> ::= <binary_be_entry> <binary_be_trailer>
<binary_be_archive_2> ::= <binary_be_entry> <binary_be_entry> <binary_be_trailer>
<binary_be_archive_3> ::= <binary_be_entry> <binary_be_entry> <binary_be_entry> <binary_be_trailer>
<binary_be_entry> ::= <binary_be_header> <binary_pathname> <binary_name_padding> <binary_file_data> <binary_data_padding>
<binary_be_header> ::= b"\x71\xc7" <binary_be_dev> <binary_be_ino> <binary_be_mode> <binary_be_uid> <binary_be_gid> <binary_be_nlink> <binary_be_rdev> <binary_be_mtime> <binary_be_namesize> <binary_be_filesize>
<binary_be_dev> ::= b"\x00\x01"
<binary_be_ino> ::= b"\x00" <binary_nonzero_byte>
<binary_be_mode> ::= b"\x81\xa4" | b"\x81\xed"
<binary_be_uid> ::= b"\x00" <binary_small_byte>
<binary_be_gid> ::= b"\x00" <binary_small_byte>
<binary_be_nlink> ::= b"\x00\x01"
<binary_be_rdev> ::= b"\x00\x00"
<binary_be_mtime> ::= b"\x00\x00\x00" <binary_small_byte>
<binary_be_namesize> ::= b"\x00" <binary_namesize_byte>
<binary_be_filesize> ::= b"\x00\x00\x00" <binary_filesize_byte>
<binary_be_trailer> ::= b"\x71\xc7" b"\x00\x00" b"\x00\x00" b"\x00\x00" b"\x00\x00" b"\x00\x00" b"\x00\x01" b"\x00\x00" b"\x00\x00\x00\x00" b"\x00\x0b" b"\x00\x00\x00\x00" b"TRAILER!!!\x00" b"\x00"

<binary_le_archive_1> ::= <binary_le_entry> <binary_le_trailer>
<binary_le_archive_2> ::= <binary_le_entry> <binary_le_entry> <binary_le_trailer>
<binary_le_archive_3> ::= <binary_le_entry> <binary_le_entry> <binary_le_entry> <binary_le_trailer>
<binary_le_entry> ::= <binary_le_header> <binary_pathname> <binary_name_padding> <binary_file_data> <binary_data_padding>
<binary_le_header> ::= b"\xc7\x71" <binary_le_dev> <binary_le_ino> <binary_le_mode> <binary_le_uid> <binary_le_gid> <binary_le_nlink> <binary_le_rdev> <binary_le_mtime> <binary_le_namesize> <binary_le_filesize>
<binary_le_dev> ::= b"\x01\x00"
<binary_le_ino> ::= <binary_nonzero_byte> b"\x00"
<binary_le_mode> ::= b"\xa4\x81" | b"\xed\x81"
<binary_le_uid> ::= <binary_small_byte> b"\x00"
<binary_le_gid> ::= <binary_small_byte> b"\x00"
<binary_le_nlink> ::= b"\x01\x00"
<binary_le_rdev> ::= b"\x00\x00"
<binary_le_mtime> ::= b"\x00\x00" <binary_small_byte> b"\x00"
<binary_le_namesize> ::= <binary_namesize_byte> b"\x00"
<binary_le_filesize> ::= b"\x00\x00" <binary_filesize_byte> b"\x00"
<binary_le_trailer> ::= b"\xc7\x71" b"\x00\x00" b"\x00\x00" b"\x00\x00" b"\x00\x00" b"\x00\x00" b"\x01\x00" b"\x00\x00" b"\x00\x00\x00\x00" b"\x0b\x00" b"\x00\x00\x00\x00" b"TRAILER!!!\x00" b"\x00"

# Names and data of the binary format
<binary_pathname> ::= <binary_name_byte> b"\x00"
<binary_name_padding> ::= b""
<binary_file_data> ::= <binary_data_byte>
<binary_data_padding> ::= b"\x00"
<binary_name_byte> ::= b"a" | b"b" | b"c" | b"0" | b"1" | b"_"
<binary_data_byte> ::= b"A" | b"B" | b"C" | b"\x00" | b"\xff"
<binary_namesize_byte> ::= b"\x02"
<binary_filesize_byte> ::= b"\x01"
<binary_small_byte> ::= b"\x00" | b"\x01" | b"\x02" | b"\x03" | b"\x04" | b"\x05" | b"\x06" | b"\x07"
<binary_nonzero_byte> ::= b"\x01" | b"\x02" | b"\x03" | b"\x04" | b"\x05" | b"\x06" | b"\x07"
