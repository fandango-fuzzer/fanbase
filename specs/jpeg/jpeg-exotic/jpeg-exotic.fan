# JPEG/JFIF with the unusual parts of the format: 8 and 16 bit quantization
# tables, 8 and 12 bit samples, baseline, extended, progressive, lossless and
# arithmetic frame markers, frames with zero lines (DNL), DAC, restart
# intervals, JFXX thumbnails and progressive scan parameters.
#
# Lengths are checked with where clauses. The DHT segments come from a helper
# so the counts and the symbols stay consistent. Files do not decode.
#
# # TODO:
# * Include these features in `jpeg.fan`

def make_dht(rnd):
    out = []
    for _ in range(rnd.randint(1, 4)):
        tc_th = rnd.choice([0x00, 0x01, 0x02, 0x03, 0x10, 0x11, 0x12, 0x13])
        counts = [0] * 16
        total = rnd.randint(1, 16)
        left = total
        while left > 0:
            i = rnd.randint(0, 15)
            add = rnd.randint(1, left)
            counts[i] += add
            left -= add
        counts = [min(c, 255) for c in counts]
        total = sum(counts)
        symbols = bytes(rnd.randint(0, 255) for _ in range(total))
        out.append(bytes([tc_th]) + bytes(counts) + symbols)
    return b''.join(out)

import random as _random
_R = _random.Random(0xC0FFEE)

<start> ::= <soi> <app0_jfif> <app0_jfxx> <appn> <com> <dqt> <dht> \
            <dac> <dri> <frame_header> <scan> <dnl> <eoi>

# Framing markers
<soi> ::= b'\xff\xd8'
<eoi> ::= b'\xff\xd9'

# APP0 / JFIF
# density units 0 (aspect ratio), 1 (dpi) or 2 (dpcm); embedded RGB thumbnail
# of Xt*Yt pixels (3 bytes each), including 0x0 and tiny ones
<app0_jfif> ::= b'\xff\xe0' <a0_len> b'JFIF\x00' <a0_ver> <a0_units> \
                <a0_xden> <a0_yden> <a0_xt> <a0_yt> <a0_thumb>
where bytes(<app0_jfif>.<a0_len>) == (len(bytes(<app0_jfif>)) - 2).to_bytes(2, 'big')
<a0_ver>   ::= rb'[\x01\x02][\x00-\x02]'
<a0_units> ::= rb'[\x00-\x02]'
<a0_xden>  ::= rb'[\x00\x01][\x00-\xff]'
<a0_yden>  ::= rb'[\x00\x01][\x00-\xff]'
<a0_xt>    ::= rb'[\x00-\x02]'
<a0_yt>    ::= rb'[\x00-\x02]'
# thumbnail RGB data == 3 * Xt * Yt bytes
<a0_thumb> ::= <byte>*
where len(bytes(<app0_jfif>.<a0_thumb>)) == 3 * bytes(<app0_jfif>.<a0_xt>)[0] * bytes(<app0_jfif>.<a0_yt>)[0]

# APP0 / JFXX extension (thumbnail format 0x10 JPEG / 0x11 palette / 0x13 RGB)
<app0_jfxx> ::= b'\xff\xe0' <a0x_len> b'JFXX\x00' <a0x_fmt> <a0x_data>
where bytes(<app0_jfxx>.<a0x_len>) == (len(bytes(<app0_jfxx>)) - 2).to_bytes(2, 'big')
<a0x_fmt>  ::= rb'[\x10\x11\x13]'
<a0x_data> ::= <byte>{0,16}

# APPn (E1..EF): Exif / XMP / ICC family, arbitrary payload
<appn> ::= b'\xff' <appn_marker> <appn_len> <appn_payload>
where bytes(<appn>.<appn_len>) == (len(bytes(<appn>)) - 2).to_bytes(2, 'big')
<appn_marker>  ::= rb'[\xe1-\xef]'
<appn_payload> ::= b'Exif\x00\x00' <byte>{0,24} \
                 | b'http://ns.adobe.com/xap/1.0/\x00' <byte>{0,16} \
                 | b'ICC_PROFILE\x00' <byte>{0,24} \
                 | <byte>{0,32}

# COM comment (may hold embedded NULs / non-text bytes)
<com> ::= b'\xff\xfe' <com_len> <com_data>
where bytes(<com>.<com_len>) == (len(bytes(<com>)) - 2).to_bytes(2, 'big')
<com_data> ::= <byte>{0,32}

<dqt> ::= b'\xff\xdb' <dqt_len> <qt8> <qt16> <qtable>{0,2}
where bytes(<dqt>.<dqt_len>) == (len(bytes(<dqt>)) - 2).to_bytes(2, 'big')
<qtable> ::= <qt8> | <qt16>
<qt8>  ::= rb'[\x00-\x03]' <byte>{64}
<qt16> ::= rb'[\x10-\x13]' <byte>{128}

<dht> ::= b'\xff\xc4' <dht_len> <dht_raw>
where bytes(<dht>.<dht_len>) == (len(bytes(<dht>)) - 2).to_bytes(2, 'big')
<dht_raw> ::= <byte>+ := make_dht(_R)

# DAC: arithmetic conditioning table(s), Tc/Tb byte + Cs byte
<dac> ::= b'\xff\xcc' <dac_len> <dac_pair>{1,4}
where bytes(<dac>.<dac_len>) == (len(bytes(<dac>)) - 2).to_bytes(2, 'big')
<dac_pair> ::= rb'[\x00-\x13]' <byte>

# DRI: restart interval, incl. 0 and large values
<dri> ::= b'\xff\xdd' <dri_len> <dri_ri>
where bytes(<dri>.<dri_len>) == (len(bytes(<dri>)) - 2).to_bytes(2, 'big')
<dri_ri> ::= <byte>{2}

# Frame header (SOF)
# marker covers SOF0/1/2/3 (Huffman) and SOF5-7/9-11/13-15 (differential /
# arithmetic / lossless); precision 8 or 12; Y may be 0 (lines via DNL);
# 1..4 components with H/V sampling 1..4 and a quant-table selector 0..3.
<frame_header> ::= b'\xff' <sof_marker> <sof_len> <sof_prec> <sof_y> <sof_x> \
                   <sof_nf> <sof_comp>{bytes(<frame_header>.<sof_nf>)[0]}
where bytes(<frame_header>.<sof_len>) == (8 + 3 * bytes(<frame_header>.<sof_nf>)[0]).to_bytes(2, 'big')
<sof_marker> ::= rb'[\xc0-\xc3\xc5-\xc7\xc9-\xcb\xcd-\xcf]'
<sof_prec>   ::= rb'[\x08\x0c]'
<sof_y>      ::= b'\x00\x00' | rb'[\x00-\x07][\x00-\xff]'
<sof_x>      ::= rb'[\x00-\x07][\x01-\xff]'
<sof_nf>     ::= rb'[\x01-\x04]'
<sof_comp>   ::= <byte> <samp_factor> rb'[\x00-\x03]'
<samp_factor> ::= rb'[\x11-\x14\x21-\x24\x31-\x34\x41-\x44]'

# Scan (SOS header + byte-stuffed entropy-coded data)
<scan> ::= <sos_header> <entropy>
<sos_header> ::= b'\xff\xda' <sos_len> <sos_ns> \
                 <sos_comp>{bytes(<sos_header>.<sos_ns>)[0]} <sos_ss> <sos_se> <sos_ahal>
where bytes(<sos_header>.<sos_len>) == (6 + 2 * bytes(<sos_header>.<sos_ns>)[0]).to_bytes(2, 'big')
<sos_ns>   ::= rb'[\x01-\x04]'
<sos_comp> ::= <byte> rb'[\x00-\x03\x10-\x13\x20-\x23\x30-\x33]'
<sos_ss>   ::= rb'[\x00-\x3f]'
<sos_se>   ::= rb'[\x00-\x3f]'
<sos_ahal> ::= <byte>

# byte stuffing (FF00) and restart markers RST0..RST7 splitting the stream,
# with at least one restart run so every RSTn shows up
<entropy> ::= <ecs> <rst_run>{1,3}
<ecs>     ::= <ent_byte>{0,48}
<rst_run> ::= <rst_marker> <ecs>
<ent_byte>   ::= rb'[\x00-\xfe]' | b'\xff\x00'
<rst_marker> ::= rb'\xff[\xd0-\xd7]'

# DNL: define number of lines (used when SOF Y == 0)
<dnl> ::= b'\xff\xdc' <dnl_len> <dnl_nl>
where bytes(<dnl>.<dnl_len>) == (len(bytes(<dnl>)) - 2).to_bytes(2, 'big')
<dnl_nl> ::= rb'[\x00-\xff][\x01-\xff]'

# All 2-byte big-endian length fields (values fixed by the `where` clauses above)
<a0_len>   ::= <byte>{2}
<a0x_len>  ::= <byte>{2}
<appn_len> ::= <byte>{2}
<com_len>  ::= <byte>{2}
<dqt_len>  ::= <byte>{2}
<dht_len>  ::= <byte>{2}
<dac_len>  ::= <byte>{2}
<dri_len>  ::= <byte>{2}
<sof_len>  ::= <byte>{2}
<sos_len>  ::= <byte>{2}
<dnl_len>  ::= <byte>{2}

<byte> ::= rb'[\x00-\xff]'
