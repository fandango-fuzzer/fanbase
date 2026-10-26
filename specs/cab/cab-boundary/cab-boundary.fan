# Cabinet files of four kinds, each with fields at the edges of the format: a
# cabinet of one stored file and block, with the CFDATA checksum; one with
# reserved areas in the header (of up to 12 bytes), the folder and the data
# block, LZX with a 2 MB window as its compression and no checksum; one that
# is part of a set, with the names of the previous and next cabinets and disks
# and a file that continues from or into them (iFolder 0xFFFD, 0xFFFE or
# 0xFFFF); and one of two folders, stored and MSZIP, each with its file and
# checksummed block. Dates, times, attributes, set IDs and cabinet numbers
# take their extreme values. The size of the cabinet, the offsets of the files
# and of the data, the sizes and the checksums are tied to the bytes by where
# constraints.
#
# TODO:
# * The data of the LZX and MSZIP folders is random bytes, so it does not
#   decompress, and the files of a set refer to cabinets that are not there.

# Integers are little-endian
def u16le(n):
    return (n & 0xFFFF).to_bytes(2, "little")

def u32le(n):
    return (n & 0xFFFFFFFF).to_bytes(4, "little")

# The CFDATA checksum (as cabinet.dll and libmspack compute it): the XOR
# of the block's 32-bit little-endian words, the one to three bytes left
# over making one more word with the first of them the highest; the data
# is summed first, and its sum is the seed for cbData and cbUncomp. Stored
# blocks have cbData == cbUncomp.
def cab_csum(data):
    data = bytes(data)

    def wordxor(buf, seed):
        c = seed
        n = len(buf)
        full = n & ~3
        for i in range(0, full, 4):
            c ^= buf[i] | (buf[i + 1] << 8) | (buf[i + 2] << 16) | (buf[i + 3] << 24)
        rem = n & 3
        ul = 0
        if rem == 3:
            ul |= buf[full] << 16
            ul |= buf[full + 1] << 8
            ul |= buf[full + 2]
        elif rem == 2:
            ul |= buf[full] << 8
            ul |= buf[full + 1]
        elif rem == 1:
            ul |= buf[full]
        return (c ^ ul) & 0xFFFFFFFF

    cb = len(data) & 0xFFFF
    seed = wordxor(data, 0)
    hdr = cb.to_bytes(2, "little") + cb.to_bytes(2, "little")
    return wordxor(hdr, seed).to_bytes(4, "little")

# One cabinet of one of the four kinds
<start> ::= <cab_basic> | <cab_reserve> | <cab_span> | <cab_multi>

# One folder, one file, one stored block with its checksum. The first
# CFFILE is at 44 (a 36-byte header and an 8-byte folder).
<cab_basic> ::= b'MSCF' b'\x00\x00\x00\x00' <cbCab1> b'\x00\x00\x00\x00' b'\x2c\x00\x00\x00' b'\x00\x00\x00\x00' b'\x03' b'\x01' b'\x01\x00' b'\x01\x00' b'\x00\x00' <setid> <icab> \
    <coffData1> b'\x01\x00' b'\x00\x00' \
    <cbFile1> b'\x00\x00\x00\x00' b'\x00\x00' <dosdate> <dostime> <attr> <name1> \
    <csum1> <cbData1> <cbUncomp1> <data1>

where bytes(<coffData1>) == u32le(60 + len(bytes(<name1>)))
where bytes(<cbCab1>) == u32le(68 + len(bytes(<name1>)) + len(bytes(<data1>)))
where bytes(<cbFile1>) == u32le(len(bytes(<data1>)))
where bytes(<cbData1>) == u16le(len(bytes(<data1>)))
where bytes(<cbUncomp1>) == u16le(len(bytes(<data1>)))
where bytes(<csum1>) == cab_csum(bytes(<data1>))

<cbCab1> ::= <byte>{4}
<coffData1> ::= <byte>{4}
<cbFile1> ::= <byte>{4}
<csum1> ::= <byte>{4}
<cbData1> ::= <byte>{2}
<cbUncomp1> ::= <byte>{2}
<data1> ::= <byte>{1,24}
<name1> ::= <fname> b'\x00'

# Reserved areas (flags 0x0004): cbCFHeader bytes after the header, two
# after the folder and four after the data block's header. LZX with a 21-bit
# window (0x1503), checksum 0. With the reserve sizes the header is 40 bytes:
# the first CFFILE is at 50 + the header's reserve, the data at 16 + the name
# after that.
<cab_reserve> ::= b'MSCF' b'\x00\x00\x00\x00' <cbCab2> b'\x00\x00\x00\x00' <coffFiles2> b'\x00\x00\x00\x00' b'\x03' b'\x01' b'\x01\x00' b'\x01\x00' b'\x04\x00' <setid> <icab> <cbHdr2> b'\x02' b'\x04' <resh2> \
    <coffData2> b'\x01\x00' b'\x03\x15' <resf2> \
    <cbFile2> b'\x00\x00\x00\x00' b'\x00\x00' <dosdate> <dostime> <attr> <name2> \
    b'\x00\x00\x00\x00' <cbData2> <cbUncomp2> <resd2> <data2>

where bytes(<cbHdr2>) == u16le(len(bytes(<resh2>)))
where bytes(<coffFiles2>) == u32le(50 + len(bytes(<resh2>)))
where bytes(<coffData2>) == u32le(66 + len(bytes(<resh2>)) + len(bytes(<name2>)))
where bytes(<cbCab2>) == u32le(78 + len(bytes(<resh2>)) + len(bytes(<name2>)) + len(bytes(<data2>)))
where bytes(<cbFile2>) == u32le(len(bytes(<data2>)))
where bytes(<cbData2>) == u16le(len(bytes(<data2>)))
where bytes(<cbUncomp2>) == u16le(len(bytes(<data2>)))

<cbCab2> ::= <byte>{4}
<coffFiles2> ::= <byte>{4}
<coffData2> ::= <byte>{4}
<cbFile2> ::= <byte>{4}
<cbHdr2> ::= <byte>{2}
<cbData2> ::= <byte>{2}
<cbUncomp2> ::= <byte>{2}
<resh2> ::= <byte>{0,12}
<resf2> ::= <byte>{2}
<resd2> ::= <byte>{4}
<data2> ::= <byte>{1,24}
<name2> ::= <fname> b'\x00'

# Part of a set (flags 0x0003): the names of the previous and next
# cabinets and their disks follow the header, and the file continues from
# the previous cabinet, into the next, or both (iFolder 0xFFFD, 0xFFFE,
# 0xFFFF).
<cab_span> ::= b'MSCF' b'\x00\x00\x00\x00' <cbCab3> b'\x00\x00\x00\x00' <coffFiles3> b'\x00\x00\x00\x00' b'\x03' b'\x01' b'\x01\x00' b'\x01\x00' b'\x03\x00' <setid> <icab> \
    <cabprev3> <diskprev3> <cabnext3> <disknext3> \
    <coffData3> b'\x01\x00' b'\x00\x00' \
    <cbFile3> b'\x00\x00\x00\x00' <ifolder3> <dosdate> <dostime> <attr> <name3> \
    <csum3> <cbData3> <cbUncomp3> <data3>

where bytes(<coffFiles3>) == u32le(44 + len(bytes(<cabprev3>)) + len(bytes(<diskprev3>)) + len(bytes(<cabnext3>)) + len(bytes(<disknext3>)))
where bytes(<coffData3>) == u32le(60 + len(bytes(<cabprev3>)) + len(bytes(<diskprev3>)) + len(bytes(<cabnext3>)) + len(bytes(<disknext3>)) + len(bytes(<name3>)))
where bytes(<cbCab3>) == u32le(68 + len(bytes(<cabprev3>)) + len(bytes(<diskprev3>)) + len(bytes(<cabnext3>)) + len(bytes(<disknext3>)) + len(bytes(<name3>)) + len(bytes(<data3>)))
where bytes(<cbFile3>) == u32le(len(bytes(<data3>)))
where bytes(<cbData3>) == u16le(len(bytes(<data3>)))
where bytes(<cbUncomp3>) == u16le(len(bytes(<data3>)))
where bytes(<csum3>) == cab_csum(bytes(<data3>))

<cbCab3> ::= <byte>{4}
<coffFiles3> ::= <byte>{4}
<coffData3> ::= <byte>{4}
<cbFile3> ::= <byte>{4}
<csum3> ::= <byte>{4}
<cbData3> ::= <byte>{2}
<cbUncomp3> ::= <byte>{2}
<data3> ::= <byte>{1,24}
<name3> ::= <fname> b'\x00'
<ifolder3> ::= b'\xfd\xff' | b'\xfe\xff' | b'\xff\xff'
<cabprev3> ::= <fname> b'\x00'
<diskprev3> ::= <dname> b'\x00'
<cabnext3> ::= <fname> b'\x00'
<disknext3> ::= <dname> b'\x00'

# Two folders, stored and MSZIP, two files and two blocks, each block
# with its checksum. The first CFFILE is at 52 (a header and two folders).
<cab_multi> ::= b'MSCF' b'\x00\x00\x00\x00' <cbCab4> b'\x00\x00\x00\x00' b'\x34\x00\x00\x00' b'\x00\x00\x00\x00' b'\x03' b'\x01' b'\x02\x00' b'\x02\x00' b'\x00\x00' <setid> <icab> \
    <coffData4a> b'\x01\x00' b'\x00\x00' \
    <coffData4b> b'\x01\x00' b'\x01\x00' \
    <cbFile4a> b'\x00\x00\x00\x00' b'\x00\x00' <dosdate> <dostime> <attr> <name4a> \
    <cbFile4b> b'\x00\x00\x00\x00' b'\x01\x00' <dosdate> <dostime> <attr> <name4b> \
    <csum4a> <cbData4a> <cbUncomp4a> <data4a> \
    <csum4b> <cbData4b> <cbUncomp4b> <data4b>

where bytes(<coffData4a>) == u32le(84 + len(bytes(<name4a>)) + len(bytes(<name4b>)))
where bytes(<coffData4b>) == u32le(92 + len(bytes(<name4a>)) + len(bytes(<name4b>)) + len(bytes(<data4a>)))
where bytes(<cbCab4>) == u32le(100 + len(bytes(<name4a>)) + len(bytes(<name4b>)) + len(bytes(<data4a>)) + len(bytes(<data4b>)))
where bytes(<cbFile4a>) == u32le(len(bytes(<data4a>)))
where bytes(<cbFile4b>) == u32le(len(bytes(<data4b>)))
where bytes(<cbData4a>) == u16le(len(bytes(<data4a>)))
where bytes(<cbUncomp4a>) == u16le(len(bytes(<data4a>)))
where bytes(<csum4a>) == cab_csum(bytes(<data4a>))
where bytes(<cbData4b>) == u16le(len(bytes(<data4b>)))
where bytes(<cbUncomp4b>) == u16le(len(bytes(<data4b>)))
where bytes(<csum4b>) == cab_csum(bytes(<data4b>))

<cbCab4> ::= <byte>{4}
<coffData4a> ::= <byte>{4}
<coffData4b> ::= <byte>{4}
<cbFile4a> ::= <byte>{4}
<cbFile4b> ::= <byte>{4}
<csum4a> ::= <byte>{4}
<csum4b> ::= <byte>{4}
<cbData4a> ::= <byte>{2}
<cbUncomp4a> ::= <byte>{2}
<cbData4b> ::= <byte>{2}
<cbUncomp4b> ::= <byte>{2}
<data4a> ::= <byte>{1,24}
<data4b> ::= <byte>{1,24}
<name4a> ::= <fname> b'\x00'
<name4b> ::= <fname> b'\x00'

# Names, dates and times (0, the first valid value, and all bits set),
# attributes (read-only, hidden, system, archive, execute, name is UTF-8,
# and all of them), set IDs and cabinet numbers
<fname> ::= rb'[A-Za-z0-9._\\-]{1,12}'
<dname> ::= rb'[A-Za-z0-9 ._-]{1,8}'

<dosdate> ::= b'\x00\x00' | b'\x21\x00' | b'\xff\xff'
<dostime> ::= b'\x00\x00' | b'\x00\x60' | b'\xff\xbf'

<attr> ::= b'\x00\x00' | b'\x01\x00' | b'\x02\x00' | b'\x04\x00' | b'\x20\x00' | b'\x40\x00' | b'\x80\x00' | b'\xe7\x00'

<setid> ::= b'\x00\x00' | b'\x34\x12' | b'\xff\xff'
<icab> ::= b'\x00\x00' | b'\x01\x00' | b'\xff\xff'

<byte> ::= rb'[\x00-\xff]'
