# Complete ADTS frames, one for each raw_data_block syntactic element: a bare
# ID_END, single-channel, channel-pair, coupling-channel and low-frequency
# elements, a data-stream and a program-config element, a fill element, AAC
# Main prediction, an eight-short-window sequence, TNS, SSR gain control, the
# SBR, SBR-with-CRC and dynamic-range fill extensions, MPEG-2 legacy
# signaling, sampling-rate and channel extremes, two raw blocks in a frame,
# and the largest data-stream and fill elements. A file is one to four frames.
#
# TODO:
# * Each frame is a fixed literal, so what varies between files is only which
#   elements appear and in what order.

<start> ::= <aac_file>

<aac_file> ::= <adts_frame>{1,4}

<adts_frame> ::= (
    <end_only_frame>
  | <single_channel_frame>
  | <channel_pair_frame>
  | <coupling_channel_frame>
  | <low_frequency_frame>
  | <data_stream_frame>
  | <program_config_frame>
  | <fill_frame>
  | <main_predictor_frame>
  | <short_window_frame>
  | <tns_frame>
  | <ssr_gain_control_frame>
  | <sbr_extension_frame>
  | <sbr_crc_extension_frame>
  | <dynamic_range_extension_frame>
  | <mpeg2_legacy_frame>
  | <sampling_channel_boundary_frame>
  | <multiple_raw_blocks_frame>
  | <maximum_data_stream_frame>
  | <maximum_fill_frame>
)

# ID_END alone is the smallest legal raw_data_block.  These alternatives also
# exercise AAC Main, LC, and SSR profile signaling without forcing every frame
# to contain a complex individual_channel_stream.
<end_only_frame> ::= (
    b"\xff\xf1\x50\x80\x01\x1f\xfc\xe0"
  | b"\xff\xf1\x10\x80\x01\x1f\xfc\xe0"
  | b"\xff\xf1\x90\x80\x01\x1f\xfc\xe0"
)

# ID_SCE (0): mono LC, long window, max_sfb=0, no optional tools, ID_END.
<single_channel_frame> ::= b"\xff\xf1\x50\x40\x01\x7f\xfc\x00\x00\x00\x07"

# ID_CPE (1): stereo pair with common_window=0 and two bounded silent ICSs.
<channel_pair_frame> ::= b"\xff\xf1\x50\x80\x01\xdf\xfc\x20\x00\x00\x00\x00\x00\x0e"

# ID_CCE (2): an SCE followed by an independently switched coupling element
# targeting tag 0.  Both channel streams have max_sfb=0; gain is unity/default.
<coupling_channel_frame> ::= b"\xff\xf1\x50\x40\x02\x3f\xfc\x00\x00\x00\x02\x08\x04\x00\x00\x00\xe0"

# ID_LFE (3), preceded by a channel_configuration=0 PCE declaring one LFE.
<low_frequency_frame> ::= b"\xff\xf1\x50\x00\x02\x5f\xfc\xa0\xa0\x00\x20\x00\x00\x00\x60\x00\x00\x07"

# ID_DSE (4): byte-aligned ancillary element, tag 0, one data octet, ID_END.
<data_stream_frame> ::= (
    b"\xff\xf1\x50\x80\x01\x7f\xfc\x81\x01\x00\xe0"
  | b"\xff\xf1\x50\x80\x01\x7f\xfc\x81\x01\x7f\xe0"
  | b"\xff\xf1\x50\x80\x01\x7f\xfc\x81\x01\xff\xe0"
)

# ID_PCE (5): LC/44.1 kHz PCE declaring one front CPE, followed by that CPE.
<program_config_frame> ::= b"\xff\xf1\x50\x00\x02\xbf\xfc\xa0\xa0\x80\x00\x04\x00\x00\x20\x00\x00\x00\x00\x00\x0e"

# ID_FIL (6): count=1, EXT_FILL with a nonzero fill nibble, then ID_END.
<fill_frame> ::= b"\xff\xf1\x50\x80\x01\x5f\xfc\xc2\x15\xc0"

# AAC Main predictor_data_present=1 with predictor_reset=0 and max_sfb=0.
<main_predictor_frame> ::= b"\xff\xf1\x10\x40\x01\x9f\xfc\x00\x00\x00\x43\x80"

# Eight-short-window sequence, alternate scale-factor grouping, max_sfb=0.
<short_window_frame> ::= b"\xff\xf1\x50\x40\x01\x9f\xfc\x00\x00\xa1\x54\x70"

# Long-window TNS signaling with n_filt=0.
<tns_frame> ::= b"\xff\xf1\x50\x40\x01\x9f\xfc\x00\x00\x20\x11\xc0"

# SSR profile with gain_control_data_present=1 and max_band=0.
<ssr_gain_control_frame> ::= b"\xff\xf1\x90\x40\x01\x9f\xfc\x00\x00\x20\x09\xc0"

# Fill extensions after an SCE: EXT_SBR_DATA, EXT_SBR_DATA_CRC, and
# EXT_DYNAMIC_RANGE.  Their bounded extension payloads contain no envelopes,
# CRC body, or excluded-channel bands respectively.
<sbr_extension_frame> ::= b"\xff\xf1\x50\x40\x01\xdf\xfc\x00\x00\x00\x06\x2d\x00\x0e"
<sbr_crc_extension_frame> ::= b"\xff\xf1\x50\x40\x01\xdf\xfc\x00\x00\x00\x06\x2e\x00\x0e"
<dynamic_range_extension_frame> ::= b"\xff\xf1\x50\x40\x01\xdf\xfc\x00\x00\x00\x06\x2b\x00\x0e"

# MPEG-2 ID=1 legacy signaling, LC profile, 44.1 kHz stereo.
<mpeg2_legacy_frame> ::= b"\xff\xf9\x50\x80\x01\x1f\xfc\xe0"

# Sampling-frequency/channel extremes: 96 kHz mono and 7.35 kHz config 7.
# The latter also sets private_bit, original/copy, home, and buffer_fullness=0.
<sampling_channel_boundary_frame> ::= (
    b"\xff\xf1\x40\x40\x01\x1f\xfc\xe0"
  | b"\xff\xf1\x73\xf0\x01\x00\x00\xe0"
)

# num_raw_data_blocks_in_frame=1: two byte-aligned ID_END blocks.
<multiple_raw_blocks_frame> ::= b"\xff\xf1\x50\x80\x01\x3f\xfd\xe0\xe0"

# DSE count=255 followed by esc_count=0 and exactly 255 ancillary octets.
# ADTS frame_length is 266 bytes (7-byte header plus 259-byte raw block).
<maximum_data_stream_frame> ::= b"\xff\xf1\x50\x80\x21\x5f\xfc\x81\xff\x00" <dse_255_octets> b"\xe0"
where len(<dse_255_octets>) == 255
<dse_255_octets> ::= b"\x00"{255}

# FIL count=15 and esc_count=255 encode the maximum 269 fill bytes.  Bit
# packing consumes one leading data bit in FE and leaves seven before ID_END.
# ADTS frame_length is 279 bytes.
<maximum_fill_frame> ::= b"\xff\xf1\x50\x80\x22\xff\xfc\xdf\xfe" <fill_268_middle_octets> b"\x01\xc0"
where len(<fill_268_middle_octets>) == 268
<fill_268_middle_octets> ::= b"\x00"{268}
