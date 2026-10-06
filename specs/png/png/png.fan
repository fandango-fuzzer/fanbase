# PNG: signature, IHDR, a mix of ancillary chunks, one or more IDAT, IEND.
#
# Every chunk is built by a small Python function that writes length, type,
# data and CRC-32 in one go. IHDR and IDAT agree on the image size, so the
# files decode. There is one branch per colour type (gray, gray+alpha, RGB,
# RGBA, indexed) so PLTE, tRNS, bKGD, sBIT and hIST get a shape that fits.
#
# TODO:
# * Far too many constructor functions; replace with grammar rules + constraints.
# * Try not to depend on `random`; let Fandango do this

import zlib
import random

# core chunk framing: length | type | data | CRC-32(type+data)
def mk_chunk(ctype, data):
    return (len(data).to_bytes(4, 'big') + ctype + data
            + zlib.crc32(ctype + data).to_bytes(4, 'big'))

def rnd_bytes(n):
    return bytes(random.randint(0, 255) for _ in range(n))

# PNG keyword / name field: 1..79 printable Latin-1 chars, here no NUL/space.
def kw():
    return bytes(random.randint(33, 126) for _ in range(random.randint(1, 20)))

# IHDR: width, height (4 bytes each), bit depth, colour type, compression 0,
# filter 0, interlace 0. The bit depth is picked from the ones legal for the
# colour type.

# samples per colour type: 0 gray, 2 RGB, 3 indexed, 4 gray+alpha, 6 RGBA
_SAMPLES = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}

# The IHDR helper keeps the geometry in _geom and the IDAT helper reads it back,
# so the image data has the size the header declares.
_geom = {'w': 1, 'h': 1, 'bd': 8, 'ct': 0}

def mk_ihdr(color_type, bit_depths):
    w = random.randint(1, 64)
    h = random.randint(1, 64)
    bd = random.choice(bit_depths)
    _geom.update(w=w, h=h, bd=bd, ct=color_type)
    # interlace is always 0 (no Adam7), which keeps the scanline size simple
    data = (w.to_bytes(4, 'big') + h.to_bytes(4, 'big')
            + bytes([bd, color_type, 0, 0, 0]))
    return mk_chunk(b'IHDR', data)

def mk_ihdr_gray():            return mk_ihdr(0, [1, 2, 4, 8, 16])
def mk_ihdr_truecolor():       return mk_ihdr(2, [8, 16])
def mk_ihdr_indexed():         return mk_ihdr(3, [8])   # 8-bit -> 256-entry PLTE
def mk_ihdr_gray_alpha():      return mk_ihdr(4, [8, 16])
def mk_ihdr_truecolor_alpha(): return mk_ihdr(6, [8, 16])

# PLTE: always 256 entries so hIST, bKGD and tRNS fit
def mk_plte():
    return mk_chunk(b'PLTE', rnd_bytes(768))

# IDAT: zlib stream of filtered scanlines (filter 0 on every row), split over
# 1 to 4 IDAT chunks. The size comes from the IHDR geometry.
def mk_idat_section():
    w, h, bd, ct = _geom['w'], _geom['h'], _geom['bd'], _geom['ct']
    rowbytes = (w * _SAMPLES[ct] * bd + 7) // 8
    raw = b''.join(b'\x00' + rnd_bytes(rowbytes) for _ in range(h))
    comp = zlib.compress(raw, random.randint(0, 9))
    n = random.randint(1, 4)
    if n == 1 or len(comp) <= n:
        return mk_chunk(b'IDAT', comp)
    cuts = sorted(random.sample(range(1, len(comp)), n - 1))
    parts, prev = [], 0
    for c in cuts:
        parts.append(comp[prev:c]); prev = c
    parts.append(comp[prev:])
    return b''.join(mk_chunk(b'IDAT', p) for p in parts)

def mk_iend():
    return mk_chunk(b'IEND', b'')

# colour / rendering ancillary chunks
def mk_gama():
    return mk_chunk(b'gAMA', random.randint(1, 500000).to_bytes(4, 'big'))

def mk_chrm():
    vals = [random.randint(0, 100000) for _ in range(8)]
    return mk_chunk(b'cHRM', b''.join(v.to_bytes(4, 'big') for v in vals))

def mk_srgb():
    return mk_chunk(b'sRGB', bytes([random.randint(0, 3)]))

def mk_iccp():
    prof = zlib.compress(rnd_bytes(random.randint(8, 128)))
    return mk_chunk(b'iCCP', kw() + b'\x00' + b'\x00' + prof)

def mk_phys():
    return mk_chunk(b'pHYs',
                    random.randint(1, 100000).to_bytes(4, 'big')
                    + random.randint(1, 100000).to_bytes(4, 'big')
                    + bytes([random.choice([0, 1])]))

def mk_time():
    return mk_chunk(b'tIME',
                    random.randint(1970, 2030).to_bytes(2, 'big')
                    + bytes([random.randint(1, 12), random.randint(1, 28),
                             random.randint(0, 23), random.randint(0, 59),
                             random.randint(0, 60)]))

# text chunks
def mk_text():
    txt = bytes(random.randint(32, 126) for _ in range(random.randint(0, 40)))
    return mk_chunk(b'tEXt', kw() + b'\x00' + txt)

def mk_ztxt():
    txt = bytes(random.randint(32, 126) for _ in range(random.randint(1, 60)))
    return mk_chunk(b'zTXt', kw() + b'\x00' + b'\x00' + zlib.compress(txt))

def mk_itxt():
    comp_flag = random.choice([0, 1])
    txt = bytes(random.randint(32, 126) for _ in range(random.randint(1, 60)))
    field = zlib.compress(txt) if comp_flag == 1 else txt
    lang = random.choice([b'en', b'de', b'', b'en-us'])
    trans = kw() if random.random() < 0.5 else b''
    return mk_chunk(b'iTXt',
                    kw() + b'\x00' + bytes([comp_flag, 0])
                    + lang + b'\x00' + trans + b'\x00' + field)

def mk_exif():
    endian = random.choice([b'II*\x00', b'MM\x00*'])
    return mk_chunk(b'eXIf', endian + (8).to_bytes(4, 'big')
                    + rnd_bytes(random.randint(8, 64)))

def mk_splt():
    depth = random.choice([8, 16])
    nentries = random.randint(1, 16)
    if depth == 8:
        body = b''.join(rnd_bytes(4) + random.randint(0, 65535).to_bytes(2, 'big')
                        for _ in range(nentries))
    else:
        body = b''.join(b''.join(random.randint(0, 65535).to_bytes(2, 'big')
                                 for _ in range(4))
                        + random.randint(0, 65535).to_bytes(2, 'big')
                        for _ in range(nentries))
    return mk_chunk(b'sPLT', kw() + b'\x00' + bytes([depth]) + body)

# colour-type-dependent chunks (sBIT/bKGD/tRNS/hIST)
def mk_sbit(n):
    return mk_chunk(b'sBIT', bytes(random.randint(1, 8) for _ in range(n)))

def mk_sbit_gray():        return mk_sbit(1)
def mk_sbit_rgb():         return mk_sbit(3)
def mk_sbit_gray_alpha():  return mk_sbit(2)
def mk_sbit_rgba():        return mk_sbit(4)

def mk_bkgd_gray():
    return mk_chunk(b'bKGD', random.randint(0, 65535).to_bytes(2, 'big'))
def mk_bkgd_rgb():
    return mk_chunk(b'bKGD', b''.join(random.randint(0, 65535).to_bytes(2, 'big')
                                      for _ in range(3)))
def mk_bkgd_idx():
    return mk_chunk(b'bKGD', bytes([random.randint(0, 255)]))

def mk_trns_gray():
    return mk_chunk(b'tRNS', random.randint(0, 65535).to_bytes(2, 'big'))
def mk_trns_rgb():
    return mk_chunk(b'tRNS', b''.join(random.randint(0, 65535).to_bytes(2, 'big')
                                      for _ in range(3)))
def mk_trns_idx():
    return mk_chunk(b'tRNS', rnd_bytes(random.randint(1, 256)))

def mk_hist():
    return mk_chunk(b'hIST', b''.join(random.randint(0, 65535).to_bytes(2, 'big')
                                      for _ in range(256)))

# Grammar
<start> ::= <signature> <image>

<signature> ::= rb'[\x00-\xff]*' := b'\x89PNG\r\n\x1a\n'

# Five colour-type modes: each fixes the IHDR colour type and the legal
# palette / ancillary-chunk shapes for that type.
<image> ::= <png_grayscale> \
          | <png_grayscale_alpha> \
          | <png_truecolor> \
          | <png_truecolor_alpha> \
          | <png_indexed>

# grayscale (colour type 0): no PLTE; gray bKGD/tRNS; 1-sample sBIT
<png_grayscale> ::= <ihdr_gray> <sbit_gray>? <pre_chunk>{0,4} \
                    <bkgd_gray>? <trns_gray>? <post_chunk>{0,4} \
                    <idat_section> <iend_chunk>

# grayscale + alpha (colour type 4): no PLTE, no tRNS
<png_grayscale_alpha> ::= <ihdr_gray_alpha> <sbit_gray_alpha>? <pre_chunk>{0,4} \
                          <bkgd_gray>? <post_chunk>{0,4} \
                          <idat_section> <iend_chunk>

# truecolour (colour type 2): PLTE optional; RGB bKGD/tRNS
<png_truecolor> ::= <ihdr_truecolor> <sbit_rgb>? <pre_chunk>{0,4} <plte_chunk>? \
                    <bkgd_rgb>? <trns_rgb>? <post_chunk>{0,4} \
                    <idat_section> <iend_chunk>

# truecolour + alpha (colour type 6): PLTE optional, no tRNS
<png_truecolor_alpha> ::= <ihdr_truecolor_alpha> <sbit_rgba>? <pre_chunk>{0,4} \
                          <plte_chunk>? <bkgd_rgb>? <post_chunk>{0,4} \
                          <idat_section> <iend_chunk>

# indexed (colour type 3): PLTE required, index bKGD, tRNS as alpha array,
# hIST allowed, sBIT for the source RGB (3 samples)
<png_indexed> ::= <ihdr_indexed> <sbit_rgb>? <pre_chunk>{0,4} <plte_chunk> \
                  <bkgd_idx>? <hist_chunk>? <trns_idx>? <post_chunk>{0,4} \
                  <idat_section> <iend_chunk>

# Colour-type-independent ancillary chunks that may precede PLTE/IDAT.
<pre_chunk> ::= <gama_chunk> | <chrm_chunk> | <srgb_chunk> | <iccp_chunk> \
              | <phys_chunk> | <time_chunk> | <text_chunk> | <ztxt_chunk> \
              | <itxt_chunk> | <exif_chunk> | <splt_chunk>

# Independent ancillary chunks that may also appear after PLTE (before IDAT).
<post_chunk> ::= <phys_chunk> | <time_chunk> | <text_chunk> | <ztxt_chunk> \
               | <itxt_chunk> | <exif_chunk> | <splt_chunk>

# chunk leaves, one helper call each
<ihdr_gray>            ::= rb'[\x00-\xff]*' := mk_ihdr_gray()
<ihdr_gray_alpha>      ::= rb'[\x00-\xff]*' := mk_ihdr_gray_alpha()
<ihdr_truecolor>       ::= rb'[\x00-\xff]*' := mk_ihdr_truecolor()
<ihdr_truecolor_alpha> ::= rb'[\x00-\xff]*' := mk_ihdr_truecolor_alpha()
<ihdr_indexed>         ::= rb'[\x00-\xff]*' := mk_ihdr_indexed()

<plte_chunk> ::= rb'[\x00-\xff]*' := mk_plte()
<idat_section> ::= rb'[\x00-\xff]*' := mk_idat_section()
<iend_chunk> ::= rb'[\x00-\xff]*' := mk_iend()

<gama_chunk> ::= rb'[\x00-\xff]*' := mk_gama()
<chrm_chunk> ::= rb'[\x00-\xff]*' := mk_chrm()
<srgb_chunk> ::= rb'[\x00-\xff]*' := mk_srgb()
<iccp_chunk> ::= rb'[\x00-\xff]*' := mk_iccp()
<phys_chunk> ::= rb'[\x00-\xff]*' := mk_phys()
<time_chunk> ::= rb'[\x00-\xff]*' := mk_time()
<text_chunk> ::= rb'[\x00-\xff]*' := mk_text()
<ztxt_chunk> ::= rb'[\x00-\xff]*' := mk_ztxt()
<itxt_chunk> ::= rb'[\x00-\xff]*' := mk_itxt()
<exif_chunk> ::= rb'[\x00-\xff]*' := mk_exif()
<splt_chunk> ::= rb'[\x00-\xff]*' := mk_splt()

<sbit_gray>       ::= rb'[\x00-\xff]*' := mk_sbit_gray()
<sbit_gray_alpha> ::= rb'[\x00-\xff]*' := mk_sbit_gray_alpha()
<sbit_rgb>        ::= rb'[\x00-\xff]*' := mk_sbit_rgb()
<sbit_rgba>       ::= rb'[\x00-\xff]*' := mk_sbit_rgba()

<bkgd_gray> ::= rb'[\x00-\xff]*' := mk_bkgd_gray()
<bkgd_rgb>  ::= rb'[\x00-\xff]*' := mk_bkgd_rgb()
<bkgd_idx>  ::= rb'[\x00-\xff]*' := mk_bkgd_idx()

<trns_gray> ::= rb'[\x00-\xff]*' := mk_trns_gray()
<trns_rgb>  ::= rb'[\x00-\xff]*' := mk_trns_rgb()
<trns_idx>  ::= rb'[\x00-\xff]*' := mk_trns_idx()

<hist_chunk> ::= rb'[\x00-\xff]*' := mk_hist()
