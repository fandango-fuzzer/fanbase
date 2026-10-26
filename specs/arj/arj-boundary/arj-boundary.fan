# ARJ archives of one file whose header fields take the edge values: all
# twelve host systems; flags for garbled, secured, multi-volume and backup
# archives, extended files and path separators, in combination and all set;
# version bytes 1, 11 and 255; methods 0 to 4; binary, text, directory and
# volume label entries; reserved bytes, chapters, extra header areas, names
# and comments of any length; and data from none at all. The main header has
# the security envelope, archive size and encryption version fields of ARJ 2.
# As in arj, the header sizes and CRCs, first_hdr_size, the extended headers
# and the sizes and CRC-32 of the data are tied to the bytes by where
# constraints.
#
# TODO:
# * One file per archive.
# * The data is stored as it is, whatever the method, and the flags are set on
#   their own: an archive says it is garbled, secured or a volume when nothing
#   in it is.

import zlib

# Integers are little-endian
def u16le(n):
    return (n & 0xFFFF).to_bytes(2, "little")

def u32le(n):
    return (n & 0xFFFFFFFF).to_bytes(4, "little")

def cat(*xs):
    return b"".join(bytes(x) for x in xs)

# The main header, one file and the end of the archive
<start> ::= <main_block> <file_block> <end_marker>

<byte> ::= rb'[\x00-\xff]'

# Host systems 0 to 11: MS-DOS, PRIMOS, Unix, Amiga, Mac OS, OS/2, Apple
# GS, Atari ST, NeXT, VAX VMS, Windows 95, Win32
<host_os> ::= b'\x00' | b'\x01' | b'\x02' | b'\x03' | b'\x04' | b'\x05' \
            | b'\x06' | b'\x07' | b'\x08' | b'\x09' | b'\x0a' | b'\x0b'

# Flags: none, garbled (0x01), old secured (0x02), volume (0x04), extended
# file (0x08), path separators (0x10), backup (0x20), secured (0x40), some
# together, and all
<arj_flags> ::= b'\x00' | b'\x01' | b'\x02' | b'\x04' | b'\x08' | b'\x10' \
              | b'\x20' | b'\x40' | b'\x03' | b'\x0d' | b'\x5f' | b'\xff'

# Version bytes
<verbyte> ::= b'\x01' | b'\x0b' | b'\xff'

# The main header (file_type 2), and its extended headers
<main_block> ::= b'\x60\xea' <m_bh_size> <m_basic> <m_bh_crc> <m_ext_section>
    where bytes(<m_bh_size>) == u16le(len(bytes(<m_basic>)))
    where bytes(<m_bh_crc>) == u32le(zlib.crc32(bytes(<m_basic>)) & 0xFFFFFFFF)

<m_basic> ::= <m_first_hdr_size> <m_arch_ver> <m_min_ver> <m_host_os> \
              <m_flags> <m_sec_ver> <m_file_type> <m_reserved> \
              <m_created> <m_modified> <m_archive_size> <m_sec_env_pos> \
              <m_filespec_pos> <m_sec_env_len> <m_host_data> <m_enc_ver> \
              <m_extra> <m_name> <m_comment>
    where bytes(<m_first_hdr_size>) == bytes([(30 + len(bytes(<m_extra>))) & 0xFF])

<m_bh_size> ::= <byte>{2}
<m_bh_crc> ::= <byte>{4}
<m_first_hdr_size> ::= <byte>
<m_arch_ver> ::= <verbyte>
<m_min_ver> ::= <verbyte>
<m_host_os> ::= <host_os>
<m_flags> ::= <arj_flags>
<m_sec_ver> ::= b'\x00' | b'\x02'
<m_file_type> ::= b'\x02'
<m_reserved> ::= b'\x00' | b'\xff'
<m_created> ::= <byte>{4}
<m_modified> ::= <byte>{4}
<m_archive_size> ::= <byte>{4}
<m_sec_env_pos> ::= <byte>{4}
<m_filespec_pos> ::= <byte>{2}
<m_sec_env_len> ::= <byte>{2}
<m_host_data> ::= <byte>{2}
<m_enc_ver> ::= <byte>
<m_extra> ::= rb'[\x00-\xff]{0,8}'
<m_name> ::= <m_name_chars> b'\x00'
<m_name_chars> ::= rb'[\x20-\x7e]{0,20}'
<m_comment> ::= <m_comment_chars> b'\x00'
<m_comment_chars> ::= rb'[\x20-\x7e]{0,24}'

# Extended headers: at most one (size, data, CRC-32), then a size of 0
<m_ext_section> ::= <m_ext_entry>{0,1} b'\x00\x00'
<m_ext_entry> ::= <m_ext_size> <m_ext_data> <m_ext_crc>
    where bytes(<m_ext_size>) == u16le(len(bytes(<m_ext_data>)))
    where bytes(<m_ext_crc>) == u32le(zlib.crc32(bytes(<m_ext_data>)) & 0xFFFFFFFF)
<m_ext_size> ::= <byte>{2}
<m_ext_data> ::= rb'[\x00-\xff]{1,16}'
<m_ext_crc> ::= <byte>{4}

# The file: its header, written out field by field so that the sizes and
# the CRC of the data reach the fields, then extended headers and the data.
# The size and CRC of the header are over its fields, joined by cat().
<file_block> ::= b'\x60\xea' <f_bh_size> \
                 <f_first_hdr_size> <f_arch_ver> <f_min_ver> <f_host_os> \
                 <f_flags> <f_method> <f_file_type> <f_reserved> \
                 <f_modified> <f_comp_size> <f_orig_size> <f_file_crc> \
                 <f_filespec_pos> <f_access_mode> <f_host_data> <f_chapter> \
                 <f_extra> <f_name> <f_comment> \
                 <f_bh_crc> <f_ext_section> <f_data>
    where bytes(<f_bh_size>) == u16le(len(cat(
              <f_first_hdr_size>, <f_arch_ver>, <f_min_ver>, <f_host_os>,
              <f_flags>, <f_method>, <f_file_type>, <f_reserved>,
              <f_modified>, <f_comp_size>, <f_orig_size>, <f_file_crc>,
              <f_filespec_pos>, <f_access_mode>, <f_host_data>, <f_chapter>,
              <f_extra>, <f_name>, <f_comment>)))
    where bytes(<f_bh_crc>) == u32le(zlib.crc32(cat(
              <f_first_hdr_size>, <f_arch_ver>, <f_min_ver>, <f_host_os>,
              <f_flags>, <f_method>, <f_file_type>, <f_reserved>,
              <f_modified>, <f_comp_size>, <f_orig_size>, <f_file_crc>,
              <f_filespec_pos>, <f_access_mode>, <f_host_data>, <f_chapter>,
              <f_extra>, <f_name>, <f_comment>)) & 0xFFFFFFFF)
    where bytes(<f_first_hdr_size>) == bytes([(30 + len(bytes(<f_extra>))) & 0xFF])
    where bytes(<f_comp_size>) == u32le(len(bytes(<f_data>)))
    where bytes(<f_orig_size>) == u32le(len(bytes(<f_data>)))
    where bytes(<f_file_crc>) == u32le(zlib.crc32(bytes(<f_data>)) & 0xFFFFFFFF)

<f_bh_size> ::= <byte>{2}
<f_bh_crc> ::= <byte>{4}
<f_first_hdr_size> ::= <byte>
<f_arch_ver> ::= <verbyte>
<f_min_ver> ::= <verbyte>
<f_host_os> ::= <host_os>
<f_flags> ::= <arj_flags>

# Method: 0 stored, 1 to 3 compressed, 4 fastest
<f_method> ::= b'\x00' | b'\x01' | b'\x02' | b'\x03' | b'\x04'

# Type: 0 binary, 1 text (7-bit), 3 directory, 4 volume label
<f_file_type> ::= b'\x00' | b'\x01' | b'\x03' | b'\x04'
<f_reserved> ::= b'\x00' | b'\xff'
<f_modified> ::= <byte>{4}
<f_comp_size> ::= <byte>{4}
<f_orig_size> ::= <byte>{4}
<f_file_crc> ::= <byte>{4}
<f_filespec_pos> ::= <byte>{2}
<f_access_mode> ::= <byte>{2}
<f_host_data> ::= <byte>{2}
<f_chapter> ::= <byte>
<f_extra> ::= rb'[\x00-\xff]{0,8}'
<f_name> ::= <f_name_chars> b'\x00'
<f_name_chars> ::= rb'[\x20-\x7e]{1,24}'
<f_comment> ::= <f_comment_chars> b'\x00'
<f_comment_chars> ::= rb'[\x20-\x7e]{0,16}'

<f_ext_section> ::= <f_ext_entry>{0,1} b'\x00\x00'
<f_ext_entry> ::= <f_ext_size> <f_ext_data> <f_ext_crc>
    where bytes(<f_ext_size>) == u16le(len(bytes(<f_ext_data>)))
    where bytes(<f_ext_crc>) == u32le(zlib.crc32(bytes(<f_ext_data>)) & 0xFFFFFFFF)
<f_ext_size> ::= <byte>{2}
<f_ext_data> ::= rb'[\x00-\xff]{1,16}'
<f_ext_crc> ::= <byte>{4}

# The data, stored, and possibly empty
<f_data> ::= rb'[\x00-\xff]{0,32}'

# The end of the archive: the ID and a basic header size of 0
<end_marker> ::= b'\x60\xea\x00\x00'
