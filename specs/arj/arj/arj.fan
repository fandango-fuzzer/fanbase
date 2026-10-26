# ARJ archives: the main header, one to three files each followed by its
# data, and the end of archive marker. Every header is the ID 0x60 0xEA, the
# size of the basic header, the basic header (the 30-byte fixed part, an
# optional extra area, the NUL-terminated name and comment), its CRC-32, and
# a chain of extended headers ended by a size of 0; an end marker is the ID
# and a size of 0. The sizes of the basic and extended headers, their CRCs,
# first_hdr_size, and the sizes and CRC-32 of a file's data are tied to the
# bytes by where constraints. All fields are little-endian.
#
# TODO:
# * Every archive has one file: the grammar allows three, but each one adds
#   two CRCs that depend on each other (the data's, then the header's that
#   holds it).
# * The data is stored as it is, whatever method the header names (0 to 4).
# * The main header's host data is random, and ARJ itself reads it as the
#   chapters the archive has, so it finds no file in a third or more of them
#   (7-Zip and The Unarchiver read them all).

import zlib

<start> ::= <arj>

<arj> ::= <main_block> <file_entry>{1,3} <end_marker>

<magic> ::= b'\x60\xea'

# The main header: the first block, file_type 2, and no data
<main_block>    ::= <magic> <m_bh_size> <m_basic_header> <m_bh_crc> b'\x00\x00'
<m_basic_header> ::= <m_first_hdr_size> <m_arj_ver> <m_min_ver> <m_host_os> \
                     <m_flags> <m_method> <m_file_type> <m_reserved> \
                     <m_date_time> <m_comp_size> <m_orig_size> <m_file_crc> \
                     <m_filespec_pos> <m_file_access> <m_host_data> \
                     <m_extra> <m_filename> <m_comment>

<m_first_hdr_size> ::= <byte>
<m_arj_ver>        ::= rb'[\x01-\x0b]'
<m_min_ver>        ::= rb'[\x01-\x0b]'
<m_host_os>        ::= rb'[\x00-\x0b]'
<m_flags>          ::= b'\x00' | b'\x10'
<m_method>         ::= b'\x00'
<m_file_type>      ::= b'\x02'
<m_reserved>       ::= b'\x00'
<m_date_time>      ::= <byte>{4}
<m_comp_size>      ::= b'\x00\x00\x00\x00'
<m_orig_size>      ::= b'\x00\x00\x00\x00'
<m_file_crc>       ::= b'\x00\x00\x00\x00'
<m_filespec_pos>   ::= b'\x00\x00'
<m_file_access>    ::= <byte>{2}
<m_host_data>      ::= <byte>{2}
<m_extra>          ::= <byte>{0,4}
<m_filename>       ::= rb'[\x20-\x7e]{0,20}' b'\x00'
<m_comment>        ::= rb'[\x20-\x7e]{0,40}' b'\x00'
<m_bh_size>        ::= <byte>{2}
<m_bh_crc>         ::= <byte>{4}

where <m_first_hdr_size> == (30 + len(bytes(<m_extra>))).to_bytes(1, 'little')
where <m_bh_size> == len(bytes(<m_basic_header>)).to_bytes(2, 'little')
where <m_bh_crc> == (zlib.crc32(bytes(<m_basic_header>)) & 0xffffffff).to_bytes(4, 'little')

# A file: its header (file_type 0, binary, or 1, text), extended headers,
# and then comp_size bytes of data
<file_entry>     ::= <magic> <f_bh_size> <f_basic_header> <f_bh_crc> \
                     <f_ext_section> <f_data>
<f_basic_header> ::= <f_first_hdr_size> <f_arj_ver> <f_min_ver> <f_host_os> \
                     <f_flags> <f_method> <f_file_type> <f_reserved> \
                     <f_date_time> <f_comp_size> <f_orig_size> <f_file_crc> \
                     <f_filespec_pos> <f_file_access> <f_host_data> \
                     <f_extra> <f_filename> <f_comment>

<f_first_hdr_size> ::= <byte>
<f_arj_ver>        ::= rb'[\x01-\x0b]'
<f_min_ver>        ::= rb'[\x01-\x0b]'
<f_host_os>        ::= rb'[\x00-\x0b]'
<f_flags>          ::= b'\x00' | b'\x10'
<f_method>         ::= rb'[\x00-\x04]'
<f_file_type>      ::= b'\x00' | b'\x01'
<f_reserved>       ::= b'\x00'
<f_date_time>      ::= <byte>{4}
<f_comp_size>      ::= <byte>{4}
<f_orig_size>      ::= <byte>{4}
<f_file_crc>       ::= <byte>{4}
<f_filespec_pos>   ::= b'\x00\x00'
<f_file_access>    ::= <byte>{2}
<f_host_data>      ::= <byte>{2}
<f_extra>          ::= <byte>{0,4}
<f_filename>       ::= rb'[\x20-\x7e]{1,20}' b'\x00'
<f_comment>        ::= rb'[\x20-\x7e]{0,40}' b'\x00'
<f_bh_size>        ::= <byte>{2}
<f_bh_crc>         ::= <byte>{4}
<f_data>           ::= <byte>{0,48}

# Extended headers: at most one (size, data, CRC-32), then a size of 0
<f_ext_section> ::= <f_ext_entry>{0,1} b'\x00\x00'
<f_ext_entry>   ::= <f_ext_size> <f_ext_data> <f_ext_crc>
<f_ext_size>    ::= <byte>{2}
<f_ext_data>    ::= <byte>{1,8}
<f_ext_crc>     ::= <byte>{4}

where <f_first_hdr_size> == (30 + len(bytes(<f_extra>))).to_bytes(1, 'little')
where <f_bh_size> == len(bytes(<f_basic_header>)).to_bytes(2, 'little')
where <f_bh_crc> == (zlib.crc32(bytes(<f_basic_header>)) & 0xffffffff).to_bytes(4, 'little')
where <f_comp_size> == len(bytes(<f_data>)).to_bytes(4, 'little')
where <f_orig_size> == len(bytes(<f_data>)).to_bytes(4, 'little')
where <f_file_crc> == (zlib.crc32(bytes(<f_data>)) & 0xffffffff).to_bytes(4, 'little')
where <f_ext_size> == len(bytes(<f_ext_data>)).to_bytes(2, 'little')
where <f_ext_crc> == (zlib.crc32(bytes(<f_ext_data>)) & 0xffffffff).to_bytes(4, 'little')

# The end of the archive: the ID and a basic header size of 0
<end_marker> ::= <magic> b'\x00\x00'
