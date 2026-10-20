# PNG at the chunk level: signature, chunk framing (length, type, data,
# CRC-32), chunk order, and the layout of each ancillary chunk.
#
# IDAT holds arbitrary bytes instead of a zlib stream and has nothing to do
# with the size in IHDR, so most files do not decode. Meant for chunk parsers,
# not for pixel decoders.
# 
# TODO:
# * Could this serve as a template for the other `png.fan` specs?
# * Try not to depend on `random`; let Fandango do this
# * Indexed images (and so PLTE and hIST) hardly ever come out: Fandango picks
#   the other colour types. They do when <image> is <image_indexed> alone.


import random
import zlib

<start> ::= <png>

<png> ::= <signature> <cgbi_chunk>? <image>

# The colour type in IHDR decides whether there is a PLTE, how large it may be,
# and which tRNS and bKGD there can be: one layout per colour type (and, for
# indexed images, per bit depth), so that these follow from the grammar.
<image> ::= <image_gray> | <image_truecolor> | <image_indexed> | <image_gray_alpha> | <image_truecolor_alpha>
<image_gray>            ::= <ihdr_gray> <chunks_before_plte> <after_plte_gray> <image_end>
<image_truecolor>       ::= <ihdr_truecolor> <chunks_before_plte> <after_plte_truecolor> <image_end>
<image_gray_alpha>      ::= <ihdr_gray_alpha> <chunks_before_plte> <after_plte_gray_alpha> <image_end>
<image_truecolor_alpha> ::= <ihdr_truecolor_alpha> <chunks_before_plte> <after_plte_truecolor_alpha> <image_end>
<image_indexed>         ::= <image_indexed_1> | <image_indexed_2> | <image_indexed_4> | <image_indexed_8>
<image_indexed_1> ::= <ihdr_indexed_1> <chunks_before_plte> <plte_chunk_1> <after_plte_indexed> <image_end>
<image_indexed_2> ::= <ihdr_indexed_2> <chunks_before_plte> <plte_chunk_2> <after_plte_indexed> <image_end>
<image_indexed_4> ::= <ihdr_indexed_4> <chunks_before_plte> <plte_chunk_4> <after_plte_indexed> <image_end>
<image_indexed_8> ::= <ihdr_indexed_8> <chunks_before_plte> <plte_chunk_8> <after_plte_indexed> <image_end>
<image_end>             ::= <idat_chunk>+ <chunks_after_idat> <iend_chunk>

<signature> ::= b'\x89PNG\r\n\x1a\n'

# CgBI: Apple's non-standard chunk for iOS-optimised PNGs. It goes before IHDR.

<cgbi_chunk>  ::= <cgbi_length> <cgbi_type> <cgbi_data> <cgbi_crc>
<cgbi_length> ::= <byte>{4}
<cgbi_type>   ::= b'CgBI'
<cgbi_data>   ::= <byte>{4}
<cgbi_crc>    ::= <byte>{4}

where <cgbi_length> == int.to_bytes(len(bytes(<cgbi_data>)), 4, 'big')
where <cgbi_crc> == int.to_bytes(zlib.crc32(bytes(<cgbi_type>) + bytes(<cgbi_data>)) & 0xffffffff, 4, 'big')

# Chunk groups follow the ordering rules: colour and profile chunks before PLTE
# and IDAT, bKGD/hIST/tRNS after PLTE and before IDAT, text, eXIf and tIME around
# IDAT. Unknown private chunks may appear in all three groups.

<chunks_before_plte> ::= <chrm_chunk>? <gama_chunk>? <iccp_chunk>? <sbit_chunk>? <srgb_chunk>? <phys_chunk>? <exif_chunk>? <splt_chunk>* <text_group>* <unknown_chunk>*
<after_plte_gray>            ::= <bkgd_chunk_gray>? <trns_chunk_gray>? <text_group>* <unknown_chunk>*
<after_plte_truecolor>       ::= <bkgd_chunk_truecolor>? <trns_chunk_truecolor>? <text_group>* <unknown_chunk>*
<after_plte_indexed>         ::= <bkgd_chunk_indexed>? <hist_chunk>? <trns_chunk_indexed>? <text_group>* <unknown_chunk>*
<after_plte_gray_alpha>      ::= <bkgd_chunk_gray>? <text_group>* <unknown_chunk>*
<after_plte_truecolor_alpha> ::= <bkgd_chunk_truecolor>? <text_group>* <unknown_chunk>*
<chunks_after_idat>  ::= <text_group>* <time_chunk>? <unknown_chunk>*

<text_group> ::= <text_chunk> | <ztxt_chunk> | <itxt_chunk>

# IHDR - image header (critical, always first, fixed 13-byte payload)

<ihdr_length> ::= <byte>{4}
<ihdr_type>   ::= b'IHDR'
<ihdr_size>   ::= <width> <height>

<ihdr_gray>      ::= <ihdr_length> <ihdr_type> <ihdr_data_gray> <ihdr_crc_gray>
<ihdr_data_gray> ::= <ihdr_size> <bit_depth_gray> b'\x00' <ihdr_compression> <ihdr_filter> <ihdr_interlace>
<bit_depth_gray> ::= b'\x01' | b'\x02' | b'\x04' | b'\x08' | b'\x10'
<ihdr_crc_gray>  ::= <byte>{4}
where <ihdr_crc_gray> == int.to_bytes(zlib.crc32(b'IHDR' + bytes(<ihdr_data_gray>)) & 0xffffffff, 4, 'big')

<ihdr_truecolor>      ::= <ihdr_length> <ihdr_type> <ihdr_data_truecolor> <ihdr_crc_truecolor>
<ihdr_data_truecolor> ::= <ihdr_size> <bit_depth_truecolor> b'\x02' <ihdr_compression> <ihdr_filter> <ihdr_interlace>
<bit_depth_truecolor> ::= b'\x08' | b'\x10'
<ihdr_crc_truecolor>  ::= <byte>{4}
where <ihdr_crc_truecolor> == int.to_bytes(zlib.crc32(b'IHDR' + bytes(<ihdr_data_truecolor>)) & 0xffffffff, 4, 'big')

<ihdr_gray_alpha>      ::= <ihdr_length> <ihdr_type> <ihdr_data_gray_alpha> <ihdr_crc_gray_alpha>
<ihdr_data_gray_alpha> ::= <ihdr_size> <bit_depth_gray_alpha> b'\x04' <ihdr_compression> <ihdr_filter> <ihdr_interlace>
<bit_depth_gray_alpha> ::= b'\x08' | b'\x10'
<ihdr_crc_gray_alpha>  ::= <byte>{4}
where <ihdr_crc_gray_alpha> == int.to_bytes(zlib.crc32(b'IHDR' + bytes(<ihdr_data_gray_alpha>)) & 0xffffffff, 4, 'big')

<ihdr_truecolor_alpha>      ::= <ihdr_length> <ihdr_type> <ihdr_data_truecolor_alpha> <ihdr_crc_truecolor_alpha>
<ihdr_data_truecolor_alpha> ::= <ihdr_size> <bit_depth_truecolor_alpha> b'\x06' <ihdr_compression> <ihdr_filter> <ihdr_interlace>
<bit_depth_truecolor_alpha> ::= b'\x08' | b'\x10'
<ihdr_crc_truecolor_alpha>  ::= <byte>{4}
where <ihdr_crc_truecolor_alpha> == int.to_bytes(zlib.crc32(b'IHDR' + bytes(<ihdr_data_truecolor_alpha>)) & 0xffffffff, 4, 'big')

<ihdr_indexed_1>      ::= <ihdr_length> <ihdr_type> <ihdr_data_indexed_1> <ihdr_crc_indexed_1>
<ihdr_data_indexed_1> ::= <ihdr_size> <bit_depth_indexed_1> b'\x03' <ihdr_compression> <ihdr_filter> <ihdr_interlace>
<bit_depth_indexed_1> ::= b'\x01'
<ihdr_crc_indexed_1>  ::= <byte>{4}
where <ihdr_crc_indexed_1> == int.to_bytes(zlib.crc32(b'IHDR' + bytes(<ihdr_data_indexed_1>)) & 0xffffffff, 4, 'big')

<ihdr_indexed_2>      ::= <ihdr_length> <ihdr_type> <ihdr_data_indexed_2> <ihdr_crc_indexed_2>
<ihdr_data_indexed_2> ::= <ihdr_size> <bit_depth_indexed_2> b'\x03' <ihdr_compression> <ihdr_filter> <ihdr_interlace>
<bit_depth_indexed_2> ::= b'\x02'
<ihdr_crc_indexed_2>  ::= <byte>{4}
where <ihdr_crc_indexed_2> == int.to_bytes(zlib.crc32(b'IHDR' + bytes(<ihdr_data_indexed_2>)) & 0xffffffff, 4, 'big')

<ihdr_indexed_4>      ::= <ihdr_length> <ihdr_type> <ihdr_data_indexed_4> <ihdr_crc_indexed_4>
<ihdr_data_indexed_4> ::= <ihdr_size> <bit_depth_indexed_4> b'\x03' <ihdr_compression> <ihdr_filter> <ihdr_interlace>
<bit_depth_indexed_4> ::= b'\x04'
<ihdr_crc_indexed_4>  ::= <byte>{4}
where <ihdr_crc_indexed_4> == int.to_bytes(zlib.crc32(b'IHDR' + bytes(<ihdr_data_indexed_4>)) & 0xffffffff, 4, 'big')

<ihdr_indexed_8>      ::= <ihdr_length> <ihdr_type> <ihdr_data_indexed_8> <ihdr_crc_indexed_8>
<ihdr_data_indexed_8> ::= <ihdr_size> <bit_depth_indexed_8> b'\x03' <ihdr_compression> <ihdr_filter> <ihdr_interlace>
<bit_depth_indexed_8> ::= b'\x08'
<ihdr_crc_indexed_8>  ::= <byte>{4}
where <ihdr_crc_indexed_8> == int.to_bytes(zlib.crc32(b'IHDR' + bytes(<ihdr_data_indexed_8>)) & 0xffffffff, 4, 'big')

where <ihdr_length> == int.to_bytes(13, 4, 'big')

<width>  ::= <byte>{4} := int.to_bytes(random.choice([1, 0x7fffffff, random.randint(1, 4000)]), 4, 'big')
<height> ::= <byte>{4} := int.to_bytes(random.choice([1, 0x7fffffff, random.randint(1, 4000)]), 4, 'big')

<ihdr_compression> ::= b'\x00'
<ihdr_filter>      ::= b'\x00'
<ihdr_interlace>   ::= b'\x00' | b'\x01'


<plte_type>   ::= b'PLTE'
<plte_entry>  ::= <byte>{3}

<plte_chunk_1>  ::= <plte_length_1> <plte_type> <plte_data_1> <plte_crc_1>
<plte_length_1> ::= <byte>{4}
<plte_data_1>   ::= <plte_entry>{1,2}
<plte_crc_1>    ::= <byte>{4}
where <plte_length_1> == int.to_bytes(len(bytes(<plte_data_1>)), 4, 'big')
where <plte_crc_1> == int.to_bytes(zlib.crc32(bytes(<plte_type>) + bytes(<plte_data_1>)) & 0xffffffff, 4, 'big')

<plte_chunk_2>  ::= <plte_length_2> <plte_type> <plte_data_2> <plte_crc_2>
<plte_length_2> ::= <byte>{4}
<plte_data_2>   ::= <plte_entry>{1,4}
<plte_crc_2>    ::= <byte>{4}
where <plte_length_2> == int.to_bytes(len(bytes(<plte_data_2>)), 4, 'big')
where <plte_crc_2> == int.to_bytes(zlib.crc32(bytes(<plte_type>) + bytes(<plte_data_2>)) & 0xffffffff, 4, 'big')

<plte_chunk_4>  ::= <plte_length_4> <plte_type> <plte_data_4> <plte_crc_4>
<plte_length_4> ::= <byte>{4}
<plte_data_4>   ::= <plte_entry>{1,16}
<plte_crc_4>    ::= <byte>{4}
where <plte_length_4> == int.to_bytes(len(bytes(<plte_data_4>)), 4, 'big')
where <plte_crc_4> == int.to_bytes(zlib.crc32(bytes(<plte_type>) + bytes(<plte_data_4>)) & 0xffffffff, 4, 'big')

<plte_chunk_8>  ::= <plte_length_8> <plte_type> <plte_data_8> <plte_crc_8>
<plte_length_8> ::= <byte>{4}
<plte_data_8>   ::= <plte_entry>{1,64} | <plte_entry>{256}
<plte_crc_8>    ::= <byte>{4}
where <plte_length_8> == int.to_bytes(len(bytes(<plte_data_8>)), 4, 'big')
where <plte_crc_8> == int.to_bytes(zlib.crc32(bytes(<plte_type>) + bytes(<plte_data_8>)) & 0xffffffff, 4, 'big')

where forall <i> in <image_indexed_1>:
    forall <h> in <i>..<hist_data>:
        len(bytes(<h>)) == len(bytes(<i>.<plte_chunk_1>.<plte_data_1>)) // 3 * 2
where forall <i> in <image_indexed_1>:
    forall <r> in <i>..<trns_data_indexed>:
        len(bytes(<r>)) <= len(bytes(<i>.<plte_chunk_1>.<plte_data_1>)) // 3

where forall <i> in <image_indexed_2>:
    forall <h> in <i>..<hist_data>:
        len(bytes(<h>)) == len(bytes(<i>.<plte_chunk_2>.<plte_data_2>)) // 3 * 2
where forall <i> in <image_indexed_2>:
    forall <r> in <i>..<trns_data_indexed>:
        len(bytes(<r>)) <= len(bytes(<i>.<plte_chunk_2>.<plte_data_2>)) // 3

where forall <i> in <image_indexed_4>:
    forall <h> in <i>..<hist_data>:
        len(bytes(<h>)) == len(bytes(<i>.<plte_chunk_4>.<plte_data_4>)) // 3 * 2
where forall <i> in <image_indexed_4>:
    forall <r> in <i>..<trns_data_indexed>:
        len(bytes(<r>)) <= len(bytes(<i>.<plte_chunk_4>.<plte_data_4>)) // 3

where forall <i> in <image_indexed_8>:
    forall <h> in <i>..<hist_data>:
        len(bytes(<h>)) == len(bytes(<i>.<plte_chunk_8>.<plte_data_8>)) // 3 * 2
where forall <i> in <image_indexed_8>:
    forall <r> in <i>..<trns_data_indexed>:
        len(bytes(<r>)) <= len(bytes(<i>.<plte_chunk_8>.<plte_data_8>)) // 3

# IDAT: one or more chunks. Empty ones are legal as long as the whole stream is not.

<idat_chunk>  ::= <idat_length> <idat_type> <idat_data> <idat_crc>
<idat_length> ::= <byte>{4}
<idat_type>   ::= b'IDAT'
<idat_data>   ::= <byte>{0,512}
<idat_crc>    ::= <byte>{4}

where <idat_length> == int.to_bytes(len(bytes(<idat_data>)), 4, 'big')
where <idat_crc> == int.to_bytes(zlib.crc32(bytes(<idat_type>) + bytes(<idat_data>)) & 0xffffffff, 4, 'big')

# IEND - end marker (critical, always last, zero-length payload)

<iend_chunk>  ::= <iend_length> <iend_type> <iend_crc>
<iend_length> ::= <byte>{4}
<iend_type>   ::= b'IEND'
<iend_crc>    ::= <byte>{4}

where <iend_length> == int.to_bytes(0, 4, 'big')
where <iend_crc> == int.to_bytes(zlib.crc32(bytes(<iend_type>)) & 0xffffffff, 4, 'big')

# cHRM - primary chromaticities (32 bytes: 8 fixed-point x/y values)

<chrm_chunk>  ::= <chrm_length> <chrm_type> <chrm_data> <chrm_crc>
<chrm_length> ::= <byte>{4}
<chrm_type>   ::= b'cHRM'
<chrm_data>   ::= <byte>{32}
<chrm_crc>    ::= <byte>{4}

where <chrm_length> == int.to_bytes(len(bytes(<chrm_data>)), 4, 'big')
where <chrm_crc> == int.to_bytes(zlib.crc32(bytes(<chrm_type>) + bytes(<chrm_data>)) & 0xffffffff, 4, 'big')

# gAMA - image gamma (4-byte fixed-point value)

<gama_chunk>  ::= <gama_length> <gama_type> <gama_data> <gama_crc>
<gama_length> ::= <byte>{4}
<gama_type>   ::= b'gAMA'
<gama_data>   ::= <byte>{4}
<gama_crc>    ::= <byte>{4}

where <gama_length> == int.to_bytes(len(bytes(<gama_data>)), 4, 'big')
where <gama_crc> == int.to_bytes(zlib.crc32(bytes(<gama_type>) + bytes(<gama_data>)) & 0xffffffff, 4, 'big')

# sRGB - standard RGB color space (1-byte rendering intent, 0-3)

<srgb_chunk>  ::= <srgb_length> <srgb_type> <srgb_data> <srgb_crc>
<srgb_length> ::= <byte>{4}
<srgb_type>   ::= b'sRGB'
<srgb_data>   ::= b'\x00' | b'\x01' | b'\x02' | b'\x03'
<srgb_crc>    ::= <byte>{4}

where <srgb_length> == int.to_bytes(len(bytes(<srgb_data>)), 4, 'big')
where <srgb_crc> == int.to_bytes(zlib.crc32(bytes(<srgb_type>) + bytes(<srgb_data>)) & 0xffffffff, 4, 'big')

# sBIT - significant bits (1 to 4 bytes, depending on color type)

<sbit_chunk>  ::= <sbit_length> <sbit_type> <sbit_data> <sbit_crc>
<sbit_length> ::= <byte>{4}
<sbit_type>   ::= b'sBIT'
<sbit_data>   ::= <byte>{1,4}
<sbit_crc>    ::= <byte>{4}

where <sbit_length> == int.to_bytes(len(bytes(<sbit_data>)), 4, 'big')
where <sbit_crc> == int.to_bytes(zlib.crc32(bytes(<sbit_type>) + bytes(<sbit_data>)) & 0xffffffff, 4, 'big')

# iCCP: name, NUL, compression method, profile data. Only method 0 (zlib) is
# defined, other values show up now and then.

<iccp_chunk>      ::= <iccp_length> <iccp_type> <iccp_data> <iccp_crc>
<iccp_length>     ::= <byte>{4}
<iccp_type>       ::= b'iCCP'
<iccp_data>       ::= <iccp_name> b'\x00' <iccp_compmethod> <iccp_profile>
<iccp_name>       ::= rb'[\x01-\xff]{1,79}'
<iccp_compmethod> ::= b'\x00' | <byte>
<iccp_profile>    ::= <byte>{0,256}
<iccp_crc>        ::= <byte>{4}

where <iccp_length> == int.to_bytes(len(bytes(<iccp_data>)), 4, 'big')
where <iccp_crc> == int.to_bytes(zlib.crc32(bytes(<iccp_type>) + bytes(<iccp_data>)) & 0xffffffff, 4, 'big')

# pHYs - physical pixel dimensions (2x4-byte density values + 1-byte unit)

<phys_chunk>  ::= <phys_length> <phys_type> <phys_data> <phys_crc>
<phys_length> ::= <byte>{4}
<phys_type>   ::= b'pHYs'
<phys_data>   ::= <byte>{4} <byte>{4} <phys_unit>
<phys_unit>   ::= b'\x00' | b'\x01'
<phys_crc>    ::= <byte>{4}

where <phys_length> == int.to_bytes(len(bytes(<phys_data>)), 4, 'big')
where <phys_crc> == int.to_bytes(zlib.crc32(bytes(<phys_type>) + bytes(<phys_data>)) & 0xffffffff, 4, 'big')

# tIME - last modification time (2-byte year, then bounded month/day/h/m/s)

<time_chunk>  ::= <time_length> <time_type> <time_data> <time_crc>
<time_length> ::= <byte>{4}
<time_type>   ::= b'tIME'
<time_data>   ::= <byte>{2} <time_month> <time_day> <time_hour> <time_minute> <time_second>
<time_month>  ::= rb'[\x01-\x0c]'
<time_day>    ::= rb'[\x01-\x1f]'
<time_hour>   ::= rb'[\x00-\x17]'
<time_minute> ::= rb'[\x00-\x3b]'
<time_second> ::= rb'[\x00-\x3c]'
<time_crc>    ::= <byte>{4}

where <time_length> == int.to_bytes(len(bytes(<time_data>)), 4, 'big')
where <time_crc> == int.to_bytes(zlib.crc32(bytes(<time_type>) + bytes(<time_data>)) & 0xffffffff, 4, 'big')

# tEXt - uncompressed Latin-1 text: keyword, NUL, text (no embedded NULs)

<text_chunk>   ::= <text_length> <text_type> <text_data> <text_crc>
<text_length>  ::= <byte>{4}
<text_type>    ::= b'tEXt'
<text_data>    ::= <text_keyword> b'\x00' <text_value>
<text_keyword> ::= rb'[\x01-\xff]{1,79}'
<text_value>   ::= rb'[\x01-\xff]{0,100}'
<text_crc>     ::= <byte>{4}

where <text_length> == int.to_bytes(len(bytes(<text_data>)), 4, 'big')
where <text_crc> == int.to_bytes(zlib.crc32(bytes(<text_type>) + bytes(<text_data>)) & 0xffffffff, 4, 'big')

<ztxt_chunk>      ::= <ztxt_length> <ztxt_type> <ztxt_data> <ztxt_crc>
<ztxt_length>     ::= <byte>{4}
<ztxt_type>       ::= b'zTXt'
<ztxt_data>       ::= <text_keyword> b'\x00' <ztxt_compmethod> <ztxt_compressed>
<ztxt_compmethod> ::= b'\x00' | <byte>
<ztxt_compressed> ::= <byte>{0,100}
<ztxt_crc>        ::= <byte>{4}

where <ztxt_length> == int.to_bytes(len(bytes(<ztxt_data>)), 4, 'big')
where <ztxt_crc> == int.to_bytes(zlib.crc32(bytes(<ztxt_type>) + bytes(<ztxt_data>)) & 0xffffffff, 4, 'big')

<itxt_chunk>      ::= <itxt_length> <itxt_type> <itxt_data> <itxt_crc>
<itxt_length>     ::= <byte>{4}
<itxt_type>       ::= b'iTXt'
<itxt_data>       ::= <text_keyword> b'\x00' <itxt_compflag> <itxt_compmethod> b'\x00' <itxt_lang> b'\x00' <itxt_transkey> b'\x00' <itxt_text>
<itxt_compflag>   ::= b'\x00' | b'\x01'
<itxt_compmethod> ::= b'\x00' | <byte>
<itxt_lang>       ::= rb'[\x01-\x7f]{0,20}'
<itxt_transkey>   ::= <byte>{0,40}
<itxt_text>       ::= <byte>{0,100}
<itxt_crc>        ::= <byte>{4}

where <itxt_length> == int.to_bytes(len(bytes(<itxt_data>)), 4, 'big')
where <itxt_crc> == int.to_bytes(zlib.crc32(bytes(<itxt_type>) + bytes(<itxt_data>)) & 0xffffffff, 4, 'big')
where (bytes(<itxt_compflag>) == b'\x00') or (bytes(<itxt_compmethod>) == b'\x00')

# eXIf: a TIFF blob that starts with II or MM for the byte order

<exif_chunk>     ::= <exif_length> <exif_type> <exif_data> <exif_crc>
<exif_length>    ::= <byte>{4}
<exif_type>      ::= b'eXIf'
<exif_data>      ::= <exif_byteorder> <byte>{2,64}
<exif_byteorder> ::= b'II' | b'MM'
<exif_crc>       ::= <byte>{4}

where <exif_length> == int.to_bytes(len(bytes(<exif_data>)), 4, 'big')
where <exif_crc> == int.to_bytes(zlib.crc32(bytes(<exif_type>) + bytes(<exif_data>)) & 0xffffffff, 4, 'big')

# sPLT: name, NUL, sample depth (8 or 16), then entries sized by the depth.
# One chunk rule per depth.

<splt_chunk> ::= <splt_chunk_8> | <splt_chunk_16>

<splt_chunk_8>  ::= <splt_length_8> <splt_type_8> <splt_data_8> <splt_crc_8>
<splt_length_8> ::= <byte>{4}
<splt_type_8>   ::= b'sPLT'
<splt_data_8>   ::= <splt_name> b'\x00' b'\x08' <splt_entry_8>*
<splt_entry_8>  ::= <byte>{6}
<splt_crc_8>    ::= <byte>{4}

where <splt_length_8> == int.to_bytes(len(bytes(<splt_data_8>)), 4, 'big')
where <splt_crc_8> == int.to_bytes(zlib.crc32(bytes(<splt_type_8>) + bytes(<splt_data_8>)) & 0xffffffff, 4, 'big')

<splt_chunk_16>  ::= <splt_length_16> <splt_type_16> <splt_data_16> <splt_crc_16>
<splt_length_16> ::= <byte>{4}
<splt_type_16>   ::= b'sPLT'
<splt_data_16>   ::= <splt_name> b'\x00' b'\x10' <splt_entry_16>*
<splt_entry_16>  ::= <byte>{10}
<splt_crc_16>    ::= <byte>{4}

where <splt_length_16> == int.to_bytes(len(bytes(<splt_data_16>)), 4, 'big')
where <splt_crc_16> == int.to_bytes(zlib.crc32(bytes(<splt_type_16>) + bytes(<splt_data_16>)) & 0xffffffff, 4, 'big')

<splt_name> ::= rb'[\x01-\xff]{1,79}'

# tRNS: the shape depends on the IHDR colour type, so there is one chunk rule
# per colour type; the image layouts above say which one an image can have.



<trns_chunk_gray>      ::= <trns_length_gray> <trns_type_gray> <trns_data_gray> <trns_crc_gray>
<trns_length_gray>     ::= <byte>{4}
<trns_type_gray>       ::= b'tRNS'
<trns_data_gray>       ::= <byte>{2}
<trns_crc_gray>        ::= <byte>{4}

where <trns_length_gray> == int.to_bytes(len(bytes(<trns_data_gray>)), 4, 'big')
where <trns_crc_gray> == int.to_bytes(zlib.crc32(bytes(<trns_type_gray>) + bytes(<trns_data_gray>)) & 0xffffffff, 4, 'big')

<trns_chunk_truecolor>  ::= <trns_length_truecolor> <trns_type_truecolor> <trns_data_truecolor> <trns_crc_truecolor>
<trns_length_truecolor> ::= <byte>{4}
<trns_type_truecolor>   ::= b'tRNS'
<trns_data_truecolor>   ::= <byte>{6}
<trns_crc_truecolor>    ::= <byte>{4}

where <trns_length_truecolor> == int.to_bytes(len(bytes(<trns_data_truecolor>)), 4, 'big')
where <trns_crc_truecolor> == int.to_bytes(zlib.crc32(bytes(<trns_type_truecolor>) + bytes(<trns_data_truecolor>)) & 0xffffffff, 4, 'big')

<trns_chunk_indexed>  ::= <trns_length_indexed> <trns_type_indexed> <trns_data_indexed> <trns_crc_indexed>
<trns_length_indexed> ::= <byte>{4}
<trns_type_indexed>   ::= b'tRNS'
<trns_data_indexed>   ::= <byte>{1,32}
<trns_crc_indexed>    ::= <byte>{4}

where <trns_length_indexed> == int.to_bytes(len(bytes(<trns_data_indexed>)), 4, 'big')
where <trns_crc_indexed> == int.to_bytes(zlib.crc32(bytes(<trns_type_indexed>) + bytes(<trns_data_indexed>)) & 0xffffffff, 4, 'big')

# bKGD: 2 bytes for gray, 6 for RGB, 1 palette index for indexed. Split per colour
# type like tRNS.



<bkgd_chunk_gray>      ::= <bkgd_length_gray> <bkgd_type_gray> <bkgd_data_gray> <bkgd_crc_gray>
<bkgd_length_gray>     ::= <byte>{4}
<bkgd_type_gray>       ::= b'bKGD'
<bkgd_data_gray>       ::= <byte>{2}
<bkgd_crc_gray>        ::= <byte>{4}

where <bkgd_length_gray> == int.to_bytes(len(bytes(<bkgd_data_gray>)), 4, 'big')
where <bkgd_crc_gray> == int.to_bytes(zlib.crc32(bytes(<bkgd_type_gray>) + bytes(<bkgd_data_gray>)) & 0xffffffff, 4, 'big')

<bkgd_chunk_truecolor>  ::= <bkgd_length_truecolor> <bkgd_type_truecolor> <bkgd_data_truecolor> <bkgd_crc_truecolor>
<bkgd_length_truecolor> ::= <byte>{4}
<bkgd_type_truecolor>   ::= b'bKGD'
<bkgd_data_truecolor>   ::= <byte>{6}
<bkgd_crc_truecolor>    ::= <byte>{4}

where <bkgd_length_truecolor> == int.to_bytes(len(bytes(<bkgd_data_truecolor>)), 4, 'big')
where <bkgd_crc_truecolor> == int.to_bytes(zlib.crc32(bytes(<bkgd_type_truecolor>) + bytes(<bkgd_data_truecolor>)) & 0xffffffff, 4, 'big')

<bkgd_chunk_indexed>  ::= <bkgd_length_indexed> <bkgd_type_indexed> <bkgd_data_indexed> <bkgd_crc_indexed>
<bkgd_length_indexed> ::= <byte>{4}
<bkgd_type_indexed>   ::= b'bKGD'
<bkgd_data_indexed>   ::= <byte>{1}
<bkgd_crc_indexed>    ::= <byte>{4}

where <bkgd_length_indexed> == int.to_bytes(len(bytes(<bkgd_data_indexed>)), 4, 'big')
where <bkgd_crc_indexed> == int.to_bytes(zlib.crc32(bytes(<bkgd_type_indexed>) + bytes(<bkgd_data_indexed>)) & 0xffffffff, 4, 'big')

# hIST: one 2 byte entry per PLTE entry, only with PLTE

<hist_chunk>  ::= <hist_length> <hist_type> <hist_data> <hist_crc>
<hist_length> ::= <byte>{4}
<hist_type>   ::= b'hIST'
<hist_data>   ::= <hist_entry>*
<hist_entry>  ::= <byte>{2}
<hist_crc>    ::= <byte>{4}

where <hist_length> == int.to_bytes(len(bytes(<hist_data>)), 4, 'big')
where <hist_crc> == int.to_bytes(zlib.crc32(bytes(<hist_type>) + bytes(<hist_data>)) & 0xffffffff, 4, 'big')

<unknown_chunk>  ::= <unknown_length> <unknown_type> <unknown_data> <unknown_crc>
<unknown_length> ::= <byte>{4}
<unknown_type>   ::= <byte> <byte> <byte> <byte>
<unknown_data>   ::= <byte>{0,64}
<unknown_crc>    ::= <byte>{4}

where <unknown_length> == int.to_bytes(len(bytes(<unknown_data>)), 4, 'big')
where <unknown_crc> == int.to_bytes(zlib.crc32(bytes(<unknown_type>) + bytes(<unknown_data>)) & 0xffffffff, 4, 'big')
where all((c in range(65, 91)) or (c in range(97, 123)) for c in bytes(<unknown_type>))
where (bytes(<unknown_type>)[0] & 0x20) == 0x20
