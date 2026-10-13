# Same as heic, with values taken from the edges of what the format allows:
# degenerate/overflow spatial extents (0x0, 1x1, 65536-wide, 0xFFFFFFFF),
# extreme HEVC profile/tier/chroma/bit-depth bytes, a hidden-item flag, an
# odd compatible-brand soup, ICC-embedded colr, and the irot/imir/pasp/clap
# transformative properties with the HEIF essential bit set.
#
# TODO:
# * Same NAL-shell limitation as heic; files rarely decode past the
#   container level.

<start> ::= <heic_file>

<heic_file> ::= <ftyp_box> <meta_box>

# ftyp - File Type Box.  Non-zero minor_version and a wide compatible-brand
# soup are both edge-cases that trip strict brand checkers.
<ftyp_box>     ::= <ftyp_size> <ftyp_content>
<ftyp_size>    ::= <u32>
<ftyp_content> ::= rb'ftyp' <major_brand> <minor_version> <compat_brands>
<major_brand>  ::= rb'heic' | rb'heix' | rb'mif1' | rb'heim' | rb'heis'
<minor_version>::= rb'\x00\x00\x00\x00' | rb'\x00\x00\x02\x00' | rb'\xde\xad\xbe\xef'
<compat_brands>::= <brand>{1,6}
<brand>        ::= rb'heic' | rb'mif1' | rb'miaf' | rb'MA1B' | rb'MA1A' \
                 | rb'msf1' | rb'heix' | rb'hevc' | rb'heim' | rb'\x00\x00\x00\x00'

# meta - Metadata Box (FullBox v0).  Holds the full item bookkeeping chain plus
# a trailing free box (legacy padding parsers must skip).
<meta_box>     ::= <meta_size> <meta_content>
<meta_size>    ::= <u32>
<meta_content> ::= rb'meta' <fullbox0> <hdlr_box> <pitm_box> <iloc_box> \
                   <iinf_box> <iprp_box> <free_box> <idat_box>

# hdlr - Handler Reference (FullBox); handler_type = 'pict'.  Name may be empty
# (just a NUL) or up to 16 printable chars -- both boundary cases.
<hdlr_box>     ::= <hdlr_size> <hdlr_content>
<hdlr_size>    ::= <u32>
<hdlr_content> ::= rb'hdlr' <fullbox0> <predefined> rb'pict' \
                   <hdlr_reserved> <handler_name>
<predefined>   ::= rb'\x00\x00\x00\x00'
<hdlr_reserved>::= rb'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
<handler_name> ::= <name_chars> rb'\x00'
<name_chars>   ::= <name_char>{0,16}
<name_char>    ::= rb'[\x20-\x7e]'

# pitm - Primary Item (FullBox); item_ID = 1.
<pitm_box>     ::= <pitm_size> <pitm_content>
<pitm_size>    ::= <u32>
<pitm_content> ::= rb'pitm' <fullbox0> <primary_item_id>
<primary_item_id> ::= rb'\x00\x01'

# iloc - Item Location (FullBox v1). offset_size=4, length_size=4,
# base_offset_size=0, index_size=0.  One item, construction_method=1 (idat),
# one extent, extent_offset=0, extent_length == coded bytes in idat.
<iloc_box>     ::= <iloc_size> <iloc_content>
<iloc_size>    ::= <u32>
<iloc_content> ::= rb'iloc' <iloc_ver> <iloc_flags> <iloc_sizes> <iloc_base_index> \
                   <iloc_item_count> <iloc_item_id> <iloc_constr_method> \
                   <iloc_data_ref_index> <iloc_extent_count> \
                   <iloc_extent_offset> <iloc_extent_length>
<iloc_ver>          ::= rb'\x01'
<iloc_flags>        ::= rb'\x00\x00\x00'
<iloc_sizes>        ::= rb'\x44'
<iloc_base_index>   ::= rb'\x00'
<iloc_item_count>   ::= rb'\x00\x01'
<iloc_item_id>      ::= rb'\x00\x01'
<iloc_constr_method>::= rb'\x00\x01'
<iloc_data_ref_index>::= rb'\x00\x00'
<iloc_extent_count> ::= rb'\x00\x01'
<iloc_extent_offset>::= rb'\x00\x00\x00\x00'
<iloc_extent_length>::= <u32>

# iinf - Item Info (FullBox) with one infe.  infe flags=0x000001 marks the item
# HIDDEN -- a rarely-exercised path many viewers ignore.  item_type = 'hvc1'.
<iinf_box>     ::= <iinf_size> <iinf_content>
<iinf_size>    ::= <u32>
<iinf_content> ::= rb'iinf' <fullbox0> <iinf_entry_count> <infe_box>
<iinf_entry_count> ::= rb'\x00\x01'

<infe_box>     ::= <infe_size> <infe_content>
<infe_size>    ::= <u32>
<infe_content> ::= rb'infe' <infe_ver> <infe_flags> <infe_item_id> \
                   <infe_prot_index> <infe_item_type> <infe_item_name>
<infe_ver>       ::= rb'\x02'
<infe_flags>     ::= rb'\x00\x00\x00' | rb'\x00\x00\x01'
<infe_item_id>   ::= rb'\x00\x01'
<infe_prot_index>::= rb'\x00\x00'
<infe_item_type> ::= rb'hvc1' | rb'hev1'
<infe_item_name> ::= <name_chars> rb'\x00'

# iprp - Item Properties -> ipco (container) + ipma (association).
# ipco carries EIGHT properties to stress deep property association:
#   1 ispe, 2 hvcC, 3 pixi, 4 colr, 5 irot, 6 imir, 7 pasp, 8 clap
<iprp_box>     ::= <iprp_size> <iprp_content>
<iprp_size>    ::= <u32>
<iprp_content> ::= rb'iprp' <ipco_box> <ipma_box>

<ipco_box>     ::= <ipco_size> <ipco_content>
<ipco_size>    ::= <u32>
<ipco_content> ::= rb'ipco' <ispe_box> <hvcC_box> <pixi_box> <colr_box> \
                   <irot_box> <imir_box> <pasp_box> <clap_box>

# ispe - Image Spatial Extents (FullBox).  Degenerate & overflow dimensions.
<ispe_box>     ::= <ispe_size> <ispe_content>
<ispe_size>    ::= <u32>
<ispe_content> ::= rb'ispe' <fullbox0> <ispe_width> <ispe_height>
<ispe_width>   ::= <dimension>
<ispe_height>  ::= <dimension>
<dimension>    ::= rb'\x00\x00\x00\x00' | rb'\x00\x00\x00\x01' \
                 | rb'\x00\x00\x00\x40' | rb'\x00\x00\x07\x80' \
                 | rb'\x00\x01\x00\x00' | rb'\xff\xff\xff\xff'

# hvcC - HEVC Decoder Configuration Record (ISO/IEC 14496-15).  Fixed 23-byte
# header followed by numOfArrays parameter-set arrays.  Fields swept toward
# extremes: profile_space/tier bits, non-zero constraint flags, high level_idc,
# min_spatial_segmentation, parallelismType, monochrome chromaFormat, 10/12/14
# bit luma/chroma, extra temporal layers, lengthSizeMinusOne variants.
#   b0  : configurationVersion = 1
#   b1  : profile_space(2) tier_flag(1) profile_idc(5)
#   b2-5: general_profile_compatibility_flags (u32)
#   b6-11: general_constraint_indicator_flags (48 bits)
#   b12 : general_level_idc
#   b13-14: reserved(1111) min_spatial_segmentation_idc(12)
#   b15 : reserved(111111) parallelismType(2)
#   b16 : reserved(111111) chromaFormat(2)
#   b17 : reserved(11111) bitDepthLumaMinus8(3)
#   b18 : reserved(11111) bitDepthChromaMinus8(3)
#   b19-20: avgFrameRate (u16)
#   b21 : constantFrameRate(2) numTemporalLayers(3) temporalIdNested(1)
#         lengthSizeMinusOne(2)
#   b22 : numOfArrays = 3  (VPS, SPS, PPS)
<hvcC_box>     ::= <hvcC_size> <hvcC_content>
<hvcC_size>    ::= <u32>
<hvcC_content> ::= rb'hvcC' <hvcc_config_ver> <hvcc_profile> <hvcc_compat> \
                   <hvcc_constraints> <hvcc_level_idc> <hvcc_min_seg> \
                   <hvcc_parallelism> <hvcc_chroma_format> <hvcc_bitdepth_luma> \
                   <hvcc_bitdepth_chroma> <hvcc_avg_framerate> <hvcc_frame_info> \
                   <hvcc_num_arrays> <hvcc_vps_array> <hvcc_sps_array> \
                   <hvcc_pps_array>
<hvcc_config_ver>  ::= rb'\x01'
# profile_space(2) tier_flag(1) profile_idc(5): Main(1), Main10(2), MainSP(3),
# RExt(4), plus high-space/high-tier exotic bytes.
<hvcc_profile>     ::= rb'\x01' | rb'\x02' | rb'\x03' | rb'\x04' \
                     | rb'\x21' | rb'\x62' | rb'\xa1' | rb'\xff'
<hvcc_compat>      ::= rb'\x60\x00\x00\x00' | rb'\x00\x00\x00\x00' \
                     | rb'\xff\xff\xff\xff' | rb'\x80\x00\x00\x00'
# 48-bit constraint flags: zero, progressive_source set, all-ones extreme.
<hvcc_constraints> ::= rb'\x00\x00\x00\x00\x00\x00' \
                     | rb'\x90\x00\x00\x00\x00\x00' \
                     | rb'\xff\xff\xff\xff\xff\xff'
# level_idc = 30*level: L3(90), L4(120), L5(150), L6.2(186), max(255).
<hvcc_level_idc>   ::= rb'\x5a' | rb'\x78' | rb'\x96' | rb'\xba' | rb'\xff'
# reserved high nibble 0xF; low 12 bits min_spatial_segmentation_idc.
<hvcc_min_seg>     ::= rb'\xf0\x00' | rb'\xf0\x01' | rb'\xff\xff'
# reserved 0b111111; parallelismType 0..3.
<hvcc_parallelism> ::= rb'\xfc' | rb'\xfd' | rb'\xfe' | rb'\xff'
# reserved 0b111111; chromaFormat 0(mono)/1(420)/2(422)/3(444).
<hvcc_chroma_format>::= rb'\xfc' | rb'\xfd' | rb'\xfe' | rb'\xff'
# reserved 0b11111; bitDepthLumaMinus8 0(8b)/2(10b)/4(12b)/6(14b).
<hvcc_bitdepth_luma>::= rb'\xf8' | rb'\xfa' | rb'\xfc' | rb'\xfe'
<hvcc_bitdepth_chroma>::= rb'\xf8' | rb'\xfa' | rb'\xfc' | rb'\xfe'
<hvcc_avg_framerate>::= rb'\x00\x00' | rb'\x00\x18' | rb'\xff\xff'
# constantFrameRate(2) numTemporalLayers(3) temporalIdNested(1) lenSizeMinus1(2)
<hvcc_frame_info>  ::= rb'\x0f' | rb'\x0b' | rb'\x1f' | rb'\x2c' | rb'\xff'
<hvcc_num_arrays>  ::= rb'\x03'

# Each parameter-set array:
#   array_completeness(1) reserved(1)=0 NAL_unit_type(6)
#   numNalus (u16) = 1
#   nalUnitLength (u16) == len(NAL blob)
#   NAL blob
# VPS = type 32 (0x20/0xA0 completeness), SPS = 33 (0x21/0xA1),
# PPS = 34 (0x22/0xA2).
<hvcc_vps_array> ::= <hvcc_vps_hdr> <hvcc_num_nalus> <vps_len> <vps_data>
<hvcc_vps_hdr>   ::= rb'\x20' | rb'\xa0'
<hvcc_sps_array> ::= <hvcc_sps_hdr> <hvcc_num_nalus> <sps_len> <sps_data>
<hvcc_sps_hdr>   ::= rb'\x21' | rb'\xa1'
<hvcc_pps_array> ::= <hvcc_pps_hdr> <hvcc_num_nalus> <pps_len> <pps_data>
<hvcc_pps_hdr>   ::= rb'\x22' | rb'\xa2'
<hvcc_num_nalus> ::= rb'\x00\x01'
<vps_len>  ::= <u16>
<sps_len>  ::= <u16>
<pps_len>  ::= <u16>
# NAL blobs: 2-byte HEVC NAL header (forbidden_zero + type + layer + tid) + body.
<vps_data> ::= rb'\x40\x01' <byte>{2,32}
<sps_data> ::= rb'\x42\x01' <byte>{2,48}
<pps_data> ::= rb'\x44\x01' <byte>{1,24}

# pixi - Pixel Information (FullBox).  Mono / RGB / RGBA channel flavours with
# 1/8/10/12/16-bit depths (channel count must match emitted depth list).
<pixi_box>     ::= <pixi_size> <pixi_content>
<pixi_size>    ::= <u32>
<pixi_content> ::= rb'pixi' <fullbox0> <pixi_body>
<pixi_body>    ::= <pixi_mono> | <pixi_rgb> | <pixi_rgba>
<pixi_mono>    ::= rb'\x01' <pixi_depth>
<pixi_rgb>     ::= rb'\x03' <pixi_depth> <pixi_depth> <pixi_depth>
<pixi_rgba>    ::= rb'\x04' <pixi_depth> <pixi_depth> <pixi_depth> <pixi_depth>
<pixi_depth>   ::= rb'\x08' | rb'\x0a' | rb'\x0c' | rb'\x10' | rb'\x01'

# colr - Colour Information.  Modern nclx OR deprecated embedded ICC ('prof'
# unrestricted / 'rICC' restricted).  nclx enums pushed to exotic values.
<colr_box>     ::= <colr_size> <colr_content>
<colr_size>    ::= <u32>
<colr_content> ::= rb'colr' <colr_body>
<colr_body>    ::= <colr_nclx> | <colr_icc>
<colr_nclx>    ::= rb'nclx' <colour_primaries> <transfer_char> \
                   <matrix_coeff> <full_range_byte>
<colr_icc>     ::= <colr_icc_type> <icc_blob>
<colr_icc_type>::= rb'prof' | rb'rICC'
<icc_blob>     ::= <byte>{12,96}
<colour_primaries> ::= rb'\x00\x01' | rb'\x00\x02' | rb'\x00\x09' \
                     | rb'\x00\x0c' | rb'\x00\x16' | rb'\x00\x00'
<transfer_char>    ::= rb'\x00\x01' | rb'\x00\x02' | rb'\x00\x0d' \
                     | rb'\x00\x10' | rb'\x00\x12' | rb'\x00\x00'
<matrix_coeff>     ::= rb'\x00\x00' | rb'\x00\x01' | rb'\x00\x02' \
                     | rb'\x00\x09' | rb'\x00\x0e' | rb'\x00\x0a'
<full_range_byte>  ::= rb'\x80' | rb'\x00'

# irot - Image Rotation (0/90/180/270 = angle 0..3 in low 2 bits).
<irot_box>     ::= <irot_size> <irot_content>
<irot_size>    ::= <u32>
<irot_content> ::= rb'irot' <irot_angle>
<irot_angle>   ::= rb'\x00' | rb'\x01' | rb'\x02' | rb'\x03'

# imir - Image Mirror (axis: 0 vertical, 1 horizontal).
<imir_box>     ::= <imir_size> <imir_content>
<imir_size>    ::= <u32>
<imir_content> ::= rb'imir' <imir_axis>
<imir_axis>    ::= rb'\x00' | rb'\x01'

# pasp - Pixel Aspect Ratio (hSpacing:u32, vSpacing:u32); non-square ratios.
<pasp_box>     ::= <pasp_size> <pasp_content>
<pasp_size>    ::= <u32>
<pasp_content> ::= rb'pasp' <pasp_h> <pasp_v>
<pasp_h>       ::= rb'\x00\x00\x00\x01' | rb'\x00\x00\x00\x10' | rb'\x00\x00\x04\x00'
<pasp_v>       ::= rb'\x00\x00\x00\x01' | rb'\x00\x00\x00\x0b' | rb'\x00\x00\x03\x00'

# clap - Clean Aperture (8 x u32: widthN/D, heightN/D, horizOffN/D, vertOffN/D).
<clap_box>     ::= <clap_size> <clap_content>
<clap_size>    ::= <u32>
<clap_content> ::= rb'clap' <u32> <u32> <u32> <u32> <u32> <u32> <u32> <u32>

# ipma - Item Property Association (FullBox); associates all 8 ipco entries with
# item 1.  Essential bit (0x80) set on hvcC and the transformative props.
<ipma_box>     ::= <ipma_size> <ipma_content>
<ipma_size>    ::= <u32>
<ipma_content> ::= rb'ipma' <fullbox0> <ipma_entry_count> <ipma_item_id> \
                   <ipma_assoc_count> <ipma_a1> <ipma_a2> <ipma_a3> <ipma_a4> \
                   <ipma_a5> <ipma_a6> <ipma_a7> <ipma_a8>
<ipma_entry_count> ::= rb'\x00\x00\x00\x01'
<ipma_item_id>     ::= rb'\x00\x01'
<ipma_assoc_count> ::= rb'\x08'
<ipma_a1>  ::= rb'\x01'   # ispe
<ipma_a2>  ::= rb'\x82'   # hvcC essential
<ipma_a3>  ::= rb'\x03'   # pixi
<ipma_a4>  ::= rb'\x04'   # colr
<ipma_a5>  ::= rb'\x85'   # irot essential
<ipma_a6>  ::= rb'\x86'   # imir essential
<ipma_a7>  ::= rb'\x07'   # pasp
<ipma_a8>  ::= rb'\x88'   # clap essential

# free - free-space box (legacy padding; content ignored by parsers).
<free_box>     ::= <free_size> <free_content>
<free_size>    ::= <u32>
<free_content> ::= rb'free' <free_pad>
<free_pad>     ::= <byte>{0,8}

# idat - Item Data; coded HEVC bytes referenced by iloc.  Length-prefixed NAL
# access-unit shell (nalUnitLength lengthSizeMinusOne=3 => 4-byte prefix) +
# bounded blob.  Not a decodable bitstream, container-only like PNG IDAT.
<idat_box>     ::= <idat_size> <idat_content>
<idat_size>    ::= <u32>
<idat_content> ::= rb'idat' <hevc_image_data>
<hevc_image_data> ::= <hevc_nal_prefix> <hevc_nal_header> <hevc_blob>
<hevc_nal_prefix> ::= rb'\x00\x00\x00\x10'
<hevc_nal_header> ::= rb'\x26\x01'
<hevc_blob>       ::= <byte>{8,256}

# Shared terminals
<fullbox0> ::= rb'\x00\x00\x00\x00'
<u32>      ::= <byte> <byte> <byte> <byte>
<u16>      ::= <byte> <byte>
<byte>     ::= rb'[\x00-\xff]'

# Constraints: box size == 4 + len(content); iloc extent == idat coded length;
# each hvcC NAL array length field == length of its NAL blob.
where bytes(<ftyp_size>) == (4 + len(bytes(<ftyp_content>))).to_bytes(4, 'big')
where bytes(<meta_size>) == (4 + len(bytes(<meta_content>))).to_bytes(4, 'big')
where bytes(<hdlr_size>) == (4 + len(bytes(<hdlr_content>))).to_bytes(4, 'big')
where bytes(<pitm_size>) == (4 + len(bytes(<pitm_content>))).to_bytes(4, 'big')
where bytes(<iloc_size>) == (4 + len(bytes(<iloc_content>))).to_bytes(4, 'big')
where bytes(<iinf_size>) == (4 + len(bytes(<iinf_content>))).to_bytes(4, 'big')
where bytes(<infe_size>) == (4 + len(bytes(<infe_content>))).to_bytes(4, 'big')
where bytes(<iprp_size>) == (4 + len(bytes(<iprp_content>))).to_bytes(4, 'big')
where bytes(<ipco_size>) == (4 + len(bytes(<ipco_content>))).to_bytes(4, 'big')
where bytes(<ispe_size>) == (4 + len(bytes(<ispe_content>))).to_bytes(4, 'big')
where bytes(<hvcC_size>) == (4 + len(bytes(<hvcC_content>))).to_bytes(4, 'big')
where bytes(<pixi_size>) == (4 + len(bytes(<pixi_content>))).to_bytes(4, 'big')
where bytes(<colr_size>) == (4 + len(bytes(<colr_content>))).to_bytes(4, 'big')
where bytes(<irot_size>) == (4 + len(bytes(<irot_content>))).to_bytes(4, 'big')
where bytes(<imir_size>) == (4 + len(bytes(<imir_content>))).to_bytes(4, 'big')
where bytes(<pasp_size>) == (4 + len(bytes(<pasp_content>))).to_bytes(4, 'big')
where bytes(<clap_size>) == (4 + len(bytes(<clap_content>))).to_bytes(4, 'big')
where bytes(<ipma_size>) == (4 + len(bytes(<ipma_content>))).to_bytes(4, 'big')
where bytes(<free_size>) == (4 + len(bytes(<free_content>))).to_bytes(4, 'big')
where bytes(<idat_size>) == (4 + len(bytes(<idat_content>))).to_bytes(4, 'big')
where bytes(<iloc_extent_length>) == len(bytes(<hevc_image_data>)).to_bytes(4, 'big')
where bytes(<vps_len>) == len(bytes(<vps_data>)).to_bytes(2, 'big')
where bytes(<sps_len>) == len(bytes(<sps_data>)).to_bytes(2, 'big')
where bytes(<pps_len>) == len(bytes(<pps_data>)).to_bytes(2, 'big')
