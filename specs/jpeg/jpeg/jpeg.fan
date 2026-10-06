# JPEG/JFIF: one baseline grayscale 8x8 image with a single MCU. JFIF header,
# a random comment, a random quantization table, one DC and one AC Huffman
# table, restart interval 0.
#
# Rules for the other markers (APPn, SOF1-15, DAC, DNL, RSTn, ...) are defined
# below as well but <start> does not use them. Redefine <start> or the segment
# rules to pull them in.
#
# TODO:
# * Document which JPEG parts are supported.
# * Check which marker elements are variable; 
#   see `jpeg-markers.fan` for the current state.

<start> ::= <soi> <jfif_segment> <comment_segment> <dqt_segment> <dht_segment> <sof0_segment> <dri_segment> <sos_segment> <entropy_data> <eoi>

# Standalone markers and marker fill.
<soi> ::= b'\xff\xd8'
<eoi> ::= b'\xff\xd9'
<marker_fill> ::= b'\xff'+
<tem_marker> ::= b'\xff\x01'
<rst0_marker> ::= b'\xff\xd0'
<rst1_marker> ::= b'\xff\xd1'
<rst2_marker> ::= b'\xff\xd2'
<rst3_marker> ::= b'\xff\xd3'
<rst4_marker> ::= b'\xff\xd4'
<rst5_marker> ::= b'\xff\xd5'
<rst6_marker> ::= b'\xff\xd6'
<rst7_marker> ::= b'\xff\xd7'
<restart_marker> ::= <rst0_marker> | <rst1_marker> | <rst2_marker> | <rst3_marker> | <rst4_marker> | <rst5_marker> | <rst6_marker> | <rst7_marker>

# APP0 to APP15. <start> uses the JFIF form, the others are for the usual
# application conventions and generic APPn data.
<app0_marker> ::= b'\xff\xe0'
<app1_marker> ::= b'\xff\xe1'
<app2_marker> ::= b'\xff\xe2'
<app3_marker> ::= b'\xff\xe3'
<app4_marker> ::= b'\xff\xe4'
<app5_marker> ::= b'\xff\xe5'
<app6_marker> ::= b'\xff\xe6'
<app7_marker> ::= b'\xff\xe7'
<app8_marker> ::= b'\xff\xe8'
<app9_marker> ::= b'\xff\xe9'
<app10_marker> ::= b'\xff\xea'
<app11_marker> ::= b'\xff\xeb'
<app12_marker> ::= b'\xff\xec'
<app13_marker> ::= b'\xff\xed'
<app14_marker> ::= b'\xff\xee'
<app15_marker> ::= b'\xff\xef'
<segment_length_2> ::= b'\x00\x02'
<empty_segment_data> ::= b''
<app3_segment> ::= <app3_marker> <segment_length_2> <empty_segment_data>
<app4_segment> ::= <app4_marker> <segment_length_2> <empty_segment_data>
<app5_segment> ::= <app5_marker> <segment_length_2> <empty_segment_data>
<app6_segment> ::= <app6_marker> <segment_length_2> <empty_segment_data>
<app7_segment> ::= <app7_marker> <segment_length_2> <empty_segment_data>
<app9_segment> ::= <app9_marker> <segment_length_2> <empty_segment_data>
<app10_segment> ::= <app10_marker> <segment_length_2> <empty_segment_data>
<app11_segment> ::= <app11_marker> <segment_length_2> <empty_segment_data>
<app15_segment> ::= <app15_marker> <segment_length_2> <empty_segment_data>

# APP0 JFIF and JFXX.
<jfif_segment> ::= <app0_marker> <jfif_length> <jfif_payload>
<jfif_length> ::= b'\x00\x10'
<jfif_payload> ::= b'JFIF\x00' <jfif_version> <density_units> <x_density> <y_density> <thumbnail_x> <thumbnail_y> <jfif_thumbnail>
<jfif_version> ::= b'\x01\x02'
<density_units> ::= b'\x00' | b'\x01' | b'\x02'
<x_density> ::= b'\x00\x01'
<y_density> ::= b'\x00\x01'
<thumbnail_x> ::= b'\x00'
<thumbnail_y> ::= b'\x00'
<jfif_thumbnail> ::= b''
<jfxx_segment> ::= <app0_marker> b'\x00\x0c' b'JFXX\x00\x10\xff\xd8\xff\xd9'

# APP1 Exif/TIFF and XMP, APP2 ICC, APP8 SPIFF, APP12 Ducky, APP13 Photoshop,
# APP14 Adobe. The payloads keep their identifying headers.
<app1_exif_segment> ::= <app1_marker> b'\x00\x10' b'Exif\x00\x00II\x2a\x00\x08\x00\x00\x00\x00\x00'
<app1_xmp_segment> ::= <app1_marker> b'\x00\x1f' b'http://ns.adobe.com/xap/1.0/\x00'
<app2_icc_segment> ::= <app2_marker> b'\x00\x11' b'ICC_PROFILE\x00\x01\x01\x00'
<app8_spiff_segment> ::= <app8_marker> b'\x00\x20' b'SPIFF\x00\x02\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x08\x08\x05\x00\x00\x00\x00\x01\x00\x00\x00\x01'
<app12_ducky_segment> ::= <app12_marker> b'\x00\x08Ducky\x00'
<app13_photoshop_segment> ::= <app13_marker> b'\x00\x10Photoshop 3.0\x00'
<app14_adobe_segment> ::= <app14_marker> b'\x00\x0fAdobe\x00\x00\x64\x00\x00\x00\x00\x01'

<comment_segment> ::= <com_marker> <comment_length> <comment_payload>
<com_marker> ::= b'\xff\xfe'
<comment_length> ::= b'\x00\x12'
<comment_payload> ::= <comment_byte>{16}
<comment_byte> ::= br'[\x00-\xff]'

# Quantization tables (DQT). This baseline image carries one 8-bit table 0.
<dqt_segment> ::= <dqt_marker> <dqt_length> <dqt_payload>
<dqt_marker> ::= b'\xff\xdb'
<dqt_length> ::= b'\x00\x43'
<dqt_payload> ::= <dqt_table_info> <quant_values>
<dqt_table_info> ::= b'\x00'
<quant_values> ::= <quant_value>{64}
<quant_value> ::= br'[\x01-\xff]'

# Huffman tables (DHT): one DC and one AC table, each with a single code.
<dht_segment> ::= <dht_marker> <dht_length> <dht_payload>
<dht_marker> ::= b'\xff\xc4'
<dht_length> ::= b'\x00\x26'
<dht_payload> ::= <dc_huffman_table> <ac_huffman_table>
<dc_huffman_table> ::= b'\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
<ac_huffman_table> ::= b'\x10\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'

# Arithmetic conditioning (DAC), restart interval (DRI), and number of lines (DNL).
<dac_segment> ::= b'\xff\xcc\x00\x04\x00\x00'
<dri_segment> ::= <dri_marker> <dri_length> <restart_interval>
<dri_marker> ::= b'\xff\xdd'
<dri_length> ::= b'\x00\x04'
<restart_interval> ::= b'\x00\x00'
<dnl_segment> ::= b'\xff\xdc\x00\x04\x00\x08'

# Frame headers. Codes C4, C8 and CC are reserved for DHT, JPG and DAC,
# respectively; all other SOF marker codes have a production here.
<frame_payload> ::= <frame_length> <precision> <image_height> <image_width> <component_count> <frame_component>
<frame_length> ::= b'\x00\x0b'
<precision> ::= b'\x08'
<image_height> ::= b'\x00\x08'
<image_width> ::= b'\x00\x08'
<component_count> ::= b'\x01'
<frame_component> ::= <component_id> <sampling_factors> <quant_table_id>
<component_id> ::= b'\x01'
<sampling_factors> ::= b'\x11'
<quant_table_id> ::= b'\x00'
<sof0_segment> ::= b'\xff\xc0' <frame_payload>
<sof1_segment> ::= b'\xff\xc1' <frame_payload>
<sof2_segment> ::= b'\xff\xc2' <frame_payload>
<sof3_segment> ::= b'\xff\xc3' <frame_payload>
<sof5_segment> ::= b'\xff\xc5' <frame_payload>
<sof6_segment> ::= b'\xff\xc6' <frame_payload>
<sof7_segment> ::= b'\xff\xc7' <frame_payload>
<sof9_segment> ::= b'\xff\xc9' <frame_payload>
<sof10_segment> ::= b'\xff\xca' <frame_payload>
<sof11_segment> ::= b'\xff\xcb' <frame_payload>
<sof13_segment> ::= b'\xff\xcd' <frame_payload>
<sof14_segment> ::= b'\xff\xce' <frame_payload>
<sof15_segment> ::= b'\xff\xcf' <frame_payload>

# Scan header and one complete baseline 8x8 entropy-coded MCU.  The DC and AC
# tables above both encode their only symbol as bit 0; 0x3f is 00 followed by
# legal all-one pad bits, so it contains DC=0 and EOB for the one block.
<sos_segment> ::= <sos_marker> <sos_length> <sos_payload>
<sos_marker> ::= b'\xff\xda'
<sos_length> ::= b'\x00\x08'
<sos_payload> ::= <scan_component_count> <scan_component> <spectral_start> <spectral_end> <successive_approximation>
<scan_component_count> ::= b'\x01'
<scan_component> ::= b'\x01\x00'
<spectral_start> ::= b'\x00'
<spectral_end> ::= b'\x3f'
<successive_approximation> ::= b'\x00'
<entropy_data> ::= b'\x3f'
<stuffed_entropy_byte> ::= b'\xff\x00'
<restart_coded_entropy> ::= <entropy_data> <restart_marker> <entropy_data>

# Hierarchical/extension and otherwise unassigned length-coded markers.
<jpg_extension_segment> ::= b'\xff\xc8' <segment_length_2> <empty_segment_data>
<expansion_segment> ::= b'\xff\xdf' <segment_length_2> <empty_segment_data>
<unassigned_02_segment> ::= b'\xff\x02' <segment_length_2> <empty_segment_data>
<unassigned_bf_segment> ::= b'\xff\xbf' <segment_length_2> <empty_segment_data>

# Length fields and other cross-field checks
where bytes(<soi>) == b'\xff\xd8' and bytes(<eoi>) == b'\xff\xd9'
where len(bytes(<jfif_payload>)) + 2 == int.from_bytes(bytes(<jfif_length>), 'big')
where bytes(<density_units>) in (b'\x00', b'\x01', b'\x02')
where len(bytes(<comment_payload>)) + 2 == int.from_bytes(bytes(<comment_length>), 'big')
where len(bytes(<dqt_payload>)) + 2 == int.from_bytes(bytes(<dqt_length>), 'big')
where len(bytes(<dht_payload>)) + 2 == int.from_bytes(bytes(<dht_length>), 'big')
where len(bytes(<frame_payload>)) == int.from_bytes(bytes(<frame_length>), 'big')
where 1 <= int.from_bytes(bytes(<image_height>), 'big') <= 65535 and 1 <= int.from_bytes(bytes(<image_width>), 'big') <= 65535
where bytes(<component_count>) == b'\x01' and bytes(<scan_component_count>) == bytes(<component_count>)
where bytes(<scan_component>)[:1] == bytes(<component_id>) and bytes(<scan_component>)[1:] == b'\x00'
where len(bytes(<sos_payload>)) + 2 == int.from_bytes(bytes(<sos_length>), 'big')
where len(bytes(<restart_interval>)) + 2 == int.from_bytes(bytes(<dri_length>), 'big') and int.from_bytes(bytes(<restart_interval>), 'big') == 0
