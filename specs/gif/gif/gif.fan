# GIF87a / GIF89a: header, logical screen descriptor with optional global
# color table, images and extensions (graphic control, comment, plain text,
# application, NETSCAPE loop), trailer.
#
# LZW data and the color tables come from helpers so they agree with the size
# bits in the headers. Screen sizes, color indices and block lengths often
# sit on edge values (0, 1, 0xFFFF, ...).
#
# What depends on another part of the file (the color tables, the background
# color, where a frame sits and how big it is, its LZW data) is settled last,
# by consistent(), from the parts the file has: Fandango builds and recombines
# the parts of a file separately, so they cannot learn it while being made.
#
# TODO:
# * Replace constructor functions (build_*()) with grammar rules + constraints
# * Where are the docstrings for the constructor functions?
# * See Fanbase `gif-minimal.fan` and the Fandango docs GIF case study
#   for a much better structure.


<start>  ::= <gif_out>
<gif_out> ::= <gif_file> := consistent(<gif>)
<gif_file> ::= rb'(?s).+'
<gif>    ::= <header> <lsd> <body> <trailer>

# Header : version 87a (no extensions officially) vs 89a
<header>  ::= <signature> <version>
<signature> ::= rb'GIF'
<version>   ::= rb'87a' | rb'89a'

# Logical Screen Descriptor + Global Color Table
# Canvas width/height are 16-bit LE and fully decoupled from image data,
# so they roam the whole range incl. 0 and 0xFFFF.
<lsd>        ::= <canvas> <gsd_packed> <bgcolor> <aspect> <gct>
<canvas>     ::= <byte>+ := build_canvas()
<gsd_packed> ::= <byte>+ := build_gsd_packed()
<bgcolor>    ::= <byte>                   # an index, settled by consistent()
<aspect>     ::= rb'\x00' | rb'\x01' | rb'\x31' | rb'\x40' | rb'\xff' | <byte>
<gct>        ::= b''                      # made by consistent()

# Body : extensions, then >=1 image, then more blocks
<body>       ::= <extensions> <image_block> <more>
<extensions> ::= <extension>{0,4}
<more>       ::= <block>{0,3}
<block>      ::= <extension> | <image_block>

# Extensions (0x21 introducer)
<extension> ::= <gce> | <comment_ext> | <plaintext_ext> | <app_ext> | <app_netscape>

# Graphic Control Extension: fixed 4-byte block. Flags byte packs
# reserved(3) | disposal(3) | userInput(1) | transparency(1); alternation
# covers every disposal method, both flags, and set reserved bits.
<gce>        ::= rb'\x21\xf9\x04' <gce_flags> <delay> <byte> rb'\x00'
<gce_flags>  ::= rb'\x00' | rb'\x01' | rb'\x04' | rb'\x08' | rb'\x09' \
               | rb'\x0c' | rb'\x1c' | rb'\x1d' | rb'\xe5' | <byte>
<delay>      ::= <u16le>

# Comment Extension: framed sub-blocks + terminator (helper frames).
<comment_ext> ::= rb'\x21\xfe' <sub_stream>

# Plain Text Extension (89a, widely unimplemented): 12-byte grid params
# then a framed text sub-block stream.
<plaintext_ext> ::= rb'\x21\x01\x0c' <ptext_params> <sub_stream>
<ptext_params>  ::= rb'[\x00-\xff]{12}'

# Application Extension: 11-byte identifier+auth, then framed sub-blocks.
<app_ext> ::= rb'\x21\xff\x0b' <app_id> <sub_stream>
<app_id>  ::= rb'NETSCAPE2\.0' | rb'ANIMEXTS1\.0' | rb'ICCRGBG1012' \
            | rb'XMP DataXMP' | rb'fractintgif' | rb'ZGATEXTI5\x00\x00' \
            | rb'[\x20-\x7e]{11}'

# NETSCAPE looping extension with a well-formed loop sub-block
# (0x03,0x01,loopLE) + terminator. loop 0 = infinite; edge 0xFFFF.
<app_netscape> ::= rb'\x21\xff\x0bNETSCAPE2\.0\x03\x01' <loop_count> rb'\x00'
<loop_count>   ::= <u16le>

<image_block>    ::= <image_descriptor> <lct> <image_data>
<image_descriptor> ::= <byte>+ := build_image_descriptor()
<lct>            ::= b''                  # made by consistent()
<image_data>     ::= b''                  # made by consistent()

# Trailer
<trailer> ::= rb'\x3b'

<u16le>      ::= rb'\x00\x00' | rb'\x01\x00' | rb'\x64\x00' | rb'\xff\x00' \
               | rb'\x00\xff' | rb'\xff\xff' | rb'[\x00-\xff]{2}'
<sub_stream> ::= <byte>+ := build_sub_stream()
<byte>       ::= rb'[\x00-\xff]'

where True

# Helpers. The build_*() ones make a part on its own; consistent() makes the
# parts agree, in the order of the file.
import random

def build_canvas():
    cw = random.choice([1, 3, 16, 64, 200, 255, 256, 320, 65535, 0])
    ch = random.choice([1, 3, 16, 64, 200, 255, 256, 240, 65535, 0])
    return cw.to_bytes(2, 'little') + ch.to_bytes(2, 'little')

def _rgb(n):
    return bytes(random.getrandbits(8) for _ in range(3 * n))

def build_gsd_packed():
    # Global Color Table flag mostly on (so a GCT exists), sometimes off.
    flag = random.choice([1, 1, 1, 0])
    color_res = random.choice([0, 1, 3, 7, 7])          # bits 4-6
    sort = random.choice([0, 0, 1])                       # bit 3
    size = random.choice([0, 0, 1, 2, 3, 5, 7])           # bits 0-2 -> 2^(n+1)
    b = (flag << 7) | (color_res << 4) | (sort << 3) | size
    return bytes([b])

def build_image_descriptor():
    # keep pixel count small so LZW stays fast, and hit the 1px edge;
    # consistent() puts the frame inside the logical screen.
    dims = [1, 1, 2, 3, 4, 5, 8, 10, 16, 24, 32]
    iw = random.choice(dims)
    ih = random.choice(dims)
    lflag = random.choice([0, 0, 0, 1])                   # local table rare
    interlace = random.choice([0, 0, 1])
    sort = random.choice([0, 1])
    lsize = random.choice([0, 1, 2, 3, 7])
    packed = (lflag << 7) | (interlace << 6) | (sort << 5) | lsize
    return descriptor(random.randint(0, 65535), random.randint(0, 65535), iw, ih, packed)

def descriptor(left, top, iw, ih, packed):
    out = bytearray(b'\x2c')             # image separator, then L,T,W,H
    out += left.to_bytes(2, 'little')
    out += top.to_bytes(2, 'little')
    out += iw.to_bytes(2, 'little')
    out += ih.to_bytes(2, 'little')
    out.append(packed)
    return bytes(out)

def _gif_lzw(indices, min_code):
    clear = 1 << min_code
    end = clear + 1
    code_size = min_code + 1
    table = {}
    for i in range(clear):
        table[bytes([i])] = i
    next_code = clear + 2
    bit_buf = 0
    bit_cnt = 0
    out = bytearray()

    def write(code, size):
        nonlocal bit_buf, bit_cnt
        bit_buf |= code << bit_cnt
        bit_cnt += size
        while bit_cnt >= 8:
            out.append(bit_buf & 0xFF)
            bit_buf >>= 8
            bit_cnt -= 8

    write(clear, code_size)
    if indices:
        buf = bytes([indices[0]])
        for k in indices[1:]:
            cur = buf + bytes([k])
            if cur in table:
                buf = cur
            else:
                write(table[buf], code_size)
                if next_code < 4096:
                    table[cur] = next_code
                    next_code += 1
                    # GIF decoders lag one entry behind, so grow the code
                    # size only once next_code passes 2^code_size.
                    if next_code > (1 << code_size) and code_size < 12:
                        code_size += 1
                buf = bytes([k])
        write(table[buf], code_size)
    write(end, code_size)
    if bit_cnt > 0:
        out.append(bit_buf & 0xFF)
    return bytes(out)

def _frame(data):
    out = bytearray()
    i = 0
    while i < len(data):
        chunk = data[i:i + 255]
        out.append(len(chunk))
        out += chunk
        i += 255
    out.append(0)                    # block terminator
    return bytes(out)

def build_image_data(iw, ih, ncolors):
    ncolors = max(2, ncolors)
    min_code = max(2, (ncolors - 1).bit_length())
    pixels = [random.randrange(ncolors) for _ in range(iw * ih)]
    comp = _gif_lzw(pixels, min_code)
    return bytes([min_code]) + _frame(comp)

def build_sub_stream():
    length = random.choice([0, 1, 3, 254, 255, 256, 300, 510])
    payload = bytes(random.getrandbits(8) for _ in range(length))
    return _frame(payload)

def _le(data):
    return int.from_bytes(data, 'little')

def consistent(gif):
    """The file, with the parts that depend on others made from them: the
    color tables from the size bits, the background color from the global
    table, each frame inside the logical screen (a 0-size screen gives a
    0-size frame), and its LZW data from its size and its table."""
    st = {}

    def emit(node):
        name = str(node.symbol)
        if name == '<canvas>':
            data = bytes(node)
            st['cw'], st['ch'] = _le(data[0:2]), _le(data[2:4])
            return data
        if name == '<gsd_packed>':
            data = bytes(node)
            st['gflag'], st['gsize'] = data[0] >> 7, data[0] & 7
            return data
        if name == '<bgcolor>':
            n = 2 ** (st['gsize'] + 1) if st['gflag'] else 2
            return bytes([[0, n - 1, min(255, n), 255][bytes(node)[0] % 4]])
        if name == '<gct>':
            return _rgb(2 ** (st['gsize'] + 1)) if st['gflag'] else b''
        if name == '<image_descriptor>':
            data = bytes(node)
            cw, ch = st['cw'], st['ch']
            iw, ih = min(_le(data[5:7]), cw), min(_le(data[7:9]), ch)
            left = _le(data[1:3]) % (cw - iw + 1)
            top = _le(data[3:5]) % (ch - ih + 1)
            st['iw'], st['ih'], st['lflag'], st['lsize'] = iw, ih, data[9] >> 7, data[9] & 7
            return descriptor(left, top, iw, ih, data[9])
        if name == '<lct>':
            return _rgb(2 ** (st['lsize'] + 1)) if st['lflag'] else b''
        if name == '<image_data>':
            if st['lflag']:
                ncolors = 2 ** (st['lsize'] + 1)
            else:
                ncolors = 2 ** (st['gsize'] + 1) if st['gflag'] else 2
            return build_image_data(st['iw'], st['ih'], ncolors)
        out = b''
        for child in node.children:
            out += emit(child) if child.is_non_terminal else bytes(child)
        return out

    return emit(gif)
