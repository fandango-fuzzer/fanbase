# PNG with the registered extension chunks on top of the standard ones: APNG
# (acTL, fcTL, fdAT), cICP, mDCV, cLLI, eXIf, oFFs, pCAL, sCAL, sTER, gIFg,
# gIFt, gIFx, dSIG and one private chunk.
#
# Images are always a single pixel, so every colour type and bit depth
# combination, both interlace methods and the zlib data can be written out
# with fixed bytes and stay valid.
#
# TODO:
# * Expand to support more than one pixel, more than one IDAT, and more than one extension chunk.
# * Replace constant strings with computed values.

import zlib

def png_crc(data):
    """ISO 3309/ITU-T V.42 CRC-32 used by PNG chunks."""
    return zlib.crc32(data) & 0xffffffff


# Top-level PNG ordering and colour-type profiles

<start> ::= <png>
<png> ::= <png_signature> <png_image>
<png_signature> ::= b"\x89PNG\r\n\x1a\n"

<png_image> ::= <gray_image> | <truecolor_image> | <indexed_image> | <gray_alpha_image> | <rgba_image>

<gray_image> ::= <gray_low_image> | <gray_16_image>
<gray_low_image> ::= <IHDR_gray_low_chunk> <shared_pre_palette> <sBIT_gray_chunk>? <eXIf_chunk>? <bKGD_gray_chunk>? <tRNS_gray_chunk>? <shared_pre_data> <IDAT_gray_low_run> <shared_post_data> <IEND_chunk>
<gray_16_image> ::= <IHDR_gray_16_chunk> <shared_pre_palette> <sBIT_gray_chunk>? <eXIf_chunk>? <bKGD_gray_chunk>? <tRNS_gray_chunk>? <shared_pre_data> <IDAT_gray_16_run> <shared_post_data> <IEND_chunk>
<truecolor_image> ::= <truecolor_8_image> | <truecolor_16_image>
<truecolor_8_image> ::= <IHDR_true_8_chunk> <shared_pre_palette> <sBIT_true_chunk>? <eXIf_chunk>? <true_palette_part> <bKGD_true_chunk>? <tRNS_true_chunk>? <shared_pre_data> <IDAT_true_8_run> <shared_post_data> <IEND_chunk>
<truecolor_16_image> ::= <IHDR_true_16_chunk> <shared_pre_palette> <sBIT_true_chunk>? <eXIf_chunk>? <true_palette_part> <bKGD_true_chunk>? <tRNS_true_chunk>? <shared_pre_data> <IDAT_true_16_run> <shared_post_data> <IEND_chunk>
<indexed_image> ::= <IHDR_indexed_chunk> <shared_pre_palette> <sBIT_indexed_chunk>? <eXIf_chunk>? <PLTE_chunk> <hIST_chunk>? <bKGD_indexed_chunk>? <tRNS_indexed_chunk>? <shared_pre_data> <IDAT_indexed_run> <shared_post_data> <IEND_chunk>
<gray_alpha_image> ::= <gray_alpha_8_image> | <gray_alpha_16_image>
<gray_alpha_8_image> ::= <IHDR_gray_alpha_8_chunk> <shared_pre_palette> <sBIT_gray_alpha_chunk>? <eXIf_chunk>? <bKGD_gray_chunk>? <shared_pre_data> <IDAT_gray_alpha_8_run> <shared_post_data> <IEND_chunk>
<gray_alpha_16_image> ::= <IHDR_gray_alpha_16_chunk> <shared_pre_palette> <sBIT_gray_alpha_chunk>? <eXIf_chunk>? <bKGD_gray_chunk>? <shared_pre_data> <IDAT_gray_alpha_16_run> <shared_post_data> <IEND_chunk>
<rgba_image> ::= <rgba_8_image> | <rgba_16_image>
<rgba_8_image> ::= <IHDR_rgba_8_chunk> <shared_pre_palette> <sBIT_rgba_chunk>? <eXIf_chunk>? <rgba_palette_part> <bKGD_true_chunk>? <shared_pre_data> <rgba_8_data_stream> <shared_post_data> <IEND_chunk>
<rgba_16_image> ::= <IHDR_rgba_16_chunk> <shared_pre_palette> <sBIT_rgba_chunk>? <eXIf_chunk>? <rgba_palette_part> <bKGD_true_chunk>? <shared_pre_data> <rgba_16_data_stream> <shared_post_data> <IEND_chunk>

<true_palette_part> ::= b"" | <PLTE_chunk> <hIST_chunk>?
<rgba_palette_part> ::= b"" | <PLTE_chunk> <hIST_chunk>?

<shared_pre_palette> ::= <colour_space_chunks>
<colour_space_chunks> ::= b"" | <sRGB_chunk> | <iCCP_chunk> | <cICP_chunk> | <cHRM_chunk> <gAMA_chunk> | <cICP_chunk> <mDCV_chunk>? <cLLI_chunk>?

<shared_pre_data> ::= <pHYs_chunk>? <sPLT_chunk>? <oFFs_chunk>? <pCAL_chunk>? <sCAL_chunk>? <sTER_chunk>?
<shared_post_data> ::= <tEXt_chunk>? <zTXt_chunk>? <iTXt_chunk>? <tIME_chunk>? <gIFg_chunk>? <gIFt_chunk>? <gIFx_chunk>? <dSIG_chunk>? <unknown_ancillary_chunk>?


# IHDR: width, height, bit depth, colour type, compression, filter, interlace

<IHDR_indexed_chunk> ::= <IHDR_length> <IHDR_type> <IHDR_indexed_record>

<IHDR_length> ::= b"\x00\x00\x00\x0d"
<IHDR_type> ::= b"IHDR"

<IHDR_indexed_record> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x01\x03\x00\x00\x00%\xdbV\xca" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x01\x03\x00\x00\x01R\xdcf\x5c" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x02\x03\x00\x00\x00b{,\x1a" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x02\x03\x00\x00\x01\x15|\x1c\x8c" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x04\x03\x00\x00\x00\xed;\xd9\xba" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x04\x03\x00\x00\x01\x9a<\xe9," | b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x03\x00\x00\x00(\xcb4\xbb" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x03\x00\x00\x01_\xcc\x04-"

# Reachable IHDR partitions pair each legal bit-depth family with its scanline.
<IHDR_gray_low_chunk> ::= <IHDR_length> <IHDR_type> <IHDR_gray_low_record>
<IHDR_gray_16_chunk> ::= <IHDR_length> <IHDR_type> <IHDR_gray_16_record>
<IHDR_true_8_chunk> ::= <IHDR_length> <IHDR_type> <IHDR_true_8_record>
<IHDR_true_16_chunk> ::= <IHDR_length> <IHDR_type> <IHDR_true_16_record>
<IHDR_gray_alpha_8_chunk> ::= <IHDR_length> <IHDR_type> <IHDR_gray_alpha_8_record>
<IHDR_gray_alpha_16_chunk> ::= <IHDR_length> <IHDR_type> <IHDR_gray_alpha_16_record>
<IHDR_rgba_8_chunk> ::= <IHDR_length> <IHDR_type> <IHDR_rgba_8_record>
<IHDR_rgba_16_chunk> ::= <IHDR_length> <IHDR_type> <IHDR_rgba_16_record>

<IHDR_gray_low_record> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x01\x00\x00\x00\x007n\xf9$" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x01\x00\x00\x00\x01@i\xc9\xb2" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x02\x00\x00\x00\x00p\xce\x83\xf4" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x02\x00\x00\x00\x01\x07\xc9\xb3b" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\x00\x00\x00\xff\x8evT" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x04\x00\x00\x00\x01\x88\x89F\xc2" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x00\x00\x00\x00:~\x9bU" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x00\x00\x00\x01My\xab\xc3"
<IHDR_gray_16_record> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x10\x00\x00\x00\x00j\xeeG\x16" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x10\x00\x00\x00\x01\x1d\xe9w\x80"
<IHDR_true_8_record> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x01\xe7pcH"
<IHDR_true_16_record> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x10\x02\x00\x00\x00\xc0\xe7\x8f\x9d" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x10\x02\x00\x00\x01\xb7\xe0\xbf\x0b"
<IHDR_gray_alpha_8_record> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x04\x00\x00\x00\xb5\x1c\x0c\x02" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x04\x00\x00\x01\xc2\x1b<\x94"
<IHDR_gray_alpha_16_record> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x10\x04\x00\x00\x00\xe5\x8c\xd0A" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x10\x04\x00\x00\x01\x92\x8b\xe0\xd7"
<IHDR_rgba_8_record> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x01h\x12\xf4\x1f"
<IHDR_rgba_16_record> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x10\x06\x00\x00\x00O\x85\x18\xca" | b"\x00\x00\x00\x01\x00\x00\x00\x01\x10\x06\x00\x00\x018\x82(\\"


# PLTE: two RGB entries; mandatory for indexed, optional for truecolour

<PLTE_chunk> ::= <PLTE_length> <PLTE_type> <PLTE_data> <PLTE_crc>
<PLTE_length> ::= b"\x00\x00\x00\x06"
<PLTE_type> ::= b"PLTE"
<PLTE_data> ::= b"\x00\x00\x00\xff\xff\xff"
<PLTE_crc> ::= b"\xa5\xd9\x9f\xdd"


# IDAT: complete zlib streams and zero-length consecutive IDAT chunks

<IDAT_indexed_run> ::= <IDAT_empty_chunk>{0,2} <IDAT_indexed_chunk> <IDAT_empty_chunk>{0,2}

<IDAT_gray_low_run> ::= <IDAT_empty_chunk>{0,2} <IDAT_gray_low_chunk> <IDAT_empty_chunk>{0,2}
<IDAT_gray_16_run> ::= <IDAT_empty_chunk>{0,2} <IDAT_gray_16_chunk> <IDAT_empty_chunk>{0,2}
<IDAT_true_8_run> ::= <IDAT_empty_chunk>{0,2} <IDAT_true_8_chunk> <IDAT_empty_chunk>{0,2}
<IDAT_true_16_run> ::= <IDAT_empty_chunk>{0,2} <IDAT_true_16_chunk> <IDAT_empty_chunk>{0,2}
<IDAT_gray_alpha_8_run> ::= <IDAT_empty_chunk>{0,2} <IDAT_gray_alpha_8_chunk> <IDAT_empty_chunk>{0,2}
<IDAT_gray_alpha_16_run> ::= <IDAT_empty_chunk>{0,2} <IDAT_gray_alpha_16_chunk> <IDAT_empty_chunk>{0,2}
<IDAT_rgba_8_run> ::= <IDAT_empty_chunk>{0,2} <IDAT_rgba_8_chunk> <IDAT_empty_chunk>{0,2}
<IDAT_rgba_16_run> ::= <IDAT_empty_chunk>{0,2} <IDAT_rgba_16_chunk> <IDAT_empty_chunk>{0,2}

<IDAT_indexed_chunk> ::= <IDAT_indexed_record>
<IDAT_empty_chunk> ::= <IDAT_empty_length> <IDAT_type> <IDAT_empty_data> <IDAT_empty_crc>

<IDAT_type> ::= b"IDAT"
<IDAT_empty_length> ::= b"\x00\x00\x00\x00"
<IDAT_empty_data> ::= b""
<IDAT_empty_crc> ::= b"5\xaf\x06\x1e"

<IDAT_indexed_record> ::= b"\x00\x00\x00\x0aIDATx\x9cc`\x00\x00\x00\x02\x00\x01H\xaf\xa4q"

<IDAT_gray_low_chunk> ::= b"\x00\x00\x00\x0aIDATx\x9cc`\x00\x00\x00\x02\x00\x01H\xaf\xa4q"
<IDAT_gray_16_chunk> ::= b"\x00\x00\x00\x0bIDATx\x9cc``\x00\x00\x00\x03\x00\x01\xb8\xad:c"
<IDAT_true_8_chunk> ::= b"\x00\x00\x00\x0cIDATx\x9cc```\x00\x00\x00\x04\x00\x01\xf6\x178U"
<IDAT_true_16_chunk> ::= b"\x00\x00\x00\x0bIDATx\x9cc`\x00\x03\x00\x00\x07\x00\x01\xb2\x86\xac\xf4"
<IDAT_gray_alpha_8_chunk> ::= b"\x00\x00\x00\x0bIDATx\x9cc``\x00\x00\x00\x03\x00\x01\xb8\xad:c"
<IDAT_gray_alpha_16_chunk> ::= b"\x00\x00\x00\x0bIDATx\x9cc`\x00\x02\x00\x00\x05\x00\x01z^\xab?"
<IDAT_rgba_8_chunk> ::= b"\x00\x00\x00\x0bIDATx\x9cc`\x00\x02\x00\x00\x05\x00\x01z^\xab?"
<IDAT_rgba_16_chunk> ::= b"\x00\x00\x00\x0bIDATx\x9cc`\x80\x02\x00\x00\x09\x00\x01\xfbR\xb8\xa9"


# IEND

<IEND_chunk> ::= <IEND_length> <IEND_type> <IEND_data> <IEND_crc>
<IEND_length> ::= b"\x00\x00\x00\x00"
<IEND_type> ::= b"IEND"
<IEND_data> ::= b""
<IEND_crc> ::= b"\xaeB`\x82"


# Colour-space ancillary chunks

<cHRM_chunk> ::= <cHRM_length> <cHRM_type> <cHRM_data> <cHRM_crc>
<cHRM_length> ::= b"\x00\x00\x00\x20"
<cHRM_type> ::= b"cHRM"
<cHRM_data> ::= b"\x00\x00z&\x00\x00\x80\x84\x00\x00\xfa\x00\x00\x00\x80\xe8\x00\x00u0\x00\x00\xea`\x00\x00:\x98\x00\x00\x17p"
<cHRM_crc> ::= b"\x9c\xbaQ<"

<gAMA_chunk> ::= <gAMA_length> <gAMA_type> <gAMA_data> <gAMA_crc>
<gAMA_length> ::= b"\x00\x00\x00\x04"
<gAMA_type> ::= b"gAMA"
<gAMA_data> ::= b"\x00\x00\xb1\x8f"
<gAMA_crc> ::= b"\x0b\xfca\x05"

<iCCP_chunk> ::= <iCCP_length> <iCCP_type> <iCCP_data> <iCCP_crc>
<iCCP_length> ::= b"\x00\x00\x00\x49"
<iCCP_type> ::= b"iCCP"
<iCCP_data> ::= b"Fandango ICC\x00\x00x\x9cc``ha\x00\x02\x16\x03\x06\x86\xdc\xbc\x92\xa2 w'\x85\x88\xc8(\x05\xf6W\x0c\xec\x0cr\x0c< \xb9\xc4\xe4\xe2\x02\x06\xbc\xe0\xdb5\x06F\x10}Y\x17\xbf:\xec\x00\x00\xd7\x0b\x0a6"
<iCCP_crc> ::= b"D\xd8U\xbf"

<sRGB_chunk> ::= <sRGB_length> <sRGB_type> <sRGB_data> <sRGB_crc>
<sRGB_length> ::= b"\x00\x00\x00\x01"
<sRGB_type> ::= b"sRGB"
<sRGB_data> ::= b"\x00"
<sRGB_crc> ::= b"\xae\xce\x1c\xe9"

<cICP_chunk> ::= <cICP_length> <cICP_type> <cICP_data> <cICP_crc>
<cICP_length> ::= b"\x00\x00\x00\x04"
<cICP_type> ::= b"cICP"
<cICP_data> ::= b"\x01\x0d\x00\x01"
<cICP_crc> ::= b"\x9ci;2"

<mDCV_chunk> ::= <mDCV_length> <mDCV_type> <mDCV_data> <mDCV_crc>
<mDCV_length> ::= b"\x00\x00\x00\x18"
<mDCV_type> ::= b"mDCV"
<mDCV_data> ::= b"\x84\xd0>\x803\xc2\x86\xc4\x1dL\x0b\xb8=\x13@B\x00\x98\x96\x80\x00\x00\x002"
<mDCV_crc> ::= b"\xf2\xcc[\xf0"

<cLLI_chunk> ::= <cLLI_length> <cLLI_type> <cLLI_data> <cLLI_crc>
<cLLI_length> ::= b"\x00\x00\x00\x08"
<cLLI_type> ::= b"cLLI"
<cLLI_data> ::= b"\x00\x00\x03\xe8\x00\x00\x01\x90"
<cLLI_crc> ::= b"y\xd8\xfdx"


# Significant bits, background, histogram, and transparency

<sBIT_gray_chunk> ::= <sBIT_gray_length> <sBIT_type> <sBIT_gray_record>
<sBIT_true_chunk> ::= <sBIT_true_length> <sBIT_type> <sBIT_true_data> <sBIT_true_crc>
<sBIT_indexed_chunk> ::= <sBIT_indexed_length> <sBIT_type> <sBIT_indexed_data> <sBIT_indexed_crc>
<sBIT_gray_alpha_chunk> ::= <sBIT_gray_alpha_length> <sBIT_type> <sBIT_gray_alpha_data> <sBIT_gray_alpha_crc>
<sBIT_rgba_chunk> ::= <sBIT_rgba_length> <sBIT_type> <sBIT_rgba_data> <sBIT_rgba_crc>
<sBIT_type> ::= b"sBIT"

<sBIT_gray_length> ::= b"\x00\x00\x00\x01"
<sBIT_gray_record> ::= b"\x01\x9f\xd6\xe3="
<sBIT_true_length> ::= b"\x00\x00\x00\x03"
<sBIT_true_data> ::= b"\x08\x08\x08"
<sBIT_true_crc> ::= b"\xdb\xe1O\xe0"
<sBIT_indexed_length> ::= b"\x00\x00\x00\x03"
<sBIT_indexed_data> ::= b"\x08\x08\x08"
<sBIT_indexed_crc> ::= b"\xdb\xe1O\xe0"
<sBIT_gray_alpha_length> ::= b"\x00\x00\x00\x02"
<sBIT_gray_alpha_data> ::= b"\x08\x08"
<sBIT_gray_alpha_crc> ::= b"U\xecF\x04"
<sBIT_rgba_length> ::= b"\x00\x00\x00\x04"
<sBIT_rgba_data> ::= b"\x08\x08\x08\x08"
<sBIT_rgba_crc> ::= b"|\x08d\x88"


<bKGD_gray_chunk> ::= <bKGD_gray_length> <bKGD_type> <bKGD_gray_data> <bKGD_gray_crc>
<bKGD_true_chunk> ::= <bKGD_true_length> <bKGD_type> <bKGD_true_data> <bKGD_true_crc>
<bKGD_indexed_chunk> ::= <bKGD_indexed_length> <bKGD_type> <bKGD_indexed_data> <bKGD_indexed_crc>
<bKGD_type> ::= b"bKGD"
<bKGD_gray_length> ::= b"\x00\x00\x00\x02"
<bKGD_gray_data> ::= b"\x00\x00"
<bKGD_gray_crc> ::= b"\xaa\x8d#2"
<bKGD_true_length> ::= b"\x00\x00\x00\x06"
<bKGD_true_data> ::= b"\x00\x00\x00\x00\x00\x00"
<bKGD_true_crc> ::= b"\xf9C\xbb\x7f"
<bKGD_indexed_length> ::= b"\x00\x00\x00\x01"
<bKGD_indexed_data> ::= b"\x00"
<bKGD_indexed_crc> ::= b"\x88\x05\x1dH"

<hIST_chunk> ::= <hIST_length> <hIST_type> <hIST_data> <hIST_crc>
<hIST_length> ::= b"\x00\x00\x00\x04"
<hIST_type> ::= b"hIST"
<hIST_data> ::= b"\x00\x01\x00\x01"
<hIST_crc> ::= b"\x86\xf3\x1d>"

<tRNS_gray_chunk> ::= <tRNS_gray_length> <tRNS_type> <tRNS_gray_data> <tRNS_gray_crc>
<tRNS_true_chunk> ::= <tRNS_true_length> <tRNS_type> <tRNS_true_data> <tRNS_true_crc>
<tRNS_indexed_chunk> ::= <tRNS_indexed_length> <tRNS_type> <tRNS_indexed_data> <tRNS_indexed_crc>
<tRNS_type> ::= b"tRNS"
<tRNS_gray_length> ::= b"\x00\x00\x00\x02"
<tRNS_gray_data> ::= b"\x00\x00"
<tRNS_gray_crc> ::= b"v\x93\xcd8"
<tRNS_true_length> ::= b"\x00\x00\x00\x06"
<tRNS_true_data> ::= b"\x00\x00\x00\x00\x00\x00"
<tRNS_true_crc> ::= b"n\xa6\x07\x91"
<tRNS_indexed_length> ::= b"\x00\x00\x00\x02"
<tRNS_indexed_data> ::= b"\x00\xff"
<tRNS_indexed_crc> ::= b"[\x91\"\xb5"


# Physical dimensions, suggested palettes, calibration, and stereo layout

<pHYs_chunk> ::= <pHYs_length> <pHYs_type> <pHYs_data> <pHYs_crc>
<pHYs_length> ::= b"\x00\x00\x00\x09"
<pHYs_type> ::= b"pHYs"
<pHYs_data> ::= b"\x00\x00\x0e\xc4\x00\x00\x0e\xc4\x01"
<pHYs_crc> ::= b"\x95+\x0e\x1b"

<sPLT_chunk> ::= <sPLT_length> <sPLT_type> <sPLT_data> <sPLT_crc>
<sPLT_length> ::= b"\x00\x00\x00\x11"
<sPLT_type> ::= b"sPLT"
<sPLT_data> ::= b"Suggested\x00\x08\x00\x00\x00\xff\x00\x01"
<sPLT_crc> ::= b"\xbb\xf1\xd9\x05"

<oFFs_chunk> ::= <oFFs_length> <oFFs_type> <oFFs_data> <oFFs_crc>
<oFFs_length> ::= b"\x00\x00\x00\x09"
<oFFs_type> ::= b"oFFs"
<oFFs_data> ::= b"\x00\x00\x00\x00\x00\x00\x00\x00\x00"
<oFFs_crc> ::= b"\xda*\xb6\xce"

<pCAL_chunk> ::= <pCAL_length> <pCAL_type> <pCAL_data> <pCAL_crc>
<pCAL_length> ::= b"\x00\x00\x00\x1f"
<pCAL_type> ::= b"pCAL"
<pCAL_data> ::= b"Calibration\x00\x00\x00\x00\x00\x00\x00\x03\xe8\x00\x02unit\x000\x001\x00"
<pCAL_crc> ::= b"\xc4}\x9f\x81"

<sCAL_chunk> ::= <sCAL_length> <sCAL_type> <sCAL_data> <sCAL_crc>
<sCAL_length> ::= b"\x00\x00\x00\x08"
<sCAL_type> ::= b"sCAL"
<sCAL_data> ::= b"\x011.0\x001.0"
<sCAL_crc> ::= b"x;\xb2\x97"

<sTER_chunk> ::= <sTER_length> <sTER_type> <sTER_data> <sTER_crc>
<sTER_length> ::= b"\x00\x00\x00\x01"
<sTER_type> ::= b"sTER"
<sTER_data> ::= b"\x00"
<sTER_crc> ::= b"\xc2\xe3\x85\x0a"


# Exif, textual metadata, and modification time

<eXIf_chunk> ::= <eXIf_length> <eXIf_type> <eXIf_data> <eXIf_crc>
<eXIf_length> ::= b"\x00\x00\x00\x0c"
<eXIf_type> ::= b"eXIf"
<eXIf_data> ::= b"II*\x00\x08\x00\x00\x00\x00\x00\x00\x00"
<eXIf_crc> ::= b"$\x1f\x1c\xe4"

<tEXt_chunk> ::= <tEXt_length> <tEXt_type> <tEXt_data> <tEXt_crc>
<tEXt_length> ::= b"\x00\x00\x00\x1d"
<tEXt_type> ::= b"tEXt"
<tEXt_data> ::= b"Comment\x00Generated by Fandango"
<tEXt_crc> ::= b"\x88\xf1\x02c"

<zTXt_chunk> ::= <zTXt_length> <zTXt_type> <zTXt_data> <zTXt_crc>
<zTXt_length> ::= b"\x00\x00\x00\x26"
<zTXt_type> ::= b"zTXt"
<zTXt_data> ::= b"Comment\x00\x00x\x9csO\xcdK-J,IMQH\xaaTpK\xccKI\xccK\xcf\x07\x00U\x12\x07\xc9"
<zTXt_crc> ::= b"k\xd6\x09\xb0"

<iTXt_chunk> ::= <iTXt_length> <iTXt_type> <iTXt_data> <iTXt_crc>
<iTXt_length> ::= b"\x00\x00\x00\x27"
<iTXt_type> ::= b"iTXt"
<iTXt_data> ::= b"Description\x00\x00\x00en\x00Description\x00PNG corpus"
<iTXt_crc> ::= b"\xbe\xb4\xa7\x83"

<tIME_chunk> ::= <tIME_length> <tIME_type> <tIME_data> <tIME_crc>
<tIME_length> ::= b"\x00\x00\x00\x07"
<tIME_type> ::= b"tIME"
<tIME_data> ::= b"\x07\xea\x07\x1e\x0c\x00\x00"
<tIME_crc> ::= b"p\xf7\x97\x9c"


# APNG animation control, frame control, and frame data

<rgba_8_data_stream> ::= <IDAT_rgba_8_run> | <acTL_one_chunk> <fcTL_zero_chunk> <IDAT_rgba_8_run> | <acTL_two_chunk> <fcTL_zero_chunk> <IDAT_rgba_8_run> <fcTL_one_chunk> <fdAT_rgba_8_chunk>
<rgba_16_data_stream> ::= <IDAT_rgba_16_run> | <acTL_one_chunk> <fcTL_zero_chunk> <IDAT_rgba_16_run> | <acTL_two_chunk> <fcTL_zero_chunk> <IDAT_rgba_16_run> <fcTL_one_chunk> <fdAT_rgba_16_chunk>

<acTL_one_chunk> ::= <acTL_length> <acTL_type> <acTL_one_data> <acTL_one_crc>
<acTL_two_chunk> ::= <acTL_length> <acTL_type> <acTL_two_data> <acTL_two_crc>
<acTL_length> ::= b"\x00\x00\x00\x08"
<acTL_type> ::= b"acTL"
<acTL_one_data> ::= b"\x00\x00\x00\x01\x00\x00\x00\x00"
<acTL_one_crc> ::= b"\xb4-\xe9\xa0"
<acTL_two_data> ::= b"\x00\x00\x00\x02\x00\x00\x00\x00"
<acTL_two_crc> ::= b"\xf3\x8d\x93p"

<fcTL_zero_chunk> ::= <fcTL_length> <fcTL_type> <fcTL_zero_data> <fcTL_zero_crc>
<fcTL_one_chunk> ::= <fcTL_length> <fcTL_type> <fcTL_one_data> <fcTL_one_crc>
<fcTL_length> ::= b"\x00\x00\x00\x1a"
<fcTL_type> ::= b"fcTL"
<fcTL_zero_data> ::= b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x0a\x00\x00"
<fcTL_zero_crc> ::= b"Z\x7f0\xd0"
<fcTL_one_data> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x0a\x00\x01"
<fcTL_one_crc> ::= b"\xb6\x0b\xea\x92"

<fdAT_rgba_8_chunk> ::= b"\x00\x00\x00\x0ffdAT\x00\x00\x00\x02x\x9cc`\x00\x02\x00\x00\x05\x00\x01\xfc\xfff\xa0"
<fdAT_rgba_16_chunk> ::= b"\x00\x00\x00\x0ffdAT\x00\x00\x00\x02x\x9cc`\x80\x02\x00\x00\x09\x00\x01}\xf3u6"


# Registered extension chunks and a legal unknown ancillary chunk

<gIFg_chunk> ::= <gIFg_length> <gIFg_type> <gIFg_data> <gIFg_crc>
<gIFg_length> ::= b"\x00\x00\x00\x04"
<gIFg_type> ::= b"gIFg"
<gIFg_data> ::= b"\x00\x00\x00\x0a"
<gIFg_crc> ::= b"|Y\xedS"

<gIFt_chunk> ::= <gIFt_length> <gIFt_type> <gIFt_data> <gIFt_crc>
<gIFt_length> ::= b"\x00\x00\x00\x17"
<gIFt_type> ::= b"gIFt"
<gIFt_data> ::= b"\x00\x00\x00\x00\x00\x01\x00\x01\x08\x08\x00\x00\x00\xff\x00Fandango"
<gIFt_crc> ::= b"H*\xf1\xdc"

<gIFx_chunk> ::= <gIFx_length> <gIFx_type> <gIFx_data> <gIFx_crc>
<gIFx_length> ::= b"\x00\x00\x00\x14"
<gIFx_type> ::= b"gIFx"
<gIFx_data> ::= b"FANDANGO001extension"
<gIFx_crc> ::= b"\x1cW\x92\xc4"

<dSIG_chunk> ::= <dSIG_length> <dSIG_type> <dSIG_data> <dSIG_crc>
<dSIG_length> ::= b"\x00\x00\x00\x1a"
<dSIG_type> ::= b"dSIG"
<dSIG_data> ::= b"Fandango signature fixture"
<dSIG_crc> ::= b"I\xb5\x84e"

<unknown_ancillary_chunk> ::= <unknown_length> <unknown_type> <unknown_data> <unknown_crc>
<unknown_length> ::= b"\x00\x00\x00\x04"
<unknown_type> ::= b"vpAg"
<unknown_data> ::= b"fuzz"
<unknown_crc> ::= b"%\x14\xee\xfb"


# IHDR profiles.
where int.from_bytes(bytes(<IHDR_indexed_chunk>)[0:4], "big") == len(bytes(<IHDR_indexed_chunk>)) - 12 and bytes(<IHDR_indexed_chunk>)[4:8] == b"IHDR" and bytes(<IHDR_indexed_chunk>)[16] in (1, 2, 4, 8) and bytes(<IHDR_indexed_chunk>)[17] == 3 and bytes(<IHDR_indexed_chunk>)[18:20] == b"\x00\x00" and bytes(<IHDR_indexed_chunk>)[20] in (0, 1) and int.from_bytes(bytes(<IHDR_indexed_chunk>)[-4:], "big") == png_crc(bytes(<IHDR_indexed_chunk>)[4:-4])
where int.from_bytes(bytes(<IHDR_gray_low_chunk>)[0:4], "big") == 13 and bytes(<IHDR_gray_low_chunk>)[16] in (1, 2, 4, 8) and bytes(<IHDR_gray_low_chunk>)[17] == 0 and int.from_bytes(bytes(<IHDR_gray_low_chunk>)[-4:], "big") == png_crc(bytes(<IHDR_gray_low_chunk>)[4:-4])
where int.from_bytes(bytes(<IHDR_gray_16_chunk>)[0:4], "big") == 13 and bytes(<IHDR_gray_16_chunk>)[16] == 16 and bytes(<IHDR_gray_16_chunk>)[17] == 0 and int.from_bytes(bytes(<IHDR_gray_16_chunk>)[-4:], "big") == png_crc(bytes(<IHDR_gray_16_chunk>)[4:-4])
where int.from_bytes(bytes(<IHDR_true_8_chunk>)[0:4], "big") == 13 and bytes(<IHDR_true_8_chunk>)[16:18] == b"\x08\x02" and int.from_bytes(bytes(<IHDR_true_8_chunk>)[-4:], "big") == png_crc(bytes(<IHDR_true_8_chunk>)[4:-4])
where int.from_bytes(bytes(<IHDR_true_16_chunk>)[0:4], "big") == 13 and bytes(<IHDR_true_16_chunk>)[16:18] == b"\x10\x02" and int.from_bytes(bytes(<IHDR_true_16_chunk>)[-4:], "big") == png_crc(bytes(<IHDR_true_16_chunk>)[4:-4])
where int.from_bytes(bytes(<IHDR_gray_alpha_8_chunk>)[0:4], "big") == 13 and bytes(<IHDR_gray_alpha_8_chunk>)[16:18] == b"\x08\x04" and int.from_bytes(bytes(<IHDR_gray_alpha_8_chunk>)[-4:], "big") == png_crc(bytes(<IHDR_gray_alpha_8_chunk>)[4:-4])
where int.from_bytes(bytes(<IHDR_gray_alpha_16_chunk>)[0:4], "big") == 13 and bytes(<IHDR_gray_alpha_16_chunk>)[16:18] == b"\x10\x04" and int.from_bytes(bytes(<IHDR_gray_alpha_16_chunk>)[-4:], "big") == png_crc(bytes(<IHDR_gray_alpha_16_chunk>)[4:-4])
where int.from_bytes(bytes(<IHDR_rgba_8_chunk>)[0:4], "big") == 13 and bytes(<IHDR_rgba_8_chunk>)[16:18] == b"\x08\x06" and int.from_bytes(bytes(<IHDR_rgba_8_chunk>)[-4:], "big") == png_crc(bytes(<IHDR_rgba_8_chunk>)[4:-4])
where int.from_bytes(bytes(<IHDR_rgba_16_chunk>)[0:4], "big") == 13 and bytes(<IHDR_rgba_16_chunk>)[16:18] == b"\x10\x06" and int.from_bytes(bytes(<IHDR_rgba_16_chunk>)[-4:], "big") == png_crc(bytes(<IHDR_rgba_16_chunk>)[4:-4])

# PLTE, IDAT streams, and IEND.
where int.from_bytes(bytes(<PLTE_chunk>)[0:4], "big") == len(bytes(<PLTE_chunk>)) - 12 and 1 <= (len(bytes(<PLTE_chunk>)) - 12) // 3 <= 256 and (len(bytes(<PLTE_chunk>)) - 12) % 3 == 0 and int.from_bytes(bytes(<PLTE_chunk>)[-4:], "big") == png_crc(bytes(<PLTE_chunk>)[4:-4])
where (len(bytes(<PLTE_chunk>)) - 12) // 3 <= 2 ** bytes(<IHDR_indexed_record>)[8]
where int.from_bytes(bytes(<IDAT_empty_chunk>)[0:4], "big") == len(bytes(<IDAT_empty_chunk>)) - 12 and int.from_bytes(bytes(<IDAT_empty_chunk>)[-4:], "big") == png_crc(bytes(<IDAT_empty_chunk>)[4:-4])
where int.from_bytes(bytes(<IDAT_indexed_chunk>)[0:4], "big") == len(bytes(<IDAT_indexed_chunk>)) - 12 and zlib.decompress(bytes(<IDAT_indexed_chunk>)[8:-4]) == b"\x00\x00" and int.from_bytes(bytes(<IDAT_indexed_chunk>)[-4:], "big") == png_crc(bytes(<IDAT_indexed_chunk>)[4:-4])
where int.from_bytes(bytes(<IDAT_gray_low_chunk>)[0:4], "big") == len(bytes(<IDAT_gray_low_chunk>)) - 12 and zlib.decompress(bytes(<IDAT_gray_low_chunk>)[8:-4]) == b"\x00\x00" and int.from_bytes(bytes(<IDAT_gray_low_chunk>)[-4:], "big") == png_crc(bytes(<IDAT_gray_low_chunk>)[4:-4])
where int.from_bytes(bytes(<IDAT_gray_16_chunk>)[0:4], "big") == len(bytes(<IDAT_gray_16_chunk>)) - 12 and zlib.decompress(bytes(<IDAT_gray_16_chunk>)[8:-4]) == b"\x00\x00\x00" and int.from_bytes(bytes(<IDAT_gray_16_chunk>)[-4:], "big") == png_crc(bytes(<IDAT_gray_16_chunk>)[4:-4])
where int.from_bytes(bytes(<IDAT_true_8_chunk>)[0:4], "big") == len(bytes(<IDAT_true_8_chunk>)) - 12 and zlib.decompress(bytes(<IDAT_true_8_chunk>)[8:-4]) == b"\x00\x00\x00\x00" and int.from_bytes(bytes(<IDAT_true_8_chunk>)[-4:], "big") == png_crc(bytes(<IDAT_true_8_chunk>)[4:-4])
where int.from_bytes(bytes(<IDAT_true_16_chunk>)[0:4], "big") == len(bytes(<IDAT_true_16_chunk>)) - 12 and zlib.decompress(bytes(<IDAT_true_16_chunk>)[8:-4]) == b"\x00\x00\x00\x00\x00\x00\x00" and int.from_bytes(bytes(<IDAT_true_16_chunk>)[-4:], "big") == png_crc(bytes(<IDAT_true_16_chunk>)[4:-4])
where int.from_bytes(bytes(<IDAT_gray_alpha_8_chunk>)[0:4], "big") == len(bytes(<IDAT_gray_alpha_8_chunk>)) - 12 and zlib.decompress(bytes(<IDAT_gray_alpha_8_chunk>)[8:-4]) == b"\x00\x00\x00" and int.from_bytes(bytes(<IDAT_gray_alpha_8_chunk>)[-4:], "big") == png_crc(bytes(<IDAT_gray_alpha_8_chunk>)[4:-4])
where int.from_bytes(bytes(<IDAT_gray_alpha_16_chunk>)[0:4], "big") == len(bytes(<IDAT_gray_alpha_16_chunk>)) - 12 and zlib.decompress(bytes(<IDAT_gray_alpha_16_chunk>)[8:-4]) == b"\x00\x00\x00\x00\x00" and int.from_bytes(bytes(<IDAT_gray_alpha_16_chunk>)[-4:], "big") == png_crc(bytes(<IDAT_gray_alpha_16_chunk>)[4:-4])
where int.from_bytes(bytes(<IDAT_rgba_8_chunk>)[0:4], "big") == len(bytes(<IDAT_rgba_8_chunk>)) - 12 and zlib.decompress(bytes(<IDAT_rgba_8_chunk>)[8:-4]) == b"\x00\x00\x00\x00\x00" and int.from_bytes(bytes(<IDAT_rgba_8_chunk>)[-4:], "big") == png_crc(bytes(<IDAT_rgba_8_chunk>)[4:-4])
where int.from_bytes(bytes(<IDAT_rgba_16_chunk>)[0:4], "big") == len(bytes(<IDAT_rgba_16_chunk>)) - 12 and zlib.decompress(bytes(<IDAT_rgba_16_chunk>)[8:-4]) == b"\x00\x00\x00\x00\x00\x00\x00\x00\x00" and int.from_bytes(bytes(<IDAT_rgba_16_chunk>)[-4:], "big") == png_crc(bytes(<IDAT_rgba_16_chunk>)[4:-4])
where int.from_bytes(bytes(<IEND_chunk>)[0:4], "big") == 0 and len(bytes(<IEND_chunk>)) == 12 and int.from_bytes(bytes(<IEND_chunk>)[-4:], "big") == png_crc(bytes(<IEND_chunk>)[4:-4])

# Colour-space chunks.
where int.from_bytes(bytes(<cHRM_chunk>)[0:4], "big") == 32 and len(bytes(<cHRM_chunk>)) == 44 and int.from_bytes(bytes(<cHRM_chunk>)[-4:], "big") == png_crc(bytes(<cHRM_chunk>)[4:-4])
where int.from_bytes(bytes(<gAMA_chunk>)[0:4], "big") == 4 and int.from_bytes(bytes(<gAMA_chunk>)[8:12], "big") > 0 and int.from_bytes(bytes(<gAMA_chunk>)[-4:], "big") == png_crc(bytes(<gAMA_chunk>)[4:-4])
where int.from_bytes(bytes(<iCCP_chunk>)[0:4], "big") == len(bytes(<iCCP_chunk>)) - 12 and 1 <= bytes(<iCCP_chunk>)[8:-4].index(b"\x00") <= 79 and bytes(<iCCP_chunk>)[8:-4][bytes(<iCCP_chunk>)[8:-4].index(b"\x00") + 1] == 0 and zlib.decompress(bytes(<iCCP_chunk>)[8:-4][bytes(<iCCP_chunk>)[8:-4].index(b"\x00") + 2:])[36:40] == b"acsp" and int.from_bytes(bytes(<iCCP_chunk>)[-4:], "big") == png_crc(bytes(<iCCP_chunk>)[4:-4])
where int.from_bytes(bytes(<sRGB_chunk>)[0:4], "big") == 1 and bytes(<sRGB_chunk>)[8] in (0, 1, 2, 3) and int.from_bytes(bytes(<sRGB_chunk>)[-4:], "big") == png_crc(bytes(<sRGB_chunk>)[4:-4])
where int.from_bytes(bytes(<cICP_chunk>)[0:4], "big") == 4 and bytes(<cICP_chunk>)[8] != 0 and bytes(<cICP_chunk>)[9] != 0 and bytes(<cICP_chunk>)[11] in (0, 1) and int.from_bytes(bytes(<cICP_chunk>)[-4:], "big") == png_crc(bytes(<cICP_chunk>)[4:-4])
where int.from_bytes(bytes(<mDCV_chunk>)[0:4], "big") == 24 and int.from_bytes(bytes(<mDCV_chunk>)[24:28], "big") >= int.from_bytes(bytes(<mDCV_chunk>)[28:32], "big") and int.from_bytes(bytes(<mDCV_chunk>)[-4:], "big") == png_crc(bytes(<mDCV_chunk>)[4:-4])
where int.from_bytes(bytes(<cLLI_chunk>)[0:4], "big") == 8 and int.from_bytes(bytes(<cLLI_chunk>)[8:12], "big") >= int.from_bytes(bytes(<cLLI_chunk>)[12:16], "big") and int.from_bytes(bytes(<cLLI_chunk>)[-4:], "big") == png_crc(bytes(<cLLI_chunk>)[4:-4])

# Significant bits and palette-dependent chunks.
where int.from_bytes(bytes(<sBIT_gray_chunk>)[0:4], "big") == 1 and bytes(<sBIT_gray_chunk>)[8] == 1 and int.from_bytes(bytes(<sBIT_gray_chunk>)[-4:], "big") == png_crc(bytes(<sBIT_gray_chunk>)[4:-4])
where int.from_bytes(bytes(<sBIT_true_chunk>)[0:4], "big") == 3 and 1 <= min(bytes(<sBIT_true_chunk>)[8:-4]) <= max(bytes(<sBIT_true_chunk>)[8:-4]) <= 16 and int.from_bytes(bytes(<sBIT_true_chunk>)[-4:], "big") == png_crc(bytes(<sBIT_true_chunk>)[4:-4])
where int.from_bytes(bytes(<sBIT_indexed_chunk>)[0:4], "big") == 3 and max(bytes(<sBIT_indexed_chunk>)[8:-4]) <= 8 and int.from_bytes(bytes(<sBIT_indexed_chunk>)[-4:], "big") == png_crc(bytes(<sBIT_indexed_chunk>)[4:-4])
where int.from_bytes(bytes(<sBIT_gray_alpha_chunk>)[0:4], "big") == 2 and 1 <= min(bytes(<sBIT_gray_alpha_chunk>)[8:-4]) <= max(bytes(<sBIT_gray_alpha_chunk>)[8:-4]) <= 16 and int.from_bytes(bytes(<sBIT_gray_alpha_chunk>)[-4:], "big") == png_crc(bytes(<sBIT_gray_alpha_chunk>)[4:-4])
where int.from_bytes(bytes(<sBIT_rgba_chunk>)[0:4], "big") == 4 and 1 <= min(bytes(<sBIT_rgba_chunk>)[8:-4]) <= max(bytes(<sBIT_rgba_chunk>)[8:-4]) <= 16 and int.from_bytes(bytes(<sBIT_rgba_chunk>)[-4:], "big") == png_crc(bytes(<sBIT_rgba_chunk>)[4:-4])
where int.from_bytes(bytes(<bKGD_gray_chunk>)[0:4], "big") == 2 and int.from_bytes(bytes(<bKGD_gray_chunk>)[-4:], "big") == png_crc(bytes(<bKGD_gray_chunk>)[4:-4])
where int.from_bytes(bytes(<bKGD_true_chunk>)[0:4], "big") == 6 and int.from_bytes(bytes(<bKGD_true_chunk>)[-4:], "big") == png_crc(bytes(<bKGD_true_chunk>)[4:-4])
where int.from_bytes(bytes(<bKGD_indexed_chunk>)[0:4], "big") == 1 and bytes(<bKGD_indexed_chunk>)[8] < (len(bytes(<PLTE_chunk>)) - 12) // 3 and int.from_bytes(bytes(<bKGD_indexed_chunk>)[-4:], "big") == png_crc(bytes(<bKGD_indexed_chunk>)[4:-4])
where int.from_bytes(bytes(<hIST_chunk>)[0:4], "big") == 2 * ((len(bytes(<PLTE_chunk>)) - 12) // 3) and int.from_bytes(bytes(<hIST_chunk>)[-4:], "big") == png_crc(bytes(<hIST_chunk>)[4:-4])
where int.from_bytes(bytes(<tRNS_gray_chunk>)[0:4], "big") == 2 and int.from_bytes(bytes(<tRNS_gray_chunk>)[-4:], "big") == png_crc(bytes(<tRNS_gray_chunk>)[4:-4])
where int.from_bytes(bytes(<tRNS_true_chunk>)[0:4], "big") == 6 and int.from_bytes(bytes(<tRNS_true_chunk>)[-4:], "big") == png_crc(bytes(<tRNS_true_chunk>)[4:-4])
where 1 <= int.from_bytes(bytes(<tRNS_indexed_chunk>)[0:4], "big") <= (len(bytes(<PLTE_chunk>)) - 12) // 3 and int.from_bytes(bytes(<tRNS_indexed_chunk>)[-4:], "big") == png_crc(bytes(<tRNS_indexed_chunk>)[4:-4])

# Physical, calibration, Exif, text, and time chunks.
where int.from_bytes(bytes(<pHYs_chunk>)[0:4], "big") == 9 and int.from_bytes(bytes(<pHYs_chunk>)[8:12], "big") > 0 and int.from_bytes(bytes(<pHYs_chunk>)[12:16], "big") > 0 and bytes(<pHYs_chunk>)[16] in (0, 1) and int.from_bytes(bytes(<pHYs_chunk>)[-4:], "big") == png_crc(bytes(<pHYs_chunk>)[4:-4])
where int.from_bytes(bytes(<sPLT_chunk>)[0:4], "big") == len(bytes(<sPLT_chunk>)) - 12 and 1 <= bytes(<sPLT_chunk>)[8:-4].index(b"\x00") <= 79 and bytes(<sPLT_chunk>)[8:-4][bytes(<sPLT_chunk>)[8:-4].index(b"\x00") + 1] in (8, 16) and int.from_bytes(bytes(<sPLT_chunk>)[-4:], "big") == png_crc(bytes(<sPLT_chunk>)[4:-4])
where int.from_bytes(bytes(<oFFs_chunk>)[0:4], "big") == 9 and bytes(<oFFs_chunk>)[16] in (0, 1) and int.from_bytes(bytes(<oFFs_chunk>)[-4:], "big") == png_crc(bytes(<oFFs_chunk>)[4:-4])
where int.from_bytes(bytes(<pCAL_chunk>)[0:4], "big") == len(bytes(<pCAL_chunk>)) - 12 and 1 <= bytes(<pCAL_chunk>)[8:-4].index(b"\x00") <= 79 and int.from_bytes(bytes(<pCAL_chunk>)[-4:], "big") == png_crc(bytes(<pCAL_chunk>)[4:-4])
where int.from_bytes(bytes(<sCAL_chunk>)[0:4], "big") == 8 and bytes(<sCAL_chunk>)[8] in (1, 2) and float(bytes(<sCAL_chunk>)[9:12]) > 0 and float(bytes(<sCAL_chunk>)[13:-4]) > 0 and int.from_bytes(bytes(<sCAL_chunk>)[-4:], "big") == png_crc(bytes(<sCAL_chunk>)[4:-4])
where int.from_bytes(bytes(<sTER_chunk>)[0:4], "big") == 1 and bytes(<sTER_chunk>)[8] in (0, 1) and int.from_bytes(bytes(<sTER_chunk>)[-4:], "big") == png_crc(bytes(<sTER_chunk>)[4:-4])
where int.from_bytes(bytes(<eXIf_chunk>)[0:4], "big") == len(bytes(<eXIf_chunk>)) - 12 and bytes(<eXIf_chunk>)[8:12] in (b"II*\x00", b"MM\x00*") and int.from_bytes(bytes(<eXIf_chunk>)[-4:], "big") == png_crc(bytes(<eXIf_chunk>)[4:-4])
where int.from_bytes(bytes(<tEXt_chunk>)[0:4], "big") == len(bytes(<tEXt_chunk>)) - 12 and 1 <= bytes(<tEXt_chunk>)[8:-4].index(b"\x00") <= 79 and int.from_bytes(bytes(<tEXt_chunk>)[-4:], "big") == png_crc(bytes(<tEXt_chunk>)[4:-4])
where int.from_bytes(bytes(<zTXt_chunk>)[0:4], "big") == len(bytes(<zTXt_chunk>)) - 12 and bytes(<zTXt_chunk>)[8:-4][bytes(<zTXt_chunk>)[8:-4].index(b"\x00") + 1] == 0 and len(zlib.decompress(bytes(<zTXt_chunk>)[8:-4][bytes(<zTXt_chunk>)[8:-4].index(b"\x00") + 2:])) > 0 and int.from_bytes(bytes(<zTXt_chunk>)[-4:], "big") == png_crc(bytes(<zTXt_chunk>)[4:-4])
where int.from_bytes(bytes(<iTXt_chunk>)[0:4], "big") == len(bytes(<iTXt_chunk>)) - 12 and bytes(<iTXt_chunk>)[8:-4][bytes(<iTXt_chunk>)[8:-4].index(b"\x00") + 1] in (0, 1) and bytes(<iTXt_chunk>)[8:-4][bytes(<iTXt_chunk>)[8:-4].index(b"\x00") + 2] == 0 and int.from_bytes(bytes(<iTXt_chunk>)[-4:], "big") == png_crc(bytes(<iTXt_chunk>)[4:-4])
where int.from_bytes(bytes(<tIME_chunk>)[0:4], "big") == 7 and 1 <= bytes(<tIME_chunk>)[10] <= 12 and 1 <= bytes(<tIME_chunk>)[11] <= 31 and bytes(<tIME_chunk>)[12] <= 23 and bytes(<tIME_chunk>)[13] <= 59 and bytes(<tIME_chunk>)[14] <= 60 and int.from_bytes(bytes(<tIME_chunk>)[-4:], "big") == png_crc(bytes(<tIME_chunk>)[4:-4])

# APNG sequence and frame relationships.
where int.from_bytes(bytes(<acTL_one_chunk>)[0:4], "big") == 8 and int.from_bytes(bytes(<acTL_one_chunk>)[8:12], "big") == 1 and int.from_bytes(bytes(<acTL_one_chunk>)[-4:], "big") == png_crc(bytes(<acTL_one_chunk>)[4:-4])
where int.from_bytes(bytes(<acTL_two_chunk>)[0:4], "big") == 8 and int.from_bytes(bytes(<acTL_two_chunk>)[8:12], "big") == 2 and int.from_bytes(bytes(<acTL_two_chunk>)[-4:], "big") == png_crc(bytes(<acTL_two_chunk>)[4:-4])
where int.from_bytes(bytes(<fcTL_zero_chunk>)[0:4], "big") == 26 and int.from_bytes(bytes(<fcTL_zero_chunk>)[8:12], "big") == 0 and int.from_bytes(bytes(<fcTL_zero_chunk>)[12:16], "big") == 1 and int.from_bytes(bytes(<fcTL_zero_chunk>)[16:20], "big") == 1 and bytes(<fcTL_zero_chunk>)[32] in (0, 1, 2) and bytes(<fcTL_zero_chunk>)[33] in (0, 1) and int.from_bytes(bytes(<fcTL_zero_chunk>)[-4:], "big") == png_crc(bytes(<fcTL_zero_chunk>)[4:-4])
where int.from_bytes(bytes(<fcTL_one_chunk>)[0:4], "big") == 26 and int.from_bytes(bytes(<fcTL_one_chunk>)[8:12], "big") == 1 and bytes(<fcTL_one_chunk>)[32] in (0, 1, 2) and bytes(<fcTL_one_chunk>)[33] in (0, 1) and int.from_bytes(bytes(<fcTL_one_chunk>)[-4:], "big") == png_crc(bytes(<fcTL_one_chunk>)[4:-4])
where int.from_bytes(bytes(<fdAT_rgba_8_chunk>)[0:4], "big") == len(bytes(<fdAT_rgba_8_chunk>)) - 12 and int.from_bytes(bytes(<fdAT_rgba_8_chunk>)[8:12], "big") == 2 and zlib.decompress(bytes(<fdAT_rgba_8_chunk>)[12:-4]) == b"\x00\x00\x00\x00\x00" and int.from_bytes(bytes(<fdAT_rgba_8_chunk>)[-4:], "big") == png_crc(bytes(<fdAT_rgba_8_chunk>)[4:-4])
where int.from_bytes(bytes(<fdAT_rgba_16_chunk>)[0:4], "big") == len(bytes(<fdAT_rgba_16_chunk>)) - 12 and int.from_bytes(bytes(<fdAT_rgba_16_chunk>)[8:12], "big") == 2 and zlib.decompress(bytes(<fdAT_rgba_16_chunk>)[12:-4]) == b"\x00\x00\x00\x00\x00\x00\x00\x00\x00" and int.from_bytes(bytes(<fdAT_rgba_16_chunk>)[-4:], "big") == png_crc(bytes(<fdAT_rgba_16_chunk>)[4:-4])

# Registered extensions and unknown-chunk property bits.
where int.from_bytes(bytes(<gIFg_chunk>)[0:4], "big") == 4 and bytes(<gIFg_chunk>)[8] <= 3 and bytes(<gIFg_chunk>)[9] in (0, 1) and int.from_bytes(bytes(<gIFg_chunk>)[-4:], "big") == png_crc(bytes(<gIFg_chunk>)[4:-4])
where int.from_bytes(bytes(<gIFt_chunk>)[0:4], "big") == len(bytes(<gIFt_chunk>)) - 12 and int.from_bytes(bytes(<gIFt_chunk>)[12:14], "big") > 0 and int.from_bytes(bytes(<gIFt_chunk>)[14:16], "big") > 0 and int.from_bytes(bytes(<gIFt_chunk>)[-4:], "big") == png_crc(bytes(<gIFt_chunk>)[4:-4])
where int.from_bytes(bytes(<gIFx_chunk>)[0:4], "big") == len(bytes(<gIFx_chunk>)) - 12 and len(bytes(<gIFx_chunk>)[8:16]) == 8 and len(bytes(<gIFx_chunk>)[16:19]) == 3 and int.from_bytes(bytes(<gIFx_chunk>)[-4:], "big") == png_crc(bytes(<gIFx_chunk>)[4:-4])
where int.from_bytes(bytes(<dSIG_chunk>)[0:4], "big") == len(bytes(<dSIG_chunk>)) - 12 and len(bytes(<dSIG_chunk>)) > 12 and int.from_bytes(bytes(<dSIG_chunk>)[-4:], "big") == png_crc(bytes(<dSIG_chunk>)[4:-4])
where int.from_bytes(bytes(<unknown_ancillary_chunk>)[0:4], "big") == len(bytes(<unknown_ancillary_chunk>)) - 12 and bytes(<unknown_ancillary_chunk>)[4] & 32 == 32 and bytes(<unknown_ancillary_chunk>)[6] & 32 == 0 and bytes(<unknown_ancillary_chunk>)[7] & 32 == 32 and int.from_bytes(bytes(<unknown_ancillary_chunk>)[-4:], "big") == png_crc(bytes(<unknown_ancillary_chunk>)[4:-4])
