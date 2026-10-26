# 7z archives of five kinds, each built whole by a Python function so that
# every size, offset, bit vector and CRC in it agrees: files stored with the
# Copy coder, each in its own folder; one file compressed with LZMA (a real
# stream from Python's lzma, with its coder properties); a real file, an
# empty file and a directory, which use the kEmptyStream and kEmptyFile bit
# vectors, with modification times, Windows attributes and kDummy padding; an
# empty archive (no streams, no files); and an archive whose header is itself
# a packed stream (kEncodedHeader). Sizes are written as 7z numbers of any
# length.
#
# TODO:
# * The grammar only picks one of the five kinds: what is inside an archive
#   comes from the Python functions, so Fandango cannot vary its structure or
#   parse a 7z file with it.
# * Copy and LZMA only: no LZMA2, PPMd, BZip2, Deflate, filters or
#   encryption.

import struct, random, zlib, lzma

SIG = bytes([0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C])

def w_num(value):
    # 7z variable-length "number" encoding (CInArchive::ReadNumber inverse).
    firstByte = 0
    mask = 0x80
    i = 0
    while i < 8:
        if value < (1 << (7 * (i + 1))):
            firstByte |= (value >> (8 * i)) & 0xff
            break
        firstByte |= mask
        mask >>= 1
        i += 1
    res = bytearray([firstByte])
    v = value
    for _ in range(i):
        res.append(v & 0xff)
        v >>= 8
    return bytes(res)

def bit_vector(bits):
    # MSB-first bit packing, as 7z uses for its boolean vectors.
    out = bytearray()
    b = 0
    mask = 0x80
    for bit in bits:
        if bit:
            b |= mask
        mask >>= 1
        if mask == 0:
            out.append(b)
            b = 0
            mask = 0x80
    if mask != 0x80:
        out.append(b)
    return bytes(out)

def folder_copy():
    # One Copy coder (ID 0x00): flags 0x01, an ID of one byte, simple, no
    # properties.
    return w_num(1) + bytes([0x01, 0x00])

def folder_lzma(props):
    # One LZMA coder (ID 03 01 01): flags 0x23, an ID of three bytes, with
    # properties.
    return w_num(1) + bytes([0x23, 0x03, 0x01, 0x01]) + w_num(len(props)) + props

def crc_block(crcs):
    out = bytearray([0x0A, 0x01])  # kCRC, AllAreDefined = 1
    for c in crcs:
        out += struct.pack('<I', c & 0xffffffff)
    return bytes(out)

def pack_info(pack_pos, pack_sizes):
    out = bytearray([0x06])                # kPackInfo
    out += w_num(pack_pos)                 # PackPos (relative to end of SignatureHeader)
    out += w_num(len(pack_sizes))          # NumPackStreams
    out.append(0x09)                       # kSize
    for s in pack_sizes:
        out += w_num(s)
    out.append(0x00)                       # kEnd
    return bytes(out)

def unpack_info(folders, unpack_sizes):
    out = bytearray([0x07, 0x0B])          # kUnpackInfo, kFolder
    out += w_num(len(folders))             # NumFolders
    out.append(0x00)                       # External = 0 (folders stored inline)
    for f in folders:
        out += f
    out.append(0x0C)                       # kCodersUnpackSize
    for s in unpack_sizes:
        out += w_num(s)
    out.append(0x00)                       # kEnd
    return bytes(out)

def substreams_info(nups, crcs):
    out = bytearray([0x08, 0x0D])          # kSubStreamsInfo, kNumUnpackStream
    for n in nups:
        out += w_num(n)
    out += crc_block(crcs)                 # kCRC over the unpacked substreams
    out.append(0x00)                       # kEnd
    return bytes(out)

def streams_info(pp, ps, folders, us, nups, crcs):
    return pack_info(pp, ps) + unpack_info(folders, us) + substreams_info(nups, crcs) + bytes([0x00])

def names_utf16(names):
    out = bytearray()
    for n in names:
        out += n.encode('utf-16-le') + b'\x00\x00'   # NUL-terminated UTF-16LE
    return bytes(out)

def files_info(names, empty_stream, empty_file, mtimes, attrs, dummy):
    out = bytearray([0x05])                # kFilesInfo
    out += w_num(len(names))               # NumFiles
    if empty_stream and any(empty_stream):
        bv = bit_vector(empty_stream)
        out.append(0x0E); out += w_num(len(bv)); out += bv          # kEmptyStream
        if empty_file and any(empty_file):
            bv2 = bit_vector(empty_file)
            out.append(0x0F); out += w_num(len(bv2)); out += bv2    # kEmptyFile
    nd = b'\x00' + names_utf16(names)      # External = 0, then names
    out.append(0x11); out += w_num(len(nd)); out += nd             # kName
    if mtimes:
        body = bytearray([0x01, 0x00])     # AllAreDefined = 1, External = 0
        for t in mtimes:
            body += struct.pack('<Q', t)   # Windows FILETIME, 100ns ticks
        out.append(0x14); out += w_num(len(body)); out += body     # kMTime
    if attrs:
        body = bytearray([0x01, 0x00])
        for a in attrs:
            body += struct.pack('<I', a)
        out.append(0x15); out += w_num(len(body)); out += body     # kWinAttributes
    if dummy:
        out.append(0x19); out += w_num(dummy); out += b'\x00' * dummy   # kDummy padding
    out.append(0x00)                       # kEnd
    return bytes(out)

def header(si, fi):
    out = bytearray([0x01])                # kHeader
    if si:
        out.append(0x04); out += si        # kMainStreamsInfo + StreamsInfo
    if fi:
        out += fi
    out.append(0x00)                       # kEnd
    return bytes(out)

def finalize(packed, hdr):
    sh = struct.pack('<QQI', len(packed), len(hdr), zlib.crc32(hdr) & 0xffffffff)
    return (SIG + bytes([0x00, 0x04])
            + struct.pack('<I', zlib.crc32(sh) & 0xffffffff)
            + sh + packed + hdr)

def rnd(lo, hi):
    return bytes(random.randint(0, 255) for _ in range(random.randint(lo, hi)))

# The five kinds of archive

def build_copy():
    # 1..4 files, each its own folder / pack stream, Copy coder.
    n = random.randint(1, 4)
    datas = [rnd(1, 40) for _ in range(n)]
    names = ["f%d.bin" % i for i in range(n)]
    si = streams_info(0, [len(d) for d in datas], [folder_copy()] * n,
                      [len(d) for d in datas], [1] * n,
                      [zlib.crc32(d) for d in datas])
    return finalize(b''.join(datas), header(si, files_info(names, None, None, None, None, 0)))

def build_lzma():
    # An LZMA stream: in the FORMAT_ALONE header, the first 5 bytes are the
    # coder properties (lc/lp/pb, dictionary size); after its 13 bytes comes
    # the packed stream.
    data = rnd(20, 250)
    comp = lzma.compress(data, format=lzma.FORMAT_ALONE)
    props, raw = comp[0:5], comp[13:]
    si = streams_info(0, [len(raw)], [folder_lzma(props)], [len(data)], [1],
                      [zlib.crc32(data)])
    return finalize(raw, header(si, files_info(["big.dat"], None, None, None, None, 0)))

def build_empty():
    # A file, an empty file and a directory, so the empty-stream and
    # empty-file bit vectors, with kMTime, kWinAttributes and kDummy.
    data = rnd(5, 30)
    names = ["real.txt", "empty.txt", "adir"]
    si = streams_info(0, [len(data)], [folder_copy()], [len(data)], [1], [zlib.crc32(data)])
    fi = files_info(names, [0, 1, 1], [1, 0],
                    [131000000000000000 + i * 10000000 for i in range(3)],
                    [0x20, 0x20, 0x10], random.randint(1, 3))
    return finalize(data, header(si, fi))

def build_emptyarch():
    # No streams, no files: NextHeaderOffset 0, and the header is kHeader kEnd.
    return finalize(b'', bytes([0x01, 0x00]))

def build_encoded():
    # kEncodedHeader: the header is stored as a Copy-coded pack stream after the
    # file's data, and the header at the end only says where it is.
    data = rnd(10, 60)
    inner = header(streams_info(0, [len(data)], [folder_copy()], [len(data)], [1],
                                [zlib.crc32(data)]),
                   files_info(["enc.bin"], None, None, None, [0x2020], 0))
    outer_si = streams_info(len(data), [len(inner)], [folder_copy()], [len(inner)], [1],
                            [zlib.crc32(inner)])
    return finalize(data + inner, bytes([0x17]) + outer_si)

# One of the five kinds, made by its function; <blob> is what the function
# returns

<start>   ::= <sevenz>
<sevenz>  ::= <f_copy> | <f_lzma> | <f_empty> | <f_emptyarch> | <f_encoded>
<f_copy>      ::= <blob> := build_copy()
<f_lzma>      ::= <blob> := build_lzma()
<f_empty>     ::= <blob> := build_empty()
<f_emptyarch> ::= <blob> := build_emptyarch()
<f_encoded>   ::= <blob> := build_encoded()
<blob>    ::= <byte>+
<byte>    ::= rb'(?s).'
