# One little endian grayscale TIFF with a 55 entry IFD: all twelve field types,
# document and color tags, XMP, IPTC, Photoshop, Exif, GPS and ICC data, and a
# SubIFD with a tiled reduced image. Values that do not fit in the entry live
# in an area after the IFD. Offsets and lengths are checked with where clauses.
#
# TODO:
# * Might serve as a better structured `tiff.fan` specification.

<start> ::= <tiff_header> <main_ifd> <value_area>

# Header

<tiff_header> ::= <byte_order> <tiff_magic> <first_ifd_offset>
<byte_order> ::= b'II'
<tiff_magic> ::= b'\x2a\x00'
<first_ifd_offset> ::= b'\x08\x00\x00\x00'

# Primary IFD

<main_ifd> ::= <main_ifd_count> <main_ifd_entries> <next_ifd_offset>
<main_ifd_count> ::= b'\x37\x00'
<next_ifd_offset> ::= b'\x00\x00\x00\x00'

<main_ifd_entries> ::= (
    <new_subfile_type_entry> <image_width_entry> <image_length_entry>
    <bits_per_sample_entry> <compression_entry> <photometric_entry>
    <thresholding_entry> <cell_width_entry> <cell_length_entry>
    <fill_order_entry> <document_name_entry> <image_description_entry>
    <make_entry> <model_entry> <strip_offsets_entry> <orientation_entry>
    <samples_per_pixel_entry> <rows_per_strip_entry> <strip_byte_counts_entry>
    <min_sample_value_entry> <max_sample_value_entry> <x_resolution_entry>
    <y_resolution_entry> <planar_configuration_entry> <page_name_entry>
    <x_position_entry> <y_position_entry> <gray_response_unit_entry>
    <gray_response_curve_entry> <resolution_unit_entry> <page_number_entry>
    <transfer_function_entry> <software_entry> <date_time_entry>
    <artist_entry> <host_computer_entry> <predictor_entry> <white_point_entry>
    <primary_chromaticities_entry> <halftone_hints_entry> <subifds_entry>
    <xmp_entry> <iptc_entry> <photoshop_entry> <exif_ifd_entry>
    <icc_profile_entry> <gps_ifd_entry> <copyright_or_private_byte_entry>
    <private_sbyte_entry> <private_undefined_entry> <private_sshort_entry>
    <private_slong_entry> <private_srational_entry> <private_float_entry>
    <private_double_entry>
)

# Each production below is one complete 12-byte TIFF directory entry:
# tag (2), type (2), count (4), then inline value or value offset (4).

<new_subfile_type_entry> ::= b'\xfe\x00\x04\x00\x01\x00\x00\x00\x00\x00\x00\x00'
<image_width_entry> ::= b'\x00\x01\x04\x00\x01\x00\x00\x00' <main_image_width>
<main_image_width> ::= b'\x01\x00\x00\x00'
<image_length_entry> ::= b'\x01\x01\x04\x00\x01\x00\x00\x00' <main_image_length>
<main_image_length> ::= b'\x01\x00\x00\x00'
<bits_per_sample_entry> ::= b'\x02\x01\x03\x00\x01\x00\x00\x00' <bits_per_sample> b'\x00\x00'
<bits_per_sample> ::= b'\x08\x00'
<compression_entry> ::= b'\x03\x01\x03\x00\x01\x00\x00\x00' <compression_value> b'\x00\x00'
<compression_value> ::= b'\x01\x00'
<photometric_entry> ::= b'\x06\x01\x03\x00\x01\x00\x00\x00' <photometric_value> b'\x00\x00'
<photometric_value> ::= b'\x01\x00'
<thresholding_entry> ::= b'\x07\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00'
<cell_width_entry> ::= b'\x08\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00'
<cell_length_entry> ::= b'\x09\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00'
<fill_order_entry> ::= b'\x0a\x01\x03\x00\x01\x00\x00\x00' <fill_order_value> b'\x00\x00'
<fill_order_value> ::= b'\x01\x00'
<document_name_entry> ::= b'\x0d\x01\x02\x00' <document_name_count> <document_name_offset>
<document_name_count> ::= b'\x0c\x00\x00\x00'
<document_name_offset> ::= b'\xa2\x02\x00\x00'
<image_description_entry> ::= b'\x0e\x01\x02\x00' <description_count> <description_offset>
<description_count> ::= b'\x18\x00\x00\x00'
<description_offset> ::= b'\xae\x02\x00\x00'
<make_entry> ::= b'\x0f\x01\x02\x00' <make_count> <make_offset>
<make_count> ::= b'\x0c\x00\x00\x00'
<make_offset> ::= b'\xc6\x02\x00\x00'
<model_entry> ::= b'\x10\x01\x02\x00' <model_count> <model_offset>
<model_count> ::= b'\x0c\x00\x00\x00'
<model_offset> ::= b'\xd2\x02\x00\x00'
<strip_offsets_entry> ::= b'\x11\x01\x04\x00\x01\x00\x00\x00' <main_strip_offset>
<main_strip_offset> ::= b'\x1f\x09\x00\x00'
<orientation_entry> ::= b'\x12\x01\x03\x00\x01\x00\x00\x00' <orientation_value> b'\x00\x00'
<orientation_value> ::= b'\x01\x00' | b'\x03\x00' | b'\x06\x00' | b'\x08\x00'
<samples_per_pixel_entry> ::= b'\x15\x01\x03\x00\x01\x00\x00\x00' <samples_per_pixel> b'\x00\x00'
<samples_per_pixel> ::= b'\x01\x00'
<rows_per_strip_entry> ::= b'\x16\x01\x04\x00\x01\x00\x00\x00' <rows_per_strip>
<rows_per_strip> ::= b'\x01\x00\x00\x00'
<strip_byte_counts_entry> ::= b'\x17\x01\x04\x00\x01\x00\x00\x00' <main_strip_byte_count>
<main_strip_byte_count> ::= b'\x01\x00\x00\x00'
<min_sample_value_entry> ::= b'\x18\x01\x03\x00\x01\x00\x00\x00\x00\x00\x00\x00'
<max_sample_value_entry> ::= b'\x19\x01\x03\x00\x01\x00\x00\x00\xff\x00\x00\x00'
<x_resolution_entry> ::= b'\x1a\x01\x05\x00\x01\x00\x00\x00' <x_resolution_offset>
<x_resolution_offset> ::= b'\xde\x02\x00\x00'
<y_resolution_entry> ::= b'\x1b\x01\x05\x00\x01\x00\x00\x00' <y_resolution_offset>
<y_resolution_offset> ::= b'\xe6\x02\x00\x00'
<planar_configuration_entry> ::= b'\x1c\x01\x03\x00\x01\x00\x00\x00' <planar_configuration> b'\x00\x00'
<planar_configuration> ::= b'\x01\x00'
<page_name_entry> ::= b'\x1d\x01\x02\x00' <page_name_count> <page_name_offset>
<page_name_count> ::= b'\x0c\x00\x00\x00'
<page_name_offset> ::= b'\xee\x02\x00\x00'
<x_position_entry> ::= b'\x1e\x01\x05\x00\x01\x00\x00\x00' <x_position_offset>
<x_position_offset> ::= b'\xfa\x02\x00\x00'
<y_position_entry> ::= b'\x1f\x01\x05\x00\x01\x00\x00\x00' <y_position_offset>
<y_position_offset> ::= b'\x02\x03\x00\x00'
<gray_response_unit_entry> ::= b'\x22\x01\x03\x00\x01\x00\x00\x00\x02\x00\x00\x00'
<gray_response_curve_entry> ::= b'\x23\x01\x03\x00' <gray_curve_count> <gray_curve_offset>
<gray_curve_count> ::= b'\x00\x01\x00\x00'
<gray_curve_offset> ::= b'\x0a\x03\x00\x00'
<resolution_unit_entry> ::= b'\x28\x01\x03\x00\x01\x00\x00\x00' <resolution_unit> b'\x00\x00'
<resolution_unit> ::= b'\x02\x00' | b'\x03\x00'
<page_number_entry> ::= b'\x29\x01\x03\x00\x02\x00\x00\x00\x00\x00\x01\x00'
<transfer_function_entry> ::= b'\x2d\x01\x03\x00' <transfer_count> <transfer_offset>
<transfer_count> ::= b'\x00\x01\x00\x00'
<transfer_offset> ::= b'\x0a\x05\x00\x00'
<software_entry> ::= b'\x31\x01\x02\x00' <software_count> <software_offset>
<software_count> ::= b'\x10\x00\x00\x00'
<software_offset> ::= b'\x0a\x07\x00\x00'
<date_time_entry> ::= b'\x32\x01\x02\x00' <date_time_count> <date_time_offset>
<date_time_count> ::= b'\x14\x00\x00\x00'
<date_time_offset> ::= b'\x1a\x07\x00\x00'
<artist_entry> ::= b'\x3b\x01\x02\x00' <artist_count> <artist_offset>
<artist_count> ::= b'\x0c\x00\x00\x00'
<artist_offset> ::= b'\x2e\x07\x00\x00'
<host_computer_entry> ::= b'\x3c\x01\x02\x00' <host_count> <host_offset>
<host_count> ::= b'\x0c\x00\x00\x00'
<host_offset> ::= b'\x3a\x07\x00\x00'
<predictor_entry> ::= b'\x3d\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00'
<white_point_entry> ::= b'\x3e\x01\x05\x00\x02\x00\x00\x00' <white_point_offset>
<white_point_offset> ::= b'\x46\x07\x00\x00'
<primary_chromaticities_entry> ::= b'\x3f\x01\x05\x00\x06\x00\x00\x00' <primaries_offset>
<primaries_offset> ::= b'\x56\x07\x00\x00'
<halftone_hints_entry> ::= b'\x41\x01\x03\x00\x02\x00\x00\x00\x00\x00\xff\x00'
<subifds_entry> ::= b'\x4a\x01\x04\x00\x01\x00\x00\x00' <subifd_offset>
<subifd_offset> ::= b'\x88\x08\x00\x00'
<xmp_entry> ::= b'\xbc\x02\x01\x00' <xmp_count> <xmp_offset>
<xmp_count> ::= b'\x20\x00\x00\x00'
<xmp_offset> ::= b'\x86\x07\x00\x00'
<iptc_entry> ::= b'\xbb\x83\x07\x00' <iptc_count> <iptc_offset>
<iptc_count> ::= b'\x08\x00\x00\x00'
<iptc_offset> ::= b'\xa6\x07\x00\x00'
<photoshop_entry> ::= b'\x49\x86\x07\x00' <photoshop_count> <photoshop_offset>
<photoshop_count> ::= b'\x0c\x00\x00\x00'
<photoshop_offset> ::= b'\xae\x07\x00\x00'
<exif_ifd_entry> ::= b'\x69\x87\x04\x00\x01\x00\x00\x00' <exif_ifd_offset>
<exif_ifd_offset> ::= b'\x7c\x08\x00\x00'
<icc_profile_entry> ::= b'\x73\x87\x07\x00' <icc_count> <icc_offset>
<icc_count> ::= b'\x80\x00\x00\x00'
<icc_offset> ::= b'\xce\x07\x00\x00'
<gps_ifd_entry> ::= b'\x25\x88\x04\x00\x01\x00\x00\x00' <gps_ifd_offset>
<gps_ifd_offset> ::= b'\x82\x08\x00\x00'
<copyright_or_private_byte_entry> ::= <copyright_entry> | <private_byte_entry>
<copyright_entry> ::= b'\x98\x82\x02\x00\x14\x00\x00\x00\xba\x07\x00\x00'

# Private tags are used to get every field type, including the signed and
# floating point ones, into the file.
<private_byte_entry> ::= b'\xe8\xfd\x01\x00\x04\x00\x00\x00\x00\x7f\x80\xff'
<private_sbyte_entry> ::= b'\xe9\xfd\x06\x00\x04\x00\x00\x00\x80\xff\x00\x7f'
<private_undefined_entry> ::= b'\xea\xfd\x07\x00\x08\x00\x00\x00' <undefined_offset>
<undefined_offset> ::= b'\x4e\x08\x00\x00'
<private_sshort_entry> ::= b'\xeb\xfd\x08\x00\x03\x00\x00\x00' <sshort_offset>
<sshort_offset> ::= b'\x56\x08\x00\x00'
<private_slong_entry> ::= b'\xec\xfd\x09\x00\x02\x00\x00\x00' <slong_offset>
<slong_offset> ::= b'\x5c\x08\x00\x00'
<private_srational_entry> ::= b'\xed\xfd\x0a\x00\x01\x00\x00\x00' <srational_offset>
<srational_offset> ::= b'\x64\x08\x00\x00'
<private_float_entry> ::= b'\xee\xfd\x0b\x00\x02\x00\x00\x00' <float_offset>
<float_offset> ::= b'\x6c\x08\x00\x00'
<private_double_entry> ::= b'\xef\xfd\x0c\x00\x01\x00\x00\x00' <double_offset>
<double_offset> ::= b'\x74\x08\x00\x00'

# Out-of-line values

<value_area> ::= <metadata_values> <nested_directories> <tile_pixel> <main_pixel>
<metadata_values> ::= (
    <document_name_data> <description_data> <make_data> <model_data>
    <x_resolution_data> <y_resolution_data> <page_name_data>
    <x_position_data> <y_position_data> <gray_curve_data>
    <transfer_function_data> <software_data> <date_time_data>
    <artist_data> <host_data> <white_point_data> <primaries_data>
    <xmp_data> <iptc_data> <photoshop_data> <copyright_data>
    <icc_profile_data> <undefined_data> <sshort_data> <slong_data>
    <srational_data> <float_data> <double_data>
)

<document_name_data> ::= b'image.tif\x00\x00\x00'
<description_data> ::= b'Fandango TIFF specimen\x00\x00'
<make_data> ::= b'Acme\x00\x00\x00\x00\x00\x00\x00\x00'
<model_data> ::= b'FanTIFF 1\x00\x00\x00'
<x_resolution_data> ::= b'\x2c\x01\x00\x00\x01\x00\x00\x00'
<y_resolution_data> ::= b'\x2c\x01\x00\x00\x01\x00\x00\x00'
<page_name_data> ::= b'Page 1\x00\x00\x00\x00\x00\x00'
<x_position_data> ::= b'\x00\x00\x00\x00\x01\x00\x00\x00'
<y_position_data> ::= b'\x00\x00\x00\x00\x01\x00\x00\x00'
<gray_curve_data> ::= <gray_curve_sample>{256}
<gray_curve_sample> ::= b'\x00\x00' | b'\xff\xff'
<transfer_function_data> ::= <transfer_sample>{256}
<transfer_sample> ::= b'\x00\x00' | b'\xff\xff'
<software_data> ::= b'Fandango 1.1.1\x00\x00'
<date_time_data> ::= b'2026:08:05 12:00:00\x00'
<artist_data> ::= b'Acme\x00\x00\x00\x00\x00\x00\x00\x00'
<host_data> ::= b'localhost\x00\x00\x00'
<white_point_data> ::= b'\x38\x31\x00\x00\x10\x27\x00\x00\x4d\x28\x00\x00\x10\x27\x00\x00'
<primaries_data> ::= (
    b'\x6a\x18\x00\x00\x10\x27\x00\x00' b'\x80\x0c\x00\x00\x10\x27\x00\x00'
    b'\x64\x0b\x00\x00\x10\x27\x00\x00' b'\xc4\x17\x00\x00\x10\x27\x00\x00'
    b'\xdc\x05\x00\x00\x10\x27\x00\x00' b'\x58\x02\x00\x00\x10\x27\x00\x00'
)
<xmp_data> ::= b'<?xpacket?><x:xmpmeta/>        \x00'
<iptc_data> ::= b'\x1c\x02\x00\x00\x00\x00\x00\x00'
<photoshop_data> ::= b'8BIM\x04\x04\x00\x00\x00\x00\x00\x00'
<copyright_data> ::= b'Public domain 2026\x00\x00'
<icc_profile_data> ::= (
    b'\x00\x00\x00\x80\x00\x00\x00\x00\x04\x30\x00\x00mntrGRAYXYZ '
    b'\x07\xea\x00\x08\x00\x05\x00\x0c\x00\x00\x00\x00acspAPPL'
    b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
    b'\x00\x00\x00\x01\x00\x00\xf6\xd6\x00\x01\x00\x00\x00\x00\xd3\x2d'
    b'FAN0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
    b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
    b'\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
)
<undefined_data> ::= b'FAN\x00TIFF'
<sshort_data> ::= b'\xff\xff\x00\x00\x01\x00'
<slong_data> ::= b'\xff\xff\xff\xff\x01\x00\x00\x00'
<srational_data> ::= b'\xff\xff\xff\xff\x01\x00\x00\x00'
<float_data> ::= b'\x00\x00\x00\x3f\x00\x00\x80\x3f'
<double_data> ::= b'\x00\x00\x00\x00\x00\x00\xf0\x3f'

# Exif/GPS pointers and tiled SubIFD

<nested_directories> ::= <empty_exif_ifd> <empty_gps_ifd> <tile_ifd>
<empty_exif_ifd> ::= b'\x00\x00\x00\x00\x00\x00'
<empty_gps_ifd> ::= b'\x00\x00\x00\x00\x00\x00'
<tile_ifd> ::= <tile_ifd_count> <tile_ifd_entries> <tile_next_ifd_offset>
<tile_ifd_count> ::= b'\x0c\x00'
<tile_next_ifd_offset> ::= b'\x00\x00\x00\x00'
<tile_ifd_entries> ::= (
    <tile_new_subfile_entry> <tile_image_width_entry> <tile_image_length_entry>
    <tile_bits_entry> <tile_compression_entry> <tile_photometric_entry>
    <tile_samples_entry> <tile_planar_entry> <tile_width_entry>
    <tile_length_entry> <tile_offsets_entry> <tile_byte_counts_entry>
)
<tile_new_subfile_entry> ::= b'\xfe\x00\x04\x00\x01\x00\x00\x00\x01\x00\x00\x00'
<tile_image_width_entry> ::= b'\x00\x01\x04\x00\x01\x00\x00\x00\x01\x00\x00\x00'
<tile_image_length_entry> ::= b'\x01\x01\x04\x00\x01\x00\x00\x00\x01\x00\x00\x00'
<tile_bits_entry> ::= b'\x02\x01\x03\x00\x01\x00\x00\x00\x08\x00\x00\x00'
<tile_compression_entry> ::= b'\x03\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00'
<tile_photometric_entry> ::= b'\x06\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00'
<tile_samples_entry> ::= b'\x15\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00'
<tile_planar_entry> ::= b'\x1c\x01\x03\x00\x01\x00\x00\x00\x01\x00\x00\x00'
<tile_width_entry> ::= b'\x42\x01\x04\x00\x01\x00\x00\x00\x10\x00\x00\x00'
<tile_length_entry> ::= b'\x43\x01\x04\x00\x01\x00\x00\x00\x10\x00\x00\x00'
<tile_offsets_entry> ::= b'\x44\x01\x04\x00\x01\x00\x00\x00' <tile_data_offset>
<tile_data_offset> ::= b'\x1e\x09\x00\x00'
<tile_byte_counts_entry> ::= b'\x45\x01\x04\x00\x01\x00\x00\x00' <tile_byte_count>
<tile_byte_count> ::= b'\x01\x00\x00\x00'
<tile_pixel> ::= <pixel_byte>
<main_pixel> ::= <pixel_byte>
<pixel_byte> ::= b'\x00' | b'\x40' | b'\x80' | b'\xff'

# Semantic constraints
# Offsets and counts are compared with the little-endian encoding of the real
# subtree lengths.

where str(<byte_order>) == 'II'
where str(<tiff_magic>) == (42).to_bytes(2, 'little').decode('latin-1')
where str(<first_ifd_offset>) == len(str(<tiff_header>)).to_bytes(4, 'little').decode('latin-1')
where str(<main_ifd_count>) == (len(str(<main_ifd_entries>)) // 12).to_bytes(2, 'little').decode('latin-1')
where len(str(<main_ifd_entries>)) == 55 * 12
where len(str(<next_ifd_offset>)) == 4 and str(<next_ifd_offset>) == '\x00\x00\x00\x00'

where str(<document_name_count>) == len(str(<document_name_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<description_count>) == len(str(<description_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<make_count>) == len(str(<make_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<model_count>) == len(str(<model_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<page_name_count>) == len(str(<page_name_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<software_count>) == len(str(<software_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<date_time_count>) == len(str(<date_time_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<artist_count>) == len(str(<artist_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<host_count>) == len(str(<host_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<xmp_count>) == len(str(<xmp_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<iptc_count>) == len(str(<iptc_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<photoshop_count>) == len(str(<photoshop_data>)).to_bytes(4, 'little').decode('latin-1')
where str(<icc_count>) == len(str(<icc_profile_data>)).to_bytes(4, 'little').decode('latin-1')

where str(<document_name_offset>) == (len(str(<tiff_header>)) + len(str(<main_ifd>))).to_bytes(4, 'little').decode('latin-1')
where str(<description_offset>) == (len(str(<tiff_header>)) + len(str(<main_ifd>)) + len(str(<document_name_data>))).to_bytes(4, 'little').decode('latin-1')
where str(<subifd_offset>) == (len(str(<tiff_header>)) + len(str(<main_ifd>)) + len(str(<metadata_values>)) + len(str(<empty_exif_ifd>)) + len(str(<empty_gps_ifd>))).to_bytes(4, 'little').decode('latin-1')
where str(<exif_ifd_offset>) == (len(str(<tiff_header>)) + len(str(<main_ifd>)) + len(str(<metadata_values>))).to_bytes(4, 'little').decode('latin-1')
where str(<gps_ifd_offset>) == (len(str(<tiff_header>)) + len(str(<main_ifd>)) + len(str(<metadata_values>)) + len(str(<empty_exif_ifd>))).to_bytes(4, 'little').decode('latin-1')
where str(<tile_data_offset>) == (len(str(<tiff_header>)) + len(str(<main_ifd>)) + len(str(<metadata_values>)) + len(str(<nested_directories>))).to_bytes(4, 'little').decode('latin-1')
where str(<main_strip_offset>) == (len(str(<tiff_header>)) + len(str(<main_ifd>)) + len(str(<metadata_values>)) + len(str(<nested_directories>)) + len(str(<tile_pixel>))).to_bytes(4, 'little').decode('latin-1')

where str(<main_strip_byte_count>) == len(str(<main_pixel>)).to_bytes(4, 'little').decode('latin-1')
where str(<tile_byte_count>) == len(str(<tile_pixel>)).to_bytes(4, 'little').decode('latin-1')
where str(<gray_curve_count>) == (len(str(<gray_curve_data>)) // 2).to_bytes(4, 'little').decode('latin-1')
where str(<transfer_count>) == (len(str(<transfer_function_data>)) // 2).to_bytes(4, 'little').decode('latin-1')
where len(str(<x_resolution_data>)) == 8 and len(str(<y_resolution_data>)) == 8
where len(str(<white_point_data>)) == 2 * 8 and len(str(<primaries_data>)) == 6 * 8

where int.from_bytes(str(<bits_per_sample>).encode('latin-1'), 'little') in [1, 2, 4, 8, 16, 32, 64]
where int.from_bytes(str(<compression_value>).encode('latin-1'), 'little') in [1, 2, 3, 4, 5, 6, 7, 8, 32773]
where int.from_bytes(str(<photometric_value>).encode('latin-1'), 'little') in range(0, 10)
where int.from_bytes(str(<orientation_value>).encode('latin-1'), 'little') in range(1, 9)
where int.from_bytes(str(<fill_order_value>).encode('latin-1'), 'little') in [1, 2]
where int.from_bytes(str(<resolution_unit>).encode('latin-1'), 'little') in [1, 2, 3]
where str(<rows_per_strip>) == str(<main_image_length>)
where str(<samples_per_pixel>) == '\x01\x00' and str(<planar_configuration>) == '\x01\x00'
where str(<date_time_data>)[4] == ':' and str(<date_time_data>)[7] == ':' and str(<date_time_data>)[10] == ' '
