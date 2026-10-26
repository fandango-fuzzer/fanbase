# ZIP (PKWARE APPNOTE): three entries, a stored text file, a deflated file
# written as a stream (general purpose bit 3, sizes and CRC-32 in a data
# descriptor after the data) and a directory, then their central directory
# records and the end of central directory record with an archive comment.
# CRC-32s, sizes, name, extra and comment lengths, the offset of each local
# header and the size and offset of the central directory are tied to the
# bytes they describe with where constraints. All fields are little-endian.
#
# TODO:
# * The deflated file is one stored deflate block (BTYPE 00), so no reader
#   ever decodes Huffman codes from these files.
# * There are always exactly these three entries, in this order.
# * No ZIP64, encryption, or archives split over several disks.

import zlib

<start> ::= <zip>

<zip> ::= <local_stored> <local_deflate> <local_dir> \
          <central_stored> <central_deflate> <central_dir> \
          <eocd>

# Fields that every header shares
<ver>      ::= b'\x14\x00'          # version needed to extract: 2.0
<vermade>  ::= b'\x14\x00'          # made by: MS-DOS, 2.0
<flags0>   ::= b'\x00\x00'
<flags3>   ::= b'\x08\x00'          # bit 3: sizes and CRC in a data descriptor
<m_store>  ::= b'\x00\x00'          # method 0, stored
<m_defl>   ::= b'\x08\x00'          # method 8, deflate
<mtime>    ::= b'\x48\x00'
<mdate>    ::= b'\x21\x00'          # 1980-01-01
<disk0>    ::= b'\x00\x00'
<iattr>    ::= b'\x00\x00'
<eattr>    ::= b'\x00\x00\x00\x00'
<eattr_dir>::= b'\x10\x00\x00\x00'  # FILE_ATTRIBUTE_DIRECTORY
<zero32>   ::= b'\x00\x00\x00\x00'
<count3>   ::= b'\x03\x00'
<clen0>    ::= b'\x00\x00'

<u16> ::= <byte>{2}
<u32> ::= <byte>{4}
<byte> ::= rb'(?s).'

# Entry 1: hello.txt, stored, with an extended timestamp extra field (0x5455)
<local_stored> ::= b'PK\x03\x04' <ver> <flags0> <m_store> <mtime> <mdate> \
                   <crc_s> <csize_s> <usize_s> <nlen_s> <elen_s> \
                   b'hello.txt' <extra_s> <data_s>

<nlen_s>  ::= b'\x09\x00'
<extra_s> ::= b'UT\x05\x00\x01\x00\x00\x00\x00' # id 0x5455, 5 bytes: flags, mtime
<data_s>  ::= rb'[ -~]{1,60}'

<crc_s>   ::= <u32>
<csize_s> ::= <u32>
<usize_s> ::= <u32>
<elen_s>  ::= <u16>

where <crc_s>   == int.to_bytes(zlib.crc32(bytes(<data_s>)) & 0xffffffff, 4, 'little')
where <csize_s> == int.to_bytes(len(bytes(<data_s>)), 4, 'little')
where <usize_s> == int.to_bytes(len(bytes(<data_s>)), 4, 'little')
where <elen_s>  == int.to_bytes(len(bytes(<extra_s>)), 2, 'little')

# Entry 2: data.bin, deflated, written as a stream. The local header has
# zeros for CRC and sizes; the data descriptor (PK\x07\x08) after the data
# has them. The data is one final stored deflate block: 0x01, LEN, ~LEN, bytes.
<local_deflate> ::= b'PK\x03\x04' <ver> <flags3> <m_defl> <mtime> <mdate> \
                    <zero32> <zero32> <zero32> <nlen_d> b'\x00\x00' \
                    b'data.bin' <ddata> <descriptor>

<nlen_d> ::= b'\x08\x00'

<ddata>  ::= b'\x01' <len_d> <nlen_bits> <data_d>
<data_d> ::= rb'[A-Za-z0-9]{1,40}'
<len_d>     ::= <u16>
<nlen_bits> ::= <u16>

<descriptor> ::= b'PK\x07\x08' <crc_d> <csize_d> <usize_d>
<crc_d>   ::= <u32>
<csize_d> ::= <u32>
<usize_d> ::= <u32>

where <len_d>     == int.to_bytes(len(bytes(<data_d>)), 2, 'little')
where <nlen_bits> == int.to_bytes(len(bytes(<data_d>)) ^ 0xffff, 2, 'little')
where <crc_d>     == int.to_bytes(zlib.crc32(bytes(<data_d>)) & 0xffffffff, 4, 'little')
where <csize_d>   == int.to_bytes(len(bytes(<ddata>)), 4, 'little')
where <usize_d>   == int.to_bytes(len(bytes(<data_d>)), 4, 'little')

# Entry 3: the directory dir/, stored, empty
<local_dir> ::= b'PK\x03\x04' <ver> <flags0> <m_store> <mtime> <mdate> \
                <zero32> <zero32> <zero32> b'\x04\x00' b'\x00\x00' b'dir/'

# Central directory: one record per entry, with its CRC, sizes and method
# again, and the offset of its local header. hello.txt has a file comment.
<central_stored> ::= b'PK\x01\x02' <vermade> <ver> <flags0> <m_store> <mtime> <mdate> \
                     <ccrc_s> <ccsize_s> <cusize_s> b'\x09\x00' <clen0> <cmlen_s> \
                     <disk0> <iattr> <eattr> <off_s> b'hello.txt' <comment_s>

<cmlen_s>   ::= <u16>
<comment_s> ::= rb'[ -~]{1,30}'
<ccrc_s>    ::= <u32>
<ccsize_s>  ::= <u32>
<cusize_s>  ::= <u32>
<off_s>     ::= <u32>

where <ccrc_s>    == int.to_bytes(zlib.crc32(bytes(<data_s>)) & 0xffffffff, 4, 'little')
where <ccsize_s>  == int.to_bytes(len(bytes(<data_s>)), 4, 'little')
where <cusize_s>  == int.to_bytes(len(bytes(<data_s>)), 4, 'little')
where <cmlen_s>   == int.to_bytes(len(bytes(<comment_s>)), 2, 'little')
where <off_s>     == int.to_bytes(0, 4, 'little')

<central_deflate> ::= b'PK\x01\x02' <vermade> <ver> <flags3> <m_defl> <mtime> <mdate> \
                      <ccrc_d> <ccsize_d> <cusize_d> b'\x08\x00' <clen0> <clen0> \
                      <disk0> <iattr> <eattr> <off_d> b'data.bin'

<ccrc_d>   ::= <u32>
<ccsize_d> ::= <u32>
<cusize_d> ::= <u32>
<off_d>    ::= <u32>

where <ccrc_d>   == int.to_bytes(zlib.crc32(bytes(<data_d>)) & 0xffffffff, 4, 'little')
where <ccsize_d> == int.to_bytes(len(bytes(<ddata>)), 4, 'little')
where <cusize_d> == int.to_bytes(len(bytes(<data_d>)), 4, 'little')
where <off_d>    == int.to_bytes(len(bytes(<local_stored>)), 4, 'little')

<central_dir> ::= b'PK\x01\x02' <vermade> <ver> <flags0> <m_store> <mtime> <mdate> \
                  <zero32> <zero32> <zero32> b'\x04\x00' <clen0> <clen0> \
                  <disk0> <iattr> <eattr_dir> <off_dir> b'dir/'

<off_dir> ::= <u32>
where <off_dir> == int.to_bytes(len(bytes(<local_stored>)) + len(bytes(<local_deflate>)), 4, 'little')

# End of central directory: three entries, the size and offset of the
# central directory, and the archive comment
<eocd> ::= b'PK\x05\x06' <disk0> <disk0> <count3> <count3> \
           <cd_size> <cd_off> <aclen> <acomment>

<cd_size>  ::= <u32>
<cd_off>   ::= <u32>
<aclen>    ::= <u16>
<acomment> ::= rb'[ -~]{0,40}'

where <cd_off>  == int.to_bytes(len(bytes(<local_stored>)) + len(bytes(<local_deflate>)) + len(bytes(<local_dir>)), 4, 'little')
where <cd_size> == int.to_bytes(len(bytes(<central_stored>)) + len(bytes(<central_deflate>)) + len(bytes(<central_dir>)), 4, 'little')
where <aclen>   == int.to_bytes(len(bytes(<acomment>)), 2, 'little')
