# JPEG/JFIF at the marker level: SOI, JFIF, other APPn, COM, DQT, DHT, DRI, a
# frame header (SOF0, SOF1 or SOF2, one or three components), SOS, entropy
# coded data with restart markers, EOI.
#
# Every segment shows up in every file and each length field matches its
# payload. Tables and scan data are random bytes, so the files rarely decode.

<start> ::= (
        <soi> <app0> <appn> <com> <dqt> <dht> <dri>
        <frame_header> <scan_header> <entropy_data> <eoi>
    )

# Fixed framing markers
<soi> ::= b'\xff\xd8'
<eoi> ::= b'\xff\xd9'

# APP0 / JFIF
# FFE0, length, "JFIF\0", version(2), density units, Xdensity, Ydensity,
# thumbnail width/height (0 = no embedded thumbnail).
<app0> ::= b'\xff\xe0' <app0_len> <app0_body>
<app0_len> ::= <byte> <byte>
<app0_body> ::= (
        b'JFIF\x00' <byte> <byte> <dens_units>
        <density> <density> b'\x00' b'\x00'
    )
    where bytes(<app0_len>) == (len(bytes(<app0_body>)) + 2).to_bytes(2, 'big')
<dens_units> ::= rb'[\x00-\x02]'
<density> ::= rb'[\x00\x01]' <byte>

# APPn (application-specific, APP1..APP15)
<appn> ::= <appn_marker> <appn_len> <appn_body>
<appn_marker> ::= rb'\xff[\xe1-\xef]'
<appn_len> ::= <byte> <byte>
<appn_body> ::= <byte>{0,32}
    where bytes(<appn_len>) == (len(bytes(<appn_body>)) + 2).to_bytes(2, 'big')

# COM (comment)
<com> ::= b'\xff\xfe' <com_len> <com_body>
<com_len> ::= <byte> <byte>
<com_body> ::= rb'[\x20-\x7e]'{0,48}
    where bytes(<com_len>) == (len(bytes(<com_body>)) + 2).to_bytes(2, 'big')

# DQT (define quantization table)
# One or more tables; each: Pq/Tq byte (precision 0 = 8-bit here, id 0..3)
# followed by 64 quantization coefficients.
<dqt> ::= b'\xff\xdb' <dqt_len> <dqt_body>
<dqt_len> ::= <byte> <byte>
<dqt_body> ::= <qtable>{1,4}
    where bytes(<dqt_len>) == (len(bytes(<dqt_body>)) + 2).to_bytes(2, 'big')
<qtable> ::= <pq_tq> <byte>{64}
<pq_tq> ::= rb'[\x00-\x03]'

<dht> ::= b'\xff\xc4' <dht_len> <dht_body>
<dht_len> ::= <byte> <byte>
<dht_body> ::= <htable>{1,4}
    where bytes(<dht_len>) == (len(bytes(<dht_body>)) + 2).to_bytes(2, 'big')
<htable> ::= <tc_th> <ht_counts> <ht_syms>
<tc_th> ::= rb'[\x00-\x03\x10-\x13]'
<ht_counts> ::= <ht_cnt>{16}
<ht_cnt> ::= rb'[\x00-\x03]'
<ht_syms> ::= <byte>{sum(bytes(<ht_counts>))}

# DRI (define restart interval)
<dri> ::= b'\xff\xdd' <dri_len> <dri_body>
<dri_len> ::= <byte> <byte>
<dri_body> ::= <byte> <byte>
    where bytes(<dri_len>) == (len(bytes(<dri_body>)) + 2).to_bytes(2, 'big')

# SOFn (frame header)
# SOF0 baseline / SOF1 extended-sequential / SOF2 progressive.
# length = 8 + 3*Nf. Precision 8. Non-zero, modest dimensions.
# Explicit 1-component (grayscale) and 3-component (YCbCr) branches carry the
# component count byte and matching length literally.
<frame_header> ::= <sof_marker> <sof_body>
<sof_marker> ::= rb'\xff[\xc0-\xc2]'
<sof_body> ::= <sof_gray> | <sof_ycc>
<sof_gray> ::= (
        b'\x00\x0b' b'\x08' <dim> <dim> b'\x01' <frame_comp>
    )
<sof_ycc> ::= (
        b'\x00\x11' b'\x08' <dim> <dim> b'\x03'
        <frame_comp> <frame_comp> <frame_comp>
    )
<dim> ::= rb'[\x00-\x07]' rb'[\x01-\xff]'
<frame_comp> ::= <byte> <sampling> <qt_sel>
<sampling> ::= rb'[\x11-\x14\x21-\x24\x31-\x34\x41-\x44]'
<qt_sel> ::= rb'[\x00-\x03]'

# SOS (scan header)
# length = 6 + 2*Ns; component selector + DC/AC Huffman table selector per
# component; spectral selection start/end + successive approximation.
<scan_header> ::= b'\xff\xda' <sos_body>
<sos_body> ::= <sos_gray> | <sos_ycc>
<sos_gray> ::= (
        b'\x00\x08' b'\x01' <scan_comp> <spectral>
    )
<sos_ycc> ::= (
        b'\x00\x0c' b'\x03' <scan_comp> <scan_comp> <scan_comp> <spectral>
    )
<scan_comp> ::= <byte> <td_ta>
<td_ta> ::= rb'[\x00-\x03\x10-\x13\x20-\x23\x30-\x33]'
<spectral> ::= b'\x00' b'\x3f' b'\x00'

# Entropy-coded data
# Byte-stuffed scan data: any non-FF byte, a stuffed FF (FF 00), or an RSTn
# restart marker (FF D0..FF D7). At least one restart chunk guarantees RSTn
# coverage.
<entropy_data> ::= <ecs> <restart_chunk>{1,3}
<ecs> ::= <entropy_byte>{0,96}
<restart_chunk> ::= <rst> <entropy_byte>{0,32}
<entropy_byte> ::= rb'[\x00-\xfe]' | b'\xff\x00' | rb'\xff[\xd0-\xd7]'
<rst> ::= rb'\xff[\xd0-\xd7]'

<byte> ::= rb'[\x00-\xff]'
