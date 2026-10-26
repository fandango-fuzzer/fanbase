# 7z archives of one file stored with the Copy coder: the signature header
# (magic, format version, the start header and its CRC), the packed stream,
# and the header: archive properties (optional), the streams info (pack info,
# one folder with one coder, substreams info) and the files info (the name,
# and optionally the modification time, Windows attributes and padding). The
# pack and unpack sizes, the folder CRC, the size of the name property and
# the offset, size and CRC of the header are tied to the bytes by where
# constraints.
#
# TODO:
# * Every size is written as a 7z number of one byte, so the packed stream
#   is shorter than 128 bytes, and there is only ever one file.
# * Only the Copy coder: no LZMA, LZMA2, PPMd, BCJ or other filters, no
#   encoded or encrypted header.

import zlib
import random


# 7z writes integers little-endian, and its CRCs are CRC-32 (zlib's).
def u32le(n):
    return (int(n) & 0xFFFFFFFF).to_bytes(4, 'little')


def u64le(n):
    return (int(n) & 0xFFFFFFFFFFFFFFFF).to_bytes(8, 'little')


def crc32le(data):
    return (zlib.crc32(bytes(data)) & 0xFFFFFFFF).to_bytes(4, 'little')


# A 7z number below 128 is the value itself, in one byte.
def one(n):
    return bytes([int(n) & 0x7F])


# The packed stream: 16 to 100 random bytes, so that its length is one byte.
def random_blob():
    n = random.randint(16, 100)
    return bytes(random.randint(0, 255) for _ in range(n))


<start> ::= <archive>

<archive> ::= <signature_header> <packed_streams> <end_header>


# Signature header, 32 bytes
<signature_header> ::= <magic> <ver_major> <ver_minor> <start_header_crc> <start_header>

<magic> ::= b'7z\xbc\xaf\x27\x1c'
<ver_major> ::= b'\x00'
<ver_minor> ::= b'\x04' | b'\x03' | b'\x02'

<start_header_crc> ::= <byte>{4}

<start_header> ::= <next_header_offset> <next_header_size> <next_header_crc>
<next_header_offset> ::= <byte>{8}
<next_header_size> ::= <byte>{8}
<next_header_crc> ::= <byte>{4}


# Packed streams
<packed_streams> ::= <pack_blob>
<pack_blob> ::= <byte>* := random_blob()


# The header
<end_header> ::= <k_header> <opt_archive_props> <main_streams_info> <files_info> <k_end>

<opt_archive_props> ::= b'' | <k_archive_props> <k_end>


# Streams info
<main_streams_info> ::= <k_main_streams> <pack_info> <unpack_info> <substreams_info> <k_end>

# Pack info: the position of the pack stream, how many there are, their sizes
<pack_info> ::= <k_pack_info> <pack_pos> <num_pack_streams> <k_size> <pack_size> <k_end>
<pack_pos> ::= b'\x00'
<num_pack_streams> ::= b'\x01'
<pack_size> ::= <byte>

# Unpack info: one folder, the size it unpacks to, and its CRC
<unpack_info> ::= <k_unpack_info> <k_folder> <num_folders> <folders_external> \
                  <folder> <k_coders_unpack_size> <unpack_size> \
                  <k_crc> <folder_crc_alldef> <folder_crc> <k_end>
<num_folders> ::= b'\x01'
<folders_external> ::= b'\x00'
<folder_crc_alldef> ::= b'\x01'
<folder_crc> ::= <byte>{4}

# A folder of one coder: flags 0x01 (an ID of one byte, simple, no
# properties), ID 0x00 (Copy)
<folder> ::= <num_coders> <coder_copy>
<num_coders> ::= b'\x01'
<coder_copy> ::= b'\x01\x00'

<unpack_size> ::= <byte>

# Substreams info: the folder holds one stream, whose CRC is the folder's,
# so no size or CRC follows
<substreams_info> ::= <k_substreams_info> <k_num_unpack_stream> <sub_num_val> <k_end>
<sub_num_val> ::= b'\x01'


# Files info: one file
<files_info> ::= <k_files_info> <num_files> \
                 <file_prop_name> <opt_prop_mtime> <opt_prop_attr> <opt_prop_dummy> \
                 <k_end>
<num_files> ::= b'\x01'

# Name: size, external (0), then the name in UTF-16LE ending with NUL
<file_prop_name> ::= <k_name> <name_size> <name_external> <name_data>
<name_external> ::= b'\x00'
<name_size> ::= <byte>
<name_data> ::= b'a\x00.\x00t\x00x\x00t\x00\x00\x00' \
              | b'f\x00i\x00l\x00e\x00.\x00b\x00i\x00n\x00\x00\x00' \
              | b'r\x00e\x00a\x00d\x00m\x00e\x00\x00\x00' \
              | b'd\x00a\x00t\x00a\x00\x00\x00'

# Modification time: size 10, all defined, external 0, one FILETIME
<opt_prop_mtime> ::= b'' | <file_prop_mtime>
<file_prop_mtime> ::= <k_mtime> b'\x0a' <mtime_alldef> <mtime_external> <mtime_value>
<mtime_alldef> ::= b'\x01'
<mtime_external> ::= b'\x00'
<mtime_value> ::= <byte>{8}

# Windows attributes: size 6, all defined, external 0, four bytes
<opt_prop_attr> ::= b'' | <file_prop_attr>
<file_prop_attr> ::= <k_win_attr> b'\x06' <attr_alldef> <attr_external> <attr_value>
<attr_alldef> ::= b'\x01'
<attr_external> ::= b'\x00'
<attr_value> ::= <byte>{4}

# Dummy (padding): size 2, two zeros
<opt_prop_dummy> ::= b'' | <file_prop_dummy>
<file_prop_dummy> ::= <k_dummy> b'\x02' b'\x00\x00'


# Property IDs
<k_end> ::= b'\x00'
<k_header> ::= b'\x01'
<k_archive_props> ::= b'\x02'
<k_main_streams> ::= b'\x04'
<k_files_info> ::= b'\x05'
<k_pack_info> ::= b'\x06'
<k_unpack_info> ::= b'\x07'
<k_substreams_info> ::= b'\x08'
<k_size> ::= b'\x09'
<k_crc> ::= b'\x0a'
<k_folder> ::= b'\x0b'
<k_coders_unpack_size> ::= b'\x0c'
<k_num_unpack_stream> ::= b'\x0d'
<k_name> ::= b'\x11'
<k_mtime> ::= b'\x14'
<k_win_attr> ::= b'\x15'
<k_dummy> ::= b'\x19'


# Copy unpacks to what was packed: both sizes are the length of the stream,
# and the folder's CRC is the stream's.
where <pack_size> == one(len(bytes(<pack_blob>)))
where <unpack_size> == one(len(bytes(<pack_blob>)))
where <folder_crc> == crc32le(bytes(<pack_blob>))

# The name property's size counts the external byte and the name.
where <name_size> == one(1 + len(bytes(<name_data>)))

# The start header: where the header is, how long it is, its CRC, and its
# own CRC.
where <next_header_offset> == u64le(len(bytes(<packed_streams>)))
where <next_header_size> == u64le(len(bytes(<end_header>)))
where <next_header_crc> == crc32le(bytes(<end_header>))
where <start_header_crc> == crc32le(bytes(<start_header>))
