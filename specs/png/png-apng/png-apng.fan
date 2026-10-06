# Animated PNG: an indexed 1x1 image with acTL, two fcTL, IDAT and fdAT, plus
# the colour, palette, text, time and physical size chunks that can go with
# it. Every file is an APNG. Lengths and CRCs are checked with where clauses.
#
# TODO:
# * Built from sample APNG files, so not as variable as it could be
# * Constraints are applied on constant strings and thus trivially true
# * Replace constant strings with computed values.

import zlib

<start> ::= <png>
<png> ::= <signature><ihdr><chrm><gama><cicp><mdcv><clli><plte><hist><trns><bkgd><sbit><phys><scal><pcal><splt><iccp><text><private_nonce><ztxt><itxt><time><exif><actl><fctl0><idat><fctl1><fdat><iend><dsig>

<signature> ::= b"\x89PNG\r\n\x1a\n"

# Critical header: 1 x 1, indexed 8-bit image; all PNG method enums are 0.
<ihdr> ::= <ihdr_length>b"IHDR"<ihdr_data><ihdr_crc>
<ihdr_length> ::= b"\x00\x00\x00\x0d"
<ihdr_data> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x08\x03\x00\x00\x00"
<ihdr_crc> ::= b"\x28\xcb\x34\xbb"
where len(bytes(<ihdr_data>)) == 13 and bytes(<ihdr_length>) == len(bytes(<ihdr_data>)).to_bytes(4, "big")
where int.from_bytes(bytes(<ihdr_data>)[0:4], "big") > 0 and int.from_bytes(bytes(<ihdr_data>)[4:8], "big") > 0
where bytes(<ihdr_data>)[8] in (1, 2, 4, 8, 16) and bytes(<ihdr_data>)[9] in (0, 2, 3, 4, 6)
where bytes(<ihdr_data>)[10:12] == b"\x00\x00" and bytes(<ihdr_data>)[12] in (0, 1)
where bytes(<ihdr_crc>) == (zlib.crc32(b"IHDR" + bytes(<ihdr_data>)) & 0xffffffff).to_bytes(4, "big")

# Colour-space and HDR signalling chunks.
<chrm> ::= <chrm_length>b"cHRM"<chrm_data><chrm_crc>
<chrm_length> ::= b"\x00\x00\x00\x20"
<chrm_data> ::= b"\x00\x00\x7a\x26\x00\x00\x80\x84\x00\x00\xfa\x00\x00\x00\x80\xe8\x00\x00\x75\x30\x00\x00\xea\x60\x00\x00\x3a\x98\x00\x00\x17\x70"
<chrm_crc> ::= b"\x9c\xba\x51\x3c"
where len(bytes(<chrm_data>)) == 32 and bytes(<chrm_length>) == len(bytes(<chrm_data>)).to_bytes(4, "big")
where bytes(<chrm_crc>) == (zlib.crc32(b"cHRM" + bytes(<chrm_data>)) & 0xffffffff).to_bytes(4, "big")

<gama> ::= <gama_length>b"gAMA"<gama_data><gama_crc>
<gama_length> ::= b"\x00\x00\x00\x04"
<gama_data> ::= b"\x00\x00\xb1\x8f"
<gama_crc> ::= b"\x0b\xfc\x61\x05"
where len(bytes(<gama_data>)) == 4 and int.from_bytes(bytes(<gama_data>), "big") > 0 and bytes(<gama_length>) == len(bytes(<gama_data>)).to_bytes(4, "big")
where bytes(<gama_crc>) == (zlib.crc32(b"gAMA" + bytes(<gama_data>)) & 0xffffffff).to_bytes(4, "big")

# Defined independently for complete PNG coverage; sRGB and iCCP are mutually exclusive.
<srgb> ::= <srgb_length>b"sRGB"<srgb_data><srgb_crc>
<srgb_length> ::= b"\x00\x00\x00\x01"
<srgb_data> ::= b"\x00"
<srgb_crc> ::= b"\xae\xce\x1c\xe9"

<cicp> ::= <cicp_length>b"cICP"<cicp_data><cicp_crc>
<cicp_length> ::= b"\x00\x00\x00\x04"
<cicp_data> ::= b"\x01\x0d\x00\x01"
<cicp_crc> ::= b"\x9c\x69\x3b\x32"
where len(bytes(<cicp_data>)) == 4 and bytes(<cicp_data>)[3] in (0, 1) and bytes(<cicp_length>) == len(bytes(<cicp_data>)).to_bytes(4, "big")
where bytes(<cicp_crc>) == (zlib.crc32(b"cICP" + bytes(<cicp_data>)) & 0xffffffff).to_bytes(4, "big")

<mdcv> ::= <mdcv_length>b"mDCv"<mdcv_data><mdcv_crc>
<mdcv_length> ::= b"\x00\x00\x00\x18"
<mdcv_data> ::= b"\x8a\x48\x39\x08\x21\x34\x9b\x96\x19\xfc\x08\xfc\x3d\x13\x40\x42\x00\x98\x96\x80\x00\x00\x00\x01"
<mdcv_crc> ::= b"\xa6\xa9\xd4\x21"
where len(bytes(<mdcv_data>)) == 24 and bytes(<mdcv_length>) == len(bytes(<mdcv_data>)).to_bytes(4, "big")
where bytes(<mdcv_crc>) == (zlib.crc32(b"mDCv" + bytes(<mdcv_data>)) & 0xffffffff).to_bytes(4, "big")

<clli> ::= <clli_length>b"cLLi"<clli_data><clli_crc>
<clli_length> ::= b"\x00\x00\x00\x04"
<clli_data> ::= b"\x03\xe8\x01\x90"
<clli_crc> ::= b"\x08\x05\x34\xe4"
where len(bytes(<clli_data>)) == 4 and int.from_bytes(bytes(<clli_data>)[0:2], "big") >= int.from_bytes(bytes(<clli_data>)[2:4], "big") and bytes(<clli_length>) == len(bytes(<clli_data>)).to_bytes(4, "big")
where bytes(<clli_crc>) == (zlib.crc32(b"cLLi" + bytes(<clli_data>)) & 0xffffffff).to_bytes(4, "big")

# Indexed-colour palette, histogram, transparency, background, and significant bits.
<plte> ::= <plte_length>b"PLTE"<plte_data><plte_crc>
<plte_length> ::= b"\x00\x00\x00\x03"
<plte_data> ::= b"\x80\x40\x20"
<plte_crc> ::= b"\x8d\x58\x49\x97"
where 3 <= len(bytes(<plte_data>)) <= 768 and len(bytes(<plte_data>)) % 3 == 0 and bytes(<plte_length>) == len(bytes(<plte_data>)).to_bytes(4, "big")
where bytes(<plte_crc>) == (zlib.crc32(b"PLTE" + bytes(<plte_data>)) & 0xffffffff).to_bytes(4, "big")

<hist> ::= <hist_length>b"hIST"<hist_data><hist_crc>
<hist_length> ::= b"\x00\x00\x00\x02"
<hist_data> ::= b"\x00\x01"
<hist_crc> ::= b"\xc5\x8c\x00\x1a"
where len(bytes(<hist_data>)) == 2 * (len(bytes(<plte_data>)) // 3) and bytes(<hist_length>) == len(bytes(<hist_data>)).to_bytes(4, "big")
where bytes(<hist_crc>) == (zlib.crc32(b"hIST" + bytes(<hist_data>)) & 0xffffffff).to_bytes(4, "big")

<trns> ::= <trns_length>b"tRNS"<trns_data><trns_crc>
<trns_length> ::= b"\x00\x00\x00\x01"
<trns_data> ::= b"\xff"
<trns_crc> ::= b"\x6d\xe4\x37\xeb"
where bytes(<ihdr_data>)[9] == 3 and 1 <= len(bytes(<trns_data>)) <= len(bytes(<plte_data>)) // 3 and bytes(<trns_length>) == len(bytes(<trns_data>)).to_bytes(4, "big")
where bytes(<trns_crc>) == (zlib.crc32(b"tRNS" + bytes(<trns_data>)) & 0xffffffff).to_bytes(4, "big")

<bkgd> ::= <bkgd_length>b"bKGD"<bkgd_data><bkgd_crc>
<bkgd_length> ::= b"\x00\x00\x00\x01"
<bkgd_data> ::= b"\x00"
<bkgd_crc> ::= b"\x88\x05\x1d\x48"
where bytes(<ihdr_data>)[9] == 3 and len(bytes(<bkgd_data>)) == 1 and bytes(<bkgd_data>)[0] < len(bytes(<plte_data>)) // 3 and bytes(<bkgd_length>) == len(bytes(<bkgd_data>)).to_bytes(4, "big")
where bytes(<bkgd_crc>) == (zlib.crc32(b"bKGD" + bytes(<bkgd_data>)) & 0xffffffff).to_bytes(4, "big")

<sbit> ::= <sbit_length>b"sBIT"<sbit_data><sbit_crc>
<sbit_length> ::= b"\x00\x00\x00\x01"
<sbit_data> ::= b"\x08"
<sbit_crc> ::= b"\xe6\x0a\x5b\x99"
where bytes(<ihdr_data>)[9] == 3 and len(bytes(<sbit_data>)) == 1 and 1 <= bytes(<sbit_data>)[0] <= bytes(<ihdr_data>)[8] and bytes(<sbit_length>) == len(bytes(<sbit_data>)).to_bytes(4, "big")
where bytes(<sbit_crc>) == (zlib.crc32(b"sBIT" + bytes(<sbit_data>)) & 0xffffffff).to_bytes(4, "big")

# Physical dimensions, scale, calibration, and suggested palette.
<phys> ::= <phys_length>b"pHYs"<phys_data><phys_crc>
<phys_length> ::= b"\x00\x00\x00\x09"
<phys_data> ::= b"\x00\x00\x0e\xc4\x00\x00\x0e\xc4\x01"
<phys_crc> ::= b"\x95\x2b\x0e\x1b"
where len(bytes(<phys_data>)) == 9 and bytes(<phys_data>)[8] in (0, 1) and bytes(<phys_length>) == len(bytes(<phys_data>)).to_bytes(4, "big")
where bytes(<phys_crc>) == (zlib.crc32(b"pHYs" + bytes(<phys_data>)) & 0xffffffff).to_bytes(4, "big")

<scal> ::= <scal_length>b"sCAL"<scal_data><scal_crc>
<scal_length> ::= b"\x00\x00\x00\x08"
<scal_data> ::= b"\x01" b"1.0\x00" b"1.0"
<scal_crc> ::= b"\x78\x3b\xb2\x97"
where bytes(<scal_data>)[0] in (1, 2) and bytes(<scal_data>)[1:].count(b"\x00") == 1 and bytes(<scal_length>) == len(bytes(<scal_data>)).to_bytes(4, "big")
where bytes(<scal_crc>) == (zlib.crc32(b"sCAL" + bytes(<scal_data>)) & 0xffffffff).to_bytes(4, "big")

<pcal> ::= <pcal_length>b"pCAL"<pcal_data><pcal_crc>
<pcal_length> ::= b"\x00\x00\x00\x13"
<pcal_data> ::= b"cal\x00" b"\x00\x00\x00\x00" b"\x00\x00\x00\x01" b"\x00\x02" b"u\x00" b"0\x00" b"1"
<pcal_crc> ::= b"\xe9\x65\x1c\x4e"
where bytes(<pcal_data>).split(b"\x00", 1)[0] == b"cal" and int.from_bytes(bytes(<pcal_data>)[4:8], "big", signed=True) < int.from_bytes(bytes(<pcal_data>)[8:12], "big", signed=True)
where bytes(<pcal_data>)[12] in (0, 1, 2, 3) and bytes(<pcal_data>)[13] == 2 and bytes(<pcal_length>) == len(bytes(<pcal_data>)).to_bytes(4, "big")
where bytes(<pcal_crc>) == (zlib.crc32(b"pCAL" + bytes(<pcal_data>)) & 0xffffffff).to_bytes(4, "big")

<splt> ::= <splt_length>b"sPLT"<splt_data><splt_crc>
<splt_length> ::= b"\x00\x00\x00\x11"
<splt_data> ::= b"suggested\x00\x08\x80\x40\x20\xff\x00\x01"
<splt_crc> ::= b"\x73\x23\x08\x50"
where bytes(<splt_data>).split(b"\x00", 1)[1][0] in (8, 16) and (len(bytes(<splt_data>).split(b"\x00", 1)[1]) - 1) % 6 == 0 and bytes(<splt_length>) == len(bytes(<splt_data>)).to_bytes(4, "big")
where bytes(<splt_crc>) == (zlib.crc32(b"sPLT" + bytes(<splt_data>)) & 0xffffffff).to_bytes(4, "big")

# ICC, uncompressed/compressed international text, modification time, and TIFF EXIF.
<iccp> ::= <iccp_length>b"iCCP"<iccp_data><iccp_crc>
<iccp_length> ::= b"\x00\x00\x00\x14"
<iccp_data> ::= b"icc\x00\x00\x78\x9c\x2b\x28\xca\x4f\xcb\xcc\x49\x05\x00\x0b\xfe\x02\xf2"
<iccp_crc> ::= b"\xfa\x17\x11\x33"
where bytes(<iccp_data>).split(b"\x00", 2)[1] == b"" and zlib.decompress(bytes(<iccp_data>).split(b"\x00", 2)[2]) == b"profile" and bytes(<iccp_length>) == len(bytes(<iccp_data>)).to_bytes(4, "big")
where bytes(<iccp_crc>) == (zlib.crc32(b"iCCP" + bytes(<iccp_data>)) & 0xffffffff).to_bytes(4, "big")

<text> ::= <text_length>b"tEXt"<text_data><text_crc>
<text_length> ::= b"\x00\x00\x00\x06"
<text_data> ::= b"Seed\x00\x00"
<text_crc> ::= b"\x8e\x27\xf1\x3e"
where 1 <= bytes(<text_data>).index(b"\x00") <= 79 and bytes(<text_length>) == len(bytes(<text_data>)).to_bytes(4, "big")
where bytes(<text_crc>) == (zlib.crc32(b"tEXt" + bytes(<text_data>)) & 0xffffffff).to_bytes(4, "big")

# PNG permits private ancillary chunks. Seven optional complete faNd chunks
# provide 128 valid, byte-distinct combinations without a generator shortcut.
<private_nonce> ::= <nonce0><nonce1><nonce2><nonce3><nonce4><nonce5><nonce6>
<nonce0> ::= b"" | b"\x00\x00\x00\x01faNd\x00\x28\x5f\xeb\xff"
<nonce1> ::= b"" | b"\x00\x00\x00\x01faNd\x01\x5f\x58\xdb\x69"
<nonce2> ::= b"" | b"\x00\x00\x00\x01faNd\x02\xc6\x51\x8a\xd3"
<nonce3> ::= b"" | b"\x00\x00\x00\x01faNd\x03\xb1\x56\xba\x45"
<nonce4> ::= b"" | b"\x00\x00\x00\x01faNd\x04\x2f\x32\x2f\xe6"
<nonce5> ::= b"" | b"\x00\x00\x00\x01faNd\x05\x58\x35\x1f\x70"
<nonce6> ::= b"" | b"\x00\x00\x00\x01faNd\x06\xc1\x3c\x4e\xca"

<ztxt> ::= <ztxt_length>b"zTXt"<ztxt_data><ztxt_crc>
<ztxt_length> ::= b"\x00\x00\x00\x14"
<ztxt_data> ::= b"Comment\x00\x00\x78\x9c\x0b\xf0\x73\x07\x00\x01\xd6\x00\xe6"
<ztxt_crc> ::= b"\x69\x4f\xaf\x46"
where bytes(<ztxt_data>).split(b"\x00", 1)[1][0] == 0 and zlib.decompress(bytes(<ztxt_data>).split(b"\x00", 1)[1][1:]) == b"PNG" and bytes(<ztxt_length>) == len(bytes(<ztxt_data>)).to_bytes(4, "big")
where bytes(<ztxt_crc>) == (zlib.crc32(b"zTXt" + bytes(<ztxt_data>)) & 0xffffffff).to_bytes(4, "big")

<itxt> ::= <itxt_length>b"iTXt"<itxt_data><itxt_crc>
<itxt_length> ::= b"\x00\x00\x00\x0d"
<itxt_data> ::= b"Title\x00" b"\x00\x00\x00\x00" b"PNG"
<itxt_crc> ::= b"\x70\xe5\x20\x74"
where bytes(<itxt_data>)[0:5] == b"Title" and bytes(<itxt_data>)[5:10] == b"\x00\x00\x00\x00\x00" and bytes(<itxt_data>)[10:] == b"PNG" and bytes(<itxt_length>) == len(bytes(<itxt_data>)).to_bytes(4, "big")
where bytes(<itxt_crc>) == (zlib.crc32(b"iTXt" + bytes(<itxt_data>)) & 0xffffffff).to_bytes(4, "big")

<time> ::= <time_length>b"tIME"<time_data><time_crc>
<time_length> ::= b"\x00\x00\x00\x07"
<time_data> ::= b"\x07\xe8\x01\x01\x00\x00\x00"
<time_crc> ::= b"\xb3\x1f\x7d\x9a"
where len(bytes(<time_data>)) == 7 and 1 <= bytes(<time_data>)[2] <= 12 and 1 <= bytes(<time_data>)[3] <= 31 and bytes(<time_data>)[4] <= 23 and bytes(<time_data>)[5] <= 59 and bytes(<time_data>)[6] <= 60 and bytes(<time_length>) == len(bytes(<time_data>)).to_bytes(4, "big")
where bytes(<time_crc>) == (zlib.crc32(b"tIME" + bytes(<time_data>)) & 0xffffffff).to_bytes(4, "big")

<exif> ::= <exif_length>b"eXIf"<exif_data><exif_crc>
<exif_length> ::= b"\x00\x00\x00\x0a"
<exif_data> ::= b"II\x2a\x00\x08\x00\x00\x00\x00\x00"
<exif_crc> ::= b"\x0b\x9c\xc8\x40"
where bytes(<exif_data>)[0:4] in (b"II\x2a\x00", b"MM\x00\x2a") and bytes(<exif_length>) == len(bytes(<exif_data>)).to_bytes(4, "big")
where bytes(<exif_crc>) == (zlib.crc32(b"eXIf" + bytes(<exif_data>)) & 0xffffffff).to_bytes(4, "big")

# APNG: two 1 x 1 frames; sequence numbers are 0, 1, and 2 in order.
<actl> ::= <actl_length>b"acTL"<actl_data><actl_crc>
<actl_length> ::= b"\x00\x00\x00\x08"
<actl_data> ::= b"\x00\x00\x00\x02\x00\x00\x00\x00"
<actl_crc> ::= b"\xf3\x8d\x93\x70"
where len(bytes(<actl_data>)) == 8 and int.from_bytes(bytes(<actl_data>)[0:4], "big") == 2 and bytes(<actl_length>) == len(bytes(<actl_data>)).to_bytes(4, "big")
where bytes(<actl_crc>) == (zlib.crc32(b"acTL" + bytes(<actl_data>)) & 0xffffffff).to_bytes(4, "big")

<fctl0> ::= <fctl0_length>b"fcTL"<fctl0_data><fctl0_crc>
<fctl0_length> ::= b"\x00\x00\x00\x1a"
<fctl0_data> ::= b"\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x64\x00\x00\x00\x00"
<fctl0_crc> ::= b"\x06\x3a\x4d\x3b"
where len(bytes(<fctl0_data>)) == 26 and bytes(<fctl0_data>)[0:4] == b"\x00\x00\x00\x00" and bytes(<fctl0_data>)[4:8] == bytes(<ihdr_data>)[0:4] and bytes(<fctl0_data>)[8:12] == bytes(<ihdr_data>)[4:8]
where bytes(<fctl0_data>)[20:22] != b"\x00\x00" and bytes(<fctl0_data>)[24] in (0, 1, 2) and bytes(<fctl0_data>)[25] in (0, 1) and bytes(<fctl0_length>) == len(bytes(<fctl0_data>)).to_bytes(4, "big")
where bytes(<fctl0_crc>) == (zlib.crc32(b"fcTL" + bytes(<fctl0_data>)) & 0xffffffff).to_bytes(4, "big")

<idat> ::= <idat_length>b"IDAT"<idat_data><idat_crc>
<idat_length> ::= b"\x00\x00\x00\x0a"
<idat_data> ::= b"\x78\x9c\x63\x60\x00\x00\x00\x02\x00\x01"
<idat_crc> ::= b"\x48\xaf\xa4\x71"
where zlib.decompress(bytes(<idat_data>)) == b"\x00\x00" and len(zlib.decompress(bytes(<idat_data>))) == int.from_bytes(bytes(<ihdr_data>)[4:8], "big") * (1 + int.from_bytes(bytes(<ihdr_data>)[0:4], "big")) and bytes(<idat_length>) == len(bytes(<idat_data>)).to_bytes(4, "big")
where bytes(<idat_crc>) == (zlib.crc32(b"IDAT" + bytes(<idat_data>)) & 0xffffffff).to_bytes(4, "big")

<fctl1> ::= <fctl1_length>b"fcTL"<fctl1_data><fctl1_crc>
<fctl1_length> ::= b"\x00\x00\x00\x1a"
<fctl1_data> ::= b"\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x64\x00\x01\x00\x01"
<fctl1_crc> ::= b"\xeb\x8c\xfd\x4e"
where len(bytes(<fctl1_data>)) == 26 and bytes(<fctl1_data>)[0:4] == b"\x00\x00\x00\x01" and bytes(<fctl1_data>)[4:8] == bytes(<ihdr_data>)[0:4] and bytes(<fctl1_data>)[8:12] == bytes(<ihdr_data>)[4:8]
where bytes(<fctl1_data>)[20:22] != b"\x00\x00" and bytes(<fctl1_data>)[24] in (0, 1, 2) and bytes(<fctl1_data>)[25] in (0, 1) and bytes(<fctl1_length>) == len(bytes(<fctl1_data>)).to_bytes(4, "big")
where bytes(<fctl1_crc>) == (zlib.crc32(b"fcTL" + bytes(<fctl1_data>)) & 0xffffffff).to_bytes(4, "big")

<fdat> ::= <fdat_length>b"fdAT"<fdat_data><fdat_crc>
<fdat_length> ::= b"\x00\x00\x00\x0e"
<fdat_data> ::= b"\x00\x00\x00\x02\x78\x9c\x63\x60\x00\x00\x00\x02\x00\x01"
<fdat_crc> ::= b"\x3a\xb0\xef\xa1"
where bytes(<fdat_data>)[0:4] == b"\x00\x00\x00\x02" and zlib.decompress(bytes(<fdat_data>)[4:]) == zlib.decompress(bytes(<idat_data>)) and bytes(<fdat_length>) == len(bytes(<fdat_data>)).to_bytes(4, "big")
where bytes(<fdat_crc>) == (zlib.crc32(b"fdAT" + bytes(<fdat_data>)) & 0xffffffff).to_bytes(4, "big")

<iend> ::= <iend_length>b"IEND"<iend_data><iend_crc>
<iend_length> ::= b"\x00\x00\x00\x00"
<iend_data> ::= b""
<iend_crc> ::= b"\xae\x42\x60\x82"
where len(bytes(<iend_data>)) == 0 and bytes(<iend_length>) == len(bytes(<iend_data>)).to_bytes(4, "big")
where bytes(<iend_crc>) == (zlib.crc32(b"IEND" + bytes(<iend_data>)) & 0xffffffff).to_bytes(4, "big")

# dSIG is permitted after IEND.  The payload is a placeholder detached-signature blob.
<dsig> ::= <dsig_length>b"dSIG"<dsig_data><dsig_crc>
<dsig_length> ::= b"\x00\x00\x00\x09"
<dsig_data> ::= b"signature"
<dsig_crc> ::= b"\x13\x39\x50\xea"
where len(bytes(<dsig_data>)) > 0 and bytes(<dsig_length>) == len(bytes(<dsig_data>)).to_bytes(4, "big")
where bytes(<dsig_crc>) == (zlib.crc32(b"dSIG" + bytes(<dsig_data>)) & 0xffffffff).to_bytes(4, "big")
