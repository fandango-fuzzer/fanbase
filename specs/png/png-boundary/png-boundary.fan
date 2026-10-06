# PNG, same layout as png.fan but with values taken from the edges: 1x1 and
# prime sizes, all bit depths, gamma 0 and 0xFFFFFFFF, empty and 79 character
# keywords, a leap second in tIME, 1 and 256 palette entries, empty and split
# IDAT chunks.
#
# TODO:
# * Replace constructor functions with grammar rules + constraints
# * Try not to depend on `random`; let Fandango do this
# * Make this an extension of `png.fan` (once it has a better structure) rather than a separate spec

import zlib
import struct
import random

# geometry handed from IHDR to IDAT within one file
_geom = {}
_SAMPLES = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}   # channels per colour type

def _chunk(typ, data):
    """len(4 BE) | type | data | CRC-32(type+data) (4 BE)."""
    body = typ + data
    return (struct.pack('>I', len(data)) + body
            + struct.pack('>I', zlib.crc32(body) & 0xffffffff))

_DIMS = [1, 2, 3, 5, 7, 8, 13, 16, 17, 31, 32]        # incl. 1 & primes
_ZLEVEL = [0, 1, 6, 9]

def _pick_bd(ct):
    if ct == 0:                       # grayscale: every legal depth
        return random.choice([1, 2, 4, 8, 16])
    if ct == 3:                       # indexed: fixed 8 so palette idx 0 valid
        return 8
    return random.choice([8, 16])     # colour / alpha types: 8 or 16

def mk_ihdr(ct):
    bd = _pick_bd(ct)
    w = random.choice(_DIMS)
    h = random.choice(_DIMS)
    _geom.clear()
    _geom.update(w=w, h=h, bd=bd, ct=ct, samples=_SAMPLES[ct])
    data = struct.pack('>IIBBBBB', w, h, bd, ct,
                       0,   # compression method 0 (only legal value)
                       0,   # filter method 0 (only legal value)
                       0)   # interlace 0 (Adam7 raw-size intentionally avoided)
    return _chunk(b'IHDR', data)

def mk_idat_section():
    """Real zlib stream of an all-zero (filter 0) image, split 1..4 IDATs."""
    w, h, bd, s = _geom['w'], _geom['h'], _geom['bd'], _geom['samples']
    rowbytes = (w * s * bd + 7) // 8
    raw = (b'\x00' + b'\x00' * rowbytes) * h        # filter byte 0 + zero pixels
    comp = zlib.compress(raw, random.choice(_ZLEVEL))
    n = random.randint(1, 4)                          # faithful multi-IDAT
    if n == 1 or len(comp) < 4:
        parts = [comp]
    else:
        cuts = sorted(random.sample(range(1, len(comp)), n - 1))
        bounds = [0] + cuts + [len(comp)]
        parts = [comp[bounds[i]:bounds[i + 1]] for i in range(len(bounds) - 1)]
    # occasionally emit a spec-legal zero-length trailing IDAT
    if random.random() < 0.25:
        parts.append(b'')
    return b''.join(_chunk(b'IDAT', p) for p in parts)

def mk_plte(n_entries):
    data = bytes(random.randrange(256) for _ in range(n_entries * 3))
    return _chunk(b'PLTE', data)

def mk_gama():
    g = random.choice([0, 1, 20000, 45454, 45455, 100000, 2147483647, 4294967295])
    return _chunk(b'gAMA', struct.pack('>I', g))

def mk_chrm():
    vals = [random.choice([0, 1, 31270, 32000, 100000, 4294967295]) for _ in range(8)]
    return _chunk(b'cHRM', struct.pack('>8I', *vals))

def mk_srgb():
    return _chunk(b'sRGB', bytes([random.randint(0, 3)]))   # all 4 intents

def mk_phys():
    x = random.choice([0, 1, 2835, 4294967295])
    y = random.choice([0, 1, 2835, 4294967295])
    return _chunk(b'pHYs', struct.pack('>IIB', x, y, random.randint(0, 1)))

def mk_time():
    yr = random.choice([0, 1, 1970, 1995, 2038, 65535])
    return _chunk(b'tIME', struct.pack('>HBBBBB', yr,
                  random.choice([1, 12]), random.choice([1, 28, 31]),
                  random.choice([0, 23]), random.choice([0, 59]),
                  random.choice([0, 59, 60])))           # 60 = leap second

_KEYWORDS = [b'K', b'Title', b'Author', b'Comment', b'Copyright',
             b'Software', b'Disclaimer', b'Warning',
             b'A' * 79, b'X' * 79]                        # 1 and max(79)
def _kw():
    return random.choice(_KEYWORDS)

def mk_text():
    txt = random.choice([b'', b'x', b'hi', b'\xe9\xe0 latin1', b'z' * 200])
    return _chunk(b'tEXt', _kw() + b'\x00' + txt)

def mk_ztxt():
    txt = random.choice([b'', b'compressed text', b'q' * 500])
    return _chunk(b'zTXt', _kw() + b'\x00' + b'\x00' + zlib.compress(txt))

def mk_itxt():
    comp = random.randint(0, 1)
    txt = random.choice(['', 'unicode ☃', 'w' * 300]).encode('utf-8')
    payload = zlib.compress(txt) if comp else txt
    lang = random.choice([b'', b'en', b'en-us'])
    trans = random.choice([b'', 'Título'.encode('utf-8')])
    return _chunk(b'iTXt', _kw() + b'\x00' + bytes([comp, 0])
                  + lang + b'\x00' + trans + b'\x00' + payload)

def mk_iccp():
    prof = random.choice([b'\x00' * 132, bytes(range(60)), b'\xff' * 300])
    return _chunk(b'iCCP', b'ICC' + b'\x00' + b'\x00' + zlib.compress(prof))

def mk_exif():
    if random.random() < 0.5:
        return _chunk(b'eXIf', b'II*\x00\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    return _chunk(b'eXIf', b'MM\x00*\x00\x00\x00\x08\x00\x00\x00\x00\x00\x00')

def mk_splt():
    depth = random.choice([8, 16])
    nent = random.choice([1, 2, 256])
    if depth == 8:
        body = bytes(random.randrange(256) for _ in range(nent * 4)) \
               + b''.join(struct.pack('>H', random.choice([0, 65535])) for _ in range(nent))
        # interleave properly: entry = R G B A freq(2)
        body = b''.join(bytes(random.randrange(256) for _ in range(4))
                        + struct.pack('>H', random.choice([0, 1, 65535])) for _ in range(nent))
    else:
        body = b''.join(struct.pack('>HHHHH',
                        *[random.choice([0, 65535]) for _ in range(5)]) for _ in range(nent))
    return _chunk(b'sPLT', b'pal' + b'\x00' + bytes([depth]) + body)

# colour-type-specific ancillary (sBIT / bKGD / tRNS / hIST)
def _sig_bits(n):
    bd = _geom['bd']
    return bytes(random.randint(1, bd) for _ in range(n))   # 1..bitdepth per channel

def mk_sbit():
    ct = _geom['ct']
    n = {0: 1, 2: 3, 3: 3, 4: 2, 6: 4}[ct]
    if ct == 3:
        return _chunk(b'sBIT', bytes(random.randint(1, 8) for _ in range(3)))
    return _chunk(b'sBIT', _sig_bits(n))

def _grey_val():
    return struct.pack('>H', random.choice([0, 1, 255, 32768, 65535]))

def mk_bkgd():
    ct = _geom['ct']
    if ct in (0, 4):
        return _chunk(b'bKGD', _grey_val())
    if ct in (2, 6):
        return _chunk(b'bKGD', _grey_val() + _grey_val() + _grey_val())
    return _chunk(b'bKGD', bytes([random.choice([0, 128, 255])]))   # indexed

def mk_trns_gray():
    return _chunk(b'tRNS', _grey_val())

def mk_trns_color():
    return _chunk(b'tRNS', _grey_val() + _grey_val() + _grey_val())

def mk_trns_indexed():
    n = random.choice([1, 128, 256])
    return _chunk(b'tRNS', bytes(random.choice([0, 128, 255]) for _ in range(n)))

def mk_hist():
    return _chunk(b'hIST', b''.join(
        struct.pack('>H', random.choice([0, 1, 65535])) for _ in range(256)))

def mk_iend():
    return _chunk(b'IEND', b'')


# Grammar
<start> ::= <signature> <image>

<signature> ::= rb'[\x00-\xff]+' := b'\x89PNG\r\n\x1a\n'

<image> ::= <png_grayscale> \
          | <png_gray_alpha> \
          | <png_truecolor> \
          | <png_truecolor_alpha> \
          | <png_indexed>

# ancillary that may appear before PLTE (any colour type)
<pre_anc>  ::= <gama> | <chrm> | <srgb> | <iccp>
# ancillary that may appear after PLTE / before IDAT
<post_anc> ::= <phys> | <time> | <text> | <ztxt> | <itxt> | <exif> | <splt>

# grayscale (ct 0): no PLTE; grey tRNS/bKGD/sBIT legal
<png_grayscale> ::= <ihdr_gray> <pre_anc>{0,3} <sbit>? <trns_g>? <bkgd>? \
                    <post_anc>{0,3} <idat_section> <iend>

# grayscale+alpha (ct 4): no PLTE, no tRNS
<png_gray_alpha> ::= <ihdr_ga> <pre_anc>{0,3} <sbit>? <bkgd>? \
                     <post_anc>{0,3} <idat_section> <iend>

# truecolour (ct 2): PLTE optional (suggested palette)
<png_truecolor> ::= <ihdr_tc> <pre_anc>{0,3} <plte_opt>? <sbit>? <trns_c>? \
                    <bkgd>? <post_anc>{0,3} <idat_section> <iend>

# truecolour+alpha (ct 6): PLTE optional, no tRNS
<png_truecolor_alpha> ::= <ihdr_tca> <pre_anc>{0,3} <plte_opt>? <sbit>? \
                          <bkgd>? <post_anc>{0,3} <idat_section> <iend>

# indexed (ct 3): PLTE mandatory; hIST/indexed tRNS/bKGD legal
<png_indexed> ::= <ihdr_idx> <pre_anc>{0,3} <plte_full> <sbit>? <trns_i>? \
                  <bkgd>? <hist>? <post_anc>{0,3} <idat_section> <iend>

# IHDR leaves (one per colour type)
<ihdr_gray> ::= rb'[\x00-\xff]+' := mk_ihdr(0)
<ihdr_ga>   ::= rb'[\x00-\xff]+' := mk_ihdr(4)
<ihdr_tc>   ::= rb'[\x00-\xff]+' := mk_ihdr(2)
<ihdr_tca>  ::= rb'[\x00-\xff]+' := mk_ihdr(6)
<ihdr_idx>  ::= rb'[\x00-\xff]+' := mk_ihdr(3)

# PLTE
<plte_full> ::= rb'[\x00-\xff]+' := mk_plte(256)                 # indexed
<plte_opt>  ::= rb'[\x00-\xff]+' := mk_plte(random.choice([1, 2, 256]))

# IDAT stream + IEND
<idat_section> ::= rb'[\x00-\xff]+' := mk_idat_section()
<iend>         ::= rb'[\x00-\xff]+' := mk_iend()

# ancillary leaves
<gama> ::= rb'[\x00-\xff]+' := mk_gama()
<chrm> ::= rb'[\x00-\xff]+' := mk_chrm()
<srgb> ::= rb'[\x00-\xff]+' := mk_srgb()
<iccp> ::= rb'[\x00-\xff]+' := mk_iccp()
<phys> ::= rb'[\x00-\xff]+' := mk_phys()
<time> ::= rb'[\x00-\xff]+' := mk_time()
<text> ::= rb'[\x00-\xff]+' := mk_text()
<ztxt> ::= rb'[\x00-\xff]+' := mk_ztxt()
<itxt> ::= rb'[\x00-\xff]+' := mk_itxt()
<exif> ::= rb'[\x00-\xff]+' := mk_exif()
<splt> ::= rb'[\x00-\xff]+' := mk_splt()
<sbit> ::= rb'[\x00-\xff]+' := mk_sbit()
<bkgd> ::= rb'[\x00-\xff]+' := mk_bkgd()
<hist> ::= rb'[\x00-\xff]+' := mk_hist()
<trns_g> ::= rb'[\x00-\xff]+' := mk_trns_gray()
<trns_c> ::= rb'[\x00-\xff]+' := mk_trns_color()
<trns_i> ::= rb'[\x00-\xff]+' := mk_trns_indexed()
