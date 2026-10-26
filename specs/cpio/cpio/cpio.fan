# cpio archives in each of the four header formats: portable ASCII (odc,
# 070707), new ASCII (newc, 070701), new ASCII with checksums (crc, 070702)
# and old binary (little-endian 070707). An archive is entries of one format
# and its TRAILER!!! entry. Each entry is a header, a NUL-terminated name and
# up to 16 bytes of data; the newc and crc formats pad the name and the data
# to four bytes, the binary format to two. The name and file sizes, the
# padding and the checksum of the crc format (the sum of the data bytes) are
# tied to the bytes by where constraints.
#
# TODO:
# * Almost every archive has a single entry.
# * Directories, devices and FIFOs have data like regular files, and every
#   entry has device numbers. 7-Zip refuses directories and FIFOs with data,
#   and before version 25.00 device numbers on an entry that is not a device
#   (GNU cpio and libarchive read them all).
# * The device, inode, owner, link count and time fields are random digits.

<start> ::= <odc_archive> | <newc_archive> | <crc_archive> | <bin_archive>

<nul>    ::= b'\x00'
<o6>     ::= r'[0-7]{6}'
<o11>    ::= r'[0-7]{11}'
<h8>     ::= r'[0-9A-Fa-f]{8}'
<fnchar> ::= r'[A-Za-z0-9._-]'

# Portable ASCII (odc): a 76-byte header of octal fields, no padding
<odc_archive> ::= <odc_entry>+ <odc_trailer>

<odc_entry> ::= "070707" <o6> <o6> <odc_mode> <o6> <o6> <o6> <o6> <o11> \
                <odc_ns> <odc_fs> <odc_fname> <nul> <odc_data>
<odc_mode>  ::= "100644" | "100755" | "040755" | "120777" | "020666" | "060666" | "010666"
<odc_ns>    ::= r'[0-7]{6}'
<odc_fs>    ::= r'[0-7]{11}'
<odc_fname> ::= <fnchar>{1,8}
<odc_data>  ::= <byte>{0,16}
where str(<odc_ns>) == format(len(bytes(<odc_fname>)) + 1, '06o')
where str(<odc_fs>) == format(len(bytes(<odc_data>)), '011o')

<odc_trailer> ::= "070707" <o6> <o6> <o6> <o6> <o6> <o6> <o6> <o11> \
                  "000013" "00000000000" "TRAILER!!!" <nul>

# New ASCII (newc): a 110-byte header of hexadecimal fields, the check field
# 0, the name and the data padded to four bytes
<newc_archive> ::= <newc_entry>+ <newc_trailer>

<newc_entry> ::= "070701" <h8> <nc_mode> <h8> <h8> <h8> <h8> <nc_fs> \
                 <h8> <h8> <h8> <h8> <nc_ns> "00000000" \
                 <nc_fname> <nul> <nc_npad> <nc_data> <nc_dpad>
<nc_mode>  ::= "000081A4" | "000081ED" | "000041ED" | "0000A1FF" | "000021B6" | "000061B6"
<nc_fs>    ::= r'[0-9A-Fa-f]{8}'
<nc_ns>    ::= r'[0-9A-Fa-f]{8}'
<nc_fname> ::= <fnchar>{1,8}
<nc_data>  ::= <byte>{0,16}
<nc_npad>  ::= <nul>{0,3}
<nc_dpad>  ::= <nul>{0,3}
where str(<nc_ns>) == format(len(bytes(<nc_fname>)) + 1, '08X')
where str(<nc_fs>) == format(len(bytes(<nc_data>)), '08X')
where bytes(<nc_npad>) == b'\x00' * ((4 - (110 + len(bytes(<nc_fname>)) + 1) % 4) % 4)
where bytes(<nc_dpad>) == b'\x00' * ((4 - len(bytes(<nc_data>)) % 4) % 4)

<newc_trailer> ::= "070701" <h8> "00000000" <h8> <h8> <h8> <h8> "00000000" \
                   <h8> <h8> <h8> <h8> "0000000B" "00000000" \
                   "TRAILER!!!" <nul> <nul> <nul> <nul>

# New ASCII with checksums (crc): newc, with the sum of the data bytes
# (modulo 2^32) in the check field
<crc_archive> ::= <crc_entry>+ <crc_trailer>

<crc_entry> ::= "070702" <h8> <cc_mode> <h8> <h8> <h8> <h8> <cc_fs> \
                <h8> <h8> <h8> <h8> <cc_ns> <cc_chk> \
                <cc_fname> <nul> <cc_npad> <cc_data> <cc_dpad>
<cc_mode>  ::= "000081A4" | "000081ED" | "000041ED" | "0000A1FF" | "000021B6" | "000061B6"
<cc_fs>    ::= r'[0-9A-Fa-f]{8}'
<cc_ns>    ::= r'[0-9A-Fa-f]{8}'
<cc_chk>   ::= r'[0-9A-Fa-f]{8}'
<cc_fname> ::= <fnchar>{1,8}
<cc_data>  ::= <byte>{0,16}
<cc_npad>  ::= <nul>{0,3}
<cc_dpad>  ::= <nul>{0,3}
where str(<cc_ns>) == format(len(bytes(<cc_fname>)) + 1, '08X')
where str(<cc_fs>) == format(len(bytes(<cc_data>)), '08X')
where str(<cc_chk>) == format(sum(bytes(<cc_data>)) % (2 ** 32), '08X')
where bytes(<cc_npad>) == b'\x00' * ((4 - (110 + len(bytes(<cc_fname>)) + 1) % 4) % 4)
where bytes(<cc_dpad>) == b'\x00' * ((4 - len(bytes(<cc_data>)) % 4) % 4)

<crc_trailer> ::= "070702" <h8> "00000000" <h8> <h8> <h8> <h8> "00000000" \
                  <h8> <h8> <h8> <h8> "0000000B" "00000000" \
                  "TRAILER!!!" <nul> <nul> <nul> <nul>

# Old binary: magic 070707 as a little-endian 16-bit number, a 26-byte
# header of 16-bit fields (the file size as two of them, high half first),
# the name and the data padded to two bytes
<bin_archive> ::= <bin_entry>+ <bin_trailer>

<bin_entry> ::= b'\xc7\x71' <s2> <s2> <bin_mode> <s2> <s2> <s2> <s2> <s4> \
                <bin_ns> <bin_fs> <bin_fname> <nul> <bin_npad> <bin_data> <bin_dpad>
<s2>       ::= <byte>{2}
<s4>       ::= <byte>{4}
<bin_mode> ::= <byte>{2}
<bin_ns>   ::= <byte>{2}
<bin_fs>   ::= <byte>{4}
<bin_fname> ::= <fnchar>{1,8}
<bin_data> ::= <byte>{0,16}
<bin_npad> ::= <nul>{0,1}
<bin_dpad> ::= <nul>{0,1}
where bytes(<bin_mode>) == (0o100644).to_bytes(2, 'little')
where bytes(<bin_ns>) == (len(bytes(<bin_fname>)) + 1).to_bytes(2, 'little')
where bytes(<bin_fs>) == (((len(bytes(<bin_data>)) >> 16) & 0xFFFF).to_bytes(2, 'little')
                          + (len(bytes(<bin_data>)) & 0xFFFF).to_bytes(2, 'little'))
where bytes(<bin_npad>) == b'\x00' * ((len(bytes(<bin_fname>)) + 1) % 2)
where bytes(<bin_dpad>) == b'\x00' * (len(bytes(<bin_data>)) % 2)

<bin_trailer> ::= b'\xc7\x71' <s2> <s2> <s2> <s2> <s2> <s2> <s2> <s4> \
                  b'\x0b\x00' b'\x00\x00\x00\x00' "TRAILER!!!" <nul> <nul>
