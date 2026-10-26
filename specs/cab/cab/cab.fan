# Microsoft Cabinet files of one folder, one file and one data block, stored
# (typeCompress 0, so the data is the file and cbData == cbUncomp == cbFile):
# CFHEADER, CFFOLDER, CFFILE and CFDATA. The header is plain, or declares a
# per-cabinet reserved area (RESERVE_PRESENT). The size of the cabinet, the
# offsets of the first CFFILE and of the data, the sizes and the CFDATA
# checksum are tied to the bytes by where constraints. All fields are
# little-endian.
#
# TODO:
# * No MSZIP, Quantum or LZX data, no cabinet sets (previous and next
#   cabinets), and only ever one folder, one file and one data block.
# * The folder and data reserve sizes are always 0.

import struct

# The CFDATA checksum: the XOR of the block's 32-bit little-endian words; the
# one to three bytes left over make one more word, the first of them the
# highest. The data is summed first, then cbData and cbUncomp.
def cab_cksum(data, seed):
    csum = seed
    n = len(data)
    cull = n // 4
    for i in range(cull):
        b = 4 * i
        csum ^= data[b] | (data[b + 1] << 8) | (data[b + 2] << 16) | (data[b + 3] << 24)
    rem = n % 4
    ul = 0
    base = cull * 4
    for i in range(rem):
        ul = (ul << 8) | data[base + i]
    csum ^= ul
    return csum & 0xffffffff

def cfdata_csum(ab, cb_data, cb_uncomp):
    c = cab_cksum(ab, 0)
    hdr = struct.pack('<HH', cb_data, cb_uncomp)
    return cab_cksum(hdr, c)

<start> ::= <cabinet>

<cabinet> ::= <header> <folder> <file> <data>

# CFHEADER: plain (flags 0), or with a reserved area (flags 0x0004). The
# offsets below are counted from the length of the header, whichever it is.
<header> ::= <header_plain> | <header_reserve>

<header_plain> ::= <sig> <resv4> <cb_cabinet> <resv4> <coff_files> <resv4> \
                   <ver_minor> <ver_major> <c_folders> <c_files> \
                   <flags_plain> <set_id> <i_cabinet>

<header_reserve> ::= <sig> <resv4> <cb_cabinet> <resv4> <coff_files> <resv4> \
                     <ver_minor> <ver_major> <c_folders> <c_files> \
                     <flags_reserve> <set_id> <i_cabinet> \
                     <cb_cfheader> <cb_cffolder> <cb_cfdata> <ab_reserve>

<sig>        ::= b'MSCF'
<resv4>      ::= b'\x00\x00\x00\x00'
<cb_cabinet> ::= <byte>{4}
<coff_files> ::= <byte>{4}
<ver_minor>  ::= b'\x03'
<ver_major>  ::= b'\x01'
<c_folders>  ::= b'\x01\x00'
<c_files>    ::= b'\x01\x00'
<flags_plain>   ::= b'\x00\x00'
<flags_reserve> ::= b'\x04\x00'
<set_id>     ::= <byte>{2}
<i_cabinet>  ::= b'\x00\x00'
# Only the cabinet has a reserved area: cbCFHeader is its length, and the
# folder and data reserves are 0.
<cb_cfheader> ::= <byte>{2}
<cb_cffolder> ::= b'\x00'
<cb_cfdata>   ::= b'\x00'
<ab_reserve>  ::= <byte>{1,16}

# CFFOLDER: one folder, stored
<folder> ::= <coff_cab_start> <c_cfdata> <type_compress>
<coff_cab_start> ::= <byte>{4}
<c_cfdata>       ::= b'\x01\x00'
<type_compress>  ::= b'\x00\x00'

# CFFILE: the one file fills the folder, from offset 0
<file> ::= <cb_file> <uoff_folder_start> <i_folder> <fdate> <ftime> \
           <attribs> <sz_name>
<cb_file>           ::= <byte>{4}
<uoff_folder_start> ::= b'\x00\x00\x00\x00'
<i_folder>          ::= b'\x00\x00'
<fdate>             ::= <byte>{2}
<ftime>             ::= <byte>{2}
# The attribute bits (read-only, hidden, system, archive, execute, name is
# UTF-8) are in the low byte
<attribs>           ::= rb'[\x00-\x7f]' b'\x00'
<sz_name>           ::= rb'[\x21-\x7e]{1,30}' b'\x00'

# CFDATA: one stored block
<data> ::= <csum> <cb_data> <cb_uncomp> <ab>
<csum>      ::= <byte>{4}
<cb_data>   ::= <byte>{2}
<cb_uncomp> ::= <byte>{2}
<ab>        ::= <byte>{1,64}

# Where the files and the data start, and how long the cabinet is
where <coff_files> == (len(bytes(<header>)) + len(bytes(<folder>))).to_bytes(4, 'little')
where <coff_cab_start> == (len(bytes(<header>)) + len(bytes(<folder>)) + len(bytes(<file>))).to_bytes(4, 'little')
where <cb_cabinet> == (len(bytes(<header>)) + len(bytes(<folder>)) + len(bytes(<file>)) + len(bytes(<data>))).to_bytes(4, 'little')
where <cb_cfheader> == len(bytes(<ab_reserve>)).to_bytes(2, 'little')
# The file is the data, stored
where <cb_file> == len(bytes(<ab>)).to_bytes(4, 'little')
where <cb_data> == len(bytes(<ab>)).to_bytes(2, 'little')
where <cb_uncomp> == len(bytes(<ab>)).to_bytes(2, 'little')
where <csum> == cfdata_csum(bytes(<ab>), len(bytes(<ab>)), len(bytes(<ab>))).to_bytes(4, 'little')
