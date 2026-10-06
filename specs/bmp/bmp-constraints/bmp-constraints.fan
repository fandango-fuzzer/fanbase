# BMP/DIB with core, info, V4 and V5 headers, palettes and an RLE8 flavour.
# bfSize, bfOffBits, biSize, biClrUsed, biSizeImage and the length of the pixel
# array are tied together with where clauses.

<start> ::= <bmp>

<bmp> ::= <bmp_info_family> | <bmp_core> | <bmp_rle8>


# [A] INFO / V4 / V5 family (BITMAPINFOHEADER-compatible, BI_RGB / BI_BITFIELDS)
# All DIB fields are listed as direct children of the file production so that
# every `where` compares plain sibling symbols.

<bmp_info_family> ::= b'BM' <bf_size> <bf_res1> <bf_res2> <bf_offbits> \
    <bih_size> <bi_width> <bi_height> <bi_planes> <bi_bpp> <bi_compression> \
    <bi_imagesize> <bi_xppm> <bi_yppm> <bi_clrused> <bi_clrimportant> \
    <dib_ext> <palette> <pixels>
where <bf_res1> == b'\x00\x00'
where <bf_res2> == b'\x00\x00'
where <bi_planes> == b'\x01\x00'
where <bih_size> == int.to_bytes(40 + len(bytes(<dib_ext>)), 4, 'little')
where <bf_offbits> == int.to_bytes(54 + len(bytes(<dib_ext>)) + len(bytes(<palette>)), 4, 'little')
where <bf_size> == int.to_bytes(len(bytes(<bmp_info_family>)), 4, 'little')
where <bi_imagesize> == int.to_bytes(len(bytes(<pixels>)), 4, 'little')
where <bi_clrused> == int.to_bytes(len(bytes(<palette>)) // 4, 4, 'little')
where len(bytes(<palette>)) == {1: 2, 4: 16, 8: 16}.get(int.from_bytes(bytes(<bi_bpp>), 'little'), 0) * 4
where len(bytes(<pixels>)) == ((int.from_bytes(bytes(<bi_bpp>), 'little') * int.from_bytes(bytes(<bi_width>), 'little') + 31) // 32) * 4 * int.from_bytes(bytes(<bi_height>), 'little')

# biSize is fully determined by the where above; give it a placeholder shape.
<bih_size> ::= <byte>{4}
<bf_size> ::= <byte>{4}
<bf_offbits> ::= <byte>{4}
<bf_res1> ::= <byte>{2}
<bf_res2> ::= <byte>{2}
<bi_planes> ::= <byte>{2}
<bi_imagesize> ::= <byte>{4}
<bi_clrused> ::= <byte>{4}

# width and height: small (2 to 4 px) so the pixel array stays short
<bi_width>  ::= b'\x04\x00\x00\x00' | b'\x02\x00\x00\x00' | b'\x03\x00\x00\x00'
<bi_height> ::= b'\x04\x00\x00\x00' | b'\x02\x00\x00\x00' | b'\x03\x00\x00\x00'

# bits-per-pixel: the six legal DIB depths (u16 LE).
<bi_bpp> ::= b'\x01\x00' | b'\x04\x00' | b'\x08\x00' | b'\x10\x00' | b'\x18\x00' | b'\x20\x00'

# compression: BI_RGB only. BI_BITFIELDS would need the pixel bits to match the
# masks. V4/V5 still carry the mask and colour space fields, which BI_RGB ignores.
<bi_compression> ::= b'\x00\x00\x00\x00'

# resolution: pixels-per-metre, any signed i32 (free 4-byte field each).
<bi_xppm> ::= <byte>{4}
<bi_yppm> ::= <byte>{4}
<bi_clrimportant> ::= <byte>{4}

# DIB header tail: nothing (INFO), V4 extension, or V5 extension
<dib_ext> ::= <v_none> | <v4_ext> | <v5_ext>
<v_none> ::= b''

# V4HEADER extension (68 bytes): 4 colour masks + CSType + 9-DWORD endpoints +
# 3 gamma DWORDs.
<v4_ext> ::= <mask_red> <mask_green> <mask_blue> <mask_alpha> \
    <cs_type> <endpoints> <gamma_r> <gamma_g> <gamma_b>

# V5HEADER extension (84 bytes): the V4 tail + intent + profile offset/size +
# reserved DWORD.
<v5_ext> ::= <mask_red> <mask_green> <mask_blue> <mask_alpha> \
    <cs_type> <endpoints> <gamma_r> <gamma_g> <gamma_b> \
    <v5_intent> <v5_profdata> <v5_profsize> <v5_reserved>

# Standard 5-6-5 / 8-8-8-8 style masks are a plausible free choice.
<mask_red>   ::= b'\x00\xf8\x00\x00' | b'\x00\x00\xff\x00'
<mask_green> ::= b'\xe0\x07\x00\x00' | b'\x00\xff\x00\x00'
<mask_blue>  ::= b'\x1f\x00\x00\x00' | b'\xff\x00\x00\x00'
<mask_alpha> ::= b'\x00\x00\x00\x00' | b'\x00\x00\x00\xff'
# LCS_sRGB ('sRGB') or LCS_CALIBRATED_RGB (0) or LCS_WINDOWS_COLOR_SPACE ('Win ')
<cs_type>    ::= b'sRGB' | b'\x00\x00\x00\x00' | b'Win '
<endpoints>  ::= <byte>{36}
<gamma_r>    ::= <byte>{4}
<gamma_g>    ::= <byte>{4}
<gamma_b>    ::= <byte>{4}
# LCS_GM_* rendering intent: 1,2,4,8
<v5_intent>  ::= b'\x08\x00\x00\x00' | b'\x01\x00\x00\x00' | b'\x02\x00\x00\x00' | b'\x04\x00\x00\x00'
<v5_profdata> ::= <byte>{4}
<v5_profsize> ::= <byte>{4}
<v5_reserved> ::= b'\x00\x00\x00\x00'

# palette: RGBQUAD entries (B,G,R,reserved). Count fixed by `where`.
<palette> ::= <rgbquad>*
<rgbquad> ::= <byte> <byte> <byte> b'\x00'

# pixel array: raw bytes, length fixed by the stride `where`.
<pixels> ::= <byte>*


# [B] BITMAPCOREHEADER family (OS/2 1.x, 12-byte header, RGBTRIPLE palette)
#   biSize u32 == 12, width u16, height u16, planes u16 == 1, bpp u16.
# Palette entries are 3-byte RGBTRIPLE (no reserved byte). BI_RGB only.

<bmp_core> ::= b'BM' <bfc_size> <bfc_res1> <bfc_res2> <bfc_offbits> \
    <bc_size> <bc_width> <bc_height> <bc_planes> <bc_bpp> \
    <core_palette> <core_pixels>
where <bfc_res1> == b'\x00\x00'
where <bfc_res2> == b'\x00\x00'
where <bc_planes> == b'\x01\x00'
where <bc_size> == b'\x0c\x00\x00\x00'
where <bfc_offbits> == int.to_bytes(26 + len(bytes(<core_palette>)), 4, 'little')
where <bfc_size> == int.to_bytes(len(bytes(<bmp_core>)), 4, 'little')
where len(bytes(<core_palette>)) == {1: 2, 4: 16, 8: 16}.get(int.from_bytes(bytes(<bc_bpp>), 'little'), 0) * 3
where len(bytes(<core_pixels>)) == ((int.from_bytes(bytes(<bc_bpp>), 'little') * int.from_bytes(bytes(<bc_width>), 'little') + 31) // 32) * 4 * int.from_bytes(bytes(<bc_height>), 'little')

<bfc_size> ::= <byte>{4}
<bfc_offbits> ::= <byte>{4}
<bfc_res1> ::= <byte>{2}
<bfc_res2> ::= <byte>{2}
<bc_size> ::= <byte>{4}
<bc_planes> ::= <byte>{2}
<bc_width>  ::= b'\x04\x00' | b'\x02\x00' | b'\x03\x00'
<bc_height> ::= b'\x04\x00' | b'\x02\x00' | b'\x03\x00'
<bc_bpp> ::= b'\x01\x00' | b'\x04\x00' | b'\x08\x00' | b'\x18\x00'
<core_palette> ::= <rgbtriple>*
<rgbtriple> ::= <byte> <byte> <byte>
<core_pixels> ::= <byte>*


# [C] BI_RLE8 compressed 8-bpp bitmap (BITMAPINFOHEADER, compression == 1)
# The pixel array is a run-length opcode stream instead of raw rows. Width is
# fixed at 4 px: each scan line is one "encoded run" (count 0x04 = width, then a
# colour index), followed by the End-Of-Line marker 00 00; the whole array ends
# with the End-Of-Bitmap marker 00 01. So the stream is exactly
#   height * (4-byte run+EOL) + 2-byte EOB
# which the `where` below ties to biHeight, keeping the run stream and the
# declared image dimensions in agreement. biSizeImage == the stream length.
# Carries a 4-entry palette (biClrUsed == 4), a valid reduced colour table;
# run colour indices are kept within 0..3 to stay inside that table.

<bmp_rle8> ::= b'BM' <bfr_size> <bfr_res1> <bfr_res2> <bfr_offbits> \
    <bir_size> <bir_width> <bir_height> <bir_planes> <bir_bpp> <bir_compression> \
    <bir_imagesize> <bir_xppm> <bir_yppm> <bir_clrused> <bir_clrimportant> \
    <rle_palette> <rle_pixels>
where <bfr_res1> == b'\x00\x00'
where <bfr_res2> == b'\x00\x00'
where <bir_planes> == b'\x01\x00'
where <bir_bpp> == b'\x08\x00'
where <bir_size> == b'\x28\x00\x00\x00'
where <bir_compression> == b'\x01\x00\x00\x00'
where <bfr_offbits> == int.to_bytes(54 + len(bytes(<rle_palette>)), 4, 'little')
where <bfr_size> == int.to_bytes(len(bytes(<bmp_rle8>)), 4, 'little')
where <bir_imagesize> == int.to_bytes(len(bytes(<rle_pixels>)), 4, 'little')
where <bir_clrused> == int.to_bytes(len(bytes(<rle_palette>)) // 4, 4, 'little')
where <bir_width> == b'\x04\x00\x00\x00'
where len(bytes(<rle_palette>)) == 16
where len(bytes(<rle_pixels>)) == int.from_bytes(bytes(<bir_height>), 'little') * 4 + 2

<bfr_size> ::= <byte>{4}
<bfr_offbits> ::= <byte>{4}
<bfr_res1> ::= <byte>{2}
<bfr_res2> ::= <byte>{2}
<bir_size> ::= <byte>{4}
<bir_planes> ::= <byte>{2}
<bir_bpp> ::= <byte>{2}
<bir_compression> ::= <byte>{4}
<bir_imagesize> ::= <byte>{4}
<bir_clrused> ::= <byte>{4}
<bir_width>  ::= <byte>{4}
<bir_height> ::= b'\x04\x00\x00\x00' | b'\x02\x00\x00\x00' | b'\x03\x00\x00\x00'
<bir_xppm> ::= <byte>{4}
<bir_yppm> ::= <byte>{4}
<bir_clrimportant> ::= <byte>{4}
<rle_palette> ::= <rgbquad>{4}

# RLE8 opcode stream: one encoded run per 4-px scan line (count 0x04 == width),
# each followed by the End-Of-Line marker 00 00, then End-Of-Bitmap 00 01.
# The number of scan lines is tied to biHeight by the `where` above.
<rle_pixels> ::= <rle_row>* b'\x00\x01'
<rle_row> ::= b'\x04' <rle_index> b'\x00\x00'
<rle_index> ::= rb'[\x00-\x03]'


# Shared terminal
<byte> ::= rb'[\x00-\xff]'
