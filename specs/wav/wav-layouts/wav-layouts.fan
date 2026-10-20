# Eight complete WAVE files with every size written out: plain PCM, an
# empty data chunk with 32639 channels, a very high sample rate, 6-channel
# 24-bit, the metadata chunks (JUNK, cue, plst, smpl, inst, LIST/INFO,
# LIST/adtl, DISP), Broadcast Wave (bext), an adtl list nested in INFO,
# and a wavl list with a slnt chunk. Only the samples and a few text bytes
# vary.
#
# TODO:
# * Sizes, rates and counts only use bytes below 0x80, so several sample
#   rates are not real ones (0x01010101 Hz, 0x0f0f0f0f Hz). Write them as
#   bytes (b"...") with their real values.

<start> ::= <wave_base> | <wave_empty> | <wave_high_rate> | <wave_surround> | <wave_metadata> | <wave_broadcast> | <wave_nested> | <wave_wavl>
<wave_base> ::= "RIFF" "\x34\x00\x00\x00" "WAVE" <body_base>
<wave_empty> ::= "RIFF" "\x24\x00\x00\x00" "WAVE" <body_empty>
<wave_high_rate> ::= "RIFF" "\x2c\x00\x00\x00" "WAVE" <body_high_rate>
<wave_surround> ::= "RIFF" "\x36\x00\x00\x00" "WAVE" <body_surround>
<wave_metadata> ::= "RIFF" "\x32\x01\x00\x00" "WAVE" <body_metadata>
<wave_broadcast> ::= "RIFF" "\x00\x03\x00\x00" "WAVE" <body_broadcast>
<wave_nested> ::= "RIFF" "\x5c\x00\x00\x00" "WAVE" <body_nested>
<wave_wavl> ::= "RIFF" "\x50\x00\x00\x00" "WAVE" <body_wavl>
<body_base> ::= <fmt_base> <data_16>
<body_empty> ::= <fmt_max_channels> <data_empty>
<body_high_rate> ::= <fmt_high_rate> <data_8>
<body_surround> ::= <fmt_surround_24> <data_18>
<body_metadata> ::= <fmt_base> <junk_chunk> <cue_chunk> <playlist_chunk> <sampler_chunk> <instrument_chunk> <info_list> <associated_data_list> <display_chunk> <data_16>
<body_broadcast> ::= <fmt_base> <bext_chunk> <broadcast_pad> <data_16>
<body_nested> ::= <fmt_base> <nested_list> <data_16>
<body_wavl> ::= <fmt_base> <wavl_list>

# fmt: five 16-byte PCM layouts, field by field
<fmt_base> ::= "fmt " <fmt_size_16> <pcm_fields_base>
where len(<pcm_fields_base>) == 16
<fmt_size_16> ::= "\x10\x00\x00\x00"
<pcm_fields_base> ::= <pcm_mono_8> | <pcm_mono_16> | <pcm_stereo_16> | <pcm_stereo_32> | <pcm_octagonal_16>

<pcm_mono_8> ::= <tag_pcm_1> <ch_mono_1> <rate_8000_1> <avg_8000_1> <align_1_1> <bits_8_1>
<tag_pcm_1> ::= "\x01\x00"
<ch_mono_1> ::= "\x01\x00"
<rate_8000_1> ::= "\x40\x1f\x00\x00"
<avg_8000_1> ::= "\x40\x1f\x00\x00"
<align_1_1> ::= "\x01\x00"
<bits_8_1> ::= "\x08\x00"

<pcm_mono_16> ::= <tag_pcm_2> <ch_mono_2> <rate_11025_2> <avg_22050_2> <align_2_2> <bits_16_2>
<tag_pcm_2> ::= "\x01\x00"
<ch_mono_2> ::= "\x01\x00"
<rate_11025_2> ::= "\x11\x2b\x00\x00"
<avg_22050_2> ::= "\x22\x56\x00\x00"
<align_2_2> ::= "\x02\x00"
<bits_16_2> ::= "\x10\x00"

<pcm_stereo_16> ::= <tag_pcm_3> <ch_stereo_3> <rate_44100_3> <avg_176400_3> <align_4_3> <bits_16_3>
<tag_pcm_3> ::= "\x01\x00"
<ch_stereo_3> ::= "\x02\x00"
<rate_44100_3> ::= "\x40\x1f\x00\x00"
<avg_176400_3> ::= "\x00\x7d\x00\x00"
<align_4_3> ::= "\x04\x00"
<bits_16_3> ::= "\x10\x00"

<pcm_stereo_32> ::= <tag_pcm_4> <ch_stereo_4> <rate_192000_4> <avg_1536000_4> <align_8_4> <bits_32_4>
<tag_pcm_4> ::= "\x01\x00"
<ch_stereo_4> ::= "\x02\x00"
<rate_192000_4> ::= "\x01\x01\x01\x01"
<avg_1536000_4> ::= "\x08\x08\x08\x08"
<align_8_4> ::= "\x08\x00"
<bits_32_4> ::= "\x20\x00"

<pcm_octagonal_16> ::= <tag_pcm_5> <ch_eight_5> <rate_48000_5> <avg_768000_5> <align_16_5> <bits_16_5>
<tag_pcm_5> ::= "\x01\x00"
<ch_eight_5> ::= "\x08\x00"
<rate_48000_5> ::= "\x01\x01\x01\x01"
<avg_768000_5> ::= "\x10\x10\x10\x10"
<align_16_5> ::= "\x10\x00"
<bits_16_5> ::= "\x10\x00"

# 32639 channels at 1 Hz
<fmt_max_channels> ::= "fmt " <fmt_size_16_max> <pcm_max_channels>
<fmt_size_16_max> ::= "\x10\x00\x00\x00"
<pcm_max_channels> ::= "\x01\x00" <max_channels> <rate_one> <avg_65535> <align_65535> <bits_eight_max>
<max_channels> ::= "\x7f\x7f"
<rate_one> ::= "\x01\x00\x00\x00"
<avg_65535> ::= "\x7f\x7f\x00\x00"
<align_65535> ::= "\x7f\x7f"
<bits_eight_max> ::= "\x08\x00"

# Stereo, 32 bits, at a very high sample rate
<fmt_high_rate> ::= "fmt " <fmt_size_16_high> <pcm_high_rate_fields>
<fmt_size_16_high> ::= "\x10\x00\x00\x00"
<pcm_high_rate_fields> ::= "\x01\x00" "\x02\x00" <rate_high> <avg_high> <align_high> "\x20\x00"
<rate_high> ::= "\x0f\x0f\x0f\x0f"
<avg_high> ::= "\x78\x78\x78\x78"
<align_high> ::= "\x08\x00"

<fmt_surround_24> ::= "fmt " <fmt_size_16_surround> <pcm_surround_fields>
<fmt_size_16_surround> ::= "\x10\x00\x00\x00"
<pcm_surround_fields> ::= "\x01\x00" "\x06\x00" <rate_surround> <avg_surround> <align_surround> "\x18\x00"
<rate_surround> ::= "\x01\x01\x01\x01"
<avg_surround> ::= "\x12\x12\x12\x12"
<align_surround> ::= "\x12\x00"

# Audio data chunks. Odd payloads carry the mandatory RIFF pad byte, which is
# excluded from the stored chunk size.
<data_empty> ::= "data" <data_size_0> <payload_0>
<data_size_0> ::= "\x00\x00\x00\x00"
<payload_0> ::= ""
<data_4> ::= "data" <data_size_4> <payload_4>
<data_size_4> ::= "\x04\x00\x00\x00"
<payload_4> ::= r'[\x00-\x7f]{4}'
<data_8> ::= "data" <data_size_8> <payload_8>
<data_size_8> ::= "\x08\x00\x00\x00"
<payload_8> ::= r'[\x00-\x7f]{8}'
<data_16> ::= "data" <data_size_16> <payload_16>
where len(<payload_16>) == 16
<data_size_16> ::= "\x10\x00\x00\x00"
<payload_16> ::= r'[\x00-\x7f]{16}'
<data_18> ::= "data" <data_size_18> <payload_18>
<data_size_18> ::= "\x12\x00\x00\x00"
<payload_18> ::= r'[\x00-\x7f]{18}'

<junk_chunk> ::= "JUNK" <junk_size> <junk_payload> <junk_pad>
where len(<junk_payload>) == 3 and len(<junk_pad>) == len(<junk_payload>) % 2
<junk_size> ::= "\x03\x00\x00\x00"
<junk_payload> ::= r'[\x00-\x7f]{3}'
<junk_pad> ::= "\x00"

<cue_chunk> ::= "cue " <cue_size> <cue_count> <cue_point>
<cue_size> ::= "\x1c\x00\x00\x00"
<cue_count> ::= "\x01\x00\x00\x00"
<cue_point> ::= "\x01\x00\x00\x00" "\x00\x00\x00\x00" "data" "\x00\x00\x00\x00" "\x00\x00\x00\x00" "\x00\x00\x00\x00"

<playlist_chunk> ::= "plst" <playlist_size> <playlist_count> <playlist_segment>
<playlist_size> ::= "\x10\x00\x00\x00"
<playlist_count> ::= "\x01\x00\x00\x00"
<playlist_segment> ::= "\x01\x00\x00\x00" "\x00\x00\x00\x00" "\x01\x00\x00\x00"

<sampler_chunk> ::= "smpl" <sampler_size> <sampler_header> <sampler_loop>
<sampler_size> ::= "\x3c\x00\x00\x00"
<sampler_header> ::= "\x00\x00\x00\x00" "\x00\x00\x00\x00" "\x3c\x00\x00\x00" "\x3c\x00\x00\x00" "\x00\x00\x00\x00" "\x00\x00\x00\x00" "\x00\x00\x00\x00" "\x01\x00\x00\x00" "\x00\x00\x00\x00"
<sampler_loop> ::= "\x01\x00\x00\x00" "\x00\x00\x00\x00" "\x00\x00\x00\x00" "\x03\x00\x00\x00" "\x00\x00\x00\x00" "\x00\x00\x00\x00"

<instrument_chunk> ::= "inst" <instrument_size> <instrument_payload> "\x00"
<instrument_size> ::= "\x07\x00\x00\x00"
<instrument_payload> ::= "\x3c\x00\x00\x00\x7f\x00\x7f"

<info_list> ::= "LIST" <info_list_size> <info_list_payload>
<info_list_size> ::= "\x1c\x00\x00\x00"
<info_list_payload> ::= "INFO" <info_name> <info_artist>
<info_name> ::= "INAM" "\x04\x00\x00\x00" "Fan\x00"
<info_artist> ::= "IART" "\x04\x00\x00\x00" "Ana\x00"

<associated_data_list> ::= "LIST" <adtl_size> <adtl_payload>
<adtl_size> ::= "\x24\x00\x00\x00"
<adtl_payload> ::= "adtl" <label_chunk> <note_chunk>
<label_chunk> ::= "labl" "\x08\x00\x00\x00" "\x01\x00\x00\x00" "A\x00\x00\x00"
<note_chunk> ::= "note" "\x08\x00\x00\x00" "\x01\x00\x00\x00" "N\x00\x00\x00"

<display_chunk> ::= "DISP" <display_size> <display_payload> "\x00"
<display_size> ::= "\x09\x00\x00\x00"
<display_payload> ::= "\x01\x00\x00\x00" "Wave\x00"

# bext, version 1: the 602-byte fixed part
<bext_chunk> ::= "bext" <bext_size> <bext_payload>
<bext_size> ::= "\x5a\x02\x00\x00"
<bext_payload> ::= <bext_description> <bext_originator> <bext_originator_ref> <bext_date> <bext_time> <bext_time_reference> <bext_version> <bext_umid> <bext_reserved>
<bext_description> ::= "Fandango PCM WAVE" r'\x00{238}'
<bext_originator> ::= "Studio" r'\x00{26}'
<bext_originator_ref> ::= "FAN-PCM" r'\x00{25}'
<bext_date> ::= "2026-08-05"
<bext_time> ::= "12:00:00"
<bext_time_reference> ::= r'\x00{8}'
<bext_version> ::= "\x01\x00"
<bext_umid> ::= r'\x00{64}'
<bext_reserved> ::= r'\x00{190}'

# JUNK, so that the RIFF size of this layout is 0x300
<broadcast_pad> ::= "JUNK" "\x62\x00\x00\x00" r'\x00{98}'

# An INFO list with an adtl list inside it
<nested_list> ::= "LIST" <nested_outer_size> <nested_outer_payload>
<nested_outer_size> ::= "\x20\x00\x00\x00"
<nested_outer_payload> ::= "INFO" <nested_inner_list>
<nested_inner_list> ::= "LIST" <nested_inner_size> <nested_inner_payload>
<nested_inner_size> ::= "\x14\x00\x00\x00"
<nested_inner_payload> ::= "adtl" <label_chunk>

# wavl: two data chunks with a slnt (silence) chunk between them
<wavl_list> ::= "LIST" <wavl_size> <wavl_payload>
<wavl_size> ::= "\x2c\x00\x00\x00"
<wavl_payload> ::= "wavl" <data_8> <silence_chunk> <data_4>
<silence_chunk> ::= "slnt" <silence_size> <silence_samples>
<silence_size> ::= "\x04\x00\x00\x00"
<silence_samples> ::= "\x04\x00\x00\x00"
