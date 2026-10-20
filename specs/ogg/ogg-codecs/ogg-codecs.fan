# Ogg streams of five codecs: Vorbis, Opus, Theora, Speex and FLAC, each with
# its identification and comment headers (and a setup header for Vorbis and
# Theora), audio pages whose packets of up to 700 bytes may go on to the next
# page, and an end-of-stream page. Pages are made by helpers that keep the
# lacing values, sequence numbers, granule positions and CRC-32 right.
#
# TODO:
# * Pages come from helpers (:= make_*()), not from grammar rules: rewrite
#   them as rules and constraints.
# * The Vorbis and Theora setup headers, the FLAC STREAMINFO fields and all
#   audio packets are random bytes, so only some Opus and Speex files decode.

import random

# CRC-32/OGG (poly 0x04c11db7, MSB-first, init 0, no reflect/xor)
_CRC_TABLE = []
for _i in range(256):
    _r = _i << 24
    for _ in range(8):
        _r = ((_r << 1) ^ 0x04c11db7) & 0xffffffff if (_r & 0x80000000) else ((_r << 1) & 0xffffffff)
    _CRC_TABLE.append(_r)

def ogg_crc(data):
    c = 0
    for b in data:
        c = ((c << 8) & 0xffffffff) ^ _CRC_TABLE[((c >> 24) & 0xff) ^ b]
    return c

# The state of the stream being made, reset by each identification page.
# Pages are made from left to right, so the serial number stays the same,
# sequence numbers count up from 0, granule positions do not go down, and a
# packet left open at the end of a page is closed on the next one.
_ST = {"serial": 0, "seq": 0, "gran": 0, "carry": 0, "codec": ""}

def _rb(n):
    return bytes(random.randint(0, 255) for _ in range(n))

def _lace_complete(n):
    # lacing values for a packet of n bytes that ENDS on this page
    return [255] * (n // 255) + [n % 255]

def _emit(htype, granule, lacing, body):
    assert len(lacing) <= 255
    hdr = (b'OggS' + bytes([0, htype])
           + (granule & 0xffffffffffffffff).to_bytes(8, 'little')
           + _ST["serial"].to_bytes(4, 'little')
           + _ST["seq"].to_bytes(4, 'little'))
    crc = ogg_crc(hdr + b'\x00\x00\x00\x00' + bytes([len(lacing)]) + bytes(lacing) + bytes(body))
    _ST["seq"] += 1
    return hdr + crc.to_bytes(4, 'little') + bytes([len(lacing)]) + bytes(lacing) + bytes(body)

def _header_page(body, bos):
    # a page carrying exactly one complete header packet, granule 0
    return _emit(2 if bos else 0, 0, _lace_complete(len(body)), body)

# Vorbis-comment block (also used by Opus, Theora, Speex, FLAC)
def _vc(vendor, comments):
    out = len(vendor).to_bytes(4, 'little') + vendor
    out += len(comments).to_bytes(4, 'little')
    for c in comments:
        out += len(c).to_bytes(4, 'little') + c
    return out

_VENDOR = b'Fandango libVorbis'
_TAGS = [b'TITLE=Test', b'ARTIST=Fandango', b'ENCODER=fandango-ogg']

# codec identification headers
def make_vorbis_id():
    _reset("vorbis")
    body = (b'\x01vorbis'
            + (0).to_bytes(4, 'little')              # vorbis version
            + bytes([random.choice([1, 2])])          # channels
            + random.choice([8000, 22050, 44100, 48000]).to_bytes(4, 'little')  # sample rate
            + (0).to_bytes(4, 'little', signed=True)  # bitrate maximum
            + (128000).to_bytes(4, 'little')          # bitrate nominal
            + (0).to_bytes(4, 'little', signed=True)  # bitrate minimum
            + bytes([0xb8])                           # blocksize_0/1 (256/2048)
            + bytes([0x01]))                          # framing flag
    return _header_page(body, True)

def make_vorbis_comment():
    return _header_page(b'\x03vorbis' + _vc(_VENDOR, _TAGS) + b'\x01', False)

def make_vorbis_setup():
    # random bytes where the codebooks would be
    return _header_page(b'\x05vorbis' + _rb(random.randint(40, 200)) + b'\x01', False)

def make_opus_id():
    _reset("opus")
    body = (b'OpusHead'
            + bytes([1])                              # version
            + bytes([random.choice([1, 2])])          # channel count
            + random.randint(0, 3840).to_bytes(2, 'little')  # pre-skip
            + (48000).to_bytes(4, 'little')           # input sample rate
            + (0).to_bytes(2, 'little', signed=True)  # output gain
            + bytes([0]))                             # mapping family
    return _header_page(body, True)

def make_opus_comment():
    return _header_page(b'OpusTags' + _vc(_VENDOR, _TAGS), False)

def make_theora_id():
    _reset("theora")
    body = (b'\x80theora'
            + bytes([3, 2, 1])                        # version major/minor/rev
            + (40).to_bytes(2, 'big') + (30).to_bytes(2, 'big')   # width/height in macroblocks
            + (640).to_bytes(3, 'big') + (480).to_bytes(3, 'big')  # frame w/h
            + bytes([0, 0])                           # x/y offset
            + (30).to_bytes(4, 'big') + (1).to_bytes(4, 'big')     # fps num/den
            + (1).to_bytes(3, 'big') + (1).to_bytes(3, 'big')      # aspect num/den
            + bytes([0, 0, 0])                        # colorspace/target bitrate hi
            + bytes([0, 0])                           # quality / gp shift+pf+rsv
            + b'\x00')
    return _header_page(body, True)

def make_theora_comment():
    return _header_page(b'\x81theora' + _vc(_VENDOR, _TAGS), False)

def make_theora_setup():
    return _header_page(b'\x82theora' + _rb(random.randint(40, 200)), False)

def make_speex_id():
    _reset("speex")
    verstr = b'speex-1.2'.ljust(20, b'\x00')
    body = (b'Speex   '                               # speex_string (5+3 spaces)
            + verstr                                  # speex_version (20)
            + (1).to_bytes(4, 'little')               # speex_version_id
            + (80).to_bytes(4, 'little')              # header_size
            + random.choice([8000, 16000, 32000]).to_bytes(4, 'little')  # rate
            + (0).to_bytes(4, 'little')               # mode
            + (4).to_bytes(4, 'little')               # mode_bitstream_version
            + bytes([random.choice([1, 2])]) + b'\x00\x00\x00'  # nb_channels
            + (0xffffffff).to_bytes(4, 'little')      # bitrate (-1)
            + (160).to_bytes(4, 'little')             # frame_size
            + (0).to_bytes(4, 'little')               # vbr
            + (1).to_bytes(4, 'little')               # frames_per_packet
            + (0).to_bytes(4, 'little')               # extra_headers
            + (0).to_bytes(4, 'little')               # reserved1
            + (0).to_bytes(4, 'little'))              # reserved2
    return _header_page(body, True)

def make_speex_comment():
    # Speex comment packet is a bare Vorbis-comment block
    return _header_page(_vc(_VENDOR, _TAGS), False)

def make_flac_id():
    _reset("flac")
    streaminfo = (bytes([0x80, 0, 0, 34])             # metadata block: last=1, type=0, length=34
                  + (4096).to_bytes(2, 'big')          # min block size
                  + (4096).to_bytes(2, 'big')          # max block size
                  + (0).to_bytes(3, 'big')             # min frame size
                  + (0).to_bytes(3, 'big')             # max frame size
                  + _rb(8)                             # sample rate/chan/bps/total (packed)
                  + _rb(16))                           # MD5 of unencoded audio
    body = (b'\x7fFLAC'                                # FLAC-in-Ogg mapping marker
            + bytes([1, 0])                            # mapping version 1.0
            + (1).to_bytes(2, 'big')                   # number of non-audio header packets
            + b'fLaC'                                   # native FLAC signature
            + streaminfo)
    return _header_page(body, True)

def make_flac_comment():
    block = b'\x84\x00\x00\x00'                        # placeholder header, patched below
    vc = _vc(_VENDOR, _TAGS)
    block = bytes([0x84]) + len(vc).to_bytes(3, 'big') + vc  # last=1, type=4 (VORBIS_COMMENT)
    return _header_page(block, False)

def _reset(codec):
    _ST["serial"] = random.randint(1, 0xffffffff)
    _ST["seq"] = 0
    _ST["gran"] = 0
    _ST["carry"] = 0
    _ST["codec"] = codec

# audio / data pages (with lacing)
def make_audio():
    lacing = []
    body = b''
    htype = 0
    completes = False
    # close a packet carried over from the previous page
    if _ST["carry"] > 0:
        htype |= 0x01                                 # continued-packet flag
        lacing += _lace_complete(_ST["carry"])
        body += _rb(_ST["carry"])
        completes = True
        _ST["carry"] = 0
    # 0..2 further whole packets on this page
    for _ in range(random.randint(0, 2)):
        if len(lacing) > 240:
            break
        n = random.randint(0, 700)
        lacing += _lace_complete(n)
        body += _rb(n)
        completes = True
    # occasionally leave a packet open, to be continued on the next page
    if random.random() < 0.4 and len(lacing) < 250:
        q = random.randint(1, 2)
        lacing += [255] * q
        body += _rb(255 * q)
        _ST["carry"] = random.randint(1, 500)
    if not lacing:
        lacing = [0]                                  # a single zero-length packet
        completes = True
    if completes:
        _ST["gran"] += random.randint(1, 4096)
        gran = _ST["gran"]
    else:
        gran = -1                                     # no packet finished on this page
    return _emit(htype, gran, lacing, body)

def make_eos():
    lacing = []
    body = b''
    htype = 0x04                                      # end-of-stream
    if _ST["carry"] > 0:
        htype |= 0x01
        lacing += _lace_complete(_ST["carry"])
        body += _rb(_ST["carry"])
        _ST["carry"] = 0
    n = random.randint(0, 400)                         # a final complete packet
    lacing += _lace_complete(n)
    body += _rb(n)
    _ST["gran"] += random.randint(1, 4096)
    return _emit(htype, _ST["gran"], lacing, body)

# One stream of Vorbis, Opus, Theora, Speex or FLAC: the identification page,
# the other header pages, audio pages, and the end-of-stream page
<start> ::= <ogg_stream>

<ogg_stream> ::= <vorbis_stream> | <opus_stream> | <theora_stream> | <speex_stream> | <flac_stream>

<vorbis_stream> ::= <vorbis_id_page> <vorbis_comment_page> <vorbis_setup_page> <audio_page>* <eos_page>
<opus_stream>   ::= <opus_id_page> <opus_comment_page> <audio_page>* <eos_page>
<theora_stream> ::= <theora_id_page> <theora_comment_page> <theora_setup_page> <audio_page>* <eos_page>
<speex_stream>  ::= <speex_id_page> <speex_comment_page> <audio_page>* <eos_page>
<flac_stream>   ::= <flac_id_page> <flac_comment_page> <audio_page>* <eos_page>

# identification (begin-of-stream) pages, one per codec
<vorbis_id_page> ::= <page> := make_vorbis_id()
<opus_id_page>   ::= <page> := make_opus_id()
<theora_id_page> ::= <page> := make_theora_id()
<speex_id_page>  ::= <page> := make_speex_id()
<flac_id_page>   ::= <page> := make_flac_id()

# comment / tags header pages
<vorbis_comment_page> ::= <page> := make_vorbis_comment()
<opus_comment_page>   ::= <page> := make_opus_comment()
<theora_comment_page> ::= <page> := make_theora_comment()
<speex_comment_page>  ::= <page> := make_speex_comment()
<flac_comment_page>   ::= <page> := make_flac_comment()

# codec setup / codebook header pages
<vorbis_setup_page> ::= <page> := make_vorbis_setup()
<theora_setup_page> ::= <page> := make_theora_setup()

# audio / data pages and the end-of-stream page
<audio_page> ::= <page> := make_audio()
<eos_page>   ::= <page> := make_eos()

# A page, field by field
<page> ::= <capture> <version> <header_type> <granule_position> <serial_number> <sequence_number> <crc> <page_segments> <segment_table> <body>
<capture>          ::= b'OggS'
<version>          ::= <byte>
<header_type>      ::= <byte>
<granule_position> ::= <byte>{8}
<serial_number>    ::= <byte>{4}
<sequence_number>  ::= <byte>{4}
<crc>              ::= <byte>{4}
<page_segments>    ::= <byte>
<segment_table>    ::= <lacing_value>*
<lacing_value>     ::= <byte>
<body>             ::= <byte>*
<byte>             ::= rb'[\x00-\xff]'

# stream_structure_version is 0
where bytes(<version>)[0] == 0
# only bits 0 (continued), 1 (BOS) and 2 (EOS) are defined
where bytes(<header_type>)[0] & 0xf8 == 0
