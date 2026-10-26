# Cabinet files in eight layouts, with every size and offset written out: an
# empty cabinet; one stored file of one byte; reserved areas in the header,
# the folder and the data block; a cabinet in a set, with the names of the
# previous and next cabinets and a file that continues; two folders with two
# files; a real MSZIP block (of "A"); folders that declare no compression,
# MSZIP, Quantum (levels and memory at both ends) or LZX (windows at both
# ends) and hold no data; and a file in a folder sixteen levels deep. The set
# ID, cabinet number, reserved bytes and file data vary; checksums are 0 (not
# given).
#
# TODO:
# * Each layout is fixed apart from a few bytes, so what varies between files
#   is mostly which layout they are.
# * The fields are written as text of bytes below 0x80, so that they are one
#   byte each: no field holds a byte of 0x80 or more.

# Integers are little-endian
<start> ::= <cabinet>

<cabinet> ::= <empty_cabinet> | <stored_cabinet> | <reserved_cabinet> | \
              <linked_cabinet> | <multifolder_cabinet> | <mszip_cabinet> | \
              <compression_marker_cabinet> | <deep_path_cabinet>

# A cabinet with no folder and no file
<empty_cabinet> ::= <signature> <zero4> "\x24\x00\x00\x00" <zero4> \
                    "\x24\x00\x00\x00" <zero4> <version> "\x00\x00" \
                    "\x00\x00" "\x00\x00" <set_id> "\x00\x00"

# One folder, one file of one byte, stored
<stored_cabinet> ::= <signature> <zero4> "\x47\x00\x00\x00" <zero4> \
                     "\x2c\x00\x00\x00" <zero4> <version> "\x01\x00" \
                     "\x01\x00" "\x00\x00" <set_id> "\x00\x00" \
                     <stored_folder> <stored_file> <cfdata_one>
<stored_folder> ::= "\x3e\x00\x00\x00" "\x01\x00" "\x00\x00"
<stored_file> ::= "\x01\x00\x00\x00" <zero4> "\x00\x00" \
                  "\x21\x00" "\x00\x00" "\x20\x00" "a\x00"

# Reserved areas: 4 bytes after the header, 2 after the folder, 3 after
# the data block's header
<reserved_cabinet> ::= <signature> <zero4> "\x55\x00\x00\x00" <zero4> \
                       "\x36\x00\x00\x00" <zero4> <version> "\x01\x00" \
                       "\x01\x00" "\x04\x00" <set_id> "\x7f\x7f" \
                       "\x04\x00" "\x02" "\x03" <header_reserve4> \
                       <reserved_folder> <reserved_file> <cfdata_two_reserved>
<header_reserve4> ::= <any_byte>{4}
<reserved_folder> ::= "\x48\x00\x00\x00" "\x01\x00" "\x00\x00" <any_byte>{2}
<reserved_file> ::= "\x02\x00\x00\x00" <zero4> "\x00\x00" \
                    "\x7e\x7e" "\x7d\x7d" "\x67\x00" "r\x00"
<cfdata_two_reserved> ::= <zero4> "\x02\x00" "\x02\x00" \
                          <any_byte>{3} <data_two>

# In a set (previous and next cabinets, flags 0x0003), with a file that
# continues
<linked_cabinet> ::= <signature> <zero4> "\x63\x00\x00\x00" <zero4> \
                     "\x4a\x00\x00\x00" <zero4> <version> "\x01\x00" \
                     "\x01\x00" "\x03\x00" "\x7f\x7f" <cabinet_index> \
                     "prev.cab\x00" "disk0\x00" "next.cab\x00" "disk2\x00" \
                     <linked_folder> <continued_file>
<linked_folder> ::= "\x63\x00\x00\x00" "\x00\x00" "\x00\x00"
<continued_file> ::= <zero4> <zero4> <continuation_index> \
                     "\x7e\x7e" "\x7d\x7d" "\x60\x00" "span.bin\x00"
<continuation_index> ::= "\x00\x00"

# Two folders, two files, a stored block for each
<multifolder_cabinet> ::= <signature> <zero4> "\x6a\x00\x00\x00" <zero4> \
                          "\x34\x00\x00\x00" <zero4> <version> "\x02\x00" \
                          "\x02\x00" "\x00\x00" <set_id> "\x00\x00" \
                          <multi_folder_zero> <multi_folder_one> \
                          <multi_file_zero> <multi_file_one> \
                          <cfdata_one> <cfdata_one>
<multi_folder_zero> ::= "\x58\x00\x00\x00" "\x01\x00" "\x00\x00"
<multi_folder_one> ::= "\x61\x00\x00\x00" "\x01\x00" "\x00\x00"
<multi_file_zero> ::= "\x01\x00\x00\x00" <zero4> "\x00\x00" \
                      "\x21\x00" "\x00\x00" "\x01\x00" "a\x00"
<multi_file_one> ::= "\x01\x00\x00\x00" <zero4> "\x01\x00" \
                     "\x7e\x7e" "\x7d\x7d" "\x67\x00" "b\x00"

# A file sixteen folders deep
<deep_path_cabinet> ::= <signature> <zero4> "\x69\x00\x00\x00" <zero4> \
                        "\x2c\x00\x00\x00" <zero4> <version> "\x01\x00" \
                        "\x01\x00" "\x00\x00" <set_id> "\x00\x00" \
                        <deep_folder> <deep_file> <cfdata_one>
<deep_folder> ::= "\x60\x00\x00\x00" "\x01\x00" "\x00\x00"
<deep_file> ::= "\x01\x00\x00\x00" <zero4> "\x00\x00" \
                "\x21\x00" "\x00\x00" "\x20\x00" \
                "a\\b\\c\\d\\e\\f\\g\\h\\i\\j\\k\\l\\m\\n\\o\\p.bin\x00"

# MSZIP: the 'CK' signature and a deflate block of the byte 'A'
<mszip_cabinet> ::= <signature> <zero4> "\x4b\x00\x00\x00" <zero4> \
                    "\x2c\x00\x00\x00" <zero4> <version> "\x01\x00" \
                    "\x01\x00" "\x00\x00" <set_id> "\x00\x00" \
                    <mszip_folder> <mszip_file> <mszip_cfdata>
<mszip_folder> ::= "\x3e\x00\x00\x00" "\x01\x00" "\x01\x00"
<mszip_file> ::= "\x01\x00\x00\x00" <zero4> "\x00\x00" \
                 "\x21\x00" "\x00\x00" "\x20\x00" "z\x00"
<mszip_cfdata> ::= <zero4> "\x05\x00" "\x01\x00" "CK\x73\x04\x00"

# A folder with no data, of each compression type: none, MSZIP, Quantum
# at level 1 and 7 with memory 10 and 21 bits, LZX with windows of 15 and
# 21 bits
<compression_marker_cabinet> ::= <signature> <zero4> "\x3e\x00\x00\x00" <zero4> \
                                 "\x2c\x00\x00\x00" <zero4> <version> "\x01\x00" \
                                 "\x01\x00" "\x00\x00" <set_id> "\x00\x00" \
                                 "\x3e\x00\x00\x00" "\x00\x00" <compression_type> \
                                 <zero4> <zero4> "\x00\x00" "\x21\x00" \
                                 "\x00\x00" "\x00\x00" "q\x00"
<compression_type> ::= "\x00\x00" | "\x01\x00" | "\x12\x0a" | \
                       "\x72\x15" | "\x03\x0f" | "\x03\x15"

# Stored blocks: cbData == cbUncomp, checksum 0
<cfdata_one> ::= <zero4> "\x01\x00" "\x01\x00" <data_one>
<cfdata_two> ::= <zero4> "\x02\x00" "\x02\x00" <data_two>
<data_one> ::= <any_byte>
<data_two> ::= <any_byte>{2}

# Fields that every layout has
<signature> ::= "MSCF"
<version> ::= "\x03\x01"
<zero4> ::= "\x00\x00\x00\x00"
<set_id> ::= <any_byte>{2}
<cabinet_index> ::= "\x00\x00" | "\x01\x00" | "\x7e\x7e" | "\x7f\x7f"
<any_byte> ::= r'[\x00-\x7f]'

# The set ID is two bytes
where len(str(<set_id>)) == 2
