# Same as heic, plus item references (iref: dimg/thmb/auxl/cdsc/prem/base),
# entity grouping (grpl: altr/ster/eqiv/custom), protection boxes (sinf/
# frma/schm/schi/tenc), and the full timed-image-sequence layout (moov/
# trak/mdia/minf/stbl with hvc1/hev1 sample entries) used for HEIC bursts
# and live photos, not just a single still.

<start> ::= <heic_file> | <heic_file> | <heic_file> | <heic_file> | <heic_file> | <heic_file> | <heic_file> | <heic_file> | <heic_file> | <heic_file> | <heic_file> | <heic_file> | <heic_file> | <heic_file> | <heic_file> | <extended_heic_file>

<heic_file> ::= <core_ftyp_box> <core_meta_box>; where int.from_bytes(bytes(<core_extent_length>), "big") == len(bytes(<core_primary_item_data>))
<extended_heic_file> ::= <ftyp_box> <meta_box> <top_level_extension>{0,1}

# Canonical still-image branch. Exact encodings seed generation while the
# equalities independently check every encoded size and the iloc/idat extent.
<core_ftyp_box> ::= <core_ftyp_size> b"ftyp" <core_ftyp_payload>; where int.from_bytes(bytes(<core_ftyp_size>), "big") == len(bytes(<core_ftyp_payload>)) + 8
<core_ftyp_size> ::= b"\x00\x00\x00\x18"
<core_ftyp_payload> ::= b"heic\x00\x00\x00\x00heicmif1"

<core_meta_box> ::= <core_meta_size> b"meta" <core_meta_payload>; where int.from_bytes(bytes(<core_meta_size>), "big") == len(bytes(<core_meta_payload>)) + 8
<core_meta_size> ::= b"\x00\x00\x01\x44"
<core_meta_payload> ::= <full_v0> <core_handler_box> <core_pitm_box> <core_iloc_box> <core_iinf_box> <core_iprp_box> <core_iref_box> <core_idat_box>

<core_handler_box> ::= <core_handler_size> b"hdlr" <core_handler_payload>; where int.from_bytes(bytes(<core_handler_size>), "big") == len(bytes(<core_handler_payload>)) + 8
<core_handler_size> ::= b"\x00\x00\x00\x2b"
<core_handler_payload> ::= <full_v0> b"\x00\x00\x00\x00pict\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00HEIC items\x00"

<core_pitm_box> ::= <core_pitm_size> b"pitm" <core_pitm_payload>; where int.from_bytes(bytes(<core_pitm_size>), "big") == len(bytes(<core_pitm_payload>)) + 8
<core_pitm_size> ::= b"\x00\x00\x00\x0e"
<core_pitm_payload> ::= <full_v0> b"\x00\x01"

<core_iloc_box> ::= <core_iloc_size> b"iloc" <core_iloc_payload>; where int.from_bytes(bytes(<core_iloc_size>), "big") == len(bytes(<core_iloc_payload>)) + 8
<core_iloc_size> ::= b"\x00\x00\x00\x1f"
<core_iloc_payload> ::= <full_v1> b"\x44\x00\x00\x01\x00\x01\x00\x01\x00\x00\x01\x00\x00\x00\x00" <core_extent_length>
<core_extent_length> ::= b"\x00\x00\x00\x0c"

<core_iinf_box> ::= <core_iinf_size> b"iinf" <core_iinf_payload>; where int.from_bytes(bytes(<core_iinf_size>), "big") == len(bytes(<core_iinf_payload>)) + 8
<core_iinf_size> ::= b"\x00\x00\x00\x30"
<core_iinf_payload> ::= <full_v0> b"\x00\x01" <core_infe_box>
<core_infe_box> ::= <core_infe_size> b"infe" <core_infe_payload>; where int.from_bytes(bytes(<core_infe_size>), "big") == len(bytes(<core_infe_payload>)) + 8
<core_infe_size> ::= b"\x00\x00\x00\x22"
<core_infe_payload> ::= <full_v2> b"\x00\x01\x00\x00hvc1Primary image\x00"

<core_iprp_box> ::= <core_iprp_size> b"iprp" <core_iprp_payload>; where int.from_bytes(bytes(<core_iprp_size>), "big") == len(bytes(<core_iprp_payload>)) + 8
<core_iprp_size> ::= b"\x00\x00\x00\x90"
<core_iprp_payload> ::= <core_ipco_box> <core_ipma_box>
<core_ipco_box> ::= <core_ipco_size> b"ipco" <core_ipco_payload>; where int.from_bytes(bytes(<core_ipco_size>), "big") == len(bytes(<core_ipco_payload>)) + 8
<core_ipco_size> ::= b"\x00\x00\x00\x72"
<core_ipco_payload> ::= <core_ispe_box> <core_pixi_box> <core_hvcc_box>
<core_ispe_box> ::= <core_ispe_size> b"ispe" <core_ispe_payload>; where int.from_bytes(bytes(<core_ispe_size>), "big") == len(bytes(<core_ispe_payload>)) + 8
<core_ispe_size> ::= b"\x00\x00\x00\x14"
<core_ispe_payload> ::= <full_v0> b"\x00\x00\x01\x00\x00\x00\x01\x00"
<core_pixi_box> ::= <core_pixi_size> b"pixi" <core_pixi_payload>; where int.from_bytes(bytes(<core_pixi_size>), "big") == len(bytes(<core_pixi_payload>)) + 8
<core_pixi_size> ::= b"\x00\x00\x00\x10"
<core_pixi_payload> ::= <full_v0> b"\x03\x08\x08\x08"
<core_hvcc_box> ::= <core_hvcc_size> b"hvcC" <hvcc_payload>; where int.from_bytes(bytes(<core_hvcc_size>), "big") == len(bytes(<hvcc_payload>)) + 8
<core_hvcc_size> ::= b"\x00\x00\x00\x46"
<core_ipma_box> ::= <core_ipma_size> b"ipma" <core_ipma_payload>; where int.from_bytes(bytes(<core_ipma_size>), "big") == len(bytes(<core_ipma_payload>)) + 8
<core_ipma_size> ::= b"\x00\x00\x00\x16"
<core_ipma_payload> ::= <full_v0> b"\x00\x00\x00\x01\x00\x01\x03\x81\x82\x83"

<core_iref_box> ::= <core_iref_size> b"iref" <core_iref_payload>; where int.from_bytes(bytes(<core_iref_size>), "big") == len(bytes(<core_iref_payload>)) + 8
<core_iref_size> ::= b"\x00\x00\x00\x0c"
<core_iref_payload> ::= <full_v0>
<core_idat_box> ::= <core_idat_size> b"idat" <core_primary_item_data>; where int.from_bytes(bytes(<core_idat_size>), "big") == len(bytes(<core_primary_item_data>)) + 8
<core_idat_size> ::= b"\x00\x00\x00\x14"
<core_primary_item_data> ::= <nal_data_length> <nal_unit>; where int.from_bytes(bytes(<nal_data_length>), "big") == len(bytes(<nal_unit>))

# Scalar and string building blocks

<byte> ::= rb'[\x00-\xff]'
<u8> ::= <byte>
<u16> ::= <byte>{2}
<u24> ::= <byte>{3}
<u32> ::= <byte>{4}
<u64> ::= <byte>{8}
<box_size> ::= b"\x00\x00" (b"\x00" | b"\x01" | b"\x02" | b"\x03") <byte>
<small_count> ::= <u8>
<dimension> ::= b"\x00\x00" <u16>
<ascii_char> ::= rb'[\x20-\x7e]'
<cstring> ::= <ascii_char>{0,12} b"\x00"
<language> ::= rb'[a-z]{3}'
<brand> ::= b"heic" | b"heix" | b"hevc" | b"hevx" | b"mif1" | b"msf1" | b"avci" | b"jpeg"
<full_v0> ::= b"\x00\x00\x00\x00"
<full_v1> ::= b"\x01\x00\x00\x00"
<full_v2> ::= b"\x02\x00\x00\x00"

# File-level boxes

<ftyp_box> ::= <ftyp_box_size> b"ftyp" <ftyp_payload>
<ftyp_payload> ::= b"heic" b"\x00\x00\x00\x00" b"heic" b"mif1" <compatible_brand>{0,2}
<compatible_brand> ::= <brand>

<meta_box> ::= <meta_box_size> b"meta" <meta_payload>
<meta_payload> ::= <full_v0> <meta_handler_box> <pitm_box> <iloc_box> <iinf_box> <iprp_box> <iref_box> <idat_box> <meta_extension>{0,1}
<meta_extension> ::= <xml_box> | <bxml_box> | <grpl_box> | <protection_box>

<mdat_box> ::= <mdat_box_size> b"mdat" <media_data>
<media_data> ::= <byte>{1,32} | <grid_item_data> | <overlay_item_data> | <exif_item_data> | <xmp_item_data> | <uri_item_data>
<free_box> ::= <free_box_size> b"free" <padding_data>
<skip_box> ::= <skip_box_size> b"skip" <padding_data>
<wide_box> ::= b"\x00\x00\x00\x08wide"
<uuid_box> ::= <uuid_box_size> b"uuid" <uuid_payload>
<uuid_payload> ::= <byte>{16} <byte>{0,16}
<padding_data> ::= <byte>{8}
<top_level_extension> ::= <mdat_box> | <movie_box> | <free_box> | <skip_box> | <wide_box> | <uuid_box> | <generic_box>

# Core item metadata

<meta_handler_box> ::= <meta_handler_box_size> b"hdlr" <meta_handler_payload>
<meta_handler_payload> ::= <full_v0> b"\x00\x00\x00\x00" b"pict" b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" b"HEIC items\x00"

<pitm_box> ::= <pitm_box_size> b"pitm" <pitm_payload>
<pitm_payload> ::= <full_v0> b"\x00\x01"

<iloc_box> ::= <iloc_box_size> b"iloc" <iloc_payload>
<iloc_payload> ::= <full_v1> b"\x44\x00" b"\x00\x01" <iloc_primary_item>
<iloc_primary_item> ::= b"\x00\x01" b"\x00\x01" b"\x00\x00" b"\x01" b"\x00\x00\x00\x00" <extent_length>
<extent_length> ::= <u32>

<iinf_box> ::= <iinf_box_size> b"iinf" <iinf_payload>
<iinf_payload> ::= <full_v0> b"\x00\x01" <primary_infe_box> | <full_v0> b"\x00\x02" <primary_infe_box> <generic_infe_box>
<primary_infe_box> ::= <primary_infe_box_size> b"infe" <primary_infe_payload>
<primary_infe_payload> ::= <full_v2> b"\x00\x01" b"\x00\x00" b"hvc1" b"Primary image\x00"

<idat_box> ::= <idat_box_size> b"idat" <primary_item_data>
<primary_item_data> ::= <hevc_item_data>
<hevc_item_data> ::= <length_prefixed_nal>{1,3}
<length_prefixed_nal> ::= <nal_data_length> <nal_unit>
<nal_data_length> ::= b"\x00\x00\x00\x08"

# Reachable syntax for additional HEIF item types.
<item_type> ::= b"hvc1" | b"grid" | b"iovl" | b"iden" | b"Exif" | b"mime" | b"uri b"
<generic_infe_box> ::= <generic_infe_box_size> b"infe" <generic_infe_payload>
<generic_infe_payload> ::= <full_v2> <secondary_item_id> b"\x00\x00" <item_type> <cstring> <item_type_extension>
<secondary_item_id> ::= <u16>
<item_type_extension> ::= b"b" | <mime_extension> | <uri_extension>
<mime_extension> ::= b"image/heic\x00" | b"application/rdf+xml\x00" <cstring>
<uri_extension> ::= b"https://example.invalid/item\x00"
<grid_item_data> ::= b"\x00" <grid_flags> <grid_rows_minus_one> <grid_columns_minus_one> <dimension> <dimension>
<grid_flags> ::= b"\x00" | b"\x01"
<grid_rows_minus_one> ::= <u8>
<grid_columns_minus_one> ::= <u8>
<overlay_item_data> ::= b"\x00" <overlay_flags> <u16> <u16> <dimension> <dimension> <overlay_offsets>{1,2}
<overlay_flags> ::= b"\x00" | b"\x01"
<overlay_offsets> ::= <u16> <u16>
<exif_item_data> ::= b"\x00\x00\x00\x04" b"II\x2a\x00" <byte>{0,16}
<xmp_item_data> ::= b"<?xpacket begin=''?>b" <ascii_char>{0,24} b"<?xpacket end='w'?>b"
<uri_item_data> ::= b"https://example.invalid/resource\x00"

# Item references

<iref_box> ::= <iref_box_size> b"iref" <iref_payload>
<iref_payload> ::= <full_v0> <item_reference>{0,2}
<item_reference> ::= <dimg_reference> | <thmb_reference> | <auxl_reference> | <cdsc_reference> | <prem_reference> | <base_reference>
<dimg_reference> ::= <dimg_reference_size> b"dimg" <reference_payload>
<thmb_reference> ::= <thmb_reference_size> b"thmb" <reference_payload>
<auxl_reference> ::= <auxl_reference_size> b"auxl" <reference_payload>
<cdsc_reference> ::= <cdsc_reference_size> b"cdsc" <reference_payload>
<prem_reference> ::= <prem_reference_size> b"prem" <reference_payload>
<base_reference> ::= <base_reference_size> b"base" <reference_payload>
<reference_payload> ::= b"\x00\x01" b"\x00\x01" <u16>

# Item properties and associations

<iprp_box> ::= <iprp_box_size> b"iprp" <iprp_payload>
<iprp_payload> ::= <ipco_box> <ipma_box>
<ipco_box> ::= <ipco_box_size> b"ipco" <ipco_payload>
<ipco_payload> ::= <ispe_box> <pixi_box> <hvcc_box> <optional_property>{0,2}
<optional_property> ::= <clap_box> | <irot_box> | <imir_box> | <colr_box> | <pasp_box> | <auxc_box> | <rloc_box> | <a1op_box> | <lsel_box> | <oinf_box>

<ipma_box> ::= <ipma_box_size> b"ipma" <ipma_payload>
<ipma_payload> ::= <full_v0> b"\x00\x00\x00\x01" b"\x00\x01" b"\x03" b"\x81\x82\x83"

<ispe_box> ::= <ispe_box_size> b"ispe" <ispe_payload>
<ispe_payload> ::= <full_v0> <dimension> <dimension>
<pixi_box> ::= <pixi_box_size> b"pixi" <pixi_payload>
<pixi_payload> ::= <full_v0> b"\x03\x08\x08\x08" | <full_v0> b"\x01\x08"

<hvcc_box> ::= <hvcc_box_size> b"hvcC" <hvcc_payload>
<hvcc_payload> ::= b"\x01" <hevc_profile_space_tier_idc> <u32> <byte>{6} <u8> b"\xf0\x00\xfc\xfd\xf8\xf8\x00\x00\x0f" <hevc_arrays>
<hevc_profile_space_tier_idc> ::= <u8>; where int.from_bytes(bytes(<hevc_profile_space_tier_idc>), "big") <= 31
<hevc_arrays> ::= b"\x03" <vps_array> <sps_array> <pps_array>
<vps_array> ::= b"\xa0\x00\x01" <nal_length> <vps_nal>; where int.from_bytes(bytes(<nal_length>), "big") == len(bytes(<vps_nal>))
<sps_array> ::= b"\xa1\x00\x01" <nal_length> <sps_nal>; where int.from_bytes(bytes(<nal_length>), "big") == len(bytes(<sps_nal>))
<pps_array> ::= b"\xa2\x00\x01" <nal_length> <pps_nal>; where int.from_bytes(bytes(<nal_length>), "big") == len(bytes(<pps_nal>))
<nal_length> ::= b"\x00\x08"
<vps_nal> ::= b"\x40\x01" <byte>{6}
<sps_nal> ::= b"\x42\x01" <byte>{6}
<pps_nal> ::= b"\x44\x01" <byte>{6}
<nal_unit> ::= <nal_header> <byte>{6}
<nal_header> ::= b"\x40\x01" | b"\x42\x01" | b"\x44\x01" | b"\x26\x01" | b"\x02\x01"

<clap_box> ::= <clap_box_size> b"clap" <clap_payload>
<clap_payload> ::= <rational> <rational> <rational> <rational>
<rational> ::= <u32> <u32_nonzero>
<u32_nonzero> ::= <u32>
<irot_box> ::= <irot_box_size> b"irot" <irot_payload>
<irot_payload> ::= b"\x00" | b"\x01" | b"\x02" | b"\x03"
<imir_box> ::= <imir_box_size> b"imir" <imir_payload>
<imir_payload> ::= b"\x00" | b"\x01"
<colr_box> ::= <colr_box_size> b"colr" <colr_payload>
<colr_payload> ::= <nclx_colour> | <icc_colour>
<nclx_colour> ::= b"nclx" <colour_primaries> <transfer_characteristics> <matrix_coefficients> <full_range_flag>
<colour_primaries> ::= b"\x00\x01" | b"\x00\x09" | b"\x00\x0c"
<transfer_characteristics> ::= b"\x00\x01" | b"\x00\x0e" | b"\x00\x10" | b"\x00\x12"
<matrix_coefficients> ::= b"\x00\x00" | b"\x00\x01" | b"\x00\x09"
<full_range_flag> ::= b"\x00" | b"\x80"
<icc_colour> ::= (b"prof" | b"rICC") <byte>{4,24}
<pasp_box> ::= <pasp_box_size> b"pasp" <pasp_payload>
<pasp_payload> ::= <u32_nonzero> <u32_nonzero>
<auxc_box> ::= <auxc_box_size> b"auxC" <auxc_payload>
<auxc_payload> ::= <full_v0> <aux_type> <byte>{0,8}
<aux_type> ::= b"urn:mpeg:hevc:2015:auxid:1\x00" | b"urn:mpeg:mpegB:cicp:systems:auxiliary:alpha\x00"
<rloc_box> ::= <rloc_box_size> b"rloc" <rloc_payload>
<rloc_payload> ::= <full_v0> <u32> <u32>
<a1op_box> ::= <a1op_box_size> b"a1op" <a1op_payload>
<a1op_payload> ::= b"\x00" | b"\x01"
<lsel_box> ::= <lsel_box_size> b"lsel" <lsel_payload>
<lsel_payload> ::= <u16>
<oinf_box> ::= <oinf_box_size> b"oinf" <oinf_payload>
<oinf_payload> ::= <full_v0> <u16> <u16> <byte>{0,8}

# XML, grouping, and protection

<xml_box> ::= <xml_box_size> b"xml b" <xml_payload>
<xml_payload> ::= <full_v0> b"<heif/>b"
<bxml_box> ::= <bxml_box_size> b"bxml" <bxml_payload>
<bxml_payload> ::= <full_v0> <byte>{1,16}
<grpl_box> ::= <grpl_box_size> b"grpl" <grpl_payload>
<grpl_payload> ::= <entity_group>{1,2}
<entity_group> ::= <altr_group> | <ster_group> | <eqiv_group> | <custom_group>
<altr_group> ::= <altr_group_size> b"altr" <entity_group_payload>
<ster_group> ::= <ster_group_size> b"ster" <entity_group_payload>
<eqiv_group> ::= <eqiv_group_size> b"eqiv" <entity_group_payload>
<custom_group> ::= <custom_group_size> b"trgr" <entity_group_payload>
<entity_group_payload> ::= <full_v0> <u32> b"\x00\x00\x00\x01" b"\x00\x00\x00\x01"

<protection_box> ::= <protection_box_size> b"ipro" <protection_payload>
<protection_payload> ::= <full_v0> b"\x00\x01" <sinf_box>
<sinf_box> ::= <sinf_box_size> b"sinf" <sinf_payload>
<sinf_payload> ::= <frma_box> <schm_box> <schi_box>
<frma_box> ::= b"\x00\x00\x00\x0cfrmahvc1"
<schm_box> ::= <schm_box_size> b"schm" <schm_payload>
<schm_payload> ::= <full_v0> b"cenc" b"\x00\x01\x00\x00"
<schi_box> ::= <schi_box_size> b"schi" <schi_payload>
<schi_payload> ::= <tenc_box>
<tenc_box> ::= <tenc_box_size> b"tenc" <tenc_payload>
<tenc_payload> ::= <full_v0> b"\x00\x00\x01\x08" <byte>{16}

# Timed image sequences / movie boxes

<movie_box> ::= <movie_box_size> b"moov" <movie_payload>
<movie_payload> ::= <mvhd_box> <trak_box> <movie_extension>{0,1}
<movie_extension> ::= <free_box> | <uuid_box>
<mvhd_box> ::= <mvhd_box_size> b"mvhd" <mvhd_payload>
<mvhd_payload> ::= <full_v0> <u32> <u32> <timescale> <duration> b"\x00\x01\x00\x00\x01\x00" b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" <unity_matrix> <byte>{24} b"\x00\x00\x00\x02"
<timescale> ::= <u32>
<duration> ::= <u32>
<unity_matrix> ::= b"\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00"

<trak_box> ::= <trak_box_size> b"trak" <trak_payload>
<trak_payload> ::= <tkhd_box> <mdia_box>
<tkhd_box> ::= <tkhd_box_size> b"tkhd" <tkhd_payload>
<tkhd_payload> ::= b"\x00\x00\x00\x07" <u32> <u32> b"\x00\x00\x00\x01" b"\x00\x00\x00\x00" <duration> <byte>{8} b"\x00\x00\x00\x00\x00\x00\x00\x00" <unity_matrix> <dimension> <dimension>
<mdia_box> ::= <mdia_box_size> b"mdia" <mdia_payload>
<mdia_payload> ::= <mdhd_box> <video_handler_box> <minf_box>
<mdhd_box> ::= <mdhd_box_size> b"mdhd" <mdhd_payload>
<mdhd_payload> ::= <full_v0> <u32> <u32> <timescale> <duration> <packed_language> b"\x00\x00"
<packed_language> ::= b"\x15\xc7" | b"\x55\xc4"
<video_handler_box> ::= <video_handler_box_size> b"hdlr" <video_handler_payload>
<video_handler_payload> ::= <full_v0> b"\x00\x00\x00\x00" b"vide" <byte>{12} b"HEVC sequence\x00"
<minf_box> ::= <minf_box_size> b"minf" <minf_payload>
<minf_payload> ::= <vmhd_box> <dinf_box> <stbl_box>
<vmhd_box> ::= b"\x00\x00\x00\x14vmhd\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00"
<dinf_box> ::= <dinf_box_size> b"dinf" <dinf_payload>
<dinf_payload> ::= <dref_box>
<dref_box> ::= <dref_box_size> b"dref" <dref_payload>
<dref_payload> ::= <full_v0> b"\x00\x00\x00\x01" <data_entry>
<data_entry> ::= <url_box> | <urn_box>
<url_box> ::= b"\x00\x00\x00\x0curl \x00\x00\x00\x01"
<urn_box> ::= <urn_box_size> b"urn b" <urn_payload>
<urn_payload> ::= <full_v0> <cstring> <cstring>

<stbl_box> ::= <stbl_box_size> b"stbl" <stbl_payload>
<stbl_payload> ::= <stsd_box> <stts_box> <ctts_box>{0,1} <stsc_box> <stsz_box> (<stco_box> | <co64_box>) <stss_box>{0,1} <sdtp_box>{0,1}
<stsd_box> ::= <stsd_box_size> b"stsd" <stsd_payload>
<stsd_payload> ::= <full_v0> b"\x00\x00\x00\x01" <visual_sample_entry>
<visual_sample_entry> ::= <hvc1_sample_entry> | <hev1_sample_entry>
<hvc1_sample_entry> ::= <hvc1_sample_entry_size> b"hvc1" <visual_sample_payload>
<hev1_sample_entry> ::= <hev1_sample_entry_size> b"hev1" <visual_sample_payload>
<visual_sample_payload> ::= <byte>{6} b"\x00\x01" <byte>{16} <u16> <u16> b"\x00\x48\x00\x00\x00\x48\x00\x00\x00\x00\x00\x00\x00\x01" <compressor_name> b"\x00\x18\xff\xff" <hvcc_box> <sample_entry_property>{0,1}
<compressor_name> ::= b"\x04HEVC" <byte>{27}
<sample_entry_property> ::= <pasp_box> | <colr_box> | <clap_box> | <sinf_box>

<stts_box> ::= <stts_box_size> b"stts" <stts_payload>
<stts_payload> ::= <full_v0> b"\x00\x00\x00\x01" <u32> <u32_nonzero>
<ctts_box> ::= <ctts_box_size> b"ctts" <ctts_payload>
<ctts_payload> ::= (<full_v0> | <full_v1>) b"\x00\x00\x00\x01" <u32> <u32>
<stsc_box> ::= <stsc_box_size> b"stsc" <stsc_payload>
<stsc_payload> ::= <full_v0> b"\x00\x00\x00\x01" b"\x00\x00\x00\x01" <u32_nonzero> b"\x00\x00\x00\x01"
<stsz_box> ::= <stsz_box_size> b"stsz" <stsz_payload>
<stsz_payload> ::= <full_v0> <u32> <u32>
<stco_box> ::= <stco_box_size> b"stco" <stco_payload>
<stco_payload> ::= <full_v0> b"\x00\x00\x00\x01" <u32>
<co64_box> ::= <co64_box_size> b"co64" <co64_payload>
<co64_payload> ::= <full_v0> b"\x00\x00\x00\x01" <u64>
<stss_box> ::= <stss_box_size> b"stss" <stss_payload>
<stss_payload> ::= <full_v0> b"\x00\x00\x00\x01" b"\x00\x00\x00\x01"
<sdtp_box> ::= <sdtp_box_size> b"sdtp" <sdtp_payload>
<sdtp_payload> ::= <full_v0> <byte>{1,8}

# Generic, forward-compatible extension box

<generic_box> ::= <generic_box_size> <generic_type> <generic_payload>
<generic_type> ::= b"prft" | b"elng" | b"kind" | b"cslg" | b"subs"
<generic_payload> ::= <full_v0> <byte>{0,24}

# Per-box size fields keep each length constraint structurally scoped.
<ftyp_box_size> ::= <box_size>
<meta_box_size> ::= <box_size>
<mdat_box_size> ::= <box_size>
<free_box_size> ::= <box_size>
<skip_box_size> ::= <box_size>
<uuid_box_size> ::= <box_size>
<meta_handler_box_size> ::= <box_size>
<pitm_box_size> ::= <box_size>
<iloc_box_size> ::= <box_size>
<iinf_box_size> ::= <box_size>
<primary_infe_box_size> ::= <box_size>
<idat_box_size> ::= <box_size>
<generic_infe_box_size> ::= <box_size>
<iref_box_size> ::= <box_size>
<dimg_reference_size> ::= <box_size>
<thmb_reference_size> ::= <box_size>
<auxl_reference_size> ::= <box_size>
<cdsc_reference_size> ::= <box_size>
<prem_reference_size> ::= <box_size>
<base_reference_size> ::= <box_size>
<iprp_box_size> ::= <box_size>
<ipco_box_size> ::= <box_size>
<ipma_box_size> ::= <box_size>
<ispe_box_size> ::= <box_size>
<pixi_box_size> ::= <box_size>
<hvcc_box_size> ::= <box_size>
<clap_box_size> ::= <box_size>
<irot_box_size> ::= <box_size>
<imir_box_size> ::= <box_size>
<colr_box_size> ::= <box_size>
<pasp_box_size> ::= <box_size>
<auxc_box_size> ::= <box_size>
<rloc_box_size> ::= <box_size>
<a1op_box_size> ::= <box_size>
<lsel_box_size> ::= <box_size>
<oinf_box_size> ::= <box_size>
<xml_box_size> ::= <box_size>
<bxml_box_size> ::= <box_size>
<grpl_box_size> ::= <box_size>
<altr_group_size> ::= <box_size>
<ster_group_size> ::= <box_size>
<eqiv_group_size> ::= <box_size>
<custom_group_size> ::= <box_size>
<protection_box_size> ::= <box_size>
<sinf_box_size> ::= <box_size>
<schm_box_size> ::= <box_size>
<schi_box_size> ::= <box_size>
<tenc_box_size> ::= <box_size>
<movie_box_size> ::= <box_size>
<mvhd_box_size> ::= <box_size>
<trak_box_size> ::= <box_size>
<tkhd_box_size> ::= <box_size>
<mdia_box_size> ::= <box_size>
<mdhd_box_size> ::= <box_size>
<video_handler_box_size> ::= <box_size>
<minf_box_size> ::= <box_size>
<dinf_box_size> ::= <box_size>
<dref_box_size> ::= <box_size>
<urn_box_size> ::= <box_size>
<stbl_box_size> ::= <box_size>
<stsd_box_size> ::= <box_size>
<hvc1_sample_entry_size> ::= <box_size>
<hev1_sample_entry_size> ::= <box_size>
<stts_box_size> ::= <box_size>
<ctts_box_size> ::= <box_size>
<stsc_box_size> ::= <box_size>
<stsz_box_size> ::= <box_size>
<stco_box_size> ::= <box_size>
<co64_box_size> ::= <box_size>
<stss_box_size> ::= <box_size>
<sdtp_box_size> ::= <box_size>
<generic_box_size> ::= <box_size>
