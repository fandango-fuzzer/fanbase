# Same as cpio, with field values at the edges: every type of entry (regular
# file, directory, symbolic link, character and block device, FIFO, socket)
# with setuid, setgid and sticky bits, all permissions or none, and a mode of
# 0; link counts of 1, 2 and the largest; times of 0, 1, 2^31 - 1, 2^32 - 1
# and the largest an odc field holds; names of any length, with '/' and '+' in
# them; and data of any length. As in cpio, the name and file sizes, the
# padding and the checksum of the crc format are tied to the bytes by where
# constraints.
#
# TODO:
# * Directories, devices, FIFOs and sockets may have data like regular files.
# * Every entry has random device numbers, which 7-Zip before version 25.00
#   refuses on an entry that is not a device (GNU cpio and libarchive read
#   them).

# One archive, in one of the four formats; an archive is entries and the
# TRAILER!!! entry (size 0, one link)
<start> ::= <odc_archive> | <newc_archive> | <crc_archive> | <bin_archive>

# Portable ASCII (odc, 070707): six octal digits a field, eleven for the
# time and the file size; no padding
<odc_archive> ::= <odc_entry>+ <odc_trailer>

<odc_entry> ::= (
    "070707"
    <odc_dev> <odc_ino> <odc_mode> <odc_uid> <odc_gid>
    <odc_nlink> <odc_rdev> <odc_mtime> <odc_namesize> <odc_filesize>
    <odc_name> <odc_data>
  )

<odc_trailer> ::= (
    "070707"
    <odc_dev> <odc_ino> "000000" <odc_uid> <odc_gid>
    "000001" <odc_rdev> "00000000000" "000013" "00000000000"
    "TRAILER!!!\x00"
  )

<odc_dev>      ::= <o6>
<odc_ino>      ::= <o6>

# The type of the file and its permissions
<odc_mode>     ::= "100644" | "100755" | "100777" | "104755" | "102644" \
                 | "040755" | "040000" | "120777" | "020666" | "060660" \
                 | "010600" | "140777" | "100000" | "106755"
<odc_uid>      ::= <o6>
<odc_gid>      ::= <o6>
<odc_nlink>    ::= "000001" | "000002" | "000077" | "177777"
<odc_rdev>     ::= <o6>
<odc_mtime>    ::= "00000000000" | "77777777777" | "00000000001" | "37777777777"
<odc_namesize> ::= <o6>
<odc_filesize> ::= <o11>
<odc_name>     ::= <fnchar>+ "\x00"
<odc_data>     ::= <byte>*

# New ASCII (newc, 070701): eight hexadecimal digits a field; the header
# and name, and the data, padded to four bytes; check is 0
<newc_archive> ::= <nc_entry>+ <nc_trailer>

<nc_entry> ::= (
    "070701"
    <nc_ino> <nc_mode> <nc_uid> <nc_gid> <nc_nlink> <nc_mtime>
    <nc_filesize> <nc_devmajor> <nc_devminor> <nc_rdevmajor> <nc_rdevminor>
    <nc_namesize> <nc_check>
    <nc_name> <nc_npad> <nc_data> <nc_dpad>
  )

<nc_trailer> ::= (
    "070701"
    <nc_ino> "00000000" "00000000" "00000000" "00000001" "00000000"
    "00000000" "00000000" "00000000" "00000000" "00000000"
    "0000000B" "00000000"
    "TRAILER!!!\x00" "\x00\x00\x00"
  )

<nc_ino>       ::= <h8>
<nc_mode>      ::= "000081A4" | "000081ED" | "000081FF" | "000041FF" \
                 | "000041ED" | "0000A1FF" | "000021B6" | "000061B0" \
                 | "000011B4" | "0000C1FF" | "000081B8" | "00000000"
<nc_uid>       ::= <h8>
<nc_gid>       ::= <h8>
<nc_nlink>     ::= "00000001" | "00000002" | "0000FFFF" | "7FFFFFFF"
<nc_mtime>     ::= "00000000" | "FFFFFFFF" | "00000001" | "7FFFFFFF"
<nc_filesize>  ::= <h8>
<nc_devmajor>  ::= <h8>
<nc_devminor>  ::= <h8>
<nc_rdevmajor> ::= <h8>
<nc_rdevminor> ::= <h8>
<nc_namesize>  ::= <h8>
<nc_check>     ::= <h8>
<nc_name>      ::= <fnchar>+ "\x00"
<nc_npad>      ::= <nul>{0,3}
<nc_data>      ::= <byte>*
<nc_dpad>      ::= <nul>{0,3}

# New ASCII with checksums (crc, 070702): newc, with the sum of the data
# bytes in check
<crc_archive> ::= <cc_entry>+ <cc_trailer>

<cc_entry> ::= (
    "070702"
    <cc_ino> <cc_mode> <cc_uid> <cc_gid> <cc_nlink> <cc_mtime>
    <cc_filesize> <cc_devmajor> <cc_devminor> <cc_rdevmajor> <cc_rdevminor>
    <cc_namesize> <cc_check>
    <cc_name> <cc_npad> <cc_data> <cc_dpad>
  )

<cc_trailer> ::= (
    "070702"
    <cc_ino> "00000000" "00000000" "00000000" "00000001" "00000000"
    "00000000" "00000000" "00000000" "00000000" "00000000"
    "0000000B" "00000000"
    "TRAILER!!!\x00" "\x00\x00\x00"
  )

<cc_ino>       ::= <h8>
<cc_mode>      ::= "000081A4" | "000081ED" | "000081FF" | "000041FF" \
                 | "0000A1FF" | "000021B6" | "000061B0" | "000011B4" \
                 | "0000C1FF" | "000081B8"
<cc_uid>       ::= <h8>
<cc_gid>       ::= <h8>
<cc_nlink>     ::= "00000001" | "00000002" | "0000FFFF"
<cc_mtime>     ::= "00000000" | "FFFFFFFF" | "7FFFFFFF"
<cc_filesize>  ::= <h8>
<cc_devmajor>  ::= <h8>
<cc_devminor>  ::= <h8>
<cc_rdevmajor> ::= <h8>
<cc_rdevminor> ::= <h8>
<cc_namesize>  ::= <h8>
<cc_check>     ::= <h8>
<cc_name>      ::= <fnchar>+ "\x00"
<cc_npad>      ::= <nul>{0,3}
<cc_data>      ::= <byte>*
<cc_dpad>      ::= <nul>{0,3}

# Old binary: magic 070707 as a little-endian 16-bit number, then 16-bit
# little-endian fields; the time and the file size are 32 bits, the high
# half first; the name (with its NUL) and the data padded to two bytes
<bin_archive> ::= <bin_entry>+ <bin_trailer>

<bin_entry> ::= (
    b'\xc7\x71'
    <bin_dev> <bin_ino> <bin_mode> <bin_uid> <bin_gid>
    <bin_nlink> <bin_rdev> <bin_mtime> <bin_namesize> <bin_filesize>
    <bin_name> <bin_npad> <bin_data> <bin_dpad>
  )

<bin_trailer> ::= (
    b'\xc7\x71'
    <bin_dev> <bin_ino> b'\x00\x00' <bin_uid> <bin_gid>
    b'\x01\x00' <bin_rdev> <bin_mtime> b'\x0b\x00' b'\x00\x00\x00\x00'
    b'TRAILER!!!\x00' b'\x00'
  )

<bin_dev>      ::= <w16>
<bin_ino>      ::= <w16>

# The type and permissions, little-endian
<bin_mode>     ::= b'\xa4\x81' | b'\xed\x81' | b'\xff\x81' | b'\xff\x41' \
                 | b'\xed\x41' | b'\xff\xa1' | b'\xb6\x21' | b'\xb0\x61' \
                 | b'\xb4\x11' | b'\xff\xc1' | b'\xb8\x81'
<bin_uid>      ::= <w16>
<bin_gid>      ::= <w16>
<bin_nlink>    ::= b'\x01\x00' | b'\x02\x00' | b'\xff\xff'
<bin_rdev>     ::= <w16>
<bin_mtime>    ::= <w16> <w16>
<bin_namesize> ::= <w16>
<bin_filesize> ::= <w16> <w16>
<bin_name>     ::= <fnchar>+ "\x00"
<bin_npad>     ::= <nul>{0,1}
<bin_data>     ::= <byte>*
<bin_dpad>     ::= <nul>{0,1}

# Digits, words and names
<o6>  ::= <odigit> <odigit> <odigit> <odigit> <odigit> <odigit>
<o11> ::= <odigit> <odigit> <odigit> <odigit> <odigit> <odigit> \
          <odigit> <odigit> <odigit> <odigit> <odigit>
<h8>  ::= <hdigit> <hdigit> <hdigit> <hdigit> <hdigit> <hdigit> <hdigit> <hdigit>
<odigit> ::= r'[0-7]'
<hdigit> ::= r'[0-9A-F]'
<w16>    ::= <byte> <byte>
<nul>    ::= "\x00"
<fnchar> ::= r'[a-zA-Z0-9._+/-]'

# The name size counts the NUL, and the file size is the data's length.
where str(<odc_namesize>) == format(len(bytes(<odc_name>)), '06o')
where str(<odc_filesize>) == format(len(bytes(<odc_data>)), '011o')

# newc: the sizes in hexadecimal, check 0, and the padding
where str(<nc_namesize>) == format(len(bytes(<nc_name>)), '08X')
where str(<nc_filesize>) == format(len(bytes(<nc_data>)), '08X')
where str(<nc_check>) == "00000000"
where bytes(<nc_npad>) == b'\x00' * ((4 - (110 + len(bytes(<nc_name>))) % 4) % 4)
where bytes(<nc_dpad>) == b'\x00' * ((4 - len(bytes(<nc_data>)) % 4) % 4)

# crc: the same, and check is the sum of the data bytes modulo 2^32
where str(<cc_namesize>) == format(len(bytes(<cc_name>)), '08X')
where str(<cc_filesize>) == format(len(bytes(<cc_data>)), '08X')
where str(<cc_check>) == format(sum(bytes(<cc_data>)) % (2**32), '08X')
where bytes(<cc_npad>) == b'\x00' * ((4 - (110 + len(bytes(<cc_name>))) % 4) % 4)
where bytes(<cc_dpad>) == b'\x00' * ((4 - len(bytes(<cc_data>)) % 4) % 4)

# Old binary: the sizes, the file size high half first, and the padding
where bytes(<bin_namesize>) == (len(bytes(<bin_name>))).to_bytes(2, 'little')
where bytes(<bin_filesize>) == ((len(bytes(<bin_data>)) >> 16) & 0xffff).to_bytes(2, 'little') + (len(bytes(<bin_data>)) & 0xffff).to_bytes(2, 'little')
where bytes(<bin_npad>) == b'\x00' * (len(bytes(<bin_name>)) % 2)
where bytes(<bin_dpad>) == b'\x00' * (len(bytes(<bin_data>)) % 2)
