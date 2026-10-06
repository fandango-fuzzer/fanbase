# BMP/DIB with 1, 4, 8, 16, 24 and 32 bits per pixel, top-down heights, short
# palettes, V4 and V5 color masks, an RLE8 flavour and extreme resolution
# fields. Six flavours, each self-contained.

<start> ::= <bmp>
<bmp> ::= <bmp_core> | <bmp_info_indexed> | <bmp_info_direct> \
    | <bmp_v4> | <bmp_v5> | <bmp_rle8>

# BITMAPCOREHEADER (OS/2 1.x): 12-byte header, u16 dimensions, no
# compression, no clr-count field. Palette is RGBTRIPLE (3 bytes/entry).
<bmp_core> ::= b'BM' <bfSize> <bfReserved> <bfOffBits> \
    <cSize> <cWidth> <cHeight> <cPlanes> <cBpp> <core_pal> <core_pixels>
<cSize> ::= <u32>
<cWidth> ::= <u16_dim>
<cHeight> ::= <u16_dim>
<cPlanes> ::= b'\x01\x00'
<cBpp> ::= b'\x01\x00' | b'\x04\x00' | b'\x08\x00' | b'\x18\x00'
<core_pal> ::= <rgbtriple>*
<rgbtriple> ::= <u8> <u8> <u8>
<core_pixels> ::= <u8>*

# BITMAPINFOHEADER (40B) - indexed depths (1/4/8), RGBQUAD palette.
# biClrUsed ties exactly to the emitted palette length (reduced palettes
# allowed: biClrUsed < 2^bpp is spec-legal and stresses parsers).
<bmp_info_indexed> ::= b'BM' <bfSize> <bfReserved> <bfOffBits> \
    <iSize> <width> <height> <planes> <bpp_idx> <comp_rgb> <biSizeImage> \
    <xppm> <yppm> <biClrUsed> <biClrImportant> <idx_pal> <idx_pixels>
<iSize> ::= <u32>
<bpp_idx> ::= b'\x01\x00' | b'\x04\x00' | b'\x08\x00'
<idx_pal> ::= <rgbquad>*
<rgbquad> ::= <u8> <u8> <u8> b'\x00'
<idx_pixels> ::= <u8>*

# BITMAPINFOHEADER (40B) - direct-colour depths (16/24/32), no palette.
<bmp_info_direct> ::= b'BM' <bfSize> <bfReserved> <bfOffBits> \
    <iSize> <width> <height> <planes> <bpp_dir> <comp_rgb> <biSizeImage> \
    <xppm> <yppm> <biClrUsed0> <biClrImportant> <dir_pixels>
<bpp_dir> ::= b'\x10\x00' | b'\x18\x00' | b'\x20\x00'
<dir_pixels> ::= <u8>*

# BITMAPV4HEADER (108B) - direct colour + RGBA bitfield masks +
# CIEXYZTRIPLE endpoints (36B) + per-channel gamma.
<bmp_v4> ::= b'BM' <bfSize> <bfReserved> <bfOffBits> \
    <v4Size> <width> <height> <planes> <bpp_dir> <comp_rgb> <biSizeImage> \
    <xppm> <yppm> <biClrUsed0> <biClrImportant> \
    <redMask> <greenMask> <blueMask> <alphaMask> <csType> <endpoints> \
    <gammaR> <gammaG> <gammaB> <v4_pixels>
<v4Size> ::= <u32>
<v4_pixels> ::= <u8>*

# BITMAPV5HEADER (124B) - V4 + rendering intent + ICC profile off/size + reserved.
<bmp_v5> ::= b'BM' <bfSize> <bfReserved> <bfOffBits> \
    <v5Size> <width> <height> <planes> <bpp_dir> <comp_rgb> <biSizeImage> \
    <xppm> <yppm> <biClrUsed0> <biClrImportant> \
    <redMask> <greenMask> <blueMask> <alphaMask> <csType> <endpoints> \
    <gammaR> <gammaG> <gammaB> \
    <intent> <profData> <profSize> <v5reserved> <v5_pixels>
<v5Size> ::= <u32>
<v5_pixels> ::= <u8>*
<intent> ::= b'\x01\x00\x00\x00' | b'\x02\x00\x00\x00' | b'\x04\x00\x00\x00' | b'\x08\x00\x00\x00'
<profData> ::= b'\x00\x00\x00\x00'
<profSize> ::= b'\x00\x00\x00\x00'
<v5reserved> ::= b'\x00\x00\x00\x00'

# BI_RLE8 flavour: 8bpp, compression = 2, run-length encoded pixel data.
# Minimal decodable stream: per scan line one encoded run "04 <idx>" then
# End-Of-Line "00 00"; finally End-Of-Bitmap "00 01".
<bmp_rle8> ::= b'BM' <bfSize> <bfReserved> <bfOffBits> \
    <iSize> <rle_w> <rle_h> <planes> <bpp8> <comp_rle8> <biSizeImage> \
    <xppm> <yppm> <biClrUsed> <biClrImportant> <idx_pal> <rle_pixels>
<rle_w> ::= b'\x04\x00\x00\x00'
<rle_h> ::= b'\x01\x00\x00\x00' | b'\x02\x00\x00\x00' | b'\x03\x00\x00\x00' | b'\x04\x00\x00\x00'
<bpp8> ::= b'\x08\x00'
<comp_rle8> ::= b'\x01\x00\x00\x00'
<rle_pixels> ::= <rle_row>* b'\x00\x01'
<rle_row> ::= b'\x04' <u8> b'\x00\x00'

# Shared BITMAPFILEHEADER + BITMAPINFOHEADER field productions.
<bfSize> ::= <u32>
# reserved words: nominally 0 (OS/2 hotspot uses them; kept spec-legal 0).
<bfReserved> ::= <u32> := b'\x00\x00\x00\x00'
<bfOffBits> ::= <u32>

<width> ::= <u32_dim>
# height: positive = bottom-up rows; negative (two's-complement) = top-down.
<height> ::= <u32_dim> | b'\xff\xff\xff\xff' | b'\xfe\xff\xff\xff' \
    | b'\xfd\xff\xff\xff' | b'\xfc\xff\xff\xff'
<u32_dim> ::= b'\x01\x00\x00\x00' | b'\x02\x00\x00\x00' \
    | b'\x03\x00\x00\x00' | b'\x04\x00\x00\x00'
<u16_dim> ::= b'\x01\x00' | b'\x02\x00' | b'\x03\x00' | b'\x04\x00'
<planes> ::= b'\x01\x00'
<comp_rgb> ::= b'\x00\x00\x00\x00'
<biSizeImage> ::= <u32> := b'\x00\x00\x00\x00'
# resolution (pixels/metre): 0, ~72dpi, and INT32_MAX extreme.
<xppm> ::= b'\x00\x00\x00\x00' | b'\x13\x0b\x00\x00' | b'\xff\xff\xff\x7f'
<yppm> ::= b'\x00\x00\x00\x00' | b'\x13\x0b\x00\x00' | b'\xff\xff\xff\x7f'
<biClrUsed> ::= <u32>
<biClrUsed0> ::= b'\x00\x00\x00\x00'
<biClrImportant> ::= <u32> := b'\x00\x00\x00\x00'

# V4/V5 masks + colour space.
<redMask> ::= b'\x00\x00\xff\x00'
<greenMask> ::= b'\x00\xff\x00\x00'
<blueMask> ::= b'\xff\x00\x00\x00'
<alphaMask> ::= b'\x00\x00\x00\xff' | b'\x00\x00\x00\x00'
# CSType: 0=LCS_CALIBRATED_RGB; 'sRGB'; 'Win ' (stored little-endian).
<csType> ::= b'\x00\x00\x00\x00' | b'BGRs' | b' niW'
# CIEXYZTRIPLE: 9 * FXPT2DOT30 (36 bytes); zero under non-calibrated space.
<endpoints> ::= <fxpt>{9}
<fxpt> ::= <u32> := b'\x00\x00\x00\x00'
<gammaR> ::= <u32> := b'\x00\x00\x00\x00'
<gammaG> ::= <u32> := b'\x00\x00\x00\x00'
<gammaB> ::= <u32> := b'\x00\x00\x00\x00'

# Primitive widths.
<u8> ::= rb'[\x00-\xff]'
<u16> ::= rb'[\x00-\xff]{2}'
<u32> ::= rb'[\x00-\xff]{4}'

# Constraints (top-level; each binds only when its flavour is present).

# BITMAPCOREHEADER
where bytes(<cSize>) == (12).to_bytes(4, 'little')
where bytes(<bfSize>) == len(bytes(<bmp_core>)).to_bytes(4, 'little')
where bytes(<bfOffBits>) == (26 + len(bytes(<core_pal>))).to_bytes(4, 'little')
where len(bytes(<core_pal>)) // 3 <= 2 ** int.from_bytes(bytes(<cBpp>), 'little')
where len(bytes(<core_pixels>)) == (
    ((int.from_bytes(bytes(<cBpp>), 'little') * int.from_bytes(bytes(<cWidth>), 'little') + 31) // 32)
    * 4 * int.from_bytes(bytes(<cHeight>), 'little'))

# BITMAPINFOHEADER (biSize == 40 wherever <iSize> is used)
where bytes(<iSize>) == (40).to_bytes(4, 'little')

# BITMAPINFOHEADER, indexed (also covers the RLE8 flavour's idx_pal)
where bytes(<bfSize>) == len(bytes(<bmp_info_indexed>)).to_bytes(4, 'little')
where bytes(<bfOffBits>) == (54 + len(bytes(<idx_pal>))).to_bytes(4, 'little')
where bytes(<biClrUsed>) == (len(bytes(<idx_pal>)) // 4).to_bytes(4, 'little')
where len(bytes(<idx_pal>)) // 4 <= 2 ** int.from_bytes(bytes(<bpp_idx>), 'little')
where len(bytes(<idx_pixels>)) == (
    ((int.from_bytes(bytes(<bpp_idx>), 'little') * int.from_bytes(bytes(<width>), 'little') + 31) // 32)
    * 4 * abs(int.from_bytes(bytes(<height>), 'little', signed=True)))

# BITMAPINFOHEADER, direct colour
where bytes(<bfSize>) == len(bytes(<bmp_info_direct>)).to_bytes(4, 'little')
where bytes(<bfOffBits>) == (54 + 0 * len(bytes(<dir_pixels>))).to_bytes(4, 'little')
where len(bytes(<dir_pixels>)) == (
    ((int.from_bytes(bytes(<bpp_dir>), 'little') * int.from_bytes(bytes(<width>), 'little') + 31) // 32)
    * 4 * abs(int.from_bytes(bytes(<height>), 'little', signed=True)))

# BITMAPV4HEADER
where bytes(<v4Size>) == (108).to_bytes(4, 'little')
where bytes(<bfSize>) == len(bytes(<bmp_v4>)).to_bytes(4, 'little')
where bytes(<bfOffBits>) == (122 + 0 * len(bytes(<v4_pixels>))).to_bytes(4, 'little')
where len(bytes(<v4_pixels>)) == (
    ((int.from_bytes(bytes(<bpp_dir>), 'little') * int.from_bytes(bytes(<width>), 'little') + 31) // 32)
    * 4 * abs(int.from_bytes(bytes(<height>), 'little', signed=True)))

# BITMAPV5HEADER
where bytes(<v5Size>) == (124).to_bytes(4, 'little')
where bytes(<bfSize>) == len(bytes(<bmp_v5>)).to_bytes(4, 'little')
where bytes(<bfOffBits>) == (138 + 0 * len(bytes(<v5_pixels>))).to_bytes(4, 'little')
where len(bytes(<v5_pixels>)) == (
    ((int.from_bytes(bytes(<bpp_dir>), 'little') * int.from_bytes(bytes(<width>), 'little') + 31) // 32)
    * 4 * abs(int.from_bytes(bytes(<height>), 'little', signed=True)))

# BI_RLE8
where bytes(<bfSize>) == len(bytes(<bmp_rle8>)).to_bytes(4, 'little')
where bytes(<biSizeImage>) == len(bytes(<rle_pixels>)).to_bytes(4, 'little')
where len(bytes(<rle_pixels>)) == int.from_bytes(bytes(<rle_h>), 'little') * 4 + 2
