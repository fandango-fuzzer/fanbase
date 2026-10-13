# JPEG XL raw codestream (ISO/IEC 18181-1): signature, SizeHeader, ImageMetadata
# (bit depth, extra channels, colour encoding, tone mapping, ICC), an optional
# preview, and one frame header + TOC. Header fields are bit-packed to match
# libjxl's field order exactly; the entropy-coded frame body is a
# structurally-framed stub, so files rarely decode.
#
# TODO:
# * The frame body is a stub (no ANS/MA-tree entropy coding), so files won't
#   round-trip through a real decoder. A real fix needs a stateful encoder,
#   not a CFG.
# * Relies on Generators alot, modify in the future

<start> ::= <jxl>

# Flavor alternation — each branch is a distinct nonterminal so the alternation
# fuzzes cleanly (no shared constrained sibling), and each maps to one call of
# the bit-packing sealer. Together they exercise every major header element.
<jxl> ::= <f_tiny_gray8>   \
        | <f_small_rgb8>    \
        | <f_med_rgb8>      \
        | <f_large_rgb8>    \
        | <f_ratio_wide>    \
        | <f_gray16>        \
        | <f_rgb16>         \
        | <f_rgb_float32>   \
        | <f_rgba8>         \
        | <f_xyb>           \
        | <f_oriented>      \
        | <f_preview>       \
        | <f_animation>     \
        | <f_modular>       \
        | <f_icc>

<f_tiny_gray8>  ::= <blob> := build_jxl(0)
<f_small_rgb8>  ::= <blob> := build_jxl(1)
<f_med_rgb8>    ::= <blob> := build_jxl(2)
<f_large_rgb8>  ::= <blob> := build_jxl(3)
<f_ratio_wide>  ::= <blob> := build_jxl(4)
<f_gray16>      ::= <blob> := build_jxl(5)
<f_rgb16>       ::= <blob> := build_jxl(6)
<f_rgb_float32> ::= <blob> := build_jxl(7)
<f_rgba8>       ::= <blob> := build_jxl(8)
<f_xyb>         ::= <blob> := build_jxl(9)
<f_oriented>    ::= <blob> := build_jxl(10)
<f_preview>     ::= <blob> := build_jxl(11)
<f_animation>   ::= <blob> := build_jxl(12)
<f_modular>     ::= <blob> := build_jxl(13)
<f_icc>         ::= <blob> := build_jxl(14)

# Generic placeholder; the := generator on each flavor overwrites it wholesale
# (the produced bytes re-parse trivially as a run of <byte>).
<blob> ::= <byte>+


# Preamble: the JXL bit-writer and the header packer.
import os


class BitWriter:
    # LSB-first bit accumulator matching libjxl's BitReader consumption order.
    def __init__(self):
        self.acc = 0
        self.nbits = 0

    def write(self, value, count):
        # Append `count` low bits of `value`, least-significant bit first.
        value &= (1 << count) - 1
        self.acc |= value << self.nbits
        self.nbits += count

    def zero_pad_to_byte(self):
        rem = self.nbits % 8
        if rem:
            self.nbits += 8 - rem

    def to_bytes(self):
        out = bytearray()
        acc = self.acc
        n = self.nbits
        pos = 0
        while pos < n:
            out.append((acc >> pos) & 0xFF)
            pos += 8
        return bytes(out)


def write_u32(bw, encs, value):
    # U32 encoding: a 2-bit selector chooses one of four sub-encodings, each
    # either a literal value ('val', k) or an offset + fixed bit width
    # ('bits', nbits, offset) meaning value = offset + read(nbits).
    for idx, enc in enumerate(encs):
        if enc[0] == 'val':
            if value == enc[1]:
                bw.write(idx, 2)
                return
        else:
            nbits = enc[1]
            offset = enc[2]
            if offset <= value < offset + (1 << nbits):
                bw.write(idx, 2)
                bw.write(value - offset, nbits)
                return
    raise ValueError('value %d not representable by U32 encs %r' % (value, encs))


def write_u64(bw, value):
    # U64: selector u(2). 0 -> 0; 1 -> u(4); 2 -> 12 + u(8);
    # 3 -> 20 bits then, while a continuation bit is set, 8 more bits.
    if value == 0:
        bw.write(0, 2)
        return
    if 1 <= value <= 15:
        bw.write(1, 2)
        bw.write(value, 4)
        return
    if 16 <= value <= 12 + 255:
        bw.write(2, 2)
        bw.write(value - 12, 8)
        return
    bw.write(3, 2)
    bw.write(value & 0xFFFFF, 20)
    value >>= 20
    while value:
        bw.write(1, 1)
        bw.write(value & 0xFF, 8)
        value >>= 8
    bw.write(0, 1)


# U32 distribution used for both ysize and xsize in SizeHeader (offset 1).
DIM_ENC = [('bits', 9, 1), ('bits', 13, 1), ('bits', 18, 1), ('bits', 30, 1)]

# Aspect-ratio table for SizeHeader.ratio 1..7 (num, den): xsize = ysize*num/den.
RATIO_TABLE = {1: (1, 1), 2: (12, 10), 3: (4, 3), 4: (3, 2),
               5: (16, 9), 6: (5, 4), 7: (2, 1)}


def write_size_header(bw, ysize, xsize, ratio):
    # small_ is true when both dims are multiples of 8 in [8,256].
    small = (ysize % 8 == 0 and 8 <= ysize <= 256 and
             xsize % 8 == 0 and 8 <= xsize <= 256)
    bw.write(1 if small else 0, 1)
    if small:
        bw.write(ysize // 8 - 1, 5)
    else:
        write_u32(bw, DIM_ENC, ysize)
    bw.write(ratio, 3)
    if ratio == 0:
        if small:
            bw.write(xsize // 8 - 1, 5)
        else:
            write_u32(bw, DIM_ENC, xsize)
    # ratio != 0 -> xsize is derived by the decoder from ysize and the table.


def write_bit_depth(bw, floating, bits_per_sample, exp_bits):
    bw.write(1 if floating else 0, 1)
    if floating:
        # bits_per_sample: U32(Val(32), Val(16), Val(24), Bits(6)+1)
        write_u32(bw, [('val', 32), ('val', 16), ('val', 24), ('bits', 6, 1)],
                  bits_per_sample)
        bw.write(exp_bits - 1, 4)
    else:
        # bits_per_sample: U32(Val(8), Val(10), Val(12), Bits(6)+1)
        write_u32(bw, [('val', 8), ('val', 10), ('val', 12), ('bits', 6, 1)],
                  bits_per_sample)


def write_customxy(bw, x, y):
    # CustomXY: two U32 signed-folded coords (unused unless custom primaries).
    write_u32(bw, [('bits', 19, 0), ('bits', 19, 524288),
                   ('bits', 20, 1048576), ('bits', 21, 2097152)], x & 0x1FFFFF)
    write_u32(bw, [('bits', 19, 0), ('bits', 19, 524288),
                   ('bits', 20, 1048576), ('bits', 21, 2097152)], y & 0x1FFFFF)


def write_color_encoding(bw, gray, want_icc, color_space, white_point,
                         primaries, transfer, rendering_intent):
    bw.write(0, 1)                 # all_default = false (fields set explicitly)
    bw.write(1 if want_icc else 0, 1)
    bw.write(color_space, 2)       # 0 RGB, 1 Gray, 2 XYB, 3 Unknown
    if want_icc:
        return
    # white_point: Enum u(2)-ish (0 D65, 1 Custom, 2 E, 3 DCI)
    bw.write(white_point, 2)
    if white_point == 1:
        write_customxy(bw, 0, 0)
    if color_space != 2:           # not XYB
        bw.write(primaries, 2)     # 0 sRGB, 1 Custom, 2 2100, 3 P3
        if primaries == 1:
            write_customxy(bw, 0, 0)
            write_customxy(bw, 0, 0)
            write_customxy(bw, 0, 0)
    # transfer function: have_gamma bool; if not, Enum tf
    bw.write(0, 1)                 # have_gamma = false
    bw.write(transfer, 5)          # transfer-function enum (u(5) domain here)
    bw.write(rendering_intent, 2)  # 0 perceptual,1 relative,2 saturation,3 abs


def write_extra_channel(bw, ec_type, bits_per_sample):
    bw.write(0, 1)                 # all_default = false
    bw.write(ec_type, 4)           # 0 Alpha,1 Depth,2 SpotColor,3 SelectionMask,...
    write_bit_depth(bw, False, bits_per_sample, 8)
    write_u32(bw, [('val', 0), ('val', 3), ('val', 4), ('bits', 3, 1)], 0)  # dim_shift
    # name length = 0
    write_u32(bw, [('val', 0), ('bits', 4, 0), ('bits', 16, 0), ('bits', 32, 0)], 0)
    if ec_type == 0:
        bw.write(0, 1)             # alpha_associated = false
    if ec_type == 2:
        write_u32(bw, [('bits', 8, 0)] * 4, 0)  # spot color placeholder


def write_preview_header(bw):
    bw.write(0, 1)                 # div8 = false
    write_u32(bw, [('bits', 5, 1), ('bits', 9, 1),
                   ('bits', 10, 1), ('bits', 12, 1)], 32)   # ysize
    bw.write(0, 3)                 # ratio = 0
    write_u32(bw, [('bits', 5, 1), ('bits', 9, 1),
                   ('bits', 10, 1), ('bits', 12, 1)], 32)   # xsize


def write_animation_header(bw):
    write_u32(bw, [('val', 100), ('val', 1000), ('bits', 10, 1),
                   ('bits', 30, 1)], 100)                   # tps_numerator
    write_u32(bw, [('val', 1), ('val', 1001), ('bits', 8, 1),
                   ('bits', 10, 1)], 1)                     # tps_denominator
    write_u32(bw, [('val', 0), ('bits', 3, 0), ('bits', 16, 0),
                   ('bits', 32, 0)], 0)                     # num_loops = infinite
    bw.write(0, 1)                                          # have_timecodes = false


def write_image_metadata(bw, spec):
    # spec keys: extra_fields, orientation, have_preview, have_animation,
    # floating, bps, exp_bits, num_extra, ec_type, xyb, gray, want_icc,
    # color_space, white_point, primaries, transfer, rendering_intent.
    if spec is None:
        bw.write(1, 1)             # all_default = true (8-bit sRGB RGB, XYB)
        return
    bw.write(0, 1)                 # all_default = false
    bw.write(1 if spec['extra_fields'] else 0, 1)
    if spec['extra_fields']:
        bw.write(spec['orientation'] - 1, 3)
        bw.write(0, 1)             # have_intrinsic_size = false
        bw.write(1 if spec['have_preview'] else 0, 1)
        if spec['have_preview']:
            write_preview_header(bw)
        bw.write(1 if spec['have_animation'] else 0, 1)
        if spec['have_animation']:
            write_animation_header(bw)
    write_bit_depth(bw, spec['floating'], spec['bps'], spec['exp_bits'])
    bw.write(1, 1)                 # modular_16bit_buffers = true
    write_u32(bw, [('val', 0), ('val', 1), ('bits', 4, 2), ('bits', 12, 1)],
              spec['num_extra'])
    for _ in range(spec['num_extra']):
        write_extra_channel(bw, spec['ec_type'], 8)
    bw.write(1 if spec['xyb'] else 0, 1)   # xyb_encoded
    write_color_encoding(bw, spec['gray'], spec['want_icc'], spec['color_space'],
                         spec['white_point'], spec['primaries'],
                         spec['transfer'], spec['rendering_intent'])
    if spec['extra_fields']:
        bw.write(1, 1)             # tone_mapping all_default = true
    write_u64(bw, 0)               # extensions = none


def write_frame_stub(bw, frame_kind, duration):
    # FrameHeader (partial): not all_default, so the encoding varies; then
    # byte-align and append a framed but non-entropy-decodable group-data
    # stub. Real group data is ANS/prefix coded and out of CFG reach.
    bw.write(0, 1)                 # all_default = false
    bw.write(0, 2)                 # frame_type = kRegularFrame
    bw.write(frame_kind, 1)        # encoding: 0 VarDCT, 1 Modular
    write_u64(bw, 0)               # flags = 0
    if frame_kind == 0:
        bw.write(0, 1)             # do_YCbCr = false (VarDCT path)
    bw.write(0, 2)                 # upsampling shift = 0
    bw.write(0, 2)                 # passes: num_passes selector -> 1 pass
    bw.write(0, 2)                 # x0/y0 (not full frame flag path) placeholder
    bw.write(0, 1)                 # is_last -> false so a duration can apply
    bw.write(0, 2)                 # save_as_reference etc. placeholder
    if duration is not None:
        write_u32(bw, [('val', 0), ('val', 1), ('bits', 8, 0),
                       ('bits', 32, 0)], duration)
    bw.write(0, 1)                 # have_crc / name_len = 0 placeholder


def build_jxl(flavor):
    # Flavor -> (ysize, xsize, ratio, metadata-spec, frame_kind, duration).
    # metadata-spec None means the compact all_default ImageMetadata.
    def meta(**kw):
        base = dict(extra_fields=False, orientation=1, have_preview=False,
                    have_animation=False, floating=False, bps=8, exp_bits=8,
                    num_extra=0, ec_type=0, xyb=False, gray=False, want_icc=False,
                    color_space=0, white_point=0, primaries=0, transfer=8,
                    rendering_intent=0)
        base.update(kw)
        return base

    table = [
        # 0: tiny 8x8 grayscale, 8-bit
        (8, 8, 0, meta(gray=True, color_space=1), 0, None),
        # 1: small 64x64 RGB 8-bit, compact all_default metadata
        (64, 64, 0, None, 0, None),
        # 2: medium 256x192 RGB 8-bit
        (256, 192, 0, None, 0, None),
        # 3: large 4096x2048 RGB 8-bit (exercises the wide U32 dim encoding)
        (4096, 2048, 0, None, 0, None),
        # 4: aspect-ratio-derived width, ratio=5 (16:9), ysize 720
        (720, 1280, 5, None, 0, None),
        # 5: grayscale 16-bit
        (200, 200, 0, meta(gray=True, color_space=1, bps=16), 0, None),
        # 6: RGB 16-bit
        (300, 300, 0, meta(bps=16), 0, None),
        # 7: RGB float32
        (128, 128, 0, meta(floating=True, bps=32, exp_bits=8), 0, None),
        # 8: RGBA (one alpha extra channel), 8-bit
        (150, 150, 0, meta(num_extra=1, ec_type=0), 0, None),
        # 9: XYB-encoded RGB
        (100, 100, 0, meta(xyb=True, color_space=2), 0, None),
        # 10: oriented (rotate 90 CW = orientation 6), extra_fields
        (240, 160, 0, meta(extra_fields=True, orientation=6), 0, None),
        # 11: preview image present
        (400, 300, 0, meta(extra_fields=True, have_preview=True), 0, None),
        # 12: animation (multi-frame), duration on the first frame
        (96, 96, 0, meta(extra_fields=True, have_animation=True), 0, 30),
        # 13: Modular-encoded frame
        (128, 96, 0, meta(bps=8), 1, None),
        # 14: embedded-ICC colour encoding (want_icc)
        (180, 120, 0, meta(want_icc=True, color_space=0), 0, None),
    ]
    ysize, xsize, ratio, spec, frame_kind, duration = table[flavor % len(table)]

    bw = BitWriter()
    write_size_header(bw, ysize, xsize, ratio)
    write_image_metadata(bw, spec)

    out = bytearray()
    out += b'\xff\x0a'                       # 1. Signature
    out += bw.to_bytes()                     # 2/3. SizeHeader + ImageMetadata

    # 4. Optional embedded ICC blob (want_icc): a short byte-aligned stub.
    if spec is not None and spec.get('want_icc'):
        out += b'\x00' * 16

    # 6. Frame region: byte-aligned FrameHeader + framed group-data stub.
    fbw = BitWriter()
    write_frame_stub(fbw, frame_kind, duration)
    fbw.zero_pad_to_byte()
    out += fbw.to_bytes()

    # Structural (non-decodable) group-data stub; os.urandom gives per-file
    # uniqueness so a -n run yields distinct outputs.
    body_len = 64 + (flavor * 8)
    out += os.urandom(body_len)

    # 12 (animation): append one more framed stub so the codestream carries a
    # second frame, and mark it as the last.
    if spec is not None and spec.get('have_animation'):
        gbw = BitWriter()
        write_frame_stub(gbw, frame_kind, 20)
        gbw.zero_pad_to_byte()
        out += gbw.to_bytes()
        out += os.urandom(48)

    return bytes(out)
