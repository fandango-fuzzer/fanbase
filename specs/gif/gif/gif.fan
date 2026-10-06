# GIF87a / GIF89a: header, logical screen descriptor with optional global
# color table, images and extensions (graphic control, comment, plain text,
# application, NETSCAPE loop), trailer.
#
# LZW data and the color tables come from helpers so they agree with the size
# bits in the headers. Screen sizes, color indices and block lengths often
# sit on edge values (0, 1, 0xFFFF, ...).
#
# TODO:
# * Replace constructor functions (build_*()) with grammar rules + constraints
# * Where are the docstrings for the constructor functions?
# * See Fanbase `gif-minimal.fan` and the Fandango docs GIF case study
#   for a much better structure.


<start>  ::= <gif>
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
<bgcolor>    ::= <byte>+ := build_bgcolor()
<aspect>     ::= rb'\x00' | rb'\x01' | rb'\x31' | rb'\x40' | rb'\xff' | <byte>
<gct>        ::= <byte>* := build_gct()

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
<lct>            ::= <byte>* := build_lct()
<image_data>     ::= <byte>+ := build_image_data()

# Trailer
<trailer> ::= rb'\x3b'

<u16le>      ::= rb'\x00\x00' | rb'\x01\x00' | rb'\x64\x00' | rb'\xff\x00' \
               | rb'\x00\xff' | rb'\xff\xff' | rb'[\x00-\xff]{2}'
<sub_stream> ::= <byte>+ := build_sub_stream()
<byte>       ::= rb'[\x00-\xff]'

where True

# Helpers. _S carries per-image / per-file geometry between the
# left-to-right generated symbols (set before the symbol that reads it).
import random

_S = {}

def build_canvas():
    cw = random.choice([1, 3, 16, 64, 200, 255, 256, 320, 65535, 0])
    ch = random.choice([1, 3, 16, 64, 200, 255, 256, 240, 65535, 0])
    _S['cw'], _S['ch'] = cw, ch
    return cw.to_bytes(2, 'little') + ch.to_bytes(2, 'little')

def _rgb(n):
    return bytes(random.getrandbits(8) for _ in range(3 * n))

def build_gsd_packed():
    # Global Color Table flag mostly on (so a GCT exists), sometimes off.
    flag = random.choice([1, 1, 1, 0])
    color_res = random.choice([0, 1, 3, 7, 7])          # bits 4-6
    sort = random.choice([0, 0, 1])                       # bit 3
    size = random.choice([0, 0, 1, 2, 3, 5, 7])           # bits 0-2 -> 2^(n+1)
    _S['gflag'] = flag
    _S['gsize'] = size
    _S['gncolors'] = (2 ** (size + 1)) if flag else 2
    b = (flag << 7) | (color_res << 4) | (sort << 3) | size
    return bytes([b])

def build_bgcolor():
    n = _S.get('gncolors', 2)
    return bytes([random.choice([0, n - 1, min(255, n), 255])])

def build_gct():
    if not _S.get('gflag'):
        _S['gncolors'] = 2
        return b''
    return _rgb(2 ** (_S['gsize'] + 1))

def build_image_descriptor():
    cw, ch = _S.get('cw', 0), _S.get('ch', 0)
    # keep pixel count small so LZW stays fast; hit the 1px edge but keep frames
    # >=1 (a 0-size frame only arises from a 0-size screen), then clamp the frame
    # inside the logical screen so the file stays spec-valid.
    dims = [1, 1, 2, 3, 4, 5, 8, 10, 16, 24, 32]
    iw = min(random.choice(dims), cw)
    ih = min(random.choice(dims), ch)
    while iw * ih > 1024:
        ih = min(random.choice(dims), ch)
    left = random.randint(0, max(0, cw - iw))
    top = random.randint(0, max(0, ch - ih))
    lflag = random.choice([0, 0, 0, 1])                   # local table rare
    interlace = random.choice([0, 0, 1])
    sort = random.choice([0, 1])
    lsize = random.choice([0, 1, 2, 3, 7])
    _S['iw'], _S['ih'] = iw, ih
    _S['lflag'], _S['lsize'], _S['interlace'] = lflag, lsize, interlace
    packed = (lflag << 7) | (interlace << 6) | (sort << 5) | lsize
    out = bytearray(b'\x2c')             # image separator, then L,T,W,H
    out += left.to_bytes(2, 'little')
    out += top.to_bytes(2, 'little')
    out += iw.to_bytes(2, 'little')
    out += ih.to_bytes(2, 'little')
    out.append(packed)
    return bytes(out)

def build_lct():
    if not _S.get('lflag'):
        _S['ncolors'] = _S.get('gncolors', 2)
        return b''
    n = 2 ** (_S['lsize'] + 1)
    _S['ncolors'] = n
    return _rgb(n)

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

def build_image_data():
    iw, ih = _S.get('iw', 1), _S.get('ih', 1)
    ncolors = max(2, _S.get('ncolors', 2))
    min_code = max(2, (ncolors - 1).bit_length())
    pixels = [random.randrange(ncolors) for _ in range(iw * ih)]
    comp = _gif_lzw(pixels, min_code)
    return bytes([min_code]) + _frame(comp)

def build_sub_stream():
    length = random.choice([0, 1, 3, 254, 255, 256, 300, 510])
    payload = bytes(random.getrandbits(8) for _ in range(length))
    return _frame(payload)
