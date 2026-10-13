# A PPM image followed by zero or more further images concatenated in the
# same file, covering maxval's full 1..65535 range: "limited" branches use
# black samples valid at any maxval, "full" branches use maxval 255 or
# 65535 and the whole sample range. Dimensions are capped at 1..9 to keep
# generation fast; the representation and size equations are the real
# format's.

<start> ::= <ppm_image> <tail_image>*

<ppm_image> ::= (
    <plain_limited_image> | <plain_full_image> | \
    <raw8_limited_image> | <raw8_full_image> | \
    <raw16_limited_image> | <raw16_full_image>
)

# P3 / plain PPM.  Zero-padded samples are legal decimal tokens.  One pixel
# per line gives 18-character raster lines, satisfying the 70-character plain
# PPM line recommendation.
<plain_limited_image> ::= (
    b'P3' <header_sep> <plain_limited_width> <header_sep> \
    <plain_limited_height> <header_sep> <plain_limited_maxval> \
    <line_end> <plain_limited_raster>
)
<plain_limited_width> ::= br'[1-9]'
<plain_limited_height> ::= br'[1-9]'
<plain_limited_maxval> ::= br'[0-9]{1,5}'
<plain_limited_raster> ::= <plain_black_pixel>+

<plain_full_image> ::= (
    b'P3' <header_sep> <plain_full_width> <header_sep> \
    <plain_full_height> <header_sep> <plain_full_maxval> \
    <line_end> <plain_full_raster>
)
<plain_full_width> ::= br'[1-9]'
<plain_full_height> ::= br'[1-9]'
<plain_full_maxval> ::= b'65535'
<plain_full_raster> ::= <plain_full_pixel>+

<plain_black_pixel> ::= <plain_zero_sample> b' ' <plain_zero_sample> b' ' <plain_zero_sample> b'\n'
<plain_full_pixel> ::= <plain_full_sample> b' ' <plain_full_sample> b' ' <plain_full_sample> b'\n'
<plain_zero_sample> ::= b'00000'
<plain_full_sample> ::= br'(?:[0-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])'

# P6 / raw PPM with one-byte samples.
<raw8_limited_image> ::= (
    b'P6' <header_sep> <raw8_limited_width> <header_sep> \
    <raw8_limited_height> <header_sep> <raw8_limited_maxval> \
    <raw_delimiter> <raw8_limited_raster>
)
<raw8_limited_width> ::= br'[1-9]'
<raw8_limited_height> ::= br'[1-9]'
<raw8_limited_maxval> ::= br'[0-9]{1,3}'
<raw8_limited_raster> ::= <raw8_zero_sample>+

<raw8_full_image> ::= (
    b'P6' <header_sep> <raw8_full_width> <header_sep> \
    <raw8_full_height> <header_sep> <raw8_full_maxval> \
    <raw_delimiter> <raw8_full_raster>
)
<raw8_full_width> ::= br'[1-9]'
<raw8_full_height> ::= br'[1-9]'
<raw8_full_maxval> ::= b'255'
<raw8_full_raster> ::= <raw8_full_sample>+
<raw8_zero_sample> ::= b'\x00'
<raw8_full_sample> ::= br'[\x00-\xff]'

# P6 / raw PPM with unsigned, big-endian two-byte samples.
<raw16_limited_image> ::= (
    b'P6' <header_sep> <raw16_limited_width> <header_sep> \
    <raw16_limited_height> <header_sep> <raw16_limited_maxval> \
    <raw_delimiter> <raw16_limited_raster>
)
<raw16_limited_width> ::= br'[1-9]'
<raw16_limited_height> ::= br'[1-9]'
<raw16_limited_maxval> ::= br'[0-9]{1,5}'
<raw16_limited_raster> ::= <raw16_zero_sample>+

<raw16_full_image> ::= (
    b'P6' <header_sep> <raw16_full_width> <header_sep> \
    <raw16_full_height> <header_sep> <raw16_full_maxval> \
    <raw_delimiter> <raw16_full_raster>
)
<raw16_full_width> ::= br'[1-9]'
<raw16_full_height> ::= br'[1-9]'
<raw16_full_maxval> ::= b'65535'
<raw16_full_raster> ::= <raw16_full_sample>+
<raw16_zero_sample> ::= b'\x00\x00'
<raw16_full_sample> ::= br'[\x00-\xff]{2}'

# A PPM file may contain a sequence of images with no inter-image separator.
# Tail productions are self-contained 1x1 images and may freely mix P3, 8-bit
# P6, and 16-bit P6 encodings; their endpoint maxvals admit every sample value.
<tail_image> ::= <tail_plain_image> | <tail_raw8_image> | <tail_raw16_image>
<tail_plain_image> ::= b'P3\n1 1\n65535\n' <tail_plain_pixel>
<tail_plain_pixel> ::= <tail_plain_sample> b' ' <tail_plain_sample> b' ' <tail_plain_sample> b'\n'
<tail_plain_sample> ::= br'(?:[0-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])'
<tail_raw8_image> ::= b'P6\n1 1\n255\n' <tail_raw8_sample>{3}
<tail_raw8_sample> ::= br'[\x00-\xff]'
<tail_raw16_image> ::= b'P6\n1 1\n65535\n' <tail_raw16_sample>{3}
<tail_raw16_sample> ::= br'[\x00-\xff]{2}'

# Header tokens may be separated by any Netpbm whitespace or by a # comment.
# A comment consumes its CR, LF, or CRLF terminator.
<header_sep> ::= <horizontal_sep> | <vertical_sep> | <comment_sep>
<horizontal_sep> ::= br'[ \t]{1,4}' | b'\x0b' | b'\x0c'
<vertical_sep> ::= <line_end>
<comment_sep> ::= br'[ \t]{0,4}' b'#' br'[\x20-\x7e]{0,48}' <line_end>
<line_end> ::= b'\n' | b'\r' | b'\r\n'

# After a P6 maxval, exactly one whitespace byte ends the header.  The next
# byte is raster data even when it happens to be '#'.
<raw_delimiter> ::= b' ' | b'\t' | b'\n' | b'\r' | b'\x0b' | b'\x0c'

# Width, height, and maxval ranges.
where 1 <= int(<plain_limited_width>) <= 9
where 1 <= int(<plain_limited_height>) <= 9
where 1 <= int(<plain_limited_maxval>) <= 65534
where 1 <= int(<plain_full_width>) <= 9
where 1 <= int(<plain_full_height>) <= 9
where int(<plain_full_maxval>) == 65535
where 1 <= int(<raw8_limited_width>) <= 9
where 1 <= int(<raw8_limited_height>) <= 9
where 1 <= int(<raw8_limited_maxval>) <= 254
where 1 <= int(<raw8_full_width>) <= 9
where 1 <= int(<raw8_full_height>) <= 9
where int(<raw8_full_maxval>) == 255
where 1 <= int(<raw16_limited_width>) <= 9
where 1 <= int(<raw16_limited_height>) <= 9
where 256 <= int(<raw16_limited_maxval>) <= 65534
where 1 <= int(<raw16_full_width>) <= 9
where 1 <= int(<raw16_full_height>) <= 9
where int(<raw16_full_maxval>) == 65535

# Exact cross-field raster sizes: three RGB samples per pixel, with one or two
# bytes per raw sample.  Each P3 pixel line is exactly 18 bytes.
where len(bytes(<plain_limited_raster>)) == int(<plain_limited_width>) * int(<plain_limited_height>) * 18
where len(bytes(<plain_full_raster>)) == int(<plain_full_width>) * int(<plain_full_height>) * 18
where len(bytes(<raw8_limited_raster>)) == int(<raw8_limited_width>) * int(<raw8_limited_height>) * 3
where len(bytes(<raw8_full_raster>)) == int(<raw8_full_width>) * int(<raw8_full_height>) * 3
where len(bytes(<raw16_limited_raster>)) == int(<raw16_limited_width>) * int(<raw16_limited_height>) * 6
where len(bytes(<raw16_full_raster>)) == int(<raw16_full_width>) * int(<raw16_full_height>) * 6

# Sample/maxval relationships.  The limited branches are black by grammar;
# full branches use regexes spanning exactly their complete storage range.
where int(<plain_zero_sample>) == 0
where int(<plain_zero_sample>) <= int(<plain_limited_maxval>)
where 0 <= int(<plain_full_sample>) <= int(<plain_full_maxval>)
where ord(bytes(<raw8_zero_sample>)) == 0
where ord(bytes(<raw8_zero_sample>)) <= int(<raw8_limited_maxval>)
where 0 <= ord(bytes(<raw8_full_sample>)) <= int(<raw8_full_maxval>)
where int.from_bytes(bytes(<raw16_zero_sample>), 'big') == 0
where int.from_bytes(bytes(<raw16_zero_sample>), 'big') <= int(<raw16_limited_maxval>)
where 0 <= int.from_bytes(bytes(<raw16_full_sample>), 'big') <= int(<raw16_full_maxval>)
