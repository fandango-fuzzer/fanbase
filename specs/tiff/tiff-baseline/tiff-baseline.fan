# Baseline TIFF 6.0, uncompressed, one strip: bilevel, gray, RGB (with some
# metadata tags), palette, and a big endian gray file. Each flavour has its
# own header, IFD and data. StripOffsets, StripByteCounts and the value offsets
# are tied to the real lengths with where clauses.

<start> ::= <tiff_rgb_le> | <tiff_gray_le> | <tiff_palette_le> \
          | <tiff_bilevel_le> | <tiff_gray_be>

# Flavour 1 - RGB, little-endian, full baseline + extended metadata (20 tags).
# meta layout:  bits(6) desc(10) make(5) model(8) xres(8) yres(8)
#               soft(9) dt(20) artist(7)   -> 81 bytes
<tiff_rgb_le> ::= <rg_hdr> <rg_ifd> <rg_meta> <rg_img>
where <rg_off_bits>   == (8 + len(bytes(<rg_ifd>))).to_bytes(4, 'little')
where <rg_off_desc>   == (8 + len(bytes(<rg_ifd>)) + 6).to_bytes(4, 'little')
where <rg_off_make>   == (8 + len(bytes(<rg_ifd>)) + 16).to_bytes(4, 'little')
where <rg_off_model>  == (8 + len(bytes(<rg_ifd>)) + 21).to_bytes(4, 'little')
where <rg_off_xres>   == (8 + len(bytes(<rg_ifd>)) + 29).to_bytes(4, 'little')
where <rg_off_yres>   == (8 + len(bytes(<rg_ifd>)) + 37).to_bytes(4, 'little')
where <rg_off_soft>   == (8 + len(bytes(<rg_ifd>)) + 45).to_bytes(4, 'little')
where <rg_off_dt>     == (8 + len(bytes(<rg_ifd>)) + 54).to_bytes(4, 'little')
where <rg_off_artist> == (8 + len(bytes(<rg_ifd>)) + 74).to_bytes(4, 'little')
where <rg_off_strip>  == (8 + len(bytes(<rg_ifd>)) + len(bytes(<rg_meta>))).to_bytes(4, 'little')
where <rg_cnt_strip>  == len(bytes(<rg_img>)).to_bytes(4, 'little')

<rg_hdr> ::= b'II' b'\x2a\x00' b'\x08\x00\x00\x00'
<rg_ifd> ::= b'\x14\x00' <rg_entries> b'\x00\x00\x00\x00'
<rg_entries> ::= \
    b'\xfe\x00' b'\x04\x00' b'\x01\x00\x00\x00' b'\x00\x00\x00\x00' \
    b'\x00\x01' b'\x04\x00' b'\x01\x00\x00\x00' <rg_w> \
    b'\x01\x01' b'\x04\x00' b'\x01\x00\x00\x00' <rg_h> \
    b'\x02\x01' b'\x03\x00' b'\x03\x00\x00\x00' <rg_off_bits> \
    b'\x03\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x01\x00\x00\x00' \
    b'\x06\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x02\x00\x00\x00' \
    b'\x0e\x01' b'\x02\x00' b'\x0a\x00\x00\x00' <rg_off_desc> \
    b'\x0f\x01' b'\x02\x00' b'\x05\x00\x00\x00' <rg_off_make> \
    b'\x10\x01' b'\x02\x00' b'\x08\x00\x00\x00' <rg_off_model> \
    b'\x11\x01' b'\x04\x00' b'\x01\x00\x00\x00' <rg_off_strip> \
    b'\x12\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x01\x00\x00\x00' \
    b'\x15\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x03\x00\x00\x00' \
    b'\x16\x01' b'\x04\x00' b'\x01\x00\x00\x00' b'\x08\x00\x00\x00' \
    b'\x17\x01' b'\x04\x00' b'\x01\x00\x00\x00' <rg_cnt_strip> \
    b'\x1a\x01' b'\x05\x00' b'\x01\x00\x00\x00' <rg_off_xres> \
    b'\x1b\x01' b'\x05\x00' b'\x01\x00\x00\x00' <rg_off_yres> \
    b'\x28\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x02\x00\x00\x00' \
    b'\x31\x01' b'\x02\x00' b'\x09\x00\x00\x00' <rg_off_soft> \
    b'\x32\x01' b'\x02\x00' b'\x14\x00\x00\x00' <rg_off_dt> \
    b'\x3b\x01' b'\x02\x00' b'\x07\x00\x00\x00' <rg_off_artist>
<rg_w> ::= b'\x08\x00\x00\x00'
<rg_h> ::= b'\x08\x00\x00\x00'
<rg_off_bits>   ::= <byte> <byte> <byte> <byte>
<rg_off_desc>   ::= <byte> <byte> <byte> <byte>
<rg_off_make>   ::= <byte> <byte> <byte> <byte>
<rg_off_model>  ::= <byte> <byte> <byte> <byte>
<rg_off_strip>  ::= <byte> <byte> <byte> <byte>
<rg_cnt_strip>  ::= <byte> <byte> <byte> <byte>
<rg_off_xres>   ::= <byte> <byte> <byte> <byte>
<rg_off_yres>   ::= <byte> <byte> <byte> <byte>
<rg_off_soft>   ::= <byte> <byte> <byte> <byte>
<rg_off_dt>     ::= <byte> <byte> <byte> <byte>
<rg_off_artist> ::= <byte> <byte> <byte> <byte>
<rg_meta> ::= b'\x08\x00\x08\x00\x08\x00' b'RGB image\x00' b'ACME\x00' \
              b'Camera1\x00' b'\x2c\x01\x00\x00\x01\x00\x00\x00' \
              b'\x2c\x01\x00\x00\x01\x00\x00\x00' b'Fandango\x00' \
              b'2026:08:05 12:00:00\x00' b'Tester\x00'
<rg_img> ::= <byte>{192}

# Flavour 2 - Grayscale (BlackIsZero), 8-bit, little-endian. 12 tags.
# meta layout: xres(8) yres(8) soft(9) -> 25 bytes
<tiff_gray_le> ::= <gs_hdr> <gs_ifd> <gs_meta> <gs_img>
where <gs_off_xres>  == (8 + len(bytes(<gs_ifd>))).to_bytes(4, 'little')
where <gs_off_yres>  == (8 + len(bytes(<gs_ifd>)) + 8).to_bytes(4, 'little')
where <gs_off_soft>  == (8 + len(bytes(<gs_ifd>)) + 16).to_bytes(4, 'little')
where <gs_off_strip> == (8 + len(bytes(<gs_ifd>)) + len(bytes(<gs_meta>))).to_bytes(4, 'little')
where <gs_cnt_strip> == len(bytes(<gs_img>)).to_bytes(4, 'little')

<gs_hdr> ::= b'II' b'\x2a\x00' b'\x08\x00\x00\x00'
<gs_ifd> ::= b'\x0c\x00' <gs_entries> b'\x00\x00\x00\x00'
<gs_entries> ::= \
    b'\x00\x01' b'\x04\x00' b'\x01\x00\x00\x00' <gs_w> \
    b'\x01\x01' b'\x04\x00' b'\x01\x00\x00\x00' <gs_h> \
    b'\x02\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x08\x00\x00\x00' \
    b'\x03\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x01\x00\x00\x00' \
    b'\x06\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x01\x00\x00\x00' \
    b'\x11\x01' b'\x04\x00' b'\x01\x00\x00\x00' <gs_off_strip> \
    b'\x16\x01' b'\x04\x00' b'\x01\x00\x00\x00' b'\x08\x00\x00\x00' \
    b'\x17\x01' b'\x04\x00' b'\x01\x00\x00\x00' <gs_cnt_strip> \
    b'\x1a\x01' b'\x05\x00' b'\x01\x00\x00\x00' <gs_off_xres> \
    b'\x1b\x01' b'\x05\x00' b'\x01\x00\x00\x00' <gs_off_yres> \
    b'\x28\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x02\x00\x00\x00' \
    b'\x31\x01' b'\x02\x00' b'\x09\x00\x00\x00' <gs_off_soft>
<gs_w> ::= b'\x08\x00\x00\x00'
<gs_h> ::= b'\x08\x00\x00\x00'
<gs_off_strip> ::= <byte> <byte> <byte> <byte>
<gs_cnt_strip> ::= <byte> <byte> <byte> <byte>
<gs_off_xres>  ::= <byte> <byte> <byte> <byte>
<gs_off_yres>  ::= <byte> <byte> <byte> <byte>
<gs_off_soft>  ::= <byte> <byte> <byte> <byte>
<gs_meta> ::= b'\x2c\x01\x00\x00\x01\x00\x00\x00' \
              b'\x2c\x01\x00\x00\x01\x00\x00\x00' b'Fandango\x00'
<gs_img> ::= <byte>{64}

# Flavour 3 - Palette-colour, 4-bit + ColorMap, little-endian. 12 tags.
# ColorMap = 3 * 2^4 = 48 SHORTs (96 bytes) in the data region.
# meta layout: xres(8) yres(8) cmap(96) -> 112 bytes
<tiff_palette_le> ::= <pl_hdr> <pl_ifd> <pl_meta> <pl_img>
where <pl_off_xres>  == (8 + len(bytes(<pl_ifd>))).to_bytes(4, 'little')
where <pl_off_yres>  == (8 + len(bytes(<pl_ifd>)) + 8).to_bytes(4, 'little')
where <pl_off_cmap>  == (8 + len(bytes(<pl_ifd>)) + 16).to_bytes(4, 'little')
where <pl_off_strip> == (8 + len(bytes(<pl_ifd>)) + len(bytes(<pl_meta>))).to_bytes(4, 'little')
where <pl_cnt_strip> == len(bytes(<pl_img>)).to_bytes(4, 'little')

<pl_hdr> ::= b'II' b'\x2a\x00' b'\x08\x00\x00\x00'
<pl_ifd> ::= b'\x0c\x00' <pl_entries> b'\x00\x00\x00\x00'
<pl_entries> ::= \
    b'\x00\x01' b'\x04\x00' b'\x01\x00\x00\x00' <pl_w> \
    b'\x01\x01' b'\x04\x00' b'\x01\x00\x00\x00' <pl_h> \
    b'\x02\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x04\x00\x00\x00' \
    b'\x03\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x01\x00\x00\x00' \
    b'\x06\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x03\x00\x00\x00' \
    b'\x11\x01' b'\x04\x00' b'\x01\x00\x00\x00' <pl_off_strip> \
    b'\x16\x01' b'\x04\x00' b'\x01\x00\x00\x00' b'\x08\x00\x00\x00' \
    b'\x17\x01' b'\x04\x00' b'\x01\x00\x00\x00' <pl_cnt_strip> \
    b'\x1a\x01' b'\x05\x00' b'\x01\x00\x00\x00' <pl_off_xres> \
    b'\x1b\x01' b'\x05\x00' b'\x01\x00\x00\x00' <pl_off_yres> \
    b'\x28\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x02\x00\x00\x00' \
    b'\x40\x01' b'\x03\x00' b'\x30\x00\x00\x00' <pl_off_cmap>
<pl_w> ::= b'\x08\x00\x00\x00'
<pl_h> ::= b'\x08\x00\x00\x00'
<pl_off_strip> ::= <byte> <byte> <byte> <byte>
<pl_cnt_strip> ::= <byte> <byte> <byte> <byte>
<pl_off_xres>  ::= <byte> <byte> <byte> <byte>
<pl_off_yres>  ::= <byte> <byte> <byte> <byte>
<pl_off_cmap>  ::= <byte> <byte> <byte> <byte>
<pl_meta> ::= b'\x2c\x01\x00\x00\x01\x00\x00\x00' \
              b'\x2c\x01\x00\x00\x01\x00\x00\x00' <pl_cmap>
<pl_cmap> ::= <bpair>{48}
<pl_img> ::= <byte>{32}

# Flavour 4 - Bilevel (WhiteIsZero), 1-bit, little-endian. 11 tags.
# meta layout: xres(8) yres(8) -> 16 bytes
<tiff_bilevel_le> ::= <bl_hdr> <bl_ifd> <bl_meta> <bl_img>
where <bl_off_xres>  == (8 + len(bytes(<bl_ifd>))).to_bytes(4, 'little')
where <bl_off_yres>  == (8 + len(bytes(<bl_ifd>)) + 8).to_bytes(4, 'little')
where <bl_off_strip> == (8 + len(bytes(<bl_ifd>)) + len(bytes(<bl_meta>))).to_bytes(4, 'little')
where <bl_cnt_strip> == len(bytes(<bl_img>)).to_bytes(4, 'little')

<bl_hdr> ::= b'II' b'\x2a\x00' b'\x08\x00\x00\x00'
<bl_ifd> ::= b'\x0b\x00' <bl_entries> b'\x00\x00\x00\x00'
<bl_entries> ::= \
    b'\x00\x01' b'\x04\x00' b'\x01\x00\x00\x00' <bl_w> \
    b'\x01\x01' b'\x04\x00' b'\x01\x00\x00\x00' <bl_h> \
    b'\x02\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x01\x00\x00\x00' \
    b'\x03\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x01\x00\x00\x00' \
    b'\x06\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x00\x00\x00\x00' \
    b'\x11\x01' b'\x04\x00' b'\x01\x00\x00\x00' <bl_off_strip> \
    b'\x16\x01' b'\x04\x00' b'\x01\x00\x00\x00' b'\x08\x00\x00\x00' \
    b'\x17\x01' b'\x04\x00' b'\x01\x00\x00\x00' <bl_cnt_strip> \
    b'\x1a\x01' b'\x05\x00' b'\x01\x00\x00\x00' <bl_off_xres> \
    b'\x1b\x01' b'\x05\x00' b'\x01\x00\x00\x00' <bl_off_yres> \
    b'\x28\x01' b'\x03\x00' b'\x01\x00\x00\x00' b'\x02\x00\x00\x00'
<bl_w> ::= b'\x08\x00\x00\x00'
<bl_h> ::= b'\x08\x00\x00\x00'
<bl_off_strip> ::= <byte> <byte> <byte> <byte>
<bl_cnt_strip> ::= <byte> <byte> <byte> <byte>
<bl_off_xres>  ::= <byte> <byte> <byte> <byte>
<bl_off_yres>  ::= <byte> <byte> <byte> <byte>
<bl_meta> ::= b'\x2c\x01\x00\x00\x01\x00\x00\x00' \
              b'\x2c\x01\x00\x00\x01\x00\x00\x00'
<bl_img> ::= <byte>{8}

# Flavour 5 - Grayscale, 8-bit, big-endian ("MM"). 12 tags.
# Big endian (MM): magic, counts and LONGs are big endian, and SHORT values sit
# in the high two bytes of the 4 byte value field.
# meta layout: xres(8) yres(8) -> 16 bytes
<tiff_gray_be> ::= <be_hdr> <be_ifd> <be_meta> <be_img>
where <be_off_xres>  == (8 + len(bytes(<be_ifd>))).to_bytes(4, 'big')
where <be_off_yres>  == (8 + len(bytes(<be_ifd>)) + 8).to_bytes(4, 'big')
where <be_off_soft>  == (8 + len(bytes(<be_ifd>)) + 16).to_bytes(4, 'big')
where <be_off_strip> == (8 + len(bytes(<be_ifd>)) + len(bytes(<be_meta>))).to_bytes(4, 'big')
where <be_cnt_strip> == len(bytes(<be_img>)).to_bytes(4, 'big')

<be_hdr> ::= b'MM' b'\x00\x2a' b'\x00\x00\x00\x08'
<be_ifd> ::= b'\x00\x0c' <be_entries> b'\x00\x00\x00\x00'
<be_entries> ::= \
    b'\x01\x00' b'\x00\x04' b'\x00\x00\x00\x01' <be_w> \
    b'\x01\x01' b'\x00\x04' b'\x00\x00\x00\x01' <be_h> \
    b'\x01\x02' b'\x00\x03' b'\x00\x00\x00\x01' b'\x00\x08\x00\x00' \
    b'\x01\x03' b'\x00\x03' b'\x00\x00\x00\x01' b'\x00\x01\x00\x00' \
    b'\x01\x06' b'\x00\x03' b'\x00\x00\x00\x01' b'\x00\x01\x00\x00' \
    b'\x01\x11' b'\x00\x04' b'\x00\x00\x00\x01' <be_off_strip> \
    b'\x01\x16' b'\x00\x04' b'\x00\x00\x00\x01' b'\x00\x00\x00\x08' \
    b'\x01\x17' b'\x00\x04' b'\x00\x00\x00\x01' <be_cnt_strip> \
    b'\x01\x1a' b'\x00\x05' b'\x00\x00\x00\x01' <be_off_xres> \
    b'\x01\x1b' b'\x00\x05' b'\x00\x00\x00\x01' <be_off_yres> \
    b'\x01\x28' b'\x00\x03' b'\x00\x00\x00\x01' b'\x00\x02\x00\x00' \
    b'\x01\x31' b'\x00\x02' b'\x00\x00\x00\x09' <be_off_soft>
<be_w> ::= b'\x00\x00\x00\x08'
<be_h> ::= b'\x00\x00\x00\x08'
<be_off_strip> ::= <byte> <byte> <byte> <byte>
<be_cnt_strip> ::= <byte> <byte> <byte> <byte>
<be_off_xres>  ::= <byte> <byte> <byte> <byte>
<be_off_yres>  ::= <byte> <byte> <byte> <byte>
<be_off_soft>  ::= <byte> <byte> <byte> <byte>
<be_meta> ::= b'\x00\x00\x01\x2c\x00\x00\x00\x01' \
              b'\x00\x00\x01\x2c\x00\x00\x00\x01' b'Fandango\x00'
<be_img> ::= <byte>{64}

# Shared byte primitives.
<bpair> ::= <byte> <byte>
<byte>  ::= rb'[\x00-\xff]'
